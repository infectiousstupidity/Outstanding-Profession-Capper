# Task 10 — Dynamic recommendation UI

Status: QUEUED  
Phase: 4 — User-facing integration  
Depends on: Tasks 03, 06, 08, 09

## Goal

Expose the dynamic optimizer without turning the profession panel into a dense dashboard.

## Modes

Support:

- `Cheapest now` — dynamic route using current character state and available prices.
- `Static guide` — deterministic existing Profession Capper route.

Dynamic mode must fall back gracefully when data is insufficient.

## Main recommendation

Show only the highest-value information at a glance:

- recommended recipe
- current skill -> target
- expected crafts
- expected cost for the current segment
- why it is preferred when useful
- price source and scan age
- active +profession modifier when relevant

## Total-to-cap summary

Expose compact totals such as:

- estimated cost to cap
- gold needed now
- expected total crafts
- TSM scan age
- number of missing/unpriced items
- active profession bonus included

Do not imply false precision.

## Acquisition guidance

For recipes/training not yet available, show actionable source information:

- trainer/vendor name
- zone/coordinates where known
- vendor/AH/reputation/drop type
- purchase/acquisition cost where known
- limited-stock/reputation caveats

## Materials

Build on the existing interactive material rows.

Add per-material pricing where available without making rows excessively wide:

- owned / needed
- selected unit price
- estimated remaining purchase cost
- tooltip with detailed price-source information

## Route inspection

Provide a compact way to inspect the rest of the optimized route without cluttering the default view.

The default panel should still answer "what should I do next?" first.

## Acceptance criteria

- Dynamic and static modes are understandable and switchable.
- Blood Elf/+gear profession bonuses are visible when they affect calculations.
- Total cost is clearly labelled as estimated.
- Stale/missing TSM data is visibly distinguished.
- Recipe acquisition guidance is actionable.
- ElvUI does not break layout or interaction.
- Manual tests cover at least Enchanting with an active skill modifier and one other profession.

## Commit

Suggested message: `feat: expose dynamic profession route recommendations`
