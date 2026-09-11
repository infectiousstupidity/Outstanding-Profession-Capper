#!/usr/bin/env python3
"""Validate declarative Profession Capper guide data."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PROFESSIONS = ROOT / "Professions"
STEP_RE = re.compile(
    r"\{\s*minSkill\s*=\s*(\d+)\s*,\s*targetSkill\s*=\s*(\d+)\s*,\s*recipes\s*=\s*\{(.*?)\}\s*,?\s*\}",
    re.S,
)


def parse_steps(path: Path):
    content = path.read_text(encoding="utf-8")
    steps = []
    for match in STEP_RE.finditer(content):
        min_skill = int(match.group(1))
        target_skill = int(match.group(2))
        recipes = [int(value) for value in re.findall(r"\d+", match.group(3))]
        steps.append((min_skill, target_skill, recipes))
    return steps


def validate_file(path: Path):
    errors = []
    steps = parse_steps(path)

    if not steps:
        return [f"{path.name}: no declarative guide steps found"]

    coverage = {rank: 0 for rank in range(1, 450)}
    previous_target = 1

    for index, (min_skill, target_skill, recipes) in enumerate(steps, start=1):
        if min_skill >= target_skill:
            errors.append(f"{path.name}: step {index} has invalid range {min_skill}-{target_skill}")
        if min_skill != previous_target:
            errors.append(f"{path.name}: step {index} starts at {min_skill}; expected {previous_target}")
        if not recipes:
            errors.append(f"{path.name}: step {index} has no recipes")
        if len(set(recipes)) != len(recipes):
            errors.append(f"{path.name}: step {index} contains duplicate recipe IDs")

        for rank in range(max(1, min_skill), min(450, target_skill)):
            coverage[rank] += 1

        previous_target = target_skill

    if steps[0][0] != 1:
        errors.append(f"{path.name}: guide must begin at skill 1")
    if steps[-1][1] != 450:
        errors.append(f"{path.name}: guide must end at skill 450")

    for rank, count in coverage.items():
        if count == 0:
            errors.append(f"{path.name}: skill {rank} has no guide step")
        elif count > 1:
            errors.append(f"{path.name}: skill {rank} is covered by {count} guide steps")

    return errors


def main():
    errors = []
    files = sorted(PROFESSIONS.glob("*.lua"))
    for path in files:
        errors.extend(validate_file(path))

    if len(files) != 10:
        errors.append(f"expected 10 profession guide files, found {len(files)}")

    if errors:
        print("Guide validation failed:")
        for error in errors:
            print(" -", error)
        return 1

    print("Guide validation passed: declarative guides cover skills 1-449 exactly once.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
