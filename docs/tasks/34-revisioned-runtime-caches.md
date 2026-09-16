# Task 34 — Revisioned runtime caches and immutable optimizer inputs

Status: IN PROGRESS — code implemented; Task 32 baseline and in-game acceptance pending  
Phase: 7 — Runtime performance hardening  
Depends on: Tasks 32 and 33

## Goal

Replace blanket cache destruction and repeated immutable-object construction with explicit, dependency-aware runtime caches.

This task must improve reuse without allowing stale recommendations.

## Correctness constraint

The current recommendation cache does not include inventory in its key. Correctness is currently preserved in part because `BAG_UPDATE` clears the entire recommendation cache.

Therefore, simply stopping that invalidation is unsafe.

Before reducing invalidation, introduce explicit revisions/generations for the state a result depends on.

## Required revision model

Introduce lightweight generation values or equivalent explicit revisions for at least:

- profession/recipe-book state;
- base skill / trained cap / active modifier;
- inventory state;
- price-provider identity + provider revision;
- acquisition/character eligibility state where it can change;
- recommendation mode / target inputs.

Do not serialize large inventory maps or recipe tables into cache keys just to detect change.

A cached artifact must declare, directly or through its key, which revisions it depends on.

## Cache layers

Implement clear cache ownership for these layers.

### 1. Canonical static recipe structures

Build reusable optimizer recipe/catalog structures from bundled data without recreating reagent/output tables on every recommendation.

Treat canonical structures as immutable. Runtime fields must live separately rather than mutating shared catalog objects.

### 2. Profession-book overlay

Reuse the Task 33 learned/live recipe snapshot and overlay it on canonical recipes by spell ID.

### 3. Price cache

Persist normalized item-price results across recommendation calculations.

The key must include:

- active provider identity;
- provider revision when available;
- item ID/item string.

If the provider cannot expose a revision, use a conservative bounded TTL. Do not assume undocumented TSM events exist.

Cache negative/missing-price results too when safe, otherwise repeated missing items can remain an expensive hot path.

### 4. Runtime inventory state

Inventory counts may be cached within a generation. `BAG_UPDATE` increments inventory generation and invalidates only artifacts that actually depend on inventory.

### 5. Recommendation and shopping-plan results

A recommendation result must not be reused if any dependency that affects its current semantics changed.

At this phase, preserve the current behavior where inventory can affect Cheapest route economics. That means an inventory revision may still invalidate the optimized route. The point of this task is to make that dependency explicit, not silently remove it.

## Price provider considerations

The current TSM provider can derive a revision from realm scan metadata such as `lastScan`, `scanTime`, etc.

Do not repeatedly call expensive TSM APIs just to discover the same item values if the provider revision is unchanged.

Keep all public/provider calls protected as required by the existing abstraction.

## Memory bounds

Caches must have an explicit bounded lifetime or bounded size where unbounded cardinality is possible.

Avoid recreating the previous allocator problem in a different form.

Document:

- key cardinality;
- invalidation/lifetime;
- maximum retained entries where applicable.

## Tests

Required deterministic coverage:

- unchanged provider revision + same item reuses a normalized price lookup;
- provider revision change invalidates/rekeys price results;
- inventory generation change cannot reuse an inventory-dependent recommendation;
- bag changes do not destroy static recipe structures or provider-revision price data;
- learned-recipe generation change invalidates affected optimizer input;
- modifier/skill generation changes do not leak stale difficulty/current-skill data;
- canonical recipe structures are not mutated by one recommendation pass;
- negative price results obey the same safe revision/TTL rules;
- cache growth remains bounded under repeated synthetic state changes.

Keep existing route-result equivalence tests and expand them to compare uncached vs cached results.

## Manual acceptance

Using Task 32 perf output:

1. Open an unchanged profession repeatedly and confirm warm opens reuse static/price structures.
2. Trigger a bag change and confirm prices/static recipe structures remain reusable while inventory-dependent outputs refresh.
3. Perform/update a TSM scan and confirm a new provider revision produces new price-derived results.
4. Learn a recipe and confirm optimizer inputs refresh without requiring unrelated price cache destruction.

## Acceptance criteria

- Full repository validation passes.
- Cache dependencies are explicit and documented.
- Blanket `recommendationCache = {}` invalidation is removed or reduced to cases where it is genuinely correct.
- Static optimizer structures are reused rather than rebuilt each recommendation.
- Price lookups persist safely across recommendation calls.
- No stale recommendation can publish after an input revision changes.
- Memory remains bounded.
- Task 32 instrumentation shows fewer repeated allocations/lookups on warm opens and volatile inventory refreshes.

## Non-goals

Do not change the optimization objective. In particular, do not remove inventory from Cheapest route costing in this task. That is a separate product/semantics decision and must not be smuggled into a performance refactor.


## Implementation status

The runtime now uses explicit generations for profession-book, skill/context, inventory, character eligibility, and recommendation mode. The recommendation key also contains provider identity/revision, target inputs, availability mode, optimization objective, and acquisition-data revision.

Task 33's profession-book snapshot remains the learned/live overlay. Bundled catalog recipes are converted lazily to canonical immutable optimizer structures and static/unknown recipes reuse those structures across passes. Inventory counts are cached only within the current inventory generation.

`PriceProvider.lua` now owns a bounded 512-entry raw-result cache keyed by provider identity, provider revision, and item identity. Negative lookups are cached. Providers without revisions use a 15-second TTL. Normalized freshness/age is recalculated on every read.

The recommendation/shopping-plan result cache is bounded to 8 entries and a 15-second TTL. It depends explicitly on all runtime generations that affect semantics. A generation/provider change detected during a calculation rejects the result instead of publishing it.

`BAG_UPDATE` no longer clears the entire recommendation/price/static-recipe cache. It advances the inventory generation only. Learned spells, level changes, reputation changes, skill/modifier changes, and mode changes advance their corresponding generations.

Deterministic tests cover revisioned positive/negative price reuse, provider revision changes, unknown-revision TTL expiry, inventory-generation invalidation, preservation of price/static structures across bag changes, profession-book/skill/eligibility invalidation, canonical recipe reuse/non-mutation, stale-result rejection, and cache-size bounds.

The code remains IN PROGRESS until the Task 32 real-client measurements and this task's manual warm-open/bag/TSM-scan/learned-recipe checks are captured.
