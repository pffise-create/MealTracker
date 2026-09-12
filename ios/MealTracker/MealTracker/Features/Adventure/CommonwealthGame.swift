import Foundation

enum CommonwealthSite: String, Codable, CaseIterable, Identifiable, Sendable {
    case homestead, creek, pinewood, ridge, crossing, township

    var id: String { rawValue }
    var name: String {
        switch self {
        case .homestead: "Vale Homestead"
        case .creek: "Willow Creek"
        case .pinewood: "The Pinewood"
        case .ridge: "Greyback Ridge"
        case .crossing: "Voss Crossing"
        case .township: "Briar Commons"
        }
    }
    var subtitle: String {
        switch self {
        case .homestead: "Three families. One place to begin."
        case .creek: "Water rights at the heart of the valley."
        case .pinewood: "Old-growth timber and stranger things beneath it."
        case .ridge: "Stone above the valley; a clear view of trouble."
        case .crossing: "Whoever holds the bridge sets the terms."
        case .township: "A place that could belong to everyone."
        }
    }
}

enum CommonwealthBuilding: String, Codable, CaseIterable, Identifiable, Sendable {
    case well, garden, lumberCamp, quarry, watchtower, tradingPost, commons
    var id: String { rawValue }
    var name: String {
        switch self {
        case .well: "Creek sluice"
        case .garden: "Kitchen gardens"
        case .lumberCamp: "Lumber camp"
        case .quarry: "Stone quarry"
        case .watchtower: "Watchtower"
        case .tradingPost: "Trading post"
        case .commons: "Commonwealth hall"
        }
    }
    var site: CommonwealthSite {
        switch self {
        case .well: .creek
        case .garden: .homestead
        case .lumberCamp: .pinewood
        case .quarry: .ridge
        case .watchtower, .tradingPost: .crossing
        case .commons: .township
        }
    }
}

struct CommonwealthCost: Equatable, Sendable {
    var xp = 0
    var timber = 0
    var stone = 0
    var supplies = 0

    var summary: String {
        [(xp, "XP"), (timber, "timber"), (stone, "stone"), (supplies, "supplies")]
            .filter { $0.0 > 0 }.map { "\($0.0) \($0.1)" }.joined(separator: " · ")
    }
}

enum CommonwealthAction: String, CaseIterable, Identifiable, Sendable {
    case acceptCharter, restoreWater, buildGarden, buildLumberCamp, buildQuarry
    case buildWatchtower, buildTradingPost, foundCommonwealth
    case gatherTimber, quarryStone, forage, patrol
    case repairCottages, openHall, fundFreeBridge, licenseCaravans, protectGrove, harvestGrove

