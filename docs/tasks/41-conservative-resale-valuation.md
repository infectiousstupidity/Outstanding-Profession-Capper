# Task 41 — Conservative resale valuation

Status: BLOCKED  
Phase: 9 — Resale-aware Smartest optimization  
Depends on: Task 40

## Goal

Add a conservative, explicit resale-value primitive to the existing price-provider layer.

The result is an estimate for optimization, not a claim that an item will sell.

This task must not change route selection yet.

## Product rule

TSM AuctionDB listing values are market evidence, not completed-sale evidence.

The addon must never present `DBMarket`, `DBMinBuyout`, `DBRecent`, or `DBHistorical` as guaranteed sale proceeds.

The API should expose both:

- a conservative optimization credit;
- enough metadata/confidence for the UI to explain the estimate.

## Required API

Extend the existing price abstraction with a resale-oriented choice, for example through the existing unit-price chooser or a dedicated helper.

The normalized result must distinguish at least:

- estimated resale value;
- optimization credit;
- confidence/reason;
- source price type;
- freshness/age;
- suspicious-price state.

Do not add another external-price provider abstraction.

## Conservative credit rules

For the initial implementation:

1. Missing price data gives zero optimization credit.
2. Suspicious prices give zero optimization credit.
3. Too-old data gives zero optimization credit.
4. Historical-only evidence may be displayed as context but must not reduce route cost.
5. Fresh current listing evidence may produce credit, but the estimate must be capped conservatively when multiple current market values are available.
6. The implementation must not claim that auction count proves demand or sell-through.
7. The value is before AH fees unless the exact ChromieCraft/AzerothCore fee configuration is verified from a reliable source and represented explicitly.

Document the exact formula in code and tests. Do not hide it behind a vague "smart score".

A reasonable initial policy is to use a fresh non-suspicious current market estimate and cap it by fresh min-buyout when both exist. If the implementation uses another formula, Agent 1 must justify it in the evidence section and Agent 2 must review that decision explicitly.

## No sale-rate guessing

Do not fabricate:

- sale probability;
- sale rate;
- days to sell;
- regional demand;
- expected completed-sale price.

If the installed 3.3.5 TSM backport later exposes verified Accounting/sale-history data, that can be a separate enhancement task.

## Cache behavior

Reuse the existing provider/revision item-price cache.

Do not create a second persistent resale cache unless performance measurements prove one is necessary.

A provider revision change must naturally invalidate/rekey resale evidence through the existing price cache.

## Tests

Cover at least:

- fresh market + min-buyout;
- only fresh min-buyout;
- stale values;
- too-old values;
- suspicious low/high ratios;
- historical-only data;
- missing data;
- provider revision change;
- cached repeated lookups;
- no negative/NaN values;
- the UI-facing metadata accurately says why credit was or was not granted.

## Required handoff workflow

### Agent 1 — implement

Implement only Task 41, run full validation, record evidence, commit/push, and move the task to `REVIEW`. Do not start Task 42.

### Agent 2 — independent review

Review the resale formula, TSM assumptions, freshness behavior, suspicious-price handling, cache reuse, tests, and wording.

If clean, record evidence and mark `DONE`.

If findings exist, record them, mark `FIX`, and hand off to Agent 3.

### Agent 3 — fix findings only

Resolve the recorded findings, rerun Task 41 and full validation, record evidence, and mark `DONE`. Only then may Task 42 begin.

Substantial new demand/sales modeling belongs in a new task.

## Acceptance criteria

- Resale value is explicitly an estimate, not a guaranteed sale.
- Suspicious, missing and too-old data cannot reduce optimization cost.
- Historical-only data cannot reduce optimization cost.
- The formula is deterministic and tested.
- Existing revisioned price caching is reused.
- No new unbounded cache or repeated TSM scan path is introduced.
- Full repository validation passes.
- Agent 2 review is clean or all findings were fixed by Agent 3.

## Evidence

### Agent 1 implementation

Pending.

### Agent 2 review

Pending.

### Agent 3 fixes

Pending.
