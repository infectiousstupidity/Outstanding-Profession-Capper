# Task 43 — Smartest objective and availability filter

Status: REVIEW  
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
- Full repository validation is pending the Agent 1 implementation commit.

Task 43 is REVIEW after the implementation commit passes validation. Task 44 remains blocked pending independent Agent 2 review.

### Agent 2 review

Pending.

### Agent 3 fixes

Pending.
