# Task 29 — Full-route optimizer memory/state explosion

Status: IN PROGRESS  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Tasks 23 and 24

## Reported failure

Opening Enchanting in Cheapest mode freezes the WoW 3.3.5 client and eventually raises:

`DynamicRecommendations.lua: memory allocation error: block too big`

After the optimizer aborts, the addon also incorrectly shows `No guide step is available` even though the deterministic Enchanting guide has a valid step.

## Root cause

The full-catalog route implementation carried every newly acquired recipe ID inside the shortest-path state.

That means a route node was keyed by:

- current skill,
- trained profession cap,
- the entire set of recipe acquisitions/tools/training already encountered.

With many unlearned recipes, the number of distinct acquisition sets grows combinatorially. The recipe-cost cache then stored a separate cost table for each recipe/skill/acquisition-set combination. On the 32-bit-era WoW 3.3.5 Lua runtime this can exhaust the allocator simply by opening a profession window.

The `No guide step` message is a secondary error: dynamic optimization and static-guide selection were inside the same protected callback. When the optimizer threw, the callback exited before the static handler ran.

## Fix

### Bounded route state

Task 29 originally solved the allocator failure by modeling recipe acquisition as a segment activation instead of carrying the full learned-recipe set.

That removed the combinatorial Lua-table state that caused the freeze, but it meant a route could conservatively repay an acquisition after switching away and later returning.

Task 38 supersedes that approximation with a compact candidate-scoped bitset:

- learned/acquired recipes are remembered exactly while they can still affect future route choices;
- expired recipe bits are removed once the recipe can never appear again;
- reusable profession tools/rods remain in the existing small acquisition map;
- profession-rank training remains represented by trained cap/state;
- live layered states are hard-capped before a next layer can exceed `maxStates`.

A completed route therefore has true one-time recipe acquisition semantics again without restoring arbitrary recipe-ID Lua sets.

### Skill-range recipe index

The full catalog is pre-indexed by useful skill range using bundled difficulty metadata.

At each simulated skill point, the solver evaluates only recipes that can still skill up and whose skill requirement can be met, rather than scanning every recipe in the profession catalog for every route state.

The live profession-book color remains authoritative for the current skill.

### Bounded recipe-cost cache

The pass-local recipe-cost cache is capped at 4,096 entries.

After Task 38 its key distinguishes the candidate recipe's exact acquired/not-acquired state in addition to current recipe/skill/reusable state. The compact bitset itself is not serialized into the cache key.

### Static fallback isolation

Dynamic recommendation calculation now has its own protected call.

If it fails:

- the deterministic guide still runs,
- the addon does not incorrectly show `No guide step`,
- dynamic optimization is disabled for the remainder of that UI session to prevent repeated freeze/error loops,
- reopening the profession continues to use Static fallback until the next UI reload.

## Regression coverage

Automated tests cover:

- one-time recipe acquisition across a continuous segment,
- full-catalog future recipe switching,
- active +profession modifiers,
- candidate skill-range indexing,
- a many-recipe route constrained to a bounded number of explored states/cost evaluations,
- route-active recipe acquisition state.

## Acceptance criteria

- Lua 5.1 syntax and full repository validation pass.
- Full-catalog optimizer no longer grows acquisition-set states combinatorially.
- Recipe-cost cache cannot grow without bound.
- Static guide survives any optimizer exception.
- Existing future-recipe/adaptive-route behavior remains covered by tests.
- Enchanting window opens responsively in game without allocator failure.

## Manual acceptance

Re-test the exact Enchanting window that previously froze. Confirm Cheapest, Available and Static can each be opened/switched without a freeze and that a valid guide/recommendation appears.

Manual in-game verification remains pending before marking DONE.
