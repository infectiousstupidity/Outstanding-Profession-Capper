# Runtime cache ownership

Task 34 makes runtime reuse dependency-aware instead of clearing all dynamic state after volatile events.

## Revision model

`RuntimeState.lua` owns small numeric generations:

- `skill` — profession name, trained/base skill, trained cap, active modifier, or effective cap changed;
- `inventory` — incremented by `BAG_UPDATE`;
- `eligibility` — learned-spell, player-level, or reputation eligibility changed;
- `mode` — recommendation mode changed;
- `manual` — explicit exceptional invalidation;
- `professionBook` — mirrored whenever Task 33 stores a new profession-book snapshot.

The Task 33 profession-book snapshot also exposes its own per-snapshot generation. Recommendation keys use that profession-specific generation when available.

Target skill, optimization objective, provider identity/revision, availability mode, and bundled acquisition revision are direct key fields rather than large serialized tables.

## Cache layers and bounds

### Inventory counts

Owner: `RuntimeState.lua`.

Key cardinality is item IDs within the current inventory generation. The cache is discarded on `BAG_UPDATE` and retains at most 2,048 item counts.

### Provider price data

Owner: `PriceProvider.lua`.

The cache stores raw provider results, including negative/missing results. Keys are provider identity + provider revision + normalized item identity. Normalization and price age are recalculated on read, so a cached raw scan can become stale naturally as time passes.

Providers with a revision retain values until that revision changes or the entry is evicted. Providers without a revision use a conservative 15-second TTL. The cache retains at most 512 entries. Inventory, skill, profession-book, and recommendation-mode changes do not clear it.

### Canonical optimizer recipes

Owner: `DynamicRecommendations.lua`.

Bundled catalog records are converted lazily to canonical optimizer recipe objects. Unknown/static recipes reuse these exact immutable structures across recommendation passes. Live learned-recipe data is overlaid separately by spell ID.

Cardinality is bounded by the bundled catalog itself (currently 3,552 records); no runtime/user-derived key can grow this cache beyond catalog size.

### Recommendation + shopping-plan result

Owner: `DynamicRecommendations.lua`.

The key explicitly includes profession-book, skill, inventory, eligibility, mode/manual generations, provider identity/revision, availability mode, optimization objective, target skill, and acquisition-data revision.

The cache retains at most 8 recommendation results and each result has a 15-second reuse TTL. The TTL also prevents time-sensitive availability/freshness presentation from remaining indefinitely unchanged even when a provider revision is stable.

Before a freshly computed result is stored or returned, the captured runtime/provider revisions are checked again. If an input generation changed during calculation, the result is rejected with `runtime_inputs_changed`.

## Event behavior

`BAG_UPDATE` now advances only inventory state. It no longer destroys static recipe or provider-price caches.

`LEARNED_SPELL_IN_TAB` invalidates the Task 33 profession book and advances character eligibility. A successful rescan stores a new profession-book generation.

Equipment/aura refreshes rely on the skill-context comparison. They advance the skill generation only when the effective profession context actually changes.

`PLAYER_LEVEL_UP` and `UPDATE_FACTION` advance eligibility and schedule a normal recommendation refresh.
