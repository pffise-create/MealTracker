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
- [x] Persistent capture entry point and honest demo estimator flows

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
- [x] Banked resource ledger and limited premium Adventure entry state

## Verification

- [x] Unit tests for deterministic domain logic and persistence round trips
- [x] UI test coverage for the milestone’s primary flows
- [x] Accessibility identifiers, Dynamic Type layouts, VoiceOver labels, and Reduce Motion support
- [x] Static parsing of every Swift source plus Xcode project, scheme, plist, entitlement, and asset metadata
- [x] Preserved React wireframe passes `pnpm check` and its full production build (existing analytics/dependency warnings remain)
- [ ] `xcodebuild` build/test on an iPhone simulator (blocked: this Linux runtime has no Xcode)
- [ ] Simulator visual inspection on standard/small iPhones in light/dark/large text (blocked: this Linux runtime has no iOS simulator)
