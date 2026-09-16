# Task 44 — Smartest mode UI and economic explanations

Status: BLOCKED  
Phase: 9 — Resale-aware Smartest optimization  
Depends on: Task 43

## Goal

Expose the new objective model clearly without turning the panel into an analytics dashboard.

The user must be able to understand why Smartest chose a recipe over Cheapest.

## Mode controls

Replace the ambiguous top-level Available mode with:

- Cheapest;
- Smartest;
- Static;

and a separate concise control for:

- Available now only.

The availability control applies to Cheapest or Smartest and is irrelevant/disabled in Static.

Preserve the current compact visual hierarchy and avoid adding a large settings panel to the main recommendation.

## Recommendation explanation

For a Smartest Enchanting recommendation, display the important economics in plain terms:

- exact skill-up chance or expected-crafts context;
- enchanting material cost;
- chosen vellum and vellum cost when the scroll path is selected;
- gross craft cost;
- estimated scroll resale value;
- effective leveling cost;
- estimated surplus when positive;
- confidence/warning when resale evidence is weak or unavailable.

Do not label listing-derived surplus as guaranteed profit.

Use wording such as:

- "Estimated resale";
- "Estimated surplus";
- "Before AH fees" when fees are not modeled;
- "Market estimate, not guaranteed sale proceeds" in an appropriate detail/help location.

Do not use fake precision.

## Direct vs scroll explanation

When Smartest chooses the vellum path, make it clear that the recommendation is:

"Enchant onto [Vellum] to create [Scroll]"

rather than simply applying the enchant to an item.

When direct is economically better, do not show a vellum as a required material.

## Compare and Full route

Update Compare and Full route so the same objective can be explained consistently.

Compare should allow the user to see why, for example:

- Gatherer has a higher skill-up chance;
- Exceptional Spellpower may have better effective economics.

Do not hide the trade-off behind a single unexplained "Smart score".

Full route totals should distinguish at least:

- gross leveling spend/value;
- estimated resale value credited;
- effective leveling cost;
- estimated surplus.

Keep the layout compact.

## Static and Cheapest

Static UI remains deterministic and price-independent.

Cheapest UI must not start showing resale-adjusted cost as if Cheapest used it.

Resale context may be shown as secondary information only if it cannot confuse the objective.

## Accessibility and compatibility

Preserve:

- WoW 3.3.5 / Lua 5.1;
- compact/expanded detail modes;
- ElvUI compatibility;
- existing native item tooltips;
- frame bounds;
- keyboard/mouse behavior.

No new panel may overflow the main frame.

## Tests

Add/extend deterministic UI-model tests for:

- Cheapest / Smartest / Static control state;
- Available-now toggle behavior;
- saved-setting migration presentation;
- Smartest direct recommendation;
- Smartest vellum recommendation;
- missing resale price;
- suspicious resale price;
- zero effective cost with positive surplus;
- Compare explanation;
- Full route totals;
- Static remains unaffected.

Manual visual verification remains required.

## Required handoff workflow

### Agent 1 — implement

Implement Task 44 only. Run UI/model/full validation, record evidence, commit/push, set `REVIEW`. Do not start Task 45.

### Agent 2 — independent review

Review clarity, objective correctness, ambiguous wording, overflow, mode/toggle behavior, Compare/Full route consistency and regression risk.

If clean, mark `DONE`.

If findings exist, record them, mark `FIX`, hand off to Agent 3.

### Agent 3 — fix findings only

Fix the recorded issues, rerun tests and required visual checks, record evidence, mark `DONE`, then Task 45 may begin.

## Acceptance criteria

- The UI exposes Cheapest, Smartest and Static clearly.
- Available-now is clearly a filter, not a competing objective.
- Smartest explains direct vs vellum execution.
- Listing-derived value is described as estimated, not guaranteed.
- Compare and Full route expose the same economics consistently.
- No regression to Static/Cheapest visual semantics.
- Frame/layout compatibility is preserved.
- Full validation and required in-game visual checks pass.
- Review/fix gate is complete.

## Evidence

### Agent 1 implementation

Pending.

### Agent 2 review

Pending.

### Agent 3 fixes

Pending.
