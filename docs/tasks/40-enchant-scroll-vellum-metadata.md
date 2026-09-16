# Task 40 — Deterministic enchant scroll and vellum metadata

Status: REVIEW  
Phase: 9 — Resale-aware Smartest optimization  
Depends on: Task 39

## Goal

Create a small, deterministic, generated data layer that tells the optimizer which Enchanting recipes can be turned into sellable scrolls and exactly which vellums are valid.

This task is data/model work only. Do not change route selection or recommendation UI yet.

## Why this task exists

The existing recipe catalog is not enough by itself.

For Enchanting, `outputItemID` can mean different things:

- a sellable enchant scroll;
- a normal crafted Enchanting item such as a runed rod;
- no output item at all for some enchants.

Do not assume every Enchanting recipe with an `outputItemID` is vellum-compatible.

Do not infer compatibility at runtime from localized spell names, item names, tooltip text, or ad-hoc string matching.

## Required data model

Generate or bundle a compact record keyed by enchant spell ID with at least:

- `scrollItemID` when the enchant has a canonical tradable scroll;
- `vellumEligible`;
- `targetType = "armor" | "weapon"` where applicable;
- the minimum compatible vellum tier/rank;
- provenance/source metadata for the generated dataset.

The model must be sufficient to determine the complete compatible vellum set without inspecting tooltips at runtime.

## Source requirements

Use a pinned, reproducible WotLK 3.3.5 data source.

Prefer data aligned with AzerothCore/ChromieCraft when it exposes the necessary spell/item relationships. If that source cannot provide all required fields, document the additional pinned source and why it is needed.

Do not silently derive missing relationships from English names.

The generator must be checked into `tools/`, and the generated Lua file must be reproducible in CI.

## Required edge cases

Tests must explicitly cover at least:

- Enchant Gloves - Gatherer;
- Enchant Gloves - Exceptional Spellpower;
- a weapon enchant;
- an armor/shield-compatible enchant as appropriate to the underlying WotLK vellum rules;
- a ring/personal enchant that must not be treated as a sellable vellum scroll;
- a runed rod or other normal Enchanting craft that has an output item but is not a vellum enchant;
- an Enchanting record with no output item.

Record any catalog entries that cannot be classified confidently. Unknown must remain unknown rather than being guessed into eligibility.

## Runtime constraints

The generated data must be cheap to load and query.

Do not add:

- runtime DBC scans;
- tooltip parsing;
- full-catalog name resolution;
- repeated `GetSpellInfo` work solely for classification;
- another unbounded cache.

The normal lookup should be an O(1) table lookup by spell ID.

## Tests

Add deterministic coverage that proves:

- generated output is current;
- representative eligible recipes map to the expected scroll and target type;
- non-vellum Enchanting crafts are excluded;
- personal/ring enchants are excluded unless the source proves a valid sellable-scroll path;
- every generated record references valid numeric IDs;
- generation is deterministic;
- the runtime does not require localized names to classify an enchant.

## Required handoff workflow

This task must use the Phase 9 three-agent gate.

### Agent 1 — implement

1. Set this task to `IN PROGRESS` in this file and `TASKS.md`.
2. Implement only Task 40.
3. Run the repository validation workflow and the new metadata tests.
4. Record implementation evidence below.
5. Commit and push the implementation.
6. Set/leave the task at `REVIEW`; do not start Task 41.

### Agent 2 — independent review

Review Agent 1's commit from scratch against this task, the source data, generated output, tests, Lua 5.1 compatibility, and runtime-cost requirements.

If clean:

- record the review evidence;
- mark the task `DONE`;
- Task 41 may begin.

If findings exist:

- record each concrete finding;
- mark the task `FIX`;
- hand off to Agent 3;
- do not start Task 41.

### Agent 3 — fix findings only

Fix the recorded review findings without expanding scope.

Then:

- run all Task 40 validation again;
- record the fix evidence;
- mark Task 40 `DONE`;
- only then may Task 41 begin.

If the review exposes a larger design problem, queue a new task instead of hiding a redesign in the fix pass.

## Acceptance criteria

- A reproducible generated scroll/vellum metadata source exists.
- Enchant scrolls are not inferred from generic `outputItemID` alone.
- Vellum eligibility and compatibility are deterministic and localization-independent.
- Representative WotLK edge cases are covered by tests.
- Runtime classification is O(1) and allocation-light.
- Full repository validation passes.
- Agent 2 review is clean or all Agent 2 findings were resolved by Agent 3.

## Evidence

### Agent 1 implementation

Implemented after Task 39 reached DONE and its validation workflow passed.

Source and provenance:
- Primary WotLK recipe/output data is the pinned `Hoizame/AtlasLootClassic` commit `8e99341e4e779328460bf7684c0d5b22ce50ddf1`, the same 3.3.5-aligned source already used by `RecipeCatalogData.lua`.
- AzerothCore WotLK commit `f1bef3bc0a2f6396175e184c2cac70df77b46d11` provides the runtime semantics: permanent Enchanting spells create the effect's numeric item type when cast on a vellum, and vellum acceptance is based on numeric armor/weapon item class.
- AzerothCore does not bundle the client Spell.dbc values in this repository. The additional pinned numeric cross-check is `b-morgan/Skillet-Classic` commit `add4400eb38d7e0839d02de0bbe10c3a162354f6`, `EnchantData5.lua`, filtered to the exact 301 WotLK Enchanting spell IDs. It is used only for equipped-item class/slot classification and a spell-to-scroll ID cross-check, never for localized names.
- Vellum tiers are derived deterministically from the first source expansion in the pinned WotLK profession dataset: Classic -> tier I, TBC -> tier II, Wrath -> tier III. Higher tiers remain compatible. Agent 2 must review this tier rule explicitly.

Implementation:
- Added `tools/data/enchant_scroll_metadata_source.json`, a compact pinned-source snapshot covering all 301 bundled Enchanting records.
- Added `tools/generate_enchant_scroll_metadata.py` and generated `EnchantScrollData.lua`.
- Generated output has 240 eligible sellable-scroll enchants. Personal/ring enchants, normal Enchanting crafts such as runed rods, and records without output items are explicitly excluded.
- Spell 33996 has conflicting pinned output evidence and remains `source_conflict` / ineligible instead of being guessed into eligibility.
- Runtime lookup is a direct numeric spell-ID table lookup. Compatible vellums reuse one shared armor/weapon table plus `minVellumTier`; no runtime DBC scan, tooltip parsing, localized-name matching, repeated GetSpellInfo work, or unbounded cache was added.
- Added deterministic source/catalog consistency checks, generated-file `--check`, Lua 5.1 edge-case tests, and CI steps.

Validation:
- `python3 tools/generate_enchant_scroll_metadata.py --check`
- `lua5.1 tools/test_enchant_scroll_metadata.lua`
- full repository `Validate addon` workflow

Task remains REVIEW until Agent 2 independently verifies the pinned-source interpretation, tier rule, deliberate 33996 unknown, Lua 5.1 behavior, and full validation.

### Agent 2 review

Pending.

### Agent 3 fixes

Pending.
