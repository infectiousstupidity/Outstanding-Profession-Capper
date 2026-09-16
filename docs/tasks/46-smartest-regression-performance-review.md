# Task 46 — Smartest end-to-end regression and performance review

Status: BLOCKED  
Phase: 9 — Resale-aware Smartest optimization  
Depends on: Tasks 40–45

## Goal

Review the completed Smartest feature as one system, prove it did not reintroduce profession-window lag or route-correctness problems, and close the phase only with recorded evidence.

This task includes implementation of concrete regression/performance fixes discovered by the review, but must not silently redesign the product objective.

## Required matrix

Exercise:

- Static;
- Cheapest;
- Smartest;
- Cheapest + Available now;
- Smartest + Available now.

At minimum test Enchanting around the previously problematic high-skill range and another profession to prove non-Enchanting paths remain unaffected.

Cover:

- cold open;
- warm reopen;
- repeated close/open;
- bag change;
- skill-up;
- learned recipe;
- TSM provider revision change;
- missing price provider;
- stale/suspicious/missing scroll price;
- direct-vs-vellum switch;
- Compare;
- Full route;
- shopping plan;
- repeat/action state.

## Correctness review

Explicitly verify:

1. Cheapest route results remain unchanged from the pre-Phase-9 regression corpus.
2. Static remains price-independent.
3. Available-now is only a constraint.
4. Smartest never produces a negative route edge.
5. Low skill-up chance cannot win merely because it creates more profitable failed crafts.
6. Resale never offsets recipe acquisition, training or reusable-tool cost.
7. Suspicious/stale/missing resale data cannot reduce optimization cost.
8. Generated metadata does not misclassify rods/personal enchants as vellum scroll crafts.
9. Vellum requirements reconcile with the shopping plan.
10. A stale route job/repeat state cannot publish after objective, inventory, skill or provider revision changes.

## Performance review

Use `/pcapper perf` and existing Phase 7 instrumentation.

Record:

- cold-open total work;
- warm-open total work;
- largest route slice;
- total route work;
- recipe-cost evaluations;
- provider-price cache hits/misses;
- number of new scroll price lookups;
- number of vellum price lookups;
- explored states;
- memory delta and retained cache counts.

The new feature must not:

- scan the entire Enchanting catalog at window open;
- perform tooltip parsing for scroll/vellum classification;
- query TSM repeatedly for the same item/provider revision;
- add an unbounded cache;
- materially worsen warm-open behavior.

If Smartest adds a measurable hot-path regression, fix it using evidence. Do not preemptively add caches.

## Economic sanity fixtures

Include deterministic fixtures demonstrating:

- Gatherer vs Exceptional Spellpower at the same skill point with their actual modeled skill-up chances;
- a cheap direct enchant beating an unprofitable vellum path;
- a profitable scroll path flooring effective cost at zero;
- two zero-cost paths where higher skill-up chance wins before larger surplus;
- no-demand data cannot be invented from auction count.

## Documentation

Update:

- `TASKS.md`;
- all Phase 9 task statuses/evidence;
- relevant user-facing documentation for Smartest/Available behavior;
- performance report with before/after Phase 9 measurements.

Document known limitations clearly, especially:

- listing value is not guaranteed sale value;
- market saturation is not modeled without verified sales data;
- AH fees remain excluded unless verified/configured;
- repeat vellum automation is limited by actual client behavior.

## Required handoff workflow

### Agent 1 — end-to-end validation/fix pass

Run the matrix, add missing regression coverage, implement only concrete defects/performance fixes found, record measurements, commit/push, and set Task 46 to `REVIEW`.

### Agent 2 — independent holistic review

Review the entire Phase 9 implementation, not just Task 46's diff.

Attempt to falsify the economic assumptions and break:

- objective ordering;
- price confidence;
- metadata classification;
- availability;
- caches;
- incremental job cancellation;
- shopping-plan reconciliation;
- UI wording.

If clean, record review evidence and mark Task 46 `DONE`.

If findings exist, record each concrete defect, mark `FIX`, and hand off to Agent 3.

### Agent 3 — final fixes

Fix only the recorded findings, rerun the affected matrix plus full repository validation, update measurements if behavior changed, record evidence, and mark Task 46 `DONE`.

If a finding requires a substantial new product model such as sales velocity, market saturation modeling or TSM Accounting integration, queue a new task instead of expanding Phase 9.

## Acceptance criteria

- Tasks 40–45 are DONE through their review/fix gates.
- Full repository validation passes.
- Cheapest and Static regressions are clean.
- Smartest and availability semantics match the documented deterministic rules.
- No negative route edge exists.
- No serious warm-open/per-frame performance regression is introduced.
- Price and vellum lookups are bounded and cache effectively.
- Required in-game Enchanting checks pass.
- Phase 9 measurements and known limitations are documented.
- Agent 2 review is clean or every finding was resolved by Agent 3.

## Evidence

### Agent 1 validation/fixes

Pending.

### Agent 2 review

Pending.

### Agent 3 final fixes

Pending.
