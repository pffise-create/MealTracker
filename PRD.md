# MealTracker Product Requirements Document

**Status:** Development-ready draft  
**Version:** 0.1  
**Platform:** Native iPhone application  
**Distribution:** Private development build installed directly through Xcode  
**Product owner / initial user:** Patrick  
**Last updated:** August 29, 2026

## 1. Product summary

MealTracker is a personal meal-tracking application designed to make complete daily food logging easier than skipping it. It combines predictive meal suggestions, AI estimation, photo and voice input, location-aware restaurant menus, Apple Health context, habit feedback, and an optional role-playing game reward layer.

The core product insight is that the user does not lack nutrition knowledge. The existing behavior fails because manually describing every meal creates repeated friction. MealTracker should learn routines so that most food can be logged by selecting and lightly editing a prediction rather than composing a new entry.

The product is grounded in the behavioral principles from *Atomic Habits*:

- **Make it obvious:** Surface the most likely meal based on time, location, and history.
- **Make it attractive:** Show visible progress, streaks, and banked adventure rewards.
- **Make it easy:** Default to one-tap predictions and automatic AI estimates.
- **Make it satisfying:** Confirm every log immediately and reward the act of logging.

The primary habit is **logging everything**. Macro achievement is a secondary positive outcome and must never be presented as a moral judgment or streak requirement.

## 2. Problem statement

Existing calorie trackers require too much repetitive entry. Conversational AI improves estimation but still requires the user to type or dictate every meal from scratch. Over time, that effort produces logging fatigue and abandonment.

MealTracker must reduce four sources of friction:

1. Re-describing foods and meals the user eats repeatedly.
2. Estimating ingredients and portions.
3. Finding restaurant menu items and nutrition information.
4. Sustaining motivation after novelty or discipline fades.

## 3. Goals

### 3.1 Primary goals

- Make a typical known meal loggable in less than 10 seconds.
- Make an unknown photographed meal loggable with no required confirmation.
- Learn foods, ingredient combinations, portions, timing, and locations passively.
- Provide a clear definition of a completely logged day.
- Encourage long-term logging without punishing imperfect nutrition.
- Preserve user control over targets, corrections, history, and permissions.
- Make logging intrinsically rewarding through immediate feedback and an optional persistent adventure.

### 3.2 Secondary goals

- Support on-demand progress conversations informed by food history and Apple Health.
- Reduce restaurant logging friction by finding trustworthy menus automatically.
- Create a foundation for later background location reminders and richer RPG systems.

### 3.3 Non-goals for MVP

- Clinical nutrition or medical advice.
- Exact laboratory-grade nutrition measurement from photographs.
- Automatic adjustment of calorie or macro targets.
- Social feeds, leaderboards, or public profiles.
- Shared household accounts.
- Apple Watch application.
- Background restaurant detection requiring Always Location access.
- Full tactical RPG combat.
- Public App Store distribution.
- Recipe entry or required ingredient weighing.

## 4. Product principles

1. **Consistency over precision.** A useful estimate logged consistently is better than a precise entry abandoned halfway through the week.
2. **Prediction before input.** The interface should offer likely actions before asking the user to compose anything.
3. **Optimistic logging.** AI-generated entries are logged immediately and remain easy to correct.
4. **No food morality.** The interface must not label foods or days as good, bad, clean, cheating, or failed.
5. **Macros only celebrate.** Hitting a target can trigger a positive moment. Missing it should not trigger warnings, red states, streak loss, or game penalties.
6. **Logging drives rewards.** Game progress is earned through logging completeness, not eating less or selecting particular foods.
7. **Never erase accumulated effort.** An incomplete day can reset the current streak, but cannot remove permanent adventure progress.
8. **Progressive permissions.** Request HealthKit, camera, microphone, photos, notifications, and location only when their benefit is clear.
9. **Passive onboarding.** Do not require the user to catalog usual foods before using the app.
10. **User corrections are training signals.** Every edit should improve future predictions.

## 5. Target user and identity

