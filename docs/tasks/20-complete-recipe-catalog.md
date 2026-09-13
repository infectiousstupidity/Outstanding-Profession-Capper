# Task 20 — Complete self-contained recipe catalog

Status: QUEUED  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Task 04

## Goal

Create one authoritative bundled catalog of every WotLK 3.3.5 recipe relevant to the ten professions supported by Profession Capper, including recipes the current character has not learned.

The optimizer must no longer discover its recipe universe only from the live profession window.

## Architecture

Add a catalog layer such as:

- `RecipeCatalog.lua` — registration, lookup, validation, profession filtering, and live-data overlay helpers.
- `RecipeCatalogData.lua` — generated static WotLK recipe records.
- a deterministic generator/import script under `tools/` that produces the bundled data from verified public/open WotLK game data.

The generated data is committed to the addon so runtime operation does not require network access or another addon.

## Required static data

At minimum, every optimizer-eligible recipe record must expose:

- recipe spell ID
- profession
- recipe name or a stable fallback name
- required profession skill where applicable
- reagent item IDs and quantities
- crafted output item ID and quantity where applicable
- recipe-item ID where one exists
- any stable prerequisite/specialization metadata required to determine eligibility

Do not duplicate orange/yellow/green/gray thresholds already owned by `RecipeDifficultyData.lua`; join that metadata by spell ID.

## Data ownership

Profession Capper must own the complete recipe catalog it needs.

- Do not depend on Ackis Recipe List or any other recipe addon.
- Do not copy restricted addon databases.
- Prefer reproducible extraction from public/open WotLK database/DBC sources.
- Record source/provenance and generation instructions so the data can be rebuilt and audited.

## Live overlay

The catalog is static game knowledge. The current profession book remains authoritative for live character state.

When a recipe is currently known, live game data may overlay fields such as:

- localized/displayed name
- live skill color
- output link
- reagent links
- craftable quantity

Unknown recipes must remain in the catalog and retain enough static reagent/output data to be costed.

## Automated validation

Add deterministic tests that verify:

- catalog records are unique by profession + spell ID
- every record has valid reagent quantities
- optimizer-eligible records have complete difficulty metadata
- profession filtering cannot leak recipes between professions
- representative known recipes from Classic, TBC, and WotLK load correctly
- a live-known recipe overlays the catalog record without removing static metadata
- an unknown recipe remains available to the optimizer input builder
- generated data is stable/reproducible

Add a coverage validator that fails CI when the canonical source contains supported recipes missing from the bundled catalog, except for an explicit reviewed exclusion list.

## Acceptance criteria

- Profession Capper has a complete bundled recipe universe for all ten supported professions.
- Unknown/unlearned recipes can be represented with full reagent/output metadata.
- Runtime catalog construction does not require Ackis, another addon, or network access.
- The catalog is generated/validated deterministically rather than hand-maintained.
- Existing static-guide behavior remains unchanged until Task 23 activates the catalog in recommendations.
