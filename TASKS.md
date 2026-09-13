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
- Preserve the deterministic static guide as a fallback. Dynamic pricing must never make the addon unusable when external price data is missing or stale.
- Static recipe and acquisition knowledge must be self-contained in Profession Capper. Do not depend on Ackis Recipe List or another recipe addon for optimizer coverage.
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
| [06 Acquisition provider integration](docs/tasks/06-acquisition-provider-integration.md) | DONE | Historical optional-provider implementation; Task 21 supersedes the Ackis runtime approach with complete bundled data. |

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
| [26 Available-now recipe recommendation](docs/tasks/26-available-now-recommendation.md) | IN PROGRESS | Offer the cheapest orange/yellow recipe whose missing materials have fresh current purchase sources. |

### Phase 5 — UI/UX polish

Source of truth: [UI polish plan](docs/UI-POLISH-PLAN.md)

| Task | Status | Purpose |
| --- | --- | --- |
| [15 Core UI hierarchy and material redesign](docs/tasks/15-ui-polish-core-hierarchy.md) | DONE | Make the current recommendation, costs, and purchase actions visually clear at a glance. |
| [16 Inline recipe comparison](docs/tasks/16-ui-polish-comparison.md) | DONE | Show why the selected recipe is cheapest without relying on a tooltip. |
| [17 Compact and expanded detail modes](docs/tasks/17-ui-polish-detail-modes.md) | DONE | Keep the default panel focused while preserving deeper comparison/route detail. |
| [18 Enchant repeat workflow presentation](docs/tasks/18-ui-polish-enchant-workflow.md) | DONE | Make target, repeat mode, and progress obvious during repeated enchants. |
| [19 Final visual QA and compatibility](docs/tasks/19-ui-polish-qa.md) | IN PROGRESS | Verify layout, ElvUI compatibility, state handling, and remove obsolete presentation code. |

### Phase 6 — Self-contained full recipe optimization

| Task | Status | Purpose |
| --- | --- | --- |
| [20 Complete self-contained recipe catalog](docs/tasks/20-complete-recipe-catalog.md) | DONE | Bundle a deterministic catalog of all supported WotLK recipes, including recipes the character has not learned. |
| [21 Complete self-contained acquisition database](docs/tasks/21-complete-acquisition-database.md) | DONE | Bundle complete recipe-source data and remove the Ackis runtime dependency path. |
| [22 Multi-source acquisition and character eligibility](docs/tasks/22-multi-source-acquisition.md) | DONE | Resolve all acquisition paths against character/route state and choose the cheapest reliable source. |
| [23 Full-catalog cheapest-route optimization](docs/tasks/23-full-catalog-route-optimization.md) | QUEUED | Optimize across known and unknown-but-obtainable recipes, including one-time learning costs and future unlocks. |
| [24 Learn/buy-first recommendation UI](docs/tasks/24-acquisition-recommendation-ui.md) | QUEUED | Make train/buy/learn actions first-class recommendations before crafting an unknown recipe. |
| [25 Full recipe optimization coverage and regression QA](docs/tasks/25-full-recipe-optimization-qa.md) | QUEUED | Prove catalog/acquisition coverage, route correctness, performance, fallback behavior, and in-game transitions. |

## Dependency order

`01 -> 02 -> 03`

`01 -> 04 -> 07`

`05 -> 06` (historical provider path; superseded by Phase 6)

`02 + 03 + 04 + 05 -> 07 -> 08 -> 09 -> 10`

Phase 5 UI order:

`10 + 14 -> 15 -> 16 -> 17`

`12 + 13 + 15 -> 18`

`15 + 16 + 17 + 18 -> 19`

Availability path:

`03 + 07 + 10 -> 26`

Phase 6 full-recipe optimization order:

`04 -> 20 -> 21 -> 22`

`07 + 08 + 09 + 20 + 21 + 22 -> 23 -> 24 -> 25`

Task 21 removes the Ackis runtime dependency after bundled acquisition coverage is in place. Task 23 must not activate full-catalog recommendations until Tasks 20–22 provide complete conservative recipe/acquisition inputs.

Do not start Task 19 until the preceding UI tasks have had their required in-game checks. Do not mark Task 25 complete until the unknown-recipe acquisition -> learning -> crafting transition has been verified in game.

## Current task

Task 10 remains in manual acceptance. Tasks 12 and 13 are awaiting in-game Enchant repeat testing. Task 14 is implemented in code and awaiting in-game purchase-guidance checks: equivalent Greater/Lesser Essence pricing is quantity-aware, and converted material rows explicitly tell the player what form and quantity to buy, the direct-vs-recommended cost, and the savings.

Task 26 is now in implementation/manual acceptance: Available mode chooses the cheapest orange/yellow recipe whose missing materials resolve to a fresh AH listing or vendor source. Stale AH listings remain valid for Cheapest mode but are rejected by Available mode. Because the current WotLK TSM AuctionDB schema stores listing price/count but not total stack quantity, a fresh listing proves presence, not necessarily that the AH contains every unit required for a large multi-craft segment; exact quantity is used when a provider exposes it.

Phase 5 Tasks 15–18 are accepted and complete. Task 19 is now in progress as the cleanup/compatibility pass. The current cleanup makes Compare rows interactive with per-recipe material tooltips, removes meaningless Static-guide route-detail UI, suppresses the redundant 1 / 1 recipe counter, and avoids showing fake zero/unknown route-price coverage when no complete route exists. Final in-game verification of these cleanup changes is still required before Task 19 is marked DONE.

Phase 6 Task 20 is complete: Profession Capper now ships a generated 3,552-record WotLK recipe catalog with static reagents/output/recipe-item data and live-book overlays. Task 21 is complete with generated trainer/vendor/reputation/limited-stock coverage plus explicit conservative manual fallbacks; Ackis is no longer a runtime dependency. Task 22 is complete: all static acquisition paths are evaluated against simulated profession skill and current character state, dynamic AH/owned-item paths are included, and the cheapest reliable source is selected while conditional alternatives are retained. Tasks 23–25 remain queued. They replace the known-recipes-only optimizer input with complete bundled WotLK recipe/acquisition knowledge, remove Ackis from the runtime design, and add acquisition-aware cheapest-route recommendations.
