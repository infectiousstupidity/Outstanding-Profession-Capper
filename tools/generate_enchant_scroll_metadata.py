#!/usr/bin/env python3
"""Generate deterministic WotLK enchant scroll/vellum metadata.

The checked-in source snapshot is derived from pinned numeric sources documented
inside tools/data/enchant_scroll_metadata_source.json. Runtime classification
never uses localized spell/item names or tooltips.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "data" / "enchant_scroll_metadata_source.json"
CATALOG = ROOT / "RecipeCatalogData.lua"
OUTPUT = ROOT / "EnchantScrollData.lua"

VELLUM_TIER_BY_ITEM = {38682: 1, 37602: 2, 43145: 3, 39349: 1, 39350: 2, 43146: 3}
VELLUM_TARGET_BY_ITEM = {38682: "armor", 37602: "armor", 43145: "armor", 39349: "weapon", 39350: "weapon", 43146: "weapon"}


def lua_string(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'


def parse_catalog():
    records = {}
    pattern = re.compile(
        r'spellID\s*=\s*(\d+).*profession\s*=\s*"Enchanting".*'
        r'outputItemID\s*=\s*(nil|\d+)'
    )
    for line in CATALOG.read_text(encoding="utf-8").splitlines():
        match = pattern.search(line)
        if match:
            records[int(match.group(1))] = (
                None if match.group(2) == "nil" else int(match.group(2))
            )
    return records


def classify(record):
    output_item_id = record["catalogOutputItemID"]
    crosscheck_item_id = record["scrollCrosscheckItemID"]
    item_class = record["equippedItemClass"]

    if (
        crosscheck_item_id is not None
        and output_item_id is not None
        and crosscheck_item_id != output_item_id
    ):
        return {"vellumEligible": False, "classification": "source_conflict"}

    if record["slot"] == "FINGER0SLOT":
        return {"vellumEligible": False, "classification": "personal_enchant"}

    if item_class in (2, 4):
        if output_item_id is None:
            return {"vellumEligible": False, "classification": "no_scroll_output"}
        target_type = "weapon" if item_class == 2 else "armor"
        vellum_item_id = record.get("minimumVellumItemID")
        if vellum_item_id not in VELLUM_TIER_BY_ITEM:
            return {"vellumEligible": False, "classification": "vellum_mapping_missing"}
        if VELLUM_TARGET_BY_ITEM[vellum_item_id] != target_type:
            return {"vellumEligible": False, "classification": "vellum_target_mismatch"}
        return {
            "vellumEligible": True,
            "scrollItemID": output_item_id,
            "targetType": target_type,
            "minVellumTier": VELLUM_TIER_BY_ITEM[vellum_item_id],
        }

    if output_item_id is None:
        return {"vellumEligible": False, "classification": "no_output_item"}

    return {"vellumEligible": False, "classification": "non_vellum_craft"}


def validate_source(source):
    if source.get("schemaVersion") != 1:
        raise RuntimeError("unsupported source schema")

    records = source.get("records")
    if not isinstance(records, list):
        raise RuntimeError("source records missing")

    catalog = parse_catalog()
    source_ids = {record["spellID"] for record in records}
    if source_ids != set(catalog):
        missing = sorted(set(catalog) - source_ids)
        extra = sorted(source_ids - set(catalog))
        raise RuntimeError(
            "source/catalog spell set mismatch: missing=%r extra=%r"
            % (missing[:10], extra[:10])
        )

    seen = set()
    for record in records:
        spell_id = record["spellID"]
        if spell_id in seen:
            raise RuntimeError("duplicate source spell ID %d" % spell_id)
        seen.add(spell_id)

        if record["expansion"] not in ("classic", "bcc", "wrath"):
            raise RuntimeError("invalid expansion for spell %d" % spell_id)
        if record["catalogOutputItemID"] != catalog[spell_id]:
            raise RuntimeError("catalog output changed for spell %d" % spell_id)

        for field in (
            "catalogOutputItemID",
            "scrollCrosscheckItemID",
            "equippedItemClass",
            "minimumVellumItemID",
        ):
            value = record.get(field)
            if value is not None and (not isinstance(value, int) or value <= 0):
                raise RuntimeError("invalid %s for spell %d" % (field, spell_id))


def render(source):
    records = sorted(source["records"], key=lambda record: record["spellID"])
    classified = [(record, classify(record)) for record in records]
    eligible_count = sum(1 for _, metadata in classified if metadata["vellumEligible"])
    unknown_count = sum(
        1
        for _, metadata in classified
        if metadata.get("classification") == "source_conflict"
    )

    provenance = source["provenance"]
    primary = provenance["primaryCatalog"]
    crosscheck = provenance["numericTargetCrosscheck"]
    core = provenance["coreSemantics"]
    vellum = provenance["vellumCompatibilityCrosscheck"]

    lines = [
        "local addonName, addonTable = ...",
        "",
        "-- Generated by tools/generate_enchant_scroll_metadata.py. Do not hand-edit.",
        "addonTable.enchantScrollMetadataProvenance = {",
        "    schemaVersion = 1,",
        "    recordCount = %d," % len(records),
        "    eligibleCount = %d," % eligible_count,
        "    unknownCount = %d," % unknown_count,
        "    primaryCatalog = { repository = %s, commit = %s, file = %s },"
        % (
            lua_string(primary["repository"]),
            lua_string(primary["commit"]),
            lua_string(primary["file"]),
        ),
        "    numericTargetCrosscheck = { repository = %s, commit = %s, file = %s },"
        % (
            lua_string(crosscheck["repository"]),
            lua_string(crosscheck["commit"]),
            lua_string(crosscheck["file"]),
        ),
        "    vellumCompatibilityCrosscheck = { repository = %s, commit = %s, file = %s },"
        % (
            lua_string(vellum["repository"]),
            lua_string(vellum["commit"]),
            lua_string(vellum["file"]),
        ),
        "    coreSemantics = { repository = %s, commit = %s },"
        % (lua_string(core["repository"]), lua_string(core["commit"])),
        '    tierRule = "pinned spell-to-vellum mapping; compatible vellums are minVellumTier and higher",',
        "}",
        "",
        "addonTable.enchantVellumCatalog = {",
        "    armor = {",
        "        { tier = 1, itemID = 38682, maxEnchantLevelRestriction = 0 },",
        "        { tier = 2, itemID = 37602, maxEnchantLevelRestriction = 35 },",
        "        { tier = 3, itemID = 43145, maxEnchantLevelRestriction = 60 },",
        "    },",
        "    weapon = {",
        "        { tier = 1, itemID = 39349, maxEnchantLevelRestriction = 0 },",
        "        { tier = 2, itemID = 39350, maxEnchantLevelRestriction = 35 },",
        "        { tier = 3, itemID = 43146, maxEnchantLevelRestriction = 60 },",
        "    },",
        "}",
        "",
        "addonTable.enchantScrollMetadata = {",
    ]

    for record, metadata in classified:
        spell_id = record["spellID"]
        expansion = lua_string(record["expansion"])
        if metadata["vellumEligible"]:
            lines.append(
                "    [%d] = { vellumEligible = true, scrollItemID = %d, "
                "targetType = %s, minVellumTier = %d, sourceExpansion = %s },"
                % (
                    spell_id,
                    metadata["scrollItemID"],
                    lua_string(metadata["targetType"]),
                    metadata["minVellumTier"],
                    expansion,
                )
            )
        elif metadata["classification"] == "source_conflict":
            lines.append(
                '    [%d] = { vellumEligible = false, classification = "source_conflict", '
                "catalogOutputItemID = %d, crosscheckItemID = %d, sourceExpansion = %s },"
                % (
                    spell_id,
                    record["catalogOutputItemID"],
                    record["scrollCrosscheckItemID"],
                    expansion,
                )
            )
        else:
            lines.append(
                "    [%d] = { vellumEligible = false, classification = %s, "
                "sourceExpansion = %s },"
                % (
                    spell_id,
                    lua_string(metadata["classification"]),
                    expansion,
                )
            )

    lines.extend(
        [
            "}",
            "",
            "function addonTable.getEnchantScrollMetadata(spellID)",
            "    local id = tonumber(spellID)",
            "    return id and addonTable.enchantScrollMetadata[id] or nil",
            "end",
            "",
            "function addonTable.getCompatibleEnchantVellums(spellID)",
            "    local metadata = addonTable.getEnchantScrollMetadata(spellID)",
            "    if not metadata or not metadata.vellumEligible then",
            "        return nil, nil",
            "    end",
            "    return addonTable.enchantVellumCatalog[metadata.targetType], metadata.minVellumTier",
            "end",
            "",
        ]
    )
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    validate_source(source)
    generated = render(source)

    if args.check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != generated:
            print("EnchantScrollData.lua is stale; run tools/generate_enchant_scroll_metadata.py")
            return 1
        print(
            "Generated enchant scroll metadata is up to date "
            "(%d records)." % len(source["records"])
        )
        return 0

    OUTPUT.write_text(generated, encoding="utf-8")
    print("Wrote %s" % OUTPUT.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
