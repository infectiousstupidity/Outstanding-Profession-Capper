# Outstanding Profession Capper

A World of Warcraft 3.3.5 / WotLK profession-leveling addon. Open a supported profession and the addon tells you what to craft next, how far to craft it, whether you have enough materials, and roughly how long the current step will take.

This fork descends from SamuelLira99/Profession-Capper, DarkChimu/Improved-Profession-Capper, and Utkuchix/Outstanding-Profession-Capper.

## What v3 adds

- Spell-ID based recipe matching instead of English recipe-name matching.
- Target-aware leveling steps: current skill, next guide breakpoint, skill-ups needed, and craftable quantity.
- Exact craft counts for orange recipes and clearly labelled minimums for non-guaranteed skill-ups.
- Craft-to-target batches that never intentionally queue more crafts than the current step requires.
- Automatic queue stop when the target skill is reached.
- A Continue-to-target action when yellow/green RNG leaves the batch short; the addon does not automate a second protected craft action.
- Live batch progress and remaining-time estimate.
- A vertical interactive materials list with item icons, owned/required counts, item tooltips, normal modified-item clicks, and Shift+Right-click Auction House search insertion.
- Recipe discovery that works even when Blizzard's profession list is filtered or categories are collapsed.
- Profession training-cap handling.
- A compact panel attached to the Blizzard profession window by default.
- Persistent attach/detach, lock and position settings.
- English, Spanish and Russian UI strings plus localized recipe fallback names.
- Automated Lua 5.1, TOC/XML, guide-range and recipe-metadata validation.

## Commands

- /pcapper — toggle the addon.
- /pcapper show / /pcapper hide
- /pcapper attach / /pcapper detach
- /pcapper lock / /pcapper unlock
- /pcapper reset — restore default settings and attach the panel again.
- /pcapper help

Dragging an attached, unlocked panel automatically detaches it and saves its new position.

## Craft-count semantics

Need is the number of skill points required to reach the next guide step.

For an orange recipe, one craft guarantees one skill-up, so the displayed craft count is exact. For yellow/green recipes, the addon shows a minimum because some crafts may not grant a point. The craft-to-target action queues only that minimum batch and stops early if the target is reached; if RNG leaves you short, use the Continue action.

The addon deliberately does not start another crafting batch automatically after an event because crafting is a protected player action.

## Supported professions

Primary: Alchemy, Blacksmithing, Enchanting, Engineering, Inscription, Jewelcrafting, Leatherworking and Tailoring.

Secondary: Cooking and First Aid.

Gathering professions and Fishing are not handled because they do not level through the same recipe-crafting flow.

## Installation

1. Download a release ZIP.
2. Extract it so the folder is named Profession_Capper.
3. Put that folder in World of Warcraft/Interface/AddOns/.
4. Reload the UI or restart the client.

## Guide data

Guide steps are declarative tables under Professions/. Structural validation guarantees complete, non-overlapping coverage from skill 1 through 449 and verifies that every referenced recipe has fallback metadata.

The external audit baseline and caveats are documented in docs/GUIDE-SOURCES.md. Realm prices can make a different valid recipe cheaper, so alternatives are preserved where useful.

## Development

Every push to master runs:

- Lua 5.1 syntax validation.
- TOC dependency/order checks.
- XML well-formedness validation.
- Full profession range validation.
- Recipe fallback-metadata validation.

Tags matching v* produce a ready-to-install Profession_Capper-<tag>.zip GitHub release.

## Credits

- SamuelLira99 — original Profession-Capper.
- DarkChimu — spell-ID matching and localization improvements.
- Utkuchix — additional localization, dynamic ingredients, availability sorting and fixes.

See the repository history for full attribution.
