# Task 04 — Recipe difficulty metadata

Status: DONE  
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

The calculation uses Task 01's skill context and deliberately keeps trained/base skill separate from effective/displayed skill.

- Effective skill (base + active modifier) is used for recipe skill requirements.
- Trained/base skill is used for orange/yellow/green/gray color and skill-up probability.
- Displayed transition points are exposed as normal thresholds + the active modifier.

That means a Blood Elf with +10 Enchanting can meet a recipe requirement ten trained points earlier, while the recipe's color transition appears ten points later in the displayed/effective skill number. The +10 does not act like ten permanently trained profession points.

## Implementation

Implemented on 2026-09-11:

- Added `RecipeDifficulty.lua` with validation, registration, lookup, optimizer eligibility, and character-specific evaluation.
- Added `RecipeDifficultyData.lua` with 3,236 WotLK-era recipe difficulty records across the ten supported professions.
- Data is limited to pre-Cataclysm spell IDs/skill ranges from a public profession reference. Yellow/gray semantics are independently represented by the WotLK 3.3.5 `SkillLineAbility` client data.
- Eleven malformed/non-monotonic source rows were rejected during import rather than normalized or guessed.
- Recipes without a complete verified record return `missing_difficulty_metadata` and are excluded from dynamic optimization.
- Updated the Phase 3 recipe-cost engine so +profession modifiers affect requirement gates but do not incorrectly advance the skill-up color/chance curve.
- The deterministic static guide remains unchanged and does not depend on this metadata.

## Automated validation

`tools/test_recipe_difficulty.lua` verifies:

- known WotLK Enchanting thresholds (including 7418 and 60763)
- orange/yellow/green/gray evaluation
- expected non-guaranteed skill-up probabilities
- gray recipes cannot skill up
- +10 profession skill shifts effective/displayed usability without changing trained-skill color
- +10 can satisfy a recipe requirement early
- unknown recipes are excluded
- non-monotonic thresholds fail validation
- broad metadata coverage is loaded

`tools/test_recipe_cost.lua` also verifies the corrected base-vs-effective skill behavior in the cost engine.

## Manual checks

No new user-facing recommendation path is activated by this task. The existing static guide behavior is unchanged, so there is no separate in-game UI behavior to validate for Task 04. Live dynamic recommendations remain disabled until later integration.

## Acceptance criteria

- PASS — every recipe admitted to dynamic optimization must have complete validated metadata.
- PASS — invalid threshold ordering is rejected.
- PASS — Blood Elf/+skill handling keeps base skill and effective/displayed skill separate.
- PASS — recipes with unknown metadata are excluded instead of guessed.
- PASS — static guide behavior is preserved.

## Commit

`feat: add recipe skill difficulty metadata`
