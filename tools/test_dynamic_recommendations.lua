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
    return spellID == 10
end

local providerName = "fixture"
addonTable.getActivePriceProviderName = function()
    return providerName
end

local solverCalls = 0
addonTable.solveCheapestProfessionRoute = function(recipes, context, state, options)
    solverCalls = solverCalls + 1
    assert(table.getn(recipes) == 1, "only eligible learned recipes should be optimized")
    assert(options.targetSkill == 225, "optimizer should target the current trained rank cap")
    assert(state.learnedRecipes[10] == true, "learned recipe state should be populated")
    assert(state.inventory[1001] == 4, "live inventory should be populated")
    assert(state.acquiredOneTime["item:6218"] == true, "owned enchanting rod should be reusable")
    return {
        complete = true,
        segments = {
            {
                recipeID = 10,
                recipe = recipes[1],
                skillStart = 200,
                skillEnd = 210,
                expectedCrafts = 12.5,
                expectedMaterialCost = 5000,
            },
        },
        actions = {},
    }
end

addonTable.buildProfessionShoppingPlan = function(route)
    return {
        complete = true,
        estimatedMarketValueCost = 5000,
        estimatedGoldNeededNow = 3000,
        totalExpectedCrafts = 12.5,
        stalePriceCount = 0,
        missingPriceCount = 0,
        priceSources = { "fixture" },
        quality = "complete",
    }
end

assert(loadfile("DynamicRecommendations.lua"))("Profession_Capper", addonTable)

local cache = {
    [10] = {
        name = "Useful recipe",
        reagents = {
            {
                name = "Dust",
                itemLink = "|cffffffff|Hitem:1001:0:0:0:0:0:0:0|h[Dust]|h|r",
                count = 2,
                owned = 4,
            },
            {
                name = "Runed Copper Rod",
                itemLink = "|cffffffff|Hitem:6218:0:0:0:0:0:0:0|h[Runed Copper Rod]|h|r",
                count = 1,
                owned = 1,
            },
        },
    },
    [20] = {
        name = "Unknown difficulty",
        reagents = {},
    },
}

local recommendation = addonTable.computeDynamicProfessionRecommendation(cache, {
    professionName = "Enchanting",
    baseSkill = 200,
    effectiveSkill = 210,
    activeSkillModifier = 10,
    currentCap = 225,
})

assert(recommendation.available == true, "complete live route should be available")
assert(recommendation.fallbackToStaticGuide == false, "complete route should not fall back")
assert(recommendation.currentSegment.recipeID == 10, "first route segment should be exposed")
assert(solverCalls == 1, "solver should run once")

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
assert(addonTable.formatCopperShort(123456) == "12g 34s", "compact money formatting")
assert(addonTable.formatPriceAge(7200) == "2h old", "scan age formatting")

print("Dynamic recommendation integration tests passed.")
