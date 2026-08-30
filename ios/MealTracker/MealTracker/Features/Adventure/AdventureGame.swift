import Foundation

enum AdventureScene: String, Codable, Equatable, Sendable {
    case ridgeGate
    case starfallFen
    case saltSpire
    case hollowCrown
    case homecoming
    case dead
}

enum AdventureLocationID: String, Codable, CaseIterable, Equatable, Sendable {
    case emberwatch
    case ridgeGate
    case starfallFen
    case saltSpire
    case hollowCrown

    var name: String {
        switch self {
        case .emberwatch: "Emberwatch"
        case .ridgeGate: "Ridge Gate"
        case .starfallFen: "Starfall Fen"
        case .saltSpire: "Salt Spire"
        case .hollowCrown: "Hollow Crown"
        }
    }

    var subtitle: String {
        switch self {
        case .emberwatch: "Last light on the coast"
        case .ridgeGate: "A road erased from maps"
        case .starfallFen: "Lanterns beneath black water"
        case .saltSpire: "The storm keeps its oath"
        case .hollowCrown: "The buried court"
        }
    }
}

enum AdventureCompanionID: String, Codable, CaseIterable, Equatable, Sendable {
    case sable
    case ilyra

    var name: String {
        switch self {
        case .sable: "Sable Vey"
        case .ilyra: "Ilyra Morn"
        }
    }

    var role: String {
        switch self {
        case .sable: "Ridge pathfinder"
        case .ilyra: "Oathbound physician"
        }
    }

    var ability: String {
        switch self {
        case .sable: "Wayfinder · +2 on routes and traps"
        case .ilyra: "Field rite · steadies one failed crossing"
        }
    }

    var lockedCopy: String {
        switch self {
        case .sable: "A hired blade watches the western gate."
        case .ilyra: "Someone is keeping lanterns lit in the fen."
        }
    }
}

struct AdventureCompanion: Codable, Equatable, Identifiable, Sendable {
    var id: AdventureCompanionID
    var isRecruited: Bool
    var bond: Int
}

enum AdventureItemID: String, Codable, Equatable, Sendable {
    case emberShard
    case fenGlass
    case stormKey
    case crownSeal

    var name: String {
        switch self {
        case .emberShard: "Ember shard"
        case .fenGlass: "Fen-glass phial"
        case .stormKey: "Storm key"
        case .crownSeal: "Seal of the Hollow Crown"
        }
    }

    var detail: String {
        switch self {
        case .emberShard: "A one-use road back from death."
        case .fenGlass: "Cold light, captured without flame."
        case .stormKey: "Opens what the Spire was built to guard."
        case .crownSeal: "Proof that the buried court is quiet."
        }
    }
}

struct AdventureItem: Codable, Equatable, Identifiable, Sendable {
    var id: AdventureItemID
    var quantity: Int
}

enum AdventureQuestStatus: String, Codable, Equatable, Sendable {
    case active
    case complete
    case locked
}

struct AdventureQuestStep: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var title: String
    var detail: String
    var status: AdventureQuestStatus
}

struct AdventureHero: Codable, Equatable, Sendable {
    var name: String
    var title: String
    var health: Int
    var maximumHealth: Int
    var resolve: Int
    var isAlive: Bool
    var deaths: Int

    static let initial = AdventureHero(
        name: "Aren Vale",
        title: "Cartographer of Emberwatch",
        health: 7,
        maximumHealth: 7,
        resolve: 2,
        isAlive: true,
        deaths: 0
    )
}

struct AdventureRoll: Codable, Equatable, Sendable {
    var die: Int
    var modifier: Int
    var target: Int

    var total: Int { die + modifier }
    var succeeded: Bool { total >= target }
}

struct AdventureOutcome: Codable, Equatable, Sendable {
    var title: String
    var detail: String
    var roll: AdventureRoll?
    var energyCost: Int
    var choiceID: AdventureChoiceID
}

