# Task 06 — Acquisition provider integration

Status: QUEUED  
Phase: 2 — Recipe knowledge and acquisition  
Depends on: Task 05

## Goal

Optionally use compatible installed addons as live recipe-source providers while keeping Profession Capper's own model and public-source data as the safe baseline.

## Intended integrations

Investigate 3.3.5-compatible addons such as Ackis Recipe List or equivalent recipe-source addons.

Integration must use public runtime APIs/globals exposed by the installed addon.

## Licensing rule

Do not copy or vendor another addon's restricted database into this repository.

If an addon has an incompatible or unclear license, runtime integration is acceptable only through its exposed API/state; redistribution of its data is not.

## Required behavior

- Detect provider availability.
- Query recipe acquisition/source information when supported.
- Normalize results into Task 05's acquisition model.
- Prefer richer live provider data when trustworthy.
- Fall back to Profession Capper's own data when provider data is absent.

## Acceptance criteria

- Profession Capper works unchanged when the external addon is not installed.
- Provider failures are isolated and cannot break profession scanning.
- At least one compatible acquisition addon is either integrated or explicitly documented as unsupported after verification.
- Source/license findings are documented.

## Commit

Suggested message: `feat: integrate optional recipe acquisition provider`