### 5.1 Initial user

The initial product is for a single user who:

- Tracks calories, protein, fat, and carbohydrates.
- Cares about macros but is fatigued by repetitive entry.
- Regularly repeats meals and ingredients.
- Eats both at home and at restaurants.
- Accepts AI estimates when correction remains easy.
- Uses an iPhone and Apple Health.
- Responds positively to streaks, visible progress, games, and longer-term accumulation.

### 5.2 Desired identity reinforcement

The application should reinforce: **“I am someone who notices and records what I eat.”**

It should not imply: **“I am only succeeding when I hit every macro.”**

## 6. Success metrics

Because this is initially a personal app, metrics may be calculated locally and viewed only by the user.

### 6.1 North-star metric

**Complete logging days per rolling 28 days.**

A complete day contains a resolved state for Breakfast, Lunch, Dinner, and Snacks. Each category must be either logged or explicitly marked Skipped / None.

### 6.2 Supporting metrics

- Seven-day and 28-day logging completeness rate.
- Current and longest complete-day streak.
- Median time to log a predicted meal.
- Percentage of entries logged from predictions versus manual input.
- Percentage of AI entries edited after logging.
- Suggestion acceptance rate by rank.
- Percentage of restaurant visits resolved using a found menu.
- Reminder-to-log conversion rate.
- Adventure rewards earned and spent.
- Days abandoned after one incomplete day.

### 6.3 Initial performance targets

- Predicted meal: median logging time under 10 seconds.
- Photo meal: visible logged estimate within 8 seconds under normal connectivity.
- Dashboard: interactive within 1 second from warm launch.
- Correction: portion or ingredient edit in no more than three taps after opening details.

## 7. Platform, distribution, and operating assumptions

- Native iPhone application built with Swift and SwiftUI.
- Minimum supported iOS version to be selected during technical setup; prefer the newest version supported by the user’s current iPhone.
- Signed with an existing paid Apple Developer account.
- Installed directly from Xcode on registered personal devices.
- No App Store submission or public distribution is required for MVP.
- The application may use a small private backend for AI requests, menu lookup, and secret management.
- API secrets must never be embedded in the iOS binary.

## 8. Information architecture

The MVP should use a shallow structure with the dashboard as the default destination.

### 8.1 Primary destinations

1. **Today:** Dashboard, daily progress, likely foods, input, and recent entries.
2. **History:** Calendar/day history and editing.
3. **Adventure:** Banked resources and game session.
4. **Settings:** Targets, permissions, data, notifications, and export.

Progress conversation should be accessible from Today and History without becoming a required primary tab.

## 9. Detailed requirements

### 9.1 Today dashboard

The dashboard must be usable without scrolling for the primary logging action on standard iPhone sizes.

#### Top: progress

- Show a primary logging-completeness ring divided into Breakfast, Lunch, Dinner, and Snacks.
- Visually distinguish Logged, Skipped / None, and Unresolved states without relying on color alone.
- Show current calories, protein, fat, and carbohydrates.
- Present macro values as neutral progress toward user-defined targets.
- Do not use red or failure language when a target is missed or exceeded.
- Show current logging streak.
- Show banked adventure energy or rewards as a secondary element.
- Provide optional End Day access without making it the dominant action.

#### Middle: likely foods

- Show a compact set of tappable meal or food cards ranked for the current moment.
- Prefer full meal templates over individual ingredients when history supports the combination.
- Each card should include a recognizable name, visual, usual portion, and concise calorie/protein estimate when available.
- Do not require horizontally scrolling through a large catalog to reach manual input.
- Include a route to See All or search additional known foods.

#### Bottom: AI input

- Show a small persistent input field near the bottom of the dashboard.
- Tapping it opens a bottom sheet with text, voice, camera, and photo-library actions.
- Preserve the visible dashboard behind the sheet.
- Support short natural-language input such as “turkey sandwich and a handful of chips.”

#### Recent log

- Display the most recent entry with Edit and Undo access.
- Undo should remain available long enough to correct accidental optimistic logs.

