import XCTest
@testable import MealTracker

final class AdventureGameTests: XCTestCase {
    func testSuccessfulQuestRecruitsBothCompanionsAndStopsAtEpilogue() throws {
        var state = AdventureState.initial

        state = try AdventureEngine.resolve(.hireSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.trustSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.keepIlyra, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.turnStormKey, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.sealHollowCrown, in: state, availableEnergy: 100)

        XCTAssertEqual(state.energySpent, 15)
        XCTAssertEqual(state.companions.filter(\.isRecruited).count, 2)
        XCTAssertTrue(state.hasItem(.crownSeal))
        XCTAssertEqual(state.quests.last?.status, .complete)
        XCTAssertTrue(AdventureEngine.encounter(for: state).choices.isEmpty)
        XCTAssertEqual(AdventureEngine.encounter(for: state).title, "The road remains on the map")
    }

    func testInsufficientEnergyCannotMutateStructuredState() {
        let original = AdventureState.initial

        XCTAssertThrowsError(
            try AdventureEngine.resolve(.hireSable, in: original, availableEnergy: 1)
        ) { error in
            XCTAssertEqual(error as? AdventureGameError, .insufficientEnergy(required: 2, available: 1))
        }
        XCTAssertEqual(original, .initial)
    }

    func testLethalChoiceAndOneUseResurrectionPreserveWorldProgress() throws {
        var state = AdventureState.initial
        state = try AdventureEngine.resolve(.hireSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.trustSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.keepIlyra, in: state, availableEnergy: 100)
        let locationsBeforeDeath = state.discoveredLocations
        let companionsBeforeDeath = state.companions

        state = try AdventureEngine.resolve(.forceSpireDoor, in: state, availableEnergy: 100)

        XCTAssertFalse(state.hero.isAlive)
        XCTAssertEqual(state.scene, .dead)
        XCTAssertEqual(state.hero.deaths, 1)
        XCTAssertEqual(state.discoveredLocations, locationsBeforeDeath)
        XCTAssertEqual(state.companions, companionsBeforeDeath)

        state = try AdventureEngine.resolve(.resurrectAtEmberRoad, in: state, availableEnergy: 100)

        XCTAssertTrue(state.hero.isAlive)
        XCTAssertEqual(state.scene, .hollowCrown)
        XCTAssertTrue(state.resurrectionUsed)
        XCTAssertFalse(state.hasItem(.emberShard))
        XCTAssertEqual(state.discoveredLocations, locationsBeforeDeath)
        XCTAssertEqual(state.companions, companionsBeforeDeath)

        state = try AdventureEngine.resolve(.forceSpireDoor, in: state, availableEnergy: 100)
        XCTAssertFalse(state.hero.isAlive)
        XCTAssertTrue(AdventureEngine.encounter(for: state).choices.isEmpty)
    }

    func testDiceAndStateRoundTripAreDeterministic() throws {
        let first = try AdventureEngine.resolve(.hireSable, in: .initial, availableEnergy: 100)
        let second = try AdventureEngine.resolve(.hireSable, in: .initial, availableEnergy: 100)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.latestOutcome?.roll, AdventureRoll(die: 14, modifier: 2, target: 12))

        let data = try JSONEncoder().encode(first)
        let decoded = try JSONDecoder().decode(AdventureState.self, from: data)
        XCTAssertEqual(decoded, first)
    }
}
