# Task 30 — Precomputed adaptive-route runtime

Status: IN PROGRESS  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Tasks 23 and 29

## Goal

Opening or reopening a profession window must not rebuild and solve the same large static problem synchronously.

Most route structure is fixed by bundled WotLK data. Runtime work should be limited to character-specific and market-specific values such as current skill, learned recipes, owned materials, TSM prices, current availability and acquisition eligibility.

## Implementation

### Build-time route topology

`tools/generate_route_data.py` compiles `RecipeDifficultyData.lua` into `GeneratedRouteData.lua`.

The generated representation stores compact recipe start/stop events rather than a duplicated candidate list for every profession skill point. CI verifies that generated data is current.

`RouteData.lua` converts those events into a cached profession/modifier candidate index once per addon session.

### Candidate-scoped runtime model

Dynamic recommendations no longer iterate the entire profession catalog on every open.

Only recipes that can matter between the current skill and the reachable target are materialized from the catalog. Character state that is expensive or sparse is resolved lazily:

- ordinary reagent inventory,
- recipe-item ownership,
- prerequisite spell knowledge,
- reputation standing.

Only the small fixed reusable profession-tool set is checked eagerly.

### No full reagent scan on window open

The profession UI no longer calls `cacheAllRecipeReagents()` merely to calculate a recommendation.

The live profession book supplies learned recipe IDs/colors immediately. Bundled catalog reagents are used for optimization, while detailed live reagent data is still loaded for the selected recipe when needed for display/crafting.

### Layered dynamic programming

The adaptive route uses the monotonic profession-skill structure directly instead of the general heap/Dijkstra path for normal dynamic recommendations.

The solver advances one skill layer at a time, keeps only relevant route states, preserves profession-rank training and reusable-tool state, and expands recipe switches only from the cheapest equivalent state.

The original general solver remains available as a fallback/test path.

### Per-recipe material economics cache

Within one recommendation pass, the expensive invariant portion of recipe cost is evaluated once per recipe/material state:

- reagent prices,
- equivalent Greater/Lesser conversions,
- inventory contribution,
- current purchase/availability evidence,
- reusable reagent costs.

Later simulated skill points reuse that result and apply only the skill-up probability multiplier. Recipe acquisition remains evaluated per simulated state so learn/buy transitions stay correct.

### Recommendation result cache

Completed adaptive recommendations are reused for identical profession state.

The cache key includes:

- price provider and provider revision when available,
- profession,
- base skill and trained cap,
- active profession modifier,
- Cheapest/Available mode,
- optimization mode/target,
- learned recipe/color signature.

Bag, learned-spell, equipment and player-aura changes invalidate the cache. TSM exposes its realm scan revision when available, so a new scan naturally selects a new cache entry.

When a provider cannot expose a revision, cached results have a short safety TTL.

## Regression coverage

Automated tests verify:

- generated topology matches the source difficulty metadata,
- generated files are current in CI,
- modifier-aware candidate indexes are correct,
- layered route solving preserves global route choices and training,
- route cost evaluations stay bounded,
- identical profession state reuses the completed recommendation without invoking the solver again,
- TSM scan revision is exposed to the cache key,
- prerequisite state remains lazy and cached on first use,
- repeated skill-point evaluations of the same recipe do not repeat material price lookups,
- cached material economics still produce the correct yellow/green expected-cost scaling.

## Acceptance criteria

- Lua 5.1 syntax and the complete repository validation workflow pass.
- Generated route topology is deterministic and checked by CI.
- Dynamic mode does not scan every recipe's live reagents when a profession window opens.
- Runtime catalog work is restricted to relevant candidate recipes.
- The adaptive route uses the layered solver.
- Material price calculations are reused across simulated skill points.
- Reopening an unchanged profession can reuse the completed recommendation instead of recalculating the route.
- Static fallback behavior remains unchanged.
- In the WoW 3.3.5 client, repeatedly opening/closing Enchanting no longer causes the severe hitch/freeze reported before this task.

## Manual acceptance

In game, test Enchanting at the same character state that previously produced the severe open/close lag.

1. Open and close Enchanting repeatedly in Cheapest mode.
2. Switch Cheapest -> Available -> Static -> Cheapest.
3. Move an applicable reagent between inventory states and confirm the recommendation refreshes.
4. Learn a recipe and confirm the route refreshes.
5. Perform/update a TSM scan and confirm subsequent pricing uses the updated data.
6. Confirm the recommendation, acquisition-first UI and Compare/Full route views remain correct.

Manual in-game latency and transition verification remains pending before marking DONE.