### 9.2 Meal categories and day lifecycle

- Every entry belongs to Breakfast, Lunch, Dinner, or Snacks.
- The app assigns a category using time and learned behavior.
- The user can change the category at any time.
- Snacks may include multiple entries while representing one completeness segment.
- Every category supports Skipped / None.
- Marking a category Skipped / None counts toward logging completeness but adds no nutrition.
- Adding food to a skipped category automatically replaces its skipped state with logged.
- The app rolls to the new local calendar day automatically at midnight.
- Previous days remain editable.
- Travel and timezone changes must not silently move existing entries to another day. Store both absolute timestamp and resolved local-day identifier.

### 9.3 End Day and streaks

- End Day is optional.
- Tapping End Day shows unresolved meal categories and allows the user to log, skip, or leave them unresolved.
- Completing all four categories triggers an immediate completion celebration.
- A day can become complete without End Day if all categories are already resolved.
- An incomplete day resets the current complete-day streak after the day closes.
- The user may recover the streak by returning to the prior day and resolving missing categories.
- The exact recovery window is an open design decision; data structures must support retroactive recovery.
- Streak recovery must never require payment, macro achievement, or game currency.
- Longest streak and total complete days remain permanent.

### 9.4 Passive prediction engine

The app should begin with minimal or no onboarding and learn from behavior.

#### Ranking inputs

- Time of day.
- Day of week.
- Current place or semantic location when permission is available.
- Recency and frequency of prior logs.
- Meal category.
- Repeated ingredient combinations.
- Previously selected swaps.
- Learned portion size.
- Restaurant order history.
- Recent repetition suppression where appropriate.

#### Learning behavior

- Every confirmed or corrected log updates prediction features.
- Repeated combinations may become named meal templates.
- Ingredient removals and swaps should affect future defaults.
- User-corrected portions become stronger signals than original AI estimates.
- Recent behavior should outweigh old imported history.
- A discussed, searched, or viewed item must not become a usual until it is actually logged.
- The app must support importing a private seed file of known items without treating every item as equally frequent.

#### Prediction transparency

- The interface does not need to explain the ranking algorithm on every card.
- A long-press or overflow action may offer Not Likely, Hide, or Forget This Suggestion.

### 9.5 Predicted meal detail

Tapping a likely meal opens an editable bottom sheet rather than logging immediately.

The sheet must include:

- Meal name.
- Preselected predicted portion.
- Plain-language portion labels paired with exact units when known, such as Half bowl — 1 cup, Usual bowl — 1.5 cups, Full bowl — 2 cups.
- Tappable ingredient selections.
- Suggested ingredient swaps.
- Add Ingredient action.
- Live calories, protein, fat, and carbohydrate estimates.
- One clear Log Meal action.

If exact portion mappings are unknown, show the plain-language choice and learn the exact mapping later rather than inventing precision.

### 9.6 Text and voice logging

- Accept conversational descriptions of foods, amounts, brands, and modifications.
- Parse multiple items from one utterance.
- Immediately create a best-estimate entry.
- Show a compact result with Edit and Undo.
- Ask a clarification only when two interpretations would materially change the entry and no reasonable default exists.
- Voice transcription should remain editable before or after logging.

### 9.7 Photo logging

- Support taking a new photo and uploading from the photo library.
- AI should identify likely foods, ingredients, portions, and nutrition.
- Log the best estimate automatically without a required confirmation step.
- Immediately show Edit and Undo.
- Only interrupt for materially ambiguous results, such as an image that does not appear to contain food.
- User corrections must feed future prediction and estimation.
- Original meal photos should be deleted after analysis by default.
- If a small visual reference is retained for a learned meal, store an explicitly generated thumbnail with clear user control.

### 9.8 Nutrition estimation

- Track calories in kcal and protein, fat, and carbohydrates in grams.
- Preserve user-supplied nutrition values as authoritative for the specified serving.
- Distinguish verified label/menu data from AI estimates internally.
- Missing nutrients may remain unknown until estimated; do not silently represent unknown as zero.
- Nutrition totals must indicate when part of the total contains estimates without interrupting normal use.
- Recalculate totals after every portion or ingredient edit.

