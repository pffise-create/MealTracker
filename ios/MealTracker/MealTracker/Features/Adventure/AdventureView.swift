import SwiftUI

struct AdventureView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selection: AdventureSection = .world
    @AccessibilityFocusState private var isOutcomeFocused: Bool

    private var encounter: AdventureEncounter {
        AdventureEngine.encounter(for: store.adventure)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                    expeditionHeader
                    sectionPicker

                    switch selection {
                    case .world: worldView
                    case .company: companyView
                    case .records: recordsView
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background)
            .navigationTitle("Adventure")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var expeditionHeader: some View {
        ZStack(alignment: .bottomLeading) {
            AdventureAtmosphere()
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    AdventureSigil(isAlive: store.adventure.hero.isAlive)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.adventure.hero.isAlive ? "ACTIVE EXPEDITION" : "LEGACY PRESERVED")
                            .font(.appBody(.caption2, weight: .bold))
                            .tracking(1.35)
                            .foregroundStyle(AdventurePalette.mist)
                        Text(store.adventure.hero.name)
                            .font(.appDisplay(.title2, weight: .bold))
                            .foregroundStyle(AdventurePalette.parchment)
                        Text(store.adventure.hero.title)
                            .font(.appBody(.subheadline))
                            .foregroundStyle(AdventurePalette.mist)
                    }
                    Spacer(minLength: 0)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.lg) { headerMetrics }
                    VStack(alignment: .leading, spacing: AppSpacing.sm) { headerMetrics }
                }
            }
            .padding(AppSpacing.xl)
        }
        .frame(minHeight: 196)
        // This is a decorative summary whose complete value is exposed as one
        // accessibility label. Capping only this dense composition prevents it
        // from consuming several screens while the primary game copy still
        // honors the user's full Dynamic Type setting.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous)
                .stroke(AdventurePalette.brass.opacity(0.45), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(store.adventure.hero.name), \(store.adventure.hero.isAlive ? "alive" : "dead"). "
            + "Health \(store.adventure.hero.health) of \(store.adventure.hero.maximumHealth). "
            + "\(store.adventureEnergyBalance) energy ready."
        )
    }

    @ViewBuilder
    private var headerMetrics: some View {
        metric(icon: .heartPulse, value: "\(store.adventure.hero.health)/\(store.adventure.hero.maximumHealth)", label: "health")
        metric(icon: .gem, value: "\(store.adventureEnergyBalance)", label: "energy")
        metric(icon: .mapPin, value: "\(store.adventure.discoveredLocations.count)/5", label: "region")
    }

    private func metric(icon: Lucide, value: String, label: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            LucideIcon(icon: icon, size: 16).foregroundStyle(AdventurePalette.brass)
            Text(value)
                .font(.appBody(.callout, weight: .bold))
                .foregroundStyle(AdventurePalette.parchment)
                .contentTransition(.numericText())
            Text(label).font(.appBody(.caption)).foregroundStyle(AdventurePalette.mist)
        }
    }

    private var sectionPicker: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.xxs) {
                    ForEach(AdventureSection.allCases) { section in
                        sectionButton(section)
                    }
                }
            } else {
                HStack(spacing: AppSpacing.xxs) {
                    ForEach(AdventureSection.allCases) { section in
                        sectionButton(section)
                    }
                }
            }
        }
        .padding(AppSpacing.xxs)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        }
        // Navigation labels remain large and readable, but do not crowd the
        // full-size story content off the first screen at AX XXXL.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func sectionButton(_ section: AdventureSection) -> some View {
        Button {
            selection = section
            Haptics.selection()
        } label: {
            Text(section.title)
                .font(.appBody(.subheadline, weight: .semibold))
                .foregroundStyle(selection == section ? Color.white : AppColors.muted)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? AppSpacing.xs : 0)
                .background(selection == section ? AppColors.brand : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
        }
        .accessibilityAddTraits(selection == section ? .isSelected : [])
    }

    private var worldView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            energyLedger
            if let outcome = store.adventure.latestOutcome {
                outcomeCard(outcome).accessibilityFocused($isOutcomeFocused)
            }
            encounterCard
            regionMap
        }
    }

    private var energyLedger: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppSpacing.md) { energyLedgerContent }
            VStack(alignment: .leading, spacing: AppSpacing.sm) { energyLedgerContent }
        }
        .padding(.horizontal, AppSpacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("adventure.balance")
    }

    @ViewBuilder
    private var energyLedgerContent: some View {
        Label {
            Text("\(store.adventureEnergyBalance) energy ready")
                .font(.appBody(.headline, weight: .bold))
        } icon: {
            LucideIcon(icon: .gem, size: 20).foregroundStyle(AppColors.brand)
        }
        Spacer(minLength: 0)
        Text("\(store.resourceBalance) earned · \(store.adventure.energySpent) spent")
            .font(.appBody(.caption, weight: .medium))
            .foregroundStyle(AppColors.muted)
    }

    private var regionMap: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeading("The Blue Verge", detail: "A coast holding one last impossible road")
            AdventureRegionMap(discovered: store.adventure.discoveredLocations, current: encounter.location)
        }
    }

    private var encounterCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(encounter.eyebrow)
                    .font(.appBody(.caption2, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(store.adventure.hero.isAlive ? AppColors.brand : AdventurePalette.rust)
                Text(encounter.title)
                    .font(.appDisplay(.title2, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                Text(encounter.narration)
                    .font(.appBody(.body))
                    .foregroundStyle(AppColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if encounter.choices.isEmpty {
                naturalPause
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(encounter.choices.enumerated()), id: \.element.id) { index, choice in
                        choiceButton(choice, isPrimary: index == 0)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .appSurface()
        .accessibilityIdentifier("adventure.encounter")
    }

    private func choiceButton(_ choice: AdventureChoiceID, isPrimary: Bool) -> some View {
        let canAfford = store.adventureEnergyBalance >= choice.energyCost
        let forecast = AdventureEngine.forecast(for: choice, in: store.adventure)
        return Button { resolve(choice) } label: {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(choice.title)
                        .font(.appBody(.headline, weight: .bold))
                        .foregroundStyle(isPrimary ? Color.white : AppColors.ink)
                        .multilineTextAlignment(.leading)
                    Text(choice.approach)
                        .font(.appBody(.caption))
                        .foregroundStyle(isPrimary ? Color.white.opacity(0.78) : AppColors.muted)
                        .multilineTextAlignment(.leading)
                    if let forecast {
                        Text(forecast.summary)
                            .font(.appBody(.caption2, weight: .bold))
                            .foregroundStyle(isPrimary ? AdventurePalette.parchment : AppColors.brand)
                    }
                }
                Spacer(minLength: AppSpacing.xs)
                Text(choice.energyCost == 0 ? "FREE" : "−\(choice.energyCost)")
                    .font(.appDisplay(.title3, weight: .bold))
                    .foregroundStyle(isPrimary ? AdventurePalette.parchment : AppColors.brand)
                LucideIcon(icon: .arrowRight, size: 18)
                    .foregroundStyle(isPrimary ? Color.white : AppColors.brand)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(isPrimary ? AppColors.brand : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            .overlay {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                }
            }
            .opacity(canAfford ? 1 : 0.5)
        }
        .disabled(!canAfford)
        .accessibilityLabel(
            "\(choice.title), \(choice.energyCost == 0 ? "free" : "costs \(choice.energyCost) energy")"
            + (forecast.map { ", \($0.chancePercent) percent chance" } ?? "")
        )
        .accessibilityHint(canAfford ? choice.approach : "More energy is earned by logging eating occasions")
        .accessibilityIdentifier("adventure.choice.\(choice.rawValue)")
    }

    private func outcomeCard(_ outcome: AdventureOutcome) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppSpacing.lg) { outcomeContent(outcome) }
            VStack(alignment: .leading, spacing: AppSpacing.md) { outcomeContent(outcome) }
        }
        .padding(AppSpacing.lg)
        .background(AdventurePalette.outcomeSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous)
                .stroke(AdventurePalette.brass.opacity(0.6), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(outcomeAccessibilityLabel(outcome))
        .accessibilityIdentifier("adventure.outcome")
    }

    @ViewBuilder
    private func outcomeContent(_ outcome: AdventureOutcome) -> some View {
        if let roll = outcome.roll {
            AdventureDie(roll: roll)
        } else {
            ZStack {
                Circle().fill(AdventurePalette.brass.opacity(0.18))
                LucideIcon(icon: .flame, size: 30).foregroundStyle(AdventurePalette.brass)
            }
            .frame(width: 76, height: 76)
            .accessibilityHidden(true)
        }

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(outcome.roll?.succeeded == false ? "CONSEQUENCE" : "PATH RESOLVED")
                .font(.appBody(.caption2, weight: .bold))
                .tracking(1.25)
                .foregroundStyle(AdventurePalette.brass)
            Text(outcome.title)
                .font(.appDisplay(.title3, weight: .bold))
                .foregroundStyle(AdventurePalette.parchment)
            Text(outcome.detail)
                .font(.appBody(.subheadline))
                .foregroundStyle(AdventurePalette.mist)
                .fixedSize(horizontal: false, vertical: true)
            if let roll = outcome.roll {
                Text("d20 \(roll.die) + \(roll.modifier) = \(roll.total) · target \(roll.target)")
                    .font(.appBody(.caption, weight: .bold))
                    .foregroundStyle(roll.succeeded ? AdventurePalette.success : AdventurePalette.rust)
            }
        }
    }

    private var naturalPause: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            LucideIcon(icon: store.adventure.hero.isAlive ? .shieldCheck : .lock, size: 20)
                .foregroundStyle(store.adventure.hero.isAlive ? AppColors.brand : AdventurePalette.rust)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.adventure.hero.isAlive ? "Expedition complete" : "The road is closed")
                    .font(.appBody(.headline, weight: .bold)).foregroundStyle(AppColors.ink)
                Text(
                    store.adventure.hero.isAlive
                        ? "The Blue Verge is quiet. Future chapters will begin from this preserved state."
                        : "The world history remains in Records. No logging reward or permanent progress was removed."
                )
                .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
    }

    private var companyView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            sectionHeading("The company", detail: "People, wounds, and promises persist between sessions")
            heroSheet
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("COMPANIONS")
                    .font(.appBody(.caption2, weight: .bold)).tracking(1.3).foregroundStyle(AppColors.muted)
                ForEach(store.adventure.companions) { companion in companionRow(companion) }
            }
        }
    }

    private var heroSheet: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                AdventureSigil(isAlive: store.adventure.hero.isAlive, compact: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.adventure.hero.name)
                        .font(.appDisplay(.title3, weight: .bold)).foregroundStyle(AppColors.ink)
                    Text(store.adventure.hero.title)
                        .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
                    if store.adventure.hero.deaths > 0 {
                        Text("Returned once from the Ember Road")
                            .font(.appBody(.caption, weight: .semibold)).foregroundStyle(AdventurePalette.rust)
                    }
                }
                Spacer(minLength: 0)
                Text(store.adventure.hero.isAlive ? "ALIVE" : "FALLEN")
                    .font(.appBody(.caption2, weight: .bold)).tracking(1)
                    .foregroundStyle(store.adventure.hero.isAlive ? AppColors.brand : AdventurePalette.rust)
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Health")
                    Spacer()
                    Text("\(store.adventure.hero.health) of \(store.adventure.hero.maximumHealth)")
                }
                .font(.appBody(.caption, weight: .semibold)).foregroundStyle(AppColors.muted)
                HealthTrack(value: store.adventure.hero.health, maximum: store.adventure.hero.maximumHealth)
            }
        }
        .padding(AppSpacing.lg)
        .appSurface()
        .accessibilityElement(children: .combine)
    }

    private func companionRow(_ companion: AdventureCompanion) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(companion.isRecruited ? AppColors.brandSoft : AppColors.surface)
                LucideIcon(icon: companion.id == .sable ? .compass : .heartPulse, size: 25)
                    .foregroundStyle(companion.isRecruited ? AppColors.brand : AppColors.unresolved)
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text(companion.isRecruited ? companion.id.name : "Undiscovered companion")
                    .font(.appBody(.headline, weight: .bold)).foregroundStyle(AppColors.ink)
                Text(companion.isRecruited ? companion.id.role : companion.id.lockedCopy)
                    .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
                if companion.isRecruited {
                    Text(companion.id.ability)
                        .font(.appBody(.caption, weight: .semibold)).foregroundStyle(AppColors.brand)
                }
            }
            Spacer(minLength: 0)
            Text(companion.isRecruited ? "BOND \(companion.bond)" : "LOCKED")
                .font(.appBody(.caption2, weight: .bold)).tracking(0.8)
                .foregroundStyle(companion.isRecruited ? AppColors.brand : AppColors.unresolved)
        }
        .padding(AppSpacing.md)
        .appSurface()
        .accessibilityElement(children: .combine)
    }

    private var recordsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            sectionHeading("Expedition record", detail: "Authoritative state—not generated narration")
            questLog
            if let frontier = store.adventure.frontier { frontierRecord(frontier) }
            inventory
            legacyLedger
        }
    }

    private func frontierRecord(_ frontier: FrontierProgress) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("FRONTIER MASTERY")
                    .font(.appBody(.caption2, weight: .bold)).tracking(1.3).foregroundStyle(AppColors.muted)
                Spacer()
                Text("\(frontier.renown) RENOWN")
                    .font(.appBody(.caption2, weight: .bold)).foregroundStyle(AppColors.brand)
            }
            ForEach(frontier.traits) { trait in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trait.id.name).font(.appBody(.headline, weight: .semibold)).foregroundStyle(AppColors.ink)
                        Text(trait.id.detail).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                    }
                    Spacer()
                    Text("\(trait.rank)/2")
                        .font(.appDisplay(.title3, weight: .bold)).foregroundStyle(AppColors.brand)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(AppSpacing.lg)
        .appSurface()
    }

    private var questLog: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THE ASH BELOW GLASS")
                .font(.appBody(.caption2, weight: .bold)).tracking(1.4).foregroundStyle(AppColors.brand)
                .padding(.bottom, AppSpacing.md)
            ForEach(Array(store.adventure.quests.enumerated()), id: \.element.id) { index, quest in
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    VStack(spacing: 0) {
                        questMarker(quest.status)
                        if index < store.adventure.quests.count - 1 {
                            Rectangle()
                                .fill(quest.status == .complete ? AppColors.brand : AppColors.border)
                                .frame(width: 1)
                                .frame(minHeight: 50)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(quest.title)
                            .font(.appBody(.headline, weight: .semibold))
                            .foregroundStyle(quest.status == .locked ? AppColors.unresolved : AppColors.ink)
                        Text(quest.detail)
                            .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, AppSpacing.md)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(quest.title), \(quest.status.rawValue). \(quest.detail)")
            }
        }
        .padding(AppSpacing.lg)
        .appSurface()
    }

    private func questMarker(_ status: AdventureQuestStatus) -> some View {
        ZStack {
            Circle()
                .fill(status == .complete ? AppColors.brand : AppColors.surface)
                .overlay { Circle().stroke(status == .locked ? AppColors.border : AppColors.brand, lineWidth: 1.5) }
            if status == .complete {
                LucideIcon(icon: .check, size: 12, strokeWidth: 2.2).foregroundStyle(Color.white)
            } else if status == .active {
                Circle().fill(AppColors.brand).frame(width: 6, height: 6)
            }
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }

    private var inventory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("INVENTORY")
                .font(.appBody(.caption2, weight: .bold)).tracking(1.3).foregroundStyle(AppColors.muted)
            if store.adventure.inventory.isEmpty {
                Text("No carried relics. Opened roads and quest history remain.")
                    .font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
            } else {
                ForEach(store.adventure.inventory) { item in
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        ZStack {
                            Circle().fill(AdventurePalette.brass.opacity(0.14))
                            LucideIcon(icon: item.id == .emberShard ? .flame : .gem, size: 20)
                                .foregroundStyle(AdventurePalette.brass)
                        }
                        .frame(width: 42, height: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.id.name)
                                .font(.appBody(.headline, weight: .semibold)).foregroundStyle(AppColors.ink)
                            Text(item.id.detail)
                                .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                        }
                        Spacer(minLength: 0)
                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .font(.appBody(.caption, weight: .bold)).foregroundStyle(AppColors.muted)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(AppSpacing.lg)
        .appSurface()
    }

    private var legacyLedger: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("LEGACY")
                .font(.appBody(.caption2, weight: .bold)).tracking(1.3).foregroundStyle(AppColors.muted)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.xl) { legacyMetrics }
                VStack(alignment: .leading, spacing: AppSpacing.sm) { legacyMetrics }
            }
            Text("Death never removes discovered locations, companions, inventory, quest history, or earned logging rewards.")
                .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
        }
        .padding(AppSpacing.lg)
        .appSurface()
    }

    @ViewBuilder
    private var legacyMetrics: some View {
        recordMetric(value: "\(store.adventure.decisionsMade)", label: "choices")
        recordMetric(value: "\(store.adventure.companions.filter(\.isRecruited).count)", label: "companions")
        recordMetric(value: "\(store.adventure.hero.deaths)", label: "deaths")
    }

    private func recordMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.appDisplay(.title2, weight: .bold)).foregroundStyle(AppColors.ink)
            Text(label).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
        }
    }

    private func sectionHeading(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.appDisplay(.title2, weight: .bold)).foregroundStyle(AppColors.ink)
            Text(detail).font(.appBody(.subheadline)).foregroundStyle(AppColors.muted)
        }
    }

    private func resolve(_ choice: AdventureChoiceID) {
        if reduceMotion {
            store.chooseAdventure(choice)
        } else {
            withAnimation(.easeOut(duration: 0.24)) { store.chooseAdventure(choice) }
        }
        DispatchQueue.main.async { isOutcomeFocused = true }
    }

    private func outcomeAccessibilityLabel(_ outcome: AdventureOutcome) -> String {
        let rollCopy: String
        if let roll = outcome.roll {
            rollCopy = "Rolled \(roll.die), plus \(roll.modifier), total \(roll.total), target \(roll.target), \(roll.succeeded ? "success" : "failure")."
        } else {
            rollCopy = "No die roll."
        }
        return "Path resolved. \(outcome.title). \(rollCopy) \(outcome.detail)"
    }
}

