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
