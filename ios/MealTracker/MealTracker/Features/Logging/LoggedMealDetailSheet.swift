import SwiftUI

struct LoggedMealDetailSheet: View {
    @EnvironmentObject private var store: MealTrackerStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var entry: MealEntry
    @State private var showingEditor = false

    init(entry: MealEntry) {
        _entry = State(initialValue: entry)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    mealHeader
                    totalNutrition
                    ingredientBreakdown
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Meal details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showingEditor = true }
                        .accessibilityIdentifier("loggedMeal.edit")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EntryEditorSheet(entry: entry) { updated in
                store.updateEntry(updated)
                entry = updated
                showingEditor = false
            } onDelete: {
                store.deleteEntry(entry)
                showingEditor = false
                dismiss()
            }
        }
    }

    private var mealHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Text(entry.category.title.uppercased())
                    .font(.appBody(.caption2, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(AppColors.brand)
                Text("•")
                    .foregroundStyle(AppColors.muted)
                Text(entry.consumedAt.formatted(date: .omitted, time: .shortened))
                    .font(.appBody(.caption, weight: .medium))
                    .foregroundStyle(AppColors.muted)
            }

            Text(entry.name)
                .font(.appDisplay(.title, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("loggedMeal.detail")

            HStack(spacing: AppSpacing.xs) {
                Text(entry.portionLabel)
                if let quantity = entry.exactQuantity, !quantity.isEmpty {
                    Text("•")
                    Text(quantity)
                }
                if entry.provenance.isEstimate {
                    Text("•")
                    Text("AI estimate")
                }
            }
            .font(.appBody(.subheadline))
            .foregroundStyle(AppColors.muted)
        }
    }

    private var totalNutrition: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel("MEAL TOTAL")
                .accessibilityIdentifier("loggedMeal.total")
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                        totalMetrics
                    }
                } else {
                    HStack(alignment: .top, spacing: AppSpacing.sm) { totalMetrics }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.brandSoft)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
    }

    @ViewBuilder
    private var totalMetrics: some View {
        nutritionMetric("Calories", entry.nutrition.calories, unit: "kcal")
        nutritionMetric("Protein", entry.nutrition.protein, unit: "g")
        nutritionMetric("Carbs", entry.nutrition.carbohydrates, unit: "g")
        nutritionMetric("Fat", entry.nutrition.fat, unit: "g")
    }

    private var ingredientBreakdown: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 3) {
                sectionLabel("INGREDIENT BREAKDOWN")
                    .accessibilityIdentifier("loggedMeal.ingredients")
                Text("Each item’s contribution to the meal total.")
                    .font(.appBody(.caption))
                    .foregroundStyle(AppColors.muted)
            }

            if entry.ingredients.isEmpty {
                Text("No ingredient breakdown was captured for this meal.")
                    .font(.appBody(.callout))
                    .foregroundStyle(AppColors.muted)
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appSurface()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entry.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                        ingredientRow(ingredient)
                        if index < entry.ingredients.count - 1 {
                            Divider().padding(.leading, AppSpacing.md)
                        }
                    }
                }
                .appSurface()
            }

            if entry.correctionCount > 0 {
                Text("The meal total was edited after logging, so it may differ from the original ingredient estimates.")
                    .font(.appBody(.caption2))
                    .foregroundStyle(AppColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func ingredientRow(_ ingredient: LoggedIngredient) -> some View {
        let nutrition = ingredient.nutrition.scaled(by: entry.portionFactor)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(ingredient.name)
                    .font(.appBody(.callout, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: AppSpacing.sm)
                Text(value(nutrition.calories, unit: "kcal"))
                    .font(.appBody(.callout, weight: .bold))
                    .foregroundStyle(AppColors.ink)
            }
            Text("Protein \(value(nutrition.protein, unit: "g"))  •  Carbs \(value(nutrition.carbohydrates, unit: "g"))  •  Fat \(value(nutrition.fat, unit: "g"))")
                .font(.appBody(.caption))
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ingredient.name), \(value(nutrition.calories, unit: "calories")), protein \(value(nutrition.protein, unit: "grams")), carbohydrates \(value(nutrition.carbohydrates, unit: "grams")), fat \(value(nutrition.fat, unit: "grams"))")
        .accessibilityIdentifier("loggedMeal.ingredient.\(ingredient.id)")
    }

    private func nutritionMetric(_ label: String, _ amount: Double?, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value(amount, unit: unit))
                .font(.appBody(.headline, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.appBody(.caption2))
                .foregroundStyle(AppColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.appBody(.caption2, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(AppColors.muted)
    }

    private func value(_ amount: Double?, unit: String) -> String {
        amount.map { "\(Int($0.rounded())) \(unit)" } ?? "—"
    }
}
