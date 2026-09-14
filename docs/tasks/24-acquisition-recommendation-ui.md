# Task 24 — Learn/buy-first recommendation UI

Status: IN PROGRESS  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Task 23

## Goal

Present unknown-recipe route choices clearly so the player knows whether the next action is to craft, train, buy, or acquire a recipe item.

## Main recommendation states

The primary recommendation must distinguish at least:

### Recipe already known

Show the existing craft-first presentation:

- recipe
- craft count / target skill
- expected cost
- materials
- craft controls

### Recipe must be learned first

Show acquisition as the dominant next action, for example:

`Learn Enchant X`
`Enchanting trainer — 5g`
`Then craft ~18 to 320`
`Estimated route cost: 23g`

Do not display an enabled craft action for a recipe that is not in the live profession book.

### Recipe item must be bought first

Show:

- recipe name
- chosen source, such as vendor or Auction House
- acquisition price
- source/location when known
- subsequent craft target and estimated cost

### Conditional alternative

Drops, limited stock, unmet reputation, quests, and other non-guaranteed sources may appear as alternatives/details but must be visibly marked conditional and must not masquerade as the guaranteed main route.

## Comparison view

Extend recipe comparison so each candidate exposes acquisition state and the cost basis used by the optimizer.

Useful columns/fields include:

- recipe
- known / trainer / vendor / AH / conditional
- one-time acquisition cost
- expected material cost per skill-up
- effective route cost
- reason excluded, when relevant

The UI should make it obvious when an unknown recipe is still cheaper after paying to learn it.

## Route view

The route view should show acquisition boundaries before the affected craft segment.

Example:

`300 — Learn Recipe X from trainer (5g)`
`300–320 — Craft Recipe X (~18 crafts)`
`320–340 — Craft Recipe Y`

Avoid duplicating the same acquisition cost on every skill point/segment.

## Refresh behavior

After the player learns a recommended recipe:

- `TRADE_SKILL_UPDATE` rebuilds the live cache
- the recipe becomes learned automatically
- the acquisition prompt disappears
- the recommendation becomes the normal craft state

No manual "I learned it" checkbox should be necessary.

## Localization and compatibility

- Add localization keys for new states/actions.
- Preserve WoW 3.3.5 / Lua 5.1 compatibility.
- Keep the existing compact/expanded and comparison UI architecture rather than creating a second UI system.

## Manual in-game checks

Verify at least:

- trainer recipe selected as cheapest
- learning it immediately transitions to craft state
- vendor/AH recipe acquisition state
- conditional recipe is not shown as guaranteed
- known recipe UI remains unchanged
- attached/detached panel and ElvUI layouts remain usable

## Acceptance criteria

- The user can immediately tell whether the addon wants them to craft or acquire a recipe.
- Acquisition source and one-time cost are visible.
- Unknown recipes cannot expose broken craft controls.
- Compare/route views explain why an unknown recipe won or lost.
- Learning the recipe transitions automatically into the existing crafting workflow.


## Implementation status

Code implementation is complete and automated validation is required before this task can be marked DONE.

Implemented behavior:

- the optimizer-selected acquisition source is now the UI source of truth instead of re-resolving a potentially different source,
- unknown selected recipes render as an explicit acquire-first state with source/location/cost guidance and no enabled craft action,
- comparison rows expose trainer/vendor/AH acquisition state and one-time cost,
- the Full route view inserts an acquisition row before the affected craft segment and does not duplicate the one-time cost on the craft row,
- shopping-plan segments retain acquisition metadata needed by the route UI,
- learning a recipe continues to transition automatically through the existing `LEARNED_SPELL_IN_TAB` / `TRADE_SKILL_UPDATE` refresh path.

Manual in-game acceptance from the task remains pending, so status stays IN PROGRESS.
