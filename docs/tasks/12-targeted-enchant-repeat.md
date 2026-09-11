# Task 12 — Targeted Enchant repeat workflow

Status: IN PROGRESS  
Phase: 4 — User-facing integration  
Depends on: Task 10

## Goal

Make item-targeted Enchanting behave correctly instead of treating it like a normal multi-craft batch.

WoW does not allow an addon to perform repeated protected item-targeting actions unattended. One hardware click is still required per enchant application. The addon should minimize that friction without pretending the client can queue five targeted enchants from one click.

## Behavior

For Enchanting recipes that target an item rather than create an output item:

- call `DoTradeSkill(..., 1)` for each application;
- never leave the UI stuck in a fake `Crafting 1/5` state after the first enchant completes;
- remember the first bag slot or equipped slot the player manually targets;
- on later clicks of Profession Capper's Enchant button, reuse that remembered target when the item is still in the same location;
- stop/reselect when the recommendation changes;
- keep normal profession batch crafting unchanged.

## Repeat controls

Expose two modes only for targeted enchants:

- `Until change` — continue one application per hardware click until the recommendation changes, the target skill is reached, or materials run out.
- `Fixed count` — player types a count such as `5`; stop after that many successful applications or earlier if the recommendation changes.

The control should remain compact and use the existing footer area rather than adding another panel.

## Safety / game limitation

Do not claim fully unattended repeated enchanting. Targeting/using an item is a protected action in WoW, so a user hardware event is required for each application.

Do not attempt to bypass this with timers, event-driven protected calls, or tainted popup automation.

## Acceptance criteria

- One targeted enchant success changes the session from active to ready-for-next rather than leaving it stuck active.
- Fixed count tracks successful applications correctly.
- Until-change mode stops when the selected recommendation changes or target skill is reached.
- First manual bag/equipment target is remembered.
- Subsequent Enchant button clicks reuse the remembered target when possible.
- Moving/replacing the remembered item causes safe fallback to manual target selection.
- Normal non-target profession batches still work unchanged.
- Lua 5.1 tests cover targeted repeat state and normal batch compatibility.

## Manual checks still required

- Enchant the same bag item repeatedly with `Until change`.
- Repeat the same equipped item.
- Use a fixed count of `5`.
- Move the remembered item between applications and confirm the addon asks for a target again instead of enchanting the wrong item.
- Confirm the repeat stops when Cheapest now changes to another recipe.
- Confirm replacement-confirmation behavior does not taint or lock the UI.
