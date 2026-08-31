import Foundation

enum AdventureScene: String, Codable, Equatable, Sendable {
    case ridgeGate
    case starfallFen
    case saltSpire
    case hollowCrown
    case homecoming
    case frontier
    case frontierReward
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

enum AdventureTraitID: String, Codable, CaseIterable, Equatable, Identifiable, Sendable {
    case ironWill
    case wayfinder
    case oathkeeper

    var id: String { rawValue }
    var name: String {
        switch self {
        case .ironWill: "Iron Will"
        case .wayfinder: "Wayfinder"
        case .oathkeeper: "Oathkeeper"
        }
    }
    var detail: String {
        switch self {
        case .ironWill: "+1 on bold approaches per rank"
        case .wayfinder: "+1 on careful approaches per rank"
        case .oathkeeper: "+1 with companions per rank"
        }
    }
}

struct AdventureTrait: Codable, Equatable, Identifiable, Sendable {
    var id: AdventureTraitID
    var rank: Int
}

struct FrontierProgress: Codable, Equatable, Sendable {
    var expeditionNumber: Int
    var step: Int
    var seed: UInt64
    var renown: Int
    var runScore: Int
    var traits: [AdventureTrait]

    static let initial = FrontierProgress(
        expeditionNumber: 1,
        step: 0,
        seed: 0xC0FFEE,
        renown: 0,
        runScore: 0,
        traits: AdventureTraitID.allCases.map { AdventureTrait(id: $0, rank: 0) }
    )

    func rank(_ id: AdventureTraitID) -> Int {
        traits.first(where: { $0.id == id })?.rank ?? 0
    }

    var grade: String {
        switch runScore {
        case 12...: "S"
        case 9...: "A"
        case 6...: "B"
        default: "C"
        }
    }
}

struct AdventureChoiceForecast: Equatable, Sendable {
    var chancePercent: Int
    var modifier: Int
    var target: Int

