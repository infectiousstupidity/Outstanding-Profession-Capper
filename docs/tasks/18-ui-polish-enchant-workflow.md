# Task 18 — Enchant repeat workflow presentation

Status: DONE  
Phase: 5 — UI/UX polish  
Depends on: Task 12, Task 13, Task 15

## Goal

Make targeted Enchanting repeat state understandable without reading button text or chat output.

Do not change the protected-action model established by Tasks 12 and 13.

## Implement

When the current recommendation is an item-targeted enchant, show a compact repeat strip near the primary action.

Expose:

- repeat mode;
- fixed count only in fixed mode;
- remembered target state;
- progress;
- stop/change state when recommendation changes.

Suggested states:

```text
Repeat: Until change      Target: select item
Repeat: Until change      Target: Chestpiece
Repeat: Fixed · 5         Target: Chestpiece
2 / 5 applied             Target: Chestpiece
Recommendation changed · repeat stopped
Target moved · select item again
```

## Target naming

When possible, display the remembered item's current name.

Do not claim the target is valid solely because a slot is remembered. Existing item-ID validation remains authoritative.

If the target cannot be resolved safely, show `select item`.

## Primary button labels

Keep labels concise:

- `Enchant`
- `Enchant again`
- `Enchant 2 / 5`

Do not put full workflow explanations in the button.

## Auto-confirm status

Do not expose implementation jargon such as `ReplaceEnchant()`.

No extra UI is needed for auto-confirm unless it fails. If WoW blocks the action, surface a concise error/fallback state.

## Suggested file changes

- `Core.lua`
- `Profession_capper.xml`
- `Localization.lua`

## Implementation note

Implemented on master pending in-game acceptance.

Presentation changes:

- targeted Enchant recommendations now show a dedicated repeat strip above the primary action;
- repeat mode is always visible and the numeric count exists only in Fixed mode;
- remembered targets are validated using the existing item-ID/location check before their item name is shown;
- invalid/moved targets are cleared and surfaced as `Target moved or changed · select item again`;
- recommendation changes preserve a presentation-only stop notice after the old repeat session is cleared;
- fixed sessions show `N / total applied`, while Until change shows the successful application count;
- the old targeted-enchant progress copy is removed from the recommendation area to avoid duplicate workflow text;
- primary labels are now only `Enchant`, `Enchant again`, or `Enchant N / total`;
- the underlying one-hardware-click-per-application flow, remembered-target reuse, and replacement auto-confirm logic are unchanged.

## Acceptance criteria

- Before first target selection, UI clearly asks for a target.
- Remembered target is visible by item name when resolvable.
- Fixed-count progress is unambiguous.
- Until-change mode is unambiguous.
- Recommendation change visibly stops the repeat session.
- Moved/replaced target visibly returns to target-selection state.
- No new protected-action automation is introduced.
- Auto-confirm behavior from Task 13 remains unchanged.

## Manual acceptance

Accepted in-game on 2026-09-13. The user reviewed the live Phase 5 UI and explicitly requested that the prior Phase 5 blockers be closed so remaining presentation issues can move into Task 19 cleanup.

## Commit

Suggested message: `feat: clarify enchant repeat workflow UI`
