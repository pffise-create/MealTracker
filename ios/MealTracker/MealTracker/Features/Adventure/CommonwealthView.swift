import SwiftUI

/// The territory is the primary play surface; every panel describes a place on it.
struct AdventureView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var section = CommonwealthSection.land
    @State private var selectedSite: CommonwealthSite = .homestead
    @State private var showingStory = false
    let onLogMeal: () -> Void

    private var state: CommonwealthState { store.commonwealth }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        bankHeader.id("gameTop")
                        if !state.introSeen {
                            introduction
                        } else {
                            if state.combat == nil {
                                Picker("Commonwealth section", selection: $section) {
                                    ForEach(CommonwealthSection.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.segmented)
                            }
                            switch section {
                            case .land:
                                if let combat = state.combat {
                                    battle(combat)
                                } else {
                                    land(proxy: proxy)
                                }
                            case .people: people
                            case .journal: journal
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .background(AppColors.background)
                .onChange(of: state.eventSequence) { _, _ in
                    proxy.scrollTo(state.combat == nil ? "lastOutcome" : "gameTop", anchor: .top)
                }
            }
            .navigationTitle("Briar Glen")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { selectedSite = state.currentSite }
            .onChange(of: state.currentSite) { _, site in selectedSite = site }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingStory = true } label: {
                        Image(systemName: "book.closed")
                    }
                    .accessibilityLabel("The story so far")
                }
            }
            .sheet(isPresented: $showingStory) {
                NavigationStack {
                    ScrollView { storyText.padding(24) }
                        .navigationTitle("Your inheritance")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingStory = false } } }
                }
            }
        }
    }

    private var bankHeader: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center))
        return layout {
            if let combat = state.combat {
                Text("PATROL · ROUND \(combat.round)")
                    .font(.appBody(.caption, weight: .semibold))
                    .foregroundStyle(AppColors.muted)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.introSeen ? state.chapterTitle : "A FRONTIER OF YOUR OWN")
                        .font(.appBody(.caption, weight: .semibold))
                        .foregroundStyle(AppColors.muted)
                    Text(state.introSeen ? "\(state.population) citizens · Turn \(state.eventSequence + 1)" : "Your land. Your people. Your call.")
                        .font(.appBody(.subheadline))
                        .foregroundStyle(AppColors.ink)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(store.commonwealthXPBalance) XP")
                    .font(.appDisplay(.title3, weight: .bold))
                    .foregroundStyle(AppColors.brand)
                if state.combat == nil && !dynamicTypeSize.isAccessibilitySize {
                    Text("BANKED")
                        .font(.appBody(.caption2, weight: .bold)).tracking(1)
                        .foregroundStyle(AppColors.muted)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(store.commonwealthXPBalance) experience points banked")
            .accessibilityIdentifier("adventure.balance")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack(alignment: .bottomLeading) {
                Image("BriarGlenValley")
                    .resizable().scaledToFill()
                    .frame(height: 280).clipped()
                LinearGradient(colors: [.clear, Color.black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 5) {
                    Text("THE DEED IS YOURS.")
                        .font(.appBody(.caption, weight: .bold)).tracking(2)
                    Text("Now earn their trust.")
                        .font(.appDisplay(.title, weight: .bold))
                }.foregroundStyle(.white).padding(20)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .accessibilityHidden(true)
            storyText
            HStack(spacing: 12) {
                ForEach(Array(state.citizens.enumerated()), id: \.element.id) { index, citizen in
                    VStack(spacing: 5) {
                        CommonwealthPortrait(index: index, size: 64)
                        Text(citizen.name).font(.appBody(.caption, weight: .semibold))
                    }.frame(maxWidth: .infinity)
                }
            }
            Button("Take the deed") {
                store.performCommonwealth(.acceptCharter)
                store.travelCommonwealth(to: .creek)
                selectedSite = .creek
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("commonwealth.begin")
            Text("Meals bank +3 XP. Completed days add +8. Spend it on land and projects whenever you play.")
                .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var storyText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You inherited Briar Glen: a weathered homestead, disputed water rights, and a valley worth defending.")
            Text("Mara, Sable, and Ilyra brought three families here for a fresh start. Across the creek, Calder Voss’s riders are staking a rival claim. In the hills, old boundary stones have begun to hum.")
            Text("Start with water. Build a home people can rely on. Decide what kind of commonwealth this becomes.")
                .fontWeight(.semibold)
        }
        .font(.appBody()).foregroundStyle(AppColors.ink)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func land(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            resourceStrip
            if dynamicTypeSize.isAccessibilitySize {
                DisclosureGroup("Locations") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(CommonwealthSite.allCases) { site in
                            Button(site.name) { visit(site, proxy: proxy) }
                                .font(.appBody()).frame(minHeight: 44)
                                .accessibilityValue(state.claimedSites.contains(site) ? "Your land" : "Frontier")
                        }
                    }.padding(.top, 8)
                }.font(.appBody(.headline))
            }
            CommonwealthMapView(
                selectedSite: selectedSite.rawValue,
                builtSites: builtSites,
                securedSites: Set(state.claimedSites.map(\.rawValue)),
                heroSite: state.currentSite.rawValue
            ) { rawValue in
                guard let site = CommonwealthSite(rawValue: rawValue) else { return }
                visit(site, proxy: proxy)
            }
            .id("valley")

            if let event = state.latestEvent {
                outcome(event)
                    .id("lastOutcome")
            }
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    if reduceMotion { proxy.scrollTo("valley", anchor: .top) }
                    else { withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo("valley", anchor: .top) } }
                } label: {
                    Label("Back to valley", systemImage: "arrow.up")
                        .font(.appBody(.caption, weight: .semibold)).frame(minHeight: 44)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(selectedSite.name).font(.appDisplay(.title2, weight: .bold))
                    Spacer()
                    Text(state.claimedSites.contains(selectedSite) ? "YOUR LAND" : "FRONTIER")
                        .font(.appBody(.caption2, weight: .bold)).tracking(0.8)
                        .foregroundStyle(AppColors.muted)
                }
                Text(selectedSite.subtitle).font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
                let residents = state.citizens.filter { $0.site == selectedSite }
                ForEach(residents) { citizen in
                    citizenMessage(citizen)
                }
                ForEach(CommonwealthEngine.actions(at: selectedSite, in: state)) { action in
                    projectAction(action)
                }
            }
            .id("siteDetails")

            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT MILESTONE").font(.appBody(.caption2, weight: .bold)).tracking(1)
                    .foregroundStyle(AppColors.muted)
                Text(state.objectiveTitle).font(.appBody(.headline, weight: .semibold))
                Text(state.objectiveDetail).font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            }.fixedSize(horizontal: false, vertical: true)
        }
    }

    private func visit(_ site: CommonwealthSite, proxy: ScrollViewProxy) {
        selectedSite = site
        store.travelCommonwealth(to: site)
        if reduceMotion { proxy.scrollTo("siteDetails", anchor: .top) }
        else { withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo("siteDetails", anchor: .top) } }
    }

    private var resourceStrip: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { resourceMetrics }
            VStack(alignment: .leading, spacing: 8) { resourceMetrics }
        }
        .font(.appBody(.caption, weight: .semibold))
        .foregroundStyle(AppColors.ink)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var resourceMetrics: some View {
        Label("\(state.timber) timber", systemImage: "tree")
        Label("\(state.stone) stone", systemImage: "mountain.2")
        Label("\(state.supplies) supplies", systemImage: "shippingbox")
        Label("\(state.morale) trust", systemImage: "person.2")
    }

    private var builtSites: Set<String> {
        var result = Set(state.buildings.map(\.rawValue)).union(["homestead"])
        if state.buildings.contains(.well) { result.insert("creek") }
        if state.buildings.contains(.lumberCamp) { result.insert("pinewood") }
        if state.buildings.contains(.quarry) { result.insert("ridge") }
        if state.buildings.contains(.watchtower) || state.buildings.contains(.tradingPost) { result.insert("crossing") }
        if state.buildings.contains(.commons) { result.insert("township") }
        return result
    }

    private func projectAction(_ action: CommonwealthAction) -> some View {
        let blocker = CommonwealthEngine.blocker(for: action, in: state, availableXP: store.commonwealthXPBalance)
        return VStack(alignment: .leading, spacing: 7) {
            Button {
                store.performCommonwealth(action)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(action.title).font(.appBody(.headline, weight: .bold))
                        Spacer(minLength: 4)
                        Text(action.cost.xp == 0 ? "FREE" : "\(action.cost.xp) XP")
                            .font(.appBody(.caption, weight: .bold))
                    }
                    Text(action.detail).font(.appBody(.subheadline))
                        .foregroundStyle(AppColors.muted)
                    if !materials(action.cost).isEmpty {
                        Text(materials(action.cost)).font(.appBody(.caption, weight: .semibold))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(AppColors.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(blocker == nil ? AppColors.brand.opacity(0.5) : AppColors.muted.opacity(0.2)))
            }
            .buttonStyle(.plain).disabled(blocker != nil)
            .accessibilityIdentifier("commonwealth.action.\(action.rawValue)")
            if let blocker {
                Text(blocker).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if store.commonwealthXPBalance < action.cost.xp {
                    Button("Log a meal · earn 3 XP", action: onLogMeal)
                        .font(.appBody(.subheadline, weight: .semibold))
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("commonwealth.earnXP")
                }
            }
        }
    }

    private func materials(_ cost: CommonwealthCost) -> String {
        [(cost.timber, "timber"), (cost.stone, "stone"), (cost.supplies, "supplies")]
            .filter { $0.0 > 0 }.map { "\($0.0) \($0.1)" }.joined(separator: " · ")
    }

    private func outcome(_ event: CommonwealthEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(AppColors.brand)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.appBody(.headline, weight: .semibold))
                Text(event.detail).font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("commonwealth.outcome")
    }

    private var people: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("The people behind the fences")
                .font(.appDisplay(.title2, weight: .bold))
            Text("\(state.population) citizens have made their home here. Their future follows your decisions.")
                .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            ForEach(state.citizens) { citizen in
                VStack(alignment: .leading, spacing: 10) {
                    citizenMessage(citizen)
                    Button("Visit \(citizen.site.name)") {
                        selectedSite = citizen.site
                        store.travelCommonwealth(to: citizen.site)
                        section = .land
                    }.font(.appBody(.subheadline, weight: .semibold)).frame(minHeight: 44)
                }
                Divider()
            }
        }
    }

    private func citizenMessage(_ citizen: CommonwealthCitizen) -> some View {
        HStack(alignment: .top, spacing: 12) {
            CommonwealthPortrait(index: state.citizens.firstIndex(where: { $0.id == citizen.id }) ?? 0, size: 72)
            VStack(alignment: .leading, spacing: 5) {
                Text(citizen.name).font(.appBody(.headline, weight: .bold))
                Text(citizen.role).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                Text("“\(state.citizenDialogue(citizen))”")
                    .font(.appBody(.subheadline)).foregroundStyle(AppColors.ink)
            }.fixedSize(horizontal: false, vertical: true)
        }.accessibilityElement(children: .combine)
    }

    private var journal: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The commonwealth ledger").font(.appDisplay(.title2, weight: .bold))
            Text("\(store.commonwealthXPBalance) XP banked · \(state.xpSpent) invested in Briar Glen")
                .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            Text("Your XP and land stay here between visits. There are no losses while you’re away.")
                .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            ForEach(state.history.reversed()) { event in
                outcome(event)
                Divider()
            }
        }
    }

    private func battle(_ combat: CommonwealthCombat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hold the crossing").font(.appDisplay(.title2, weight: .bold))
            Text(combat.intent.detail).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
            CommonwealthBattlefield(combat: combat)
            if dynamicTypeSize.isAccessibilitySize {
                ForEach(CommonwealthTactic.allCases) { tacticButton($0) }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    ForEach([CommonwealthTactic.attack, .guard, .flank]) { tacticButton($0) }
                }
                HStack(spacing: 8) {
                    tacticButton(.rally)
                    tacticButton(.retreat)
                }
            }
            Text(combat.latestDetail).font(.appBody(.subheadline))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("commonwealth.combatDetail")
            DisclosureGroup("Tactic guide") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(combat.enemyName).fontWeight(.semibold)
                    ForEach(CommonwealthTactic.allCases) { tactic in
                        Text("\(tactic.title): \(CommonwealthEngine.tacticDetail(for: tactic, in: state))")
                    }
                    Text("This patrol is already paid for. Every turn is free.")
                    if state.buildings.contains(.watchtower) {
                        Text("Watchtower: +4 starting health and +1 Attack/Flank damage, except frontal attacks against a shield.")
                    }
                }
                .font(.appBody(.subheadline)).padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
            }.font(.appBody(.subheadline))
        }
    }

    private func tacticButton(_ tactic: CommonwealthTactic) -> some View {
        Button { store.fightCommonwealth(tactic) } label: {
            VStack(spacing: 5) {
                Label(tactic.title, systemImage: tacticSymbol(tactic))
                    .font(.appBody(.subheadline, weight: .bold))
                Text(tacticSummary(tactic))
                    .font(.appBody(.caption2)).foregroundStyle(AppColors.muted)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(8)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.brand.opacity(0.25)))
        }
        .buttonStyle(.plain).foregroundStyle(AppColors.ink)
        .disabled(tactic == .rally && state.combat?.rallyAvailable == false)
        .accessibilityHint(CommonwealthEngine.tacticDetail(for: tactic, in: state))
        .accessibilityIdentifier("commonwealth.tactic.\(tactic.rawValue)")
    }

    private func tacticSummary(_ tactic: CommonwealthTactic) -> String {
        let tower = state.buildings.contains(.watchtower) ? 1 : 0
        switch tactic {
        case .attack: return state.combat?.intent == .brace ? "1 damage" : "\(4 + tower)–\(5 + tower) damage"
        case .guard: return state.combat?.intent == .rush ? "Block 4 · deal 2" : "Block 4"
        case .flank: return "Move · deal \((state.combat?.intent == .brace ? 5 : 2) + tower)"
        case .rally: return state.combat?.rallyAvailable == false ? "Used this patrol" : "+5 health · once"
        case .retreat: return "Keep land · leave"
        }
    }

    private func tacticSymbol(_ tactic: CommonwealthTactic) -> String {
        switch tactic {
        case .attack: "bolt.fill"
        case .guard: "shield.lefthalf.filled"
        case .flank: "arrow.triangle.branch"
        case .rally: "heart.fill"
        case .retreat: "arrow.uturn.backward"
        }
    }
}

