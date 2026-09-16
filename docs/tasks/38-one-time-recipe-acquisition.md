# Task 38 — Restore one-time recipe acquisition without state explosion

Status: IN PROGRESS — compact exact acquisition state implemented; real-client Enchanting memory/performance acceptance pending  
Phase: 8 — Post-Phase-7 correctness follow-up  
Depends on: Task 37 review

## Problem

Task 23 defined recipe learning/acquisition as a one-time route cost.

Task 29 removed persistent `recipe:<id>` keys from route state because arbitrary learned-recipe sets caused combinatorial state explosion in the WoW 3.3.5 Lua runtime. Recipe acquisition is now treated as a segment activation:

- first activation pays acquisition;
- continuing the same recipe does not repay;
- switching away and later returning can pay acquisition again.

That is conservative for memory, but not semantically exact. Once a recipe is learned, returning to it should not require buying/training it again.

## Goal

Restore true one-time recipe acquisition semantics while keeping route state bounded enough for the 3.3.5 client.

## Required work

- Design a compact acquired-recipe representation that does not recreate arbitrary full learned-recipe-set state.
- Preserve exact one-time acquisition for routes that acquire recipe B, switch away, and later return to B.
- Stress-test worst-case full-catalog state counts and allocator behavior.
- Keep reusable tools/training state correct.
- Preserve Task 35 incremental cancellation and exact-result publication.
- Update pass-local recipe-cost caching to depend on the new acquisition representation.
- Add deterministic acquire → switch → return regressions where paying twice changes the globally cheapest route.
- Re-run the original Enchanting memory/performance case in the real client before accepting the design.

## Non-goals

- Do not hide the problem by making acquisition free.
- Do not approximate the route locally.
- Do not change Cheapest/Available objectives.
- Do not restore the original unbounded arbitrary acquisition-set state.

## Acceptance criteria

- A learned/acquired recipe is charged at most once along a complete route.
- Acquire → switch → return regression chooses the correct exact route.
- Full-catalog state count/memory remains bounded in deterministic stress tests.
- Real-client Enchanting route calculation does not reintroduce the Task 29 allocator failure.
- Full validation passes.


## Implementation

Recipe learning is now tracked separately from reusable tools/training state.

### Candidate-scoped compact bitset

For each route calculation, the solver builds a deterministic bit index over the union of recipe candidates that can appear between the start and target skills.

Each route node stores:

- the existing small map for reusable tools/training keys;
- a fixed-width binary string containing learned/acquired recipe bits;
- the active recipe ID.

The solver no longer stores `recipe:<id>` keys in the general Lua acquisition map.

When costing one recipe, the solver materializes only that candidate's `acquiredOneTime["recipe:<id>"]` view if its bit is set. Existing RecipeCost/RecipeAcquisition behavior therefore continues to see normal one-time acquisition state without requiring those modules to understand the bitset.

### Expired history is removed exactly

The generated candidate index gives the solver the future recipe candidates by skill.

At each skill transition, acquired recipe bits are intersected with the set of recipes that can still appear at the current or a later skill. Once a recipe can never be selected again, remembering that it was learned cannot affect any future decision, so its bit is removed.

This is exact state reduction, not an approximation.

### Hard memory bound

The layered solver now refuses to insert more than `maxStates` live states into a ready/next layer. It returns `state_limit_exceeded` before a larger layer can be allocated.

The legacy heap solver is also capped by the same maximum number of unique stored state keys.

A completed route is still exact. If exact acquisition history exceeds the configured state ceiling, dynamic routing fails safely and Static remains the fallback rather than silently approximating acquisition costs.

### Cost-cache dependency

The pass-local recipe-cost cache now distinguishes:

- recipe/skill;
- reusable acquisition signature;
- continuing vs switching;
- whether the candidate recipe is already acquired.

An acquired candidate can therefore never reuse a cached “must purchase/learn” cost, or vice versa.

### Diagnostics

Route-job metrics now expose:

- `peakLayerStates`;
- candidate recipe acquisition bit count;
- acquisition bitset byte width.

`/pcapper perf` prints these with the route-job line.

## Automated regressions

Tests now cover:

- learn recipe B → switch to A → return to B;
- a cost curve where paying B twice changes the globally cheapest route;
- exact acquisition charged only on B's first use;
- legacy and layered synchronous solver agreement for this case;
- synchronous and incremental layered agreement;
- dynamic recommendation + pass-local recipe-cost caching preserving the same result;
- acquisition-heavy synthetic state growth stopping at a deterministic hard state ceiling;
- compact 12-candidate acquisition history using two bytes;
- existing reusable tools, training, modifiers, state limits, full-catalog routing and stale-job cancellation.

## Remaining acceptance

The code and CI portion can be completed automatically.

The original Enchanting case must still be run in WoW 3.3.5 to verify that exact recipe acquisition history does not reintroduce the Task 29 allocator/freeze problem. Record:

- cold Cheapest;
- cold Available;
- warm Cheapest;
- largest route slice;
- explored/peak-layer states;
- acquisition bit count/bytes;
- route-job memory delta;
- retained heap over repeated opens.

Do not mark Task 38 DONE until that real-client result is recorded.