private enum AdventureSection: String, CaseIterable, Identifiable {
    case world
    case company
    case records
    var id: String { rawValue }
    var title: String {
        switch self {
        case .world: "World"
        case .company: "Company"
        case .records: "Records"
        }
    }
}

private enum AdventurePalette {
    static let deepInk = Color(red: 0.025, green: 0.07, blue: 0.13)
    static let ocean = Color(red: 0.035, green: 0.19, blue: 0.34)
    static let electric = Color(red: 0.07, green: 0.36, blue: 1)
    static let brass = Color(red: 0.86, green: 0.69, blue: 0.36)
    static let parchment = Color(red: 0.95, green: 0.94, blue: 0.87)
    static let mist = Color(red: 0.72, green: 0.80, blue: 0.86)
    static let rust = Color(red: 0.91, green: 0.48, blue: 0.34)
    static let success = Color(red: 0.49, green: 0.84, blue: 0.67)
    static let outcomeSurface = Color(red: 0.035, green: 0.09, blue: 0.16)
}

private struct AdventureAtmosphere: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AdventurePalette.ocean, AdventurePalette.deepInk],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                let horizon = size.height * 0.64
                var ridge = Path()
                ridge.move(to: CGPoint(x: 0, y: horizon))
                ridge.addLine(to: CGPoint(x: size.width * 0.25, y: horizon * 0.76))
                ridge.addLine(to: CGPoint(x: size.width * 0.46, y: horizon * 0.92))
                ridge.addLine(to: CGPoint(x: size.width * 0.68, y: horizon * 0.57))
                ridge.addLine(to: CGPoint(x: size.width, y: horizon * 0.86))
                ridge.addLine(to: CGPoint(x: size.width, y: size.height))
                ridge.addLine(to: CGPoint(x: 0, y: size.height))
                ridge.closeSubpath()
                context.fill(ridge, with: .color(AdventurePalette.deepInk.opacity(0.72)))
                for index in 0..<7 {
                    let inset = CGFloat(index) * 15
                    let rect = CGRect(x: -30 + inset, y: horizon - 26 + inset * 0.25, width: size.width + 60 - inset * 2, height: 70 + inset)
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(AdventurePalette.electric.opacity(0.08)),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 8])
                    )
                }
                let star = CGRect(x: size.width * 0.78, y: size.height * 0.16, width: 4, height: 4)
                context.fill(Path(ellipseIn: star), with: .color(AdventurePalette.parchment.opacity(0.8)))
            }
            .accessibilityHidden(true)
        }
    }
}

