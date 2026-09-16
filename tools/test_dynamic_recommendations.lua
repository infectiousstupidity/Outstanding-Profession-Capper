local addonTable = {}

local owned = {
    [6218] = 1,
    [1001] = 4,
}

function GetItemCount(itemID)
    return owned[itemID] or 0
end

function UnitFactionGroup()
    return "Alliance"
end

addonTable.isRecipeEligibleForDynamicOptimization = function(spellID)
    return spellID == 10 or spellID == 11 or spellID == 12
end

local providerName = "fixture"
addonTable.getActivePriceProviderName = function()
    return providerName
end

local priceLookupCalls = 0
addonTable.lookupItemPrice = function(item)
    priceLookupCalls = priceLookupCalls + 1
    return {
        item = item,
        available = true,
        minBuyout = 100,
        source = "fixture",
        freshness = "fresh",
        ageSeconds = 60,
    }
end

local recipeCostCalls = 0
local sawAvailableModeCost = false
addonTable.calculateRecipeCost = function(recipe, skill, _, _, options)
    recipeCostCalls = recipeCostCalls + 1
    if options and options.requireAvailableNow then
        sawAvailableModeCost = true
    end
    local id = recipe.spellID
    if id == 10 then
        return {
            available = true,
            useful = true,
            difficulty = "green",
            skillUpChance = 0.4,
            expectedCraftsPerSkillUp = 2.5,
            currentPurchaseCostPerCraft = 300,
            expectedCurrentPurchaseCostPerSkillUp = 750,
            materialMarketValuePerCraft = 300,
            expectedMarketCostPerSkillUp = 750,
            quality = "complete",
            reagentCosts = {},
            availableNow = true,
            availabilityConfidence = "fresh_listing",
        }
    elseif id == 11 then
        return {
            available = true,
            useful = true,
            difficulty = "orange",
            skillUpChance = 1,
            expectedCraftsPerSkillUp = 1,
            currentPurchaseCostPerCraft = 200,
            expectedCurrentPurchaseCostPerSkillUp = 200,
            materialMarketValuePerCraft = 200,
            expectedMarketCostPerSkillUp = 200,
            quality = "complete",
            reagentCosts = {},
            availableNow = false,
            availabilityConfidence = "unavailable",
        }
    elseif id == 12 then
        return {
            available = true,
            useful = true,
            difficulty = "green",
            skillUpChance = 0.5,
            expectedCraftsPerSkillUp = 2,
            currentPurchaseCostPerCraft = 20,
            expectedCurrentPurchaseCostPerSkillUp = 40,
            materialMarketValuePerCraft = 20,
            expectedMarketCostPerSkillUp = 40,
            quality = "complete",
            reagentCosts = {},
            availableNow = true,
            availabilityConfidence = "fresh_listing",
        }
    end
    return { available = false }
end

local solverCalls = 0
addonTable.solveCheapestProfessionRoute = function(recipes, context, state, options)
    solverCalls = solverCalls + 1
    assert(table.getn(recipes) == 3, "eligible learned recipes should be passed to optimizer")
    assert(options.targetSkill == 225, "optimizer should target current trained cap")
    assert(options.optimizeFor == "current", "route should optimize current purchase cost")
    assert(type(options.costRecipe) == "function", "full route should enforce orange/yellow-only costs")
    local callsBeforeRouteCost = recipeCostCalls
    local greenRouteCost = options.costRecipe(recipes[3], context.baseSkill, context, state, options.costOptions or {})
    assert(greenRouteCost.available == false, "green recipe must not be usable in full dynamic route")
    assert(greenRouteCost.unavailableReason == "not_orange_or_yellow", "green route exclusion reason")
    assert(recipeCostCalls == callsBeforeRouteCost, "route should reuse cached current-skill recipe costs")
    if options.costOptions and options.costOptions.requireAvailableNow then
        local unavailableRouteCost = options.costRecipe(
            recipes[2],
            context.baseSkill,
            context,
            state,
            options.costOptions
        )
        assert(unavailableRouteCost.available == false, "available route must reject stale/unavailable materials")
        assert(unavailableRouteCost.unavailableReason == "materials_not_available_now", "available route exclusion reason")
    end
    assert(state.learnedRecipes[10] == true, "learned recipe state should be populated")
    assert(state.inventory[1001] == 4, "live inventory should be populated")
    assert(state.acquiredOneTime["item:6218"] == true, "owned enchanting rod should be reusable")
    return {
        complete = false,
        reason = "no_complete_route",
        segments = {},
        actions = {},
    }
end

addonTable.buildProfessionShoppingPlan = function()
    error("shopping plan should not run for incomplete route")
end

assert(loadfile("DynamicRecommendations.lua"))("Profession_Capper", addonTable)

