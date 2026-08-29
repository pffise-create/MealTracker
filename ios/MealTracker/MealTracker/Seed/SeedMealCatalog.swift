import Foundation

/// Cold-start content only. These templates are never represented as personal history.
/// The prediction engine marks a template as learned only after an actual MealEntry exists.
enum SeedMealCatalog {
    static let templates: [MealTemplate] = [
        MealTemplate(
            id: "starter-egg-spinach-toast",
            name: "Egg & spinach toast",
            category: .breakfast,
            ingredients: [
                slot("toast", option("sourdough", "Sourdough toast", 150, 5, 1.5, 28)),
                slot(
                    "eggs",
                    option("two-eggs", "Two eggs", 144, 13, 10, 1),
                    option("egg-whites", "Egg whites", 75, 16, 0, 1)
                ),
                slot("spinach", option("spinach", "Wilted spinach", 25, 3, 0, 4)),
                slot("olive-oil", option("olive-oil", "Olive oil", 40, 0, 4.5, 0))
            ],
            portions: portions("plate", "1 plate"),
            defaultPortionID: "usual",
            typicalHours: 6...10,
            provenance: .starter
        ),
        MealTemplate(
            id: "starter-turkey-hummus-wrap",
            name: "Turkey hummus wrap",
            category: .lunch,
            ingredients: [
                slot("wrap", option("whole-wheat-wrap", "Whole-wheat wrap", 190, 6, 4, 34)),
                slot(
                    "protein",
                    option("turkey", "Roasted turkey", 130, 26, 2, 2),
                    option("chicken", "Roasted chicken", 140, 27, 3, 0)
                ),
                slot("spread", option("hummus", "Hummus", 90, 3, 6, 8)),
                slot("greens", option("greens", "Crisp greens", 20, 1, 0, 4))
            ],
            portions: portions("wrap", "1 wrap"),
            defaultPortionID: "usual",
            typicalHours: 11...14,
            provenance: .starter
        ),
        MealTemplate(
            id: "starter-lemon-chicken-bowl",
            name: "Lemon chicken grain bowl",
            category: .dinner,
            ingredients: [
                slot(
                    "protein",
                    option("chicken", "Lemon chicken", 260, 43, 8, 3),
                    option("tofu", "Crisp tofu", 235, 21, 14, 8)
                ),
                slot(
                    "grain",
                    option("farro", "Farro", 200, 7, 2, 41),
                    option("brown-rice", "Brown rice", 215, 5, 2, 45)
                ),
                slot("vegetables", option("roasted-vegetables", "Roasted vegetables", 120, 4, 5, 16)),
                slot("tahini", option("tahini", "Tahini drizzle", 90, 3, 8, 3))
            ],
            portions: portions("bowl", "1½ cups"),
            defaultPortionID: "usual",
            typicalHours: 17...21,
            provenance: .starter
        ),
        MealTemplate(
            id: "starter-yogurt-berries",
            name: "Yogurt berry crunch",
            category: .snacks,
            ingredients: [
                slot(
                    "yogurt",
                    option("greek-yogurt", "Greek yogurt", 150, 20, 4, 8),
                    option("cottage-cheese", "Cottage cheese", 180, 24, 5, 10)
                ),
                slot("berries", option("berries", "Mixed berries", 70, 1, 0, 17)),
                slot("granola", option("granola", "Granola", 130, 3, 5, 20))
            ],
            portions: portions("bowl", "1 cup"),
            defaultPortionID: "usual",
            typicalHours: 14...17,
            provenance: .starter
        ),
        MealTemplate(
            id: "starter-pasta-peas",
            name: "Pasta, peas & parmesan",
            category: .dinner,
            ingredients: [
                slot("pasta", option("pasta", "Pasta", 400, 14, 2, 80)),
                slot("peas", option("peas", "Green peas", 100, 7, 0.5, 18)),
                slot("parmesan", option("parmesan", "Parmesan", 110, 10, 7, 1)),
                slot("olive-oil", option("olive-oil", "Olive oil", 80, 0, 9, 0))
            ],
            portions: portions("bowl", "2 cups"),
            defaultPortionID: "usual",
            typicalHours: 17...21,
            provenance: .starter
        )
    ]

    private static func option(
        _ id: String,
        _ name: String,
        _ calories: Double,
        _ protein: Double,
        _ fat: Double,
        _ carbohydrates: Double
    ) -> IngredientOption {
        IngredientOption(
            id: id,
            name: name,
            nutrition: NutritionFacts(
                calories: calories,
                protein: protein,
                fat: fat,
                carbohydrates: carbohydrates
            )
        )
    }

    private static func slot(_ id: String, _ options: IngredientOption...) -> IngredientSlot {
        IngredientSlot(
            id: id,
            options: options,
            selectedOptionID: options.first?.id ?? id,
            isIncluded: true
        )
    }

    private static func portions(_ noun: String, _ usualQuantity: String) -> [PortionOption] {
        [
            PortionOption(id: "light", label: "Light \(noun)", exactQuantity: nil, factor: 0.72),
            PortionOption(id: "usual", label: "Usual \(noun)", exactQuantity: usualQuantity, factor: 1),
            PortionOption(id: "generous", label: "Generous \(noun)", exactQuantity: nil, factor: 1.32)
        ]
    }
}
