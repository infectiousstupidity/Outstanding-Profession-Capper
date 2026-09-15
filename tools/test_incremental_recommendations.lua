local addonTable = {}

local owned = { [1001] = 0 }

function GetItemCount(itemID)
    return owned[itemID] or 0
end

function UnitFactionGroup()
    return "Alliance"
end

addonTable.getActivePriceProviderName = function()
    return "fixture"
end

addonTable.getActivePriceProviderRevision = function()
    return "1"
end

addonTable.lookupItemPrice = function(item)
    return {
        item = item,
        available = true,
        minBuyout = 100,
        source = "fixture",
        freshness = "fresh",
    }
end

addonTable.chooseUsableUnitPrice = function(result)
    if not result or not result.available then return nil, "missing" end
    return {
        unitPrice = result.minBuyout,
        priceType = "auction",
        source = result.source,
        freshness = result.freshness,
    }
end

addonTable.isRecipeEligibleForDynamicOptimization = function()
    return true
end

addonTable.getRecipeDifficultyMetadata = function()
    return {
        requiredSkill = 0,
        graySkill = 2,
    }
end

addonTable.calculateRecipeCost = function(recipe)
    local cheap = recipe.spellID == 10
    local cost = cheap and 50 or 100
    return {
        available = true,
        useful = true,
        difficulty = "orange",
        skillUpChance = 1,
        expectedCraftsPerSkillUp = 1,
        currentPurchaseCostPerCraft = cost,
        expectedCurrentPurchaseCostPerSkillUp = cost,
        materialMarketValuePerCraft = cost,
        expectedMarketCostPerSkillUp = cost,
        goldNeededNowPerCraft = cost,
        expectedGoldNeededNowPerSkillUp = cost,
        oneTimeCosts = {},
        reagentCosts = {},
        quality = "complete",
        availableNow = not cheap,
        availabilityConfidence = cheap and "unavailable" or "fresh_listing",
    }
end

addonTable.buildProfessionShoppingPlan = function(route)
    return {
        complete = route.complete,
        estimatedCurrentPurchaseCost = route.totalCurrentPurchaseCost,
        estimatedMarketValueCost = route.totalMarketCost,
        estimatedGoldNeededNow = route.totalGoldCost,
        totalExpectedCrafts = route.totalExpectedCrafts,
        stalePriceCount = 0,
        missingPriceCount = 0,
    }
end

assert(loadfile("RuntimeState.lua"))("Profession_Capper", addonTable)
assert(loadfile("RouteSolver.lua"))("Profession_Capper", addonTable)
assert(loadfile("DynamicRecommendations.lua"))("Profession_Capper", addonTable)

local cache = {
    [10] = {
        name = "Cheap but not available now",
        skillType = "optimal",
        reagents = {{ itemID = 1001, count = 1, owned = 0 }},
    },
    [11] = {
        name = "Available",
        skillType = "optimal",
        reagents = {{ itemID = 1001, count = 1, owned = 0 }},
    },
}

local context = {
    professionName = "Enchanting",
    baseSkill = 0,
    effectiveSkill = 0,
    activeSkillModifier = 0,
    currentCap = 1,
}

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format(
            "%s: expected %s, got %s",
            label,
            tostring(expected),
            tostring(actual)
        ))
    end
end

local function finishPending(pending)
    local fake = 0
    local function clock()
        fake = fake + 0.6
        return fake
    end

    local status = "running"
    local result = pending
    local slices = 0
    while status == "running" do
        status, result = addonTable.stepDynamicProfessionRecommendation(
            pending,
            1,
            clock
        )
        slices = slices + 1
        assert(slices < 1000, "incremental recommendation must finish")
    end
    assertEqual(status, "completed", "recommendation completion status")
    return result, slices
end

local syncCheapest = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    { targetSkill = 1 }
)
assertEqual(syncCheapest.currentSegment.recipeID, 10, "synchronous Cheapest semantics")

addonTable.invalidateDynamicRecommendationCache()
local pendingCheapest = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    {
        targetSkill = 1,
        incrementalRoute = true,
    }
)
assertEqual(pendingCheapest.calculating, true, "cold incremental result is pending")
assertEqual(pendingCheapest.available, false, "local candidate is not published as exact Cheapest")
assertEqual(table.getn(pendingCheapest.candidates), 0, "pending state exposes no approximate ranking")
local asyncCheapest, cheapestSlices = finishPending(pendingCheapest)
assert(cheapestSlices > 1, "Cheapest route spans multiple fake-clock slices")
assertEqual(asyncCheapest.currentSegment.recipeID, syncCheapest.currentSegment.recipeID, "Cheapest exact equivalence")
assertEqual(asyncCheapest.routeComplete, true, "Cheapest exact route published atomically")

local syncAvailable = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    {
        targetSkill = 1,
        requireAvailableNow = true,
    }
)
assertEqual(syncAvailable.currentSegment.recipeID, 11, "synchronous Available semantics")

addonTable.invalidateDynamicRecommendationCache()
local pendingAvailable = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    {
        targetSkill = 1,
        requireAvailableNow = true,
        incrementalRoute = true,
    }
)
assertEqual(pendingAvailable.available, false, "Available mode stays pending before exact route")
local asyncAvailable = finishPending(pendingAvailable)
assertEqual(asyncAvailable.currentSegment.recipeID, syncAvailable.currentSegment.recipeID, "Available exact equivalence")
assertEqual(asyncAvailable.routeComplete, true, "Available exact route complete")

addonTable.invalidateDynamicRecommendationCache()
local stalePending = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    {
        targetSkill = 1,
        incrementalRoute = true,
    }
)
addonTable.noteRuntimeInventoryChanged()
local staleStatus, staleResult = addonTable.stepDynamicProfessionRecommendation(
    stalePending,
    1,
    function() return 1 end
)
assertEqual(staleStatus, "cancelled", "inventory generation cancels old recommendation")
assertEqual(staleResult.reason, "runtime_inputs_changed", "stale job cannot publish")
assert(stalePending._incremental == nil, "cancelled recommendation drops job closure")

addonTable.invalidateDynamicRecommendationCache()
local explicitPending = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    {
        targetSkill = 1,
        incrementalRoute = true,
    }
)
assert(addonTable.cancelDynamicProfessionRecommendation(explicitPending, "profession_closed"))
assert(explicitPending._incremental == nil, "explicit cancellation drops route job")
assert(explicitPending.recipes == nil, "explicit cancellation releases optimizer recipes")
assert(explicitPending.state == nil, "explicit cancellation releases optimizer state")

print("Incremental recommendation tests passed")