local commonReagents = {
    {
        name = "Dust",
        itemLink = "|cffffffff|Hitem:1001:0:0:0:0:0:0:0|h[Dust]|h|r",
        count = 1,
        owned = 4,
    },
    {
        name = "Runed Copper Rod",
        itemLink = "|cffffffff|Hitem:6218:0:0:0:0:0:0:0|h[Runed Copper Rod]|h|r",
        count = 1,
        owned = 1,
    },
}

local cache = {
    [10] = {
        name = "Yellow recipe",
        skillType = "medium",
        reagents = commonReagents,
    },
    [11] = {
        name = "Orange recipe",
        skillType = "optimal",
        reagents = commonReagents,
    },
    [12] = {
        name = "Green recipe",
        skillType = "easy",
        reagents = commonReagents,
    },
}

local recommendation = addonTable.computeDynamicProfessionRecommendation(cache, {
    professionName = "Enchanting",
    baseSkill = 200,
    effectiveSkill = 210,
    activeSkillModifier = 10,
    currentCap = 225,
})

assert(recommendation.available == true, "current recommendation should survive incomplete full route")
assert(recommendation.fallbackToStaticGuide == false, "priced current step should not fall back")
assert(recommendation.currentSegment.recipeID == 11, "cheapest orange/yellow recipe should win")
assert(table.getn(recommendation.candidates) == 2, "green recipe must not compete")
assert(recommendation.candidates[1].recipeID == 11, "candidates should be sorted by expected cost per skill-up")
assert(recommendation.candidates[2].recipeID == 10, "second priced orange/yellow recipe")
assert(recommendation.candidates[2].difficulty == "yellow", "live game difficulty must override stale static color")
assert(math.abs(recommendation.candidates[2].skillUpChance - 0.75) < 0.0001, "mismatched live yellow uses safe current estimate")
assert(recommendation.routeComplete == false, "full route should remain explicitly incomplete")
assert(recommendation.routeReason == "no_complete_route", "full-route failure reason should be preserved")
assert(solverCalls == 1, "solver should still attempt full route")
local cachedRecommendation = addonTable.computeDynamicProfessionRecommendation(cache, {
    professionName = "Enchanting",
    baseSkill = 200,
    effectiveSkill = 210,
    activeSkillModifier = 10,
    currentCap = 225,
})
assert(cachedRecommendation == recommendation, "identical profession state should reuse cached recommendation")
assert(solverCalls == 1, "cached reopen must not rerun the route solver")
assert(type(recommendation.priceLookup) == "function", "recommendation should expose its pass-local price cache")
recommendation.priceLookup(1001)
recommendation.priceLookup(1001)
assert(priceLookupCalls == 1, "pass-local price cache should query each item once")

local availableRecommendation = addonTable.computeDynamicProfessionRecommendation(cache, {
    professionName = "Enchanting",
    baseSkill = 200,
    effectiveSkill = 210,
    activeSkillModifier = 10,
    currentCap = 225,
}, {
    requireAvailableNow = true,
})
assert(availableRecommendation.available == true, "available mode should find a fresh purchasable alternative")
assert(availableRecommendation.currentSegment.recipeID == 10, "available mode should skip the cheaper unavailable recipe")
assert(table.getn(availableRecommendation.availableCandidates) == 1, "only one orange/yellow candidate is available now")
assert(availableRecommendation.availableCandidates[1].recipeID == 10, "freshly available candidate should be exposed")
assert(solverCalls == 2, "available mode should also attempt an availability-constrained route")
assert(sawAvailableModeCost == true, "available mode must reach recipe costing so confirmed sources can be selected")

providerName = "null"
local noProvider = addonTable.computeDynamicProfessionRecommendation(cache, {
    professionName = "Enchanting",
    baseSkill = 200,
    currentCap = 225,
})
assert(noProvider.available == false, "missing provider should disable dynamic mode")
assert(noProvider.reason == "no_price_provider", "missing provider reason")
assert(noProvider.fallbackToStaticGuide == true, "missing provider should fall back")

addonTable.lookupItemPrice = function()
    return {
        available = true,
        minBuyout = 100,
        source = "fixture",
        freshness = "fresh",
        ageSeconds = 60,
    }
end
addonTable.chooseUsableUnitPrice = function(result)
    return {
        unitPrice = result.minBuyout,
        priceType = "auction",
        source = result.source,
        freshness = result.freshness,
        ageSeconds = result.ageSeconds,
    }
end

local price = addonTable.getMaterialPriceInfo(1001, 3)
assert(price.available == true, "material price should resolve")
assert(price.estimatedRemainingCost == 300, "material purchase estimate")

