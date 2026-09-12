# Briar Glen: first playable region

## Direction and scope

The user's references are Red Dead Redemption, SimCity, Civilization VI, and Yellowstone with a touch of fantasy. The player inherits a homestead and grows it into a commonwealth, responsible for aligned families. This implementation is a compact first region, not a claim of comparable scale or production budget.

The opening explains the inheritance, Mara/Sable/Ilyra, rival Calder Voss, and the first objective. A coherent six-site map shows ownership, buildings, inhabitants, and the player's location. Land, People, and Journal remain separate views of the same saved state.

## Play loop

1. Meals earn 3 XP each; completed days earn another 8. These are the existing reward-ledger rules, independent of food quality or macro targets.
2. Claim the deed for free. Restore water for 3 XP and 2 timber.
3. Patrol the crossing for 6 XP. Read enemy intent, then Attack, Guard, Flank, Rally, or Retreat. Once started, every turn is free, including after relaunch.
4. Paid expeditions supply timber, stone, and provisions. Gardens, lumber camp, and quarry improve yields and recruit families.
5. Choose one permanent crossing landmark: defense (watchtower) or resource income (trading post). Costs and exclusivity are displayed before spending.
6. Found the commonwealth hall. Three rotating council disputes offer two responses each, trading materials and XP against citizen trust. At 75 trust, resource expeditions yield an extra supply.

One completed three-meal day earns 17 XP: enough for water, a full patrol, and a smaller land action. Seven such days bank 119 XP if unspent. There is no daily reset, energy cap, offline attack, or resource decay. Inspection and travel do not cost XP. Resource recovery actions have no material prerequisites, preventing an empty-store softlock; new actions still require banked meal XP.

## Tactical rules

- Strike: 4 incoming damage; side cover blocks 1, Guard blocks 4.
- Brace: frontal attacks deal 1; Flank deals 5 before any tower bonus.
- Aim: 5 damage targets the current lane. Flank moves to the next lane, evading the shot; side cover otherwise blocks 1.
- Rush: 6 incoming damage; Guard blocks 4 and counters for 2.
- Rally restores up to 5 health once per patrol; the opponent still acts.
- A watchtower adds 4 starting health and 1 Attack/Flank damage, except a frontal attack against Brace remains 1.
- Defeat or retreat preserves buildings and stores. The patrol cost remains spent; a new patrol starts at full health. Victories grant supplies and secure the crossing, never free XP.

The seeded PRNG and full combat state are saved, so relaunch does not reroll an encounter. Enemy health grows modestly with victories and is capped. Combat currently has one rival faction and a small intent set, not a deep character-class/equipment system.

## Persistence and meal safety

`CommonwealthGame.swift` owns the deterministic engine and Codable state. `MealTrackerStore` reads the authoritative reward ledger before spending, saves the new game state, then publishes it. A failed save does not charge the displayed bank or advance play.

The balance is `max(0, earned rewards - legacy Adventure spend - commonwealth spend)`. Undoing a rewarded meal therefore cannot create extra spendable XP; any resulting deficit is covered by later genuine rewards. Nutrition edits do not mint XP. Existing meal records and the legacy `adventure-state-v1` save are not migrated or deleted. The new save uses `commonwealth-state-v1`; old legacy state remains readable by the store but its interface is no longer shown.

The latest 40 journal events are retained; event IDs remain monotonic. Production has no test rewards. The `-uiTestingCommonwealth` fixture requires `-uiTesting` and logs eight entries into an isolated in-memory repository through the normal reward path.

## Asset and runtime budget

Three images are reused across the introduction, map, citizens, and battle:

| Asset | Dimensions | Source disk allocation |
| --- | --- | --- |
| Valley JPEG | 1120 × 1400 | 772 KiB |
| Three-citizen JPEG atlas | 1152 × 384 | 164 KiB |
| Two-fighter transparent PNG atlas | 768 × 512 | 408 KiB |

Total source allocation: 1,344 KiB (about 1.31 MiB). The atlas/background pixel data would occupy about 9.2 MiB if all decoded once as 4-byte RGBA; this is an arithmetic estimate, **not a measured peak app-memory result**. Asset-catalog packaging, texture copies, view caches, and the rest of the meal app affect installed size and runtime memory.

Buildings, ownership banners, and tiny inhabitants are drawn with SwiftUI Canvas. Native terrain and trails provide a fallback if the painted map is unavailable. Map selection and combat use native controls. There is no new package dependency, 3D scene, display-link loop, downloaded level data, video, procedural content service, or gameplay model call. Reduce Motion removes optional map/scroll animations. Full labels and state are exposed for map locations and combat; the visual map's small cartographic labels intentionally remain compact. At accessibility text sizes, a separate Locations list provides scalable buttons for all six places, and combat controls stack vertically. Action outcomes automatically scroll into view.

## Art provenance and briefs

All three assets were generated for this project using the built-in image-generation tool, then resized/compressed for shipping. No game screenshots or third-party character art were incorporated. The following records the asset briefs:

- **Valley:** portrait-format detailed painterly isometric frontier valley; northern rocky ridge, western evergreen forest, eastern winding stream, open homestead and township clearings, coherent traversable terrain, warm muted earth colors, subtle fantasy. No text, UI, characters, or permanent buildings; native state overlays supply those.
- **Citizens:** one horizontal, equally divided three-portrait atlas in a consistent painterly frontier-fantasy style. Mara: capable ranch forewoman; Sable: male scout; Ilyra: older female physician. Distinct faces, grounded clothing, restrained backgrounds, no text.
- **Fighters:** transparent horizontal two-cell atlas of full-body frontier-fantasy combatants. Player on the left in a blue duster, rival on the right in a rust-red coat with shield. Readable silhouettes, matching lighting and scale, no text or interface.

Generated originals remain outside the repository; only the shipping-resolution assets are tracked. `Assets.xcassets/BriarGlen*.imageset` contains the images and their catalog metadata.

## Verification scope

The exact latest test and visual-inspection results are recorded in `IMPLEMENTATION_CHECKLIST.md`. Tests cover resource gates and yields, mutually exclusive buildings, cover/aimed lanes, combat persistence, defeat/retreat, seven-day banking, legacy-save preservation, undo debt, failed-save atomicity, repeat council decisions, and bounded save size.

An independent game-critic agent reviews clarity, agency, tactical depth, progression, repeat play, visual coherence, and mobile-session fit. Its rating is a design judgment, not proof that eight out of ten players will enjoy the game. Longer-term retention and perceived session length require human playtesting. Physical-device VoiceOver order and measured peak memory also remain separate verification work.

### Independent first-region review, September 12, 2026

| Criterion | Editorial score / 10 |
| --- | --- |
| Story introduction and immediate motivation | 8.5 |
| Spatial gameplay and orientation | 8 |
| Meaningful decisions and consequences | 7.5 |
| Tactical combat and readable feedback | 8 |
| Banked XP and short-session fit | 8 |
| Visual craft and footprint | 8 |

Overall: **8.0/10 for the first playable region**. Iteration corrected cosmetic-only cover, inaccurate tower descriptions, a post-charter dead end, first-session sequencing, below-fold combat controls, mismatched landmark rendering, and accessibility navigation. The critic's remaining concern is breadth: three recurring council situations and one rival faction do not constitute a long-lived campaign. This score is not a player-survey percentage or a AAA-quality certification.
