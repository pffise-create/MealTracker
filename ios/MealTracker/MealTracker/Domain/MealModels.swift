import Foundation

enum MealCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snacks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snacks: "Snacks"
        }
    }

    var defaultHour: Int {
        switch self {
        case .breakfast: 8
        case .lunch: 12
        case .dinner: 19
        case .snacks: 15
        }
    }
}

enum CategoryResolution: String, Codable, Sendable {
    case unresolved
    case logged
    case skipped

    var accessibilityDescription: String {
        switch self {
        case .unresolved: "Unresolved"
        case .logged: "Food logged"
        case .skipped: "Skipped or none"
        }
    }
}

enum NutritionProvenance: String, Codable, Sendable {
    case userSupplied
    case official
    case database
    case starter
    case demoEstimate

    var isEstimate: Bool { self == .demoEstimate }
}

enum MealInputMethod: String, Codable, CaseIterable, Sendable {
    case prediction
    case text
    case voice
    case camera
    case photoLibrary
    case restaurantMenu
    case manual
}

struct NutritionFacts: Codable, Hashable, Sendable {
    var calories: Double?
    var protein: Double?
    var fat: Double?
    var carbohydrates: Double?

    static let zero = NutritionFacts(calories: 0, protein: 0, fat: 0, carbohydrates: 0)
    static let unknown = NutritionFacts(calories: nil, protein: nil, fat: nil, carbohydrates: nil)

    var containsUnknown: Bool {
        calories == nil || protein == nil || fat == nil || carbohydrates == nil
    }

    func scaled(by factor: Double) -> NutritionFacts {
        NutritionFacts(
            calories: calories.map { $0 * factor },
            protein: protein.map { $0 * factor },
            fat: fat.map { $0 * factor },
            carbohydrates: carbohydrates.map { $0 * factor }
        )
    }
}

struct NutritionSummary: Equatable, Sendable {
    var calories: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbohydrates: Double = 0
    var containsUnknown = false
    var containsEstimate = false

    mutating func add(_ facts: NutritionFacts, provenance: NutritionProvenance) {
        calories += facts.calories ?? 0
        protein += facts.protein ?? 0
        fat += facts.fat ?? 0
        carbohydrates += facts.carbohydrates ?? 0
        containsUnknown = containsUnknown || facts.containsUnknown
        containsEstimate = containsEstimate || provenance.isEstimate
    }
}

struct IngredientOption: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var name: String
    var nutrition: NutritionFacts
}

struct IngredientSlot: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var options: [IngredientOption]
    var selectedOptionID: String
    var isIncluded: Bool

    var selectedOption: IngredientOption? {
        options.first { $0.id == selectedOptionID }
    }
}

struct PortionOption: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var label: String
    var exactQuantity: String?
    var factor: Double

    var displayText: String {
        guard let exactQuantity else { return label }
        return "\(label) — \(exactQuantity)"
    }
}

struct MealTemplate: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var name: String
    var category: MealCategory
    var ingredients: [IngredientSlot]
    var portions: [PortionOption]
    var defaultPortionID: String
    var typicalHours: ClosedRange<Int>
    var provenance: NutritionProvenance

    var defaultPortion: PortionOption {
        portions.first { $0.id == defaultPortionID }
            ?? portions.first
            ?? PortionOption(id: "default", label: "Usual portion", exactQuantity: nil, factor: 1)
    }
}

struct MealDraft: Identifiable, Sendable {
    let id: UUID
    let templateID: String?
    var name: String
    var category: MealCategory
    var ingredients: [IngredientSlot]
    var portions: [PortionOption]
    var selectedPortionID: String
    var provenance: NutritionProvenance

    init(template: MealTemplate) {
        id = UUID()
        templateID = template.id
        name = template.name
        category = template.category
        ingredients = template.ingredients
        portions = template.portions
        selectedPortionID = template.defaultPortionID
        provenance = template.provenance
    }

    init(
        name: String,
        category: MealCategory,
        ingredients: [IngredientSlot],
        portions: [PortionOption],
        provenance: NutritionProvenance,
        templateID: String? = nil
    ) {
        id = UUID()
        self.templateID = templateID
        self.name = name
        self.category = category
        self.ingredients = ingredients
        self.portions = portions
        selectedPortionID = portions.first?.id ?? "default"
        self.provenance = provenance
    }

