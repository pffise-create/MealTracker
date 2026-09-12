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
- [x] Banked meal XP ledger and persistent local Briar Glen commonwealth
- [x] Six-site illustrated valley, citizen households, seven improvements, tactical patrols, and recurring council decisions

## Original milestone verification (historical; predates Briar Glen)

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
- [x] Prior Adventure received an agent rubric review. Its score was a heuristic, not a user study or evidence of an enthusiast approval percentage; that interface is now superseded by Briar Glen.

## Briar Glen verification — September 12, 2026

- [x] Xcode 26.3 (17C529), iOS 26.2: final clean simulator build passes with no compiler warnings reported
- [x] iPhone 17 light: all 42 local checks pass — 35 unit tests and 7 UI tests
- [x] New unit coverage includes 11 Commonwealth engine tests and 3 store/persistence tests; seven-day banking, legacy spending, undo debt, save failures, combat/cover, council tradeoffs, and bounded history are verified
- [x] iPhone 16e (smallest installed simulator), light/default text: all 3 game UI tests pass on the final UI
- [x] iPhone 16e, dark/Accessibility XXXL: all 3 game UI tests pass, including retreat, XP gating, and return to Today
- [x] iPhone 17, dark/Accessibility XXXL: additional introduction → water → map → citizens → journal visual test passes
- [x] Screenshots inspected for introduction, map, citizen details, action outcomes, journal, and combat; all five tactics, combatants, health, and intent fit together at normal text sizes on both phones
- [x] Fixed inherited accessibility identifiers, first-battle sequencing, post-action scrolling, scalable location navigation, and large-text battle controls
- [x] Existing completion/recovery UI assertions updated to check actual resolved state, streak, and earned XP after earlier app-copy changes; both pass
- [x] Independent critic: 8.0/10 for the first playable region. Criteria and limitations are in `COMMONWEALTH.md`; no human approval percentage is claimed
- [x] Three shipping art assets total 1,372,112 bytes (~1.31 MiB), with no new dependencies or gameplay network calls
- [ ] Physical-device VoiceOver order, device peak-memory profiling, and longer-term human playtesting remain unverified

Local result bundles: `/tmp/mealtracker-commonwealth.KHtCAf/release-standard.xcresult`, `release-small.xcresult`, `release-ax.xcresult`, and `ax-visual.xcresult`. The final clean-build products are under `/tmp/mealtracker-commonwealth.KHtCAf/final-build`. UI screenshots were exported beside these bundles and selected handoff images saved in the Codex workspace's `artifacts/commonwealth` folder, not the app bundle.

Live AI/restaurant network tests were explicitly excluded from this game-focused regression run. React and backend source were unchanged; their builds were not rerun in this pass. User-owned Xcode project/scheme changes were preserved and excluded from the game commit.

## Live-service boundary

- [x] OpenAI Responses API request is server-only, schema constrained, runtime validated, and configured with response storage disabled
- [x] The iPhone sends text or photo inputs to an HTTPS backend and stores only the separate backend access token in Keychain
- [x] Missing URL/token/provider failures become explicit unavailable/demo states; no API key ships in the app bundle
- [ ] End-to-end live OpenAI response verified against a deployed backend (requires operator-provided server secrets and HTTPS URL)
