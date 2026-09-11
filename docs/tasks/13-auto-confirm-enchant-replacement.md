# Task 13 — Auto-confirm Enchant replacement

Status: IN PROGRESS  
Phase: 4 — User-facing integration  
Depends on: Task 12

## Goal

Remove the repetitive "replace existing enchant?" confirmation during Profession Capper's targeted-enchant repeat workflow.

## Constraint

`ReplaceEnchant()` is protected. It may only be called from a hardware-event execution path.

Calling it before WoW has actually raised the `REPLACE_ENCHANT` dialog is unsafe, so Profession Capper must never call it speculatively.

## Behavior

While a Profession Capper targeted-enchant session is active:

- after the first manual bag/equipment target click, detect whether `REPLACE_ENCHANT` is actually visible;
- if visible, call `ReplaceEnchant()` immediately within that same hardware click;
- on later Profession Capper Enchant-button clicks, do the same after reusing the remembered target;
- do nothing when the replacement popup is not visible;
- do not globally suppress replacement confirmations outside Profession Capper's targeted-enchant workflow.

## Acceptance criteria

- No replacement popup remains after enchanting an already-enchanted remembered target.
- First manual target selection can auto-confirm replacement.
- Later remembered-target Enchant clicks can auto-confirm replacement.
- A target with no existing enchant is unaffected.
- `ReplaceEnchant()` is never called unless `StaticPopup_Visible("REPLACE_ENCHANT")` is true.
- Lua 5.1 test covers both visible and non-visible popup cases.

## Manual checks still required

- Repeat-enchant an already-enchanted bag item.
- Repeat-enchant an already-enchanted equipped item.
- Verify no `ADDON_ACTION_FORBIDDEN` / taint error appears.
- Verify a fresh item without an existing enchant still works normally.
