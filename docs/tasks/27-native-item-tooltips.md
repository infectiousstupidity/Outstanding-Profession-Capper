# Task 27 — Native item tooltips across recipe UI

Status: IN PROGRESS  
Phase: 5 — UI/UX polish  
Depends on: Tasks 15, 16, 23, and 24

## Goal

Every recipe entry that represents a crafted item should expose the normal WoW item tooltip, not only Profession Capper's custom recipe/cost text.

The player must be able to hover a recommendation such as `Ring of Twilight Shadows` and see the actual item tooltip with quality, stats, requirements and other normal client-provided item information.

## Scope

Apply native output-item tooltips to:

- the main recommendation icon/name area,
- recipe rows in Compare,
- craft rows in Full route,
- acquisition rows that refer to a recipe output.

Existing material rows already use their native item hyperlinks and must keep doing so.

## Tooltip behavior

When a recipe has an output item:

1. Prefer the live profession-book output item link.
2. Otherwise use the bundled catalog output item ID.
3. Render it through `GameTooltip:SetHyperlink` so the client supplies the canonical item tooltip.
4. Append Profession Capper context below the native tooltip where useful, such as recipe name, route range, expected costs, materials, or acquisition guidance.

When a recipe has no output item, such as many Enchanting recipes, preserve a readable recipe fallback tooltip rather than inventing an item.

Do not replace native item stats with duplicated custom text.

## Compatibility

- WoW 3.3.5 / Lua 5.1 only.
- No external item database dependency.
- Missing uncached item info must degrade safely to the recipe name.
- Hover targets must not alter crafting/click behavior.

## Acceptance criteria

- Hovering the main recommendation for an item-producing recipe shows the actual item tooltip.
- Hovering a Compare recipe row shows the actual output item tooltip plus Profession Capper comparison context.
- Hovering a Full route craft/acquisition row shows the output item tooltip where applicable.
- Existing reagent/material tooltips still work.
- Recipes without output items retain a safe text tooltip.
- Automated repository validation passes.

## Manual in-game acceptance

Verify at least one Jewelcrafting item with visible stats and one Enchanting recipe without an output item. Record the result here before marking DONE.

Implementation is complete in code; manual in-game tooltip verification remains pending.