### 9.9 Targets and macro feedback

- The user manually sets calorie, protein, fat, and carbohydrate targets.
- The app must not automatically change targets.
- An AI progress conversation may recommend changes only when initiated by the user.
- Applying any recommended target change requires explicit confirmation.
- Target achievement may trigger positive haptics, animation, or bonus adventure rewards.
- Missing or exceeding a target must not reset a streak or reduce game progress.

### 9.10 Location and restaurant mode

#### MVP permission model

- Request Location While Using the App only.
- Do not request Always Location for MVP.
- Restaurant detection occurs when the user opens or foregrounds the app.
- The app should continue functioning fully without location permission.

#### Venue resolution

- Resolve current coordinates to a nearby food venue.
- If multiple adjacent venues are plausible, show a compact venue chooser.
- Respect approximate-location mode; do not claim certainty when precision is insufficient.
- Remember user venue corrections.

#### Restaurant dashboard state

- Automatically replace normal likely-food suggestions with the detected restaurant context.
- Show restaurant name and location.
- Show previously logged or likely orders first.
- Provide View Full Menu.
- Keep photo, voice, and text input accessible.
- Leaving the location context returns the dashboard to normal predictions.

#### Menu retrieval hierarchy

1. Search official restaurant menu and nutrition sources.
2. Search reputable structured menu sources permitted for application use.
3. Use the user’s previously logged items at that venue.
4. If no trustworthy menu is available, show fallback logging immediately.

Menu search may continue briefly in the background, but it must not block fallback input. Do not display a scraped or stale menu as authoritative. Track source, retrieval date, and whether nutrition is official or estimated.

Restaurant and product imagery must comply with source licenses. The application must not assume that delivery-platform imagery is reusable.

### 9.11 Notifications

#### MVP

- Support learned meal-time reminders when a category remains unresolved.
- Do not notify if the relevant category is already resolved.
- Avoid stacking reminders for the same eating occasion.
- Learn from whether reminders are opened, dismissed, or ignored.
- Allow per-category notification controls and a global pause.

#### Post-MVP

- Optional background restaurant reminders using Always Location.
- Request upgraded permission only after explaining the specific benefit.
- Background location must never be required for basic tracking.

### 9.12 History

- Calendar view showing complete, incomplete, and unreviewed days.
- Day detail view with entries grouped by meal category.
- Edit, delete, recategorize, or add past entries.
- Mark past categories Skipped / None.
- Recalculate daily totals and streak state after edits.
- Provide a clear indicator when a recovered day restores a streak.

### 9.13 On-demand progress conversation

- User initiates all progress reviews.
- AI may discuss calorie and macro trends, logging consistency, weight trend, workouts, steps, and active calories when authorized.
- AI should distinguish observed data from inference.
- No unsolicited weekly review.
- No automatic target adjustment.
- Health-related output must avoid diagnosis and clearly identify uncertainty.

### 9.14 HealthKit

- Request read access only for the initial MVP.
- Candidate types: body mass, workouts, step count, and active energy burned.
- Request access contextually when the user first opens progress analysis.
- Query HealthKit as needed rather than copying the full health history into the app database.
- MealTracker data should not be written to HealthKit in MVP.
- The app must behave normally when access is partially or fully denied.

## 10. Adventure reward system

### 10.1 Purpose

The adventure makes logging immediately satisfying and creates anticipation beyond rings and streaks. It must remain optional and must never slow the primary logging flow.

### 10.2 Core loop

1. Log an eating occasion.
2. Receive a brief resource or loot reveal.
3. Bank rewards without entering the game.
4. Enter Adventure later by choice.
5. Spend banked resources to progress through encounters.
6. Stop naturally when resources are exhausted.

A fully logged day should generally fund approximately two to four minutes of play, subject to balancing.

