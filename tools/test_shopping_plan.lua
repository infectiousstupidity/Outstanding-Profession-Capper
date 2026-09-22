
local addonTable = {}
local prices = {}
addonTable.lookupItemPrice = function(item)
    return prices[item] or { available = false, unavailableReason = "missing" }
end
addonTable.chooseUsableUnitPrice = function(result, purpose)
    if not result.available then
        return nil, result.unavailableReason
    end
    local function choice(value, priceType)
        if not value then return nil end
        return {
            unitPrice = value,
            priceType = priceType,
            source = result.source or "fixture",
            freshness = result.freshness or "fresh",
            ageSeconds = result.ageSeconds,
            isStale = result.freshness == "stale",
            isTooOld = result.isTooOld or false,
        }
    end
    if purpose == "market" then return choice(result.marketValue, "market") end
    if purpose == "auction" then return choice(result.minBuyout, "auction") end
    if purpose == "vendor" then return choice(result.vendorBuyPrice, "vendor") end
    if purpose == "spend" then return choice(result.minBuyout or result.vendorBuyPrice, result.minBuyout and "auction" or "vendor") end
    return nil, "unknown"
end
addonTable.getActivePriceProviderName = function() return "fixture" end

assert(loadfile("RecipeCost.lua"))("Profession_Capper", addonTable)
assert(loadfile("ShoppingPlan.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function findMaterial(plan, itemID)
    for i = 1, table.getn(plan.materials) do
        if plan.materials[i].itemID == itemID then
            return plan.materials[i]
        end
    end
end

prices[1001] = {
    available = true, marketValue = 100, minBuyout = 90, vendorBuyPrice = 80,
    source = "fixture", freshness = "fresh", ageSeconds = 100,
}
prices[2001] = {
    available = true, marketValue = 50, minBuyout = 45,
    source = "fixture", freshness = "fresh", ageSeconds = 200,
}
prices[3001] = {
    available = true, marketValue = 10, minBuyout = 9,
    source = "fixture", freshness = "stale", ageSeconds = 50000,
}

local producer = {
    id = "producer",
    reagents = {
        { itemID = 1001, quantity = 2 },
        { itemID = 3001, quantity = 1, reusable = true, reusableKey = "tool" },
    },
    outputs = {
        { itemID = 2001, quantity = 1 },
    },
}
local consumer = {
    id = "consumer",
    reagents = {
        { itemID = 1001, quantity = 2 },
        { itemID = 2001, quantity = 1 },
        { itemID = 3001, quantity = 1, reusable = true, reusableKey = "tool" },
    },
}

local route = {
    complete = true,
    totalGrossLevelingCost = 900,
    totalResaleCredit = 200,
    totalEffectiveLevelingCost = 700,
    totalEstimatedResaleSurplus = 50,
    segments = {
        { recipeID = "producer", skillStart = 0, skillEnd = 1, expectedMaterialCost = 250 },
        { recipeID = "consumer", skillStart = 1, skillEnd = 2, expectedMaterialCost = 350 },
    },
    actions = {
        {
            type = "craft", recipe = producer, expectedCrafts = 1,
            marketCost = 260, goldCost = 200, acquisitionGoldCost = 20,
        },
        {
            type = "craft", recipe = consumer, expectedCrafts = 2,
            marketCost = 390, goldCost = 300, acquisitionGoldCost = 0,
        },
        {
            type = "training", marketCost = 30, goldCost = 30,
        },
    },
}

local plan = addonTable.buildProfessionShoppingPlan(route, {
    inventory = { [1001] = 2 },
}, {})
assertEqual(plan.complete, true, "plan complete")
assertEqual(plan.estimatedMarketValueCost, 680, "route market total from actions")
local segmentTotal = 0
for i = 1, table.getn(plan.segments) do
    segmentTotal = segmentTotal + plan.segments[i].marketCost
end
assertEqual(segmentTotal, plan.estimatedMarketValueCost, "total equals cost segments")
assertEqual(plan.acquisitionCost, 50, "recipe plus training acquisition")
assertEqual(plan.totalExpectedCrafts, 3, "total expected crafts")
assertEqual(plan.totalGrossLevelingCost, 900, "route gross leveling total carried into plan")
assertEqual(plan.totalResaleCredit, 200, "route resale credit carried into plan")
assertEqual(plan.totalEffectiveLevelingCost, 700, "route effective total carried into plan")
assertEqual(plan.totalEstimatedResaleSurplus, 50, "route surplus carried into plan")

local base = findMaterial(plan, 1001)
assertEqual(base.totalExpectedQuantity, 6, "aggregate repeated reagent quantity")
assertEqual(base.quantityCurrentlyOwned, 2, "owned quantity exposed")
assertEqual(base.quantityStillNeeded, 4, "owned quantity subtracted once globally")
assertEqual(base.chosenPriceType, "vendor", "vendor beats auction")
assertEqual(base.estimatedPurchaseCost, 320, "purchase cost")

local intermediate = findMaterial(plan, 2001)
assertEqual(intermediate.totalExpectedQuantity, 2, "intermediate gross requirement")
assertEqual(intermediate.routeProducedQuantity, 1, "route output offsets requirement")
assertEqual(intermediate.quantityStillNeeded, 1, "only net intermediate purchased")

local tool = findMaterial(plan, 3001)
assertEqual(tool.totalExpectedQuantity, 1, "reusable counted once across route")
assertEqual(tool.quantityStillNeeded, 1, "reusable still needed once")
assertEqual(plan.stalePriceCount, 1, "stale price surfaced")
assertEqual(plan.oldestPriceAgeSeconds, 50000, "oldest scan age surfaced")
assertEqual(plan.estimatedGoldNeededNow, 320 + 45 + 9 + 50, "global shopping cash plus acquisition")
assertEqual(plan.priceDepthKnown, false, "AH depth explicitly unknown")
assertEqual(plan.auctionCostIsEstimate, true, "AH total explicitly estimate")

local missingRoute = {
    complete = true,
    actions = {
        {
            type = "craft",
            recipe = { reagents = { { itemID = 9999, quantity = 1 } } },
            expectedCrafts = 1,
            marketCost = 1,
            goldCost = 1,
            acquisitionGoldCost = 0,
        },
    },
    segments = {},
}
local missing = addonTable.buildProfessionShoppingPlan(missingRoute, {}, {})
assertEqual(missing.complete, false, "missing price makes plan incomplete")
assertEqual(missing.missingPriceCount, 1, "missing price count")
assertEqual(missing.missingPriceQuantity, 1, "missing price quantity")
assertEqual(missing.estimatedGoldNeededNow, nil, "missing price does not become zero")

prices[16202] = {
    available = true, marketValue = 400, minBuyout = 400,
    source = "fixture", freshness = "fresh", ageSeconds = 100,
}
prices[16203] = {
    available = true, marketValue = 900, minBuyout = 900,
    source = "fixture", freshness = "fresh", ageSeconds = 100,
}

local essenceRoute = {
    complete = true,
    actions = {
        {
            type = "craft",
            recipe = {
                reagents = {
                    { itemID = 16202, quantity = 3 },
                },
            },
            expectedCrafts = 1,
            marketCost = 900,
            goldCost = 900,
            acquisitionGoldCost = 0,
        },
    },
    segments = {},
}
local essencePlan = addonTable.buildProfessionShoppingPlan(essenceRoute, {}, {})
local essenceMaterial = findMaterial(essencePlan, 16202)
assertEqual(essencePlan.complete, true, "essence shopping plan complete")
assertEqual(essenceMaterial.sourceItemID, 16203, "shopping list recommends greater eternal essence")
assertEqual(essenceMaterial.sourceQuantity, 1, "shopping list gives exact greater quantity")
assertEqual(essenceMaterial.estimatedPurchaseCost, 900, "shopping list uses whole greater price")
assertEqual(essenceMaterial.directTotalCost, 1200, "shopping list exposes direct lesser total")
assertEqual(essenceMaterial.savings, 300, "shopping list exposes conversion savings")
assertEqual(essenceMaterial.converted, true, "shopping list marks conversion")

local acquisitionRoute = {
    complete = true,
    actions = {
        {
            type = "craft",
            recipe = { id = "unknown", reagents = {} },
            recipeID = "unknown",
            skillFrom = 200,
            skillTo = 201,
            expectedCrafts = 1,
            marketCost = 50,
            goldCost = 50,
            acquisitionGoldCost = 50,
            cost = {
                acquisition = {
                    alreadyAcquired = false,
                    source = "trainer",
                    goldCost = 50,
                    model = {
                        sourceType = "trainer",
                        sourceName = "Fixture trainer",
                    },
                },
            },
        },
    },
    segments = {},
}
local acquisitionPlan = addonTable.buildProfessionShoppingPlan(acquisitionRoute, {}, {})
assertEqual(acquisitionPlan.complete, true, "acquisition route plan complete")
assertEqual(acquisitionPlan.segments[1].requiresAcquisition, true, "segment exposes acquisition boundary")
assertEqual(acquisitionPlan.segments[1].acquisition.source, "trainer", "segment retains acquisition source")
assertEqual(acquisitionPlan.segments[1].acquisitionCost, 50, "segment retains one-time acquisition cost")

print("Total cost and shopping plan tests passed.")
