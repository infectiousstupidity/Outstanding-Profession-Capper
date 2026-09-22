# Profession Capper task plan

This file governs implementation work. Keep it current as work progresses.

## Execution rules

- Work directly on `master`. Do not create feature branches or pull requests unless explicitly requested.
- One implementation task = one commit = one push unless a task explicitly defines an independent review/fix gate.
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
- Phase 9 uses a strict three-agent gate per task: Agent 1 implements -> Agent 2 independently reviews -> Agent 3 fixes recorded findings if any -> only then may the next task start.
- For a three-agent task, the implementation, review bookkeeping, and fix pass may be separate commits. Never combine work from two task numbers in one commit.

## Status values

- `QUEUED` — ready but not started.
- `BLOCKED` — cannot start until a dependency is resolved.
- `IN PROGRESS` — current implementation task.
- `REVIEW` — Agent 1 implementation is complete and awaiting independent Agent 2 review.
- `FIX` — Agent 2 recorded concrete findings that Agent 3 must resolve before the task can close.
- `DONE` — implemented, independently reviewed, any required fixes completed, pushed, and validated.

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
| [27 Native item tooltips across recipe UI](docs/tasks/27-native-item-tooltips.md) | IN PROGRESS | Show canonical WoW output-item tooltips on main, Compare, and Full route recipe entries. |
| [28 Static full-route browser](docs/tasks/28-static-full-route.md) | IN PROGRESS | Expose the deterministic Static guide as a complete paged route with rank-training boundaries. |

### Phase 6 — Self-contained full recipe optimization

| Task | Status | Purpose |
| --- | --- | --- |
| [20 Complete self-contained recipe catalog](docs/tasks/20-complete-recipe-catalog.md) | DONE | Bundle a deterministic catalog of all supported WotLK recipes, including recipes the character has not learned. |
| [21 Complete self-contained acquisition database](docs/tasks/21-complete-acquisition-database.md) | DONE | Bundle complete recipe-source data and remove the Ackis runtime dependency path. |
| [22 Multi-source acquisition and character eligibility](docs/tasks/22-multi-source-acquisition.md) | DONE | Resolve all acquisition paths against character/route state and choose the cheapest reliable source. |
| [23 Full-catalog cheapest-route optimization](docs/tasks/23-full-catalog-route-optimization.md) | DONE | Optimize across known and unknown-but-obtainable recipes, including one-time learning costs and future unlocks. |
| [24 Learn/buy-first recommendation UI](docs/tasks/24-acquisition-recommendation-ui.md) | IN PROGRESS | Make train/buy/learn actions first-class recommendations before crafting an unknown recipe. |
| [25 Full recipe optimization coverage and regression QA](docs/tasks/25-full-recipe-optimization-qa.md) | QUEUED | Prove catalog/acquisition coverage, route correctness, performance, fallback behavior, and in-game transitions. |
| [29 Full-route optimizer memory/state explosion](docs/tasks/29-full-route-optimizer-memory.md) | IN PROGRESS | Bound full-catalog route state/cache growth and keep Static usable if dynamic optimization fails. |
| [30 Precomputed adaptive-route runtime](docs/tasks/30-precomputed-route-runtime.md) | IN PROGRESS | Precompute static route topology and minimize runtime catalog, state, pricing and solver work when profession windows open. |
| [31 In-frame route details and recipe source locations](docs/tasks/31-route-details-source-locations.md) | IN PROGRESS | Keep expanded route details inside the main frame and show physical trainer/vendor NPC locations. |

### Phase 7 — Runtime performance hardening

This phase addresses the remaining severe profession-window lag. It is deliberately ordered measurement-first so agents do not rewrite the solver or cache model based on assumptions.

