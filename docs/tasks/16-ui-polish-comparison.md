# Task 16 — Inline recipe comparison and optimizer explanation

Status: DONE  
Phase: 5 — UI/UX polish  
Depends on: Task 15

## Goal

Make it obvious why Profession Capper selected the current recipe.

The user should not need to trust a black box or decode a tooltip.

## Implement

Change `Compare` from a hover-only explanation into a toggle for a compact inline comparison section.

Default rows:

```text
WHY THIS ONE
1  Greater Agility   Yellow   ~2g 40s/app   ~3g 20s/skill-up
2  Major Mana        Yellow   ~3g 10s/app   ~4g 08s/skill-up
3  Major Health      Orange   ~4g 80s/app   ~4g 80s/skill-up
```

Use existing `dynamicRecommendation.candidates`.

## Rules

- Order by the exact ranking used by Cheapest now.
- Current winner is visibly highlighted.
- Show live recipe difficulty.
- Show cost/application and expected cost/skill-up.
- Green recipes must not appear as Cheapest-now competitors.
- Mark stale-price candidates.
- If a candidate cannot be priced, either omit it with a clear summary or show `price unavailable`; do not display zero.
- Show a maximum sensible number of rows by default. If more exist, use a small `+N more` control.
- Do not make the section a nested card.

## Route detail

If a complete route exists, comparison detail may continue with a short `Route` subsection.

If a full route does not exist, say so briefly without making the current-step recommendation look invalid.

## Interaction

- Click `Compare` to show/hide.
- Do not require hover.
- Preserve the existing tooltip only if it still adds useful detail; otherwise remove duplicate information.
- Toggling compare must not change the selected recipe.

## Suggested file changes

- `Core.lua`
- `Profession_capper.xml`
- `Localization.lua`

## Implementation note

Implemented on master pending in-game acceptance.

The old hover-only GameTooltip dump is removed from the Compare interaction. The button now toggles a real companion panel anchored to the main Profession Capper window.

Current comparison:

- shows the top five ranked candidates by default;
- uses the optimizer's existing candidate order without re-ranking;
- guards against green/gray recipes even if upstream data changes;
- highlights the winner and shows each alternative's extra expected cost per skill-up versus the winner;
- marks stale-price rows directly;
- supports a progressive `Show N more` control up to the top ten candidates;
- keeps the selected recipe unchanged.

Full route:

- lives behind a separate tab so route detail does not compete with current-step comparison;
- shows range, recipe/training step, expected crafts, and estimated cost;
- shows the estimated remaining total when available;
- uses one brief unavailable message when the route is incomplete.

The panel closes with the main addon, closes when Static guide is selected, and refreshes while open after recommendation updates.

## Acceptance criteria

- Player can explain why the winner beat the #2 candidate from visible numbers.
- Ranking matches optimizer order.
- Orange/yellow live difficulty matches the TradeSkill window.
- Current winner is visually obvious.
- Stale/missing prices are clearly distinguished.
- Incomplete full route does not disable current comparison.
- Panel resizes cleanly when comparison opens/closes.
- Comparison remains readable with at least five candidates.

## Manual acceptance

Accepted in-game on 2026-09-13. The user reviewed the live Phase 5 UI and explicitly requested that the prior Phase 5 blockers be closed so remaining presentation issues can move into Task 19 cleanup.

## Commit

Suggested message: `feat: show inline cheapest-recipe comparison`
