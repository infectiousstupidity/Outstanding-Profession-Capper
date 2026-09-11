# Task 09 — Total cost and shopping plan

Status: QUEUED  
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

## Acceptance criteria

- Total route cost equals the sum of route segments under the same cost semantics.
- Owned materials reduce gold-needed-now but not market-value route cost.
- Aggregated shopping quantities are internally consistent with route crafts.
- Missing prices are surfaced clearly.
- Performance is acceptable on 3.3.5 Lua.

## Commit

Suggested message: `feat: add profession route total cost and shopping plan`
