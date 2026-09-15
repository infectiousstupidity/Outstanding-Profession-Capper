# Task 37 — Phase 7 holistic implementation review

Status: QUEUED  
Phase: 7 — Runtime performance hardening review  
Depends on: Tasks 32, 33, 34, 35 and 36

## Goal

After all Phase 7 implementation tasks are complete, perform an independent holistic review of the finished performance architecture.

This is not another implementation phase disguised as review. First verify what was actually built against the task docs, then fix only concrete defects discovered by the review. If substantial redesign is required, create a new task instead of silently expanding this one.

## Review scope

Review the final code paths spanning:

- `Core.lua` event/refresh lifecycle;
- profession-book scanning and snapshot ownership;
- `DynamicRecommendations.lua` optimizer input and result caching;
- `PriceProvider.lua` and `TSMPriceProvider.lua` price revision/cache behavior;
- `RecipeCost.lua` runtime state/cost caching;
- `RouteSolver.lua` synchronous/incremental shared logic;
- `ShoppingPlan.lua`;
- UI publication/cancellation behavior;
- performance instrumentation and reports;
- test coverage and CI.

## Questions the review must answer

1. Is any expensive work still triggered by an event that cannot affect it?
2. Can any cache return stale data because a dependency is missing from its revision set?
3. Can a cancelled/stale route job still mutate shared state or publish UI?
4. Is immutable catalog data truly immutable in practice?
5. Are there duplicate caches that disagree about ownership or invalidation?
6. Is any cache unbounded?
7. Is the incremental solver semantically identical to the intended layered solver?
8. Can profession-window filter/header mutation cause event amplification?
9. Does Static remain usable when dynamic optimization fails?
10. Did performance work accidentally alter Cheapest or Available semantics?
11. Are manual perf claims supported by recorded measurements?
12. Are there new code smells: oversized functions, duplicated transition logic, hidden global state, unnecessary table churn, or fragile Lua 5.1 behavior?

## Adversarial scenarios

Attempt to break the implementation with sequences such as:

- open Enchanting -> start calculation -> close immediately -> open Jewelcrafting;
- start Cheapest -> switch Available -> switch Static -> switch Cheapest while prior jobs are pending;
- bag change during route calculation;
- skill-up during route calculation;
- learn recipe during route calculation;
- provider revision changes between job start and publish;
- optimizer throws an error while Static remains valid;
- repeatedly open/close the same profession many times;
- price provider unavailable, then available;
- route details / Compare / map locations opened while recommendation state changes.

Use deterministic tests for what can be simulated and real-client verification for frame/event behavior.

## Code-quality review

Prefer deletion/simplification where Phase 7 left transitional machinery behind.

Specifically look for:

- old blanket invalidation APIs no longer needed;
- duplicate synchronous and incremental solver implementations;
- caches keyed by large serialized tables;
- repeated `pcall`/API work that can safely be hoisted;
- excessive per-state table allocation;
- debug instrumentation accidentally enabled in normal paths;
- task-specific comments that should be replaced by durable architectural comments.

Do not optimize merely for fewer lines. Preserve clarity around cache ownership and invalidation.

## Documentation review

Update:

- `TASKS.md`;
- Phase 7 task statuses;
- performance baseline/final report;
- README only if user-facing diagnostics or behavior changed.

The final documentation must clearly state:

- what was measured;
- what was changed;
- what the final invalidation model is;
- what remains intentionally approximate;
- any remaining known performance limitation.

## Acceptance criteria

- Tasks 32–36 are complete and their acceptance evidence exists.
- Full repository validation passes at the final reviewed commit.
- Review finds no stale-publication path.
- Review finds no unbounded cache introduced by Phase 7.
- Incremental and synchronous route regression corpus agrees.
- Static fallback is isolated from optimizer failure.
- Recorded real-client before/after measurements support the performance claim.
- Any substantial unresolved issue is captured as a new numbered task.
- `TASKS.md` reflects the final state accurately.

## Final handoff

End the task with a concise review summary containing:

- defects found;
- defects fixed;
- tests added/changed;
- before/after performance measurements;
- remaining risks;
- follow-up task numbers, if any.

Do not mark this task DONE until that summary exists.
