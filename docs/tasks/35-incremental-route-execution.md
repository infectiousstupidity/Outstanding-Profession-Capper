# Task 35 — Incremental, cancellable exact-route execution

Status: IN PROGRESS — code implemented; Task 32/34 measurements and in-game acceptance pending  
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


## Implementation status

The layered exact-route solver now runs through one explicit state machine used by both synchronous tests and the incremental UI path. The job stores the current skill layer, ready/group/next-state maps, node/group/candidate cursors, missing-data reasons, explored-state count, and finalization state. No coroutine yielding is used.

Production slices use `debugprofilestop()` when available, with a conservative internal default budget of 3 ms. `GetTime()` and `os.clock()` remain fallbacks. Tests can inject a deterministic fake clock.

Each route job captures the Task 34 recommendation cache key as its generation token and receives a live dependency check covering profession-book, skill/modifier, inventory, eligibility, mode/manual generations, provider identity, and provider revision. A stale job is cancelled before another slice and cannot finalize/publish.

The dynamic recommendation path now has an incremental mode used by `Core.lua`. A valid exact cached result is still returned immediately. On a cold miss, the frame shows an explicit “Calculating exact route · Static fallback” state; the local current-step ranking is retained only as internal work and is not published as authoritative Cheapest/Available. Compare/Route are hidden while pending. The exact result is applied atomically after the job completes and the dependency check still passes.

Profession close, refresh supersession, mode/input changes, and explicit cancellation release the job's large state tables. Optimizer exceptions are caught at the existing UI fallback boundary and leave Static usable.

Task 32 performance output now records async route-job slice count, largest slice, accumulated work time, wall time until exact result is ready, explored states, cancellation count, and memory delta.

Automated coverage includes synchronous/incremental route equivalence, training boundaries, acquisition-first routes, reusable tools, future recipe switches, modifiers, state limits, fake-clock pause/resume, generation cancellation, stale-state release, exact Cheapest/Available equivalence, pending-state behavior, and inventory-generation cancellation.

The task remains IN PROGRESS until the real-client Enchanting/Jewelcrafting matrix is rerun and the close/reopen, bag move, mode-switch, TSM revision, and skill-up cancellation checks are recorded.
