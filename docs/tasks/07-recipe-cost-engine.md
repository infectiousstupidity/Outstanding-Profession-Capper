# Task 07 — Recipe cost engine

Status: DONE  
Phase: 3 — Cost engine and optimizer  
Depends on: Tasks 02, 03, 04, 05

## Goal

Calculate the expected cost of using one recipe at a given profession skill.

## Inputs

- recipe reagents and quantities
- current character inventory
- selected unit prices from Task 02/03
- vendor prices where cheaper/appropriate
- recipe difficulty from Task 04
- acquisition requirements/cost from Task 05
- active profession-skill modifiers from Task 01

## Outputs

For a recipe at a specific skill, expose:

- material market value per craft
- gold needed now per craft
- expected skill-up chance
- expected crafts per skill-up
- expected market cost per skill-up
- expected gold-needed-now per skill-up
- acquisition cost if not yet learned
- missing/stale/unpriced material flags
- confidence/quality state

## Owned materials

Track both:

- market-value route cost, including owned materials at their opportunity value
- cash/gold needed now, excluding materials already owned

Do not treat owned materials as having no value in the market-cost total.

## Reusable/intermediate items

Do not repeatedly charge reusable tools/rods or prerequisite items that persist across later steps.

The cost API must be capable of receiving route inventory/state so later solver work can account for this.

## Implementation notes

Implemented on 2026-09-11:

- Added `RecipeCost.lua` as a pure cost/skill-up engine. It does not alter the current static guide.
- Accepts explicit recipe difficulty, reagents, acquisition state, character skill context, inventory, reusable state, and the neutral price-provider API.
- Uses effective profession skill, including active +profession modifiers, when calculating recipe usefulness.
- Models expected crafts as `1 / skill-up chance`; gray recipes are rejected.
- Preserves both market-value cost and gold-needed-now cost. Owned materials reduce only gold-needed-now.
- Compares current vendor and Auction House purchase prices and chooses the cheaper usable source explicitly.
- Missing price/acquisition metadata yields an incomplete/unavailable estimate instead of silently becoming zero.
- Reusable reagents/tools are surfaced as one-time costs and are not multiplied by expected retry crafts.
- Acquisition costs are exposed separately as one-time route costs so the solver can charge them once.

This task implements the Phase 3 engine contract before Tasks 04/05 populate production recipe metadata. Until those dependencies are complete, no live dynamic route is activated and the deterministic guide remains authoritative.

## Automated validation

`tools/test_recipe_cost.lua` covers:

- orange recipes: guaranteed one craft per point
- yellow and green expected-craft math
- gray recipes excluded
- +profession modifiers shifting effective difficulty
- owned materials preserving market value while reducing immediate gold
- vendor beating a more expensive Auction House price
- missing prices producing incomplete estimates, never zero
- non-immediate drop acquisition rejected
- trainable acquisition cost exposed as one-time cost
- reusable tool/reagent cost charged once rather than once per expected craft

## Manual checks

No user-facing route selection is enabled by Task 07, so there is no independent in-game behavior to validate yet. Live route behavior is deferred to the later integration task after Tasks 04/05 supply production metadata.

## Acceptance criteria

- PASS — orange recipes produce a guaranteed one-craft-per-point calculation.
- PASS — yellow/green recipes produce an expected-cost calculation without claiming certainty.
- PASS — gray recipes are never considered useful for skill-ups.
- PASS — missing prices produce an incomplete/unavailable estimate, not zero.
- PASS — vendor-vs-AH choice is explicit and testable.

## Commit

Suggested message: `feat: add expected profession recipe cost engine`
