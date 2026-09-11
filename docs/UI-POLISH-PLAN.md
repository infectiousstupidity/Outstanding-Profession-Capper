# Profession Capper UI polish plan

Status: PLANNED  
Scope: Phase 5 — UI/UX polish  
Implementation: tasks 15–19

## Goal

Make Profession Capper feel like a focused decision tool instead of a debug/status panel.

The first question the UI must answer is:

> What should I do right now?

Everything else is supporting information.

Do not redesign the addon into a dashboard. Keep it compact, native to WoW 3.3.5, compatible with ElvUI, and usable while the TradeSkill window is open.

## Design principles

1. **One dominant recommendation.** The current recipe and primary action must be visually dominant.
2. **Progressive detail.** Costs and materials are immediately visible; route/comparison detail is available without overwhelming the default view.
3. **Explain the optimizer.** The player should be able to see why a recipe is cheapest without reverse-engineering tooltips.
4. **Buying guidance must be explicit.** If the addon recommends buying a different reagent form, show exactly what to buy.
5. **State must be obvious.** Crafting, waiting for target, ready for next enchant, stale prices, and fallback mode must look different.
6. **No nested-card UI.** Use spacing, typography, thin separators, and restrained backgrounds rather than boxes inside boxes.
7. **No gratuitous decoration.** No gradients, oversized headers, fake shadows, or ornamental chrome.
8. **Preserve WoW/ElvUI compatibility.** Prefer standard frame primitives and inherited fonts/buttons. Do not depend on Retail-only APIs.

## Target visual hierarchy

From top to bottom:

1. Title + close button
2. Profession / skill progress + mode controls
3. Current recommendation
4. Primary cost/action summary
5. Materials and purchase guidance
6. Optional comparison/route detail
7. Enchant repeat controls when relevant
8. Primary action footer

## Proposed default layout

Approximate compact state:

```text
┌──────────────────────────────────────────────┐
│ Profession Capper                       [×]  │
│ Enchanting 315 / 385 (+10)                  │
│ [Cheapest now]  Static guide      [Compare] │
│──────────────────────────────────────────────│
│ [icon] Enchant Gloves - Greater Agility     │
│        YELLOW · skill 315 → 320              │
│        Cheapest current skill-up             │
│                                              │
│ ~2g 40s / application   ~3g 20s / skill-up  │
│ Can make 5              current TSM prices  │
│──────────────────────────────────────────────│
│ MATERIALS                                    │
│ [i] Lesser Eternal Essence       0 / 3       │
│     Buy 1× Greater instead · save ~3g   ~9g │
│ [i] Illusion Dust                 2 / 4       │
│     Buy 2                                ~1g │
│──────────────────────────────────────────────│
│ Repeat: [Until change ▾]       Target: set   │
│                                              │
│            [ Enchant until change ]          │
└──────────────────────────────────────────────┘
```

Expanded detail state:

```text
│ WHY THIS ONE                                  │
│ 1  Greater Agility   Yellow  2.4g/app  3.2g/↑│
│ 2  Major Mana        Yellow  3.1g/app  4.1g/↑│
│ 3  Major Health      Orange  4.8g/app  4.8g/↑│
│                                              │
│ ROUTE                                         │
│ 315–320 Greater Agility  ~7 crafts   ~17g    │
│ 320–325 ...                                  │
```

The exact pixel dimensions can be adjusted during implementation. Preserve a narrow utility-panel feel; do not expand to a full-screen or TradeSkill-sized replacement UI.

## Visual system

### Background and separators

- Main backdrop: keep a near-black neutral background close to the current `0.035` values.
- Border: subtle gray, not bright gold.
- Section separators: 1 px equivalent, low-contrast gray.
- Avoid multiple panel backdrops inside the main frame.

### Typography

Use existing WoW fonts for compatibility.

- Title: `GameFontNormalLarge`.
- Recommendation title: `GameFontNormal`, visually strongest content after title.
- Primary numbers: `GameFontHighlightSmall`.
- Secondary/meta copy: `GameFontNormalSmall` or `GameFontDisableSmall`.
- Avoid all-caps except short section labels such as `MATERIALS` / `WHY THIS ONE`, if it remains readable in the client font.

### Semantic colors

Do not color whole paragraphs.

- Orange recipe: WoW recipe orange.
- Yellow recipe: WoW recipe yellow.
- Green recipe: WoW recipe green, but green recipes must not compete in Cheapest now unless product logic later changes.
- Good / cheapest / savings: restrained green.
- Warning / stale: amber.
- Missing / unavailable: red.
- Secondary text: neutral gray.
- Item names retain item-quality coloring.

Use color as reinforcement, never as the only signal.

## Current recommendation block

The recommendation block should expose:

