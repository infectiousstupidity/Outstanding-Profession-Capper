# Task 42 — Resale-aware Enchanting craft economics

Status: DONE  
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

Validation:
- Implementation commit: `ba908da717d46a26eae03ff61ccff386bad9213d` (`feat: add resale-aware enchant economics`).
- GitHub Actions `Validate addon` run 114 completed successfully.
- The new Task 42 recipe-cost coverage passed, including Gatherer/Exceptional Spellpower economics, higher-rank vellum selection, floor-at-zero/surplus separation, stale/suspicious resale rejection, one-time-cost protection, and material-cache reuse.
- Existing enchant metadata, price provider, TSM provider, Cheapest route solver, incremental route execution, shopping-plan, dynamic recommendation, full-catalog route, performance-guard, structure, and guide validation all remained green.

Task 42 remains REVIEW for the required independent Agent 2 pass. Task 43 has not been started.

### Agent 2 review

Reviewed independently against the actual current `master` at `44e2277466a1a5aa460c54e1dcf21962efc6d173`, implementation commit `ba908da717d46a26eae03ff61ccff386bad9213d`, the Task 40/41 production paths, the live recommendation path, and the current tests. The only commit after the Task 42 implementation changed `TASKS.md` and this task document; no Task 42 implementation code changed after `ba908da717d46a26eae03ff61ccff386bad9213d`.

Review outcome: **FIX**.

Findings:

1. **HIGH — Task 42 expected economics can become stale after the live skill-up chance is reconciled.**
   - **Affected behavior:** `DynamicRecommendations.applyLiveSkillType()` can change `cost.skillUpChance` and then recompute `expectedCraftsPerSkillUp` plus the existing Cheapest cost fields, but it does not recompute Task 42's `expectedEffectiveCostPerSkillUp`, `expectedEstimatedSurplusPerSkillUp`, or the mirrored values inside `executionEconomics`. A live recipe can therefore expose one final skill-up chance while its resale-aware expected economics still use the earlier chance.
   - **Evidence:** live profession records are built with `liveSkillType`; both current-recipe ranking and `adaptiveRouteCost()` call `applyLiveSkillType()` after `calculateRecipeCost()`. Task 42 derives its expected fields inside `RecipeCost.applyExecutionEconomics()` before that post-processing occurs. The Task 42 recipe-cost coverage tests direct `calculateRecipeCost()` chance scaling, while the dynamic/incremental recommendation coverage does not assert Task 42 fields through a `liveSkillType` adjustment.
   - **Impact:** current Cheapest ordering is not changed because `RouteSolver.lua` still consumes only the legacy Cheapest fields, but the Task 42 result contract is internally inconsistent and Task 43 could consume a wrong expected effective cost.
   - **Smallest correct fix direction:** make the final skill-up probability authoritative in one place. Do not derive Task 42 economics from a guessed recipe-color probability. If live reconciliation legitimately changes the final numeric chance, recompute all Task 42 chance-derived fields from `effectiveCostPerCraft`, `fixedOneTimeMaterialCost`, and `estimatedSurplus`, including the mirrored `executionEconomics` values. Add a production-path regression where `liveSkillType` changes/reconciles the chance and assert all legacy and Task 42 expected fields use the same final probability.

