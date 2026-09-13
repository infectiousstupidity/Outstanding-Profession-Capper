# Task 25 — Full recipe optimization coverage and regression QA

Status: QUEUED  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Tasks 20, 21, 22, 23, and 24

## Goal

Prove that self-contained full-catalog optimization is complete, conservative, and does not regress the existing addon.

This task closes the feature only after deterministic coverage and in-game checks pass.

## Deterministic coverage gates

CI must validate for all ten supported professions:

- canonical recipe catalog coverage
- difficulty metadata coverage for every optimizer-eligible recipe
- acquisition coverage for every optimizer-eligible recipe
- reagent/output integrity
- recipe-item linkage where applicable
- duplicate/conflicting acquisition records
- profession/rank boundaries
- no accidental Cataclysm+ records
- no Ackis runtime dependency
- reproducible generated data

Explicit reviewed exclusions must be machine-readable and documented; silent gaps are not allowed.

## Route regression matrix

Add fixtures covering representative leveling ranges and acquisition types across:

- Alchemy
- Blacksmithing
- Enchanting
- Engineering
- Inscription
- Jewelcrafting
- Leatherworking
- Tailoring
- Cooking
- First Aid

Include edge cases for:

- recipe unlock exactly at the next skill point
- profession-rank cap boundary
- active +profession modifiers
- expensive training vs cheaper known recipe
- cheaper unknown trainer/vendor recipe
- AH recipe item available/unavailable
- owned recipe item
- limited-stock vendor
- reputation/faction restriction
- quest/drop/world-drop source
- missing/stale material prices
- reusable tools and Enchanting rods
- equivalent Greater/Lesser Essence purchasing

## Performance

Measure route construction with the full recipe catalog.

The profession UI must remain responsive on the 3.3.5 client. If full-catalog evaluation is too expensive:

- pre-index recipes by profession and useful skill ranges
- cache immutable joins between catalog/difficulty/acquisition metadata
- invalidate only on meaningful state/price changes

Do not sacrifice correctness by reverting to the live-known recipe subset.

## In-game acceptance

Perform documented checks with at least several professions and include one real unknown-recipe transition:

1. addon recommends an unlearned but cheaper recipe,
2. source/cost are correct,
3. player learns/buys it,
4. addon refreshes,
5. recipe becomes the craft recommendation,
6. route totals update correctly.

Also verify operation without:

- Ackis Recipe List
- TSM/AuctionDB

Without a price provider, the existing deterministic/static fallback should remain usable.

## Documentation cleanup

Update:

- `README.md`
- `TASKS.md`
- relevant task docs
- changelog/release notes as appropriate

Remove stale wording implying that dynamic optimization only considers live/known recipes or needs an external recipe database.

## Acceptance criteria

- Full recipe/acquisition coverage validators pass.
- All regression fixtures pass under Lua 5.1.
- Existing addon validation passes.
- In-game unknown-recipe acquisition -> learning -> crafting flow is verified.
- No Ackis dependency remains.
- Static fallback remains functional when dynamic pricing cannot run.
- The feature is considered complete only after all manual acceptance notes are recorded.
