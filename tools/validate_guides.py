#!/usr/bin/env python3
"""Validate Profession Capper guide rank coverage and target metadata."""

from pathlib import Path
import re
import sys

PROFESSIONS = Path(__file__).resolve().parents[1] / "Professions"
CONDITION_RE = re.compile(r"^\s*(?:if|elseif)\s+(rank.+?)\s+then\s*$")
TARGET_RE = re.compile(r"^\s*targetSkill\s*=\s*(\d+)\s*;?\s*$")


def condition_matches(condition: str, rank: int) -> bool:
    match = re.fullmatch(r"rank\s*>\s*(\d+)\s+and\s+rank\s*<\s*(\d+)", condition)
    if match:
        return rank > int(match.group(1)) and rank < int(match.group(2))

    match = re.fullmatch(r"rank\s*>=\s*(\d+)\s+and\s+rank\s*<\s*(\d+)", condition)
    if match:
        return int(match.group(1)) <= rank < int(match.group(2))

    match = re.fullmatch(r"rank\s*==\s*(\d+)", condition)
    if match:
        return rank == int(match.group(1))

    raise ValueError("Unsupported rank condition: " + condition)


def validate_file(path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    branches = []
    errors = []

    for index, line in enumerate(lines):
        match = CONDITION_RE.match(line)
        if not match:
            continue

        condition = match.group(1)
        target = None
        for following in lines[index + 1:index + 5]:
            target_match = TARGET_RE.match(following)
            if target_match:
                target = int(target_match.group(1))
                break
            if CONDITION_RE.match(following):
                break

        if target is None:
            errors.append(f"{path.name}:{index + 1}: branch has no targetSkill")
        branches.append((condition, target))

    for rank in range(1, 450):
        matches = [condition for condition, _ in branches if condition_matches(condition, rank)]
        if not matches:
            errors.append(f"{path.name}: skill {rank} has no guide step")
        elif len(matches) > 1:
            errors.append(f"{path.name}: skill {rank} matches multiple guide steps: {matches}")

    content = "\n".join(lines)
    if "return shouldCraft, shouldCraftRecipe, targetSkill" not in content:
        errors.append(f"{path.name}: handler does not return targetSkill")

    return errors


def main() -> int:
    errors = []
    for path in sorted(PROFESSIONS.glob("*.lua")):
        errors.extend(validate_file(path))

    if errors:
        print("Guide validation failed:")
        for error in errors:
            print(" -", error)
        return 1

    print("Guide validation passed: every profession covers skills 1-449 exactly once.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
