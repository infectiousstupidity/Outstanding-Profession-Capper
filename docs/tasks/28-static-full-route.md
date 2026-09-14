# Task 28 — Static full-route browser

Status: IN PROGRESS  
Phase: 5 — UI/UX polish  
Depends on: Tasks 15, 17, 23, and 27

## Goal

Make the deterministic Static guide inspectable as a complete leveling route instead of only showing the current guide step.

The player must be able to select Static, open Route, and see the remaining guide from the current skill toward 450, including profession-rank training boundaries.

## Route construction

Build the static route from the registered profession guide itself.

Requirements:

- start at the character's current base profession skill,
- retain each guide step and its ordered recipe alternatives,
- apply the same guide relevance filters used by the current-step selector,
- retain bundled recipe records so output-item tooltips work,
- insert profession-rank training actions at the correct skill thresholds,
- split a guide range around a training boundary when necessary,
- if a required rank threshold is already behind the current skill but the rank is not trained, show the training action as the first applicable action,
- do not use AuctionDB/TSM pricing for Static mode.

## UI

- The existing Compare button becomes Route while Static mode is selected.
- Static mode opens directly to Full route; Current-price comparison is hidden because it is not meaningful in Static mode.
- Show recipe range, primary static recipe and number of alternatives.
- Crafts and cost are intentionally shown as unknown rather than fabricated.
- Hovering a static craft row uses the native item tooltip from Task 27 and lists alternative guide recipes.
- Long routes are paged in bounded groups so the companion window cannot grow beyond the screen.
- Dynamic Full route uses the same bounded paging behavior.

## Acceptance criteria

- Static mode exposes a complete remaining route.
- Profession-rank training appears in route order.
- Current-step relevance rules are preserved.
- Long routes remain usable on normal screen sizes.
- No price provider is required.
- Dynamic Compare/Full route behavior remains intact.
- Lua 5.1 tests cover guide splitting, training insertion, alternatives and overdue training.
- Repository validation passes.

## Manual in-game acceptance

Open at least one low/mid-skill profession and verify the Static route through multiple rank boundaries, page controls, native route-row tooltips and mode switching. Record the result before marking DONE.

Implementation is complete in code; manual in-game acceptance remains pending.
