# Task 05 — Recipe acquisition model

Status: QUEUED  
Phase: 2 — Recipe knowledge and acquisition  
Depends on: none

## Goal

Represent how recipes and profession ranks are obtained so the optimizer never recommends an inaccessible recipe as though it were already known.

## Acquisition types

Support at least:

- already learned
- profession trainer
- vendor
- limited-stock vendor
- Auction House recipe/item
- reputation requirement
- quest
- world/drop source
- unknown/manual acquisition

## Data model

Where known, acquisition entries should support:

- NPC/source name
- zone
- coordinates
- faction restrictions
- reputation requirement
- purchase price
- required profession skill
- trainer rank/tier
- item ID for recipe items
- notes such as limited stock

Profession-rank trainers must use the same model where practical.

## Route behavior

The future solver must be able to distinguish:

- immediately usable
- trainable now
- purchasable now
- obtainable but with non-gold requirements
- unavailable/unknown

Do not assign zero acquisition cost to reputation/drop recipes.

## Data sourcing

Use public/verifiable game data.

Do not copy databases from addons whose licensing does not permit redistribution.

## Acceptance criteria

- Static guide can ask the acquisition model why a missing recipe is unavailable.
- Trainer/vendor recipes can expose useful location/source information.
- Unknown/drop/reputation acquisition cannot be mistaken for free instant access.
- Data validation catches malformed acquisition entries.

## Commit

Suggested message: `feat: model recipe and trainer acquisition sources`
