# Task 36 — End-to-end performance regression hardening

Status: QUEUED  
Phase: 7 — Runtime performance hardening  
Depends on: Tasks 32, 33, 34 and 35

## Goal

Treat the new runtime behavior as a system, not a collection of isolated optimizations.

Re-run the original lag scenarios, close correctness gaps introduced by the new lifecycle/caches/scheduler, and add regression gates so future feature work cannot casually return to synchronous full recomputation.

## Required review matrix

Exercise all three recommendation modes:

- Static;
- Cheapest;
- Available.

Exercise at least:

- Enchanting around the original 352-state report;
- Jewelcrafting around the original low-skill report;
- cold open;
- warm reopen;
- repeated close/open;
- `BAG_UPDATE`;
- successful craft/skill change;
- learning a recipe;
- +profession modifier change;
- TSM provider revision/scan change where available;
- no-price-provider/fallback behavior;
- Compare;
- Full route;
- acquisition-first recommendation;
- trainer/vendor map-location UI.

The performance work must not regress the recently added source-location or route-details behavior.

## Correctness checks

Explicitly verify:

- no stale result after an input generation changes;
- no recipe-book cache leakage across professions/characters in the same UI session;
- no stale price result after provider revision changes;
- no inventory-dependent route reuse under the current Cheapest semantics;
- Static fallback remains independent from optimizer failure;
- Available still requires the existing availability evidence;
- current live recipe color overrides bundled difficulty when appropriate;
- learned/unlearned transitions still update acquisition guidance correctly.

## Performance checks

Use the Task 32 instrumentation and append final measurements to the baseline report.

Report, not just assert:

- cold-open total work;
- warm-open total work;
- maximum single-frame/slice cost;
- route total duration;
- profession-scan count per user action;
- price lookups and cache hit rate;
- recipe-cost evaluations;
- explored states;
- memory delta;
- retained cache memory after repeated opens.

Do not hide a regression by averaging several frames. The largest individual UI-thread slice matters.

## Regression thresholds

Derive practical thresholds from the measured baseline and improved implementation rather than inventing unrealistic absolute numbers.

However, add deterministic structural gates where possible, such as:

- bag-only refresh cannot call the full profession scanner;
- unchanged warm-open cannot invoke the route solver when a valid exact result exists;
- stale incremental job cannot publish;
- price provider is not queried repeatedly for the same item/revision inside a warm path;
- cache sizes remain bounded;
- one UI event cannot schedule multiple equivalent expensive jobs.

Document any behavior that cannot be asserted in offline tests and leave it in the manual acceptance checklist.

## Cleanup

Remove temporary profiling-only hacks, duplicate cache layers, obsolete invalidation functions, and dead synchronous paths that are no longer required.

Keep the supported `/pcapper perf` diagnostic if it remains useful, but make sure it is low-overhead and documented.

Do not perform unrelated UI redesign.

## Semantics decision note

This task must document, but not silently change, the known inventory-model tradeoff:

- Cheapest currently lets owned inventory affect route economics;
- the route solver does not model full ordinary-reagent depletion as route state;
- the final Shopping Plan aggregates requirements more accurately.

If changing Cheapest to market-route optimization with inventory applied only to the shopping plan is desired, create a separate future task with explicit product approval. It is not part of this performance hardening phase.

## Acceptance criteria

- Full repository validation passes.
- All Phase 7 automated regression cases pass.
- Original severe Enchanting open/close lag is materially reduced in real-client measurements.
- Repeated unchanged opens do not repeat expensive work unnecessarily.
- No stale result or cache-correctness regression is found in the event matrix.
- Memory remains stable across repeated open/close cycles.
- Performance report contains clear before/after measurements.
- Any remaining bottleneck is documented with evidence and a queued follow-up task rather than hidden.
