# Task 15 — Core UI hierarchy and material redesign

Status: DONE  
Phase: 5 — UI/UX polish  
Depends on: Task 10, Task 14

## Goal

Make the default Profession Capper panel immediately answer:

> What should I do right now, what will it cost, and what do I need to buy?

This task is visual/information hierarchy only. Do not change optimizer decisions.

## Implement

### Header

- Keep `Profession Capper` as the title.
- Put profession progress directly below it.
- Present `Cheapest now` / `Static guide` as a visually coherent two-state control.
- Keep `Compare` secondary.

### Recommendation block

Make the current recommendation visually dominant.

Show:

- recipe icon;
- recipe name;
- live recipe difficulty;
- current skill → recommendation segment target;
- one short reason, such as `Cheapest current skill-up`;
- current availability / makeable count.

Do not use a large nested card.

### Cost summary

Replace the current loosely grouped status lines with a compact readable summary:

- per application;
- expected per skill-up;
- immediate missing-material purchase cost if available;
- price source/freshness in secondary text.

Never display a fake full-route total when only the current segment is valid.

### Materials

Rework material rows into two-line rows:

Primary:

```text
[item] Required material                       owned / needed
```

Secondary:

```text
Buy N× recommended source · save ~X            ~cost
```

For normal materials:

```text
Buy N                                           ~cost
```

If no purchase is needed, suppress the secondary purchase line.

Preserve:

- item-quality name color;
- missing-material indication;
- conversion purchase guidance from Task 14;
- price freshness;
- hover tooltip;
- Shift-Right-Click AH search.

### Spacing

Use consistent internal spacing and thin separators between logical sections.

Avoid:

- nested boxes;
- excessive vertical gaps;
- large empty areas;
- repeated labels that say the same thing.

## Suggested file changes

- `Profession_capper.xml`
- `Core.lua`
- `Localization.lua`

Do not add a UI framework.

## Acceptance criteria

- Current recommendation is the strongest visual element after the window title.
- User can identify recipe, color/difficulty, per-application cost, per-skill-up cost, and missing materials without hovering.
- Equivalent-essence buy guidance is visible inline.
- Material rows remain readable with long WotLK item names.
- Cheapest/static mode state is visually obvious.
- Dynamic fallback is obvious without dominating the whole panel.
- Panel still grows correctly for material count.
- No overlap at the minimum supported UI scale used during manual testing.
- ElvUI skinning does not make text/buttons unreadable.
- Existing crafting/enchant behavior is unchanged.

## Implementation note

Implemented on master pending manual acceptance. Automated validation must pass before the commit is considered ready for testing.

The code changes:

- reorganize the stable XML hierarchy around profession progress, recommendation, costs, materials, and the primary action;
- show the live recipe difficulty beside the current skill range;
- keep current-step price source/freshness visible instead of promoting full-route totals in the default view;
- show normal-material `Buy N` guidance as well as equivalent-reagent conversion guidance;
- summarize the immediate missing-material purchase total when all required prices are available;
- make Cheapest-now / Static-guide selection visually persistent without disabling the selected button;
- size the footer differently when Enchant repeat controls are actually present.

Second-pass visual implementation now uses the approved restrained mockup as the concrete target:

- wider but still compact 560px panel;
- profession icon plus a real progress bar;
- recommendation heading and right-aligned short reason;
- separate difficulty badge and skill target;
- four aligned metrics for application cost, skill-up cost, makeable count, and immediate buy-missing cost;
- subdued TSM source/freshness line;
- real Have / Need / Missing / Est. Cost material columns;
- a dedicated green best-buy callout row for Greater/Lesser Essence conversions instead of squeezing guidance into the material line;
- a larger centered primary action while preserving static recipe navigation and Enchant repeat controls.

The required in-game screenshots and ElvUI checks below are still pending, so this task remains `IN PROGRESS`.

## Manual screenshots to capture

Before marking DONE, capture:

1. Cheapest-now Enchanting recommendation with 2+ materials.
2. Equivalent-essence purchase hint.
3. Missing-material state.
4. Static guide mode.
5. ElvUI enabled.

## Manual acceptance

Accepted in-game on 2026-09-13. The user reviewed the live Phase 5 UI and explicitly requested that the prior Phase 5 blockers be closed so remaining presentation issues can move into Task 19 cleanup.

## Commit

Suggested message: `feat: polish profession recommendation hierarchy`