| Task | Status | Purpose |
| --- | --- | --- |
| [32 Runtime performance instrumentation and baseline](docs/tasks/32-performance-instrumentation-baseline.md) | IN PROGRESS | Measure the real cold/warm open, refresh, solver, price, allocation, memory, and event costs before changing execution behavior. |
| [33 Profession scan lifecycle and event invalidation](docs/tasks/33-profession-scan-lifecycle.md) | IN PROGRESS | Stop bag/volatile-state changes from rediscovering the profession book; make recipe-book invalidation explicit. |
| [34 Revisioned runtime caches and immutable optimizer inputs](docs/tasks/34-revisioned-runtime-caches.md) | IN PROGRESS | Replace blanket invalidation/repeated object construction with bounded dependency-aware caches and persistent provider-revision pricing. |
| [35 Incremental, cancellable exact-route execution](docs/tasks/35-incremental-route-execution.md) | IN PROGRESS | Time-slice the existing layered route calculation without changing the authoritative global Cheapest result or allowing stale jobs to publish. |
| [36 End-to-end performance regression hardening](docs/tasks/36-performance-regression-hardening.md) | IN PROGRESS | Re-run the full event/mode matrix, add regression gates, clean transitional machinery, and record before/after performance. |
| [37 Phase 7 holistic implementation review](docs/tasks/37-performance-hardening-review.md) | IN PROGRESS | Independently review all Phase 7 work for stale caches/jobs, semantic drift, memory growth, code smells, and unsupported performance claims. |

### Phase 8 — Post-Phase-7 follow-up

| Task | Status | Purpose |
| --- | --- | --- |
| [38 Restore one-time recipe acquisition without state explosion](docs/tasks/38-one-time-recipe-acquisition.md) | IN PROGRESS | Restore true one-time recipe learning costs without reintroducing the Task 29 acquisition-set state explosion. |
| [39 Consolidate route solver implementations](docs/tasks/39-route-solver-consolidation.md) | DONE | Prove caller/equivalence requirements and consolidate duplicated legacy heap/layered route transition logic. |


### Phase 9 — Resale-aware Smartest optimization

This phase adds a deterministic Smartest objective without changing Cheapest. It starts only after Task 39 consolidates route-solver behavior. Every task uses the strict Agent 1 implement -> Agent 2 review -> Agent 3 fix-if-needed gate, and the next task may not start until the previous task is DONE.

| Task | Status | Purpose |
| --- | --- | --- |
| [40 Deterministic enchant scroll and vellum metadata](docs/tasks/40-enchant-scroll-vellum-metadata.md) | DONE | Generate reliable scroll/vellum compatibility data without runtime tooltip/name guessing. |
| [41 Conservative resale valuation](docs/tasks/41-conservative-resale-valuation.md) | DONE | Turn TSM listing data into conservative resale evidence without pretending listings are guaranteed sales. |
| [42 Resale-aware Enchanting craft economics](docs/tasks/42-resale-aware-enchant-economics.md) | DONE | Compare direct vs vellum execution, cap resale credit at gross craft cost, and track surplus separately. |
| [43 Smartest objective and availability filter](docs/tasks/43-smartest-objective-and-availability-filter.md) | REVIEW | Add lexicographic Smartest routing and make Available-now an orthogonal constraint. |
| [44 Smartest mode UI and economic explanations](docs/tasks/44-smartest-ui-and-explanations.md) | REVIEW | Implemented on PR #2; full validation run 131 passed. Independent review and in-game visual verification remain. |
| [45 Vellum execution and shopping-plan integration](docs/tasks/45-vellum-execution-and-shopping-plan.md) | BLOCKED | Make scroll recommendations actionable, reconcile vellums with shopping/availability, and verify repeat safety. |
| [46 Smartest end-to-end regression and performance review](docs/tasks/46-smartest-regression-performance-review.md) | BLOCKED | Stress-test correctness, assumptions, UI, caches and performance before closing the phase. |

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

`23 + 29 -> 30 -> 25`

`21 + 24 + 30 -> 31 -> 25`

Phase 7 performance order:

`29 + 30 -> 32 -> 33 -> 34 -> 35 -> 36 -> 37`

Post-review follow-up:

`37 -> 38 -> 39`

Phase 9 Smartest optimization:

`39 -> 40 -> 41 -> 42 -> 43 -> 44 -> 45 -> 46`