    var id: String { rawValue }
    var title: String {
        switch self {
        case .acceptCharter: "Claim your inheritance"
        case .restoreWater: "Restore the creek"
        case .buildGarden: "Plant kitchen gardens"
        case .buildLumberCamp: "Raise a lumber camp"
        case .buildQuarry: "Open the quarry"
        case .buildWatchtower: "Build a watchtower"
        case .buildTradingPost: "Build a trading post"
        case .foundCommonwealth: "Found the commonwealth"
        case .gatherTimber: "Take a timber expedition"
        case .quarryStone: "Gather ridge stone"
        case .forage: "Provision the settlement"
        case .patrol: "Patrol the crossing"
        case .repairCottages: "Repair the family cottages"
        case .openHall: "Open the hall for shelter"
        case .fundFreeBridge: "Keep the bridge toll-free"
        case .licenseCaravans: "License the caravan road"
        case .protectGrove: "Protect the silver grove"
        case .harvestGrove: "Harvest the outer grove"
        }
    }
    var detail: String {
        switch self {
        case .acceptCharter: "Take responsibility for Briar Glen and the families who stayed."
        case .restoreWater: "Mara will reopen the sluice. Water unlocks expeditions and building."
        case .buildGarden: "Provision trips yield 6 supplies instead of 3. Morale +8."
        case .buildLumberCamp: "Timber expeditions yield 7 timber instead of 4. A fourth family settles here."
        case .buildQuarry: "Stone trips yield 6 stone instead of 3. Another family joins the valley."
        case .buildWatchtower: "Choose defense: +4 health and +1 damage in patrols. Permanently replaces the trading-post option."
        case .buildTradingPost: "Choose trade: every expedition brings +2 supplies. Permanently replaces the watchtower option."
        case .foundCommonwealth: "Give every family a seat at the hall. Establish a self-governing valley."
        case .gatherTimber: "Bring home timber. The lumber camp improves each trip."
        case .quarryStone: "Bring home stone. A working quarry improves each trip."
        case .forage: "Bring home supplies. Gardens improve each trip."
        case .patrol: "Face Voss's outriders in turn-based combat. Victory secures the bridge and brings supplies."
        case .repairCottages: "Storms damaged the family cottages. Spend materials on repairs; trust +8."
        case .openHall: "Shelter the families in the hall and feed them from your stores; trust +5. Saves building materials."
        case .fundFreeBridge: "Pay to repair the bridge and keep passage free for every family; trust +10."
        case .licenseCaravans: "A merchant funds repairs for a toll charter: gain 5 timber and 3 stone; trust −4."
        case .protectGrove: "Ilyra asks you to preserve the silver roots. Support the wardens; trust +10."
        case .harvestGrove: "Tomas needs timber for winter repairs. Cut the outer grove: gain 10 timber; trust −8."
        }
    }
    var site: CommonwealthSite {
        switch self {
        case .acceptCharter, .buildGarden, .forage: .homestead
        case .restoreWater: .creek
        case .buildLumberCamp, .gatherTimber: .pinewood
        case .buildQuarry, .quarryStone: .ridge
        case .buildWatchtower, .buildTradingPost, .patrol: .crossing
        case .foundCommonwealth: .township
        case .repairCottages, .openHall, .fundFreeBridge, .licenseCaravans, .protectGrove, .harvestGrove: .township
        }
    }
    var cost: CommonwealthCost {
        switch self {
        case .acceptCharter: CommonwealthCost()
        case .restoreWater: CommonwealthCost(xp: 3, timber: 2)
        case .buildGarden: CommonwealthCost(xp: 6, timber: 3)
        case .buildLumberCamp: CommonwealthCost(xp: 9, timber: 5, stone: 2)
        case .buildQuarry: CommonwealthCost(xp: 9, timber: 5, supplies: 2)
        case .buildWatchtower: CommonwealthCost(xp: 12, timber: 7, stone: 5)
        case .buildTradingPost: CommonwealthCost(xp: 12, timber: 7, supplies: 5)
        case .foundCommonwealth: CommonwealthCost(xp: 18, timber: 10, stone: 8, supplies: 8)
        case .gatherTimber, .quarryStone, .forage: CommonwealthCost(xp: 3)
        case .patrol: CommonwealthCost(xp: 6)
        case .repairCottages: CommonwealthCost(xp: 3, timber: 6, stone: 2)
        case .openHall: CommonwealthCost(xp: 3, supplies: 5)
        case .fundFreeBridge: CommonwealthCost(xp: 6, timber: 3, stone: 3)
        case .licenseCaravans: CommonwealthCost(xp: 3, supplies: 2)
        case .protectGrove: CommonwealthCost(xp: 6, supplies: 4)
        case .harvestGrove: CommonwealthCost(xp: 3, supplies: 2)
        }
    }
    var building: CommonwealthBuilding? {
        switch self {
        case .restoreWater: .well
        case .buildGarden: .garden
        case .buildLumberCamp: .lumberCamp
        case .buildQuarry: .quarry
        case .buildWatchtower: .watchtower
        case .buildTradingPost: .tradingPost
        case .foundCommonwealth: .commons
        default: nil
        }
    }
    var councilCycle: Int? {
        switch self {
        case .repairCottages, .openHall: 0
        case .fundFreeBridge, .licenseCaravans: 1
        case .protectGrove, .harvestGrove: 2
        default: nil
        }
    }
}

struct CommonwealthCitizen: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var role: String
    var site: CommonwealthSite
}

struct CommonwealthEvent: Codable, Equatable, Identifiable, Sendable {
    var id: Int
    var title: String
    var detail: String
}

