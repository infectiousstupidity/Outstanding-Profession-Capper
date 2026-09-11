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
    "Settings.lua",
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

    try:
        ET.parse(ROOT / "Profession_capper.xml")
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
