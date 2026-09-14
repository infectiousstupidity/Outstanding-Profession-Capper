#!/usr/bin/env python3
"""Generate RecipeSourceLocations.lua from pinned WotLK source databases.

Usage:
  python3 tools/generate_recipe_source_locations.py \
      RecipeAcquisitionData.lua \
      creature_default_trainer.sql \
      wotlkNpcDB.lua \
      lookupZones.lua \
      RecipeSourceLocations.lua
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

QUESTIE_REVISION = "215b0c757e2cefdffc11414b2c70456e37573cc2"
AZEROTHCORE_REVISION = "f1bef3bc0a2f6396175e184c2cac70df77b46d11"


def lua_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def main() -> int:
    if len(sys.argv) != 6:
        print(__doc__.strip())
        return 2

    acquisition = Path(sys.argv[1]).read_text(encoding="utf-8")
    creature_default_trainer = Path(sys.argv[2]).read_text(encoding="utf-8")
    npc_db = Path(sys.argv[3]).read_text(encoding="utf-8")
    zone_db = Path(sys.argv[4]).read_text(encoding="utf-8")
    output = Path(sys.argv[5])

    trainer_ids: set[int] = set()
    npc_ids: set[int] = set()
    for line in acquisition.splitlines():
        source_type_match = re.search(r'sourceType = "(trainer|vendor|limited_vendor|reputation)"', line)
        if not source_type_match:
            continue
        source_type = source_type_match.group(1)
        trainer = re.search(r"trainerID = (\d+)", line)
        vendor = re.search(r"vendorID = (\d+)", line)
        source = re.search(r"sourceID = (\d+)", line)
        if source_type == "trainer":
            identifier = trainer or source
            if identifier:
                trainer_ids.add(int(identifier.group(1)))
        else:
            identifier = vendor or source
            if identifier:
                npc_ids.add(int(identifier.group(1)))

    trainer_groups: dict[int, list[int]] = {}
    for creature_id, trainer_id in re.findall(r"\((\d+),(\d+)\)", creature_default_trainer):
        trainer_id = int(trainer_id)
        if trainer_id in trainer_ids:
            trainer_groups.setdefault(trainer_id, []).append(int(creature_id))
            npc_ids.add(int(creature_id))

    zone_names: dict[int, str] = {}
    for zone_id, name in re.findall(r'^\s*\[(\d+)\]\s*=\s*"((?:\\.|[^"])*)",?', zone_db, re.M):
        zone_names.setdefault(int(zone_id), name.replace('\\"', '"').replace("\\\\", "\\"))

    npcs: dict[int, dict] = {}
    for line in npc_db.splitlines():
        match = re.match(r"^\[(\d+)\]\s*=\s*\{'((?:\\.|[^'])*)'", line)
        if not match:
            continue
        npc_id = int(match.group(1))
        if npc_id not in npc_ids:
            continue

        name = match.group(2).replace("\\'", "'").replace("\\\\", "\\")
        faction_match = re.search(r',"(A|H|AH)",', line)
        faction = {"A": "alliance", "H": "horde", "AH": "neutral"}.get(
            faction_match.group(1) if faction_match else ""
        )

        by_zone = {}
        for zone_id, x, y in re.findall(r"\[(\d+)\]\s*=\s*\{\{(-?[\d.]+),(-?[\d.]+)", line):
            zone_id, x, y = int(zone_id), float(x), float(y)
            if x < 0 or y < 0 or x > 100 or y > 100:
                continue
            by_zone.setdefault(zone_id, {
                "zone": zone_names.get(zone_id, f"Area {zone_id}"),
                "x": x,
                "y": y,
            })
        if by_zone:
            npcs[npc_id] = {"name": name, "faction": faction, "locations": by_zone}

    lines = [
        "local addonName, addonTable = ...",
        "",
        "-- Generated from Questie WotLK NPC spawn data plus AzerothCore trainer-group mappings.",
        "-- Sources:",
        f"--   Questie/Questie @ {QUESTIE_REVISION}",
        f"--   AzerothCore/azerothcore-wotlk @ {AZEROTHCORE_REVISION}",
        "-- Only NPCs referenced by bundled recipe acquisition metadata are included.",
        "",
        'addonTable.recipeSourceLocationDataRevision = "questie-215b0c7+acore-f1bef3b"',
        "local npcLocations = {",
    ]

    for npc_id in sorted(npcs):
        npc = npcs[npc_id]
        lines.append(f"    [{npc_id}] = {{")
        lines.append(f"        name = {lua_quote(npc['name'])},")
        if npc["faction"]:
            lines.append(f"        faction = {lua_quote(npc['faction'])},")
        lines.append("        locations = {")
        for zone_id in sorted(npc["locations"]):
            location = npc["locations"][zone_id]
            lines.append(
                "            { zone = %s, zoneID = %d, x = %.2f, y = %.2f },"
                % (lua_quote(location["zone"]), zone_id, location["x"], location["y"])
            )
        lines.extend(["        },", "    },"])

    lines.extend(["}", "", "local trainerGroups = {"])
    for trainer_id in sorted(trainer_ids):
        npc_group = sorted(set(trainer_groups.get(trainer_id, [])))
        if npc_group:
            lines.append(
                f"    [{trainer_id}] = {{ " + ", ".join(map(str, npc_group)) + " },"
            )

    lines.extend([
        "}",
        "",
        "addonTable.recipeSourceNpcLocations = npcLocations",
        "addonTable.recipeSourceTrainerGroups = trainerGroups",
        "",
        "local function appendNpcLocations(result, npcID)",
        "    local npc = npcLocations[tonumber(npcID)]",
        "    if not npc then return end",
        "    for index = 1, table.getn(npc.locations or {}) do",
        "        local source = npc.locations[index]",
        "        table.insert(result, {",
        "            npcID = tonumber(npcID),",
        "            name = npc.name,",
        "            faction = npc.faction,",
        "            zone = source.zone,",
        "            zoneID = source.zoneID,",
        "            coordinates = { x = source.x, y = source.y },",
        "        })",
        "    end",
        "end",
        "",
        "function addonTable.getRecipeSourceLocations(entry)",
        '    if type(entry) ~= "table" then return {} end',
        "    local sourceType = entry.sourceType or entry.source",
        "    local result = {}",
        "",
        '    if sourceType == "trainer" then',
        "        local trainerID = tonumber(entry.trainerID or entry.sourceID)",
        "        local npcIDs = trainerID and trainerGroups[trainerID] or nil",
        '        if type(npcIDs) == "table" then',
        "            for index = 1, table.getn(npcIDs) do",
        "                appendNpcLocations(result, npcIDs[index])",
        "            end",
        "        elseif trainerID then",
        "            appendNpcLocations(result, trainerID)",
        "        end",
        '    elseif sourceType == "vendor"',
        '        or sourceType == "limited_vendor"',
        '        or sourceType == "reputation"',
        "    then",
        "        appendNpcLocations(result, entry.vendorID or entry.sourceID)",
        "    end",
        "",
        "    return result",
        "end",
        "",
    ])

    output.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {output} with {len(npcs)} located recipe-source NPCs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
