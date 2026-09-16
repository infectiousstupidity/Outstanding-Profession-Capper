# Phase 7 performance regression report

Status: REAL-CLIENT MATRIX PENDING

This report is the final Task 36 acceptance record. Automated regression gates are implemented, but performance values must come from the actual WoW 3.3.5 client. Do not replace pending cells with synthetic Lua timings or estimates.

## Automated regression gates

| Gate | Automated evidence |
| --- | --- |
| BAG_UPDATE cannot rediscover the profession book | `tools/test_profession_book.lua` + `tools/validate_phase7_guards.py` |
| Equivalent event burst schedules one expensive refresh | `tools/test_refresh_coordinator.lua` |
| Same-character warm reopen reuses profession snapshot | `tools/test_profession_book.lua` |
| Profession/character snapshot leakage is rejected | `tools/test_profession_book.lua` |
| Warm exact recommendation does not rerun solver | `tools/test_runtime_caches.lua` |
| Inventory change invalidates current Cheapest result | `tools/test_runtime_caches.lua` |
| Provider revision invalidates price result | `tools/test_runtime_caches.lua` |
| Same-name/same-revision provider replacement cannot reuse stale data | `tools/test_price_provider.lua` |
| Provider instance replacement cancels pending route publication | `tools/test_incremental_recommendations.lua` |
| Same item/provider/revision is queried once | `tools/test_runtime_caches.lua` |
| Runtime caches and eviction queues stay bounded | `tools/test_runtime_caches.lua`, `tools/test_route_data.lua` |
| Incremental route equals synchronous exact route | `tools/test_incremental_route.lua` |
| Stale incremental job cannot publish | `tools/test_incremental_route.lua`, `tools/test_incremental_recommendations.lua` |
| Cheapest and Available semantics survive slicing | `tools/test_incremental_recommendations.lua` |
| Live current-skill color overrides static metadata | `tools/test_dynamic_recommendations.lua` |
| Acquisition-first → learned → craft transition | `tools/test_full_catalog_routes.lua` |
| Static fallback boundary remains protected | `tools/validate_phase7_guards.py` + existing optimizer error tests |
| Trainer/vendor locations remain valid | `tools/test_recipe_source_locations.lua` |
| Route details/full catalog remain valid | `tools/test_full_catalog_routes.lua`, addon structure validation |

## Structural thresholds

These are deterministic and do not depend on a particular PC:

- A burst of equivalent scheduled refresh requests may dispatch at most one expensive refresh before another request is scheduled.
- BAG_UPDATE must produce zero profession-book identity scans by itself.
- A valid warm exact recommendation must produce zero additional route-solver calls.
- One item/provider/revision combination may perform at most one underlying provider query while retained in the price cache.
- Inventory entries must remain at or below 2,048.
- Provider-price entries must remain at or below 512 and its eviction queue at or below its documented bound.
- Recommendation entries must remain at or below 8 and its eviction queue at or below its documented bound.
- Generated candidate-index entries must remain at or below 16 and its queue must remain bounded.
- Re-registering a provider under the same name/revision must create a new cache namespace.
- A stale route job must publish zero recommendation results after its dependency generation or provider instance changes.

No absolute millisecond threshold is invented here. The real-client performance thresholds must be derived from the measured before/after runs below.

## Real-client measurement procedure

Use one addon build, character, TSM/AuctionDB dataset, UI scale, and addon set for a comparison run. Enable instrumentation with `/pcapper perf on`.

Before each isolated scenario:

1. run `/pcapper perf reset`;
2. perform exactly one named action;
3. run `/pcapper perf`;
4. copy the complete summary here.

For repeated open/close memory testing, do not reset between cycles. Record the retained `heap=` and cache-entry line after every cycle. The largest route slice matters; do not average it away.

## Enchanting ~352

| Scenario | Mode | Refresh total | Largest normal phase | Largest route slice | Exact ready | Book scans | Price h/m | Recipe costs | States | Memory delta | Retained heap | Result |
| --- | --- | ---: | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | --- |
| Cold open | Static | pending | pending | n/a | n/a | pending | n/a | n/a | n/a | pending | pending | pending |
| Cold open | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Warm reopen | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Cold open | Available | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| BAG_UPDATE | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Successful craft / skill-up | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Learn recipe | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| +profession modifier change | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| TSM revision/scan change | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |

## Jewelcrafting low skill

