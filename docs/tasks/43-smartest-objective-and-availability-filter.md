# Task 43 — Smartest objective and availability filter

Status: FIX  
Phase: 9 — Resale-aware Smartest optimization  
Depends on: Tasks 39 and 42

## Goal

Add Smartest as a deterministic optimization objective while turning Available-now into an orthogonal constraint instead of a competing objective.

The conceptual model becomes:

- Static fallback/path;
- Cheapest objective;
- Smartest objective;
- Available-now filter that can constrain Cheapest or Smartest.

## Preserve Cheapest

Cheapest must retain its current semantics and regression results.

Smartest is an additional objective. Do not silently change Cheapest to use resale credit.

## Smartest route ordering

Smartest must use deterministic lexicographic route ordering rather than an arbitrary weighted score.

Primary objective:

1. lowest total expected effective leveling cost;

Tie-breakers, in order:

2. fewer total expected crafts / higher aggregate leveling efficiency;
3. greater total estimated resale surplus;
4. stable deterministic recipe/route ID ordering if still tied.

The first objective must remain non-negative because Task 42 floors per-craft resale-adjusted leveling cost at zero.

Do not reward low skill-up chance merely because it produces more profitable scrolls.

## Solver implementation

Task 39 should have consolidated route transition logic before this task begins.

Implement Smartest through the shared route engine, not by cloning the solver.

Route state/results must carry enough aggregate fields for lexicographic comparison, including:

- effective leveling cost;
- expected craft count;
- estimated resale surplus.

All synchronous/incremental/test entry points must use the same comparison semantics.

## Available-now constraint

Separate objective from feasibility.

Represent availability as an explicit boolean/constraint, for example:

- objective: `cheapest | smartest`;
- `availableOnly: true | false`;
- Static remains separate.

When `availableOnly` is true, preserve the existing Available evidence rules for required purchases and extend them to the selected vellum path.

Do not define a fourth independent "Available optimizer" with ambiguous ranking semantics.

## Settings migration

The current settings use `dynamic | available | static`.

Provide a deterministic saved-setting migration:

- old `dynamic` -> Cheapest, availableOnly false;
- old `available` -> Cheapest, availableOnly true;
- old `static` -> Static.

Do not destroy unrelated saved settings.

The UI change itself belongs to Task 44, but the internal model and migration belong here.

## Negative-edge guard

Add explicit tests/guards proving no Smartest route edge is negative.

The legacy negative-edge risk must not return through one-time costs, resale credit, or aggregation.

## Tests

Cover:

- existing Cheapest fixtures unchanged;
- existing Available behavior unchanged when mapped to Cheapest + availableOnly;
- Smartest chooses a higher gross-cost enchant when resale reduces effective leveling cost;
- Smartest does not prefer a low-chance recipe solely to farm more profitable failures;
- zero-effective-cost tie prefers fewer expected crafts before surplus;
- surplus breaks a tie only after cost and expected crafts;
- deterministic final tie;
- availability rejects a Smartest scroll path when the vellum or another required purchase is not currently available;
- Static remains independent;
- saved-setting migration;
- synchronous/incremental equivalence;
- stale job cancellation still works with the new objective/filter inputs;
- recommendation cache keys include objective and availability constraint.

## Required handoff workflow

### Agent 1 — implement

Implement Task 43 only. Preserve Cheapest baselines, add Smartest/filter tests, run full validation, record evidence, commit/push, set `REVIEW`. Do not start Task 44.

### Agent 2 — independent review

Review route mathematics, tie-break ordering, migration, availability semantics, cache/job generations, Cheapest non-regression and all solver entry points.

If clean, mark `DONE`.

If findings exist, record each one, mark `FIX`, hand off to Agent 3.

### Agent 3 — fix findings only

Fix only the recorded findings, rerun the full route/regression suite, record evidence, mark `DONE`, then Task 44 may begin.

## Acceptance criteria

- Smartest is a separate deterministic objective.
- Available-now is an orthogonal filter/constraint.
- Cheapest output remains unchanged for the regression corpus.
- Smartest route edges cannot be negative.
- Low skill-up chance cannot win merely by creating more profitable crafts.
- Tie-break rules are lexicographic and tested.
- Settings migrate safely.
- Cache keys and incremental-job generations include the new inputs.
- Full validation passes.
- Review/fix gate is complete.

## Evidence

### Agent 1 implementation

Implemented on current `master` as Task 43 only.

