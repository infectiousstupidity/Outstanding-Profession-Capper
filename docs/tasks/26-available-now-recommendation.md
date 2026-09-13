# Task 26 — Available-now recipe recommendation

Status: IN PROGRESS  
Phase: 4 — User-facing integration  
Depends on: Tasks 03, 07, 10

## Goal

Give the player an immediate alternative when the mathematically cheapest recipe depends on a material that is not currently listed.

The UI should answer two different questions without conflating them:

- **Cheapest** — cheapest expected skill-up using usable current/stale price data.
- **Available** — cheapest orange/yellow skill-up whose missing materials have current purchase sources in a fresh scan.
- **Static** — deterministic fallback guide.

## Availability rule

A recipe qualifies for **Available** when every missing reagent is one of:

- already owned in sufficient amount for the evaluated application;
- purchasable from a vendor;
- represented by an auction purchase choice backed by a **fresh** price-provider scan.

Greater/Lesser Essence substitutions from Task 14 count using the actual selected purchase form.

Stale AH listings are deliberately rejected by Available mode even though their prices may remain usable in Cheapest mode.

If a price provider exposes exact available quantity, reject a purchase whose known quantity is lower than the required source quantity.

### TSM 3.3.5 limitation

The currently supported WotLK TSM AuctionDB schema records the latest minimum buyout and auction count, but does not persist total stack quantity. Therefore a fresh TSM listing proves that the item was present at scan time, not that enough individual units exist for a large multi-craft segment.

Profession Capper exposes this as `fresh_listing` confidence rather than pretending exact quantity is known. The price abstraction preserves an optional `availableQuantity` field so providers/backports that expose exact depth can be stricter automatically.

## UI

Add a compact third recommendation mode:

`Cheapest | Available | Static | Compare`

In Available mode:

- recommendation reason reads `Cheapest available now`;
- comparison only contains candidates that satisfy current availability;
- full route uses the same availability constraint;
- if none qualify, clearly fall back to Static guide and explain that no orange/yellow recipe has all missing materials in a fresh AH scan.

In normal Cheapest comparison, candidates that are priced but not currently confirmed should say `not in fresh AH scan`.

## Acceptance criteria

- A cheaper recipe with stale AH material data can still win Cheapest.
- The same recipe cannot win Available.
- Available selects the next-cheapest orange/yellow candidate with fresh purchase sources.
- Owned materials do not require an AH listing.
- Vendor-backed materials count as available.
- Equivalent-essence purchases use the availability of the selected source form.
- Comparison reflects the selected mode.
- No available candidate produces an explicit fallback reason instead of silently claiming availability.
- Existing Static guide behavior is unchanged.
- Existing 6-hour `fresh` threshold remains the source of truth; do not introduce a second freshness setting.
- Lua 5.1 validation passes.

## Manual checks still required

1. Fresh-scan an AH where the cheapest recipe has one missing/unlisted reagent.
2. Confirm Cheapest still shows the economic winner when its stale price remains usable.
3. Switch to Available and confirm another orange/yellow recipe is selected.
4. Confirm every missing material for that recommendation was present in the fresh scan.
5. Verify Greater/Lesser Essence substitution still works in Available mode.
6. Verify a stale scan causes Available to refuse to claim current availability.
