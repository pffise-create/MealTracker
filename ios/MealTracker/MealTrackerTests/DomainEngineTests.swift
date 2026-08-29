import Foundation
import XCTest
@testable import MealTracker

final class DomainEngineTests: XCTestCase {
    func testNutritionAggregationPreservesUnknownAndEstimateSignals() {
        let known = makeEntry(
            id: UUID(),
            day: "2026-08-29",
            category: .breakfast,
            nutrition: NutritionFacts(calories: 400, protein: 30, fat: 12, carbohydrates: 42),
            provenance: .official
        )
        let unknown = makeEntry(
            id: UUID(),
            day: "2026-08-29",
            category: .lunch,
            nutrition: .unknown,
            provenance: .demoEstimate
        )

        let summary = NutritionEngine.aggregate([known, unknown])

        XCTAssertEqual(summary.calories, 400)
        XCTAssertEqual(summary.protein, 30)
        XCTAssertTrue(summary.containsUnknown)
        XCTAssertTrue(summary.containsEstimate)
    }

    func testMealCategoryResolutionAndDayCompletionIgnoreMacros() {
        let breakfast = makeEntry(
            id: UUID(),
            day: "2026-08-29",
            category: .breakfast,
            nutrition: .unknown
        )
        let day = DaySnapshot(
            dayIdentifier: "2026-08-29",
            timeZoneIdentifier: "America/Los_Angeles",
            entries: [breakfast],
            skippedCategories: [.lunch, .dinner, .snacks],
            endedAt: nil
        )

        XCTAssertEqual(day.resolution(for: .breakfast), .logged)
        XCTAssertEqual(day.resolution(for: .lunch), .skipped)
        XCTAssertTrue(day.isComplete)
    }

    func testLocalDayRolloverAndTimezoneAssignment() throws {
        let timestamp = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-30T06:30:00Z"))
        let pacific = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))

        XCTAssertEqual(LocalDayResolver.identifier(for: timestamp, in: pacific), "2026-08-29")
        XCTAssertEqual(LocalDayResolver.identifier(for: timestamp, in: utc), "2026-08-30")
        XCTAssertEqual(LocalDayResolver.addingDays(1, to: "2026-08-29"), "2026-08-30")
    }

    func testStreakIncrementResetAndRecovery() {
        let complete27 = completeDay("2026-08-27")
        let incomplete28 = incompleteDay("2026-08-28")
        let complete29 = completeDay("2026-08-29")
        let current30 = incompleteDay("2026-08-30")

        let reset = StreakEngine.calculate(
            days: [complete27, incomplete28, complete29, current30],
            currentDayIdentifier: "2026-08-30"
        )
        XCTAssertEqual(reset.current, 1)
        XCTAssertEqual(reset.longest, 1)

        let recovered = StreakEngine.calculate(
            days: [complete27, completeDay("2026-08-28"), complete29, current30],
            currentDayIdentifier: "2026-08-30"
        )
        XCTAssertEqual(recovered.current, 3)
        XCTAssertEqual(recovered.longest, 3)
    }

    func testPortionAndIngredientSwapRecalculateImmediately() throws {
        let template = try XCTUnwrap(SeedMealCatalog.templates.first { $0.id == "starter-lemon-chicken-bowl" })
        var draft = MealDraft(template: template)
        let usualCalories = try XCTUnwrap(draft.nutrition.calories)

        draft.selectedPortionID = "light"
        let lightCalories = try XCTUnwrap(draft.nutrition.calories)
        XCTAssertLessThan(lightCalories, usualCalories)

        let proteinIndex = try XCTUnwrap(draft.ingredients.firstIndex { $0.id == "protein" })
        draft.ingredients[proteinIndex].selectedOptionID = "tofu"
        XCTAssertNotEqual(draft.nutrition.protein, MealDraft(template: template).nutrition.protein)
    }

    func testCorrectedRecentBehaviorOutweighsStaleStarterRanking() throws {
        let lunch = try XCTUnwrap(SeedMealCatalog.templates.first { $0.category == .lunch })
        let breakfast = try XCTUnwrap(SeedMealCatalog.templates.first { $0.category == .breakfast })
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-08-29T19:00:00Z"))
        let recentCorrected = makeEntry(
            id: UUID(),
            day: "2026-08-29",
            category: .breakfast,
            nutrition: .zero,
            templateID: breakfast.id,
            consumedAt: now.addingTimeInterval(-3_600),
            correctionCount: 4
        )

        let ranked = DeterministicMealPredictionEngine().predictions(
            templates: [lunch, breakfast],
            entries: [recentCorrected],
            now: now,
            timeZone: TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
        )

        XCTAssertEqual(ranked.first?.template.id, breakfast.id)
        XCTAssertTrue(ranked.first?.isLearned == true)
    }

    func testRewardAmountsAreDeterministicPerEatingOccasion() {
        let id = UUID()
        XCTAssertEqual(RewardEngine.mealEvent(entryID: id, at: Date()).amount, 3)
        XCTAssertEqual(RewardEngine.completionEvent(dayIdentifier: "2026-08-29", at: Date()).amount, 8)
    }

    private func completeDay(_ identifier: String) -> DaySnapshot {
        DaySnapshot(
            dayIdentifier: identifier,
            timeZoneIdentifier: "UTC",
            entries: [],
            skippedCategories: Set(MealCategory.allCases),
            endedAt: nil
        )
    }

    private func incompleteDay(_ identifier: String) -> DaySnapshot {
        DaySnapshot(
            dayIdentifier: identifier,
            timeZoneIdentifier: "UTC",
            entries: [],
            skippedCategories: [],
            endedAt: nil
        )
    }
}

func makeEntry(
    id: UUID,
    day: String,
    category: MealCategory,
    nutrition: NutritionFacts,
    provenance: NutritionProvenance = .official,
    templateID: String? = nil,
    consumedAt: Date = Date(timeIntervalSince1970: 1_777_000_000),
    correctionCount: Int = 0
) -> MealEntry {
    MealEntry(
        id: id,
        templateID: templateID,
        name: "Test meal",
        createdAt: consumedAt,
        consumedAt: consumedAt,
        localDayIdentifier: day,
        timeZoneIdentifier: "UTC",
        category: category,
        ingredients: [],
        portionLabel: "Usual",
        exactQuantity: nil,
        portionFactor: 1,
        nutrition: nutrition,
        provenance: provenance,
        inputMethod: .manual,
        correctionCount: correctionCount,
        venueID: nil
    )
}
