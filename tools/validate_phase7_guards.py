#!/usr/bin/env python3
"""Structural regression gates for Phase 7 runtime performance hardening."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(name: str) -> str:
    return (ROOT / name).read_text(encoding="utf-8")


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def main() -> int:
    errors: list[str] = []

    core = read("Core.lua")
    dynamic = read("DynamicRecommendations.lua")
    profession_book = read("ProfessionBook.lua")
    route_solver = read("RouteSolver.lua")
    shopping_plan = read("ShoppingPlan.lua")

    require(
        "professionRefreshCoordinator = addonTable.createRefreshCoordinator()" in core,
        "Core.lua must use the testable refresh coordinator",
        errors,
    )
    require(
        "incrementalRoute = true" in core,
        "optimized UI path must request incremental exact-route execution",
        errors,
    )
    require(
        "solveCheapestProfessionRoute" not in core,
        "Core.lua must not call the synchronous full route solver directly",
        errors,
    )
    require(
        "pcall(" in core
        and "computeDynamicProfessionRecommendation" in core
        and 'reason = "optimizer_error"' in core,
        "optimized UI path must retain the protected Static fallback boundary",
        errors,
    )

    bag_start = core.find('if event == "BAG_UPDATE" then')
    bag_end = core.find('if event == "LEARNED_SPELL_IN_TAB" then', bag_start)
    bag_block = core[bag_start:bag_end] if bag_start >= 0 and bag_end > bag_start else ""
    require(
        "noteRuntimeInventoryChanged" in bag_block,
        "BAG_UPDATE must advance the inventory revision",
        errors,
    )
    require(
        "invalidateProfessionBook" not in bag_block
        and "buildRecipeCache" not in bag_block
        and "withUnfilteredTradeSkill" not in bag_block,
        "BAG_UPDATE must not invalidate or directly scan the profession book",
        errors,
    )

    require(
        'eventName == "BAG_UPDATE"' in profession_book
        and 'return "preserve"' in profession_book,
        "profession-book policy must preserve identity on BAG_UPDATE",
        errors,
    )
    require(
        "character_switch" in profession_book and "ownerKey" in profession_book,
        "profession-book cache must be owner-scoped",
        errors,
    )

    require(
        "inventoryRevision" in dynamic
        and "providerRevision" in dynamic
        and "professionBook" in dynamic
        and "skill" in dynamic
        and "eligibility" in dynamic,
        "recommendation cache key must retain explicit runtime dependencies",
        errors,
    )
    require(
        "invalidateDynamicRecommendationCache" not in dynamic,
        "blanket dynamic-cache invalidation must not return",
        errors,
    )
    require(
        "getRouteRefreshKey" not in shopping_plan
        and "routeRefreshNeeded" not in shopping_plan,
        "obsolete serialized route-refresh keys must stay removed",
        errors,
    )

    require(
        "DEFAULT_ROUTE_SLICE_BUDGET_MS = 3" in route_solver,
        "incremental route solver must keep an explicit conservative default slice budget",
        errors,
    )
    require(
        "stepCheapestProfessionRouteJob" in route_solver
        and "createCheapestProfessionRouteJob" in route_solver,
        "route solver must retain resumable job entry points",
        errors,
    )
    require(
        "routeJobStillCurrent" in route_solver
        and "stale_inputs" in route_solver,
        "incremental route solver must retain stale-generation cancellation",
        errors,
    )
    require(
        "getActivePriceProviderState" in dynamic
        and "providerIdentity" in dynamic,
        "recommendation dependencies must include provider instance identity",
        errors,
    )

    price_provider = read("PriceProvider.lua")
    route_data = read("RouteData.lua")
    require(
        "providerInstanceCounter" in price_provider
        and "getActivePriceProviderIdentity" in price_provider,
        "provider cache namespace must change when a provider object is replaced",
        errors,
    )
    require(
        "CANDIDATE_INDEX_CACHE_MAX_ENTRIES" in route_data
        and "getGeneratedRouteCandidateCacheStats" in route_data,
        "generated route candidate indexes must remain explicitly bounded",
        errors,
    )
    require(
        "buildRecipeAcquisitionCodec" in route_solver
        and "recipeMask" in route_solver
        and "normalizeRecipeMask" in route_solver,
        "route solver must retain compact exact recipe-acquisition history",
        errors,
    )
    require(
        "peakLayerStates" in route_solver
        and 'reason = "state_limit_exceeded"' in route_solver,
        "route solver must hard-bound live exact acquisition states",
        errors,
    )

    if errors:
        print("Phase 7 structural guard validation failed:")
        for error in errors:
            print(" -", error)
        return 1

    print("Phase 7 structural guards passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
