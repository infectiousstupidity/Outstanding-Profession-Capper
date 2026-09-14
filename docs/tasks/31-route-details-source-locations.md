# Task 31 — In-frame route details and recipe source locations

Status: IN PROGRESS  
Phase: 5 / 6 — UI polish and acquisition data  
Depends on: Tasks 21, 24, 29, 30

## Reported issues

1. Expanded **Route details** can render below the Profession Capper frame instead of inside it.
2. Trainer/vendor recommendations say only `Trainer` or `Vendor`, so the player does not know which NPC to visit or where that NPC is located.

## Implementation

### Route-details layout

The details panel is now anchored to the bottom-left of `MainFrameCore`, above the active footer controls, instead of being positioned below the materials frame.

The runtime height calculation reanchors the panel using the regular or Enchant-repeat footer height and reserves the details panel's full height. This keeps route details inside the parent frame even when:

- there are no rendered material rows;
- material rows expand vertically;
- Enchant repeat controls use the larger footer.

The details panel gains a dedicated recipe-source line without displacing the route/cost/coverage lines outside the frame.

### Bundled trainer/vendor locations

`RecipeSourceLocations.lua` bundles physical source locations for recipe-related NPCs already referenced by Profession Capper's acquisition database.

The generated data combines:

- Questie WotLK NPC names, faction, zones and map coordinates;
- AzerothCore `creature_default_trainer` mappings so abstract trainer IDs resolve to the physical NPCs that use them.

Only NPCs referenced by Profession Capper acquisition metadata are emitted. The checked-in source revision is recorded in the generated file.

`tools/generate_recipe_source_locations.py` reproduces the file from the pinned inputs.

### Acquisition model

Trainer/vendor/reputation acquisition results now carry a `locations` list. Existing `zone` / `coordinates` fields remain compatible and use the first generated location as a fallback.

Location presentation:

- removes NPCs restricted to the opposite player faction;
- prefers a source in the player's current zone;
- otherwise prefers a neutral source, then the player's faction;
- keeps all valid alternatives available for tooltips.

### UI presentation

Compact recommendation text now includes the destination zone when known:

`Get recipe: Trainer · Dalaran · 5g 00s`

Expanded guidance includes the NPC and exact map coordinates, for example:

`Trainer · Enchanter Nalthanis · Dalaran (39.1, 39.8) · +N more locations · 5g 00s`

The expanded Route details panel includes a `Where:` row for acquisition-first recommendations.

Compare and Full route tooltips enumerate physical trainer/vendor locations. The main recommendation item tooltip also exposes source locations when the current recommendation requires learning/buying the recipe.

## Regression coverage

Automated validation covers:

- the details frame being structurally anchored inside `MainFrameCore`;
- WotLK source-location data loading under Lua 5.1;
- trainer-group expansion to physical NPCs;
- known Dalaran Enchanting trainer name/zone/coordinates;
- a known vendor name/zone;
- location metadata surviving acquisition resolution and explanation;
- full existing addon validation and route tests.

## Acceptance criteria

- Route details never render outside the main Profession Capper frame.
- Expanded details remain inside the frame with both normal and Enchant-repeat footer layouts.
- Trainer/vendor acquisition text shows a useful destination zone when data exists.
- Expanded/tooltip guidance shows NPC name and map coordinates.
- Faction-incompatible source NPCs are not presented when the player's faction is known.
- Compare and Full route acquisition rows expose the same location data.
- Existing dynamic/static route behavior remains unchanged.
- Full repository CI passes.

## Manual acceptance

In the WoW 3.3.5 client:

1. Open Enchanting with Details expanded and confirm all Route details stay inside the black frame.
2. Check a recommendation for an unlearned trainer recipe such as Enchant Cloak - Speed and confirm a zone is visible in the main row.
3. Hover the recommendation and confirm the NPC/location list is visible.
4. Open Compare and Full route, hover acquisition rows, and confirm trainer/vendor locations are shown.
5. Check an Alliance and Horde character if available and confirm opposite-faction-only NPCs are filtered.
6. Check a targeted Enchant recipe with repeat controls and confirm the expanded details panel remains above the repeat footer.

Manual in-game verification remains pending before marking DONE.
