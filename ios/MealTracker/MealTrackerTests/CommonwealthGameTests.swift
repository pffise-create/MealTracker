import Foundation
import SwiftData
import XCTest
@testable import MealTracker

final class CommonwealthGameTests: XCTestCase {
    func testFirstMealCanRestoreWaterAndEveryResourceTripCostsXP() throws {
        var state = try CommonwealthEngine.resolve(.acceptCharter, in: .initial, availableXP: 0)
        XCTAssertEqual(state.xpSpent, 0)
        XCTAssertNotNil(CommonwealthEngine.blocker(for: .forage, in: state, availableXP: 100))
        state = try CommonwealthEngine.resolve(.restoreWater, in: state, availableXP: RewardEngine.mealAmount)
        XCTAssertEqual(state.xpSpent, RewardEngine.mealAmount)
        XCTAssertTrue(state.buildings.contains(.well))
        XCTAssertTrue(state.builtSites.contains("creek"))

        for action in [CommonwealthAction.forage, .gatherTimber, .quarryStone, .patrol] {
            XCTAssertThrowsError(try CommonwealthEngine.resolve(action, in: state, availableXP: 0))
        }
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.acceptCharter, in: state, availableXP: 100))
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.restoreWater, in: state, availableXP: 100))
    }

    func testBuildingsChangeYieldsAndCrossingChoiceIsExclusive() throws {
        let base = try settledValley()
        var gardens = try CommonwealthEngine.resolve(.buildGarden, in: base, availableXP: 100)
        let gardenStores = gardens.supplies
        gardens = try CommonwealthEngine.resolve(.forage, in: gardens, availableXP: 100)
        XCTAssertEqual(gardens.supplies - gardenStores, 6)
        let unplanted = try CommonwealthEngine.resolve(.forage, in: base, availableXP: 100)
        XCTAssertEqual(unplanted.supplies - base.supplies, 3)

        var lumber = try CommonwealthEngine.resolve(.buildLumberCamp, in: base, availableXP: 100)
        let woodBefore = lumber.timber
        lumber = try CommonwealthEngine.resolve(.gatherTimber, in: lumber, availableXP: 100)
        XCTAssertEqual(lumber.timber - woodBefore, 7)
        XCTAssertEqual(lumber.population, base.population + 3)

        var crossing = base
        crossing.claimedSites.insert(.crossing)
        var trade = try CommonwealthEngine.resolve(.buildTradingPost, in: crossing, availableXP: 100)
        let storesBefore = trade.supplies
        trade = try CommonwealthEngine.resolve(.gatherTimber, in: trade, availableXP: 100)
        XCTAssertEqual(trade.supplies - storesBefore, 2)
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.buildWatchtower, in: trade, availableXP: 100))

        var defense = try CommonwealthEngine.resolve(.buildWatchtower, in: crossing, availableXP: 100)
        defense = try CommonwealthEngine.resolve(.patrol, in: defense, availableXP: 100)
        XCTAssertEqual(defense.combat?.playerMaximumHealth, 18)
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.buildTradingPost, in: defense, availableXP: 100))
    }

    func testResourceShortagesAlwaysHaveRenewablePaidRecovery() throws {
        var state = try settledValley()
        state.timber = 0
        state.stone = 0
        state.supplies = 0
        XCTAssertNotNil(CommonwealthEngine.blocker(for: .buildLumberCamp, in: state, availableXP: 100))
        state = try CommonwealthEngine.resolve(.gatherTimber, in: state, availableXP: 100)
        state = try CommonwealthEngine.resolve(.gatherTimber, in: state, availableXP: 100)
        state = try CommonwealthEngine.resolve(.quarryStone, in: state, availableXP: 100)
        state = try CommonwealthEngine.resolve(.forage, in: state, availableXP: 100)
        state = try CommonwealthEngine.resolve(.buildLumberCamp, in: state, availableXP: 100)
        XCTAssertTrue(state.buildings.contains(.lumberCamp))
        XCTAssertGreaterThanOrEqual(state.timber, 0)
        XCTAssertGreaterThanOrEqual(state.stone, 0)
        XCTAssertGreaterThan(state.supplies, 0)
    }

    func testTacticsRespondDifferentlyToTelegraphedIntent() throws {
        var strike = try CommonwealthEngine.resolve(.patrol, in: settledValley(), availableXP: 100)
        strike.combat?.intent = .strike
        let guarded = try CommonwealthEngine.fight(.guard, in: strike)
        let attacked = try CommonwealthEngine.fight(.attack, in: strike)
        XCTAssertEqual(guarded.combat?.playerHealth, 14)
        XCTAssertEqual(attacked.combat?.playerHealth, 10)
        XCTAssertLessThan(try XCTUnwrap(attacked.combat?.enemyHealth), try XCTUnwrap(guarded.combat?.enemyHealth))

        var braced = strike
        braced.combat?.intent = .brace
        let flanked = try CommonwealthEngine.fight(.flank, in: braced)
        let frontal = try CommonwealthEngine.fight(.attack, in: braced)
        XCTAssertEqual(flanked.combat?.enemyHealth, 8)
        XCTAssertEqual(frontal.combat?.enemyHealth, 12)
        XCTAssertNotEqual(flanked.combat?.playerLane, braced.combat?.playerLane)

        var aimed = strike
        aimed.combat?.intent = .aim
        XCTAssertEqual(try CommonwealthEngine.fight(.flank, in: aimed).combat?.playerHealth, 14)
        XCTAssertEqual(try CommonwealthEngine.fight(.attack, in: aimed).combat?.playerHealth, 9)
    }

    func testCombatRestoresExactlyAndDoesNotChargePerTurn() throws {
        var state = try CommonwealthEngine.resolve(.patrol, in: settledValley(), availableXP: 100)
        state = try CommonwealthEngine.fight(.attack, in: state)
        let restored = try JSONDecoder().decode(CommonwealthState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
        XCTAssertEqual(
            try CommonwealthEngine.fight(.flank, in: restored),
            try CommonwealthEngine.fight(.flank, in: state)
        )
        let rallied = try CommonwealthEngine.fight(.rally, in: restored)
        XCTAssertEqual(rallied.xpSpent, state.xpSpent)
        XCTAssertThrowsError(try CommonwealthEngine.fight(.rally, in: rallied))
        XCTAssertThrowsError(try CommonwealthEngine.travel(to: .homestead, in: rallied))
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.forage, in: rallied, availableXP: 100))
    }

    func testSideCoverReducesStrikeAndAimedDamageAndFlankingLeavesTargetLane() throws {
        var openRoad = try CommonwealthEngine.resolve(.patrol, in: settledValley(), availableXP: 100)
        openRoad.combat?.intent = .strike
        var inCover = openRoad
        inCover.combat?.playerLane = 0
        inCover.combat?.enemyLane = 0
        XCTAssertEqual(try CommonwealthEngine.fight(.attack, in: inCover).combat?.playerHealth, 11)
        XCTAssertEqual(try CommonwealthEngine.fight(.attack, in: openRoad).combat?.playerHealth, 10)

        inCover.combat?.intent = .aim
        XCTAssertEqual(try CommonwealthEngine.fight(.attack, in: inCover).combat?.playerHealth, 10)
        let evaded = try CommonwealthEngine.fight(.flank, in: inCover)
        XCTAssertEqual(evaded.combat?.playerHealth, 14)
        XCTAssertNotEqual(evaded.combat?.playerLane, inCover.combat?.enemyLane)
    }

    func testDefeatAndRetreatKeepLandAndAllowFullHealthRetry() throws {
        var state = try CommonwealthEngine.resolve(.patrol, in: settledValley(), availableXP: 100)
        state.combat?.playerHealth = 1
        state.combat?.intent = .rush
        let buildings = state.buildings
        let supplies = state.supplies
        let defeated = try CommonwealthEngine.fight(.attack, in: state)
        XCTAssertNil(defeated.combat)
        XCTAssertEqual(defeated.currentSite, .homestead)
        XCTAssertEqual(defeated.buildings, buildings)
        XCTAssertEqual(defeated.supplies, supplies)
        XCTAssertEqual(defeated.xpSpent, state.xpSpent)

        let retried = try CommonwealthEngine.resolve(.patrol, in: defeated, availableXP: 6)
        XCTAssertEqual(retried.combat?.playerHealth, retried.combat?.playerMaximumHealth)
        XCTAssertEqual(retried.xpSpent, state.xpSpent + 6)
        let retreated = try CommonwealthEngine.fight(.retreat, in: retried)
        XCTAssertNil(retreated.combat)
        XCTAssertEqual(retreated.supplies, supplies)
        XCTAssertEqual(retreated.xpSpent, retried.xpSpent)
        XCTAssertThrowsError(try CommonwealthEngine.fight(.attack, in: retreated))
    }

    func testCompletePatrolRewardsOnlyOnceAndUnlocksCrossing() throws {
        var state = try CommonwealthEngine.resolve(.patrol, in: settledValley(), availableXP: 100)
        let supplies = state.supplies
        let xpSpent = state.xpSpent
        for _ in 0..<40 {
            guard let combat = state.combat else { break }
            let tactic: CommonwealthTactic
            switch combat.intent {
            case .strike, .rush: tactic = .guard
            case .brace, .aim: tactic = .flank
            }
            state = try CommonwealthEngine.fight(tactic, in: state)
        }
        XCTAssertNil(state.combat)
        XCTAssertEqual(state.patrolsWon, 1)
        XCTAssertTrue(state.claimedSites.contains(.crossing))
        XCTAssertEqual(state.supplies, supplies + 4)
        XCTAssertEqual(state.xpSpent, xpSpent)
        XCTAssertThrowsError(try CommonwealthEngine.fight(.attack, in: state))
    }

    func testCommonwealthRequiresEconomyAndCrossingAndPreservesRenewablePlay() throws {
        var state = try settledValley()
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.foundCommonwealth, in: state, availableXP: 100))
        state = try CommonwealthEngine.resolve(.buildLumberCamp, in: state, availableXP: 100)
        state = try CommonwealthEngine.resolve(.buildQuarry, in: state, availableXP: 100)
        state.claimedSites.insert(.crossing)
        state = try CommonwealthEngine.resolve(.buildTradingPost, in: state, availableXP: 100)
        state = try CommonwealthEngine.resolve(.foundCommonwealth, in: state, availableXP: 100)
        XCTAssertTrue(state.buildings.contains(.commons))
        XCTAssertEqual(state.population, 15)
        XCTAssertTrue(CommonwealthEngine.actions(at: .pinewood, in: state).contains(.gatherTimber))
        XCTAssertTrue(CommonwealthEngine.actions(at: .crossing, in: state).contains(.patrol))
    }

    func testHundredsOfActionsKeepSaveSmallAndHistoryBounded() throws {
        var state = try settledValley()
        for _ in 0..<250 {
            state = try CommonwealthEngine.resolve(.forage, in: state, availableXP: 3)
        }
        XCTAssertEqual(state.history.count, 40)
        XCTAssertEqual(Set(state.history.map(\.id)).count, 40)
        XCTAssertLessThan(try JSONEncoder().encode(state).count, 50_000)
        let beforeTravel = state
        state = try CommonwealthEngine.travel(to: .ridge, in: state)
        XCTAssertEqual(state.xpSpent, beforeTravel.xpSpent)
        XCTAssertEqual(state.supplies, beforeTravel.supplies)
        XCTAssertEqual(state.history, beforeTravel.history)
    }

    func testCouncilRotatesRealResourceAndTrustTradeoffsWithoutFreeRewards() throws {
        var state = try settledValley()
        state.buildings.insert(.commons)
        state.morale = 74
        XCTAssertEqual(Set(CommonwealthEngine.actions(at: .township, in: state)), [.repairCottages, .openHall])
        let openedHall = try CommonwealthEngine.resolve(.openHall, in: state, availableXP: 3)
        XCTAssertEqual(openedHall.supplies, state.supplies - 5)
        XCTAssertEqual(openedHall.timber, state.timber)
        state = try CommonwealthEngine.resolve(.repairCottages, in: state, availableXP: 3)
        XCTAssertEqual(state.morale, 82)
        XCTAssertEqual(state.timber, 44)
        XCTAssertEqual(state.councilDecisions, 1)
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.repairCottages, in: state, availableXP: 100))
        XCTAssertEqual(Set(CommonwealthEngine.actions(at: .township, in: state)), [.fundFreeBridge, .licenseCaravans])

        state = try CommonwealthEngine.resolve(.licenseCaravans, in: state, availableXP: 3)
        XCTAssertEqual(state.morale, 78)
        XCTAssertEqual(state.timber, 49)
        state = try CommonwealthEngine.resolve(.harvestGrove, in: state, availableXP: 3)
        XCTAssertEqual(state.morale, 70)
        XCTAssertEqual(state.councilDecisions, 3)
        XCTAssertEqual(Set(CommonwealthEngine.actions(at: .township, in: state)), [.repairCottages, .openHall])
        XCTAssertThrowsError(try CommonwealthEngine.resolve(.openHall, in: state, availableXP: 0))

        let untrustedTrip = try CommonwealthEngine.resolve(.gatherTimber, in: state, availableXP: 3)
        state.morale = 75
        let trustedTrip = try CommonwealthEngine.resolve(.gatherTimber, in: state, availableXP: 3)
        XCTAssertEqual(trustedTrip.supplies, untrustedTrip.supplies + 1)
    }

    private func settledValley() throws -> CommonwealthState {
        var state = try CommonwealthEngine.resolve(.acceptCharter, in: .initial, availableXP: 0)
        state = try CommonwealthEngine.resolve(.restoreWater, in: state, availableXP: 3)
        state.timber = 50
        state.stone = 50
        state.supplies = 50
        return state
    }
}

