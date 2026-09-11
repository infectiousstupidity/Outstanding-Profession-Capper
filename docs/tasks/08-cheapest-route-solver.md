# Task 08 — Cheapest route solver

Status: DONE  
Phase: 3 — Cost engine and optimizer  
Depends on: Tasks 01, 04, 05, 07

## Goal

Find the cheapest viable profession-leveling route from the character's current state to the current profession cap.

## Algorithm

Use a deterministic global optimizer such as dynamic programming / shortest-path over profession skill states.

Do not use a purely greedy "cheapest next craft" algorithm.

The solver must be able to choose a slightly more expensive immediate step when it reduces total future cost.

## Route state

Account for:

- trained/base skill
- active skill modifiers
- recipe skill-up probability
- learned recipes
- recipe acquisition
- profession-rank training gates
- reusable rods/tools/intermediate items
- inventory already owned
- current price data
- recipes that cannot reasonably be acquired

## Safety

If dynamic data is incomplete enough to make the result unreliable, return an incomplete route and fall back to the deterministic static guide.

Never fabricate missing prices or recipe acquisition.

## Outputs

At minimum:

- ordered route segments
- skill range for each segment
- recipe
- expected craft count
- expected material cost
- expected acquisition cost
- cumulative cost
- confidence/missing-data information

## Implementation notes

Implemented on 2026-09-11:

- Added `RouteSolver.lua` using a deterministic Dijkstra/shortest-path search over profession skill, trained-cap, and one-time acquisition/reusable state.
- The default optimization target is market-value route cost. Gold-needed-now remains tracked for reporting, while Task 09 performs authoritative whole-route inventory subtraction.
- Recipe acquisition is charged once. Reusable tools/reagents are carried as state and are not charged again after acquisition.
- Recipe metadata may declare reusable outputs so a crafted persistent prerequisite can satisfy later route state.
- Profession-rank training is modeled as explicit same-skill state transitions that raise the trained cap and include their acquisition cost.
- Active +profession modifiers are passed through to the Task 07 cost engine at every skill state.
- Missing/incomplete prices, acquisition metadata, or training metadata cannot be guessed into a valid route.
- Search is bounded by a configurable state limit (default 20,000). Hitting the limit returns an incomplete route and preserves the static-guide fallback instead of risking an unbounded client-side search.
- Adjacent uses of the same recipe are compacted into ordered route segments with expected crafts and cumulative costs.

As with Task 07, the solver is implemented before Tasks 04/05 populate the production recipe graph. It is not wired into the live recommendation UI yet.

## Automated validation

`tools/test_route_solver.lua` covers:

- a constructed case where global optimization beats a greedy cheapest-next-craft choice
- a valid route reaching its target
- incomplete dynamic data returning the static-guide fallback
- explicit profession-rank training gates and costs
- active +profession modifiers changing route choice
- reusable one-time state being charged once
- bounded search returning safely when the state limit is exceeded

## Manual checks

No live route is selected in-game by Task 08. The static guide is still the only user-facing recommendation source until production metadata and Task 10 integration exist.

## Acceptance criteria

- PASS — solver reaches the target when a valid route exists.
- PASS — gray/unusable recipes are rejected by the cost contract and cannot become route edges.
- PASS — recipes unavailable under the acquisition model are rejected before route selection.
- PASS — +profession modifiers materially affect route choice where appropriate.
- PASS — a constructed test case proves the solver can beat a greedy next-step choice.
- PASS — static-guide fallback remains intact for incomplete/no-route cases.

## Commit

Suggested message: `feat: add cheapest profession route solver`