addonTable.chooseCheapestEquivalentPurchase = function(item, quantity, purpose)
    assert(item == 16202, "converted material item")
    assert(quantity == 3, "converted material quantity")
    assert(purpose == "purchase", "converted material uses purchase price")
    return {
        effectiveUnitPrice = 300,
        sourceUnitPrice = 900,
        sourceQuantity = 1,
        requestedQuantity = 3,
        producedQuantity = 3,
        excessQuantity = 0,
        totalCost = 900,
        directTotalCost = 1200,
        alternateTotalCost = 900,
        savings = 300,
        priceType = "auction",
        source = "fixture",
        freshness = "fresh",
        ageSeconds = 60,
        sourceItemID = 16203,
        converted = true,
        conversionRatio = 3,
        conversionDirection = "greater_to_lesser",
    }
end

local converted = addonTable.getMaterialPriceInfo(16202, 3)
assert(converted.available == true, "converted material price available")
assert(converted.sourceItemID == 16203, "converted source item exposed")
assert(converted.sourceQuantity == 1, "converted source quantity exposed")
assert(converted.estimatedRemainingCost == 900, "converted whole-item total exposed")
assert(converted.directTotalCost == 1200, "direct comparison total exposed")
assert(converted.savings == 300, "converted savings exposed")

assert(addonTable.formatCopperShort(123456) == "12g 34s", "compact money formatting")
assert(addonTable.formatPriceAge(7200) == "2h old", "scan age formatting")

providerName = "fixture"
assert(loadfile("RouteSolver.lua"))("Profession_Capper", addonTable)

local reviewRecipes = {
    { spellID = 101, name = "Review bridge", profession = "Enchanting", reagents = {} },
    { spellID = 102, name = "Review acquired", profession = "Enchanting", reagents = {} },
}
local reviewCosts = {
    [101] = { [0] = 2, [1] = 3, [2] = 200 },
    [102] = { [0] = 1, [1] = 100, [2] = 101 },
}

addonTable.isRecipeEligibleForDynamicOptimization = function()
    return true
end

addonTable.getRecipeDifficultyMetadata = function()
    return {
        requiredSkill = 0,
        yellowSkill = 4,
        greenSkill = 4,
        graySkill = 4,
    }
end

addonTable.buildFullProfessionOptimizationInput = function()
    return reviewRecipes, {
        baseSkill = 0,
        currentCap = 3,
        reachableCap = 3,
        inventory = {},
        learnedRecipes = {
            [101] = true,
            [102] = false,
        },
        acquiredOneTime = {},
        trainingSteps = {},
        fullCatalog = true,
    }
end

addonTable.calculateRecipeCost = function(recipe, skill, _, state)
    local key = "recipe:" .. tostring(recipe.spellID)
    local acquired = state.acquiredOneTime and state.acquiredOneTime[key] == true
    local continuing = state.routeActiveRecipeID ~= nil
        and tostring(state.routeActiveRecipeID) == tostring(recipe.spellID)
    local oneTimeCosts = {}

    if recipe.spellID == 102 and not acquired and not continuing then
        oneTimeCosts = {{
            key = key,
            kind = "recipe_acquisition",
            marketCost = 10,
            goldCost = 10,
        }}
    end

    local material = reviewCosts[recipe.spellID][skill]
    return {
        available = material ~= nil,
        useful = material ~= nil,
        difficulty = "orange",
        skillUpChance = 1,
        expectedCraftsPerSkillUp = 1,
        currentPurchaseCostPerCraft = material,
        expectedCurrentPurchaseCostPerSkillUp = material,
        materialMarketValuePerCraft = material,
        expectedMarketCostPerSkillUp = material,
        goldNeededNowPerCraft = material,
        expectedGoldNeededNowPerSkillUp = material,
        oneTimeCosts = oneTimeCosts,
        reagentCosts = {},
        quality = "complete",
        availableNow = true,
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

local exactAcquisitionRecommendation = addonTable.computeDynamicProfessionRecommendation(
    {},
    {
        professionName = "Enchanting",
        baseSkill = 0,
        effectiveSkill = 0,
        activeSkillModifier = 0,
        currentCap = 3,
    },
    {
        targetSkill = 3,
        optimizeFor = "current",
    }
)

assert(exactAcquisitionRecommendation.routeComplete == true, "exact acquisition route completes")
assert(table.getn(exactAcquisitionRecommendation.route.actions) == 3, "exact acquisition route has three crafts")
assert(exactAcquisitionRecommendation.route.actions[1].recipeID == 102, "dynamic route acquires recipe first")
assert(exactAcquisitionRecommendation.route.actions[2].recipeID == 101, "dynamic route switches away")
assert(exactAcquisitionRecommendation.route.actions[3].recipeID == 102, "dynamic route returns to learned recipe")
assert(
    exactAcquisitionRecommendation.route.totalCurrentPurchaseCost == 115,
    "dynamic pass-local cost cache preserves one-time acquisition state"
)
assert(
    exactAcquisitionRecommendation.route.actions[3].acquisitionGoldCost == 0,
    "dynamic return segment does not repay recipe acquisition"
)

print("Dynamic recommendation integration tests passed.")