- Added `objective = cheapest | smartest` and orthogonal `availableOnly` inputs while retaining `requireAvailableNow` as a compatibility alias.
- Extended the shared layered route engine instead of cloning it. Smartest compares routes lexicographically by total expected effective leveling cost, then expected crafts, then selected-scroll estimated surplus, then stable route/recipe ID order.
- Smartest aggregates recipe acquisition/training costs outside resale credit and rejects any negative Smartest edge explicitly.
- Existing Cheapest metric selection remains unchanged.
- Current-recipe fallback ranking uses the same Smartest tie-break order when Smartest is requested.
- Recommendation cache keys and incremental generation tokens now include objective and availability. A newer request with different objective/filter inputs invalidates the older pending job.
- Availability remains a feasibility constraint and now includes the selected vellum when scroll execution wins. Vellum resale economics do not bypass fresh purchase evidence.
- Added deterministic settings migration from legacy `dynamic | available | static` into `optimized/static + recommendationObjective + recommendationAvailableOnly`, preserving unrelated settings. Existing UI projection remains temporarily compatible; Task 44 owns the visible UI redesign.
- Added regressions for Smartest vs Cheapest, efficiency-before-surplus, surplus tie-breaks, deterministic final ties, negative-edge rejection, vellum availability, saved-setting migration, synchronous/incremental equivalence, objective-driven stale cancellation, and cache separation.

Validation:
- Agent 1 implementation commit: `3e0adcebd14f4e45827b4757b8f47df1a9eb0047` (`feat: add Smartest route objective`).
- GitHub Actions `Validate addon` run 119 completed successfully on that commit.
- Validation passed Lua 5.1 syntax; recommendation-setting migration; recipe cost and conservative resale; Cheapest and Smartest route tests; synchronous/incremental route equivalence; dynamic/incremental recommendations; full-catalog routes; shopping plan; cache/performance guards; addon structure; and profession guides.

Task 43 remains REVIEW for the required independent Agent 2 pass. Task 44 remains blocked.

### Agent 2 review

Verdict: **FIX**.

Reviewed the actual current `master` at bookkeeping commit `4fe725f544241e0019249253922ee1f4fb6a9380`; its parent is exactly Task 43 implementation commit `3e0adcebd14f4e45827b4757b8f47df1a9eb0047`. There are no later code changes in the review boundary.

Baseline validation:
- Independently verified GitHub Actions `Validate addon` run 119 on the implementation commit and run 120 on the bookkeeping commit. Both completed successfully.
- Those runs execute Lua 5.1 syntax validation, settings migration, recipe-cost and conservative-resale tests, route and incremental-route tests, shopping-plan tests, dynamic and incremental recommendation tests, full-catalog route tests, runtime/cache/performance guards, addon structure validation, and profession-guide validation.
- The review adds `tools/test_task43_review.lua` as a final CI step after the complete baseline suite so adversarial failures do not hide baseline regressions.

#### Finding 1 — HIGH — Available-only changes Cheapest fallback economics instead of only filtering feasibility

Evidence:
- `DynamicRecommendations.lua:1028-1034` changes Cheapest fallback ranking to `expectedGoldNeededNowPerSkillUp` / `goldNeededNowPerCraft` whenever `availableOnly` is enabled.
- Unrestricted Cheapest at `DynamicRecommendations.lua:1035-1039` ranks by `expectedCurrentPurchaseCostPerSkillUp` / current purchase cost.
- `firstRankedCandidate()` at `DynamicRecommendations.lua:1101-1108` already has the correct independent feasibility mechanism: it can skip candidates whose `availableNow` is false after ranking.
- The adversarial review fixture uses two recipes that are both confirmed available. Recipe A is cheaper by the normal Cheapest score but has a more expensive confirmed-now purchase path; Recipe B is more expensive by the normal Cheapest score but cheaper by the availability-specific gold field. Current code flips the selected fallback recipe only because the filter is enabled.

Impact:
- `availableOnly = true` is not orthogonal in the current-recipe fallback. It can change the economic ordering among recipes that are all feasible.
- When the full route is incomplete and the fallback is published, Available-only can disagree with the Cheapest objective and with the authoritative route scorer.

Smallest reasonable fix direction:
- Keep the exact same Cheapest score fields regardless of `availableOnly`.
- Apply `availableNow` only as a feasibility filter. Do not substitute availability-specific gold fields into the objective.

#### Finding 2 — HIGH — Smartest current-recipe fallback omits recipe acquisition cost and can disagree with the authoritative solver

