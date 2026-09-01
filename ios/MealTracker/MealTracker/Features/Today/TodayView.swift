import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDraft: MealDraft?
    @State private var editingEntry: MealEntry?
    @State private var inspectingEntry: MealEntry?
    @State private var showingCapture = false
    @State private var showingEndDay = false
    @State private var showingRestaurant = false
    @State private var openCaptureAfterRestaurant = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.lg) {
                    DailyProgressCard(day: store.today)
                    MacroSnapshotCard(summary: store.today.nutrition, targets: store.settings.targets)
                    TodayLogSection(
                        day: store.today,
                        onSelect: { inspectingEntry = $0 }
                    )
                    HabitRail(streak: store.streak.current, resources: store.resourceBalance)

                    if let confirmation = store.recentConfirmation {
                        RecentConfirmationCard(
                            confirmation: confirmation,
                            onEdit: { editingEntry = confirmation.entry },
                            onUndo: store.undoRecent
                        )
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    }

                    PredictionSection(
                        predictions: store.predictions,
                        onSelect: { selectedDraft = store.draft(for: $0) },
                        onRestaurant: { showingRestaurant = true }
                    )

                    SkipNextMealButton(day: store.today) { category in
                        store.markSkipped(category, dayIdentifier: store.today.dayIdentifier)
                    }

                    Button {
                        showingEndDay = true
                    } label: {
                        HStack {
                            LucideIcon(icon: .checkCircle, size: 18)
                            Text("End day")
                        }
                    }
                    .buttonStyle(QuietActionButtonStyle())
                    .accessibilityIdentifier("today.endDay")
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        LucideIcon(icon: .settings, size: 21)
                            .foregroundStyle(AppColors.ink)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier("today.settings")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CaptureBar { showingCapture = true }
            }
        }
        .sheet(item: $selectedDraft) { draft in
            MealDetailSheet(initialDraft: draft) { finalDraft in
                store.log(draft: finalDraft)
                selectedDraft = nil
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingEntry) { entry in
            EntryEditorSheet(entry: entry) { updated in
                store.updateEntry(updated)
                editingEntry = nil
            } onDelete: {
                store.deleteEntry(entry)
                editingEntry = nil
            }
        }
        .sheet(item: $inspectingEntry) { entry in
            LoggedMealDetailSheet(entry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingCapture) {
            CaptureSheet()
                .presentationDetents([.height(420), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEndDay) {
            EndDaySheet(day: store.today) { categories in
                store.endDay(skipping: categories)
                showingEndDay = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRestaurant, onDismiss: {
            if openCaptureAfterRestaurant {
                openCaptureAfterRestaurant = false
                showingCapture = true
            }
        }) {
            RestaurantModeView {
                openCaptureAfterRestaurant = true
                showingRestaurant = false
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private var greeting: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: Date())
        switch hour {
        case 4..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

private struct TodayLogSection: View {
    let day: DaySnapshot
    let onSelect: (MealEntry) -> Void

    private var entries: [MealEntry] {
        day.entries.sorted { $0.consumedAt < $1.consumedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S LOG")
                        .font(.appBody(.caption2, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(AppColors.muted)
                        .accessibilityIdentifier("today.log")
                    Text(entries.isEmpty ? "Nothing logged yet" : entryCount)
                        .font(.appBody(.caption))
                        .foregroundStyle(AppColors.muted)
                }
                Spacer()
                if !entries.isEmpty {
                    Text("Tap for ingredients")
                        .font(.appBody(.caption2, weight: .semibold))
                        .foregroundStyle(AppColors.brand)
                }
            }

            if entries.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    LucideIcon(icon: .utensils, size: 20)
                        .foregroundStyle(AppColors.brand)
                    Text("Your meals and their macro breakdowns will appear here.")
                        .font(.appBody(.callout))
                        .foregroundStyle(AppColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appSurface()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        Button { onSelect(entry) } label: {
                            TodayLogRow(entry: entry)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Shows meal and ingredient nutrition details")
                        .accessibilityIdentifier("today.entry.\(entry.id.uuidString)")

                        if index < entries.count - 1 {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .appSurface()
            }
        }
    }

    private var entryCount: String {
        "\(entries.count) \(entries.count == 1 ? "meal" : "meals") logged"
    }
}

private struct TodayLogRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let entry: MealEntry

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    identity
                    macroLine
                }
            } else {
                HStack(spacing: AppSpacing.sm) {
                    identity
                    Spacer(minLength: AppSpacing.xs)
                    macroLine
                    LucideIcon(icon: .chevronRight, size: 17)
                        .foregroundStyle(AppColors.brand)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .frame(minHeight: 68)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var identity: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle().fill(AppColors.brandSoft)
                Text(String(entry.category.title.prefix(1)))
                    .font(.appBody(.caption, weight: .bold))
                    .foregroundStyle(AppColors.brand)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.appBody(.callout, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                    .multilineTextAlignment(.leading)
                Text("\(entry.category.title) • \(entry.consumedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.appBody(.caption2))
                    .foregroundStyle(AppColors.muted)
            }
        }
    }

    private var macroLine: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
            Text(nutritionValue(entry.nutrition.calories, unit: "kcal"))
                .font(.appBody(.callout, weight: .bold))
                .foregroundStyle(AppColors.ink)
            Text("P \(shortValue(entry.nutrition.protein)) • C \(shortValue(entry.nutrition.carbohydrates)) • F \(shortValue(entry.nutrition.fat))")
                .font(.appBody(.caption2, weight: .medium))
                .foregroundStyle(AppColors.muted)
        }
    }

    private var accessibilitySummary: String {
        "\(entry.name), \(entry.category.title), \(nutritionValue(entry.nutrition.calories, unit: "calories")), protein \(nutritionValue(entry.nutrition.protein, unit: "grams")), carbohydrates \(nutritionValue(entry.nutrition.carbohydrates, unit: "grams")), fat \(nutritionValue(entry.nutrition.fat, unit: "grams"))"
    }

    private func shortValue(_ value: Double?) -> String {
        value.map { "\(Int($0.rounded()))g" } ?? "—"
    }

    private func nutritionValue(_ value: Double?, unit: String) -> String {
        value.map { "\(Int($0.rounded())) \(unit)" } ?? "unknown"
    }
}

private struct DailyProgressCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let day: DaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        progressRing
                        progressCopy
                    }
                } else {
                    HStack(alignment: .center, spacing: AppSpacing.md) {
                        progressRing
                        progressCopy
                    }
                }
            }

            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.xs) {
                    statusLabels
                }
            } else {
                HStack(spacing: AppSpacing.xs) { statusLabels }
            }
        }
        .padding(AppSpacing.md)
        .appSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(completenessLabel)
        .accessibilityIdentifier("today.completeness")
    }

    private var progressRing: some View {
        CompletenessRing(day: day)
            .frame(width: 92, height: 92)
    }

    private var progressCopy: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("DAILY LOG")
                .font(.appBody(.caption2, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AppColors.muted)
            Text(day.isComplete ? "Today is fully resolved" : "\(day.resolvedCount) of 4 moments")
                .font(.appDisplay(.title3, weight: .bold))
                .foregroundStyle(AppColors.ink)
            Text(day.isComplete ? "Complete through logging or an explicit none." : "Logging completeness—not macro perfection.")
                .font(.appBody(.caption))
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusLabels: some View {
        ForEach(MealCategory.allCases) { category in
            CategoryStatusLabel(category: category, resolution: day.resolution(for: category))
                .frame(maxWidth: .infinity)
        }
    }

    private var completenessLabel: String {
        let parts = MealCategory.allCases.map {
            "\($0.title), \(day.resolution(for: $0).accessibilityDescription)"
        }
        return "Daily log, \(day.resolvedCount) of 4 resolved. \(parts.joined(separator: ". "))"
    }
}

