# Task 06 — Acquisition provider integration

Status: DONE  
Phase: 2 — Recipe knowledge and acquisition  
Depends on: Task 05

## Goal

Optionally use compatible installed addons as live recipe-source providers while keeping Profession Capper's own model and public-source data as the safe baseline.

## Verified provider: Ackis Recipe List

Ackis Recipe List v2.01-8-g9458672 was verified as compatible with client interface 30300.

Its public addon object is exposed as `_G.AckisRecipeList`, and its public `GetRecipeData` method can return recipe acquisition data. The v2.01 acquisition-type protocol is:

- 1 trainer
- 2 vendor
- 3 mob drop
- 4 quest
- 5 seasonal
- 6 reputation
- 7 world drop
- 8 custom

The adapter supports both public API shapes found in the 3.3.5-era code: `GetRecipeData(spellID, "acquire_data")` and builds returning the whole recipe record.

## Licensing

Ackis Recipe List v2.01 source explicitly states **All Rights Reserved**.

Profession Capper therefore does **not** copy, vendor, transform, or redistribute ARL's database. `AckisAcquisitionProvider.lua` only calls the installed addon's public runtime API and normalizes the result into Task 05's own acquisition model.

No ARL source files or database rows are included in this repository.

## Runtime behavior

- `AckisRecipeList` is an optional dependency only.
- Without ARL installed, Profession Capper behaves exactly as before and uses its own acquisition data.
- Provider queries are wrapped in `pcall`; a broken provider records an error and falls back to built-in data.
- Live type/source IDs enrich built-in records.
- Richer built-in names, coordinates, and verified prices are preserved when ARL only provides IDs.
- A provider vendor/trainer classification with no known price does not become a free route.
- Drop, quest, reputation, seasonal, and custom sources remain non-instant/manual as appropriate.
- The adapter never accesses ARL private trainer/vendor/mob tables, because those are not part of its public API.

## Known limitation

The verified public `GetRecipeData` acquisition table exposes acquisition type and source IDs, but no separate public `GetTrainerData` / `GetVendorData` / `GetMobData` lookup was found. Therefore the integration does not reach into ARL private tables to recover source names or coordinates. When Profession Capper already has richer public-source metadata, that information wins.

## Automated validation

`tools/test_ackis_acquisition_provider.lua` verifies:

- provider registration/detection
- unchanged built-in behavior with ARL absent
- trainer/vendor/drop/quest normalization
- ARL source IDs are exposed
- live metadata merges without erasing verified built-in costs/source names
- vendor data without a known price cannot become a zero-cost acquisition
- drop/quest sources are non-instant
- whole-record API compatibility
- provider exceptions are isolated and built-in fallback still resolves

## Manual checks

The provider is optional and does not activate the user-facing dynamic recommendation UI. Runtime behavior is guarded by availability checks and has a complete no-provider fallback. A later Task 10 in-game integration check should verify the installed ARL combination if ARL is present on the test client.

## Acceptance criteria

- PASS — Profession Capper works unchanged when ARL is absent.
- PASS — provider failures are isolated and cannot escape into profession scanning/resolution.
- PASS — Ackis Recipe List v2.01 (30300) is integrated through its public runtime API.
- PASS — live results normalize into Task 05's model and merge with the built-in fallback.
- PASS — ARL's All Rights Reserved database is not redistributed.

## Commit

`feat: integrate optional recipe acquisition provider`
