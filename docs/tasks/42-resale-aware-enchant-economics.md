# Task 42 — Resale-aware Enchanting craft economics

Status: BLOCKED  
Phase: 9 — Resale-aware Smartest optimization  
Depends on: Tasks 40 and 41

## Goal

Teach the recipe-cost layer to evaluate both ways of performing a vellum-compatible enchant:

- direct enchant on an item;
- enchant onto the cheapest compatible vellum and create a sellable scroll.

Do not change the route objective in this task.

## Core economics

For a vellum-compatible enchant, calculate both paths.

### Direct

`directGrossCost = enchanting material cost`

There is no resale credit.

### Scroll

`scrollGrossCost = enchanting material cost + chosen vellum cost`

`resaleEstimate = conservative resale estimate from Task 41`

`resaleCredit = min(scrollGrossCost, resaleEstimate)`

`effectiveLevelingCost = scrollGrossCost - resaleCredit`

`estimatedSurplus = max(0, resaleEstimate - scrollGrossCost)`

The route-relevant effective cost must never become negative.

Profit/surplus remains separate informational data.

## Cheapest compatible vellum

Use Task 40 compatibility metadata.

For each eligible enchant:

- enumerate only compatible vellum ranks;
- use the existing price provider and purchase/market choice semantics;
- choose the cheapest valid vellum for the relevant cost purpose;
- allow a higher-rank vellum to win when it is genuinely cheaper and compatible.

Do not hardcode "always use Vellum III".

## Important scope rules

Resale credit may offset only the variable scroll-craft economics:

- enchanting materials;
- vellum.

It must not offset:

- recipe acquisition cost;
- profession-rank training;
- reusable rods/tools;
- unrelated one-time route costs.

Do not use recipe color as a proxy for skill-up chance. Preserve the exact current skill-up probability from `RecipeCost.lua`.

## Result model

Extend recipe cost output with explicit fields sufficient for later optimizer/UI work, such as:

- selected execution method: direct or scroll;
- direct gross cost;
- scroll gross cost;
- vellum item ID and cost;
- scroll output item ID;
- resale estimate;
- resale credit;
- estimated surplus;
- effective cost per craft;
- expected effective cost per skill-up;
- resale confidence/reason.

Keep existing Cheapest fields unchanged.

## Caching and performance

Integrate this into the existing per-recipe material economics reuse from Task 30.

Do not introduce a new persistent craft-economics cache unless `/pcapper perf` demonstrates a need.

Expected added runtime work for a relevant enchant should be bounded to cached price lookups for:

- one scroll item;
- the small compatible vellum set.

The six vellum item IDs should naturally become hot price-cache hits.

## Tests

Required cases include:

- direct path is better because the scroll is low value;
- scroll path is better because resale recovers cost;
- resale estimate exceeds gross cost, but effective route cost floors at zero;
- surplus is still reported separately;
- higher-rank vellum is chosen because it is cheaper;
- missing/suspicious/stale scroll data gives no route credit;
- no compatible vellum falls back to direct economics;
- ring/personal/non-vellum craft cannot enter scroll economics;
- exact skill-up probability changes expected cost correctly;
- recipe acquisition/training/tool costs are not erased by resale credit;
- material-economics cache reuse avoids repeated price work across simulated skill points.

Use Gatherer and Exceptional Spellpower as regression fixtures where the generated data permits.

## Required handoff workflow

### Agent 1 — implement

Implement Task 42 only. Run all recipe-cost, price, metadata and full validation tests. Record evidence, commit/push, and move to `REVIEW`. Do not start Task 43.

### Agent 2 — independent review

Review formulas, floor-at-zero behavior, vellum selection, exact skill-up probability, one-time-cost separation, cache ownership and tests.

Clean review: mark `DONE`.

Findings: record them, mark `FIX`, hand off to Agent 3.

### Agent 3 — fix findings only

Fix recorded findings, rerun all relevant validation, record evidence, mark `DONE`, then Task 43 may begin.

## Acceptance criteria

- Direct and scroll execution economics are both modeled.
- Cheapest compatible vellum selection is deterministic.
- Effective route cost can reach zero but never go negative.
- Estimated surplus is tracked separately.
- Resale does not offset acquisition/training/tool costs.
- Exact skill-up chance remains authoritative.
- Existing caches are reused and runtime work remains bounded.
- Full repository validation passes.
- Review/fix gate is complete.

## Evidence

### Agent 1 implementation

Pending.

### Agent 2 review

Pending.

### Agent 3 fixes

Pending.
