# Task 23 — Full-catalog cheapest-route optimization

Status: DONE  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Tasks 07, 08, 09, 20, 21, and 22

## Goal

Make dynamic recommendations optimize across all usable WotLK recipes, including recipes the character has not learned yet.

This task is the behavior change that fixes the current known-recipes-only limitation.

## Optimization input

Replace the current live-only recipe input with a merged catalog input:

`bundled recipe catalog + live profession book + character state + acquisition state + current prices`

Rules:

- all catalog recipes for the current profession are candidates
- only recipes actually present in the live profession book are marked learned
- live data overlays known recipes
- unknown recipes keep bundled reagents/output/difficulty/acquisition metadata
- invalid/incomplete recipes are excluded with explicit reasons rather than guessed

## Route semantics

The globally cheapest complete route should become authoritative when available.

Do not choose the immediate recipe with a separate greedy ranking that can disagree with the full route.

The route cost must include:

- expected material cost per skill-up
- inventory-aware immediate gold need
- one-time recipe acquisition cost
- reusable tool/rod costs
- profession-rank training costs
- current recipe-item AH price when that is the chosen acquisition method

The first route step may therefore be conceptually:

`learn/buy recipe -> craft recipe`

rather than simply "craft a known recipe."

## Required scenario

A deterministic regression fixture must cover this exact behavior:

1. Start below a recipe unlock threshold.
2. Craft the cheapest available recipe until the threshold.
3. A previously unknown trainer/vendor recipe becomes obtainable.
4. Its acquisition cost plus remaining material cost makes it the cheapest continuation.
5. The route switches to it.

Also test the inverse where the recipe's acquisition cost makes staying with a known recipe cheaper.

## Current recommendation behavior

When the selected recipe is already learned, preserve normal craft behavior.

When the selected recipe is not learned:

- do not attempt to select/craft a nonexistent live profession-book entry
- expose the acquisition as the required next action
- keep the planned craft segment and costs attached so Task 24 can explain what happens after learning it
- refresh naturally after `TRADE_SKILL_UPDATE` once the recipe becomes known

## Fallback

The deterministic static guide remains the safe fallback when the full dynamic route cannot be computed due to missing required price/runtime data.

An unavailable conditional recipe must not make the whole addon unusable if another valid route exists.

## Automated validation

Add integration tests for:

- known recipe vs cheaper trainer recipe
- trainer acquisition too expensive, so known recipe wins
- vendor recipe
- owned recipe item
- AH-listed recipe item
- unavailable drop/quest/limited-stock recipe excluded from guaranteed route
- route that unlocks a recipe at a future skill
- Blood Elf +10 Enchanting behavior
- profession-rank training followed by newly available recipes
- route remains stable when no external recipe addon is installed
- comparison candidates include eligible unknown recipes
- fallback remains available when prices are incomplete

## Acceptance criteria

- Cheapest-route optimization no longer means "cheapest recipe I already know."
- All reliably obtainable catalog recipes participate.
- Recipe acquisition cost can change which route wins.
- The route's first action/segment is the source of truth for the main recommendation.
- No Ackis installation changes optimizer coverage.


## Implementation result

Implemented on master with the post-freeze performance protections preserved.

- Optimizer input now merges the bundled profession catalog with the live profession book.
- Unknown but reliably obtainable recipes participate before they are learned.
- The full route may cross profession-rank training boundaries up to the highest cap the character's level can currently reach.
- A complete global route overrides the greedy current-step recommendation, so future unlocks can make the addon tell the player to stop and acquire a better recipe.
- Recipe acquisition is charged once in route state and exposed on the selected segment for Task 24.
- Available mode constrains the immediate action only; it does not require every future material through 450 to be on the Auction House at the same time.
- The pass-local recipe and price caches from the performance fix remain in use.
- If the complete route cannot be proven, the existing immediate dynamic recommendation remains available with an explicit incomplete-route reason rather than freezing or becoming unusable.

Automated regression coverage is in `tools/test_full_catalog_routes.lua`.
