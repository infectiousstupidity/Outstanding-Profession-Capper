# Profession Capper task plan

This file governs implementation work. Keep it current as work progresses.

## Execution rules

- Work directly on `master`. Do not create feature branches or pull requests unless explicitly requested.
- One implementation task = one commit = one push.
- Do not combine two task docs into one implementation commit.
- Every task commit must update this `TASKS.md` in the same commit.
- Mark a task `IN PROGRESS` only when implementation begins.
- Mark a task `DONE` only when its acceptance criteria pass.
- If a task discovers new required work, add a new task doc and queue it explicitly rather than silently expanding scope.
- Preserve the deterministic static guide as a fallback. Dynamic pricing must never make the addon unusable when external addon data is missing or stale.
- Stay compatible with WoW 3.3.5 / Lua 5.1.
- Run the repository validation workflow for every task.
- Manual in-game checks that CI cannot prove must be recorded in the task doc before the task is marked `DONE`.

## Status values

- `QUEUED` — ready but not started.
- `BLOCKED` — cannot start until a dependency is resolved.
- `IN PROGRESS` — current implementation task.
- `DONE` — implemented, committed, pushed, and validated.

## Phases

### Phase 1 — Character and price foundations

| Task | Status | Purpose |
| --- | --- | --- |
| [01 Character profession skill context](docs/tasks/01-character-skill-context.md) | IN PROGRESS | Correctly model base skill, active +profession modifiers, and effective skill. |
| [02 Price provider abstraction](docs/tasks/02-price-provider-abstraction.md) | DONE | Define one internal API for external price sources. |
| [03 TSM AuctionDB integration](docs/tasks/03-tsm-auctiondb-integration.md) | DONE | Read local TSM/AuctionDB prices and freshness safely. |
| [11 Enchanting rod ownership-aware recommendations](docs/tasks/11-enchanting-rod-ownership.md) | DONE | Do not recommend crafting a runed rod already superseded by one the character owns. |

### Phase 2 — Recipe knowledge and acquisition

| Task | Status | Purpose |
| --- | --- | --- |
| [04 Recipe difficulty metadata](docs/tasks/04-recipe-difficulty-metadata.md) | DONE | Model orange/yellow/green/gray thresholds for route calculations. |
| [05 Recipe acquisition model](docs/tasks/05-recipe-acquisition-model.md) | DONE | Model trainer/vendor/AH/reputation/drop acquisition and costs. |
| [06 Acquisition provider integration](docs/tasks/06-acquisition-provider-integration.md) | DONE | Optionally consume compatible existing addon data without copying restricted databases. |

### Phase 3 — Cost engine and optimizer

| Task | Status | Purpose |
| --- | --- | --- |
| [07 Recipe cost engine](docs/tasks/07-recipe-cost-engine.md) | DONE | Estimate cost per craft and per expected skill-up. |
| [08 Cheapest route solver](docs/tasks/08-cheapest-route-solver.md) | DONE | Find the cheapest viable path from current skill to cap. |
| [09 Total cost and shopping plan](docs/tasks/09-total-cost-shopping-plan.md) | DONE | Aggregate total route cost, gold needed now, and material requirements. |

### Phase 4 — User-facing integration

| Task | Status | Purpose |
| --- | --- | --- |
| [10 Dynamic recommendation UI](docs/tasks/10-dynamic-recommendation-ui.md) | IN PROGRESS | Present cheapest-route recommendations, acquisition guidance, costs, and confidence. |
| [12 Targeted Enchant repeat workflow](docs/tasks/12-targeted-enchant-repeat.md) | IN PROGRESS | Repeat item-targeted enchants without fake batch state; remember the target and support until-change/fixed counts. |
| [13 Auto-confirm Enchant replacement](docs/tasks/13-auto-confirm-enchant-replacement.md) | IN PROGRESS | Skip the replace-enchant confirmation during Profession Capper repeat clicks without calling the protected API prematurely. |
| [14 Equivalent reagent purchase guidance](docs/tasks/14-equivalent-reagent-purchase-guidance.md) | IN PROGRESS | Show the exact cheaper Greater/Lesser Essence purchase, quantity, conversion, and savings instead of only using it internally for pricing. |

### Phase 5 — UI/UX polish

Source of truth: [UI polish plan](docs/UI-POLISH-PLAN.md)

| Task | Status | Purpose |
| --- | --- | --- |
| [15 Core UI hierarchy and material redesign](docs/tasks/15-ui-polish-core-hierarchy.md) | IN PROGRESS | Make the current recommendation, costs, and purchase actions visually clear at a glance. |
| [16 Inline recipe comparison](docs/tasks/16-ui-polish-comparison.md) | IN PROGRESS | Show why the selected recipe is cheapest without relying on a tooltip. |
| [17 Compact and expanded detail modes](docs/tasks/17-ui-polish-detail-modes.md) | IN PROGRESS | Keep the default panel focused while preserving deeper comparison/route detail. |
| [18 Enchant repeat workflow presentation](docs/tasks/18-ui-polish-enchant-workflow.md) | IN PROGRESS | Make target, repeat mode, and progress obvious during repeated enchants. |
| [19 Final visual QA and compatibility](docs/tasks/19-ui-polish-qa.md) | QUEUED | Verify layout, ElvUI compatibility, state handling, and remove obsolete presentation code. |

## Dependency order

`01 -> 02 -> 03`

`01 -> 04 -> 07`

`05 -> 06`

`02 + 03 + 04 + 05 -> 07 -> 08 -> 09 -> 10`

Task 06 may be completed before or after Task 07, but Task 08 must not assume acquisition-provider data is always available.

Phase 5 UI order:

`10 + 14 -> 15 -> 16 -> 17`

`12 + 13 + 15 -> 18`

`15 + 16 + 17 + 18 -> 19`

Do not start Task 19 until the preceding UI tasks have had their required in-game checks.

## Current task

Task 10 remains in manual acceptance. Tasks 12 and 13 are awaiting in-game Enchant repeat testing. Task 14 is implemented in code and awaiting in-game purchase-guidance checks: equivalent Greater/Lesser Essence pricing is quantity-aware, and converted material rows explicitly tell the player what form and quantity to buy, the direct-vs-recommended cost, and the savings.

Phase 5 Tasks 15, 16, and 18 remain in manual acceptance. Task 17 is implemented in code and awaiting in-game acceptance: Compact is the default persisted view; Expanded adds inline route total, immediate gold need, expected crafts, route price coverage, and comparable-candidate count without duplicating the Task 16 Compare companion panel. Task 19 remains queued.
