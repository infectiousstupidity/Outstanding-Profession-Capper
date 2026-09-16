# Task 39 — Consolidate route solver implementations

Status: DONE  
Phase: 8 — Post-Phase-7 architecture cleanup  
Depends on: Task 38

## Problem

Production optimized UI uses the layered route-job state machine introduced in Task 35, but `RouteSolver.lua` still contains the older heap-based non-layered implementation for callers that omit `layeredDynamicProgramming = true`.

The two paths duplicate craft edges, training transitions, state limits, missing-data handling and route reconstruction, creating semantic-drift risk.

## Goal

After Task 38 settles the authoritative acquisition-state model, prove the required behavior of all callers and consolidate routing around one authoritative transition implementation.

## Required work

- Inventory all callers of `solveCheapestProfessionRoute`.
- Build an explicit equivalence corpus covering acquisition, reusable tools, training, modifiers, incomplete data, state limits and all cost objectives.
- Compare the legacy and layered implementations before deleting behavior.
- Document any intentional semantic difference.
- Remove or isolate duplicate transition logic only after the corpus establishes the intended contract.
- Keep synchronous exact tests and incremental production execution on the same transition semantics.

## Acceptance criteria

- One authoritative transition implementation owns production and synchronous exact routing, or any retained compatibility path has a documented reason and isolated tests.
- Regression corpus passes.
- Full repository validation passes.
- Existing authoritative first-route-segment behavior is preserved for covered scenarios.


## Implementation evidence

- Caller inventory: production recommendation code uses the resumable route job directly; synchronous callers are regression tests/full-catalog helpers and now delegate to that same job state machine.
- Pre-consolidation baseline: master validation run 35062351800 passed with both the default heap solver and layered job corpus present.
- The duplicate heap queue and its craft/training transition loop were removed. `solveCheapestProfessionRoute` is now a synchronous wrapper around `createCheapestProfessionRouteJob` + `runCheapestProfessionRouteJob`.
- The production-only `layeredDynamicProgramming` selector is removed; there is no second transition implementation to drift.
- The regression corpus covers acquisition + switch/return reuse, reusable tools, training, future unlocks, skill modifiers, incomplete data, state limits, and current/market/gold objective behavior. Synchronous and incremental execution share the same transition code.
- Task 38's acquisition-state implementation is already the code path under test. Its remaining real-client performance acceptance does not define different route-transition semantics, so this consolidation does not weaken or bypass that pending measurement gate.