private struct AdventureSigil: View {
    var isAlive: Bool
    var compact = false
    var body: some View {
        ZStack {
            Circle().fill(isAlive ? AdventurePalette.electric.opacity(0.2) : AdventurePalette.rust.opacity(0.18))
            Circle().stroke(AdventurePalette.brass.opacity(0.8), lineWidth: 1).padding(5)
            LucideIcon(icon: isAlive ? .compass : .flame, size: compact ? 25 : 31)
                .foregroundStyle(isAlive ? AdventurePalette.parchment : AdventurePalette.rust)
        }
        .frame(width: compact ? 56 : 68, height: compact ? 56 : 68)
        .accessibilityHidden(true)
    }
}

private struct AdventureDie: View {
    var roll: AdventureRoll
    var body: some View {
        ZStack {
            AdventureDieShape().fill(roll.succeeded ? AdventurePalette.brass : AdventurePalette.rust)
            AdventureDieShape().stroke(AdventurePalette.parchment.opacity(0.55), lineWidth: 1).padding(4)
            Text("\(roll.die)")
                .font(.appDisplay(.title2, weight: .bold)).foregroundStyle(AdventurePalette.deepInk)
        }
        .frame(width: 78, height: 82)
        .accessibilityHidden(true)
    }
}

private struct AdventureDieShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.31))
        path.addLine(to: CGPoint(x: rect.width * 0.83, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.17, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.31))
        path.closeSubpath()
        return path
    }
}

