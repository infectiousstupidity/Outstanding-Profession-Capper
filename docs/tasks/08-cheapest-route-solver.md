# Task 08 — Cheapest route solver

Status: QUEUED  
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

## Acceptance criteria

- Solver reaches the cap when a valid route exists.
- Solver does not use gray recipes.
- Solver does not use recipes that are unavailable under the acquisition model.
- +profession modifiers materially affect route choice where appropriate.
- A constructed test case proves the solver can beat a greedy next-step choice.
- Static guide fallback remains intact.

## Commit

Suggested message: `feat: add cheapest profession route solver`