private struct CompletenessRing: View {
    let day: DaySnapshot

    var body: some View {
        ZStack {
            ForEach(Array(MealCategory.allCases.enumerated()), id: \.element.id) { index, category in
                segment(index: index, resolution: day.resolution(for: category))
            }
            VStack(spacing: 1) {
                Text("\(day.resolvedCount)/4")
                    .font(.appDisplay(.title3, weight: .bold))
                Text("resolved")
                    .font(.appBody(.caption2, weight: .medium))
                    .foregroundStyle(AppColors.muted)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func segment(index: Int, resolution: CategoryResolution) -> some View {
        let start = Double(index) / 4 + 0.012
        let end = Double(index + 1) / 4 - 0.012
        switch resolution {
        case .logged:
            Circle()
                .trim(from: start, to: end)
                .stroke(AppColors.brand, style: StrokeStyle(lineWidth: 9, lineCap: .butt))
                .rotationEffect(.degrees(-90))
        case .skipped:
            Circle()
                .trim(from: start, to: end)
                .stroke(AppColors.skipped, style: StrokeStyle(lineWidth: 7, lineCap: .butt, dash: [3, 3]))
                .rotationEffect(.degrees(-90))
        case .unresolved:
            Circle()
                .trim(from: start, to: end)
                .stroke(AppColors.border, style: StrokeStyle(lineWidth: 7, lineCap: .butt))
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct CategoryStatusLabel: View {
    let category: MealCategory
    let resolution: CategoryResolution

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            Group {
                switch resolution {
                case .logged: LucideIcon(icon: .check, size: 14)
                case .skipped: LucideIcon(icon: .skipForward, size: 14)
                case .unresolved: LucideIcon(icon: .circle, size: 14)
                }
            }
            .foregroundStyle(resolution == .logged ? AppColors.brand : AppColors.muted)
            Text(category.title)
                .font(.appBody(.caption2, weight: .medium))
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(minHeight: 34)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.title), \(resolution.accessibilityDescription)")
    }
}

private struct MacroSnapshotCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let summary: NutritionSummary
    let targets: NutritionTargets

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("NEUTRAL SNAPSHOT")
                    .font(.appBody(.caption2, weight: .bold))
                    .tracking(1.2)
                Spacer()
                if summary.containsEstimate || summary.containsUnknown {
                    HStack(spacing: AppSpacing.xxs) {
                        LucideIcon(icon: .info, size: 13)
                        Text(summary.containsUnknown ? "Some values unknown" : "Includes estimates")
                    }
                    .font(.appBody(.caption2))
                }
            }
            .foregroundStyle(AppColors.muted)

            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                    macroMetrics
                }
            } else {
                HStack(alignment: .top, spacing: AppSpacing.sm) { macroMetrics }
            }
        }
        .padding(AppSpacing.md)
        .appSurface()
        .accessibilityIdentifier("today.macros")
    }

    @ViewBuilder
    private var macroMetrics: some View {
        MacroMetric(label: "Calories", value: summary.calories, target: targets.calories, unit: "")
        MacroMetric(label: "Protein", value: summary.protein, target: targets.protein, unit: "g")
        MacroMetric(label: "Fat", value: summary.fat, target: targets.fat, unit: "g")
        MacroMetric(label: "Carbs", value: summary.carbohydrates, target: targets.carbohydrates, unit: "g")
    }
}

