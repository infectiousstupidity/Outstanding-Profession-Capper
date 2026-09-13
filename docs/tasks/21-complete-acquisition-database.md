# Task 21 — Complete self-contained acquisition database

Status: DONE  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Task 20

## Goal

Make Profession Capper's bundled acquisition data authoritative and remove the Ackis runtime path.

## Implementation

- Generated 6,518 acquisition records from AzerothCore WotLK world data at commit `f1bef3bc0a2f6396175e184c2cac70df77b46d11`.
- Trainer rows retain real training cost, profession-skill requirement, player-level requirement and prerequisite spell IDs.
- Recipe items are joined to vendor and item-template data, distinguishing unlimited, limited-stock and reputation-gated vendors and retaining purchase prices/requirements.
- Every catalog recipe has at least one record. Where the pinned deterministic tables do not prove a guaranteed source, an explicit `manual` record is emitted instead of guessing or treating the recipe as free.
- Recipe acquisition storage now retains multiple static records per spell while preserving the legacy single-record getter for compatibility until Task 22 switches resolution to all candidates.
- Removed `AckisAcquisitionProvider.lua`, the Ackis optional dependency, its CI test and provider runtime plumbing.

## Validation

The Lua 5.1 acquisition test iterates all 3,552 catalog recipes, requires acquisition coverage for every one, verifies trainer/vendor/limited/reputation/manual classes, verifies multiple-source coverage, checks a known trainer price, and asserts that no external acquisition-provider registry remains.
