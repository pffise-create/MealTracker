import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var displayedMonth = Date()
    @State private var selectedDay: SelectedDay?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    streakSummary
                    CalendarCard(
                        displayedMonth: $displayedMonth,
                        days: store.days,
                        todayIdentifier: store.today.dayIdentifier,
                        onSelect: { selectedDay = SelectedDay(identifier: $0) }
                    )
                    historyLegend
                    recentDays
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("History")
        }
        .sheet(item: $selectedDay) { selected in
            DayDetailView(dayIdentifier: selected.identifier)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var streakSummary: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.sm) { summaryMetrics }
            } else {
                HStack(spacing: AppSpacing.sm) { summaryMetrics }
            }
        }
    }

    @ViewBuilder
    private var summaryMetrics: some View {
        summaryMetric(value: "\(store.streak.current)", label: "Current streak")
        summaryMetric(value: "\(store.streak.longest)", label: "Longest streak")
        summaryMetric(value: "\(store.lifetimeCompleteDayCount)", label: "Lifetime complete")
    }

    private func summaryMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.appDisplay(.title2, weight: .bold)).foregroundStyle(AppColors.ink)
            Text(label).font(.appBody(.caption)).foregroundStyle(AppColors.muted).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .padding(AppSpacing.sm)
        .appSurface()
    }

    private var historyLegend: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.xs) { legendItems }
            } else {
                HStack(spacing: AppSpacing.lg) { legendItems }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var legendItems: some View {
        legend(icon: .checkCircle, text: "Complete", color: AppColors.brand)
        legend(icon: .circleDashed, text: "Incomplete", color: AppColors.muted)
        legend(icon: .circle, text: "Current", color: AppColors.ink)
    }

    private func legend(icon: Lucide, text: String, color: Color) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            LucideIcon(icon: icon, size: 14).foregroundStyle(color)
            Text(text).font(.appBody(.caption)).foregroundStyle(AppColors.muted)
        }
    }

    private var recentDays: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("RECENT DAYS")
                .font(.appBody(.caption2, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AppColors.muted)
            ForEach(store.days.prefix(7)) { day in
                Button { selectedDay = SelectedDay(identifier: day.dayIdentifier) } label: {
                    HStack(spacing: AppSpacing.sm) {
                        LucideIcon(icon: day.isComplete ? .checkCircle : .circleDashed, size: 20)
                            .foregroundStyle(day.isComplete ? AppColors.brand : AppColors.muted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatted(day.dayIdentifier))
                                .font(.appBody(.headline, weight: .semibold))
                                .foregroundStyle(AppColors.ink)
                            Text(day.isComplete ? "All four moments resolved" : "\(day.resolvedCount) of 4 resolved")
                                .font(.appBody(.caption))
                                .foregroundStyle(AppColors.muted)
                        }
                        Spacer()
                        LucideIcon(icon: .chevronRight, size: 18).foregroundStyle(AppColors.brand)
                    }
                    .padding(AppSpacing.md)
                    .appSurface()
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("history.day.\(day.dayIdentifier)")
            }
        }
    }

    private func formatted(_ identifier: String) -> String {
        let timeZone = TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
        guard let date = LocalDayResolver.date(from: identifier, timeZone: timeZone) else { return identifier }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

private struct CalendarCard: View {
    @Binding var displayedMonth: Date
    let days: [DaySnapshot]
    let todayIdentifier: String
    let onSelect: (String) -> Void

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .autoupdatingCurrent
        return calendar
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Button { shiftMonth(-1) } label: {
                    LucideIcon(icon: .chevronRight, size: 19)
                        .rotationEffect(.degrees(180))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.appDisplay(.title3, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                Spacer()
                Button { shiftMonth(1) } label: {
                    LucideIcon(icon: .chevronRight, size: 19).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next month")
            }
            HStack {
                ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.appBody(.caption2, weight: .bold))
                        .foregroundStyle(AppColors.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 6) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(minHeight: 44)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .appSurface()
        .accessibilityIdentifier("history.calendar")
    }

    private func dayCell(_ date: Date) -> some View {
        let identifier = LocalDayResolver.identifier(for: date, in: calendar.timeZone)
        let snapshot = days.first { $0.dayIdentifier == identifier }
        let isToday = identifier == todayIdentifier
        return Button { onSelect(identifier) } label: {
            ZStack {
                if snapshot?.isComplete == true {
                    Circle().fill(AppColors.brand)
                } else if snapshot != nil {
                    Circle().stroke(AppColors.muted, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                } else if isToday {
                    Circle().stroke(AppColors.ink, lineWidth: 1.5)
                }
                Text("\(calendar.component(.day, from: date))")
                    .font(.appBody(.callout, weight: isToday ? .bold : .medium))
                    .foregroundStyle(snapshot?.isComplete == true ? Color.white : AppColors.ink)
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayAccessibility(identifier: identifier, snapshot: snapshot, isToday: isToday))
        .accessibilityIdentifier("calendar.\(identifier)")
    }

    private var monthCells: [Date?] {
        guard
            let interval = calendar.dateInterval(of: .month, for: displayedMonth),
            let daysRange = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells = Array<Date?>(repeating: nil, count: leading)
        cells += daysRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func shiftMonth(_ value: Int) {
        if let date = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = date
            Haptics.selection()
        }
    }

    private func dayAccessibility(identifier: String, snapshot: DaySnapshot?, isToday: Bool) -> String {
        if isToday { return "Today, \(snapshot?.resolvedCount ?? 0) of 4 resolved" }
        if let snapshot { return "\(identifier), \(snapshot.isComplete ? "complete" : "incomplete")" }
        return "\(identifier), no log"
    }
}

private struct DayDetailView: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.dismiss) private var dismiss
    let dayIdentifier: String
    @State private var selectedDraft: MealDraft?
    @State private var editingEntry: MealEntry?

    private var day: DaySnapshot {
        store.day(identifier: dayIdentifier) ?? DaySnapshot(
            dayIdentifier: dayIdentifier,
            timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier,
            entries: [],
            skippedCategories: [],
            endedAt: nil
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(day.isComplete ? "Day complete" : "\(day.resolvedCount) of 4 resolved")
                            .font(.appDisplay(.title2, weight: .bold))
                            .foregroundStyle(AppColors.ink)
                        Text(day.isComplete
                             ? "Historical edits recalculate streaks automatically. Earned adventure progress remains banked."
                             : "Resolve the missing moments to recover any eligible streak chain.")
                            .font(.appBody(.subheadline))
                            .foregroundStyle(AppColors.muted)
                    }

                    ForEach(MealCategory.allCases) { category in
                        categorySection(category)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle(dayIdentifier)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
        .sheet(item: $selectedDraft) { draft in
            MealDetailSheet(initialDraft: draft) { finalDraft in
                store.log(draft: finalDraft, targetDayIdentifier: dayIdentifier)
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
    }

    private func categorySection(_ category: MealCategory) -> some View {
        let entries = day.entries.filter { $0.category == category }
        let resolution = day.resolution(for: category)
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(category.title)
                    .font(.appBody(.headline, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                Spacer()
                Text(resolution.accessibilityDescription)
                    .font(.appBody(.caption, weight: .semibold))
                    .foregroundStyle(resolution == .logged ? AppColors.brand : AppColors.muted)
            }

            ForEach(entries) { entry in
                Button { editingEntry = entry } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name).font(.appBody(.callout, weight: .semibold)).foregroundStyle(AppColors.ink)
                            Text("\(Int((entry.nutrition.calories ?? 0).rounded())) kcal • \(entry.portionLabel)")
                                .font(.appBody(.caption)).foregroundStyle(AppColors.muted)
                        }
                        Spacer()
                        LucideIcon(icon: .pencil, size: 17).foregroundStyle(AppColors.brand)
                    }
                    .padding(AppSpacing.sm)
                    .appSurface()
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("history.entry.\(entry.id.uuidString)")
            }

            HStack {
                if resolution == .unresolved {
                    Button("Mark None") {
                        store.markSkipped(category, dayIdentifier: dayIdentifier)
                    }
                    .accessibilityIdentifier("history.skip.\(category.rawValue)")
                } else if resolution == .skipped {
                    Button("Restore unresolved") {
                        store.markSkipped(category, dayIdentifier: dayIdentifier, skipped: false)
                    }
                }
                Spacer()
                Menu("Add food") {
                    ForEach(store.templatesForManualEntry()) { template in
                        Button(template.name) {
                            var draft = MealDraft(template: template)
                            draft.category = category
                            selectedDraft = draft
                        }
                    }
                }
                .accessibilityIdentifier("history.add.\(category.rawValue)")
            }
            .font(.appBody(.callout, weight: .semibold))
            .foregroundStyle(AppColors.brand)
            .frame(minHeight: 44)
        }
        .padding(AppSpacing.md)
        .appSurface(prominent: resolution == .unresolved)
    }
}

private struct SelectedDay: Identifiable {
    let identifier: String
    var id: String { identifier }
}
