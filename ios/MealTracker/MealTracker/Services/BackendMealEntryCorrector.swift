import Foundation

struct MealEntryCorrection: Equatable, Sendable {
    var nutrition: NutritionFacts
    var summary: String
}

protocol MealEntryCorrecting: Sendable {
    func correct(entry: MealEntry, instruction: String) async throws -> MealEntryCorrection
}

struct BackendMealEntryCorrector: MealEntryCorrecting {
    private let baseURL: URL

    init?(bundle: Bundle = .main) {
        guard let value = bundle.object(forInfoDictionaryKey: "MEALTRACKER_API_BASE_URL") as? String,
              !value.isEmpty,
              !value.contains("$("),
              let baseURL = URL(string: value),
              baseURL.scheme == "https" else {
            return nil
        }
        self.baseURL = baseURL
    }

    func correct(entry: MealEntry, instruction: String) async throws -> MealEntryCorrection {
        let cleaned = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw MealAnalysisError.emptyInput }
        guard let accessToken = BackendCredentialStore.accessToken else {
            throw MealAnalysisError.unavailable
        }

        var request = URLRequest(url: baseURL.appending(path: "api/entry-correction"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(
            BackendMealEntryCorrectionRequest(entry: entry, instruction: cleaned)
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw MealAnalysisError.timedOut
        }
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw MealAnalysisError.unavailable
        }

        let result = try JSONDecoder().decode(BackendMealEntryCorrectionResponse.self, from: data).correction
        guard result.applied else { throw MealEntryCorrectionError.notApplied(result.summary) }
        return MealEntryCorrection(
            nutrition: NutritionFacts(
                calories: result.calories,
                protein: result.protein,
                fat: result.fat,
                carbohydrates: result.carbohydrates
            ),
            summary: result.summary
        )
    }
}

struct UnavailableMealEntryCorrector: MealEntryCorrecting {
    func correct(entry: MealEntry, instruction: String) async throws -> MealEntryCorrection {
        _ = entry
        _ = instruction
        throw MealAnalysisError.unavailable
    }
}

struct DemoMealEntryCorrector: MealEntryCorrecting {
    func correct(entry: MealEntry, instruction: String) async throws -> MealEntryCorrection {
        let pattern = #"\b(\d+(?:\.\d+)?)\s*(?:kcal|calories?|cals?)\b"#
        let range = instruction.range(of: pattern, options: .regularExpression)
        let matched = range.map { String(instruction[$0]) } ?? ""
        let number = matched.split(whereSeparator: { !$0.isNumber && $0 != "." }).first.flatMap { Double($0) }
        guard let calories = number else {
            throw MealEntryCorrectionError.notApplied("Say what should change, for example “this was 120 calories.”")
        }
        return MealEntryCorrection(
            nutrition: NutritionFacts(
                calories: calories,
                protein: entry.nutrition.protein,
                fat: entry.nutrition.fat,
                carbohydrates: entry.nutrition.carbohydrates
            ),
            summary: "Calories corrected to \(Int(calories.rounded())) kcal."
        )
    }
}

enum MealEntryCorrectionError: LocalizedError {
    case notApplied(String)

    var errorDescription: String? {
        switch self {
        case let .notApplied(message): return message
        }
    }
}

private struct BackendMealEntryCorrectionRequest: Encodable {
    var entry: MealEntry
    var instruction: String
}

private struct BackendMealEntryCorrectionResponse: Decodable {
    var correction: BackendMealEntryCorrectionPayload
}

private struct BackendMealEntryCorrectionPayload: Decodable {
    var applied: Bool
    var calories: Double
    var protein: Double
    var fat: Double
    var carbohydrates: Double
    var summary: String
}
