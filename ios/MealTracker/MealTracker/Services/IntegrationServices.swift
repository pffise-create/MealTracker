import Foundation

struct MealAnalysisResult: Sendable {
    var draft: MealDraft
    var disclosure: String
}

protocol MealTextAnalyzing: Sendable {
    func analyze(text: String, category: MealCategory) async throws -> MealAnalysisResult
}

protocol MealPhotoAnalyzing: Sendable {
    func analyze(imageData: Data, category: MealCategory) async throws -> MealAnalysisResult
}

enum MealAnalysisError: LocalizedError {
    case emptyInput
    case imageUnreadable
    case unavailable
    case timedOut

    var errorDescription: String? {
        switch self {
        case .emptyInput: "Describe at least one food to continue."
        case .imageUnreadable: "That image could not be read. Try another photo or use text."
        case .unavailable: "Meal analysis is unavailable. Your input has not been logged."
        case .timedOut: "The private AI server took too long to wake. Try again; the next request should be faster."
        }
    }
}

struct DemoMealAnalyzer: MealTextAnalyzing, MealPhotoAnalyzing {
    func analyze(text: String, category: MealCategory) async throws -> MealAnalysisResult {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw MealAnalysisError.emptyInput }
        try await Task.sleep(for: .milliseconds(550))

        let lowercase = cleaned.lowercased()
        let facts: NutritionFacts
        if lowercase.contains("sandwich") || lowercase.contains("wrap") {
            facts = NutritionFacts(calories: 510, protein: 31, fat: 18, carbohydrates: 55)
        } else if lowercase.contains("pizza") {
            facts = NutritionFacts(calories: 640, protein: 27, fat: 24, carbohydrates: 76)
        } else if lowercase.contains("salad") {
            facts = NutritionFacts(calories: 430, protein: 28, fat: 22, carbohydrates: 32)
        } else {
            facts = NutritionFacts(calories: 520, protein: 30, fat: 19, carbohydrates: 57)
        }

        return MealAnalysisResult(
            draft: demoDraft(name: cleaned, category: category, facts: facts),
            disclosure: "Demo estimate based on local sample rules—not live AI analysis."
        )
    }

    func analyze(imageData: Data, category: MealCategory) async throws -> MealAnalysisResult {
        guard !imageData.isEmpty else { throw MealAnalysisError.imageUnreadable }
        try await Task.sleep(for: .milliseconds(750))
        let facts = NutritionFacts(calories: 560, protein: 34, fat: 21, carbohydrates: 59)
        return MealAnalysisResult(
            draft: demoDraft(name: "Photo meal estimate", category: category, facts: facts),
            disclosure: "Demo photo estimate—not live image analysis. Review Edit if needed."
        )
    }

    private func demoDraft(name: String, category: MealCategory, facts: NutritionFacts) -> MealDraft {
        let ingredient = IngredientOption(id: "demo-estimate", name: name, nutrition: facts)
        return MealDraft(
            name: name,
            category: category,
            ingredients: [
                IngredientSlot(
                    id: "demo-estimate",
                    options: [ingredient],
                    selectedOptionID: ingredient.id,
                    isIncluded: true
                )
            ],
            portions: [
                PortionOption(id: "usual", label: "Estimated portion", exactQuantity: nil, factor: 1)
            ],
            provenance: .demoEstimate
        )
    }
}

struct VenueCandidate: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var subtitle: String
    var latitude: Double
    var longitude: Double
    var confidence: String
}

@MainActor
protocol VenueResolving: AnyObject {
    var authorization: LocationAuthorizationState { get }
    func resolveForegroundVenues() async throws -> [VenueCandidate]
}

enum LocationAuthorizationState: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case restricted
}

struct RestaurantMenuItem: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var description: String
    var nutrition: NutritionFacts
    var sourceDescription: String
    var isOfficial: Bool
}

struct RestaurantMenuSource: Equatable, Sendable {
    var title: String
    var url: URL
    var retrievedAt: String
}

enum RestaurantMenuResult: Equatable, Sendable {
    case available(items: [RestaurantMenuItem], source: RestaurantMenuSource)
    case noReliableMenu
}

protocol RestaurantMenuSearching: Sendable {
    func menu(for venue: VenueCandidate) async throws -> RestaurantMenuResult
}

struct DemoRestaurantMenuService: RestaurantMenuSearching {
    func menu(for venue: VenueCandidate) async throws -> RestaurantMenuResult {
        _ = venue
        try await Task.sleep(for: .milliseconds(650))
        return .noReliableMenu
    }
}

struct HealthContextSnapshot: Equatable, Sendable {
    var latestWeightKilograms: Double?
    var stepsToday: Double?
    var activeEnergyToday: Double?
    var recentWorkoutCount: Int?
}

@MainActor
protocol HealthKitReading: AnyObject {
    var isAvailable: Bool { get }
    func requestReadAccess() async throws -> Bool
    func currentSnapshot() async throws -> HealthContextSnapshot
}

protocol AdventureContentGenerating: Sendable {
    func entryCopy(resourceBalance: Int) async throws -> String
}

struct DemoAdventureContentGenerator: AdventureContentGenerating {
    func entryCopy(resourceBalance: Int) async throws -> String {
        _ = resourceBalance
        return "A quiet trail waits beyond the ridge. The full adventure opens in a later milestone."
    }
}
