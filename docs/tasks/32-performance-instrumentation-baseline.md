# Task 32 — Runtime performance instrumentation and baseline

Status: IN PROGRESS — instrumentation implemented; real-client baseline capture pending  
Phase: 7 — Runtime performance hardening  
Depends on: Tasks 29 and 30

## Goal

Stop guessing about the profession-window lag. Add low-overhead instrumentation that can identify exactly where time and memory are spent on the real WoW 3.3.5 client, and establish a reproducible baseline before changing execution behavior.

This task is measurement only. Do not change recommendation semantics, route selection, cache invalidation, or event behavior except where required to observe it.

## Why this task comes first

The current code already contains several optimizations: generated route topology, candidate scoping, layered dynamic programming, bounded route-cost caching, and completed recommendation caching. Earlier assumptions that every live reagent or every catalog recipe was scanned on every open were too broad.

The remaining bottleneck must therefore be measured rather than inferred.

## Instrumentation requirements

Add a small internal performance module or equivalent isolated code. Do not scatter ad-hoc print statements through hot paths.

Use `debugprofilestop()` when available on the 3.3.5 client. A test/runtime fallback may use `GetTime()` or `os.clock()`, but production timing should prefer the native profiler.

Record at minimum:

- total refresh time;
- profession-book scan / `withUnfilteredTradeSkill`;
- `buildRecipeCache`;
- optimizer-input construction;
- generated candidate-index construction/reuse;
- current candidate ranking;
- unique price lookups;
- recipe-cost evaluations;
- route solver time;
- route `exploredStates`;
- shopping-plan time;
- UI render/update time;
- number of refresh requests;
- refresh reason/event;
- cache hit/miss counts where relevant;
- Lua memory before/after the refresh using `collectgarbage("count")`.

Instrumentation must be disabled by default and cheap when disabled.

## User-facing debug access

Add or extend a debug command such as:

`/pcapper perf`

The command should provide a compact summary of the most recent refresh and accumulated counters. Add a reset form, for example:

`/pcapper perf reset`

Do not spam chat automatically during normal gameplay.

The output must distinguish at least:

- cold profession open;
- warm reopen / cache hit;
- refresh caused by `BAG_UPDATE`;
- refresh caused by skill/profession change;
- refresh caused by learning a recipe;
- price-provider revision change when detectable.

## Baseline matrix

Document manual measurements for these cases before Task 33 starts:

1. Enchanting around the currently reported 352 skill state:
   - Static cold open;
   - Cheapest cold open;
   - Cheapest warm reopen;
   - Available cold open;
   - bag change while open;
   - one successful craft/skill update if practical.
2. Jewelcrafting around the currently reported low-skill state:
   - Static cold open;
   - Cheapest cold open;
   - Cheapest warm reopen.
3. At least five repeated opens of the same unchanged profession to expose variance.

Capture:

- total milliseconds;
- largest phase;
- explored route states;
- recipe-cost evaluations;
- unique price lookups;
- memory delta;
- number of expensive refreshes caused by one user action.

Do not invent a universal latency target in this task. Record the actual baseline first.

## Automated regression coverage

Add deterministic tests for the instrumentation itself where practical:

- disabled instrumentation does not affect recommendation results;
- timers/counters can be reset;
- nested or failed measured operations do not leave instrumentation in a corrupt state;
- a refresh reason is recorded explicitly rather than inferred from the final state.

Tests must remain Lua 5.1 compatible.

## Deliverable

Commit:

- instrumentation code;
- tests;
- command/help text if required;
- a short baseline report under `docs/performance/` or another clearly named documentation location.

The baseline report is part of the acceptance criteria. This task is not complete with instrumentation code alone.

## Acceptance criteria

- Full repository validation passes.
- Instrumentation is off by default.
- Normal recommendation behavior is unchanged.
- A real-client baseline identifies the dominant cold-open and refresh costs.
- The report includes both Enchanting and Jewelcrafting measurements.
- The report explicitly states whether the route solver is actually the dominant stall before Task 35 is attempted.
- The report records any event amplification, such as one user action causing multiple expensive refreshes.

## Do not do in this task

- Do not rewrite the route solver.
- Do not change the definition of Cheapest.
- Do not remove inventory from route economics.
- Do not add guessed caching rules.
- Do not hide lag with delayed rendering before the actual source of the lag is measured.
