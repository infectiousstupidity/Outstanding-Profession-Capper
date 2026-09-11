# Task 05 — Recipe acquisition model

Status: DONE  
Phase: 2 — Recipe knowledge and acquisition  
Depends on: none

## Goal

Represent how recipes and profession ranks are obtained so the optimizer never recommends an inaccessible recipe as though it were already known.

## Acquisition types

Implemented support for:

- already learned
- profession trainer
- vendor
- limited-stock vendor
- Auction House recipe/item
- reputation requirement
- quest
- world/drop source
- unknown/manual acquisition

## Data model

`RecipeAcquisition.lua` supports, where known:

- recipe spell ID or a stable profession-rank key
- profession / entry kind
- source type and source/NPC name
- source/trainer/vendor ID
- zone and coordinates
- faction restriction
- reputation faction/standing
- purchase/training price
- required profession skill
- trainer rank/tier
- recipe item ID
- limited-stock flag and notes

Profession-rank training uses the same registration/validation/resolution model as recipes.

## Route behavior

Resolution distinguishes:

- `immediately_usable` — already learned
- `trainable_now` — verified trainer source with a known current gold cost
- `purchasable_now` — verified vendor or currently listed Auction House recipe item
- `obtainable` / `obtainable_non_gold` — limited stock, reputation, quest, or drop
- `unavailable` / `unavailable_unknown` — unmet requirements or unknown/manual source

Limited-stock, reputation, quest, drop, and unknown records never become free immediate acquisitions.

The Phase 3 recipe-cost engine now delegates acquisition decisions to this model when it is loaded. Its older inline acquisition path remains only as a compatibility fallback for isolated tests/callers.

## Built-in data

The bundled seed is intentionally conservative. It currently contains verified Enchanting trainer rows taken from the public AzerothCore WotLK `npc_trainer` data, including spell 7420, spell 7426, and profession-rank training spell 7416.

This task does not copy another addon's acquisition database. Missing sources remain unknown until verified or supplied by the optional runtime provider in Task 06.

## Automated validation

`tools/test_recipe_acquisition.lua` covers:

- learned-state override
- trainer availability, price, source ID, and +skill requirement handling
- vendor source/location/cost
- limited stock staying non-guaranteed
- reputation/drop never becoming zero-cost instant routes
- current Auction House recipe-item pricing
- unknown source exclusion
- static-guide explanation API
- malformed vendor/AH/limited-stock metadata rejection

Existing Phase 3 cost-engine tests continue to validate compatibility.

## Manual checks

This task does not activate the dynamic recommendation UI. The deterministic static guide is unchanged, so there is no new in-game user-facing path to test independently before Task 10.

## Acceptance criteria

- PASS — the static guide can query `explainRecipeAcquisition` for the exact state/reason/source of a missing recipe.
- PASS — trainer/vendor records expose source/location fields and acquisition price where known.
- PASS — unknown/drop/reputation/limited-stock acquisition cannot be mistaken for free instant access.
- PASS — malformed acquisition entries fail validation.
- PASS — profession-rank training can use the same model.

## Commit

`feat: model recipe and trainer acquisition sources`