enum CommonwealthEnemyIntent: String, Codable, CaseIterable, Sendable {
    case strike, brace, aim, rush
    var title: String {
        switch self {
        case .strike: "Blade raised"
        case .brace: "Shield braced"
        case .aim: "Taking aim"
        case .rush: "Preparing a rush"
        }
    }
    var detail: String {
        switch self {
        case .strike: "A 4-damage strike is coming. Side cover blocks 1; Guard blocks 4."
        case .brace: "Frontal attacks deal only 1 damage. Flank to break the defense."
        case .aim: "A 5-damage shot targets your lane. Flank to evade it. Side cover blocks 1."
        case .rush: "A 6-damage charge is coming. Guard blocks 4 and counters for 2."
        }
    }
}

enum CommonwealthTactic: String, CaseIterable, Identifiable, Sendable {
    case attack, `guard`, flank, rally, retreat
    var id: String { rawValue }
    var title: String {
        switch self {
        case .attack: "Attack"
        case .guard: "Guard"
        case .flank: "Flank"
        case .rally: "Rally"
        case .retreat: "Retreat"
        }
    }
    var detail: String {
        switch self {
        case .attack: "Deal 4–5 damage. Only 1 against a braced shield."
        case .guard: "Block 4 damage. Counter a rush for 2."
        case .flank: "Change lane. Deal 2, or 5 against a shield. Evade aimed shots; side cover blocks 1 strike damage."
        case .rally: "Recover 5 health, once per patrol. The enemy still acts."
        case .retreat: "Return home safely. Keep your land; this patrol's XP stays spent."
        }
    }
}

struct CommonwealthCombat: Codable, Equatable, Sendable {
    var playerHealth: Int
    var playerMaximumHealth: Int
    var enemyHealth: Int
    var enemyMaximumHealth: Int
    var enemyName: String
    var intent: CommonwealthEnemyIntent
    var round: Int
    var playerLane: Int
    var enemyLane: Int
    var rallyAvailable: Bool
    var latestDetail: String
    var seed: UInt64
}

struct CommonwealthState: Codable, Equatable, Sendable {
    var version = 1
    var introSeen = false
    var currentSite: CommonwealthSite = .homestead
    var claimedSites: Set<CommonwealthSite> = [.homestead]
    var buildings: Set<CommonwealthBuilding> = []
    var timber = 6
    var stone = 3
    var supplies = 4
    var morale = 55
    var xpSpent = 0
    var citizens: [CommonwealthCitizen] = [
        CommonwealthCitizen(id: "mara", name: "Mara Vale", role: "Ranch forewoman · Vale family", site: .homestead),
        CommonwealthCitizen(id: "sable", name: "Sable Vey", role: "Scout · Vey family", site: .crossing),
        CommonwealthCitizen(id: "ilyra", name: "Ilyra Morn", role: "Physician · Morn family", site: .homestead)
    ]
    var combat: CommonwealthCombat?
    var history: [CommonwealthEvent] = []
    var eventSequence = 0
    var patrolsWon = 0
    var patrolsStarted = 0
    var councilDecisions = 0

