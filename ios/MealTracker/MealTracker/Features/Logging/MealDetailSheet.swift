import SwiftUI

struct MealDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft: MealDraft
    @State private var customIngredient = ""
    @State private var isAddingIngredient = false
    let onLog: (MealDraft) -> Void

    init(initialDraft: MealDraft, onLog: @escaping (MealDraft) -> Void) {
        _draft = State(initialValue: initialDraft)
        self.onLog = onLog
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(draft.name)
                            .font(.appDisplay(.title, weight: .bold))
                            .foregroundStyle(AppColors.ink)
                        Text(draft.provenance == .starter
                             ? "Starter nutrition data. Your changes become the future default after logging."
                             : "Preselected from your recent logged behavior.")
                            .font(.appBody(.subheadline))
                            .foregroundStyle(AppColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    portionSection
                    ingredientSection
                    NutritionEstimateCard(facts: draft.nutrition, provenance: draft.provenance)

                    Button {
                        onLog(draft)
                    } label: {
                        HStack {
                            Text("Log meal")
                            LucideIcon(icon: .check, size: 19)
                        }
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .accessibilityHint("Adds this meal and updates today’s totals")
                    .accessibilityIdentifier("meal.log")
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Meal detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var portionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel("PORTION")
            Menu {
                ForEach(draft.portions) { portion in
                    Button {
                        withAnimation(reduceMotion ? nil : AppMotion.selection) {
                            draft.selectedPortionID = portion.id
                        }
                        Haptics.selection()
                    } label: {
                        HStack {
                            Text(portion.displayText)
                            if portion.id == draft.selectedPortionID {
                                LucideIcon(icon: .check, size: 14)
                            }
                        }
                    }
                    .accessibilityIdentifier("portion.\(portion.id)")
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(draft.selectedPortion.label)
                            .font(.appBody(.headline, weight: .bold))
                            .foregroundStyle(AppColors.ink)
                        if let quantity = draft.selectedPortion.exactQuantity {
                            Text(quantity)
                                .font(.appBody(.caption))
                                .foregroundStyle(AppColors.muted)
                        }
                    }
                    Spacer()
                    Text("Change")
                        .font(.appBody(.callout, weight: .semibold))
                        .foregroundStyle(AppColors.brand)
                    LucideIcon(icon: .chevronRight, size: 16)
                        .foregroundStyle(AppColors.brand)
                }
                .padding(AppSpacing.md)
                .frame(minHeight: 58)
                .appSurface()
            }
            .accessibilityIdentifier("meal.portion")
        }
    }

    private var ingredientSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionLabel("INGREDIENTS & SWAPS")
            VStack(spacing: AppSpacing.xs) {
                ForEach($draft.ingredients) { $slot in
                    IngredientRow(slot: $slot)
                }
            }

            if isAddingIngredient {
                HStack(spacing: AppSpacing.xs) {
                    TextField("Ingredient name", text: $customIngredient)
                        .font(.appBody())
                        .textInputAutocapitalization(.sentences)
                        .padding(.horizontal, AppSpacing.sm)
                        .frame(minHeight: 48)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        }
                        .accessibilityIdentifier("ingredient.customName")
                    Button("Add") {
                        let cleaned = customIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleaned.isEmpty else { return }
                        draft.addCustomIngredient(named: cleaned)
                        customIngredient = ""
                        isAddingIngredient = false
                        Haptics.selection()
                    }
                    .buttonStyle(QuietActionButtonStyle())
                    .accessibilityIdentifier("ingredient.confirmAdd")
                }
                Text("Nutrition remains unknown until you edit the logged entry; it is not counted as zero silently.")
                    .font(.appBody(.caption2))
                    .foregroundStyle(AppColors.muted)
            } else {
                Button {
                    isAddingIngredient = true
                } label: {
                    HStack {
                        LucideIcon(icon: .plus, size: 17)
                        Text("Add ingredient")
                    }
                }
                .buttonStyle(QuietActionButtonStyle())
                .accessibilityIdentifier("ingredient.add")
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.appBody(.caption2, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(AppColors.muted)
    }
}

private struct IngredientRow: View {
    @Binding var slot: IngredientSlot

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                slot.isIncluded.toggle()
                Haptics.selection()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(slot.isIncluded ? AppColors.brand : Color.clear)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(slot.isIncluded ? AppColors.brand : AppColors.unresolved, lineWidth: 1.5)
                    if slot.isIncluded {
                        LucideIcon(icon: .check, size: 15).foregroundStyle(.white)
                    }
                }
                .frame(width: 28, height: 28)
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(slot.isIncluded ? "Remove \(selectedName)" : "Include \(selectedName)")
            .accessibilityIdentifier("ingredient.toggle.\(slot.id)")

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedName)
                    .font(.appBody(.callout, weight: .semibold))
                    .foregroundStyle(slot.isIncluded ? AppColors.ink : AppColors.muted)
                if slot.options.count > 1 {
                    Text("Swap available")
                        .font(.appBody(.caption2))
                        .foregroundStyle(AppColors.muted)
                }
            }
            Spacer()
            if slot.options.count > 1 {
                Menu {
                    ForEach(slot.options) { option in
                        Button(option.name) {
                            slot.selectedOptionID = option.id
                            slot.isIncluded = true
                            Haptics.selection()
                        }
                        .accessibilityIdentifier("ingredient.swap.\(option.id)")
                    }
                } label: {
                    Text("Swap")
                        .font(.appBody(.callout, weight: .semibold))
                        .foregroundStyle(AppColors.brand)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .appSurface()
    }

    private var selectedName: String {
        slot.selectedOption?.name ?? "Ingredient"
    }
}

struct NutritionEstimateCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let facts: NutritionFacts
    let provenance: NutritionProvenance

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text(provenance == .demoEstimate ? "DEMO ESTIMATE" : "NUTRITION")
                    .font(.appBody(.caption2, weight: .bold))
                    .tracking(1.2)
                Spacer()
                if facts.containsUnknown {
                    Text("Unknown values shown as —")
                        .font(.appBody(.caption2))
                }
            }
            .foregroundStyle(AppColors.muted)
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                    nutritionValues
                }
            } else {
                HStack { nutritionValues }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.brandSoft)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .accessibilityIdentifier("meal.nutrition")
    }

    @ViewBuilder
    private var nutritionValues: some View {
        value("Calories", facts.calories, unit: "")
        value("Protein", facts.protein, unit: "g")
        value("Fat", facts.fat, unit: "g")
        value("Carbs", facts.carbohydrates, unit: "g")
    }

    private func value(_ label: String, _ value: Double?, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value.map { "\(Int($0.rounded()))\(unit)" } ?? "—")
                .font(.appBody(.headline, weight: .bold))
                .foregroundStyle(AppColors.ink)
            Text(label)
                .font(.appBody(.caption2))
                .foregroundStyle(AppColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
