import Foundation
import SwiftData

@Model
final class MealEntryRecord {
    @Attribute(.unique) var id: UUID
    var templateID: String?
    var name: String
    var createdAt: Date
    var consumedAt: Date
    var localDayIdentifier: String
    var timeZoneIdentifier: String
    var categoryRaw: String
    var ingredientsData: Data
    var portionLabel: String
    var exactQuantity: String?
    var portionFactor: Double
    var nutritionData: Data
    var provenanceRaw: String
    var inputMethodRaw: String
    var correctionCount: Int
    var venueID: String?

    init(entry: MealEntry, encoder: JSONEncoder = JSONEncoder()) throws {
        id = entry.id
        templateID = entry.templateID
        name = entry.name
        createdAt = entry.createdAt
        consumedAt = entry.consumedAt
        localDayIdentifier = entry.localDayIdentifier
        timeZoneIdentifier = entry.timeZoneIdentifier
        categoryRaw = entry.category.rawValue
        ingredientsData = try encoder.encode(entry.ingredients)
        portionLabel = entry.portionLabel
        exactQuantity = entry.exactQuantity
        portionFactor = entry.portionFactor
        nutritionData = try encoder.encode(entry.nutrition)
        provenanceRaw = entry.provenance.rawValue
        inputMethodRaw = entry.inputMethod.rawValue
        correctionCount = entry.correctionCount
        venueID = entry.venueID
    }

    func update(from entry: MealEntry, encoder: JSONEncoder = JSONEncoder()) throws {
        templateID = entry.templateID
        name = entry.name
        createdAt = entry.createdAt
        consumedAt = entry.consumedAt
        localDayIdentifier = entry.localDayIdentifier
        timeZoneIdentifier = entry.timeZoneIdentifier
        categoryRaw = entry.category.rawValue
        ingredientsData = try encoder.encode(entry.ingredients)
        portionLabel = entry.portionLabel
        exactQuantity = entry.exactQuantity
        portionFactor = entry.portionFactor
        nutritionData = try encoder.encode(entry.nutrition)
        provenanceRaw = entry.provenance.rawValue
        inputMethodRaw = entry.inputMethod.rawValue
        correctionCount = entry.correctionCount
        venueID = entry.venueID
    }

    func snapshot(decoder: JSONDecoder = JSONDecoder()) throws -> MealEntry {
        guard
            let category = MealCategory(rawValue: categoryRaw),
            let provenance = NutritionProvenance(rawValue: provenanceRaw),
            let inputMethod = MealInputMethod(rawValue: inputMethodRaw)
        else {
            throw PersistenceError.invalidStoredValue
        }
        return MealEntry(
            id: id,
            templateID: templateID,
            name: name,
            createdAt: createdAt,
            consumedAt: consumedAt,
            localDayIdentifier: localDayIdentifier,
            timeZoneIdentifier: timeZoneIdentifier,
            category: category,
            ingredients: try decoder.decode([LoggedIngredient].self, from: ingredientsData),
            portionLabel: portionLabel,
            exactQuantity: exactQuantity,
            portionFactor: portionFactor,
            nutrition: try decoder.decode(NutritionFacts.self, from: nutritionData),
            provenance: provenance,
            inputMethod: inputMethod,
            correctionCount: correctionCount,
            venueID: venueID
        )
    }
}

@Model
final class DayRecord {
    @Attribute(.unique) var dayIdentifier: String
    var timeZoneIdentifier: String
    var skippedCategoriesRaw: String
    var endedAt: Date?

    init(dayIdentifier: String, timeZoneIdentifier: String) {
        self.dayIdentifier = dayIdentifier
        self.timeZoneIdentifier = timeZoneIdentifier
        skippedCategoriesRaw = ""
    }

    var skippedCategories: Set<MealCategory> {
        Set(skippedCategoriesRaw.split(separator: ",").compactMap { MealCategory(rawValue: String($0)) })
    }

    func setSkipped(_ skipped: Set<MealCategory>) {
        skippedCategoriesRaw = skipped.map(\.rawValue).sorted().joined(separator: ",")
    }
}

@Model
final class RewardRecord {
    @Attribute(.unique) var sourceID: String
    var kindRaw: String
    var amount: Int
    var createdAt: Date

    init(event: RewardEvent) {
        sourceID = event.sourceID
        kindRaw = event.kind.rawValue
        amount = event.amount
        createdAt = event.createdAt
    }

    var event: RewardEvent? {
        guard let kind = RewardEvent.Kind(rawValue: kindRaw) else { return nil }
        return RewardEvent(sourceID: sourceID, kind: kind, amount: amount, createdAt: createdAt)
    }
}

@Model
final class SettingsRecord {
    @Attribute(.unique) var id: String
    var calorieTarget: Double
    var proteinTarget: Double
    var fatTarget: Double
    var carbohydrateTarget: Double
    var notificationsEnabled: Bool
    var deleteOriginalPhotos: Bool

    init(settings: UserSettings) {
        id = "primary"
        calorieTarget = settings.targets.calories
        proteinTarget = settings.targets.protein
        fatTarget = settings.targets.fat
        carbohydrateTarget = settings.targets.carbohydrates
        notificationsEnabled = settings.notificationsEnabled
        deleteOriginalPhotos = settings.deleteOriginalPhotos
    }

    var settings: UserSettings {
        UserSettings(
            targets: NutritionTargets(
                calories: calorieTarget,
                protein: proteinTarget,
                fat: fatTarget,
                carbohydrates: carbohydrateTarget
            ),
            notificationsEnabled: notificationsEnabled,
            deleteOriginalPhotos: deleteOriginalPhotos
        )
    }

    func update(from settings: UserSettings) {
        calorieTarget = settings.targets.calories
        proteinTarget = settings.targets.protein
        fatTarget = settings.targets.fat
        carbohydrateTarget = settings.targets.carbohydrates
        notificationsEnabled = settings.notificationsEnabled
        deleteOriginalPhotos = settings.deleteOriginalPhotos
    }
}

enum PersistenceError: Error {
    case invalidStoredValue
}
