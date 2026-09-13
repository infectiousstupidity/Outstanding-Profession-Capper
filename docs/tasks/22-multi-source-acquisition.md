# Task 22 — Multi-source acquisition and character eligibility engine

Status: QUEUED  
Phase: 6 — Self-contained full recipe optimization  
Depends on: Tasks 20 and 21

## Goal

Resolve all acquisition paths for a recipe against the current character and route state, and expose the cheapest reliable way to acquire an unknown recipe.

## Core behavior

`RecipeAcquisition.lua` must support multiple candidate acquisition paths instead of one effective record per recipe.

For each recipe, resolve every source into a normalized state such as:

- already learned
- recipe item already owned
- trainable now
- purchasable from an unlimited vendor now
- purchasable from the Auction House now
- reputation/faction gated
- limited-stock/conditional
- quest gated
- drop/world-drop conditional
- unknown/manual

Then choose the cheapest currently reliable acquisition for optimization while retaining the other paths for UI/explanation.

## Dynamic acquisition sources

Static source knowledge comes from Profession Capper's bundled database.

Dynamic state may come from:

- WoW APIs for learned recipes, inventory, player level, faction, reputation and other character prerequisites
- the configured price provider for a tradeable recipe item's current Auction House price

TSM may supply current market prices. It must not supply static recipe/source knowledge.

## Reliability policy

The guaranteed cheapest route may use:

- already learned recipes
- owned recipe items
- verified trainer recipes with satisfied requirements and known cost
- verified unlimited vendor recipes with satisfied requirements and known cost
- tradeable recipe items with a current usable Auction House price
- reputation/vendor recipes only when all requirements are satisfied and the source is deterministically obtainable

The guaranteed route must not assume availability of:

- random drops
- world drops with no current AH listing
- unfinished quest chains
- unmet reputation requirements
- limited-stock vendors
- unknown/manual sources

Those sources remain visible as conditional alternatives.

## Simulated route skill fix

Acquisition eligibility must use the skill value being simulated by the route solver.

Example:

- character is currently 290
- route reaches 300
- a trainer recipe requires 300

When evaluating the node at 300, the recipe must become trainable even though the character was 290 when the route computation began.

Use:

`simulated base skill + active profession modifier`

for profession-skill gates.

Continue using current character state for player level, faction, reputation, specialization, inventory, and other non-route attributes.

## One-time acquisition

Learning/buying a recipe is a one-time route cost.

The resolver/cost engine must expose enough acquisition metadata for the solver and UI to know:

- which source was chosen
- acquisition gold/market cost
- whether the recipe must be learned before crafting
- the acquisition key used to prevent charging the cost again

## Automated validation

Cover at minimum:

- learned recipe wins with zero acquisition cost
- owned recipe item is recognized
- trainer vs AH chooses the cheaper reliable acquisition
- vendor vs AH chooses the cheaper reliable acquisition
- limited-stock source is not treated as guaranteed
- drop source becomes usable when its tradeable recipe item is currently on the AH
- reputation/faction requirements are enforced
- active +profession skill affects profession requirement gates correctly
- future simulated skill unlocks a trainer recipe
- acquisition cost is charged once across multiple route steps
- missing acquisition price never becomes zero

## Acceptance criteria

- Every recipe can expose multiple acquisition paths.
- The optimizer can select the cheapest reliable path without pretending conditional sources are guaranteed.
- Future skill unlocks are evaluated against simulated route skill.
- Acquisition remains conservative when data or dynamic availability is incomplete.
