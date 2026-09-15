# Task 32 runtime performance baseline

Status: real-client capture required

This file is the measurement record for Task 32. The instrumentation and deterministic tests are implemented, but the numbers below must come from the actual WoW 3.3.5 client. CI, synthetic Lua fixtures, and guessed timings are not substitutes for the real client, so no fabricated baseline values are committed here.

## Instrumentation

Performance instrumentation is off by default. Use:

- `/pcapper perf` — enable instrumentation if needed and print the latest summary.
- `/pcapper perf on` — enable instrumentation.
- `/pcapper perf off` — disable instrumentation.
- `/pcapper perf reset` — clear all samples/counters and leave instrumentation enabled.

The summary records total refresh time, Lua memory delta, refresh reason/category, refresh-request amplification, profession-book scan time, recipe-cache construction, optimizer-input construction, generated candidate-index build/reuse, candidate ranking, route-solver time and explored states, shopping-plan time, UI render time, unique price lookups, recipe-cost evaluations, and relevant cache hit/miss counts.

The category distinguishes cold profession opens, warm reopen/cache hits, bag refreshes, skill/profession changes, learned-recipe refreshes, mode changes, multiple coalesced events, and detectable price-provider revision changes.

## Capture procedure

Use the same character, addon build, TSM/AuctionDB data, and UI state throughout one baseline run. Before each named case, run `/pcapper perf reset`, perform exactly the action described, then run `/pcapper perf` and copy the summary into the table.

For repeated-open variance, enable/reset once, then perform at least five close/reopen cycles without changing bags, skill, provider data, or mode. Record all five total times rather than only the best result.

For BAG_UPDATE amplification, make one controlled bag change while the profession window is open. Record both `requests-since-last` and accumulated BAG_UPDATE requests so one user action producing several events is visible.

## Enchanting baseline

Target state: approximately 352 trained Enchanting, matching the reported lag case.

| Case | Total ms | Largest non-container phase | Route states | Recipe-cost evals | Unique price lookups | Memory delta KB | Refresh requests for action | Notes |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |
| Static cold open | pending | pending | pending | pending | pending | pending | pending | Real client required |
| Cheapest cold open | pending | pending | pending | pending | pending | pending | pending | Real client required |
| Cheapest warm reopen | pending | pending | pending | pending | pending | pending | pending | Real client required |
| Available cold open | pending | pending | pending | pending | pending | pending | pending | Real client required |
| BAG_UPDATE while open | pending | pending | pending | pending | pending | pending | pending | Real client required |
| Successful craft / skill update | pending | pending | pending | pending | pending | pending | pending | Capture if practical |

Repeated unchanged opens:

| Repeat | Total ms | Category | Recommendation cache h/m | Generated-index cache h/m | Memory delta KB |
| --- | ---: | --- | --- | --- | ---: |
| 1 | pending | pending | pending | pending | pending |
| 2 | pending | pending | pending | pending | pending |
| 3 | pending | pending | pending | pending | pending |
| 4 | pending | pending | pending | pending | pending |
| 5 | pending | pending | pending | pending | pending |

## Jewelcrafting baseline

Target state: the currently reported low-skill Jewelcrafting character state.

| Case | Total ms | Largest non-container phase | Route states | Recipe-cost evals | Unique price lookups | Memory delta KB | Refresh requests for action | Notes |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |
| Static cold open | pending | pending | pending | pending | pending | pending | pending | Real client required |
| Cheapest cold open | pending | pending | pending | pending | pending | pending | pending | Real client required |
| Cheapest warm reopen | pending | pending | pending | pending | pending | pending | pending | Real client required |

## Gate conclusions

Route solver dominant on cold open: **undetermined until the real-client matrix is captured**.

Event amplification present: **undetermined until BAG_UPDATE and skill-update cases are captured**.

Task 33 must not begin from a performance assumption. Fill this report with the real-client measurements first, then use the dominant measured phase and event-amplification evidence to drive the next task.
