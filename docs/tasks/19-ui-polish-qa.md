# Task 19 — Final visual QA and compatibility polish

Status: IN PROGRESS  
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

## Cleanup findings from 2026-09-13 in-game review

The current live UI exposed three concrete cleanup issues:

- Compare rows looked like table rows but had no mouse interaction, so there was no way to inspect the materials behind a candidate recipe.
- Expanded route details showed misleading `oldest age unknown · 0 stale · 0 missing` coverage when the full route was unavailable.
- Static guide mode still exposed an expanded `Route details` control even though current-price route details are intentionally inactive, and single-option static steps displayed a redundant `1 / 1` counter.

Implemented on master pending final in-game verification:

- Compare rows are real mouse-enabled buttons with hover/click material tooltips showing recipe difficulty, per-application cost, per-skill-up cost, required materials, and current owned counts.
- Incomplete routes no longer render fake zero/unknown coverage statistics.
- Static guide hides the Details control/detail block while preserving the persisted detail preference for when Cheapest now is selected again.
- Static guide suppresses the recipe-position counter when there is only one option.

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