### 10.3 Game model

- AI dungeon master.
- Persistent main character.
- Recruitable companions with personalities, abilities, relationships, and quests.
- Game-like interface rather than open-ended chat.
- Map, character/companion views, inventory, quest log, illustrated encounters, visible choices, and dice outcomes.
- Fast encounters resolved through one or two meaningful decisions rather than tactical turn-by-turn combat.
- Player choices and dice rolls may cause genuine failure or death.
- Character death may be permanent, while rare resurrection paths can also exist.
- World history and accumulated account-level progress survive character death.

### 10.4 Reward rules

- Reward an eating occasion, not each ingredient, to prevent reward farming by splitting entries.
- Completing the day grants a larger bonus.
- Macro achievement may grant optional bonus loot, cosmetic rewards, or rerolls.
- Macro misses never impose penalties.
- Incomplete days do not remove existing resources, characters, items, or world progress.
- When energy runs out, end at a natural pause or cliffhanger, not in the middle of resolving an encounter.

### 10.5 AI game-state reliability

The AI dungeon master may generate narration, dialogue, encounters, and consequences, but it must operate on structured state. The application—not the model’s prose—must be authoritative for:

- Character statistics and status.
- Companion roster and relationships.
- Inventory and currency.
- Map and discovered locations.
- Quest state.
- Dice results.
- Death, resurrection eligibility, and legacy state.
- Banked and spent resources.

### 10.6 MVP game scope

The first game implementation should include:

- One character.
- At least two recruitable companions.
- One small region.
- A short quest chain generated within bounded rules.
- Fast choice-based encounters.
- Resource banking and consumption.
- Character death and one defined resurrection path.

Deep crafting, tactical combat, multiplayer, and an unrestricted infinite world are post-MVP.

## 11. Core user flows

### 11.1 Log a predicted meal

1. Open app.
2. See current progress and likely foods.
3. Tap a predicted meal.
4. Review preselected ingredients and portion.
5. Make optional swaps or portion change.
6. Tap Log Meal.
7. See updated totals and immediate reward.
8. Return to dashboard.

### 11.2 Log by photo

1. Open AI input sheet.
2. Take or upload photo.
3. AI analyzes image.
4. App automatically adds best estimate.
5. Dashboard updates immediately.
6. User optionally taps Edit or Undo.

### 11.3 Log at a restaurant

1. Open app at restaurant.
2. App resolves venue using foreground location.
3. Restaurant mode appears automatically.
4. User selects a likely order or opens full menu.
5. Selected item opens portion/customization details.
6. User logs item.
7. App remembers order and venue.

If menu lookup fails, steps 4–6 become photo, voice, or text logging.

### 11.4 Complete the day

1. Dashboard shows one or more unresolved categories.
2. User logs food or marks categories Skipped / None.
3. Ring reaches complete.
4. App celebrates logging completeness.
5. Streak increments and day-completion reward is banked.

### 11.5 Recover a streak

1. User opens History and selects incomplete prior day.
2. Missing categories are clearly identified.
3. User adds entries or marks categories Skipped / None.
4. Day becomes complete.
5. Streak chain is recalculated and restored where eligible.

## 12. Data model

The implementation may evolve, but the MVP must represent the following entities explicitly.

### 12.1 UserSettings

- User ID.
- Local timezone.
- Calorie target.
- Protein target.
- Fat target.
- Carbohydrate target.
- Notification preferences.
- Permission states.
- Data-retention preferences.

### 12.2 FoodItem

- Stable ID.
- Canonical name.
- Aliases and brand.
- Default serving label and exact quantity when known.
- Calories, protein, fat, and carbohydrates per serving.
- Data provenance: user supplied, official, database, or AI estimated.
- Confidence and last verification date.
- Image reference and license metadata when applicable.

### 12.3 MealTemplate

- Stable ID and display name.
- Usual meal category.
- Ingredient list and default selections.
- Optional ingredient swaps.
- Portion options.
- Learned time/day/location features.
- Usage frequency, recency, and correction history.

