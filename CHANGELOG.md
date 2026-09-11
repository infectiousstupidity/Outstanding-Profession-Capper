# Changelog

## v3.0.0-alpha4 — 2026-09-11

- Reworked the panel spacing and recipe hierarchy for better readability.
- Replaced problematic Unicode separators/arrows in core status text with WoW-safe ASCII.
- Added singular/plural skill-up wording.
- Split recipe states into explicit "Recipe not learned" and "Missing materials" messages.
- Replaced the wrapped materials sentence with a vertical material list.
- Added reagent icons, item-quality names, owned/required counts and item tooltips.
- Added normal WoW modified-item-click behavior on material rows.
- Added Shift+Right-click to insert a reagent name into the Blizzard Auction House browse search.
- Made panel height adapt to the number of materials.


## v3.0.0-alpha3 — 2026-09-11

- Replaced profession rank if/elseif chains with declarative guide tables.
- Added target skill, needed skill-ups, craft-count semantics and ETA.
- Added bounded craft-to-target sessions with stop-at-target behavior.
- Added live crafting progress and safe Continue handling for failed skill-ups.
- Added filter-independent recipe scanning that restores the Blizzard profession view.
- Added training-cap handling.
- Added compact attached UI plus persistent position, attach/detach and lock settings.
- Added /pcapper management commands.
- Split UI localization from recipe fallback-name data.
- Fixed Enchanting skill 184 coverage.
- Fixed Alchemy 249 overlap and 390-399 gap; restored the Mighty Strength transition.
- Added Lua 5.1, TOC/XML and guide-data CI validation.
- Added automatic release ZIP generation for version tags.

## v2.0.0

Upstream Outstanding/Improved Profession Capper baseline: spell-ID matching, localization support, dynamic reagent names, availability sorting and compatibility fixes.
