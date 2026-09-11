# Task 02 — Price provider abstraction

Status: DONE  
Phase: 1 — Character and price foundations  
Depends on: Task 01

## Goal

Create a provider-neutral internal pricing API so Profession Capper is not coupled directly to TSM globals.

## Required behavior

Define an internal price result that can represent:

- item identifier/link
- current minimum buyout
- historical/market value
- vendor buy price when relevant
- source name
- scan/update timestamp when available
- stale/fresh state
- unavailable state
- reason data is unavailable

Provide a single lookup path the future optimizer can call.

## Price semantics

Do not silently treat missing data as zero.

Keep these concepts separate:

- market value of materials consumed
- gold that must be spent now
- vendor price
- AH price
- price freshness/confidence

## Scope

- Add provider registration/selection.
- Add a deterministic null provider.
- Add helper logic for choosing a usable unit price without embedding TSM-specific code.
- Add freshness thresholds/settings in one place.

## Non-goals

- No TSM integration yet.
- No route optimization.
- No UI beyond debug-safe internal state if needed.

## Acceptance criteria

- Core addon works with no pricing addon installed.
- A provider can return fresh, stale, or unavailable prices.
- Missing prices never become zero-cost ingredients.
- Unit tests/validation cover price-source selection semantics where practical.

## Implementation notes

Implemented:
- Added `PriceProvider.lua` as the single provider-neutral pricing layer loaded before settings/session/core behavior.
- Added deterministic provider registration, priority-based automatic selection, explicit provider selection, runtime availability checks, unregister support, and a permanent null fallback.
- Added `lookupItemPrice(item)` as the canonical lookup path. Provider failures are contained with `pcall` and become unavailable results rather than addon errors.
- Normalized results keep item identity/link, minimum buyout, market value, vendor buy price, source, update time, freshness, age, and unavailability reason separate.
- Non-positive and missing prices normalize to `nil`, never zero.
- Centralized freshness policy at 6 hours fresh / 72 hours maximum stale age for current auction purchase use.
- Added `chooseUsableUnitPrice` modes for market value, current spend, auction-only, and vendor-only semantics without any TSM-specific knowledge.
- Fresh current buyout is preferred for current-spend estimates; stale/current auction data is not silently promoted over a known vendor price, and auction data older than the maximum stale age is rejected for current-spend use.
- No external pricing addon or global is referenced by this task.

## Validation

Automated Lua 5.1 coverage now verifies:
- null-provider fallback with no pricing addon installed
- fresh, stale, unknown-timestamp, and unavailable results
- zero/negative prices never becoming valid prices
- market versus current-spend source selection
- stale-age rejection
- deterministic provider availability/selection
- provider exceptions degrading to unavailable results

The repository validation workflow loads the new module through the TOC and runs the new pricing test on every push/PR. No live pricing-addon check is required for this task because external integration is explicitly deferred to Task 03.

## Commit

Suggested message: `feat: add profession price provider abstraction`
