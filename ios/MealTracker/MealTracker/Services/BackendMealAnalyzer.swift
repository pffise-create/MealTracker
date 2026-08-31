import Foundation
import Security

enum BackendCredentialStore {
    private static let service = "com.pffise.MealTracker.backend"
    private static let account = "access-token"

    static var accessToken: String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(accessToken: String) throws {
        let key: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(key as CFDictionary)
        let cleaned = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        var item = key
        item[kSecValueData as String] = Data(cleaned.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw MealAnalysisError.unavailable }
    }
}

struct BackendMealAnalyzer: MealTextAnalyzing, MealPhotoAnalyzing {
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

    func analyze(text: String, category: MealCategory) async throws -> MealAnalysisResult {
        try await request(BackendMealAnalysisRequest(category: category.rawValue, text: text))
    }

    func analyze(imageData: Data, category: MealCategory) async throws -> MealAnalysisResult {
        try await request(
            BackendMealAnalysisRequest(
                category: category.rawValue,
                imageBase64: imageData.base64EncodedString(),
                mimeType: "image/jpeg"
            )
        )
    }

    private func request(_ payload: BackendMealAnalysisRequest) async throws -> MealAnalysisResult {
        guard let accessToken = BackendCredentialStore.accessToken else {
            throw MealAnalysisError.unavailable
        }
        let endpoint = baseURL.appending(path: "api/meal-analysis")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        // Render's free instances can spend roughly 50 seconds waking before
        // OpenAI processing begins. Leave enough room for both phases.
        request.timeoutInterval = 90
        request.httpBody = try JSONEncoder().encode(payload)

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
        let decoded = try JSONDecoder().decode(BackendMealAnalysisResponse.self, from: data)
        let ingredientSlots = decoded.analysis.items.enumerated().map { index, item in
            let identifier = "ai-item-\(index)"
            return IngredientSlot(
                id: identifier,
                options: [
                    IngredientOption(
                        id: identifier,
                        name: "\(item.name) • \(item.quantity)",
                        nutrition: item.nutrition
                    )
                ],
                selectedOptionID: identifier,
                isIncluded: true
            )
        }
        return MealAnalysisResult(
            draft: MealDraft(
                name: decoded.analysis.name,
                category: MealCategory(rawValue: payload.category) ?? .snacks,
                ingredients: ingredientSlots.isEmpty ? [decoded.analysis.fallbackIngredient] : ingredientSlots,
                portions: [PortionOption(id: "estimated", label: "AI estimate", exactQuantity: nil, factor: 1)],
                provenance: .aiEstimate
            ),
            disclosure: decoded.provenance
        )
    }
}

private struct BackendMealAnalysisRequest: Encodable {
    var category: String
    var text: String?
    var imageBase64: String?
    var mimeType: String?

    init(category: String, text: String) {
        self.category = category
        self.text = text
    }

    init(category: String, imageBase64: String, mimeType: String) {
        self.category = category
        self.imageBase64 = imageBase64
        self.mimeType = mimeType
    }
}

private struct BackendMealAnalysisResponse: Decodable {
    var analysis: BackendNutrition
    var provenance: String
}

private struct BackendNutrition: Decodable {
    var name: String
    var items: [BackendNutritionItem]
    var calories: Double
    var protein: Double
    var fat: Double
    var carbohydrates: Double

    var nutrition: NutritionFacts {
        NutritionFacts(calories: calories, protein: protein, fat: fat, carbohydrates: carbohydrates)
    }

    var fallbackIngredient: IngredientSlot {
        IngredientSlot(
            id: "ai-estimate",
            options: [IngredientOption(id: "ai-estimate", name: name, nutrition: nutrition)],
            selectedOptionID: "ai-estimate",
            isIncluded: true
        )
    }
}

private struct BackendNutritionItem: Decodable {
    var name: String
    var quantity: String
    var calories: Double
    var protein: Double
    var fat: Double
    var carbohydrates: Double

    var nutrition: NutritionFacts {
        NutritionFacts(calories: calories, protein: protein, fat: fat, carbohydrates: carbohydrates)
    }
}