    static let initial = CommonwealthState()
    var latestEvent: CommonwealthEvent? { history.last }
    var population: Int { citizens.count * 3 }
    var builtSites: Set<String> { Set(buildings.map { $0.site.rawValue }) }
    var isTrusted: Bool { morale >= 75 }
    var chapterTitle: String {
        if buildings.contains(.commons) { return "A commonwealth of your own" }
        if claimedSites.contains(.crossing) { return "A valley worth keeping" }
        if buildings.contains(.well) { return "Roots and rivals" }
        return "An inheritance of dust"
    }
    var objectiveTitle: String {
        if !introSeen { return "Welcome to Briar Glen" }
        if !buildings.contains(.well) { return "Bring water back to the valley" }
        if !claimedSites.contains(.crossing) { return "Secure Voss Crossing" }
        if !buildings.contains(.lumberCamp) || !buildings.contains(.quarry) { return "Build the valley's livelihood" }
        if !buildings.contains(.watchtower) && !buildings.contains(.tradingPost) { return "Choose how the valley will grow" }
        if !buildings.contains(.commons) { return "Found your commonwealth" }
        return ["Repair the families' homes", "Set the bridge's terms", "Decide the grove's future"][councilDecisions % 3]
    }
    var objectiveDetail: String {
        if !introSeen { return "Your aunt left you a deed, a weathered ranch, and three families who refused to leave." }
        if !buildings.contains(.well) { return "At Willow Creek, reopen the sluice Voss's men closed. Mara is ready to help." }
        if !claimedSites.contains(.crossing) { return "Lead a patrol at the bridge. Read the outrider's intent before each turn." }
        if !buildings.contains(.lumberCamp) || !buildings.contains(.quarry) { return "Establish a lumber camp in the Pinewood and a quarry on Greyback Ridge. Expeditions supply both." }
        if !buildings.contains(.watchtower) && !buildings.contains(.tradingPost) { return "A watchtower strengthens patrols. A trading post adds supplies to every expedition. Choose one at the crossing." }
        if !buildings.contains(.commons) { return "Gather 10 timber, 8 stone, 8 supplies and 18 XP, then raise the hall at Briar Commons." }
        let dispute = [
            "Storms damaged the cottages. Pay for repairs or open the hall to shelter your citizens.",
            "The bridge needs repairs. Fund free passage or trade a toll charter for materials.",
            "Ilyra wants to protect the silver roots; Tomas needs winter timber. Hear both claims at the hall."
        ][councilDecisions % 3]
        return "\(dispute) At 75 trust, resource expeditions bring 1 extra supply."
    }
    func citizenDialogue(_ citizen: CommonwealthCitizen) -> String {
        switch citizen.id {
        case "mara":
            if !buildings.contains(.well) { return "Your aunt never turned a family away. Voss says the creek is his now. Get that sluice open and we'll have a chance." }
            if buildings.contains(.commons) { return "We arrived as tenants. Now this is our commonwealth. She would have liked that." }
            return buildings.contains(.garden) ? "The gardens are feeding us. Now let's give these families a voice in what comes next." : "Water's running. A garden would make every supply trip go twice as far."
        case "ilyra":
            return buildings.contains(.well) ? "Clean water does more than any remedy. Leave the silver-barked trees standing; the roots glow when the creek runs. Some things here are older than our deeds." : "Three families are sharing the last good water. I can tend the sick, but we need that creek flowing again."
        case "sable":
            if buildings.contains(.watchtower) { return "From that tower, nothing reaches the bridge unseen. We can stand our ground." }
            if buildings.contains(.tradingPost) { return "Voss wanted a toll road. You've made it a place people come to trade. I'll keep the caravans safe." }
            return claimedSites.contains(.crossing) ? "We hold the bridge. A tower would protect us; a trading post would connect us. There's only room for one." : "The outriders announce every move with their shoulders. Guard a rush, circle a shield, move when they aim."
        case "tomas": return "We brought our tools and our children. A place with work and clean water is worth building."
        default: return "The ridge stone runs deep. Build something here that outlasts all of us."
        }
    }
}

enum CommonwealthGameError: LocalizedError, Equatable {
    case blocked(String)
    var errorDescription: String? {
        switch self { case .blocked(let message): message }
    }
}

enum CommonwealthEngine {
    static func tacticDetail(for tactic: CommonwealthTactic, in state: CommonwealthState) -> String {
        guard state.buildings.contains(.watchtower) else { return tactic.detail }
        switch tactic {
        case .attack: return "Deal 5–6 damage with watchtower support. Only 1 against a braced shield."
        case .flank: return "Change lane. Deal 3, or 6 against a shield. Evade aimed shots; side cover blocks 1 strike damage."
        default: return tactic.detail
        }
    }

    static func actions(at site: CommonwealthSite, in state: CommonwealthState) -> [CommonwealthAction] {
        guard state.introSeen else { return site == .homestead ? [.acceptCharter] : [] }
        return CommonwealthAction.allCases.filter { action in
            guard action != .acceptCharter, action.site == site else { return false }
            if let building = action.building, state.buildings.contains(building) { return false }
            if action == .buildWatchtower, state.buildings.contains(.tradingPost) { return false }
            if action == .buildTradingPost, state.buildings.contains(.watchtower) { return false }
            if let cycle = action.councilCycle {
                return state.buildings.contains(.commons) && cycle == state.councilDecisions % 3
            }
            return true
        }
    }

