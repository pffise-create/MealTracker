import Foundation
import SwiftData
import XCTest
@testable import MealTracker

@MainActor
final class PersistenceAndStoreTests: XCTestCase {
    func testPersistenceRoundTripPreservesAbsoluteAndLocalTimeData() throws {
        let repository = try makeRepository()
        let id = UUID()
        let entry = makeEntry(
            id: id,
            day: "2026-08-29",
            category: .dinner,
            nutrition: NutritionFacts(calories: 620, protein: 44, fat: 20, carbohydrates: 64)
        )

        try repository.saveEntry(entry)
        let fetched = try XCTUnwrap(repository.fetchEntries().first)

        XCTAssertEqual(fetched.id, id)
        XCTAssertEqual(fetched.localDayIdentifier, "2026-08-29")
        XCTAssertEqual(fetched.timeZoneIdentifier, "UTC")
        XCTAssertEqual(fetched.nutrition.calories, 620)
    }

    func testAddingFoodReplacesSkippedState() throws {
        let repository = try makeRepository()
        try repository.setSkipped(
            true,
            category: .lunch,
            dayIdentifier: "2026-08-29",
            timeZoneIdentifier: "UTC"
        )
        try repository.saveEntry(
            makeEntry(id: UUID(), day: "2026-08-29", category: .lunch, nutrition: .zero)
        )

        let day = try XCTUnwrap(repository.fetchDays().first)
        XCTAssertEqual(day.resolution(for: .lunch), .logged)
        XCTAssertFalse(day.skippedCategories.contains(.lunch))
    }

    func testRewardLedgerIsIdempotent() throws {
        let repository = try makeRepository()
        let event = RewardEngine.completionEvent(dayIdentifier: "2026-08-29", at: Date())
        try repository.addRewardIfNeeded(event)
        try repository.addRewardIfNeeded(event)

        XCTAssertEqual(try repository.fetchRewards().count, 1)
        XCTAssertEqual(try repository.fetchRewards().first?.amount, 8)
    }

    func testUndoRemovesEntryAndRewardsFromAccidentalLog() throws {
        let repository = try makeRepository()
        let clock = FixedClock(
            now: Date(timeIntervalSince1970: 1_777_000_000),
            timeZone: TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
        )
        let store = MealTrackerStore(
            repository: repository,
            clock: clock,
            voiceTranscriber: TestVoiceTranscriber(),
            venueResolver: TestVenueResolver(),
            healthKit: TestHealthKit()
        )
        store.bootstrap()
        let template = try XCTUnwrap(SeedMealCatalog.templates.first)
        let draft = MealDraft(template: template)

        store.log(draft: draft)
        XCTAssertEqual(try repository.fetchEntries().count, 1)
        XCTAssertEqual(store.resourceBalance, RewardEngine.mealAmount)

        store.undoRecent()
        XCTAssertTrue(try repository.fetchEntries().isEmpty)
        XCTAssertEqual(store.resourceBalance, 0)
    }

    func testUndoRestoresSkippedResolutionReplacedByLog() throws {
        let repository = try makeRepository()
        let clock = FixedClock(
            now: Date(timeIntervalSince1970: 1_777_000_000),
            timeZone: TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
        )
        let store = MealTrackerStore(
            repository: repository,
            clock: clock,
            voiceTranscriber: TestVoiceTranscriber(),
            venueResolver: TestVenueResolver(),
            healthKit: TestHealthKit()
        )
        store.bootstrap()
        let template = try XCTUnwrap(SeedMealCatalog.templates.first)
        store.markSkipped(template.category, dayIdentifier: store.today.dayIdentifier)

        store.log(draft: MealDraft(template: template))
        XCTAssertEqual(store.today.resolution(for: template.category), .logged)

        store.undoRecent()
        XCTAssertEqual(store.today.resolution(for: template.category), .skipped)
    }

    func testHistoricalRecoveryRecalculatesStreakWithoutMacroDependency() throws {
        let repository = try makeRepository()
        let clock = FixedClock(
            now: LocalDayResolver.date(
                from: "2026-08-30",
                hour: 12,
                timeZone: TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
            ) ?? Date(),
            timeZone: TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
        )
        let store = MealTrackerStore(
            repository: repository,
            clock: clock,
            voiceTranscriber: TestVoiceTranscriber(),
            venueResolver: TestVenueResolver(),
            healthKit: TestHealthKit()
        )
        store.bootstrap()
        for category in MealCategory.allCases {
            store.markSkipped(category, dayIdentifier: "2026-08-29")
        }

        XCTAssertEqual(store.streak.current, 1)
        XCTAssertEqual(store.lifetimeCompleteDayCount, 1)
    }

    private func makeRepository() throws -> SwiftDataMealRepository {
        let container = try ModelContainer(
            for: MealEntryRecord.self,
            DayRecord.self,
            RewardRecord.self,
            SettingsRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataMealRepository(context: container.mainContext)
    }
}

@MainActor
private final class TestVoiceTranscriber: VoiceTranscribing {
    var isRecording = false
    func requestAuthorization() async -> Bool { true }
    func start(onUpdate: @escaping (String) -> Void) throws {
        isRecording = true
        onUpdate("test meal")
    }
    func stop() { isRecording = false }
}

@MainActor
private final class TestVenueResolver: VenueResolving {
    var authorization: LocationAuthorizationState = .authorized
    func resolveForegroundVenues() async throws -> [VenueCandidate] { [] }
}

@MainActor
private final class TestHealthKit: HealthKitReading {
    var isAvailable = true
    func requestReadAccess() async throws -> Bool { true }
    func currentSnapshot() async throws -> HealthContextSnapshot {
        HealthContextSnapshot(latestWeightKilograms: nil, stepsToday: nil, activeEnergyToday: nil, recentWorkoutCount: nil)
    }
}
