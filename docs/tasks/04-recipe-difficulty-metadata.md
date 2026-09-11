# Task 04 — Recipe difficulty metadata

Status: QUEUED  
Phase: 2 — Recipe knowledge and acquisition  
Depends on: Task 01

## Goal

Give the optimizer enough recipe-skill metadata to determine how useful a recipe is at each trained skill level, including active +profession modifiers.

## Data required per recipe

At minimum:

- recipe spell ID
- profession
- learn/required skill
- orange boundary
- yellow boundary
- green boundary
- gray boundary

Use canonical 3.3.5/WotLK values from verifiable public references or game data.

## Modifier handling

The calculation must use Task 01's skill context.

Do not assume that displayed skill and trained/base skill are interchangeable.

The result should answer:

- recipe color/difficulty for the current character
- whether a skill-up is guaranteed
- expected/non-guaranteed skill-up probability when appropriate
- whether the recipe can still skill the profession at all

## Scope

- Extend declarative recipe/guide data or add a dedicated recipe metadata layer.
- Add validation for monotonic thresholds and missing metadata.
- Preserve existing static guide behavior while metadata is being introduced.

## Non-goals

- Do not price recipes yet.
- Do not solve the route yet.

## Acceptance criteria

- Every recipe eligible for dynamic optimization has complete difficulty metadata.
- Invalid threshold ordering fails validation.
- Blood Elf/+skill scenarios produce the correct shifted usability window according to verified 3.3.5 behavior.
- Recipes with unknown metadata are excluded from dynamic optimization rather than guessed.

## Commit

Suggested message: `feat: add recipe skill difficulty metadata`
