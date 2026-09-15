# Task 33 — Profession scan lifecycle and event invalidation

Status: QUEUED  
Phase: 7 — Runtime performance hardening  
Depends on: Task 32

## Goal

Stop treating volatile character changes as a reason to rediscover the profession book.

The expensive Blizzard trade-skill scan should run only when recipe-book structure or live profession-row data actually needs to be refreshed. Bag changes and unrelated state changes must not trigger the filter-clear / header-expand / full recipe scan path.

Preserve all existing recommendation semantics.

## Current problem

The profession-open path uses `withUnfilteredTradeSkill()` to snapshot the Blizzard profession UI, clear filters, expand headers, scan recipe rows, and restore the user's view.

That operation is legitimate when the addon must rediscover recipes. It is not a correct general-purpose refresh primitive.

In particular, `BAG_UPDATE` currently invalidates the dynamic recommendation and schedules a forced profession refresh. That can lead to another profession scan even though moving or buying an item cannot teach or remove profession recipes.

## Required design

Separate profession knowledge into two categories.

Durable/session-cached profession-book data:

- recipe spell ID;
- recipe identity/name;
- output link/item where available;
- stable profession membership.

Live row data that may need refresh when the profession book itself changes:

- live skill color/type;
- Blizzard `numAvailable`;
- any other value obtained directly from the open trade-skill row and proven to affect current UI behavior.

Do not cache inventory, prices, skill modifier, or acquisition eligibility inside the profession-book snapshot.

## Invalidation rules

Define explicit invalidation reasons instead of using one generic "refresh everything" path.

At minimum:

- initial profession open -> scan;
- switching to a different profession -> scan;
- `LEARNED_SPELL_IN_TAB` -> invalidate recipe-book snapshot and scan when relevant;
- profession skill/color changes -> refresh only the live fields that actually changed, unless the Blizzard API requires a scan;
- `BAG_UPDATE` -> must not invalidate the recipe-book snapshot;
- price changes -> must not invalidate the recipe-book snapshot;
- equipment/aura changes that only alter +profession skill -> must not rediscover recipe identity.

If the 3.3.5 API forces a broader scan for a specific case, document that case and why.

## UI preservation

The scan must continue to preserve the player's profession-window state:

- filters;
- collapsed/expanded headers;
- selected recipe;
- scroll position.

Do not make the profession UI visibly jump merely to save time.

## Event-storm protection

Use the Task 32 instrumentation to prove that one user action cannot recursively cause multiple full scans because the addon itself changed profession filters/header state.

Keep the existing mutation guard or replace it with a simpler mechanism only if tests and profiling show the replacement is safe.

## Tests

Add regression tests for invalidation behavior. Tests should assert behavior/call counts rather than implementation details where possible.

Required cases:

- repeated unchanged `TRADE_SKILL_UPDATE` does not rescan;
- `BAG_UPDATE` does not rescan the profession book;
- learning a recipe causes the snapshot to be refreshed;
- switching professions cannot reuse the wrong snapshot;
- +profession modifier changes update recommendation inputs without pretending the recipe set changed;
- Static, Cheapest and Available still receive the live information they require.

Add counters/test hooks only if they are not shipped as expensive production behavior.

## Manual acceptance

Using Task 32 perf output:

1. Open Enchanting cold and record one profession scan.
2. Close/reopen unchanged and confirm the scan is reused when safe.
3. Move a relevant reagent between bags/bank-equivalent inventory states supported by the client and confirm no profession rescan is caused solely by that bag event.
4. Learn a recipe and confirm it appears after the appropriate rescan.
5. Change an applicable +profession item/aura and confirm effective skill updates without unnecessary recipe rediscovery.

## Acceptance criteria

- Full repository validation passes.
- Bag changes no longer trigger profession-book rediscovery.
- Learned recipe changes still become visible correctly.
- Profession switching cannot leak cached data between professions.
- Live skill color/type remains correct for the current recommendation.
- Task 32 measurements show a reduction in scan count and no new event loop.
- Recommendation outputs remain semantically unchanged for identical inputs.

## Non-goals

- Do not redesign optimizer caching here.
- Do not change TSM price caching here.
- Do not make the route solver asynchronous here.
- Do not change the meaning of Cheapest or Available.