private struct MacroMetric: View {
    let label: String
    let value: Double
    let target: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(Int(value.rounded()))\(unit)")
                .font(.appBody(.headline, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(label) / \(Int(target))\(unit)")
                .font(.appBody(.caption2))
                .foregroundStyle(AppColors.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            GeometryReader { proxy in
                Capsule()
                    .fill(AppColors.border)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.ink.opacity(0.55))
                            .frame(width: proxy.size.width * min(value / max(target, 1), 1))
                    }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(Int(value.rounded())) of \(Int(target)) \(unit)")
    }
}

private struct HabitRail: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let streak: Int
    let resources: Int

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 0) {
                    railItem(icon: .flame, title: "Current streak", value: "\(streak) \(streak == 1 ? "day" : "days")")
                    Divider()
                    railItem(icon: .gem, title: "Banked resources", value: "\(resources) energy")
                }
            } else {
                HStack(spacing: 0) {
                    railItem(icon: .flame, title: "Current streak", value: "\(streak) \(streak == 1 ? "day" : "days")")
                    Divider().padding(.vertical, AppSpacing.xs)
                    railItem(icon: .gem, title: "Banked resources", value: "\(resources) energy")
                }
            }
        }
        .appSurface()
    }

    private func railItem(icon: Lucide, title: String, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            LucideIcon(icon: icon, size: 20)
                .foregroundStyle(AppColors.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.appBody(.caption2)).foregroundStyle(AppColors.muted)
                Text(value).font(.appBody(.subheadline, weight: .bold)).foregroundStyle(AppColors.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 58)
    }
}

private struct RecentConfirmationCard: View {
    let confirmation: RecentConfirmation
    let onEdit: () -> Void
    let onUndo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                ZStack {
                    Circle().fill(AppColors.brand)
                    LucideIcon(icon: .check, size: 16).foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Logged \(confirmation.entry.name)")
                        .font(.appBody(.subheadline, weight: .bold))
                        .foregroundStyle(AppColors.ink)
                    Text("+\(RewardEngine.mealAmount) energy • totals updated")
                        .font(.appBody(.caption))
                        .foregroundStyle(AppColors.muted)
                }
                Spacer()
            }
            .accessibilityIdentifier("recent.confirmation")
            if let disclosure = confirmation.disclosure {
                Text(disclosure)
                    .font(.appBody(.caption2))
                    .foregroundStyle(AppColors.muted)
            }
            HStack {
                Button("Edit", action: onEdit)
                    .accessibilityIdentifier("recent.edit")
                Spacer()
                Button("Undo", action: onUndo)
                    .accessibilityIdentifier("recent.undo")
            }
            .font(.appBody(.callout, weight: .semibold))
            .foregroundStyle(AppColors.brand)
        }
        .padding(AppSpacing.md)
        .appSurface(prominent: true)
    }
}

