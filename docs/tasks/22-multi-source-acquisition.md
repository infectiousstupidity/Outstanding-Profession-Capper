# Task 22 — Multi-source acquisition and character eligibility engine

Status: DONE  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Tasks 20 and 21

## Goal

Resolve every acquisition path for a recipe against the current character and simulated route state, then select the cheapest reliable source without promoting conditional sources to guaranteed ones.

## Implementation

`RecipeAcquisition.lua` now evaluates all bundled records for a recipe. The resolver exposes `resolveRecipeAcquisitionPaths()` for the full candidate set and `resolveRecipeAcquisition()` for the cheapest currently reliable candidate.

Reliable paths include:

- already learned recipes,
- recipe items already owned,
- trainer and unlimited-vendor sources with satisfied requirements and a known non-zero cost,
- reputation vendors after the required standing is satisfied,
- current Auction House listings for recipe items.

Limited-stock vendors, quests, drops/world drops without a current AH listing, manual sources, unmet reputation/faction requirements and ambiguous zero/missing prices remain conditional/unavailable. All alternatives are retained on the selected result for later UI explanation.

## Character and route state

Profession-skill gates use the route solver's simulated base skill plus the active profession modifier. Player level, faction, reputation, specialization/prerequisite spells and inventory use current character state.

A recipe acquired earlier in a simulated route is recognized through the existing `recipe:<spellID>` one-time key. This prevents its learning cost from being charged again.

## Dynamic recipe-item handling

Static recipe/source knowledge remains bundled. The configured price provider is consulted only for the current AH price of a known recipe item. A drop/manual recipe can therefore become a reliable route candidate when its recipe item is actually listed on the AH.

## Validation

The Lua 5.1 acquisition test covers:

- learned and owned recipe states,
- trainer vs AH and vendor vs AH price choice,
- limited-stock exclusion,
- drop recipe made reliable by an AH listing,
- reputation and faction gates,
- active +profession skill and future simulated-skill unlocks,
- ambiguous zero prices remaining unavailable,
- one-time acquisition cost charged exactly once by the route solver,
- all 3,552 catalog recipes retaining explicit acquisition coverage.

All acceptance criteria are deterministic and covered by CI.