struct AdventureState: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version: Int
    var hero: AdventureHero
    var scene: AdventureScene
    var returnSceneAfterDeath: AdventureScene?
    var discoveredLocations: Set<AdventureLocationID>
    var companions: [AdventureCompanion]
    var inventory: [AdventureItem]
    var quests: [AdventureQuestStep]
    var energySpent: Int
    var decisionsMade: Int
    var resurrectionUsed: Bool
    var latestOutcome: AdventureOutcome?

    static let initial = AdventureState(
        version: currentVersion,
        hero: .initial,
        scene: .ridgeGate,
        returnSceneAfterDeath: nil,
        discoveredLocations: [.emberwatch, .ridgeGate],
        companions: AdventureCompanionID.allCases.map {
            AdventureCompanion(id: $0, isRecruited: false, bond: 0)
        },
        inventory: [AdventureItem(id: .emberShard, quantity: 1)],
        quests: [
            AdventureQuestStep(
                id: "trace-road",
                title: "Trace the vanished road",
                detail: "Find a living route beyond Ridge Gate.",
                status: .active
            ),
            AdventureQuestStep(
                id: "light-fen",
                title: "Follow the drowned lanterns",
                detail: "Learn why Starfall Fen still burns blue.",
                status: .locked
            ),
            AdventureQuestStep(
                id: "seal-court",
                title: "Enter the buried court",
                detail: "Carry the storm key beneath the Hollow Crown.",
                status: .locked
            )
        ],
        energySpent: 0,
        decisionsMade: 0,
        resurrectionUsed: false,
        latestOutcome: nil
    )

    func companion(_ id: AdventureCompanionID) -> AdventureCompanion? {
        companions.first { $0.id == id }
    }

    func hasItem(_ id: AdventureItemID) -> Bool {
        inventory.contains { $0.id == id && $0.quantity > 0 }
    }
}

enum AdventureChoiceID: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case hireSable
    case takeOldRoad
    case trustSable
    case crossFenAlone
    case keepIlyra
    case takeFenGlass
    case turnStormKey
    case forceSpireDoor
    case sealHollowCrown
    case claimHollowCrown
    case resurrectAtEmberRoad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hireSable: "Hire the pathfinder"
        case .takeOldRoad: "Take the old road alone"
        case .trustSable: "Trust Sable’s marked stones"
        case .crossFenAlone: "Cross by the drowned causeway"
        case .keepIlyra: "Ask Ilyra to join the expedition"
        case .takeFenGlass: "Accept the phial and part ways"
        case .turnStormKey: "Let the storm key choose the door"
        case .forceSpireDoor: "Force the crownward door"
        case .sealHollowCrown: "Seal the court with both oaths"
        case .claimHollowCrown: "Take the crown for Emberwatch"
        case .resurrectAtEmberRoad: "Walk the Ember Road"
        }
    }

    var approach: String {
        switch self {
        case .hireSable: "Safer route · may recruit Sable"
        case .takeOldRoad: "Uncertain route · keep your own counsel"
        case .trustSable: "Pathfinder advantage · reach the lantern keeper"
        case .crossFenAlone: "High risk · a direct line through the water"
        case .keepIlyra: "Recruit physician · strengthen the company"
        case .takeFenGlass: "Gain an item · remain a solitary company"
        case .turnStormKey: "Measured risk · listen to the mechanism"
        case .forceSpireDoor: "Lethal risk · defy the storm oath"
        case .sealHollowCrown: "Company advantage · end the breach"
        case .claimHollowCrown: "Lethal risk · seize forbidden power"
        case .resurrectAtEmberRoad: "One use · consume the ember shard"
        }
    }

    var energyCost: Int {
        switch self {
        case .hireSable, .takeOldRoad: 2
        case .trustSable, .crossFenAlone: 3
        case .keepIlyra, .takeFenGlass: 2
        case .turnStormKey, .forceSpireDoor: 4
        case .sealHollowCrown, .claimHollowCrown: 4
        case .resurrectAtEmberRoad: 6
        }
    }
}

struct AdventureEncounter: Equatable, Sendable {
    var eyebrow: String
    var title: String
    var narration: String
    var location: AdventureLocationID
    var choices: [AdventureChoiceID]
}

enum AdventureGameError: LocalizedError, Equatable {
    case insufficientEnergy(required: Int, available: Int)
    case choiceUnavailable
    case resurrectionUnavailable

