# MealTrack Wireframe — Design Direction

## Three stylistic approaches

### Theme Name: Monochrome Editorial Instrument
Very spare, paper-like grayscale UI that makes the hierarchy and interaction model impossible to miss. It treats logging as a calm daily instrument rather than a wellness scorecard.

**Probability:** 0.03

### Theme Name: Soft Utility Canvas
A warm neutral interface with tactile panels and restrained color accents, designed to feel approachable and domestic without becoming playful.

**Probability:** 0.08

### Theme Name: Quiet Field Notes
A highly typographic, text-forward system inspired by field journals and premium health print design, with imagery reserved for moments of recognition.

**Probability:** 0.06

## Chosen approach: Monochrome Editorial Instrument

### Design Movement
Swiss editorial modernism translated into a native iPhone utility: strict hierarchy, visible structure, and quiet confidence.

### Core Principles
1. **Hierarchy before decoration.** Every block exists to clarify what to do next.
2. **Neutral progress.** Nutrition is observable information, never a pass/fail judgment.
3. **Low-friction defaults.** The predicted meal is the largest, most obvious action.
4. **Feedback without pressure.** Logging earns a small confirmation and resources, while missed days never erase adventure progress.

### Color Philosophy
Phase 1 is intentionally grayscale: ink, graphite, fog, paper, and a single darker action tone. The lack of branded color prevents visual polish from obscuring the structure under review. Status is expressed through labels, spacing, and fill—not warning colors.

### Layout Paradigm
A narrow phone frame anchors a two-column review canvas on desktop. Inside the phone, the dashboard reads top-to-bottom as a daily brief: completeness ring, neutral macro snapshot, streak/reward rail, then predicted actions. Bottom sheets rise from the AI input and meal cards so the interaction model remains explicit.

### Signature Elements
- A segmented logging ring divided into Breakfast, Lunch, Dinner, and Snacks.
- Dashed borders and annotation labels that make wireframe intent visible.
- A persistent “next easiest action” rail at the bottom of the phone.

### Interaction Philosophy
The interface anticipates rather than asks. Tapping a predicted meal opens a prefilled detail sheet. Tapping the AI field expands the capture choices. Restaurant mode changes the suggestions in place. Every action has a visible escape route: Undo, Edit, Close, Back, or End day.

### Animation
Use only short, functional transitions: sheets rise in 220ms, selected chips settle in 140ms, and reward confirmation fades in without blocking the next action. Respect reduced-motion preferences. No decorative entrance animation belongs in Phase 1.

### Typography System
Use Arial for the low-fidelity prototype to preserve the wireframe character and keep focus on hierarchy. Headlines are 700 weight with tight tracking; labels are 10–11px uppercase with expanded tracking; body copy is 13–15px with generous line-height.

### Brand Essence
A calm meal log for adults who want consistency without judgment—prediction makes the next healthy habit easier to repeat. Personality: **clear, encouraging, unpressured**.

### Brand Voice
Headlines are direct and human. CTAs describe the action, not a promise. Microcopy reassures without congratulating dietary perfection.

Example lines: “You usually eat around now.” / “Log it as-is. You can edit later.”

### Wordmark & Logo
Use the generated four-part open ring mark as a temporary Phase 1 symbol. Its missing segment signals that a day can be incomplete without becoming a failure; the ring can be completed through logging or an explicit “Skipped / None” choice.

### Signature Brand Color
Deferred until Phase 2 review. Phase 1 uses graphite as the only action emphasis so the interaction hierarchy can be evaluated without color bias.

## Phase 1 scope decision

This implementation deliberately stops at the grayscale clickable wireframe. It includes the dashboard, predicted-meal detail sheet, expanded AI capture sheet, restaurant context state, history/day editing, End Day and streak recovery, banked adventure entry, and a concise hierarchy rationale. Phase 2 visual exploration is intentionally deferred until the wireframe has been reviewed and approved.


## Phase 2 visual exploration

The five directions below preserve the approved information architecture and interaction model: the same daily completeness ring, neutral macro snapshot, compact Next Meal suggestions, direct capture bar, predicted-meal detail sheet, and bottom navigation. They differ only in visual language, typography, icon treatment, palette, surfaces, imagery, and motion character.