### 12.4 MealEntry

- Stable ID.
- Absolute creation and consumption timestamps.
- Local-day identifier and timezone.
- Meal category.
- Food items and ingredients.
- Portion.
- Nutrition totals.
- Estimation/provenance metadata.
- Input method: prediction, text, voice, camera, photo upload, restaurant menu, or manual edit.
- Venue ID when relevant.
- Edit history sufficient to learn corrections.

### 12.5 DailyLog

- Local-day identifier.
- Per-category states: unresolved, logged, or skipped.
- Nutrition totals.
- End Day timestamp when used.
- Completion status and completion timestamp.
- Streak contribution and recovery state.
- Rewards earned.

### 12.6 Venue

- Stable internal ID.
- Provider IDs.
- Name and coordinates.
- User-confirmed identity.
- Previously logged orders.
- Menu source, retrieval time, and reliability state.

### 12.7 ReminderProfile

- Meal category.
- Learned time window.
- Notification schedule.
- Response history.
- Suppression state.

### 12.8 GameState

- Account-level progression.
- Character and companion state.
- Inventory and currency.
- World/map state.
- Quest state.
- Banked resource balance.
- Structured event history.
- Death, legacy, and resurrection state.

## 13. AI requirements

### 13.1 AI responsibilities

- Parse text and voice meal descriptions.
- Estimate foods, ingredients, portions, and nutrition from photos.
- Resolve ambiguous meal descriptions when a safe default exists.
- Generate progress analysis on demand.
- Generate bounded RPG narration, dialogue, encounters, and consequences.

### 13.2 AI must not be authoritative for

- Stored nutrition values explicitly supplied by the user.
- Daily totals after deterministic calculation.
- Streak calculation.
- Permission state.
- Game inventory, currency, dice results, or character state.

### 13.3 Structured output

All AI meal analysis must return validated structured data containing:

- Detected items.
- Estimated amounts and units.
- Calories, protein, fat, and carbohydrates.
- Confidence by item or field.
- Material ambiguities.
- Suggested editable ingredient structure.

Malformed output must not corrupt the log. The client or backend must validate schemas and provide a retry or manual fallback.

### 13.4 Cost and latency controls

- Use deterministic local calculations whenever possible.
- Cache known foods and prior estimates.
- Do not call a model when a selected known item already has sufficient nutrition data.
- Resize/compress photos before upload.
- Separate fast meal-estimation calls from richer game-generation calls.

## 14. Proposed technical architecture

### 14.1 iOS client

- SwiftUI for interface.
- SwiftData or equivalent local persistence.
- HealthKit for authorized activity and weight reads.
- Core Location and MapKit for foreground place context.
- PhotosUI and camera capture for images.
- Native speech recognition or secure transcription service for voice.
- UserNotifications for meal reminders.
- Background work limited to supported, nonessential maintenance.

### 14.2 Storage

- Local-first database is authoritative for the active device.
- Encrypted iCloud sync/backup for structured meal data, settings, streaks, learned predictions, and game state.
- Sensitive payloads should be encrypted before remote storage when practical.
- HealthKit history should be queried as needed and not duplicated wholesale.
- Original meal photos should be deleted after analysis by default.
- Restaurant menus should be cached with expiration metadata.

### 14.3 Private backend

A minimal backend is recommended for:

- Protecting AI and search API credentials.
- Calling multimodal and language models.
- Normalizing menu search results.
- Validating structured AI responses.
- Enforcing request limits and logging operational errors without retaining unnecessary sensitive content.

The backend should not become the primary store for the user’s meal history unless required later.

## 15. Privacy and security

- Health, meal, location, and photo data are sensitive.
- Collect only data required for a user-visible feature.
- Do not sell data or use it for advertising.
- Explain what is sent to external AI or menu providers.
- Avoid sending HealthKit details unrelated to the requested progress analysis.
- Strip unnecessary image metadata before upload.
- Use TLS for all network transport.
- Store authentication tokens in Keychain.
- Never store API secrets in source code or the app binary.
- Provide data export and full local/cloud deletion controls.
- Avoid logging raw meal descriptions, coordinates, photos, or HealthKit values in diagnostic logs.
- Treat denied permissions as normal states, not errors.

