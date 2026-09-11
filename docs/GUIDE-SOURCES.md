# Guide data audit baseline

Audit baseline recorded: 2026-09-11.

Profession Capper's recommendations originated in the upstream addon lineage. The v3 data model preserves those choices while making every skill range explicit and mechanically validated. The following current WotLK Classic guides are the external reference set used when reviewing transitions:

- Alchemy: https://www.wow-professions.com/wotlk/alchemy-leveling-guide-wotlk-classic
- Blacksmithing: https://www.wow-professions.com/wotlk/blacksmithing-leveling-guide-wotlk-classic
- Cooking: https://www.wow-professions.com/wotlk/cooking-leveling-guide-wotlk-classic
- Enchanting: https://www.wow-professions.com/wotlk/enchanting-leveling-guide-wotlk-classic
- Engineering: https://www.wow-professions.com/wotlk/engineering-leveling-guide-wotlk-classic
- First Aid: https://www.wow-professions.com/wotlk/first-aid-leveling-guide-wotlk-classic
- Inscription: https://www.wow-professions.com/wotlk/inscription-leveling-guide-wotlk-classic
- Jewelcrafting: https://www.wow-professions.com/wotlk/jewelcrafting-leveling-guide-wotlk-classic
- Leatherworking: https://www.wow-professions.com/wotlk/leatherworking-leveling-guide-wotlk-classic
- Tailoring: https://www.wow-professions.com/wotlk/tailoring-leveling-guide-wotlk-classic

## Audit rules

1. Every skill from 1 through 449 must resolve to exactly one guide step.
2. Every step must move forward to a higher target skill.
3. Every step must contain at least one recipe spell ID.
4. Every spell ID must have fallback recipe metadata.
5. Orange steps may show exact craft counts; yellow/green steps must be treated as minimums.
6. When several recipes are valid, the addon may keep alternatives and order learned options by current craftable quantity.
7. Realm economics are not encoded as universal truth. A recipe can be valid but not cheapest on every server.

## Known verified repair

The inherited data had an Enchanting hole at 184 and an Alchemy hole at 390-399 plus an overlap at 249. v3 repairs those structural errors. The Alchemy Northrend transition now includes Elixir of Mighty Strength at 385-395 before Mighty Agility, matching the current reference path.

Future recipe changes should update the relevant declarative profession table and include the source/rationale in the commit.
