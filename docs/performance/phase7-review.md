# Phase 7 holistic review

Review target: Phase 7 runtime-performance architecture through Task 36  
Status: CODE REVIEW COMPLETE; REAL-CLIENT ACCEPTANCE PENDING

The code review was completed under explicit continuation even though the original WoW 3.3.5 before/after matrix has not yet been recorded. This document therefore separates deterministic code findings from claims that require the real client.

## Defects fixed

### 1. Provider replacement shared stale identity

Before the review, the provider raw-price cache used provider name + provider revision + item. An in-flight recommendation also compared only provider name/revision.

If a provider object was re-registered under the same name and exposed the same revision, both mechanisms considered it unchanged.

Fix:

- every provider registration receives a monotonically increasing session instance ID;
- raw price keys include provider instance identity;
- revisioned lookup closures capture the instance identity already observed by the recommendation;
- recommendation cache/job dependencies include provider name + instance identity + revision;
- the combined provider-state read avoids redundant provider-selection checks.

Regression coverage verifies that a same-name/same-revision replacement queries the replacement provider, an old captured lookup returns `provider_changed`, and a pending recommendation is cancelled when provider identity changes.

### 2. Generated candidate-index retention was too large

`RouteData.lua` cached one full candidate index for every profession/modifier value encountered and never evicted it. The modifier range is finite, but each index contains 450 skill snapshots, so modifier churn could retain substantial session memory.

Fix:

- cache capped at 16 profession/modifier entries;
- eviction queue bounded and compacted;
- cache stats exposed;
- `/pcapper perf` retained-cache line now includes candidate-index entries;
- deterministic tests exceed the bound and verify both entries and queue remain bounded.

## Substantial semantic issue discovered

### Recipe learning is not truly one-time after Task 29

Task 23 specified one-time recipe acquisition in route state. Task 29 later removed persistent `recipe:<id>` keys from route state to stop combinatorial memory growth.

Current behavior is therefore:

- acquiring an unlearned recipe is charged when a route segment activates it;
- continuing that same segment does not repay;
- switching away and later returning can conservatively pay the acquisition again.

This was intentional in Task 29, but it is a semantic drift from true one-time recipe learning and can alter exact route totals/selection. The attempted review regression exposed this directly.

A safe fix requires a more compact representation of learned/acquired recipes rather than restoring the old arbitrary acquisition-set state. That work is queued as **Task 38** and was not hidden inside this review.

## Solver duplication

Production optimized UI uses the Task 35 layered route-job state machine. `RouteSolver.lua` still also contains the older heap-based non-layered solver for callers that omit `layeredDynamicProgramming = true`.

No stale-publication problem was found in that legacy path, but duplicated craft/training transition logic is a long-term semantic-drift risk. Consolidation is queued as **Task 39**, after Task 38 establishes the corrected acquisition semantics and an explicit equivalence corpus.

## Stale-publication review

After the provider-instance fix, no remaining known path was found that can publish an exact incremental result after a known dependency changes.

Dependencies cover:

- profession-book generation;
- skill/cap/modifier generation;
- inventory generation;
- eligibility generation;
- recommendation-mode generation;
- provider name;
- provider instance identity;
- provider revision when exposed;
- target, optimization mode, availability mode, and acquisition-data revision through the recommendation key.

Jobs recheck dependencies before additional slices and before final cache/publication. Core also supersedes the currently owned job when a new refresh begins.

Providers that expose no revision remain intentionally TTL-based. Their raw values may remain cached for at most the configured 15 seconds because there is no stronger external change signal.

## Event and profession-book lifecycle

The review found no reason for BAG_UPDATE or unchanged warm reopen to rediscover recipe identity.

Current ownership:

- profession recipe-book identity/live overlay: `ProfessionBook.lua`;
- character owner: profession-book owner key;
- skill/cap/modifier: RuntimeState skill generation;
- inventory: inventory generation + bounded count cache;
- provider prices: provider instance + revision + item;
- eligibility: learned spell / level / reputation generation;
- recommendation mode: mode generation;
- exact result: bounded dependency-keyed recommendation cache;
- in-progress exact route: cancellable job-local state.

Trade-skill filter/header mutation remains guarded by `tradeSkillStateMutation` plus a short restoration suppression window, preventing self-generated TRADE_SKILL_UPDATE amplification from recursively rescanning.

## Cache-bound review

Reviewed runtime caches:

- inventory counts: max 2,048 per generation;
- provider raw prices: max 512, bounded queue;
- recommendation results: max 8, bounded queue;
- generated candidate indexes: max 16 after this review;
- pass-local recipe costs: max 4,096 per recommendation;
- acquired-signature memo: weak-keyed and pass-local;
- canonical optimizer recipes: bounded by bundled catalog cardinality;
- profession snapshots: supported professions for active owner only;
- route-job working state: released on completion/cancellation.

No unbounded Phase 7 cache remains identified.

## Immutable catalog review

Canonical bundled recipe objects are reused across recommendation passes; learned recipes use separate live overlays. No production assignment into canonical recipe/reagent fields was found.

They are not deep-frozen with proxy tables. That remains intentional because Lua 5.1 proxy immutability would add complexity and hot-path overhead. Existing tests verify recommendation passes do not mutate canonical reagent quantities.

## Static / Cheapest / Available

Static remains independent from optimizer success. Dynamic computation is protected; a hard optimizer exception falls back to Static rather than making the addon unusable.

Safe review fixes did not intentionally alter Cheapest or Available behavior.

Known approximation that remains:

- owned ordinary reagents affect Cheapest economics;
- ordinary reagent depletion is not modeled as complete route state;
- recipe acquisition is currently segment-scoped, not truly one-time across non-contiguous segments;
- Shopping Plan performs more complete aggregate material accounting.

## Performance evidence

Deterministic tests prove structural properties: bounded caches, warm exact-result reuse, stale-job cancellation, event coalescing, scanner reuse, provider replacement isolation.

Real-client before/after measurements: **not recorded yet**.

Therefore this review does not claim a specific Enchanting cold-open time, warm-open time, maximum slice, or retained-heap stability. Those remain pending in `phase7-regression-report.md`.

## Final handoff

Defects fixed:

1. provider instance identity added to price/recommendation dependencies;
2. generated candidate-index cache bounded.

Substantial issues queued:

- **Task 38:** restore true one-time recipe acquisition semantics without reintroducing state explosion;
- **Task 39:** consolidate legacy heap and layered route transition implementations after acquisition semantics are settled.

Tests changed:

- provider replacement regression in price-provider tests;
- pending-job cancellation on provider-instance replacement;
- candidate-index cache/queue bound regression;
- Phase 7 structural guards for provider identity and candidate-index bounds.

Before/after performance measurements: not available; real-client capture remains pending.

Remaining risks:

- real WoW frame/event timing and heap behavior are unmeasured;
- segment-scoped recipe acquisition can overcharge non-contiguous reuse;
- duplicated route solver implementations remain until Task 39;
- unknown-revision providers necessarily rely on TTL;
- Cheapest ordinary-inventory route state remains intentionally approximate.
