# Task 19 — Final visual QA and compatibility polish

Status: QUEUED  
Phase: 5 — UI/UX polish  
Depends on: Tasks 15–18

## Goal

Finish Phase 5 with an evidence-based visual/interaction cleanup rather than accumulating one-off spacing fixes.

## Review matrix

Test at minimum:

- Enchanting, Cheapest now, complete current pricing.
- Enchanting with +profession modifier.
- Equivalent Greater/Lesser Essence recommendation.
- Missing material prices.
- Stale TSM prices.
- No price provider / static fallback.
- Static guide mode.
- Targeted enchant: no target yet.
- Targeted enchant: remembered bag target.
- Targeted enchant: remembered equipped target.
- Fixed repeat count.
- Until-change repeat.
- Another crafting profession with normal batch crafting.
- Comparison collapsed.
- Comparison expanded.
- Full route available.
- Full route unavailable.
- ElvUI enabled.
- ElvUI disabled.

## Visual QA checklist

Check:

- no overlapping text;
- no clipped long recipe/item names;
- consistent left/right alignment;
- consistent section spacing;
- no accidental double separators;
- no large empty areas;
- no button that visually competes with the primary action;
- color remains readable against the backdrop;
- selected mode is obvious without relying on text alone;
- stale/missing/error states are distinguishable;
- material cost columns line up;
- panel height shrinks/grows correctly.

## Interaction QA checklist

Check:

- drag/lock behavior;
- close/reopen;
- /reload persistence;
- switching Cheapest now / Static guide;
- Compare toggle;
- compact/expanded toggle;
- Shift-Right-Click AH search;
- item modified-click behavior;
- enchant repeat target capture;
- enchant repeat target reuse;
- auto-confirm existing enchant;
- fixed repeat count editing;
- normal batch crafting.

## Cleanup

During this task only:

- remove presentation code made obsolete by Tasks 15–18;
- remove duplicate tooltip copy if the same data is now inline;
- consolidate repeated layout constants;
- remove dead named XML frames;
- do not refactor optimizer/business logic unless required to fix a demonstrated bug.

## Acceptance artifacts

Before marking DONE, add a short section to this doc recording:

- tested WoW client/build;
- tested ElvUI state/version if known;
- UI scale used;
- screenshots/manual observations;
- any intentionally deferred visual issues.

## Commit

Suggested message: `fix: finish profession capper visual polish`