    var errorDescription: String? {
        switch self {
        case let .insufficientEnergy(required, available):
            "This choice needs \(required) energy. \(available) is banked; logging another eating occasion will add more."
        case .choiceUnavailable:
            "That path is no longer available."
        case .resurrectionUnavailable:
            "The Ember Road has already closed. World progress remains preserved."
        }
    }
}

enum AdventureEngine {
    static func encounter(for state: AdventureState) -> AdventureEncounter {
        switch state.scene {
        case .ridgeGate:
            return AdventureEncounter(
                eyebrow: "I · THE WESTERN VERGE",
                title: "A road erased from maps",
                narration: "Beyond Ridge Gate, blue fire moves through the heather without heat. Sable Vey waits beneath the last milepost and names a price before the weather turns.",
                location: .ridgeGate,
                choices: [.hireSable, .takeOldRoad]
            )
        case .starfallFen:
            return AdventureEncounter(
                eyebrow: "II · STARFALL FEN",
                title: "Lanterns under black water",
                narration: "The causeway ends beneath a drowned orchard. A physician holds one lantern above the flood while something enormous circles below it.",
                location: .starfallFen,
                choices: state.companion(.sable)?.isRecruited == true
                    ? [.trustSable, .crossFenAlone]
                    : [.crossFenAlone]
            )
        case .saltSpire:
            return AdventureEncounter(
                eyebrow: "III · THE LANTERN KEEPER",
                title: "An oath before the storm",
                narration: "Ilyra Morn binds the wound at your side. She will open the Spire, but asks whether this expedition intends to return with witnesses—or only relics.",
                location: .saltSpire,
                choices: [.keepIlyra, .takeFenGlass]
            )
        case .hollowCrown:
            return AdventureEncounter(
                eyebrow: "IV · SALT SPIRE",
                title: "The crownward door",
                narration: "Thunder lives inside the lock. The storm key turns against your hand, testing whether the company came as guests or thieves.",
                location: .saltSpire,
                choices: [.turnStormKey, .forceSpireDoor]
            )
        case .homecoming:
            if state.hasItem(.crownSeal) {
                return AdventureEncounter(
                    eyebrow: "EPILOGUE · EMBERWATCH",
                    title: "The road remains on the map",
                    narration: "The Hollow Crown is sealed. Sable marks the safe miles in black ink; Ilyra leaves one blue lantern in the western window. The first expedition is complete.",
                    location: .hollowCrown,
                    choices: []
                )
            }
            return AdventureEncounter(
                eyebrow: "V · THE BURIED COURT",
                title: "The Hollow Crown wakes",
                narration: "Beneath the Spire, an empty throne speaks with the voices of lost expeditions. One oath can close the breach. One choice can place its power in mortal hands.",
                location: .hollowCrown,
                choices: [.sealHollowCrown, .claimHollowCrown]
            )
        case .dead:
            return AdventureEncounter(
                eyebrow: "THE EMBER ROAD",
                title: "The map remembers your name",
                narration: "Aren Vale is dead. The region, companions, inventory, and every road already opened remain. One ember shard can call the cartographer home—once.",
                location: state.discoveredLocations.contains(.hollowCrown) ? .hollowCrown : .saltSpire,
                choices: state.resurrectionUsed || !state.hasItem(.emberShard) ? [] : [.resurrectAtEmberRoad]
            )
        }
    }