| Scenario | Mode | Refresh total | Largest normal phase | Largest route slice | Exact ready | Book scans | Price h/m | Recipe costs | States | Memory delta | Retained heap | Result |
| --- | --- | ---: | --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | --- |
| Cold open | Static | pending | pending | n/a | n/a | pending | n/a | n/a | n/a | pending | pending | pending |
| Cold open | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Warm reopen | Cheapest | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Cold open | Available | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending | pending |

## Repeated unchanged close/open

Use at least ten unchanged Cheapest close/open cycles for the original Enchanting case.

| Cycle | Refresh total | Route solver reran? | Book scan? | Retained heap | Book entries | Inventory entries | Price entries | Recommendation entries |
| ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | pending | pending | pending | pending | pending | pending | pending | pending |
| 2 | pending | pending | pending | pending | pending | pending | pending | pending |
| 3 | pending | pending | pending | pending | pending | pending | pending | pending |
| 4 | pending | pending | pending | pending | pending | pending | pending | pending |
| 5 | pending | pending | pending | pending | pending | pending | pending | pending |
| 6 | pending | pending | pending | pending | pending | pending | pending | pending |
| 7 | pending | pending | pending | pending | pending | pending | pending | pending |
| 8 | pending | pending | pending | pending | pending | pending | pending | pending |
| 9 | pending | pending | pending | pending | pending | pending | pending | pending |
| 10 | pending | pending | pending | pending | pending | pending | pending | pending |

Acceptance requires no monotonic retained-heap growth attributable to stale route jobs or unbounded cache keys. Small Lua GC fluctuations are expected; record the actual sequence rather than selecting the lowest value.

## Cancellation/event matrix

While an exact route is visibly calculating, perform each action separately.

| Action during calculation | Expected | Actual |
| --- | --- | --- |
| Close profession window | old job cancelled; no later UI overwrite | pending |
| Reopen profession window | new/current job or valid exact cache owns UI | pending |
| Move one reagent | inventory generation changes; old job cannot publish | pending |
| Cheapest → Available | mode generation changes; old Cheapest job cannot publish | pending |
| Cheapest/Available → Static | pending optimizer work cannot replace Static | pending |
| Skill-up | skill generation changes; old job cannot publish | pending |
| Learn recipe | profession snapshot invalidated/rescanned; acquisition guidance updates | pending |
| TSM provider revision changes | old provider-revision job/result cannot publish as current | pending |

## UI/fallback matrix

| Check | Actual |
| --- | --- |
| No price provider still leaves Static usable | pending |
| Compare opens with current exact result | pending |
| Full route shows coherent exact route only | pending |
| Acquisition-first recommendation has correct source guidance | pending |
| Learned recipe removes acquire-first guidance | pending |
| Trainer/vendor alternatives remain listed | pending |
| Show on map opens the correct marked location | pending |
| Route details stay inside the main frame | pending |

## Cheapest inventory semantics

Task 36 intentionally does not change the product semantics:

- owned ordinary reagents currently affect Cheapest route economics;
- ordinary-reagent depletion is not carried as full route state;
- the final Shopping Plan aggregates total requirements more accurately than the route-state approximation.

Changing Cheapest to optimize a pure market route and apply owned inventory only in the Shopping Plan requires a separate explicitly approved product task.

## Final threshold decision

Pending real-client data.

After filling the tables, record:

- the original severe Enchanting cold/warm behavior;
- the improved cold refresh cost and largest single route slice;
- the improved unchanged warm-open cost;
- whether the original freeze/long blocking interaction is materially reduced;
- whether retained heap stabilizes across repeated opens;
- any measured bottleneck that still dominates.

If a remaining bottleneck is material, queue a separate evidence-based follow-up task rather than expanding Task 36 silently.


## Task 37 review findings

The Phase 7 holistic review is recorded in [phase7-review.md](phase7-review.md).

The review fixed two concrete Phase 7 defects:

- provider objects re-registered under the same name/revision could share stale raw-price cache identity and evade pending-job invalidation;
- generated profession/modifier candidate indexes could accumulate large 450-skill tables for the whole session.

The review also found a larger semantic issue introduced deliberately by Task 29: recipe learning is modeled as a segment activation instead of permanent one-time route state. That avoids state explosion, but a route that learns recipe B, switches to A, and later returns to B can conservatively pay the acquisition cost again. Task 38 is queued to restore true one-time acquisition semantics without returning to the old combinatorial state model.

A separate maintainability follow-up, Task 39, is queued for the duplicated legacy heap solver versus the layered job engine.
