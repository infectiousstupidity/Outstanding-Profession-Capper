#!/usr/bin/env python3
"""Validate addon packaging metadata and XML."""

from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "Profession_Capper.toc"
REQUIRED_ORDER = [
    "constants.lua",
    "Localization.lua",
    "Guide.lua",
    "CharacterSkill.lua",
    "RecipeDifficulty.lua",
    "RecipeDifficultyData.lua",
    "GeneratedRouteData.lua",
    "Performance.lua",
    "ProfessionBook.lua",
    "RouteData.lua",
    "RecipeCatalog.lua",
    "RecipeCatalogData.lua",
    "RecipeSourceLocations.lua",
    "MapLocations.lua",
    "RecipeAcquisition.lua",
    "RecipeAcquisitionData.lua",
    "ProfessionTraining.lua",
    "PriceProvider.lua",
    "TSMPriceProvider.lua",
    "RecipeCost.lua",
    "RouteSolver.lua",
    "ShoppingPlan.lua",
    "DynamicRecommendations.lua",
    "Settings.lua",
    "EnchantConfirmation.lua",
    "Session.lua",
]


def main():
    errors = []
    lines = [line.strip() for line in TOC.read_text(encoding="utf-8-sig").splitlines()]
    files = [line for line in lines if line and not line.startswith("##")]

    for path in files:
        normalized = path.replace("\\", "/")
        if not (ROOT / normalized).exists():
            errors.append(f"TOC references missing file: {path}")

    positions = {}
    for required in REQUIRED_ORDER:
        if required not in files:
            errors.append(f"TOC is missing required module: {required}")
        else:
            positions[required] = files.index(required)

    for earlier, later in zip(REQUIRED_ORDER, REQUIRED_ORDER[1:]):
        if earlier in positions and later in positions and positions[earlier] >= positions[later]:
            errors.append(f"TOC load order must place {earlier} before {later}")

    if "Profession_capper.xml" not in files:
        errors.append("TOC must load Profession_capper.xml")

    source_locations_text = (ROOT / "RecipeSourceLocations.lua").read_text(encoding="utf-8")
    if "zoneID = " in source_locations_text:
        errors.append("RecipeSourceLocations.lua must use explicit areaID/mapID fields, not legacy zoneID")
    if "mapID = " not in source_locations_text:
        errors.append("RecipeSourceLocations.lua must include WorldMapAreaID values for Show on map")
    for bad_name, area_id in (("Events", 12), ("Professions", 11), ("Class", 10), ("Eastern Kingdoms", 1)):
        bad_entry = f'zone = "{bad_name}", areaID = {area_id},'
        if bad_entry in source_locations_text:
            errors.append(f"Recipe source AreaTableID {area_id} is mislabeled as Questie category {bad_name}")

    core_text = (ROOT / "Core.lua").read_text(encoding="utf-8")
    acquisition_forward = core_text.find("local acquisitionWhereSummary")
    detail_panel = core_text.find("local function updateDetailPanel()")
    acquisition_definition = core_text.find("acquisitionWhereSummary = function(acquisition)")
    if not (0 <= acquisition_forward < detail_panel < acquisition_definition):
        errors.append(
            "Core.lua must forward-declare acquisitionWhereSummary before updateDetailPanel"
        )

    try:
        tree = ET.parse(ROOT / "Profession_capper.xml")
        details = next(
            (
                element
                for element in tree.getroot().iter()
                if element.tag.rsplit("}", 1)[-1] == "Frame"
                and element.attrib.get("name") == "$parentDetails"
            ),
            None,
        )
        if details is None:
            errors.append("Profession_capper.xml is missing the route-details frame")
        else:
            anchor = next(
                (
                    element
                    for element in details.iter()
                    if element.tag.rsplit("}", 1)[-1] == "Anchor"
                ),
                None,
            )
            if anchor is None or anchor.attrib.get("point") != "BOTTOMLEFT" \
                    or anchor.attrib.get("relativeTo") != "MainFrameCore" \
                    or anchor.attrib.get("relativePoint") != "BOTTOMLEFT":
                errors.append("Route details must be anchored inside MainFrameCore")
    except ET.ParseError as exc:
        errors.append(f"Profession_capper.xml is not well formed: {exc}")

    if errors:
        print("Addon validation failed:")
        for error in errors:
            print(" -", error)
        return 1

    print("Addon validation passed: TOC dependencies exist and XML is well formed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
