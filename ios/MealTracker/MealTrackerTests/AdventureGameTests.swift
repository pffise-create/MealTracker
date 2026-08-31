import XCTest
@testable import MealTracker

final class AdventureGameTests: XCTestCase {
    func testPrologueUnlocksRenewableExpeditions() throws {
        var state = AdventureState.initial
        state.hero.resolve = 20
        state = try AdventureEngine.resolve(.hireSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.trustSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.keepIlyra, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.turnStormKey, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.sealHollowCrown, in: state, availableEnergy: 100)

        XCTAssertEqual(state.energySpent, 15)
        XCTAssertEqual(state.companions.filter(\.isRecruited).count, 2)
        XCTAssertTrue(state.hasItem(.crownSeal))
        XCTAssertEqual(state.quests.last?.status, .complete)
        XCTAssertEqual(AdventureEngine.encounter(for: state).choices, [.beginFrontierExpedition])

        state = try AdventureEngine.resolve(.beginFrontierExpedition, in: state, availableEnergy: 100)
        XCTAssertEqual(state.scene, .frontier)
        XCTAssertEqual(state.frontier?.expeditionNumber, 1)
        XCTAssertEqual(AdventureEngine.encounter(for: state).choices.count, 2)
    }

    func testInsufficientEnergyCannotMutateStructuredState() {
        let original = AdventureState.initial
        XCTAssertThrowsError(try AdventureEngine.resolve(.hireSable, in: original, availableEnergy: 1)) { error in
            XCTAssertEqual(error as? AdventureGameError, .insufficientEnergy(required: 3, available: 1))
        }
        XCTAssertEqual(original, .initial)
    }

    func testDeathOffersResurrectionOrSuccessorWithoutErasingWorld() throws {
        var state = AdventureState.initial
        state.hero.resolve = 20
        state = try AdventureEngine.resolve(.hireSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.trustSable, in: state, availableEnergy: 100)
        state = try AdventureEngine.resolve(.keepIlyra, in: state, availableEnergy: 100)
        state.hero.resolve = -20
        let locationsBeforeDeath = state.discoveredLocations
        let inventoryBeforeDeath = state.inventory

        state = try AdventureEngine.resolve(.forceSpireDoor, in: state, availableEnergy: 100)
        XCTAssertFalse(state.hero.isAlive)
        XCTAssertEqual(Set(AdventureEngine.encounter(for: state).choices), [.resurrectAtEmberRoad, .nameSuccessor])

        state = try AdventureEngine.resolve(.nameSuccessor, in: state, availableEnergy: 100)
        XCTAssertTrue(state.hero.isAlive)
        XCTAssertEqual(state.hero.title, "Heir to the Ember Map")
        XCTAssertTrue(state.discoveredLocations.isSuperset(of: locationsBeforeDeath))
        XCTAssertEqual(state.inventory, inventoryBeforeDeath)
    }

    func testSeededDiceAreRepeatableAndForecastMatchesRollProfile() throws {
        let first = try AdventureEngine.resolve(.hireSable, in: .initial, availableEnergy: 100)
        let second = try AdventureEngine.resolve(.hireSable, in: .initial, availableEnergy: 100)
        let bold = try AdventureEngine.resolve(.takeOldRoad, in: .initial, availableEnergy: 100)

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first.latestOutcome?.roll?.die, bold.latestOutcome?.roll?.die)
        XCTAssertEqual(first.latestOutcome?.roll?.modifier, AdventureEngine.forecast(for: .hireSable, in: .initial)?.modifier)
        XCTAssertEqual(first.latestOutcome?.roll?.target, AdventureEngine.forecast(for: .hireSable, in: .initial)?.target)
        XCTAssertGreaterThan(AdventureEngine.forecast(for: .hireSable, in: .initial)?.chancePercent ?? 0, 0)
        XCTAssertEqual(try JSONDecoder().decode(AdventureState.self, from: JSONEncoder().encode(first)), first)
    }

    func testThreeEncounterRunGradesTrainsAndRenews() throws {
        var state = AdventureState.initial
        state.hero.resolve = 20
        state.frontier = .initial
        state.scene = .frontier

        for expectedStep in 1...3 {
            let choice = try XCTUnwrap(AdventureEngine.encounter(for: state).choices.first)
            state = try AdventureEngine.resolve(choice, in: state, availableEnergy: 100)
            XCTAssertEqual(state.frontier?.step, expectedStep)
        }

        XCTAssertEqual(state.scene, .frontierReward)
        XCTAssertEqual(state.frontier?.grade, "A")
        let renown = try XCTUnwrap(state.frontier?.renown)
        state = try AdventureEngine.resolve(.trainWayfinder, in: state, availableEnergy: 100)
        XCTAssertEqual(state.scene, .frontier)
        XCTAssertEqual(state.frontier?.expeditionNumber, 2)
        XCTAssertEqual(state.frontier?.step, 0)
        XCTAssertEqual(state.frontier?.rank(.wayfinder), 1)
        XCTAssertEqual(state.frontier?.renown, renown)
        XCTAssertEqual(state.frontier?.runScore, 0)
    }

    func testTraitsChangeOddsAndCapWithoutEndingPlay() throws {
        var state = AdventureState.initial
        state.frontier = .initial
        state.frontier?.traits[1].rank = 1
        state.scene = .frontier
        let careful = try XCTUnwrap(AdventureEngine.encounter(for: state).choices.first)
        var untrained = state
        untrained.frontier?.traits[1].rank = 0
        XCTAssertEqual(
            AdventureEngine.forecast(for: careful, in: state)?.modifier,
            (AdventureEngine.forecast(for: careful, in: untrained)?.modifier ?? 0) + 1
        )

        state.frontier?.traits[1].rank = 2
        state.frontier?.step = 3
        state.frontier?.renown = 4
        state.scene = .frontierReward
        state = try AdventureEngine.resolve(.trainWayfinder, in: state, availableEnergy: 100)
        XCTAssertEqual(state.frontier?.rank(.wayfinder), 2)
        XCTAssertEqual(state.frontier?.renown, 6)
        XCTAssertEqual(state.scene, .frontier)
    }
}
