# Task 11 — Enchanting rod ownership-aware recommendations

Status: DONE  
Phase: 1 — Character and price foundations  
Depends on: none

## Goal

Stop the static Enchanting guide from recommending runed rods the character already owns or has already superseded with a higher-tier runed rod.

## Required behavior

- Treat the runed Enchanting rods as an ordered upgrade chain.
- If the character owns a given rod, do not recommend crafting that rod again.
- A higher-tier rod suppresses recommendations for every lower-tier rod because it can serve as the lesser tool.
- Continue recommending the next higher rod when it has not yet been obtained.
- Count rods in bags and bank.
- Preserve a normal skill-up recommendation when filtering an obsolete rod out of a guide step.

## Implementation notes

Implemented:
- Added the Wrath rod item hierarchy from Runed Copper through Runed Titanium.
- Recognizes the legacy Runed Cobalt Rod if a 3.3.5 server exposes the removed beta item, without ever recommending its removed recipe.
- Enchanting guide recipe filtering now checks the highest rod tier actually owned through `GetItemCount(itemID, true)`.
- Rod recipe filtering is fail-open if the ownership API is unavailable, preserving the existing deterministic guide.
- Added a generic optional recipe-relevance hook to `Guide.lua`; other profession guides are unchanged.
- Added a fallback normal enchant for the level-1 rod-only step so a character who already owns a rod is never left without a recommendation.

## Validation

Automated Lua 5.1 coverage verifies:
- no rod owned preserves the existing Arcanite/Fel Iron recommendations
- Runed Arcanite suppresses Arcanite and lower rods but keeps Fel Iron relevant
- Runed Fel Iron suppresses both Fel Iron and Arcanite
- Runed Titanium suppresses every lower rod recommendation across representative rod steps
- bank-inclusive ownership checks are used
- the level-1 step falls back to a normal enchant
- legacy Runed Cobalt ownership suppresses lower rods if that item exists on the server

No manual test is required to prove the filtering logic. A live check with an existing high-tier rod is still useful to verify the server reports the item through `GetItemCount` as expected.

## Commit

Suggested message: `fix: skip owned enchanting rod upgrades`