## 16. Permission strategy

Permissions should be requested immediately before first use of the related feature.

| Permission | Trigger | MVP behavior if denied |
|---|---|---|
| Camera | User taps Take Photo | Offer photo library, voice, and text |
| Photo library | User taps Upload Photo | Offer camera, voice, and text |
| Microphone / speech | User taps voice input | Offer text and photo |
| Location While Using | User enables or first uses restaurant detection | Show normal predictions and restaurant search |
| Notifications | User enables meal reminders after seeing benefit | Keep reminders off |
| HealthKit read categories | User opens Health-informed progress analysis | Analyze meal data only |

## 17. Visual and interaction design requirements

The final visual direction is intentionally unresolved. Wireframing must happen before visual styling.

### 17.1 Wireframe phase

Produce grayscale wireframes and a clickable prototype for:

- Today dashboard.
- Predicted-meal detail sheet.
- Expanded AI/photo/voice input.
- Restaurant dashboard state.
- History and day editing.
- End Day and streak recovery.
- Adventure reward entry state.

Validate hierarchy, reachability, tap count, and bottom-sheet behavior before choosing fonts, icons, colors, or imagery.

### 17.2 Visual exploration phase

After wireframe approval, produce five distinct design directions using the same approved structure. Each direction must specify:

- Font family and license.
- Icon system and license.
- Color tokens with light/dark behavior.
- Progress-ring treatment.
- Suggestion-card treatment.
- Food imagery approach.
- Macro celebration behavior.
- Relationship between nutrition UI and adventure UI.

### 17.3 Asset licensing

- All reusable fonts, icons, illustrations, and graphics must use open-source or clearly permissive commercial licenses.
- Track source and license metadata in the repository.
- Do not rely on SF Symbols if the project requires every design dependency to be open source.
- User meal photos are preferred for learned meals.
- Open-source emoji or illustrations may provide cold-start imagery.
- Open Food Facts may support packaged product imagery subject to attribution and share-alike requirements.
- Openverse or Wikimedia Commons images must be filtered and recorded per asset license.
- Restaurant and delivery-service imagery must not be reused without permission.

## 18. Accessibility

- Support Dynamic Type without clipping primary actions.
- Provide VoiceOver labels for rings, macro progress, suggestion cards, ingredient toggles, and game state.
- Never communicate status through color alone.
- Maintain approximately 44-by-44-point touch targets.
- Respect Reduce Motion while preserving completion feedback.
- Support adequate contrast in light and dark modes.
- Keep editable text inputs at least 16 points where platform behavior requires it.

## 19. Error and edge-case handling

- **No network:** Known foods, manual entry, history, totals, and game state remain available. Queue AI/menu work or provide a manual fallback.
- **AI timeout:** Keep the input/photo available and offer retry or manual edit.
- **Unknown nutrients:** Show estimated/unknown state; never count unknown as zero silently.
- **Wrong venue:** Provide immediate venue correction and remember it.
- **Adjacent restaurants:** Ask the user to select among plausible venues.
- **No menu:** Reveal fallback input immediately.
- **Duplicate optimistic entry:** Undo and duplicate detection should prevent accidental double logging.
- **Midnight while editing:** Preserve the intended local day and allow changing it explicitly.
- **Timezone travel:** Do not rewrite historical day assignments.
- **Permission revoked:** Detect gracefully and explain how to re-enable only when the feature is invoked.
- **Deleted photo:** Meal entry remains intact because original photos are not required after analysis.
- **Game generation failure:** Preserve banked resources and current structured state; retry without charging resources twice.
- **Character death:** Persist world/legacy state before presenting successor or resurrection options.

## 20. Analytics and observability

For a personal build, analytics should default to local-only product counters. Operational telemetry must exclude sensitive content.