    static func resolve(
        _ choice: AdventureChoiceID,
        in original: AdventureState,
        availableEnergy: Int
    ) throws -> AdventureState {
        let validChoices = encounter(for: original).choices
        guard validChoices.contains(choice) else { throw AdventureGameError.choiceUnavailable }
        guard availableEnergy >= choice.energyCost else {
            throw AdventureGameError.insufficientEnergy(required: choice.energyCost, available: availableEnergy)
        }

        var state = original
        state.energySpent += choice.energyCost
        state.decisionsMade += 1

        switch choice {
        case .hireSable:
            let roll = AdventureRoll(die: 14, modifier: state.hero.resolve, target: 12)
            recruit(.sable, bond: 1, in: &state)
            discover(.starfallFen, in: &state)
            completeQuest("trace-road", unlock: "light-fen", in: &state)
            state.scene = .starfallFen
            state.latestOutcome = outcome(
                "Terms accepted",
                "Sable finds the vanished road before the rain closes it. The pathfinder joins your company.",
                roll,
                choice
            )
        case .takeOldRoad:
            let roll = AdventureRoll(die: 7, modifier: state.hero.resolve, target: 12)
            state.hero.health = max(1, state.hero.health - 2)
            discover(.starfallFen, in: &state)
            completeQuest("trace-road", unlock: "light-fen", in: &state)
            state.scene = .starfallFen
            state.latestOutcome = outcome(
                "The road takes its toll",
                "You reach the fen without a guide, bloodied by shale and two hours behind the storm.",
                roll,
                choice
            )
        case .trustSable:
            let roll = AdventureRoll(die: 12, modifier: state.hero.resolve + 2, target: 13)
            discover(.saltSpire, in: &state)
            state.scene = .saltSpire
            state.latestOutcome = outcome(
                "The marked stones hold",
                "Sable reads the water correctly. You reach Ilyra’s lantern with dry powder and an intact company.",
                roll,
                choice
            )
        case .crossFenAlone:
            let roll = AdventureRoll(die: 5, modifier: state.hero.resolve, target: 12)
            state.hero.health = max(1, state.hero.health - 3)
            addItem(.fenGlass, in: &state)
            discover(.saltSpire, in: &state)
            state.scene = .saltSpire
            state.latestOutcome = outcome(
                "The causeway gives way",
                "You escape the water with a cold phial in hand, but the thing below leaves a wound that will not warm.",
                roll,
                choice
            )
        case .keepIlyra:
            let roll = AdventureRoll(die: 11, modifier: state.hero.resolve + 1, target: 11)
            recruit(.ilyra, bond: 1, in: &state)
            addItem(.stormKey, in: &state)
            completeQuest("light-fen", unlock: "seal-court", in: &state)
            state.scene = .hollowCrown
            state.latestOutcome = outcome(
                "A second oath joins yours",
                "Ilyra enters the company and places the storm key in your palm. It beats like a quiet heart.",
                roll,
                choice
            )
        case .takeFenGlass:
            let roll = AdventureRoll(die: 10, modifier: state.hero.resolve, target: 11)
            addItem(.fenGlass, in: &state)
            addItem(.stormKey, in: &state)
            completeQuest("light-fen", unlock: "seal-court", in: &state)
            state.scene = .hollowCrown
            state.latestOutcome = outcome(
                "A colder bargain",
                "Ilyra gives you the key but remains with the wounded. The Spire will be faced without her oath.",
                roll,
                choice
            )
        case .turnStormKey:
            let companionBonus = state.companion(.ilyra)?.isRecruited == true ? 2 : 0
            let roll = AdventureRoll(die: 13, modifier: state.hero.resolve + companionBonus, target: 15)
            discover(.hollowCrown, in: &state)
            state.scene = .homecoming
            state.latestOutcome = outcome(
                roll.succeeded ? "The Spire recognizes the oath" : "The lock answers in thunder",
                roll.succeeded
                    ? "The crownward door opens without breaking. Far below, a court exhales after a century."
                    : "The door opens, but the backlash leaves your company shaken and Aren wounded.",
                roll,
                choice
            )
            if !roll.succeeded { state.hero.health = max(1, state.hero.health - 2) }
        case .forceSpireDoor:
            let roll = AdventureRoll(die: 3, modifier: state.hero.resolve, target: 17)
            killHero(returningTo: .hollowCrown, in: &state)
            state.latestOutcome = outcome(
                "The storm oath collects its debt",
                "The crownward door opens. Aren Vale does not cross its threshold alive.",
                roll,
                choice
            )
        case .sealHollowCrown:
            let companyBonus = state.companions.filter(\.isRecruited).count * 2
            let roll = AdventureRoll(die: 14, modifier: state.hero.resolve + companyBonus, target: 16)
            if roll.succeeded {
                addItem(.crownSeal, in: &state)
                completeQuest("seal-court", unlock: nil, in: &state)
                state.scene = .homecoming
                state.latestOutcome = outcome(
                    "The breach is sealed",
                    "Every lantern in Emberwatch burns blue for one breath. The first expedition is complete; the region remembers what you chose.",
                    roll,
                    choice
                )
            } else {
                killHero(returningTo: .homecoming, in: &state)
                state.latestOutcome = outcome(
                    "The oath breaks",
                    "The court closes around Aren before the final word can be spoken.",
                    roll,
                    choice
                )
            }
        case .claimHollowCrown:
            let roll = AdventureRoll(die: 4, modifier: state.hero.resolve, target: 18)
            killHero(returningTo: .homecoming, in: &state)
            state.latestOutcome = outcome(
                "No living sovereign",
                "The Crown accepts the claim and rejects the claimant. Aren’s map falls open at the road home.",
                roll,
                choice
            )
        case .resurrectAtEmberRoad:
            guard !state.resurrectionUsed, state.hasItem(.emberShard) else {
                throw AdventureGameError.resurrectionUnavailable
            }
            removeItem(.emberShard, in: &state)
            state.resurrectionUsed = true
            state.hero.isAlive = true
            state.hero.health = max(3, state.hero.maximumHealth / 2)
            state.scene = state.returnSceneAfterDeath ?? .hollowCrown
            state.returnSceneAfterDeath = nil
            state.latestOutcome = outcome(
                "Aren returns at first light",
                "The ember shard is gone. The map, company, and opened roads remain—and death will not offer this bargain twice.",
                nil,
                choice
            )
        }

        return state
    }

