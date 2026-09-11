# Task 01 — Character profession skill context

Status: QUEUED  
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

## Manual checks

Record results for:
- Enchanting with no +skill item.
- Blood Elf Enchanting racial active.
- Equip/unequip any available +Enchanting item and verify values refresh.

## Commit

Suggested message: `feat: model profession skill modifiers explicitly`

The commit must also mark Task 01 DONE and Task 02 IN PROGRESS or leave it QUEUED in `TASKS.md`, depending on whether Task 02 begins immediately.