    static func blocker(for action: CommonwealthAction, in state: CommonwealthState, availableXP: Int) -> String? {
        if state.combat != nil { return "Finish or retreat from the patrol first." }
        if action == .acceptCharter { return state.introSeen ? "Your inheritance is already claimed." : nil }
        if !state.introSeen { return "Claim your inheritance first." }
        if let building = action.building, state.buildings.contains(building) { return "Already built." }
        if action != .restoreWater && !state.buildings.contains(.well) { return "Restore Willow Creek first." }
        if let cycle = action.councilCycle {
            if !state.buildings.contains(.commons) { return "Found the commonwealth before convening its council." }
            if cycle != state.councilDecisions % 3 { return "The council has moved to another claim." }
        }
        if action == .buildWatchtower || action == .buildTradingPost {
            if !state.claimedSites.contains(.crossing) { return "Win a patrol to secure the crossing first." }
            if state.buildings.contains(.tradingPost) || state.buildings.contains(.watchtower) {
                return "The crossing already has its landmark."
            }
        }
        if action == .foundCommonwealth {
            if !state.buildings.contains(.lumberCamp) || !state.buildings.contains(.quarry) {
                return "Build a lumber camp and quarry first."
            }
            if !state.buildings.contains(.watchtower) && !state.buildings.contains(.tradingPost) {
                return "Secure the crossing and choose its landmark first."
            }
        }
        let cost = action.cost
        if availableXP < cost.xp { return "Need \(cost.xp - max(0, availableXP)) more XP. Log a meal to earn \(RewardEngine.mealAmount)." }
        if state.timber < cost.timber { return "Need \(cost.timber - state.timber) more timber from the Pinewood." }
        if state.stone < cost.stone { return "Need \(cost.stone - state.stone) more stone from Greyback Ridge." }
        if state.supplies < cost.supplies { return "Need \(cost.supplies - state.supplies) more supplies. Provision at the homestead." }
        return nil
    }