    var summary: String { "\(chancePercent)% · d20 \(modifier >= 0 ? "+" : "")\(modifier) vs \(target)" }
}

struct AdventureState: Codable, Equatable, Sendable {
    static let currentVersion = 2

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
    var frontier: FrontierProgress?

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
        latestOutcome: nil,
        frontier: nil
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
    case beginFrontierExpedition
    case readTheTrail
    case breakTheWard
    case rallyCompany
    case claimRelic
    case guardCrossing
    case chaseOmen
    case trainIronWill
    case trainWayfinder
    case trainOathkeeper
    case nameSuccessor

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
        case .beginFrontierExpedition: "Chart the next expedition"
        case .readTheTrail: "Read the hidden trail"
        case .breakTheWard: "Break through the ward"
        case .rallyCompany: "Rally the company"
        case .claimRelic: "Reach for the relic"
        case .guardCrossing: "Secure the crossing"
        case .chaseOmen: "Chase the blue omen"
        case .trainIronWill: "Temper Iron Will"
        case .trainWayfinder: "Hone Wayfinder"
        case .trainOathkeeper: "Deepen Oathkeeper"
        case .nameSuccessor: "Name a successor"
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
        case .beginFrontierExpedition: "Renewable run · three encounters and a reward"
        case .readTheTrail: "Careful · higher odds, stronger bonds"
        case .breakTheWard: "Bold · lower cost, greater renown"
        case .rallyCompany: "Careful · companions improve the roll"
        case .claimRelic: "Bold · risk health for relics and renown"
        case .guardCrossing: "Careful · protect the company"
        case .chaseOmen: "Bold · pursue a high-grade finish"
        case .trainIronWill: "Rank up bold approaches · cap 2"
        case .trainWayfinder: "Rank up careful approaches · cap 2"
        case .trainOathkeeper: "Rank up companion approaches · cap 2"
        case .nameSuccessor: "Free · preserve the world, lose one bond rank"
        }
    }

    var energyCost: Int {
        switch self {
        case .hireSable, .trustSable, .keepIlyra, .turnStormKey, .sealHollowCrown: 3
        case .takeOldRoad, .crossFenAlone, .takeFenGlass, .forceSpireDoor, .claimHollowCrown: 1
        case .resurrectAtEmberRoad: 6
        case .readTheTrail, .rallyCompany, .guardCrossing: 3
        case .breakTheWard, .claimRelic, .chaseOmen: 1
        case .beginFrontierExpedition, .trainIronWill, .trainWayfinder, .trainOathkeeper, .nameSuccessor: 0
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
                    choices: [.beginFrontierExpedition]
                )
            }
            return AdventureEncounter(
                eyebrow: "V · THE BURIED COURT",
                title: "The Hollow Crown wakes",
                narration: "Beneath the Spire, an empty throne speaks with the voices of lost expeditions. One oath can close the breach. One choice can place its power in mortal hands.",
                location: .hollowCrown,
                choices: [.sealHollowCrown, .claimHollowCrown]
            )
        case .frontier:
            let frontier = state.frontier ?? .initial
            let shell = frontierShell(for: frontier)
            return AdventureEncounter(
                eyebrow: "EXPEDITION \(frontier.expeditionNumber) · \(frontier.step + 1) OF 3",
                title: shell.title,
                narration: shell.narration,
                location: shell.location,
                choices: shell.choices
            )
        case .frontierReward:
            let frontier = state.frontier ?? .initial
            return AdventureEncounter(
                eyebrow: "EXPEDITION \(frontier.expeditionNumber) · GRADE \(frontier.grade)",
                title: "Choose what the road taught you",
                narration: "The company returns with \(frontier.runScore) marks of distinction. Take one lesson forward; a mastered trait converts future training into renown.",
                location: .emberwatch,
                choices: [.trainIronWill, .trainWayfinder, .trainOathkeeper]
            )
        case .dead:
            return AdventureEncounter(
                eyebrow: "THE EMBER ROAD",
                title: "The map remembers your name",
                narration: "Aren Vale is dead. The region, companions, inventory, and every road already opened remain. One ember shard can call the cartographer home—once.",
                location: state.discoveredLocations.contains(.hollowCrown) ? .hollowCrown : .saltSpire,
                choices: state.resurrectionUsed || !state.hasItem(.emberShard)
                    ? [.nameSuccessor]
                    : [.resurrectAtEmberRoad, .nameSuccessor]
            )
        }
    }

    static func forecast(for choice: AdventureChoiceID, in state: AdventureState) -> AdventureChoiceForecast? {
        guard let profile = rollProfile(for: choice, in: state) else { return nil }
        let needed = profile.target - profile.modifier
        let successfulFaces = min(20, max(0, 21 - needed))
        return AdventureChoiceForecast(
            chancePercent: successfulFaces * 5,
            modifier: profile.modifier,
            target: profile.target
        )
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
            let roll = makeRoll(for: choice, in: state)
            if roll.succeeded {
                recruit(.sable, bond: 1, in: &state)
            } else {
                state.hero.health = max(1, state.hero.health - 1)
            }
            discover(.starfallFen, in: &state)
            completeQuest("trace-road", unlock: "light-fen", in: &state)
            state.scene = .starfallFen
            state.latestOutcome = outcome(
                roll.succeeded ? "Terms accepted" : "Terms refused",
                roll.succeeded
                    ? "Sable finds the vanished road before the rain closes it. The pathfinder joins your company."
                    : "The negotiation fails. Aren reaches the fen alone, one health poorer and without a pathfinder.",
                roll,
                choice
            )
        case .takeOldRoad:
            let roll = makeRoll(for: choice, in: state)
            if !roll.succeeded { state.hero.health = max(1, state.hero.health - 2) }
            discover(.starfallFen, in: &state)
            completeQuest("trace-road", unlock: "light-fen", in: &state)
            state.scene = .starfallFen
            state.latestOutcome = outcome(
                roll.succeeded ? "The old road yields" : "The road takes its toll",
                roll.succeeded
                    ? "You find a forgotten cairn and reach the fen ahead of the storm."
                    : "You reach the fen without a guide, bloodied by shale and two hours behind the storm.",
                roll,
                choice
            )
        case .trustSable:
            let roll = makeRoll(for: choice, in: state)
            if !roll.succeeded { state.hero.health = max(1, state.hero.health - 1) }
            discover(.saltSpire, in: &state)
            state.scene = .saltSpire
            state.latestOutcome = outcome(
                roll.succeeded ? "The marked stones hold" : "The fen changes course",
                roll.succeeded
                    ? "Sable reads the water correctly. You reach Ilyra’s lantern with dry powder and an intact company."
                    : "One marker has sunk beneath the flood. The company reaches Ilyra, but the detour costs one health.",
                roll,
                choice
            )
        case .crossFenAlone:
            let roll = makeRoll(for: choice, in: state)
            if !roll.succeeded { state.hero.health = max(1, state.hero.health - 3) }
            addItem(.fenGlass, in: &state)
            discover(.saltSpire, in: &state)
            state.scene = .saltSpire
            state.latestOutcome = outcome(
                roll.succeeded ? "The direct line holds" : "The causeway gives way",
                roll.succeeded
                    ? "You cross before the black water rises and recover a cold phial from the final milepost."
                    : "You escape the water with a cold phial in hand, but the thing below leaves a wound that will not warm.",
                roll,
                choice
            )
        case .keepIlyra:
            let roll = makeRoll(for: choice, in: state)
            if roll.succeeded { recruit(.ilyra, bond: 1, in: &state) }
            addItem(.stormKey, in: &state)
            completeQuest("light-fen", unlock: "seal-court", in: &state)
            state.scene = .hollowCrown
            state.latestOutcome = outcome(
                roll.succeeded ? "A second oath joins yours" : "The physician remains",
                roll.succeeded
                    ? "Ilyra enters the company and places the storm key in your palm. It beats like a quiet heart."
                    : "Ilyra gives you the storm key, but your appeal fails. She remains with the fen’s wounded.",
                roll,
                choice
            )
        case .takeFenGlass:
            let roll = makeRoll(for: choice, in: state)
            if !roll.succeeded { state.hero.health = max(1, state.hero.health - 1) }
            addItem(.fenGlass, in: &state)
            addItem(.stormKey, in: &state)
            completeQuest("light-fen", unlock: "seal-court", in: &state)
            state.scene = .hollowCrown
            state.latestOutcome = outcome(
                roll.succeeded ? "A colder bargain" : "Glass draws blood",
                roll.succeeded
                    ? "Ilyra gives you the key and a clean phial. The Spire will be faced without her oath."
                    : "The unstable phial burns one health from Aren’s hand. Ilyra remains with the wounded.",
                roll,
                choice
            )
        case .turnStormKey:
            let roll = makeRoll(for: choice, in: state)
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
            let roll = makeRoll(for: choice, in: state)
            discover(.hollowCrown, in: &state)
            if roll.succeeded { state.scene = .homecoming } else { killHero(returningTo: .homecoming, in: &state) }
            state.latestOutcome = outcome(
                roll.succeeded ? "The ward shatters" : "The storm oath collects its debt",
                roll.succeeded
                    ? "The crownward door breaks and reveals a cache the oathkeepers abandoned."
                    : "The crownward door opens. Aren Vale does not cross its threshold alive.",
                roll,
                choice
            )
        case .sealHollowCrown:
            let roll = makeRoll(for: choice, in: state)
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
            let roll = makeRoll(for: choice, in: state)
            if roll.succeeded {
                addItem(.crownSeal, in: &state)
                completeQuest("seal-court", unlock: nil, in: &state)
                state.hero.title = "Bearer of the Hollow Seal"
                state.scene = .homecoming
            } else {
                killHero(returningTo: .homecoming, in: &state)
            }
            state.latestOutcome = outcome(
                roll.succeeded ? "The Crown yields" : "No living sovereign",
                roll.succeeded
                    ? "Aren survives the forbidden claim and carries its seal back to Emberwatch."
                    : "The Crown accepts the claim and rejects the claimant. Aren’s map falls open at the road home.",
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
        case .beginFrontierExpedition:
            state.frontier = state.frontier ?? .initial
            state.scene = .frontier
            state.latestOutcome = outcome(
                "A new map opens",
                "Three dangers lie between Emberwatch and the blue horizon. The route changes with every expedition.",
                nil,
                choice
            )
        case .readTheTrail, .breakTheWard, .rallyCompany, .claimRelic, .guardCrossing, .chaseOmen:
            resolveFrontier(choice, in: &state)
        case .trainIronWill:
            finishExpedition(training: .ironWill, in: &state)
        case .trainWayfinder:
            finishExpedition(training: .wayfinder, in: &state)
        case .trainOathkeeper:
            finishExpedition(training: .oathkeeper, in: &state)
        case .nameSuccessor:
            let names = ["Mara Vale", "Tarin Ash", "Neris Vey", "Edda Morn"]
            state.hero.name = names[state.hero.deaths % names.count]
            state.hero.title = "Heir to the Ember Map"
            state.hero.isAlive = true
            state.hero.health = state.hero.maximumHealth
            state.companions = state.companions.map {
                var companion = $0
                companion.bond = max(0, companion.bond - 1)
                return companion
            }
            state.scene = state.returnSceneAfterDeath ?? (state.frontier == nil ? .hollowCrown : .frontier)
            state.returnSceneAfterDeath = nil
            state.latestOutcome = outcome(
                "The map changes hands",
                "A successor takes up every opened road and hard-won relic. The company mourns, then marches on.",
                nil,
                choice
            )
        }

        return state
    }

    private struct FrontierShell {
        var title: String
        var narration: String
        var location: AdventureLocationID
        var choices: [AdventureChoiceID]
        var target: Int
    }

    private static let frontierShells: [FrontierShell] = [
        FrontierShell(
            title: "The glasswood moves at dusk",
            narration: "Silver trunks close around an unmarked trail. The safe path is slow; a humming ward offers a violent shortcut.",
            location: .ridgeGate,
            choices: [.readTheTrail, .breakTheWard],
            target: 12
        ),
        FrontierShell(
            title: "A bell beneath the fen",
            narration: "Each toll lifts a drowned bridge for one breath. The company can keep time—or dive for the relic sounding it.",
            location: .starfallFen,
            choices: [.rallyCompany, .claimRelic],
            target: 13
        ),
        FrontierShell(
            title: "The ash caravan is cornered",
            narration: "Pilgrims hold a narrow crossing against shapes made of rain. Guard their retreat, or chase the blue omen leading the attack.",
            location: .saltSpire,
            choices: [.guardCrossing, .chaseOmen],
            target: 14
        ),
        FrontierShell(
            title: "Runes wake on the salt road",
            narration: "A forgotten boundary burns underfoot. Its pattern can be solved carefully—or broken before the storm arrives.",
            location: .saltSpire,
            choices: [.readTheTrail, .breakTheWard],
            target: 14
        ),
        FrontierShell(
            title: "The lantern beast kneels",
            narration: "A wounded creature shields a relic in its antlers. The company can calm it, or seize the prize before it rises.",
            location: .starfallFen,
            choices: [.rallyCompany, .claimRelic],
            target: 12
        ),
        FrontierShell(
            title: "Blue fire crosses the Crown",
            narration: "The breach flickers open for a final moment. Hold the road for those behind you, or follow the omen through.",
            location: .hollowCrown,
            choices: [.guardCrossing, .chaseOmen],
            target: 15
        )
    ]

    private static func frontierShell(for frontier: FrontierProgress) -> FrontierShell {
        let mixed = frontier.seed &+ UInt64(frontier.step * 17) &+ UInt64(frontier.expeditionNumber * 31)
        return frontierShells[Int(mixed % UInt64(frontierShells.count))]
    }

    private static func rollProfile(for choice: AdventureChoiceID, in state: AdventureState) -> (modifier: Int, target: Int)? {
        let resolve = state.hero.resolve
        let recruited = state.companions.filter(\.isRecruited).count
        let companionBond = state.companions.filter(\.isRecruited).map(\.bond).max() ?? 0
        let frontier = state.frontier ?? .initial
        let careful = frontier.rank(.wayfinder)
        let bold = frontier.rank(.ironWill)
        let company = recruited > 0 ? frontier.rank(.oathkeeper) : 0

        switch choice {
        case .hireSable: return (resolve, 11)
        case .takeOldRoad: return (resolve, 14)
        case .trustSable: return (resolve + 2 + companionBond, 13)
        case .crossFenAlone: return (resolve, 15)
        case .keepIlyra: return (resolve + 1, 11)
        case .takeFenGlass: return (resolve, 14)
        case .turnStormKey: return (resolve + (state.companion(.ilyra)?.isRecruited == true ? 2 : 0), 14)
        case .forceSpireDoor: return (resolve + bold, 17)
        case .sealHollowCrown: return (resolve + recruited * 2 + company, 15)
        case .claimHollowCrown: return (resolve + bold, 18)
        case .readTheTrail, .guardCrossing:
            return (resolve + careful + company + companionBond, frontierShell(for: frontier).target)
        case .rallyCompany:
            return (resolve + careful + company + recruited + companionBond, frontierShell(for: frontier).target)
        case .breakTheWard, .claimRelic, .chaseOmen:
            return (resolve + bold + (state.hasItem(.fenGlass) ? 1 : 0), frontierShell(for: frontier).target + 3)
        case .resurrectAtEmberRoad, .beginFrontierExpedition, .trainIronWill, .trainWayfinder,
             .trainOathkeeper, .nameSuccessor:
            return nil
        }
    }

    private static func makeRoll(for choice: AdventureChoiceID, in state: AdventureState) -> AdventureRoll {
        let profile = rollProfile(for: choice, in: state) ?? (0, 20)
        var value = (state.frontier?.seed ?? 0xA11CE) ^ UInt64(state.decisionsMade &* 1_103_515_245)
        for byte in choice.rawValue.utf8 {
            value = value &* 1_099_511_628_211 ^ UInt64(byte)
        }
        value ^= value >> 33
        value = value &* 0xff51afd7ed558ccd
        value ^= value >> 33
        let die = Int(value % 20) + 1
        return AdventureRoll(die: die, modifier: profile.modifier, target: profile.target)
    }

    private static func resolveFrontier(_ choice: AdventureChoiceID, in state: inout AdventureState) {
        var frontier = state.frontier ?? .initial
        let encounter = frontierShell(for: frontier)
        let roll = makeRoll(for: choice, in: state)
        let isCareful = [.readTheTrail, .rallyCompany, .guardCrossing].contains(choice)
        let successScore = isCareful ? 3 : 5

        if roll.succeeded {
            frontier.runScore += successScore
            frontier.renown += isCareful ? 1 : 2
            if isCareful {
                strengthenBestCompanion(in: &state)
            } else if choice == .claimRelic {
                addItem(.fenGlass, in: &state)
            }
        } else {
            frontier.runScore += isCareful ? 1 : 0
            state.hero.health -= isCareful ? 1 : 3
        }

        frontier.step += 1
        state.frontier = frontier
        let nextScene: AdventureScene = frontier.step >= 3 ? .frontierReward : .frontier
        if state.hero.health <= 0 {
            killHero(returningTo: nextScene, in: &state)
        } else {
            state.scene = nextScene
        }
        state.latestOutcome = outcome(
            roll.succeeded ? "The company prevails" : "The road collects a price",
            roll.succeeded
                ? "\(encounter.title) becomes another line on the living map. \(isCareful ? "Trust deepens." : "The risk earns greater renown.")"
                : "The expedition continues, but the failure costs \(isCareful ? 1 : 3) health.",
            roll,
            choice
        )
    }

    private static func finishExpedition(training traitID: AdventureTraitID, in state: inout AdventureState) {
        var frontier = state.frontier ?? .initial
        let oldGrade = frontier.grade
        if let index = frontier.traits.firstIndex(where: { $0.id == traitID }), frontier.traits[index].rank < 2 {
            frontier.traits[index].rank += 1
        } else {
            frontier.renown += 2
        }
        frontier.expeditionNumber += 1
        frontier.step = 0
        frontier.runScore = 0
        frontier.seed = frontier.seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        state.frontier = frontier
        state.hero.health = min(state.hero.maximumHealth, state.hero.health + 2)
        state.scene = .frontier
        state.latestOutcome = outcome(
            "Grade \(oldGrade) expedition recorded",
            "\(traitID.name) advances. The company recovers 2 health and a new route appears.",
            nil,
            choiceForTrait(traitID)
        )
    }

    private static func choiceForTrait(_ id: AdventureTraitID) -> AdventureChoiceID {
        switch id {
        case .ironWill: .trainIronWill
        case .wayfinder: .trainWayfinder
        case .oathkeeper: .trainOathkeeper
        }
    }

    private static func strengthenBestCompanion(in state: inout AdventureState) {
        guard let index = state.companions.indices
            .filter({ state.companions[$0].isRecruited })
            .min(by: { state.companions[$0].bond < state.companions[$1].bond }) else { return }
        state.companions[index].bond = min(3, state.companions[index].bond + 1)
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
