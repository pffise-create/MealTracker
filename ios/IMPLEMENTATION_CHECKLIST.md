# First engineering milestone checklist

## Product foundation

- [x] Native SwiftUI iPhone project under `ios/MealTracker`
- [x] SwiftData local persistence with in-memory test support
- [x] Protocol-based repository, clock, prediction, and integration boundaries
- [x] Electric Blue semantic design tokens with dark appearance
- [x] Bundled Plus Jakarta Sans, DM Sans, and Lucide icons

## Core habit loop

- [x] Four-part Breakfast/Lunch/Dinner/Snacks completeness ring
- [x] Logged, Skipped / None, and Unresolved states without color-only meaning
- [x] Neutral calorie, protein, fat, and carbohydrate progress
- [x] Predicted meals with editable portions, ingredients, and swaps
- [x] Persistent logging, immediate totals, rewards, haptic confirmation, Edit, and Undo
- [x] Persistent capture entry point, private-backend OpenAI text/photo estimator, and honest local demo fallback

## Day lifecycle and history

- [x] Automatic local-day rollover and timezone-stable identifiers
- [x] Explicit End Day and Skip / None for every category
- [x] Complete-day calculation independent of macros
- [x] Current/longest streak, reset, retroactive recovery, and lifetime completion count
- [x] Calendar history, grouped details, add/edit/delete/recategorize past entries

## Context and reward foundations

- [x] Foreground location/venue UI with denied and unreliable-menu fallbacks
- [x] Protocols for text/photo analysis, voice, location, menu, HealthKit, and adventure generation
- [x] Native contextual camera, photo-library, speech, location, and HealthKit seams
- [x] Banked resource ledger and persistent deterministic Adventure campaign
- [x] Five-region map, companion recruitment, quest log, inventory, consequential choices, dice, death, and one-use resurrection

## Verification

- [x] Unit tests for deterministic domain logic and persistence round trips
- [x] UI test coverage for the milestone’s primary flows
- [x] Accessibility identifiers, Dynamic Type layouts, VoiceOver labels, and Reduce Motion support
- [x] Static parsing of every Swift source plus Xcode project, scheme, plist, entitlement, and asset metadata
- [x] Preserved React wireframe passes `pnpm check` and its full production build (existing analytics/dependency warnings remain)
- [x] Xcode 26.3 Debug build succeeds for the `MealTracker` scheme against the iOS 26.2 simulator runtime
- [x] All 19 unit tests pass on iPhone 17 (6 Adventure, 7 domain, 6 persistence/store)
- [x] All 5 UI tests pass on iPhone 17, covering log/edit/undo, skipped/day completion, historical recovery, primary navigation, and Adventure World/Company/Records
- [x] Adventure screenshots inspected on iPhone 17 in light and dark appearances
- [x] Adventure UI test and screenshot inspection pass on the smallest installed simulator (iPhone 16e) in light mode
- [x] Adventure UI test and screenshot inspection pass on iPhone 17 in dark mode at Accessibility XXXL
- [x] Adventure supports renewable seeded expeditions, honest pre-choice odds, six trait ranks, graded runs, renown, and successor continuity without network or media assets
- [x] Independent fantasy-game rubric evaluation scores Adventure 85/100 (81–84% predicted enthusiast approval; 82/100 certification bar)

## Live-service boundary

- [x] OpenAI Responses API request is server-only, schema constrained, runtime validated, and configured with response storage disabled
- [x] The iPhone sends text or photo inputs to an HTTPS backend and stores only the separate backend access token in Keychain
- [x] Missing URL/token/provider failures become explicit unavailable/demo states; no API key ships in the app bundle
- [ ] End-to-end live OpenAI response verified against a deployed backend (requires operator-provided server secrets and HTTPS URL)