Each Phase 9 arrow is a hard handoff gate: the upstream task must be DONE after its independent review/fix cycle before the downstream task begins.

Task 32 remains the real-client measurement gate. Under explicit continuation, Tasks 33–37 have code implemented or reviewed but must not be marked DONE until the required WoW evidence exists. Tasks 33–34 preserve current Cheapest/Available semantics. Task 35 preserves the globally selected first route segment and rejects stale work. Task 36 owns the full regression/performance matrix. Task 37 reviews the phase as one architecture and queues substantive follow-up work rather than hiding it inside the review.

Task 21 removes the Ackis runtime dependency after bundled acquisition coverage is in place. Task 23 must not activate full-catalog recommendations until Tasks 20–22 provide complete conservative recipe/acquisition inputs.

Do not start Task 19 until the preceding UI tasks have had their required in-game checks. Do not mark Task 25 complete until the unknown-recipe acquisition -> learning -> crafting transition has been verified in game.

## Current task

Task 10 remains in manual acceptance. Tasks 12 and 13 are awaiting in-game Enchant repeat testing. Task 14 is implemented in code and awaiting in-game purchase-guidance checks: equivalent Greater/Lesser Essence pricing is quantity-aware, and converted material rows explicitly tell the player what form and quantity to buy, the direct-vs-recommended cost, and the savings.

Task 26 is now in implementation/manual acceptance: Available mode chooses the cheapest orange/yellow recipe whose missing materials resolve to a fresh AH listing or vendor source. Stale AH listings remain valid for Cheapest mode but are rejected by Available mode. Because the current WotLK TSM AuctionDB schema stores listing price/count but not total stack quantity, a fresh listing proves presence, not necessarily that the AH contains every unit required for a large multi-craft segment; exact quantity is used when a provider exposes it.

Phase 5 Tasks 15–18 are accepted and complete. Task 19 is now in progress as the cleanup/compatibility pass. Task 27 is implemented in code and awaiting in-game verification of native output-item tooltips. Task 28 is implemented in code and awaiting in-game verification of the paged Static full route. The current cleanup makes Compare rows interactive with per-recipe material tooltips, removes meaningless Static-guide route-detail UI, suppresses the redundant 1 / 1 recipe counter, and avoids showing fake zero/unknown route-price coverage when no complete route exists. Final in-game verification of these cleanup changes is still required before Task 19 is marked DONE.

Phase 6 Task 20 is complete: Profession Capper now ships a generated 3,552-record WotLK recipe catalog with static reagents/output/recipe-item data and live-book overlays. Task 21 is complete with generated trainer/vendor/reputation/limited-stock coverage plus explicit conservative manual fallbacks; Ackis is no longer a runtime dependency. Task 22 is complete: all static acquisition paths are evaluated against simulated profession skill and current character state, dynamic AH/owned-item paths are included, and the cheapest reliable source is selected while conditional alternatives are retained. Task 23 is complete: the optimizer now uses the full bundled catalog, future recipe unlocks and reachable profession-rank training while preserving the newer pass-local cost/price caches. Task 24 is implemented in code and awaiting its required in-game acquisition/learning transition checks. Task 29 fixes the reported full-catalog allocator/state explosion and is awaiting in-game Enchanting verification. Task 30 replaces most profession-open recomputation with generated route topology, candidate-scoped/lazy character state, a layered route solver, per-recipe material-cost reuse and completed-recommendation caching; automated validation passes, while the original in-game Enchanting open/close latency case remains the required manual acceptance. Task 31 fixes expanded Route details so they are bottom-anchored inside the main frame and adds bundled physical trainer/vendor NPC locations, including faction-aware zone/coordinate guidance in the main recommendation, Details, Compare and Full route tooltips. Automated validation is required; in-game layout/location verification remains manual acceptance. Task 25 remains queued for final full-recipe optimization coverage and acceptance.