Evidence:
- Smartest fallback ranking at `DynamicRecommendations.lua:1025-1027` compares only `cost.expectedEffectiveCostPerSkillUp`; it does not add unapplied recipe-acquisition one-time cost.
- The authoritative solver explicitly adds recipe-acquisition market cost through `applyCostOneTime()` and includes it in the Smartest edge metric at `RouteSolver.lua:810-827`.
- The adversarial fixture has Recipe A with zero craft effective cost but a 1000-cost recipe acquisition and Recipe B with 100 effective cost and no acquisition. The one-step authoritative Smartest route correctly prefers B; when a later skill makes the full route incomplete, the current fallback incorrectly prefers A.

Impact:
- The published fallback can contradict the authoritative Smartest route ordering.
- A large recipe acquisition can effectively disappear from Smartest fallback ranking, violating the requirement that resale-aware leveling economics cannot erase or bypass recipe acquisition.

Smallest reasonable fix direction:
- Reuse the shared Smartest edge scoring/comparison semantics for the fallback.
- At minimum, include unapplied recipe-acquisition market cost in the fallback primary metric with the same acquired-state rules as the route solver. Shared scoring is preferred to prevent future divergence.

#### Finding 3 — MEDIUM — Malformed Smartest metrics are silently converted into zero-cost edges

Evidence:
- `RouteSolver.lua` uses `numberOrZero(value) = tonumber(value) or 0`.
- `jobEvaluateCraft()` checks only whether the resolved Smartest metric is negative, then later aggregates it through `numberOrZero()` at `RouteSolver.lua:801-833`.
- A nonnumeric `expectedEffectiveCostPerSkillUp` therefore becomes zero instead of being rejected. NaN-like numeric values are also not explicitly rejected by the current negative-only comparisons.
- The adversarial regression supplies a nonnumeric Smartest effective-cost metric; current code accepts the route as a free complete edge.

Impact:
- Corrupt or malformed cost data can win Smartest as a zero-cost route.
- Malformed values can also undermine deterministic lexicographic comparison rather than failing safely.

Smallest reasonable fix direction:
- Validate all Smartest comparison metrics before aggregation: effective cost and expected crafts must be finite numeric values with valid non-negative/positive domains as appropriate.
- Reject malformed edges explicitly before any `numberOrZero()` coercion. Validate surplus as finite before using it as a tie-breaker.

#### Solver/pruning review

The shared layered solver's `bestSwitchNode` pruning is exact for the current production cost model after excluding the malformed-input defect above:

- `routeStateKey` includes skill, trained cap, non-recipe acquired/reusable state, and normalized recipe-acquisition history. States with different future one-time obligations are therefore not merged.
- Within one identical route state, Smartest prefix ordering is lexicographic and every future switch receives the same production edge/state effect; adding the same suffix preserves the first lexicographic difference.
- Non-best nodes still retain the one transition that can depend on their prior recipe: continuing `lastRecipeID`. This preserves cases where a prefix with worse secondary metrics later wins on primary cost by continuing its current recipe.
- Training is resolved before grouping, and training costs enter the primary metric without resale surplus.
- Final-state selection uses the same `nodeBetter()` comparator, including deterministic route-token ordering rather than Lua table iteration order.

The adversarial review suite adds passing cases for equal-cost/different-crafts pruning, equal-cost-and-crafts/different-surplus pruning, a temporarily worse secondary prefix that later wins through continuation, and deterministic final ties under reversed recipe input order.

#### Other reviewed behavior

No additional defect was found in the following areas:
- Cheapest non-Smartest route metric selection remains unchanged in the shared solver.
- Smartest surplus is accumulated only for the selected scroll execution path; direct execution receives zero surplus.
- Resale credit is capped at scroll gross cost and effective craft cost is floored at zero.
- Reusable/tool cost stays outside resale credit; recipe acquisition and profession training are separately added by the route solver.
- Exact skill-up probability and live skill-type reconciliation rescale expected craft count, effective cost, and selected-scroll surplus consistently.
- Owned/vendor availability, conservative AH freshness/quantity evidence, Greater/Lesser Essence availability substitution, and selected-vellum availability are implemented conservatively.
- Legacy setting migration is deterministic/idempotent by version, preserves unrelated settings, maps `dynamic` and `available` as specified, and Static preserves dormant objective/filter preferences.
- Recommendation cache identity contains objective and availability, pending incremental jobs are invalidated by newer objective/filter requests, synchronous and incremental route solving share one engine, and the recommendation cache remains bounded.

Task 43 is **FIX**. Task 44 remains blocked until Agent 3 fixes the three findings and the full validation suite, including the new adversarial regressions, passes.


### Agent 3 fixes

Pending.