private enum CommonwealthSection: String, CaseIterable, Identifiable {
    case land = "Land", people = "People", journal = "Journal"
    var id: String { rawValue }
}

struct CommonwealthPortrait: View {
    let index: Int
    let size: CGFloat
    var body: some View {
        Group {
            if index < 3 {
                Image("BriarGlenCitizens")
                    .resizable().frame(width: size * 3, height: size)
                    .offset(x: CGFloat(1 - max(0, index)) * size)
                    .frame(width: size, height: size).clipped()
            } else {
                ZStack {
                    AppColors.brandSoft
                    Image(systemName: index == 3 ? "tree.fill" : "hammer.fill")
                        .font(.title2).foregroundStyle(AppColors.brand)
                }.frame(width: size, height: size)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}

private struct CommonwealthBattlefield: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let combat: CommonwealthCombat
    private var boardHeight: CGFloat { dynamicTypeSize.isAccessibilitySize ? 420 : 230 }
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("You  \(combat.playerHealth)/\(combat.playerMaximumHealth)", systemImage: "heart.fill")
                Spacer()
                Text("Rider  \(combat.enemyHealth)/\(combat.enemyMaximumHealth)")
            }.font(.appBody(.caption, weight: .bold)).foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            ZStack {
                Image("BriarGlenValley").resizable().scaledToFill()
                    .frame(height: boardHeight).clipped()
                Color.black.opacity(0.24)
                VStack(spacing: 8) {
                    HStack(spacing: 14) {
                        ForEach(0..<3) { lane in
                            battleCell(occupied: combat.enemyLane == lane, enemy: true, lane: lane)
                        }
                    }
                    HStack {
                        Image(systemName: "arrow.down").foregroundStyle(.white.opacity(0.6))
                        Text(combat.intent.title.uppercased()).font(.appBody(.caption2, weight: .bold)).tracking(1)
                        Image(systemName: "arrow.down").foregroundStyle(.white.opacity(0.6))
                    }.foregroundStyle(.white)
                    HStack(spacing: 14) {
                        ForEach(0..<3) { lane in
                            battleCell(occupied: combat.playerLane == lane, enemy: false, lane: lane)
                        }
                    }
                }.padding(10)
            }.frame(height: boardHeight).clipShape(RoundedRectangle(cornerRadius: 12))
            HStack {
                Text("West cover")
                Spacer()
                Text("Open road")
                Spacer()
                Text("East cover")
            }.font(.appBody(.caption2, weight: .semibold)).foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(red: 0.15, green: 0.21, blue: 0.18), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Battle at the crossing. You have \(combat.playerHealth) health and are in lane \(combat.playerLane + 1). Enemy has \(combat.enemyHealth) health in lane \(combat.enemyLane + 1). \(combat.intent.detail)")
    }

    private func battleCell(occupied: Bool, enemy: Bool, lane: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(occupied ? (enemy ? Color(red: 0.5, green: 0.20, blue: 0.14) : AppColors.brand).opacity(0.85) : Color.black.opacity(0.20))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(occupied ? 0.85 : 0.3), lineWidth: occupied ? 2 : 1))
            if occupied {
                VStack(spacing: 2) {
                    Image("BriarGlenFighters")
                        .resizable().frame(width: 108, height: 72)
                        .offset(x: enemy ? -27 : 27)
                        .frame(width: 54, height: 72).clipped()
                    Text(enemy ? "RIDER" : "YOU")
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                }
            } else {
                Image(systemName: lane == 1 ? "road.lanes" : "shield.lefthalf.filled")
                    .foregroundStyle(.white.opacity(0.6)).font(.title3)
            }
        }.frame(maxWidth: .infinity).frame(height: dynamicTypeSize.isAccessibilitySize ? 140 : 92)
    }
}