- recipe icon;
- recipe name;
- live game-reported recipe difficulty;
- current skill → segment target;
- a short explanation: `Cheapest current skill-up`, `Static guide fallback`, etc.;
- cost per application;
- expected cost per skill-up;
- how many the player can currently make;
- price freshness/source in secondary text.

Do not repeat the same cost in three different places.

## Materials

Each material row should have two text levels:

Primary row:

```text
[item icon] Required material name         owned / required
```

Secondary row:

```text
Buy N× recommended source · save ~X        ~purchase total
```

For normal materials, secondary text can simply be:

```text
Buy N                                      ~purchase total
```

If owned quantity is sufficient, suppress purchase copy instead of showing `Buy 0`.

For Greater/Lesser essence conversion:

- keep the actual recipe reagent as the primary material;
- show the recommended source form on the second line;
- make savings visible without requiring hover;
- tooltip retains detailed conversion math;
- Shift-Right-Click searches the recommended source form.

## Cost summary

Default view should expose, at minimum:

- cost per application;
- expected cost per skill-up;
- immediate missing-material purchase cost when meaningful;
- price freshness.

A full route total should only appear when the full route is valid. Do not visually imply a full-route estimate exists when only the current step is trustworthy.

## Compare / trust UI

`Compare` should stop being tooltip-only in Phase 5.

It should toggle a compact inline section containing the current orange/yellow candidates, ordered by expected purchase cost per skill-up.

Each row:

```text
rank  recipe               difficulty  /app       /skill-up
1     Greater Agility      Yellow      2g 40s     3g 20s
2     Major Mana           Yellow      3g 10s     4g 08s
```

Requirements:

- highlight the selected winner;
- use live current recipe difficulty for the current skill;
- indicate stale/missing prices;
- never display a green recipe as a Cheapest-now competitor;
- cap default visible rows, with a simple `+N more` affordance if required.

The player should be able to answer “why is this cheaper?” from this section alone.

## Compact / expanded detail

Default should be compact.

Persist one setting:

- `compact` — recommendation + summary + required materials + primary action.
- `expanded` — adds comparison and route details.

Do not create separate windows.

The expand/collapse control should be a small text/icon affordance, not another large button.

## Enchant repeat workflow

When the recommendation is a targeted enchant, replace the generic footer with a coherent repeat strip.

Show:

- repeat mode;
- fixed count only when fixed-count mode is selected;
- remembered target state;
- repeat progress;
- primary `Enchant` action.

Suggested states:

```text
Repeat: Until change       Target: select item
Repeat: Fixed · 5          Target: Chestpiece
2 / 5 applied             Target: Chestpiece
Recommendation changed · repeat stopped
```

Do not make the user infer repeat state from button labels alone.

## Interaction rules

- `Cheapest now` and `Static guide` behave as a two-state segmented control visually, even if implemented with WoW buttons.
- `Compare` toggles inline detail rather than relying exclusively on hover.
- Material rows remain hoverable/clickable.
- Shift-Right-Click on a material searches for the recommended purchase item.
- Primary action remains a single obvious bottom action.
- Previous/next static-recipe arrows should not consume visual weight in Cheapest-now mode.
- Keyboard focus for the fixed repeat count must remain usable.
- No animation required.

## Data/state rules

UI polish must not duplicate optimizer logic.

Use existing values from:

- `dynamicRecommendation.currentCost`;
- `dynamicRecommendation.currentSegment`;
- `dynamicRecommendation.candidates`;
- `dynamicRecommendation.plan`;
- `getMaterialPriceInfo()`;
- craft/enchant session state;
- settings.

If a value is unavailable, display an explicit unavailable/fallback state rather than inventing `0` or an estimate.

## File-level implementation map

Primary files:

- `Profession_capper.xml` — static frame structure and anchors.
- `Core.lua` — dynamic rows, view state, rendering, comparison detail, material presentation.
- `Localization.lua` — all user-facing strings.
- `Settings.lua` — compact/expanded preference if persisted.

Tests:

- extend current Lua tests for any new presentation-state helper logic that can be tested without WoW frames;
- do not attempt to unit-test Blizzard frame rendering itself;
- add structural validation for any newly required XML named frames if useful.

## Non-goals

Phase 5 is not:

- a rewrite of the optimizer;
- a replacement TradeSkill window;
- a new settings system;
- a full shopping-list window;
- a new price provider;
- a custom UI framework;
- a Retail backport;
- an ElvUI hard dependency.

## Implementation order

1. Task 15 — hierarchy + recommendation/material redesign.
2. Task 16 — inline comparison / “why this one”.
3. Task 17 — compact/expanded detail mode.
4. Task 18 — enchant repeat presentation.
5. Task 19 — final visual QA, ElvUI compatibility, and cleanup.

Each task is one implementation commit and must update `TASKS.md`.