Phase 7 is now in progress. Task 32 instrumentation is implemented in code with an opt-in /pcapper perf command, phase/counter/cache measurements, refresh-reason tracking, memory deltas, and automated instrumentation tests. The real 3.3.5 client baseline is still the hard acceptance gate: Enchanting/Jewelcrafting cold-open, warm-open, event-refresh, route, pricing, memory, and event-amplification measurements still need to be recorded. Under explicit continuation, Task 33's code is now implemented but remains IN PROGRESS pending that evidence and its in-game checks. It separates profession-book scanning from volatile state: same-profession reopens and BAG_UPDATE reuse the session snapshot, learned recipes invalidate it, profession switches force a scan, and base-skill changes refresh live difficulty without rediscovering recipe identity. Task 34's code is also now implemented and remains IN PROGRESS pending the same real-client gate: runtime dependencies have explicit generations, provider prices and recommendations are bounded/revisioned caches, BAG_UPDATE invalidates inventory-dependent outputs without destroying prices/static recipes, and bundled recipes use reusable canonical optimizer structures. Task 35's code is now implemented and remains IN PROGRESS pending real-client acceptance. The exact layered solver is an explicit resumable state machine with a 3 ms default time budget, generation/provider cancellation, exact-result-only publication, pending Static fallback UI, and synchronous/incremental equivalence tests. Task 36 automated hardening is implemented and remains IN PROGRESS pending the real-client matrix. Task 37's holistic code review is implemented and also remains IN PROGRESS pending that evidence. Task 38 is now implemented in code and remains IN PROGRESS pending the original Enchanting allocator/performance acceptance: recipe learning is tracked exactly with a candidate-scoped fixed-width bitset, obsolete recipe bits expire when they can no longer affect future choices, live layered state insertion is hard-capped, and pass-local recipe-cost caching distinguishes acquired vs not-acquired candidates. Deterministic acquire → switch → return tests verify acquisition is charged once. Task 39 is complete: the duplicate heap route implementation is removed, synchronous routing delegates to the same layered job state machine used by incremental production execution, and the existing equivalence corpus covers acquisition, reusable tools, training, future unlocks, modifiers, incomplete data, state limits, and objective ordering. Task 38's remaining real-client performance evidence is still pending and is not reclassified by this consolidation. No real-client latency or retained-heap claim is considered proven yet.


Phase 9 is unblocked by Task 39. Task 40 is DONE after independent review found and Agent 3 fixed the expansion-based vellum-tier heuristic; all 240 eligible scroll enchants now use a pinned direct minimum-vellum mapping, and full validation passed on run 106. Task 41 is DONE. Task 42 is DONE after Agent 3 resolved both independent-review findings: live skill-up reconciliation now rescales all Task 42 expected economics from the final chance, and informational surplus now derives from the retained resale estimate while only trusted optimization value can reduce route cost. Fix commit `67abf1afce12898497243b85a72d9a68501011a0` passed full `Validate addon` run 117. Cheapest ordering and existing cache ownership remain unchanged. Task 43 is DONE after Agent 3 fixed all three independent-review findings in `44a22cc7ef93b76dd3fffb8efc21b07486526130`: Available-only is again a pure feasibility filter for Cheapest fallback, Smartest fallback now includes unapplied recipe-acquisition cost, and malformed/non-finite Smartest metrics are rejected safely. Full `Validate addon` run 123 passed, including the Agent 2 adversarial suite. Task 44 is now in REVIEW after Agent 1 implementation on PR #2. Full `Validate addon` run 131 passed on implementation head `d99ab475cd3e28db8560cc49c40f114eb940a4e8`. Independent Agent 2 review and real in-game visual verification remain required; Task 45 is still blocked. The approved product model is: Static remains the deterministic fallback/path; Cheapest keeps current cost-minimizing semantics; Smartest is a separate deterministic resale-aware objective; Available-now becomes an orthogonal feasibility filter that can constrain Cheapest or Smartest. Smartest must never use negative route edges: resale credit can reduce variable material + vellum cost to zero, while any estimated surplus is tracked separately. Listing prices are market estimates, not guaranteed sale proceeds. Tasks 40–46 must execute strictly through the Agent 1 implementation -> Agent 2 independent review -> Agent 3 fix-if-needed workflow before proceeding to the next task.
