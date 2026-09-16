# Task 45 — Vellum execution and shopping-plan integration

Status: BLOCKED  
Phase: 9 — Resale-aware Smartest optimization  
Depends on: Task 44

## Goal

Make a Smartest scroll recommendation actionable without pretending the addon can automate behavior that WoW 3.3.5 secure interaction rules do not safely permit.

Integrate selected vellums into material requirements, availability and the Enchanting workflow.

## Shopping-plan integration

When a route segment chooses the scroll execution method:

- include the chosen vellum as a consumed reagent;
- account for the expected number of crafts using the same rounding/quantity conventions as the existing shopping plan;
- include owned vellums before missing-purchase quantities where existing inventory semantics apply;
- include vellum purchase cost in gross cost;
- include vellum availability in Available-now feasibility.

Do not add a vellum when the selected method is direct.

## Execution presentation

For a scroll path, the primary action must explicitly identify:

- the enchant;
- the vellum item to target;
- the resulting scroll.

The workflow must not accidentally instruct the player to overwrite a normal equipped-item enchant when Smartest intended scroll production.

## Repeat workflow safety

Do not assume the existing targeted repeat-enchant workflow automatically works for vellums.

Verify in the real 3.3.5 client how successive vellums are targeted/consumed.

Allowed outcomes:

1. If the existing secure interaction can safely repeat on successive vellums, integrate it and test it.
2. If it cannot, keep the recommendation/action manual and explicit. Do not invent fake auto-batching state.

No protected API workaround or automation beyond what the client permits.

## Availability semantics

When Available-now is enabled and Smartest chooses a scroll path, the route is feasible only if all required current-purchase evidence passes the existing availability rules, including the vellum.

Preserve the existing conservative behavior when exact AH stack quantity is unavailable.

## Route transitions

After a skill-up or material/inventory change:

- invalidate/re-evaluate the recommendation using existing generation rules;
- do not continue blindly producing the old scroll after the authoritative recommendation changes;
- a stale repeat/target state must not override the new Smartest result.

## Tests

Cover:

- vellum appears in shopping requirements only for scroll method;
- owned vellums reduce purchase quantity correctly;
- availability includes vellum evidence;
- direct method remains unchanged;
- recommendation change invalidates stale repeat/action state;
- shopping totals reconcile with route economics;
- no duplicate vellum line from both synthetic economics and reagent aggregation;
- no protected-action assumptions in deterministic tests.

Manual in-game verification must cover successive vellum targeting before any repeat integration is accepted.

## Required handoff workflow

### Agent 1 — implement

Implement Task 45 only. Run shopping-plan/recommendation/full validation and required in-game checks, record evidence, commit/push, set `REVIEW`. Do not start Task 46.

### Agent 2 — independent review

Review shopping reconciliation, availability, target safety, repeat assumptions, stale-state behavior and secure-interaction boundaries.

If clean, mark `DONE`.

If findings exist, record them, mark `FIX`, hand off to Agent 3.

### Agent 3 — fix findings only

Fix the recorded findings, rerun tests and required in-game checks, record evidence, mark `DONE`, then Task 46 may begin.

## Acceptance criteria

- Selected vellums are represented exactly once in shopping/material requirements.
- Available-now accounts for vellum feasibility.
- Direct recommendations do not require vellum.
- Scroll recommendations clearly target vellum and identify the produced scroll.
- No unsupported auto-batching behavior is claimed or implemented.
- Stale repeat/action state cannot survive a recommendation change.
- Shopping totals reconcile with route economics.
- Full validation and required in-game checks pass.
- Review/fix gate is complete.

## Evidence

### Agent 1 implementation

Pending.

### Agent 2 review

Pending.

### Agent 3 fixes

Pending.
