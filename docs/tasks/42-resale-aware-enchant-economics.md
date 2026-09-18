# Task 42 — Resale-aware Enchanting craft economics

Status: REVIEW  
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

Implemented Task 42 without changing the existing Cheapest route fields or route solver objective.

Implementation:
- Added additive Enchanting execution economics to `RecipeCost.lua`. Existing `expectedMarketCostPerSkillUp`, `expectedGoldNeededNowPerSkillUp`, and `expectedCurrentPurchaseCostPerSkillUp` remain unchanged.
- Direct economics use only variable enchanting-material market cost. Reusable rods/tools remain fixed one-time material cost and are added after resale adjustment when computing expected effective cost.
- Eligible enchants use Task 40 numeric metadata to enumerate only compatible vellums at or above the pinned minimum tier. The cheapest compatible vellum is chosen deterministically by existing market-price semantics; equal prices prefer the lower tier.
- Scroll resale uses the same pass-local/revisioned `priceLookup` supplied to recipe costing, then Task 41's `evaluateResaleValue`. Only Task 41 optimization-eligible value can reduce cost.
- `resaleCredit = min(scrollGrossCost, optimizationEligibleResaleValue)`; scroll effective cost is floored at zero. Trusted surplus above gross cost is retained separately and never creates a negative route edge.
- Added result fields for selected execution method, direct/scroll gross cost, scroll effective cost, chosen vellum, scroll output, resale estimate/credit/confidence/reason, surplus, fixed one-time material cost, effective cost per craft, expected effective cost per skill-up, and expected surplus per skill-up.
- Recipe acquisition remains in existing `oneTimeCosts`; profession-rank training remains owned by the route solver and is untouched by Task 42.
- Execution economics are stored inside the existing per-recipe `materialCostCache`, so repeated simulated skill points reuse reagent, vellum, and scroll price work. No persistent craft-economics cache was added.

Coverage:
- Gatherer low-value direct path and resale-aware scroll path.
- Exceptional Spellpower floor-at-zero plus separate surplus.
- Higher-rank compatible vellum winning because it is cheaper.
- Stale/suspicious scroll data granting zero route credit.
- Missing vellum fallback.
- Personal/ring and non-vellum craft exclusion.
- Exact yellow skill-up probability scaling.
- Recipe acquisition and reusable-tool costs surviving resale credit.
- Material-cache reuse across skill points without repeated scroll/vellum lookups.

Validation: pending the implementation commit's full GitHub Actions `Validate addon` run. Task remains REVIEW for the required independent Agent 2 pass; Task 43 is not started.

### Agent 2 review

Pending.

### Agent 3 fixes

Pending.