@MainActor
final class CommonwealthStoreTests: XCTestCase {
    func testSevenDaysOfMealXPBankAcrossRelaunchAndLegacySpendIsPreserved() throws {
        let suiteName = "commonwealth-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let legacy = UserDefaultsAdventureStatePersistence(defaults: defaults)
        var oldAdventure = AdventureState.initial
        oldAdventure.energySpent = 6
        try legacy.save(oldAdventure)
        let legacyBytes = defaults.data(forKey: "adventure-state-v1")
        let persistence = UserDefaultsCommonwealthStatePersistence(defaults: defaults)
        let repository = try makeRepository()
        let store = makeStore(repository: repository, persistence: persistence, legacy: legacy)
        store.bootstrap()
        let template = try XCTUnwrap(SeedMealCatalog.templates.first)
        for day in 1...7 {
            store.log(draft: MealDraft(template: template), targetDayIdentifier: "2026-09-0\(day)")
        }
        XCTAssertEqual(store.resourceBalance, 21)
        XCTAssertEqual(store.commonwealthXPBalance, 15)
        store.performCommonwealth(.acceptCharter)
        store.performCommonwealth(.restoreWater)
        XCTAssertEqual(store.commonwealthXPBalance, 12)

        let reopened = makeStore(repository: repository, persistence: persistence, legacy: legacy)
        reopened.bootstrap()
        XCTAssertEqual(reopened.commonwealth, store.commonwealth)
        XCTAssertEqual(reopened.commonwealthXPBalance, 12)
        XCTAssertEqual(reopened.adventure, oldAdventure)
        XCTAssertEqual(defaults.data(forKey: "adventure-state-v1"), legacyBytes)
        XCTAssertNotNil(defaults.data(forKey: "commonwealth-state-v1"))
    }

