# Task 35 — Incremental, cancellable exact-route execution

Status: QUEUED  
Phase: 7 — Runtime performance hardening  
Depends on: Tasks 32, 33 and 34

## Goal

Prevent the full adaptive-route calculation from monopolizing a WoW UI frame while preserving the current route-selection semantics.

This task is justified only after the Task 32/34 measurements are reviewed. The implementation must use those measurements as the before/after benchmark.

## Important semantic rule

Do not replace the globally selected first route segment with a locally cheapest approximation.

The current optimizer first computes a local fallback candidate, but once the complete route is solved it intentionally uses `route.segments[1]` as the authoritative Cheapest recommendation.

Therefore the UI must never label an approximate local choice as the final Cheapest answer.

Allowed cold-start behavior:

- immediately show the Profession Capper frame;
- reuse the last still-valid exact result if one exists;
- otherwise show an explicit calculating/pending state;
- atomically publish the exact result when the route job completes.

Static may be shown as an explicitly labelled fallback, but not disguised as the optimized result.

## Implementation approach

Convert the existing layered dynamic-programming route path into an explicit resumable job/state machine.

Do not depend on yielding a coroutine through protected/C API boundaries. WoW 3.3.5 uses Lua 5.1-era behavior and such yielding is fragile.

The job should hold explicit state such as:

- current skill layer;
- current/next route states;
- candidate cursor;
- group/node cursor;
- accumulated missing-data flags;
- explored-state count;
- finalization state.

Reuse the existing layered solver logic rather than maintaining two independently evolving optimization algorithms.

## Time budgeting

Do not use a fixed "N states per frame" budget. State cost is variable because some evaluations can cause acquisition logic, price/cache lookups, and material calculations.

Use a time budget measured with `debugprofilestop()` when available.

The budget should be configurable internally and conservative by default. The implementation should yield control once the budget is exhausted and continue on a later frame.

The goal is to bound the worst single-frame addon cost, not merely total route duration.

## Generation/cancellation safety

Every job must capture the relevant Task 34 revisions/generations.

If any dependency changes while a job is running, for example:

- profession changes;
- skill changes;
- active profession modifier changes;
- recipe is learned;
- inventory generation changes under current semantics;
- price-provider revision changes;
- recommendation mode changes;

the old job must be cancelled or marked stale.

A stale job must never publish UI state.

Use an explicit job/generation token so this is testable.

## UI behavior

While calculating:

- keep the addon interactive;
- do not freeze profession-window close/open;
- Compare/Route views must not display data from a superseded job;
- show a concise calculating state only when there is no valid exact cached result.

When complete, publish the route/recommendation as one coherent result. Avoid partially replacing individual fields over several frames.

## Compatibility path

Keep a synchronous solver entry point for deterministic unit tests if useful, but it should share the same core transition logic.

Do not duplicate cost semantics between synchronous and incremental paths.

## Tests

Required automated coverage:

- incremental result exactly matches synchronous layered solver result for existing route fixtures;
- training boundaries match;
- acquisition-first routes match;
- reusable rod/tool state matches;
- future recipe switches match;
- modifier-aware routes match;
- Cheapest and Available semantics remain unchanged;
- a job can pause/resume across many slices;
- cancelling generation N prevents it from publishing after generation N+1 starts;
- price/inventory/skill changes cancel or invalidate the correct job;
- state-limit and optimizer-error fallback still work;
- no job retains unbounded stale state after cancellation.

Add a deterministic fake clock for unit tests rather than depending on wall-clock speed.

## Manual acceptance

Use the same Enchanting and Jewelcrafting scenarios from Task 32.

Record:

- time to frame becoming interactive;
- largest single measured work slice;
- total time until exact route result is ready;
- number of slices;
- explored states;
- memory delta.

While a route is calculating, actively:

1. close the profession window;
2. reopen it;
3. move a reagent;
4. switch Cheapest/Available/Static;
5. if practical, cause a skill-up.

Confirm stale work never overwrites the newer state.

## Acceptance criteria

- Full repository validation passes.
- Exact route output matches the existing layered solver for the regression corpus.
- No locally cheapest approximation is presented as authoritative Cheapest.
- Route work is resumable and time-budgeted.
- Stale jobs cannot publish.
- Profession UI remains responsive during a cold full-route calculation.
- Task 32/34 before/after metrics are added to the performance report.
- Static fallback still survives optimizer failure.

## Scope guard

Do not change the route's economics to make this easier. Inventory-sensitive Cheapest behavior remains as-is in this task.