    private static func outcome(
        _ title: String,
        _ detail: String,
        _ roll: AdventureRoll?,
        _ choice: AdventureChoiceID
    ) -> AdventureOutcome {
        AdventureOutcome(title: title, detail: detail, roll: roll, energyCost: choice.energyCost, choiceID: choice)
    }

    private static func recruit(_ id: AdventureCompanionID, bond: Int, in state: inout AdventureState) {
        guard let index = state.companions.firstIndex(where: { $0.id == id }) else { return }
        state.companions[index].isRecruited = true
        state.companions[index].bond = max(state.companions[index].bond, bond)
    }

    private static func discover(_ id: AdventureLocationID, in state: inout AdventureState) {
        state.discoveredLocations.insert(id)
    }

    private static func addItem(_ id: AdventureItemID, in state: inout AdventureState) {
        if let index = state.inventory.firstIndex(where: { $0.id == id }) {
            state.inventory[index].quantity += 1
        } else {
            state.inventory.append(AdventureItem(id: id, quantity: 1))
        }
    }

    private static func removeItem(_ id: AdventureItemID, in state: inout AdventureState) {
        guard let index = state.inventory.firstIndex(where: { $0.id == id }) else { return }
        state.inventory[index].quantity -= 1
        if state.inventory[index].quantity <= 0 { state.inventory.remove(at: index) }
    }

    private static func completeQuest(_ id: String, unlock nextID: String?, in state: inout AdventureState) {
        if let index = state.quests.firstIndex(where: { $0.id == id }) {
            state.quests[index].status = .complete
        }
        if let nextID, let nextIndex = state.quests.firstIndex(where: { $0.id == nextID }) {
            state.quests[nextIndex].status = .active
        }
    }

    private static func killHero(returningTo scene: AdventureScene, in state: inout AdventureState) {
        state.hero.health = 0
        state.hero.isAlive = false
        state.hero.deaths += 1
        state.returnSceneAfterDeath = scene
        state.scene = .dead
    }
}

@MainActor
protocol AdventureStatePersisting: AnyObject {
    func load() -> AdventureState?
    func save(_ state: AdventureState) throws
}

@MainActor
final class UserDefaultsAdventureStatePersistence: AdventureStatePersisting {
    private let defaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, key: String = "adventure-state-v1") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> AdventureState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(AdventureState.self, from: data)
    }

    func save(_ state: AdventureState) throws {
        defaults.set(try encoder.encode(state), forKey: key)
    }
}