    func testOverspendAndUndoCannotManufactureXP() throws {
        let repository = try makeRepository()
        let store = makeStore(repository: repository)
        store.bootstrap()
        let draft = MealDraft(template: try XCTUnwrap(SeedMealCatalog.templates.first))
        store.log(draft: draft)
        store.performCommonwealth(.acceptCharter)
        store.performCommonwealth(.restoreWater)
        let built = store.commonwealth
        store.performCommonwealth(.forage)
        XCTAssertEqual(store.commonwealth, built)
        XCTAssertEqual(store.commonwealthXPBalance, 0)
        XCTAssertNotNil(store.appError)

        store.undoRecent()
        XCTAssertEqual(store.resourceBalance, 0)
        XCTAssertEqual(store.commonwealthXPBalance, 0)
        store.log(draft: draft)
        XCTAssertEqual(store.commonwealthXPBalance, 0)
        store.log(draft: draft)
        XCTAssertEqual(store.commonwealthXPBalance, 3)
        store.performCommonwealth(.forage)
        XCTAssertEqual(store.commonwealthXPBalance, 0)
        XCTAssertEqual(store.commonwealth.xpSpent, 6)
    }

    func testFailedSaveLeavesWorldAndSpendUntouched() throws {
        let repository = try makeRepository()
        let persistence = FailingCommonwealthPersistence()
        let store = makeStore(repository: repository, persistence: persistence)
        store.bootstrap()
        store.log(draft: MealDraft(template: try XCTUnwrap(SeedMealCatalog.templates.first)))
        let initial = store.commonwealth
        store.performCommonwealth(.restoreWater)
        XCTAssertEqual(store.commonwealth, initial)
        XCTAssertEqual(store.commonwealthXPBalance, 3)
        XCTAssertNotNil(store.appError)
    }

