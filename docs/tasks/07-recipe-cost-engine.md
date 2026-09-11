# Task 07 — Recipe cost engine

Status: QUEUED  
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

## Acceptance criteria

- Orange recipes produce a guaranteed one-craft-per-point calculation.
- Yellow/green recipes produce an expected-cost calculation without claiming certainty.
- Gray recipes are never considered useful for skill-ups.
- Missing prices produce an incomplete/unavailable estimate, not zero.
- Vendor-vs-AH choice is explicit and testable.

## Commit

Suggested message: `feat: add expected profession recipe cost engine`
