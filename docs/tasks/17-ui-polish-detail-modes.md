# Task 17 — Compact and expanded detail modes

Status: DONE  
Phase: 5 — UI/UX polish  
Depends on: Task 16

## Goal

Keep the normal panel focused while allowing deeper route/cost detail on demand.

Task 16 was manually directed to use a dedicated Compare companion panel after this task was originally written. Task 17 therefore must not undo that accepted design or duplicate the ranked comparison table inside the main panel. Expanded mode adds inline route/coverage context; the existing Compare panel remains the single detailed recipe-comparison surface.

## Modes

### Compact

Default.

Show only:

- profession progress;
- mode selector;
- current recommendation;
- essential cost summary;
- materials;
- relevant enchant repeat state;
- primary action.

Comparison/route details are collapsed.

### Expanded

Adds inline:

- full-route total when available;
- immediate gold needed for the route;
- expected remaining crafts;
- route-level stale/missing price coverage;
- number of comparable orange/yellow recipes.

The detailed ranked recipe comparison remains in the existing Task 16 Compare companion panel. Expanded mode references that surface rather than reproducing the same rows in the main panel.

## Persistence

Add one saved setting:

`detailMode = "compact" | "expanded"`

Default to `compact`.

Use the existing settings module; do not add a second saved-variable structure.

## Control

Use a small secondary affordance such as:

- `Details ▾` / `Details ▴`, or
- a small +/- style button with tooltip.

Do not add another large primary-looking button.

## Resizing

Panel height must be derived from visible content.

No fixed empty space should remain when details are collapsed.

## Suggested file changes

- `Settings.lua`
- `Core.lua`
- `Profession_capper.xml`
- `Localization.lua`

## Implementation note

Implemented on master pending in-game acceptance.

- Added persisted `detailMode = "compact" | "expanded"` to the existing settings structure; default is `compact`.
- Added one small `Details + / Details -` secondary control.
- Compact leaves the Task 15/18 decision flow unchanged.
- Expanded inserts one inline Route details section after Materials with route total, immediate gold needed, expected crafts, route price coverage, and comparable-candidate count.
- The Task 16 Compare companion panel remains independent and is not duplicated or automatically opened/closed by Details.
- Main-panel height includes the details block only while Expanded.
- Toggling Details calls only the render path; it does not reset recommendation state or the Enchant repeat session.

## Acceptance criteria

- New users open in compact mode.
- Mode persists across reload/restart.
- Expanded mode shows route/cost-coverage information inline without creating any additional window; detailed recipe ranking remains in the already-existing Compare companion panel.
- Compact mode contains no dead vertical space left by hidden sections.
- Switching modes does not change recommendation/crafting state.
- Enchant repeat session survives toggling details.
- Material rows remain in the same logical place in both modes.
- No frame overlap at supported UI scales.

## Manual acceptance

Accepted in-game on 2026-09-13. The user reviewed the live Phase 5 UI and explicitly requested that the prior Phase 5 blockers be closed so remaining presentation issues can move into Task 19 cleanup.

## Commit

Suggested message: `feat: add compact and expanded profession views`
