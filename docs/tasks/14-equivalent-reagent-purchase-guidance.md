# Task 14 — Equivalent reagent purchase guidance

Status: IN PROGRESS  
Phase: 4 — User-facing integration  
Depends on: Task 10

## Goal

When an Enchanting reagent can be converted between Greater and Lesser Essences, do not merely use the cheaper equivalent internally. Tell the player exactly what to buy so they do not purchase the more expensive form by mistake.

## Required behavior

For supported Greater/Lesser Essence pairs:

- compare the actual whole-item purchase required for the recipe quantity;
- never compare against fractional Greater Essences;
- use the cheaper real purchase in recipe cost, route cost, and shopping-plan calculations;
- keep the recipe's required reagent visible;
- add an inline purchase hint when the equivalent form is cheaper;
- show the exact source quantity, conversion yield, direct cost, recommended cost, and savings in the material tooltip;
- Shift-Right-Click on that material searches the Auction House for the recommended purchase form, not the more expensive required form.

Example:

- recipe needs 3 Lesser Eternal Essence;
- 3 Lesser cost 12g;
- 1 Greater Eternal Essence costs 9g;
- row says `Buy 1x Greater Eternal Essence instead · save ~3g`;
- tooltip explains that 1 Greater covers 3 Lesser and shows 12g vs 9g.

Counterexample:

- recipe needs 2 Lesser Eternal Essence;
- each Lesser costs 4g;
- 1 Greater costs 9g;
- addon must recommend 2 Lesser for 8g, not normalize the Greater to a fake 6g cost.

## Supported conversions

Use the existing Greater/Lesser Essence mapping already maintained by the cost engine. Do not hard-code display-only exceptions in the UI.

## Acceptance criteria

- Quantity-aware comparison handles 2-vs-3 Lesser correctly.
- Current recipe cost and expected skill-up cost use the real whole-item purchase.
- Shopping plan exposes the chosen source item and source quantity.
- Material row visibly tells the player to buy the equivalent form when cheaper.
- Tooltip shows conversion, direct total, recommended total, and savings.
- Shift-Right-Click searches the recommended source item.
- Existing non-convertible reagent behavior remains unchanged.
- Lua 5.1 tests cover a converted 3-Lesser purchase and a non-converted 2-Lesser purchase.

## Manual checks still required

- Find an Enchant recommendation using Lesser Eternal Essence where Greater is cheaper.
- Confirm the row visibly says to buy Greater Eternal Essence.
- Confirm the displayed quantity matches the required Lesser amount after 3:1 conversion.
- Confirm tooltip totals match current TSM prices.
- Shift-Right-Click and verify the AH search uses Greater Eternal Essence.
- Test a quantity where buying individual Lessers is actually cheaper and verify no conversion hint is shown.
