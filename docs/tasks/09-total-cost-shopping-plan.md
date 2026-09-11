# Task 09 — Total cost and shopping plan

Status: DONE  
Phase: 3 — Cost engine and optimizer  
Depends on: Task 08

## Goal

Turn the optimized route into a useful "from here to cap" cost estimate and material plan.

## Required totals

Expose at least:

- estimated market-value cost from current skill to cap
- estimated gold needed now
- recipe/training acquisition cost
- total expected crafts
- per-segment cost
- price-source freshness
- count/value of missing or unpriced materials

## Material aggregation

Aggregate reagents across the entire route.

For every material show:

- total expected quantity
- quantity currently owned
- quantity still needed
- chosen unit-price source
- estimated purchase cost

Avoid double-counting reusable rods/tools and route intermediates.

## Price depth caveat

TSM minimum buyout is not a full order-book/depth quote.

The UI/data model must label total AH cost as an estimate and preserve scan age/confidence.

## Route refresh

Recompute totals when materially relevant state changes:

- profession skill
- profession modifier/equipment
- inventory
- recipe knowledge
- selected price source / scan data

Avoid excessive recomputation on irrelevant events.

## Implementation notes

Implemented on 2026-09-11:

- Added `ShoppingPlan.lua` to turn a complete optimized route into route totals and a whole-route material plan.
- Rebuilds cost segments from route actions, including profession-rank training, so the market-value route total uses the same cost semantics as the sum of its segments.
- Aggregates reagents across every expected craft in the route.
- Subtracts route-produced intermediate items from later external requirements.
- Counts reusable tools/rods once across the route and respects reusable state already owned/acquired.
- Applies character inventory once globally after aggregation. Owned materials reduce gold-needed-now while leaving the optimizer's market-value route cost unchanged.
- Re-prices the final net shopping list through the neutral price-provider API and explicitly chooses the cheaper usable vendor/Auction House purchase source.
- Exposes source, price type, freshness, scan age, stale/suspicious counts, and missing-price quantity/value information per plan.
- Marks Auction House totals as estimates and explicitly records that market depth is unknown; minimum buyout is not treated as proof that the full quantity is available at that price.
- Added a route-refresh fingerprint based only on profession skill/modifier/cap, inventory, recipe knowledge, reusable state, price/provider revision, recipe revision, and acquisition revision. Unrelated state does not trigger recomputation.
- Missing procurement prices make the shopping plan incomplete and leave gold-needed-now unavailable rather than silently assuming zero.

This completes the Phase 3 engine layer. Production dynamic recommendations remain disabled until Tasks 04/05 provide verified recipe difficulty/acquisition metadata and Task 10 deliberately wires the engine into the UI.

## Automated validation

`tools/test_shopping_plan.lua` covers:

- route market total equals the sum of rebuilt cost segments
- expected craft and acquisition totals
- repeated materials aggregated across route steps
- owned inventory subtracted once globally
- vendor beating a more expensive Auction House price
- route-produced intermediates offsetting later purchases
- reusable tools counted once across the route
- stale price/scan-age reporting
- missing prices producing an incomplete result with no fake zero cash total
- refresh keys changing for inventory/+skill changes but not irrelevant state

## Manual checks

Task 09 adds no user-facing dynamic recommendation yet. The deterministic static guide remains unchanged, so there is no independent in-game Phase 3 UI behavior to validate before Task 10.

## Acceptance criteria

- PASS — total route cost equals the sum of route segments under the same cost semantics.
- PASS — owned materials reduce gold-needed-now but not market-value route cost.
- PASS — aggregated shopping quantities are internally consistent with route crafts, route outputs, and reusable items.
- PASS — missing prices are surfaced clearly and never converted to zero.
- PASS — aggregation is linear in route actions/materials, refreshes are relevance-keyed, and the implementation stays within Lua 5.1-compatible constructs.

## Commit

Suggested message: `feat: add profession route total cost and shopping plan`