    static func resolve(_ action: CommonwealthAction, in original: CommonwealthState, availableXP: Int) throws -> CommonwealthState {
        if let reason = blocker(for: action, in: original, availableXP: availableXP) { throw CommonwealthGameError.blocked(reason) }
        var state = original
        state.currentSite = action.site
        state.xpSpent += action.cost.xp
        state.timber -= action.cost.timber
        state.stone -= action.cost.stone
        state.supplies -= action.cost.supplies
        if let building = action.building {
            state.buildings.insert(building)
            state.claimedSites.insert(building.site)
        }
        switch action {
        case .acceptCharter:
            state.introSeen = true
            record("The deed is yours", "Mara, Sable and Ilyra stand with you. First, restore the water at Willow Creek.", in: &state)
        case .restoreWater:
            state.morale += 10
            record("Water returns", "Mara lifts the sluice. The fields drink again. Across the creek, silver roots briefly shine beneath the water.", in: &state)
        case .buildGarden:
            state.morale += 8
            record("A garden at every doorstep", "Mara divides the beds among the families. Provision trips now bring 6 supplies.", in: &state)
        case .buildLumberCamp:
            state.citizens.append(CommonwealthCitizen(id: "tomas", name: "Tomas Bell", role: "Forester · Bell family", site: .pinewood))
            state.morale += 5
            record("The first new arrivals", "The Bell family raises a timber camp. Timber expeditions now bring 7 timber.", in: &state)
        case .buildQuarry:
            state.citizens.append(CommonwealthCitizen(id: "ada", name: "Ada Moss", role: "Mason · Moss family", site: .ridge))
            state.morale += 5
            record("Stone for a future", "Ada Moss moves her family to the ridge. Stone trips now bring 6 stone.", in: &state)
        case .buildWatchtower:
            state.morale += 6
            record("A watch over the valley", "Sable raises your banner. Every future patrol gains 4 health and 1 attack damage. The crossing's purpose is defense.", in: &state)
        case .buildTradingPost:
            state.morale += 6
            record("Open for trade", "The first caravan crosses without paying Voss. Every resource expedition now brings 2 extra supplies.", in: &state)
        case .foundCommonwealth:
            state.morale += 15
            record("The Briar Glen Commonwealth", "Five families sign the charter. Water, work and a voice for every household. The valley is yours to keep building.", in: &state)
        case .gatherTimber:
            let amount = state.buildings.contains(.lumberCamp) ? 7 : 4
            state.timber += amount
            expeditionBonus(in: &state)
            record("Timber brought home", "Your crew returns with \(amount) timber.\(expeditionBonusCopy(state))", in: &state)
        case .quarryStone:
            let amount = state.buildings.contains(.quarry) ? 6 : 3
            state.stone += amount
            expeditionBonus(in: &state)
            record("Stone brought home", "The ridge yields \(amount) stone.\(expeditionBonusCopy(state))", in: &state)
        case .forage:
            let amount = state.buildings.contains(.garden) ? 6 : 3
            state.supplies += amount
            expeditionBonus(in: &state)
            record("The stores are fuller", "Your families bring home \(amount) supplies.\(expeditionBonusCopy(state))", in: &state)
        case .patrol:
            state.patrolsStarted += 1
            let health = state.buildings.contains(.watchtower) ? 18 : 14
            let enemyHealth = 13 + min(5, state.patrolsWon)
            state.combat = CommonwealthCombat(
                playerHealth: health, playerMaximumHealth: health,
                enemyHealth: enemyHealth, enemyMaximumHealth: enemyHealth,
                enemyName: state.patrolsWon == 0 ? "Voss's outrider" : "Voss's enforcer",
                intent: .strike, round: 1, playerLane: 1, enemyLane: 1,
                rallyAvailable: true, latestDetail: "Sable covers your back. The outrider raises a blade; read the intent before you act.",
                seed: UInt64(state.patrolsStarted) &* 2_654_435_761
            )
            record("At the crossing", "Voss's men block the bridge. This patrol's 6 XP is spent; every combat turn is free.", in: &state)
        case .repairCottages:
            state.morale += 8
            record("Dry roofs, stronger trust", "Tomas repairs the cottages before nightfall. Families see their work returned in care. Trust +8.", in: &state)
        case .openHall:
            state.morale += 5
            record("No family left outside", "Mara sets beds beside the council benches. The hall becomes a shelter while your building stocks recover. Trust +5.", in: &state)
        case .fundFreeBridge:
            state.morale += 10
            record("A road for everyone", "Your crews repair the bridge. Sable takes down the toll board; families cross freely. Trust +10.", in: &state)
        case .licenseCaravans:
            state.timber += 5
            state.stone += 3
            state.morale -= 4
            record("The cost of a charter", "A merchant delivers 5 timber and 3 stone. The new toll helps the stores, but your families remember your promise. Trust −4.", in: &state)
        case .protectGrove:
            state.morale += 10
            record("The roots remain", "Ilyra leads the wardens into the grove. The silver trees still glow above the creek. Your citizens see a promise kept. Trust +10.", in: &state)
        case .harvestGrove:
            state.timber += 10
            state.morale -= 8
            record("Timber, at a price", "Tomas returns with 10 timber for winter repairs. Ilyra closes her shutters as the grove's outer lights go dark. Trust −8.", in: &state)
        }
        if action.councilCycle != nil { state.councilDecisions += 1 }
        state.morale = min(100, max(0, state.morale))
        return state
    }

    static func travel(to site: CommonwealthSite, in original: CommonwealthState) throws -> CommonwealthState {
        guard original.combat == nil else { throw CommonwealthGameError.blocked("Finish or retreat from the patrol first.") }
        var state = original
        state.currentSite = site
        return state
    }