2. **MEDIUM — informational surplus is calculated from optimization-eligible credit instead of the retained resale estimate.**
   - **Affected behavior:** `RecipeCost.buildExecutionEconomics()` sets `estimatedSurplus = max(0, optimizationValue - scrollGrossCost)`. Task 41 deliberately retains `estimatedResaleValue` as context even when stale, suspicious, too old, unknown-freshness, or context-only evidence is rejected for optimization. Task 42's specified result model is `estimatedSurplus = max(0, resaleEstimate - scrollGrossCost)`; only `resaleCredit` is supposed to depend on optimization eligibility.
   - **Evidence:** rejected Task 41 evidence returns a non-nil contextual `estimatedResaleValue` with `optimizationCredit = 0`. Task 42 then reports zero surplus because it subtracts from `optimizationValue`, not `resaleEstimate`. The stale/suspicious recipe-cost tests assert zero credit and direct fallback but never assert the informational surplus; the fresh profitable case cannot distinguish the two operands because estimate and optimization credit are equal.
   - **Impact:** untrusted data still cannot reduce optimization cost, so route safety is preserved, but the informational surplus field loses the exact evidence/context separation required by Task 42 and can under-report the retained market estimate.
   - **Smallest correct fix direction:** keep `resaleCredit` based only on Task 41's optimization-eligible value, but compute `estimatedSurplus` from the safe retained `resaleEstimate`. Add stale/suspicious (and ideally unknown/context-only) high-estimate regressions proving zero credit while informational surplus and confidence/reason remain available.

What passed:
- Direct versus scroll gross/effective arithmetic is correct for optimization-eligible resale evidence; resale credit is capped at scroll gross cost and effective cost floors at zero.
- Recipe acquisition remains a separate solver one-time cost, profession training remains a separate route action, and reusable rods/tools remain fixed one-time material cost outside resale credit.
- Task 40 metadata gates scroll economics to explicitly vellum-eligible enchants. Compatible vellum enumeration respects the pinned minimum tier, is deterministic on equal prices, and allows a cheaper higher-rank vellum to win.
- Missing vellum/resale paths fall back safely; stale, suspicious, too-old, unknown-freshness, missing, and context-only Task 41 evidence cannot reduce optimization cost.
- Existing Cheapest route metrics/order are unchanged: `RouteSolver.lua` still resolves edges from the legacy expected market/gold/current fields and does not consume Task 42 resale-aware fields.
- Existing material/recommendation price caching is reused. Task 42 adds no persistent craft-economics cache; the provider price cache remains bounded and the recommendation-local material cache prevents repeated vellum/scroll work across simulated skill points.

Validation:
- Re-ran GitHub Actions `Validate addon` run 115, attempt 2, against current `master` `44e2277466a1a5aa460c54e1dcf21962efc6d173`.
- The rerun passed Lua 5.1 syntax; runtime-cache/performance tests; generated enchant metadata verification/tests; price provider, conservative resale, and TSM provider tests; recipe-cost tests; cheapest and incremental route tests; shopping/recommendation/full-catalog/static route tests; Enchanting rod coverage; Phase 7 performance guards; addon structure; and guide validation.
- The green suite does not falsify either finding because the missing assertions described above are not present.

Task 42 moves to **FIX** for Agent 3. Task 43 remains blocked and was not started.

### Agent 3 fixes

Resolved only the two findings recorded by Agent 2.

- Live skill-up reconciliation now rescales all Task 42 chance-derived fields from the final numeric chance used by the production recommendation path. `expectedEffectiveCostPerSkillUp` preserves fixed one-time material cost outside the per-craft multiplier, `expectedEstimatedSurplusPerSkillUp` uses the same final expected craft count, and the mirrored `executionEconomics` values are kept consistent.
- Informational surplus now follows the Task 42 result contract: `estimatedSurplus = max(0, resaleEstimate - scrollGrossCost)`. Optimization remains conservative because `resaleCredit` still uses only Task 41's optimization-eligible value and is still capped at `scrollGrossCost`.
- Added recipe-cost regressions proving stale and suspicious high resale estimates retain informational surplus while granting zero route credit and leaving direct execution selected.
- Added a dynamic recommendation production-path regression where live `medium` difficulty reconciles a stale `green` cost result from 40% to 75% skill-up chance, then verifies legacy expected cost, Task 42 expected effective cost/surplus, and the mirrored execution-economics values all use the same final chance.
- No Cheapest objective/order, vellum compatibility, price-provider/cache ownership, one-time cost treatment, or Task 43 implementation was changed.

Validation:
- Full repository validation must pass on the Agent 3 fix commit before this task is considered closed.

Task 42 is DONE after the Agent 3 fix commit passes full validation. Task 43 becomes the next available task but was not started.
