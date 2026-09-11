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
| [04 Recipe difficulty metadata](docs/tasks/04-recipe-difficulty-metadata.md) | QUEUED | Model orange/yellow/green/gray thresholds for route calculations. |
| [05 Recipe acquisition model](docs/tasks/05-recipe-acquisition-model.md) | QUEUED | Model trainer/vendor/AH/reputation/drop acquisition and costs. |
| [06 Acquisition provider integration](docs/tasks/06-acquisition-provider-integration.md) | QUEUED | Optionally consume compatible existing addon data without copying restricted databases. |

### Phase 3 — Cost engine and optimizer

| Task | Status | Purpose |
| --- | --- | --- |
| [07 Recipe cost engine](docs/tasks/07-recipe-cost-engine.md) | DONE | Estimate cost per craft and per expected skill-up. |
| [08 Cheapest route solver](docs/tasks/08-cheapest-route-solver.md) | DONE | Find the cheapest viable path from current skill to cap. |
| [09 Total cost and shopping plan](docs/tasks/09-total-cost-shopping-plan.md) | QUEUED | Aggregate total route cost, gold needed now, and material requirements. |

### Phase 4 — User-facing integration

| Task | Status | Purpose |
| --- | --- | --- |
| [10 Dynamic recommendation UI](docs/tasks/10-dynamic-recommendation-ui.md) | QUEUED | Present cheapest-route recommendations, acquisition guidance, costs, and confidence. |

## Dependency order

`01 -> 02 -> 03`

`01 -> 04 -> 07`

`05 -> 06`

`02 + 03 + 04 + 05 -> 07 -> 08 -> 09 -> 10`

Task 06 may be completed before or after Task 07, but Task 08 must not assume acquisition-provider data is always available.

## Current task

Phase 3 Tasks 07/08 are complete and Task 09 is next. Live optimized routes remain intentionally unavailable until Tasks 04/05 provide verified difficulty and acquisition metadata; the static guide remains the fallback.
