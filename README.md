# MealTracker

MealTracker contains two independently buildable applications:

- `client/` is the preserved React/Vite interaction wireframe and Electric Blue visual reference.
- `ios/MealTracker/` is the production-oriented native iPhone application built with Swift, SwiftUI, SwiftData, and Apple frameworks.

The native first milestone is local-first and deliberately optimizes one complete loop: see a likely meal, adjust the portion or ingredients, log it, receive immediate feedback, and edit or undo it. History, day completion, streak recovery, durable rewards, contextual permission states, and integration seams are included around that loop.

## Requirements

- macOS with Xcode 16 or newer
- iOS 17 or newer iPhone or simulator
- An Apple Developer team selected in Xcode for installation on a physical iPhone
- Node 20+ and pnpm 10.x only if you want to run the React wireframe

No AI, search, or menu API key is required for this milestone. No secret belongs in the iOS project, source, build settings, plist, or app bundle.

## Open and run the native app

1. Clone the repository on a Mac.
2. Open `ios/MealTracker/MealTracker.xcodeproj` in Xcode.
3. Select the `MealTracker` project, then the `MealTracker` target, then **Signing & Capabilities**.
4. Choose your Apple Developer team. If Xcode reports that the bundle identifier is unavailable, change `com.pffise.MealTracker` to a unique identifier you control.
5. Keep **HealthKit** enabled. Xcode reads the committed entitlement and may ask to repair the capability for your team.
6. Connect and unlock your iPhone, select it as the run destination, and press **Run** (`⌘R`). Trust the developer profile on the iPhone if iOS asks.

The app requests camera, speech/microphone, foreground location, and Apple Health only when the corresponding feature is opened. It never requests Always Location.

## Build and test on a Mac

List available simulator names:

```sh
xcrun simctl list devices available
```

Build without code signing:

```sh
xcodebuild \
  -project ios/MealTracker/MealTracker.xcodeproj \
  -scheme MealTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run unit and UI tests:

```sh
xcodebuild \
  -project ios/MealTracker/MealTracker.xcodeproj \
  -scheme MealTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Repeat visual verification on a standard iPhone simulator and a small supported iPhone simulator. Check light mode, dark mode, and an Accessibility Dynamic Type size. The current execution environment used to author this milestone is Linux and does not contain Xcode or an iOS simulator, so those Mac-only commands and screenshot checks still need to be run before calling the build release-verified.

## Run the preserved wireframe

Use the repository’s pinned pnpm version (Corepack is recommended):

```sh
corepack enable
corepack prepare pnpm@10.4.1 --activate
pnpm install --frozen-lockfile
pnpm check
pnpm build
pnpm dev
```

The React application remains a review canvas. It is not shipped inside the iPhone application.

## Native architecture

- `Domain/`: value types and pure nutrition, completion, streak, reward, local-day, and prediction logic.
- `Persistence/`: SwiftData records and the `MealRepository` protocol.
- `Seed/`: clearly identified starter meal templates, separate from learned history.
- `Services/`: protocols plus native or honestly labeled demo implementations.
- `App/`: dependency composition, application state, and tab navigation.
- `Features/`: focused SwiftUI screens and sheets.
- `DesignSystem/`: Electric Blue semantic colors, typography, spacing, surfaces, motion, haptics, and Lucide rendering.
- `MealTrackerTests/` and `MealTrackerUITests/`: deterministic domain, persistence, integration-loop, and UI coverage.

See [ios/ARCHITECTURE.md](ios/ARCHITECTURE.md) for the lifecycle and reward invariants.

## Persistence and privacy

- SwiftData is authoritative for entries, day resolution, settings, and immutable reward ledger events.
- Every entry stores its absolute timestamps, resolved `yyyy-MM-dd` local-day identifier, and timezone identifier. Changing timezones does not reassign history.
- Original photo bytes are held only for the active analysis operation and are not written to disk.
- Apple Health is read-only and queried on demand; Health history is not copied into SwiftData.
- Denied optional permissions are normal UI states with fallback logging.

The milestone is local-only. Encrypted iCloud sync, export/delete tooling, reminder scheduling, and a production private backend remain outside this slice.

## Real versus demo integrations

| Capability | Current implementation |
|---|---|
| Persistence and calculations | Real, local SwiftData and deterministic Swift |
| Voice transcription | Native Apple Speech + microphone |
| Foreground nearby venues | Native Core Location + MapKit |
| Apple Health reads | Native, contextual, read-only HealthKit |
| Camera and photo selection | Native camera and Photos picker |
| Text/photo nutrition analysis | Explicitly labeled local demo estimator |
| Restaurant menu lookup | Explicit no-reliable-menu provider and complete fallbacks |
| Adventure generation | Explicit limited demo provider; rewards are real and persistent |

Production providers should be implemented behind the existing protocols and call a private TLS backend. See [ios/CONFIGURATION.md](ios/CONFIGURATION.md).

## Visual and accessibility QA

The app uses bundled Plus Jakarta Sans for display roles, DM Sans for interface copy, and vendored Lucide SVG assets. All type uses Dynamic Type-relative roles. Major flows expose accessibility identifiers and explicit VoiceOver status. Completeness uses labels and icon/stroke treatments in addition to color. Motion is short and optional; SwiftUI transition motion is removed when Reduce Motion is enabled.

Before a physical-device handoff, verify:

- iPhone 16/17 standard size, light and dark appearance
- iPhone SE (3rd generation) or the smallest supported simulator
- Accessibility XXXL text size
- VoiceOver order for Today, the meal sheet, History, and Adventure
- Reduce Motion enabled
- camera, microphone/speech, location, and HealthKit denial paths

## Known limitations

- The authoring runtime cannot execute `xcodebuild`, simulator UI tests, or visual screenshot inspection.
- AI nutrition and restaurant menu providers require a private backend and are intentionally demo/unavailable, never presented as live.
- iCloud sync, notifications, export/deletion, and the full adventure game are not in the first engineering milestone.
- The app is configured for direct Xcode installation, not App Store distribution.

Third-party licenses are recorded in [ASSET_LICENSES.md](ASSET_LICENSES.md). Progress is tracked in [ios/IMPLEMENTATION_CHECKLIST.md](ios/IMPLEMENTATION_CHECKLIST.md).
