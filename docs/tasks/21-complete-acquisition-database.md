# Task 21 — Complete self-contained acquisition database

Status: QUEUED  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Task 20

## Goal

Bundle complete acquisition knowledge for the recipe catalog so Profession Capper itself knows how every supported recipe can be obtained.

Ackis Recipe List must not be required, queried, or used as an authority.

## Data model

Replace the current tiny acquisition seed with generated, auditable WotLK 3.3.5 acquisition data.

A recipe may have zero, one, or multiple acquisition records. Static records should support, where applicable:

- trainer
- unlimited vendor
- limited-stock vendor
- recipe item
- reputation vendor
- quest reward
- mob drop
- world drop
- other explicitly modeled/manual sources

Each source should retain the stable metadata required for later eligibility checks, such as:

- recipe spell ID
- recipe item ID
- source type
- trainer/vendor/NPC/quest/faction IDs
- source name fallback
- zone/coordinates when reliably available
- purchase/training price
- required profession skill
- required player level
- faction restriction
- reputation faction/standing
- specialization or other prerequisite
- limited-stock flag
- source/provenance

## Generation

Add a deterministic generator/import path under `tools/` using verified public/open WotLK database data.

Do not manually curate thousands of rows. Small explicit overrides are acceptable only when:

- the source data is incomplete or ambiguous,
- the override is documented,
- the validator makes the override visible.

## Remove Ackis dependency

Once bundled acquisition coverage is in place, remove the Ackis runtime path:

- remove `AckisAcquisitionProvider.lua`
- remove `AckisRecipeList` from `OptionalDeps`
- remove Ackis-specific tests and provider-only code that no longer serves another purpose
- update documentation so Profession Capper's bundled acquisition database is authoritative

Task 06 remains historical documentation of the old approach; this task supersedes that runtime architecture.

## Coverage policy

Every optimizer-eligible catalog recipe must end in one of two explicit states:

1. one or more known acquisition sources, or
2. an explicit reviewed `unknown/manual` record.

Missing data must never silently mean "free" or "already obtainable."

## Automated validation

Add tests/validators for:

- trainer source, cost, skill and level requirements
- vendor and limited-stock vendor distinction
- reputation/faction prerequisites
- quest/drop/world-drop classification
- recipe-item linkage
- multiple acquisition records for one spell ID
- no missing catalog spell IDs without an explicit unknown/manual record
- no Ackis dependency remains in TOC/runtime/tests
- deterministic regeneration of bundled data

## Acceptance criteria

- Static acquisition knowledge is fully self-contained.
- Every supported catalog recipe has explicit acquisition coverage.
- Ackis is completely removed from the runtime dependency path.
- Missing or uncertain acquisition data is explicit and conservative.
- Static-guide behavior remains usable while Tasks 22–24 integrate the new data into optimization.