    var selectedPortion: PortionOption {
        portions.first { $0.id == selectedPortionID }
            ?? PortionOption(id: "default", label: "Usual portion", exactQuantity: nil, factor: 1)
    }

    var nutrition: NutritionFacts {
        let selected = ingredients.compactMap { slot -> NutritionFacts? in
            guard slot.isIncluded else { return nil }
            return slot.selectedOption?.nutrition
        }
        let totals = selected.reduce(NutritionFacts.zero) { partial, next in
            NutritionFacts(
                calories: sum(partial.calories, next.calories),
                protein: sum(partial.protein, next.protein),
                fat: sum(partial.fat, next.fat),
                carbohydrates: sum(partial.carbohydrates, next.carbohydrates)
            )
        }
        return totals.scaled(by: selectedPortion.factor)
    }

    mutating func addCustomIngredient(named name: String) {
        let key = "custom-\(UUID().uuidString)"
        ingredients.append(
            IngredientSlot(
                id: key,
                options: [IngredientOption(id: key, name: name, nutrition: .unknown)],
                selectedOptionID: key,
                isIncluded: true
            )
        )
    }
}

private func sum(_ lhs: Double?, _ rhs: Double?) -> Double? {
    guard let lhs, let rhs else { return nil }
    return lhs + rhs
}

struct LoggedIngredient: Codable, Hashable, Identifiable, Sendable {
    let id: String
    var name: String
    var nutrition: NutritionFacts
}

struct MealEntry: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var templateID: String?
    var name: String
    var createdAt: Date
    var consumedAt: Date
    var localDayIdentifier: String
    var timeZoneIdentifier: String
    var category: MealCategory
    var ingredients: [LoggedIngredient]
    var portionLabel: String
    var exactQuantity: String?
    var portionFactor: Double
    var nutrition: NutritionFacts
    var provenance: NutritionProvenance
    var inputMethod: MealInputMethod
    var correctionCount: Int
    var venueID: String?
}

struct DaySnapshot: Identifiable, Equatable, Sendable {
    var id: String { dayIdentifier }
    var dayIdentifier: String
    var timeZoneIdentifier: String
    var entries: [MealEntry]
    var skippedCategories: Set<MealCategory>
    var endedAt: Date?

    func resolution(for category: MealCategory) -> CategoryResolution {
        if entries.contains(where: { $0.category == category }) { return .logged }
        if skippedCategories.contains(category) { return .skipped }
        return .unresolved
    }

    var isComplete: Bool {
        MealCategory.allCases.allSatisfy { resolution(for: $0) != .unresolved }
    }

    var nutrition: NutritionSummary {
        entries.reduce(into: NutritionSummary()) { summary, entry in
            summary.add(entry.nutrition, provenance: entry.provenance)
        }
    }

    var resolvedCount: Int {
        MealCategory.allCases.filter { resolution(for: $0) != .unresolved }.count
    }
}

struct NutritionTargets: Codable, Equatable, Sendable {
    var calories: Double = 2_200
    var protein: Double = 160
    var fat: Double = 75
    var carbohydrates: Double = 230
}

struct UserSettings: Equatable, Sendable {
    var targets: NutritionTargets
    var notificationsEnabled: Bool
    var deleteOriginalPhotos: Bool

    static let defaults = UserSettings(
        targets: NutritionTargets(),
        notificationsEnabled: false,
        deleteOriginalPhotos: true
    )
}

struct RewardEvent: Identifiable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case mealLogged
        case dayCompleted
    }

    var id: String { sourceID }
    var sourceID: String
    var kind: Kind
    var amount: Int
    var createdAt: Date
}

struct StreakSummary: Equatable, Sendable {
    var current: Int
    var longest: Int
    var totalCompleteDays: Int

    static let zero = StreakSummary(current: 0, longest: 0, totalCompleteDays: 0)
}

struct MealPrediction: Identifiable, Sendable {
    var id: String { template.id }
    var template: MealTemplate
    var score: Double
    var reason: String
    var isLearned: Bool
}
