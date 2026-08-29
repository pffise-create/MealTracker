# Native iPhone milestone plan

This plan maps the first native build to PRD section 24 and the approved Electric Blue direction.

1. Establish an iOS 17 SwiftUI application with SwiftData persistence, protocol-based dependencies, deterministic clocks/calendars, and an Electric Blue semantic design system.
2. Implement the daily habit loop: four category resolution states, neutral nutrition totals, predictions, a sub-ten-second known-meal sheet, durable logging, immediate rewards, Edit, and Undo.
3. Implement local-day lifecycle and history: timezone-stable day identifiers, automatic rollover, End Day, historical editing, recalculation, streak reset, and retroactive recovery.
4. Add honest integration seams: native contextual permission handling plus demo meal-analysis/menu/adventure providers where a private backend is required.
5. Add focused unit and UI tests, accessibility identifiers, license records, setup documentation, and visual-QA guidance for standard, small, dark, and large-text configurations.

## Architecture decisions

- `MealTrackerStore` is the presentation/application boundary. SwiftUI views render its published snapshots and send intent methods; they do not calculate streaks, rewards, totals, or predictions.
- `MealRepository` is the persistence boundary. The production implementation uses SwiftData; tests can use its in-memory configuration or a spy.
- Nutrition, day completion, streaks, rewards, local-day resolution, and ranking are pure deterministic engines.
- Seed templates live in `SeedMealCatalog` and have explicit `starter` provenance. Only actual logs produce learned prediction signals.
- Entry and day-completion rewards are immutable ledger events. Undo removes the just-created entry reward; later incompleteness never deducts already banked progress.
- Absolute timestamps, the resolved local-day identifier, and the timezone identifier are stored together. Historical entries never migrate when the device timezone changes.
- The first build has no client secrets and no live AI/menu backend. Demo results are named as demo estimates in both data provenance and UI.
