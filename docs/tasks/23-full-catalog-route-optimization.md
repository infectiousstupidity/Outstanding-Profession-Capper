# Task 23 — Full-catalog cheapest-route optimization

Status: DONE  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Tasks 07, 08, 09, 20, 21, and 22

## Goal

Make the bundled recipe universe, rather than only the live profession book, the optimizer input and make the global route the source of truth for the current recommendation.

## Implementation

- Added `buildFullProfessionOptimizationInput()`: all eligible catalog recipes for the active profession are merged with live profession-book data.
- Only live rows are marked learned. Unknown recipes keep bundled reagents, outputs, required skill and acquisition metadata.
- Character state now includes player level, faction, inventory, known prerequisite/specialization spells, queried reputation standings, learned recipes and reusable tools.
- Added `ProfessionTraining.lua` with deterministic WotLK profession-rank costs/requirements through 450. Dynamic routing targets the highest rank currently reachable by player level and can insert rank training into the route.
- The global cheapest route is computed first. Its first craft segment is the authoritative main recommendation; the old separate greedy current-step choice is no longer allowed to disagree with it.
- Green recipes are allowed when their expected skill-up-adjusted cost actually makes them cheaper; gray/unusable recipes remain excluded by the cost engine.
- Route segments retain their first cost/acquisition object so an unknown selected recipe exposes `nextAction = "acquire_recipe"` and cannot be mistaken for a live craftable row.
- If the complete route or shopping plan cannot be proven, dynamic mode falls back to the deterministic static guide.

## Regression coverage

Automated Lua 5.1 tests cover the required future-unlock scenario: craft a known recipe to the threshold, acquire a previously unknown trainer recipe once, then switch because the remainder is cheaper. The inverse high-acquisition-cost case stays on the known recipe.

Coverage also verifies:

- full catalog vs learned-state separation,
- unknown recipe selected as an acquisition-first action,
- Blood Elf +10 Enchanting threshold behavior,
- profession-rank training followed by a newly useful recipe,
- current inventory/prerequisite state capture,
- no external recipe addon dependency,
- static fallback when the price provider is unavailable.

All deterministic acceptance criteria pass in CI.
