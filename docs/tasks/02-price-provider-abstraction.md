# Task 02 — Price provider abstraction

Status: QUEUED  
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

## Commit

Suggested message: `feat: add profession price provider abstraction`
