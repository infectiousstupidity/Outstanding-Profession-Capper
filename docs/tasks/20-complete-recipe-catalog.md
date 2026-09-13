# Task 20 — Complete self-contained recipe catalog

Status: DONE  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Task 04

## Goal

Bundle the WotLK 3.3.5 recipe universe for all ten supported professions so unknown recipes exist independently of the live profession book.

## Implementation

- `RecipeCatalog.lua` owns validation, registration, profession indexes, lookup, live overlays, and optimizer-input construction.
- `RecipeCatalogData.lua` contains 3,552 generated recipe records with spell ID, profession, stable fallback name, skill requirement, reagents, output and recipe-item linkage where known.
- `tools/generate_recipe_catalog.py` reproduces the data from AtlasLootClassic commit `8e99341e4e779328460bf7684c0d5b22ce50ddf1`.
- Difficulty curves stay in `RecipeDifficultyData.lua`; the catalog joins them by spell ID instead of duplicating them.
- Runtime operation has no network or external recipe-addon dependency.

## Validation

`tools/test_recipe_catalog.lua` runs under Lua 5.1 and verifies total/profession coverage, verified difficulty coverage, representative Classic/WotLK data, live-overlay preservation, unknown-recipe retention and duplicate rejection.

Dynamic recommendations remain live-only until Task 23 deliberately activates full-catalog optimization.
