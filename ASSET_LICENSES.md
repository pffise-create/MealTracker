# Asset licenses

All reusable external assets in the native application are listed here. No restaurant, delivery-platform, wireframe meal, or stock food imagery is shipped.

| Asset | Source | Author | License | Attribution required | Modifications |
|---|---|---|---|---|---|
| Plus Jakarta Sans variable font | [Google Fonts repository](https://github.com/google/fonts/tree/main/ofl/plusjakartasans) | Tokotype | SIL Open Font License 1.1 | Preserve the license with redistributed font files | File renamed to `PlusJakartaSans-Variable.ttf`; glyphs unmodified |
| DM Sans variable font | [Google Fonts repository](https://github.com/google/fonts/tree/main/ofl/dmsans) | Colophon Foundry, Jonny Pinhorn, Indian Type Foundry contributors | SIL Open Font License 1.1 | Preserve the license with redistributed font files | File renamed to `DMSans-Variable.ttf`; glyphs unmodified |
| Lucide icon subset, version 0.453.0 | [`lucide-static` package](https://www.npmjs.com/package/lucide-static/v/0.453.0) / [Lucide repository](https://github.com/lucide-icons/lucide) | Lucide contributors | ISC | Copyright and license notice included | Selected SVGs placed in Xcode image sets and configured for template tinting; paths unmodified |

The complete bundled notices are under `ios/MealTracker/MealTracker/Resources/Licenses/`.

## Project-created assets

- The Electric Blue app icon and segmented-ring mark were created for MealTracker in this repository and do not require third-party attribution.
- Cold-start food recognition uses Lucide food symbols. User meal photos are preferred when a future learned-thumbnail policy is implemented.
