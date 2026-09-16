# Task 38 — Restore one-time recipe acquisition without state explosion

Status: QUEUED  
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