| Direction | Design character | Font system | Icon system | Palette | Surface and control language | Food imagery | Tradeoff |
|---|---|---|---|---|---|---|---|
| **01 — Warm Editorial** | Premium print-inspired utility with a warm paper ground, ink typography, and one restrained botanical accent. | Fraunces for display moments; DM Sans for interface copy. Both are open-source under the SIL Open Font License. | Lucide icons, 1.75px stroke, softened corners. Lucide is ISC licensed. | Paper `#F4F0E8`, ink `#25231F`, clay `#B8664D`, sage `#72806C`, line `#D8D0C4`. | Slightly rounded cards, hairline borders, clay primary button, ring uses clay only for completed segments, input is a paper inset. | User-generated meal photos first; consistent generated placeholders for missing meals. Avoid food-photo overload by using one image per suggestion. | Strongest editorial warmth and adult tone, but the clay accent can compete with the neutral-progress principle if overused. |
| **02 — Mineral / Clinical Calm** | High-clarity health utility that feels precise, credible, and quietly reassuring rather than sterile. | Plus Jakarta Sans for all UI with a heavier optical display weight. Open-source under the SIL Open Font License. | Phosphor Icons, regular weight, consistent 20px optical box. Phosphor is MIT licensed. | Chalk `#F7F8F6`, graphite `#202525`, mineral blue `#547A82`, moss `#7E927A`, border `#DDE3DF`. | Crisp 10px radii, soft shadow beneath sheets, dense but breathable metric rows, mineral-blue action states, pale inset input. | Open Food Facts imagery when a packaged product is recognized, with visible attribution in detail context; otherwise neutral generated placeholders. | Most legible and trustworthy, but risks drifting toward generic clinical wellness software. |
| **03 — Citrus Ledger** | Energetic but disciplined habit tracker using a ledger-like layout and a single citrus signal for moments of action. | Space Grotesk for headings; IBM Plex Sans for body. Both are open-source under the SIL Open Font License. | Tabler Icons, 2px stroke, squared optical geometry. Tabler is MIT licensed. | Soft white `#FBFAF5`, carbon `#20211E`, citrus `#E4A52D`, terracotta `#C66A4B`, divider `#D9D6CB`. | Low-radius cards, bold underlined links, solid carbon buttons, citrus ring completion, tactile 1px inset input with compact controls. | Consistent generated overhead food thumbnails with flat daylight and neutral backgrounds; no restaurant imagery unless user-supplied or openly licensed. | Makes the next action highly noticeable, but the citrus signal needs strict restraint to avoid reward-chasing or childish gamification. |
| **04 — Night Kitchen** | Low-light, late-evening companion with charcoal surfaces, warm food photography, and quiet amber focus states. | Manrope for interface; Instrument Serif for occasional meal names. Both are open-source under the SIL Open Font License. | Lucide icons in light stroke, with a small amber active state. ISC licensed. | Charcoal `#171917`, surface `#232722`, cream `#F2EEE4`, amber `#D6A35D`, muted sage `#819286`. | Soft 16px sheets, layered dark surfaces, cream text, amber primary action, progress ring uses cream and amber without red or warning states. | User-generated photos or openly licensed food photography with attribution; use dim, natural kitchen-light crops and never repeat the same image across cards. | Most emotionally distinctive and native-feeling at night, but dark mode reduces scan speed for dense macro data and requires careful contrast validation. |
| **05 — Coastal Utility** | Airy, optimistic, and spacious: a modern field guide for daily meals with oceanic blue and sea-glass green. | Public Sans for functional UI; Newsreader for editorial meal labels. Both are open-source under the SIL Open Font License. | Radix Icons, compact and geometric, MIT licensed. | Mist `#F1F5F2`, ink `#19323A`, ocean `#287A85`, sea-glass `#8BB7A6`, sand `#D9C9A7`. | Rounded 14px cards, subtle tinted panels, ocean filled CTAs, ring uses sea-glass completion, input is a wide pill with an anchored icon rail. | Open-source emoji or food illustrations for suggestions, supplemented by user-generated photos when available; avoid fantasy or childish illustration styles. | Most approachable and spacious, but the softer colors can weaken the urgency of the predicted next meal if hierarchy is not kept strict. |

### Shared comparison criteria

The review should compare the options on the same five questions: Which direction makes the predicted meal the most obvious next action? Which one keeps nutrition neutral rather than judgmental? Which one feels most adult and native to iPhone? Which one gives food imagery a useful recognition role without becoming decorative noise? Which one has the clearest path from tap to log, edit, and undo?

### Licensing note

The font families named above are intended to be sourced from Google Fonts or their official repositories under the SIL Open Font License. Lucide, Phosphor, Tabler, and Radix Icons are permissively licensed open-source icon sets as noted in the table. User-generated photos must be treated as user-owned content. Open Food Facts imagery requires attribution and compliance with its database and image-license terms. Openly licensed photography and emoji/illustration sources should be cited in the product’s asset notes when used. Generated placeholders are used only where no licensed or user-supplied image is available.


## Phase 2 refinement decision

The comparison set is intentionally reduced to two directions for focused review: **Mineral Calm** is retained as Option 2 from the original exploration, and **Bright Signal** is added as a new bright-color alternative. Warm Editorial, Citrus Ledger, Night Kitchen, and Coastal Utility are retired from the active comparison canvas. Both remaining options preserve the same dashboard and meal-detail UX.