    static func fight(_ tactic: CommonwealthTactic, in original: CommonwealthState) throws -> CommonwealthState {
        guard var combat = original.combat else { throw CommonwealthGameError.blocked("There is no active patrol.") }
        guard tactic != .rally || combat.rallyAvailable else { throw CommonwealthGameError.blocked("Rally has already been used in this patrol.") }
        var state = original
        if tactic == .retreat {
            state.combat = nil
            state.currentSite = .homestead
            record("A safe retreat", "Sable guides you home. Your land and stores are safe. Rally again whenever you have 6 XP for a new patrol.", in: &state)
            return state
        }
        let intent = combat.intent
        let towerBonus = state.buildings.contains(.watchtower) ? 1 : 0
        var outgoing = 0
        var incoming = 0
        switch tactic {
        case .attack: outgoing = intent == .brace ? 1 : 4 + nextDie(&combat.seed, sides: 2) + towerBonus
        case .guard: outgoing = intent == .rush ? 2 : 0
        case .flank:
            combat.playerLane = (combat.playerLane + 1) % 3
            outgoing = (intent == .brace ? 5 : 2) + towerBonus
        case .rally:
            combat.rallyAvailable = false
            combat.playerHealth = min(combat.playerMaximumHealth, combat.playerHealth + 5)
        case .retreat: break
        }
        combat.enemyHealth = max(0, combat.enemyHealth - outgoing)
        if combat.enemyHealth == 0 {
            state.combat = nil
            state.patrolsWon += 1
            state.claimedSites.insert(.crossing)
            let gained = 4 + (state.buildings.contains(.tradingPost) ? 2 : 0)
            state.supplies += gained
            state.morale = min(100, state.morale + 4)
            record("The bridge is yours", "The outrider yields. Sable brings the crew home with \(gained) supplies. Your next patrol starts at full health.", in: &state)
            return state
        }
        switch intent {
        case .strike: incoming = 4
        case .brace: incoming = 1
        case .aim: incoming = combat.playerLane == combat.enemyLane ? 5 : 0
        case .rush: incoming = 6
        }
        if combat.playerLane != 1 && (intent == .strike || intent == .aim) {
            incoming = max(0, incoming - 1)
        }
        if tactic == .guard { incoming = max(0, incoming - 4) }
        combat.playerHealth = max(0, combat.playerHealth - incoming)
        if combat.playerHealth == 0 {
            state.combat = nil
            state.currentSite = .homestead
            state.morale = max(0, state.morale - 3)
            record("Sable gets you home", "The patrol is beaten, but nobody is lost. Your buildings and stores remain. Recover fully at home; a new patrol costs 6 XP.", in: &state)
            return state
        }
        combat.latestDetail = tactic == .rally
            ? "You rally for up to 5 health. The outrider deals \(incoming) damage."
            : "You deal \(outgoing) damage and take \(incoming)."
        combat.round += 1
        // Persist the PRNG state so restoring a fight cannot reroll a turn.
        let intents = CommonwealthEnemyIntent.allCases
        combat.intent = intents[nextDie(&combat.seed, sides: intents.count)]
        combat.enemyLane = combat.playerLane
        state.combat = combat
        return state
    }

    private static func nextDie(_ seed: inout UInt64, sides: Int) -> Int {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((seed >> 32) % UInt64(sides))
    }
    private static func expeditionBonus(in state: inout CommonwealthState) {
        if state.buildings.contains(.tradingPost) { state.supplies += 2 }
        if state.isTrusted { state.supplies += 1 }
    }
    private static func expeditionBonusCopy(_ state: CommonwealthState) -> String {
        (state.buildings.contains(.tradingPost) ? " Traders add 2 supplies." : "")
            + (state.isTrusted ? " Your citizens' trust adds 1 supply." : "")
    }
    private static func record(_ title: String, _ detail: String, in state: inout CommonwealthState) {
        state.eventSequence += 1
        state.history.append(CommonwealthEvent(id: state.eventSequence, title: title, detail: detail))
        if state.history.count > 40 { state.history.removeFirst(state.history.count - 40) }
    }
}

@MainActor
protocol CommonwealthStatePersisting: AnyObject {
    func load() -> CommonwealthState?
    func save(_ state: CommonwealthState) throws
}

@MainActor
final class InMemoryCommonwealthStatePersistence: CommonwealthStatePersisting {
    private var state: CommonwealthState?
    init(state: CommonwealthState? = nil) { self.state = state }
    func load() -> CommonwealthState? { state }
    func save(_ state: CommonwealthState) throws { self.state = state }
}

@MainActor
final class CommonwealthUITestLegacyPersistence: AdventureStatePersisting {
    private var state = AdventureState.initial
    func load() -> AdventureState? { state }
    func save(_ state: AdventureState) throws { self.state = state }
}

@MainActor
final class UserDefaultsCommonwealthStatePersistence: CommonwealthStatePersisting {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "commonwealth-state-v1") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> CommonwealthState? {
        guard let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(CommonwealthState.self, from: data),
              state.version == 1 else { return nil }
        return state
    }

    func save(_ state: CommonwealthState) throws {
        defaults.set(try JSONEncoder().encode(state), forKey: key)
    }
}
