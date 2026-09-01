import SwiftUI

struct EntryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var entry: MealEntry
    @State private var calories: String
    @State private var protein: String
    @State private var fat: String
    @State private var carbohydrates: String
    let onSave: (MealEntry) -> Void
    let onDelete: () -> Void

    init(entry: MealEntry, onSave: @escaping (MealEntry) -> Void, onDelete: @escaping () -> Void) {
        _entry = State(initialValue: entry)
        _calories = State(initialValue: entry.nutrition.calories.map { String(Int($0.rounded())) } ?? "")
        _protein = State(initialValue: entry.nutrition.protein.map { String(Int($0.rounded())) } ?? "")
        _fat = State(initialValue: entry.nutrition.fat.map { String(Int($0.rounded())) } ?? "")
        _carbohydrates = State(initialValue: entry.nutrition.carbohydrates.map { String(Int($0.rounded())) } ?? "")
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Meal name", text: $entry.name)
                        .accessibilityIdentifier("entry.name")
                    Picker("Meal category", selection: $entry.category) {
                        ForEach(MealCategory.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Portion label", text: $entry.portionLabel)
                }
                Section("Ingredients") {
                    ForEach($entry.ingredients) { $ingredient in
                        TextField("Ingredient", text: $ingredient.name)
                            .accessibilityIdentifier("entry.ingredient.\(ingredient.id)")
                    }
                    .onDelete { offsets in entry.ingredients.remove(atOffsets: offsets) }
                }
                Section {
                    nutrientField("Calories", text: $calories, unit: "kcal")
                    nutrientField("Protein", text: $protein, unit: "g")
                    nutrientField("Fat", text: $fat, unit: "g")
                    nutrientField("Carbohydrates", text: $carbohydrates, unit: "g")
                } header: {
                    Text("Nutrition")
                } footer: {
                    Text("Blank values remain unknown. Saving this correction increases its weight in future predictions.")
                }
                Section {
                    Button("Delete entry", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                    .accessibilityIdentifier("entry.delete")
                }
            }
            .font(.appBody())
            .navigationTitle("Edit log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.nutrition = NutritionFacts(
                            calories: Double(calories),
                            protein: Double(protein),
                            fat: Double(fat),
                            carbohydrates: Double(carbohydrates)
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .disabled(entry.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("entry.save")
                }
            }
        }
    }

    private func nutrientField(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("—", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .accessibilityIdentifier("entry.nutrition.\(label.lowercased())")
            Text(unit).foregroundStyle(AppColors.muted)
        }
    }
}
