# Task 10 — Dynamic recommendation UI

Status: IN PROGRESS  
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

## Implementation

Implemented on `master`:

- `Cheapest now` and `Static guide` modes with the selected mode persisted.
- Current-step comparison uses WoW's live recipe difficulty and only lets game-reported orange/yellow recipes compete for `Cheapest now`.
- Candidates are ranked by current purchasable material cost per expected skill-up, with per-application cost shown separately.
- A current cheapest recommendation remains available even when missing future data prevents a complete priced route; static fallback is reserved for cases where the current step itself cannot be priced safely.
- Compact current-segment cost/craft information plus estimated total-to-rank-cap/cap cost, gold needed now, total crafts, price source, scan age, and stale/missing indicators.
- Per-material remaining purchase estimates and price-source tooltips, including Greater/Lesser enchanting essence equivalence when one form is cheaper after conversion.
- Actionable trainer/vendor/AH/reputation/drop acquisition text for unlearned static-guide recipes when metadata is available.
- Hoverable route inspection without expanding the default panel into a dashboard.
- Active +profession modifiers remain visible in the profession header and are passed into the optimizer.
- Focused automated tests cover live difficulty overriding stale static color, orange/yellow-only candidate comparison, incomplete full-route handling, reusable Enchanting rods, current-price route optimization, Greater/Lesser essence conversion, and per-application material cost.

## Manual acceptance checks still required

The repository rules require these in-game checks before this task can be marked `DONE`:

- Enchanting with an active +profession modifier: confirm displayed skill/target, route choice, pricing, materials, and fallback behavior.
- One other profession: confirm dynamic/static switching, route/material layout, and crafting interaction.
- ElvUI enabled: confirm the panel, mode buttons, route tooltip, material rows, and click/hover behavior remain usable.
- TSM data states: confirm current, stale, missing, and no-provider states are visibly distinct.
- Unlearned recipe: confirm available acquisition metadata produces useful trainer/vendor/AH/reputation/drop guidance.

## Commit

Suggested message: `feat: expose dynamic profession route recommendations`
