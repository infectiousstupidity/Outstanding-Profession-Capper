# Task 01 — Character profession skill context

Status: IN PROGRESS  
Phase: 1 — Character and price foundations  
Depends on: none

## Goal

Create one authoritative character-skill model that distinguishes trained/base profession skill from active profession bonuses.

This must handle Blood Elf +10 Enchanting and equipped/temporary +profession effects without hard-coding race-specific route logic.

## Required behavior

Read all relevant values from the 3.3.5 profession API, including the fourth return value from `GetTradeSkillLine()`.

Expose a small internal context containing at least:

- profession name
- current displayed/effective skill
- active skill modifier
- inferred trained/base skill
- current profession cap
- effective cap if the client exposes a modifier there
- whether a modifier is currently active

The rest of the addon must stop assuming that one `rank` integer fully describes profession skill.

## Scope

- Introduce a focused character/profession context module or helper.
- Update current guide/crafting calculations to use the new context without changing recommendations yet.
- Detect changes when equipment or other active modifiers change and refresh recommendations.
- Keep behavior generic so Draenei Jewelcrafting or other profession bonuses can use the same machinery.

## Non-goals

- Do not implement price optimization.
- Do not hard-code `BloodElf = +10`.
- Do not yet alter recipe route selection based on price.

## Acceptance criteria

- A character with no modifier behaves exactly as before.
- A Blood Elf Enchanter exposes the +10 modifier separately from trained/base skill.
- Equipping or removing +profession gear causes the context to refresh.
- Existing guide, crafting, and training-cap behavior still works.
- Lua 5.1 and repository validation pass.

## Implementation notes

Implemented:
- Added a single profession-skill context with trained/base skill, active modifier, effective skill, trained cap, effective cap, and modifier state.
- Reads the fourth return from `GetTradeSkillLine()` when present.
- Falls back to the Wrath-era `GetSkillLineInfo()` modifier fields when the fourth return is unavailable.
- Keeps the existing static guide/crafting route keyed to trained/base skill so Task 01 does not change recommendations.
- Refreshes the context when player equipment or player auras change.
- Added Lua 5.1 coverage for no modifier, a +10 skill-line modifier, temporary +skill, direct trade-skill modifier, and context change detection.

## Manual checks

Required before marking this task DONE:
- PENDING — Enchanting with no +skill item.
- PENDING — Blood Elf Enchanting racial active.
- PENDING — Equip/unequip any available +Enchanting item and verify values refresh.

These checks require a live 3.3.5 client and are intentionally not claimed as passed by CI.

## Commit

Suggested message: `feat: model profession skill modifiers explicitly`

The commit must also mark Task 01 DONE and Task 02 IN PROGRESS or leave it QUEUED in `TASKS.md`, depending on whether Task 02 begins immediately.
