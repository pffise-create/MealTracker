import SwiftUI

struct EndDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let day: DaySnapshot
    let onFinish: (Set<MealCategory>) -> Void
    @State private var categoriesToSkip: Set<MealCategory>

    init(day: DaySnapshot, onFinish: @escaping (Set<MealCategory>) -> Void) {
        self.day = day
        self.onFinish = onFinish
        _categoriesToSkip = State(
            initialValue: Set(MealCategory.allCases.filter { day.resolution(for: $0) == .unresolved })
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(day.isComplete ? "Day complete" : "Finish day")
                        .font(.appDisplay(.title2, weight: .bold))
                        .foregroundStyle(AppColors.ink)
                }

                VStack(spacing: AppSpacing.xs) {
                    ForEach(MealCategory.allCases) { category in
                        let resolution = day.resolution(for: category)
                        Button {
                            guard resolution == .unresolved else { return }
                            if categoriesToSkip.contains(category) {
                                categoriesToSkip.remove(category)
                            } else {
                                categoriesToSkip.insert(category)
                            }
                            Haptics.selection()
                        } label: {
                            HStack {
                                LucideIcon(
                                    icon: categoriesToSkip.contains(category) ? .checkCircle : statusIcon(resolution),
                                    size: 20
                                )
                                Text(category.title)
                                    .font(.appBody(.headline, weight: .semibold))
                                Spacer()
                                Text(categoriesToSkip.contains(category) ? "Skip" : resolution.accessibilityDescription)
                                    .font(.appBody(.caption))
                                    .foregroundStyle(AppColors.muted)
                            }
                            .foregroundStyle(categoriesToSkip.contains(category) ? AppColors.brand : AppColors.ink)
                            .padding(AppSpacing.md)
                            .appSurface(prominent: categoriesToSkip.contains(category))
                        }
                        .buttonStyle(.plain)
                        .disabled(resolution != .unresolved)
                        .accessibilityIdentifier("endDay.\(category.rawValue)")
                    }
                }
                Spacer()
                Button("Finish day") { onFinish(categoriesToSkip) }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityIdentifier("endDay.finish")
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
            .navigationTitle("End day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func statusIcon(_ resolution: CategoryResolution) -> Lucide {
        switch resolution {
        case .logged: .check
        case .skipped: .skipForward
        case .unresolved: .circle
        }
    }
}