    private func makeRepository() throws -> SwiftDataMealRepository {
        let container = try ModelContainer(
            for: MealEntryRecord.self, DayRecord.self, RewardRecord.self, SettingsRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataMealRepository(context: container.mainContext)
    }

    private func makeStore(
        repository: SwiftDataMealRepository,
        persistence: (any CommonwealthStatePersisting)? = nil,
        legacy: (any AdventureStatePersisting)? = nil
    ) -> MealTrackerStore {
        MealTrackerStore(
            repository: repository,
            clock: FixedClock(now: Date(timeIntervalSince1970: 1_789_128_000), timeZone: TimeZone(identifier: "UTC")!),
            voiceTranscriber: CommonwealthTestVoice(),
            venueResolver: CommonwealthTestVenue(),
            healthKit: CommonwealthTestHealth(),
            adventurePersistence: legacy ?? CommonwealthTestLegacyPersistence(),
            commonwealthPersistence: persistence ?? InMemoryCommonwealthStatePersistence()
        )
    }
}

@MainActor
private final class CommonwealthTestLegacyPersistence: AdventureStatePersisting {
    func load() -> AdventureState? { .initial }
    func save(_ state: AdventureState) throws {}
}

@MainActor
private final class FailingCommonwealthPersistence: CommonwealthStatePersisting {
    func load() -> CommonwealthState? {
        var state = CommonwealthState.initial
        state.introSeen = true
        return state
    }
    func save(_ state: CommonwealthState) throws { throw CocoaError(.fileWriteNoPermission) }
}

@MainActor
private final class CommonwealthTestVoice: VoiceTranscribing {
    var isRecording = false
    func requestAuthorization() async -> Bool { true }
    func start(onUpdate: @escaping (String) -> Void) throws { isRecording = true }
    func stop() { isRecording = false }
}

@MainActor
private final class CommonwealthTestVenue: VenueResolving {
    var authorization: LocationAuthorizationState = .authorized
    func resolveForegroundVenues() async throws -> [VenueCandidate] { [] }
}

@MainActor
private final class CommonwealthTestHealth: HealthKitReading {
    var isAvailable = true
    func requestReadAccess() async throws -> Bool { true }
    func currentSnapshot() async throws -> HealthContextSnapshot {
        HealthContextSnapshot(latestWeightKilograms: nil, stepsToday: nil, activeEnergyToday: nil, recentWorkoutCount: nil)
    }
}