private struct PredictionSection: View {
    let predictions: [MealPrediction]
    let onSelect: (MealPrediction) -> Void
    let onRestaurant: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT MEAL")
                        .font(.appBody(.caption2, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(AppColors.muted)
                    Text("You can log a likely meal in seconds.")
                        .font(.appBody(.caption))
                        .foregroundStyle(AppColors.muted)
                }
                Spacer()
                Button("Restaurant", action: onRestaurant)
                    .font(.appBody(.caption, weight: .semibold))
                    .foregroundStyle(AppColors.brand)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("today.restaurant")
            }

            if predictions.isEmpty {
                ContentUnavailableView {
                    VStack(spacing: AppSpacing.xs) {
                        LucideIcon(icon: .utensils, size: 28)
                            .foregroundStyle(AppColors.brand)
                        Text("No suggestions yet")
                            .font(.appDisplay(.title3, weight: .bold))
                    }
                } description: {
                    Text("Use capture below. Logged meals—not searches—teach future suggestions.")
                }
                .frame(minHeight: 180)
            } else {
                ForEach(Array(predictions.enumerated()), id: \.element.id) { index, prediction in
                    PredictionCard(prediction: prediction, prominent: index == 0) {
                        onSelect(prediction)
                    }
                }
            }
        }
    }
}

private struct PredictionCard: View {
    let prediction: MealPrediction
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(prominent ? AppColors.brand : AppColors.brandSoft)
                    LucideIcon(icon: foodIcon, size: 25)
                        .foregroundStyle(prominent ? Color.white : AppColors.brand)
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(prediction.template.name)
                        .font(.appBody(.headline, weight: .bold))
                        .foregroundStyle(AppColors.ink)
                        .multilineTextAlignment(.leading)
                    Text(prediction.reason)
                        .font(.appBody(.caption))
                        .foregroundStyle(AppColors.muted)
                        .multilineTextAlignment(.leading)
                    Text(estimateText)
                        .font(.appBody(.caption, weight: .semibold))
                        .foregroundStyle(AppColors.ink)
                }
                Spacer(minLength: AppSpacing.xs)
                LucideIcon(icon: .chevronRight, size: 19)
                    .foregroundStyle(AppColors.brand)
            }
            .padding(AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 76)
        .appSurface(prominent: prominent)
        .accessibilityLabel("\(prediction.template.name). \(prediction.reason). \(estimateText). Review and log.")
        .accessibilityIdentifier("prediction.\(prediction.template.id)")
    }

    private var estimateText: String {
        let draft = MealDraft(template: prediction.template)
        let calories = Int((draft.nutrition.calories ?? 0).rounded())
        let protein = Int((draft.nutrition.protein ?? 0).rounded())
        return "\(calories) kcal • \(protein)g protein"
    }

    private var foodIcon: Lucide {
        let name = prediction.template.name.lowercased()
        if name.contains("wrap") || name.contains("toast") { return .sandwich }
        if name.contains("bowl") || name.contains("pasta") { return .soup }
        return .salad
    }
}

private struct SkipNextMealButton: View {
    let day: DaySnapshot
    let onSkip: (MealCategory) -> Void

    var unresolved: [MealCategory] {
        MealCategory.allCases.filter { day.resolution(for: $0) == .unresolved }
    }

    var body: some View {
        if !unresolved.isEmpty {
            Menu {
                ForEach(unresolved) { category in
                    Button("No \(category.title)") { onSkip(category) }
                        .accessibilityIdentifier("skip.\(category.rawValue)")
                }
            } label: {
                HStack {
                    LucideIcon(icon: .skipForward, size: 17)
                    Text("Mark Skipped / None")
                    Spacer()
                    LucideIcon(icon: .chevronRight, size: 16)
                }
                .font(.appBody(.callout, weight: .semibold))
                .foregroundStyle(AppColors.muted)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("today.skipMenu")
        }
    }
}

private struct CaptureBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle().fill(AppColors.brand)
                    LucideIcon(icon: .sparkles, size: 17).foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)
                Text("What did you eat?")
                    .font(.appBody(.callout, weight: .semibold))
                    .foregroundStyle(AppColors.ink)
                Spacer()
                LucideIcon(icon: .mic, size: 19)
                LucideIcon(icon: .camera, size: 19)
            }
            .foregroundStyle(AppColors.brand)
            .padding(.horizontal, AppSpacing.sm)
            .frame(minHeight: 54)
            .background(AppColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.brand.opacity(0.42), lineWidth: 1.5)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 14, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(.ultraThinMaterial)
        .accessibilityLabel("Log with text, voice, camera, or photo")
        .accessibilityIdentifier("today.capture")
    }
}