Useful event types:

- Dashboard opened.
- Suggestion displayed and rank.
- Suggestion selected.
- Input method initiated and completed.
- Entry edited or undone.
- Category resolved or skipped.
- Day completed or recovered.
- Reminder scheduled/opened/dismissed.
- Venue resolved/corrected.
- Menu found/fallback used.
- Adventure reward earned/spent.
- AI request latency, success, and schema-validation failure without raw meal/photo content.

## 21. MVP acceptance criteria

The MVP is ready for personal daily use when all of the following are true:

1. The app installs directly on the user’s iPhone through Xcode.
2. The user can set calorie and macro targets.
3. Today displays the four-part completeness ring and neutral macro progress.
4. The user can log, skip, edit, and delete entries in all four meal categories.
5. The app rolls days automatically and allows historical editing.
6. A known predicted meal can be logged with editable ingredients and portion.
7. Text and voice descriptions create structured estimated entries.
8. A taken or uploaded photo creates an automatic best-estimate entry with Edit and Undo.
9. At least basic passive ranking uses meal history and time of day.
10. Foreground location can resolve a restaurant or allow correction.
11. Restaurant mode can show prior orders, attempt menu lookup, and fall back without blocking.
12. Learned meal reminders respect resolved categories and notification settings.
13. Complete days increment a streak; incomplete days reset it; historical correction can restore it.
14. Logging generates banked adventure resources without requiring immediate play.
15. A bounded playable adventure supports a main character, companions, quick encounters, structured state, and resource spending.
16. HealthKit data can be read for an explicitly initiated progress conversation when authorized.
17. Structured data survives app restart and is backed up or synced through the approved encrypted iCloud design.
18. Original food photos are not retained by default.
19. The app remains usable when optional permissions are denied.
20. No API secrets are present in the client repository or binary.

## 22. Suggested delivery phases

### Phase A: Product and interaction foundation

- Approve grayscale wireframes.
- Define local data model.
- Implement dashboard, day lifecycle, manual logging, targets, and history.
- Import initial known-food seed data.

### Phase B: Friction reduction

- Add predicted meals and passive learning.
- Add ingredient/portion detail sheet.
- Add text, voice, camera, and photo estimation.
- Add Edit and Undo learning loop.

### Phase C: Context and continuity

- Add foreground location and venue resolution.
- Add menu search hierarchy and restaurant fallback.
- Add meal-time notifications.
- Add encrypted iCloud backup/sync.
- Add HealthKit-powered on-demand progress analysis.

### Phase D: Reward layer

- Add banked resources and reward animation.
- Implement bounded AI dungeon master.
- Add character, companions, fast encounters, death, legacy, and resurrection.

### Phase E: Refinement

- Select and apply final visual direction.
- Accessibility audit.
- Latency and AI-cost optimization.
- Personal beta use and prediction tuning.

## 23. Open decisions

These decisions do not block the initial wireframe or data-model work:

- Application name and brand identity.
- Final visual direction, fonts, icons, and color system.
- Exact streak-recovery window and presentation.
- Nutrition database and menu-search providers.
- AI model/provider selection.
- On-device versus cloud transcription.
- Minimum supported iOS version.
- Specific encrypted iCloud implementation.
- Retained thumbnail policy for learned meals.
- Adventure setting, art direction, progression balance, and content boundaries.
- Whether later versions write nutrition data to Apple Health.
- Whether later versions add Always Location, widgets, Live Activities, or Apple Watch.

## 24. First engineering milestone

The first milestone should produce a local-only vertical slice:

1. Today dashboard with all four meal categories.
2. Manual and seeded-food logging.
3. Predicted-food cards using simple time/history ranking.
4. Portion and ingredient detail bottom sheet.
5. Daily totals, End Day, history, streak calculation, and recovery.
6. Mocked AI, restaurant, HealthKit, and adventure interfaces behind protocols so real services can be integrated later.

This milestone validates whether the primary habit loop is fast and satisfying before adding expensive or permission-heavy dependencies.
