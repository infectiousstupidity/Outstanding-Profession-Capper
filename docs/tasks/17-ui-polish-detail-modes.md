# Task 17 — Compact and expanded detail modes

Status: QUEUED  
Phase: 5 — UI/UX polish  
Depends on: Task 16

## Goal

Keep the normal panel focused while allowing deeper cost/route detail without opening another window.

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

Adds:

- recipe comparison;
- full-route summary when available;
- additional price/freshness detail that would otherwise require hover.

Do not duplicate the same information in both compact and expanded sections.

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

## Acceptance criteria

- New users open in compact mode.
- Mode persists across reload/restart.
- Expanded mode shows comparison and route information without another window.
- Compact mode contains no dead vertical space left by hidden sections.
- Switching modes does not change recommendation/crafting state.
- Enchant repeat session survives toggling details.
- Material rows remain in the same logical place in both modes.
- No frame overlap at supported UI scales.

## Commit

Suggested message: `feat: add compact and expanded profession views`