private struct HealthTrack: View {
    var value: Int
    var maximum: Int
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.border)
                Capsule()
                    .fill(value > 0 ? AppColors.brand : AdventurePalette.rust)
                    .frame(width: proxy.size.width * CGFloat(value) / CGFloat(max(1, maximum)))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

private struct AdventureRegionMap: View {
    var discovered: Set<AdventureLocationID>
    var current: AdventureLocationID
    private let positions: [AdventureLocationID: CGPoint] = [
        .emberwatch: CGPoint(x: 0.18, y: 0.76),
        .ridgeGate: CGPoint(x: 0.34, y: 0.53),
        .starfallFen: CGPoint(x: 0.56, y: 0.70),
        .saltSpire: CGPoint(x: 0.72, y: 0.39),
        .hollowCrown: CGPoint(x: 0.82, y: 0.18)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mapTexture
                ForEach(AdventureLocationID.allCases, id: \.rawValue) { location in
                    mapMarker(location, size: proxy.size)
                }
            }
        }
        .frame(height: 168)
        .background(AdventurePalette.deepInk)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.prominent, style: .continuous)
                .stroke(AdventurePalette.brass.opacity(0.35), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mapAccessibilityLabel)
    }

    private var mapTexture: some View {
        Canvas { context, canvasSize in
            let ordered = AdventureLocationID.allCases.compactMap { positions[$0] }.map {
                CGPoint(x: $0.x * canvasSize.width, y: $0.y * canvasSize.height)
            }
            var route = Path()
            if let first = ordered.first { route.move(to: first) }
            ordered.dropFirst().forEach { route.addLine(to: $0) }
            context.stroke(
                route,
                with: .linearGradient(
                    Gradient(colors: [AdventurePalette.brass.opacity(0.35), AdventurePalette.electric.opacity(0.8)]),
                    startPoint: ordered.first ?? .zero,
                    endPoint: ordered.last ?? CGPoint(x: canvasSize.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 7])
            )
            for index in 0..<9 {
                let inset = CGFloat(index) * 16
                let contour = CGRect(
                    x: -canvasSize.width * 0.1 + inset,
                    y: canvasSize.height * 0.08 + inset * 0.4,
                    width: canvasSize.width * 1.2 - inset * 2,
                    height: canvasSize.height * 0.88 - inset
                )
                context.stroke(Path(ellipseIn: contour), with: .color(AdventurePalette.mist.opacity(0.055)), lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }

    private func mapMarker(_ location: AdventureLocationID, size: CGSize) -> some View {
        let isDiscovered = discovered.contains(location)
        let isCurrent = current == location
        let point = positions[location] ?? .zero
        return VStack(spacing: 4) {
            ZStack {
                if isCurrent {
                    Circle().fill(AdventurePalette.electric.opacity(0.28)).frame(width: 36, height: 36)
                }
                Circle()
                    .fill(isDiscovered ? AdventurePalette.brass : AdventurePalette.deepInk)
                    .overlay {
                        Circle().stroke(isDiscovered ? AdventurePalette.parchment : AdventurePalette.mist.opacity(0.35), lineWidth: 1)
                    }
                    .frame(width: isCurrent ? 16 : 12, height: isCurrent ? 16 : 12)
            }
            Text(isDiscovered ? location.name : "Unknown")
                .font(.appBody(.caption2, weight: .bold))
                .foregroundStyle(isDiscovered ? AdventurePalette.parchment : AdventurePalette.mist.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(width: 96)
        .position(x: point.x * size.width, y: point.y * size.height)
    }

    private var mapAccessibilityLabel: String {
        let opened = AdventureLocationID.allCases.filter(discovered.contains).map(\.name).joined(separator: ", ")
        return "Map of the Blue Verge. Current location, \(current.name). Discovered: \(opened)."
    }
}
