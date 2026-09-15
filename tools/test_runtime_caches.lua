local addonTable = {}

local now = 100
local owned = {
    [1001] = 4,
    [6218] = 1,
}
local itemCountCalls = 0

function GetTime()
    return now
end

function GetItemCount(itemID)
    itemCountCalls = itemCountCalls + 1
    return owned[itemID] or 0
end

function UnitFactionGroup()
    return "Alliance"
end

function UnitLevel()
    return 80
end

function IsSpellKnown()
    return false
end

function GetFactionInfoByID()
    return "Fixture", nil, 5
end

function GetSpellInfo(spellID)
    return "Spell " .. tostring(spellID)
end

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

assert(loadfile("RuntimeState.lua"))("Profession_Capper", addonTable)
assert(loadfile("ProfessionBook.lua"))("Profession_Capper", addonTable)
assert(loadfile("PriceProvider.lua"))("Profession_Capper", addonTable)

local providerRevision = 1
local providerCalls = {}
local providerValue = 100
local revisionedProvider = {
    getRevision = function()
        return providerRevision
    end,
    getItemPrice = function(self, item)
        local itemID = tonumber(item) or tonumber(string.match(tostring(item), "(%d+)"))
        providerCalls[itemID] = (providerCalls[itemID] or 0) + 1
        if itemID == 9999 then
            return {
                item = item,
                itemID = itemID,
                available = false,
                unavailableReason = "missing",
                source = "fixture",
            }
        end
        return {
            item = item,
            itemID = itemID,
            minBuyout = providerValue + (itemID or 0),
            source = "fixture",
        }
    end,
}
assert(addonTable.registerPriceProvider("revisioned", revisionedProvider, 10))
assert(addonTable.selectPriceProvider("revisioned"))

local first = addonTable.lookupItemPrice(1001)
local second = addonTable.lookupItemPrice(1001)
assertEqual(first.minBuyout, 1101, "first revisioned price")
assertEqual(second.minBuyout, 1101, "same revision cached price")
assertEqual(providerCalls[1001], 1, "same provider revision reuses raw lookup")

providerRevision = 2
providerValue = 200
local revised = addonTable.lookupItemPrice(1001)
assertEqual(revised.minBuyout, 1201, "provider revision changes price")
assertEqual(providerCalls[1001], 2, "provider revision rekeys price")

local missingOne = addonTable.lookupItemPrice(9999)
local missingTwo = addonTable.lookupItemPrice(9999)
assertEqual(missingOne.available, false, "negative price cached")
assertEqual(missingTwo.available, false, "negative price cache reuse")
assertEqual(providerCalls[9999], 1, "negative price uses same revision cache")

local beforeBagPriceCalls = providerCalls[1001]
addonTable.noteRuntimeInventoryChanged()
local afterBagPrice = addonTable.lookupItemPrice(1001)
assertEqual(afterBagPrice.minBuyout, 1201, "bag revision preserves price data")
assertEqual(providerCalls[1001], beforeBagPriceCalls, "bag change does not destroy price cache")

local ttlCalls = 0
local ttlProvider = {
    getItemPrice = function(self, item)
        ttlCalls = ttlCalls + 1
        return {
            item = item,
            minBuyout = 50,
            source = "ttl",
        }
    end,
}
assert(addonTable.registerPriceProvider("ttl", ttlProvider, 5))
assert(addonTable.selectPriceProvider("ttl"))
addonTable.lookupItemPrice(2000)
addonTable.lookupItemPrice(2000)
assertEqual(ttlCalls, 1, "unknown revision uses short TTL cache")
now = now + 16
addonTable.lookupItemPrice(2000)
assertEqual(ttlCalls, 2, "unknown revision expires conservatively")
assert(addonTable.selectPriceProvider("revisioned"))

local callsBeforeInventory = itemCountCalls
assertEqual(addonTable.getRuntimeInventoryCount(1001), 4, "inventory first read")
assertEqual(addonTable.getRuntimeInventoryCount(1001), 4, "inventory generation cache")
assertEqual(itemCountCalls, callsBeforeInventory + 1, "inventory queried once per generation")

owned[1001] = 7
addonTable.noteRuntimeInventoryChanged()
assertEqual(addonTable.getRuntimeInventoryCount(1001), 7, "inventory refresh after BAG_UPDATE")
assertEqual(itemCountCalls, callsBeforeInventory + 2, "new inventory generation rereads count")

for itemID = 3000, 3600 do
    addonTable.lookupItemPrice(itemID)
end
local priceStats = addonTable.getPriceCacheStats()
assert(priceStats.entries <= priceStats.maxEntries, "provider price cache remains bounded")
assert(
    priceStats.queueEntries <= priceStats.maxQueueEntries,
    "provider price eviction queue remains bounded"
)

for itemID = 5000, 7200 do
    addonTable.getRuntimeInventoryCount(itemID)
end
local runtimeStats = addonTable.getRuntimeStateCacheStats()
assert(runtimeStats.inventoryEntries <= runtimeStats.maxInventoryEntries, "inventory cache remains bounded")

local records = {
    {
        spellID = 10,
        profession = "Enchanting",
        name = "Known",
        requiredSkill = 1,
        outputItemID = 50010,
        outputQuantity = 1,
        reagents = {
            { itemID = 1001, count = 1 },
        },
    },
    {
        spellID = 11,
        profession = "Enchanting",
        name = "Unknown canonical",
        requiredSkill = 1,
        outputItemID = 50011,
        outputQuantity = 1,
        reagents = {
            { itemID = 1001, count = 2 },
        },
    },
}

addonTable.getRecipeCatalogRecipes = function(profession)
    assertEqual(profession, "Enchanting", "catalog profession")
    return records
end

addonTable.getRecipeCatalogRecord = function(spellID)
    for i = 1, table.getn(records) do
        if records[i].spellID == tonumber(spellID) then
            return records[i]
        end
    end
end

addonTable.isRecipeEligibleForDynamicOptimization = function()
    return true
end

addonTable.calculateRecipeCost = function(recipe)
    return {
        available = true,
        useful = true,
        difficulty = "orange",
        skillUpChance = 1,
        expectedCraftsPerSkillUp = 1,
        currentPurchaseCostPerCraft = recipe.spellID == 10 and 100 or 50,
        expectedCurrentPurchaseCostPerSkillUp = recipe.spellID == 10 and 100 or 50,
        materialMarketValuePerCraft = recipe.spellID == 10 and 100 or 50,
        expectedMarketCostPerSkillUp = recipe.spellID == 10 and 100 or 50,
        goldNeededNowPerCraft = recipe.spellID == 10 and 100 or 50,
        expectedGoldNeededNowPerSkillUp = recipe.spellID == 10 and 100 or 50,
        quality = "complete",
        reagentCosts = {},
        oneTimeCosts = {},
        availableNow = true,
    }
end

local solverCalls = 0
local mutateDuringSolve = false
addonTable.solveCheapestProfessionRoute = function()
    solverCalls = solverCalls + 1
    if mutateDuringSolve then
        addonTable.noteRuntimeInventoryChanged()
    end
    return {
        complete = false,
        reason = "fixture_incomplete",
        segments = {},
        actions = {},
        exploredStates = 1,
    }
end

addonTable.buildProfessionShoppingPlan = function()
    error("shopping plan should not run for incomplete fixture route")
end

assert(loadfile("DynamicRecommendations.lua"))("Profession_Capper", addonTable)

local liveCache = {
    [10] = {
        name = "Known live",
        skillType = "optimal",
        reagents = {
            {
                name = "Dust",
                itemID = 1001,
                count = 1,
                owned = 7,
            },
        },
        outputItemLink = "item:50010",
        outputCount = 1,
    },
}

local context = {
    professionName = "Enchanting",
    baseSkill = 200,
    effectiveSkill = 200,
    activeSkillModifier = 0,
    currentCap = 225,
}

addonTable.storeProfessionBookSnapshot("Enchanting", liveCache, context)
local recommendation = addonTable.computeDynamicProfessionRecommendation(
    liveCache,
    context,
    { targetSkill = 201 }
)
assertEqual(recommendation.available, true, "initial recommendation")
assertEqual(solverCalls, 1, "initial route solve")

local warm = addonTable.computeDynamicProfessionRecommendation(
    liveCache,
    context,
    { targetSkill = 201 }
)
assert(warm == recommendation, "unchanged revisions reuse recommendation object")
assertEqual(solverCalls, 1, "warm recommendation cache hit")

addonTable.noteRuntimeInventoryChanged()
local bagChanged = addonTable.computeDynamicProfessionRecommendation(
    liveCache,
    context,
    { targetSkill = 201 }
)
assertEqual(bagChanged.available, true, "inventory generation produces recommendation")
assertEqual(solverCalls, 2, "inventory generation invalidates dependent recommendation")

addonTable.noteRuntimeEligibilityChanged()
addonTable.computeDynamicProfessionRecommendation(liveCache, context, { targetSkill = 201 })
assertEqual(solverCalls, 3, "eligibility generation invalidates recommendation")

local modifierContext = {
    professionName = "Enchanting",
    baseSkill = 200,
    effectiveSkill = 205,
    activeSkillModifier = 5,
    currentCap = 225,
}
addonTable.computeDynamicProfessionRecommendation(liveCache, modifierContext, { targetSkill = 201 })
assertEqual(solverCalls, 4, "modifier/skill generation invalidates recommendation")

addonTable.storeProfessionBookSnapshot("Enchanting", liveCache, modifierContext)
addonTable.computeDynamicProfessionRecommendation(liveCache, modifierContext, { targetSkill = 201 })
assertEqual(solverCalls, 5, "profession-book generation invalidates optimizer result")

local recipesOne = addonTable.buildFullProfessionOptimizationInput(liveCache, modifierContext)
local recipesTwo = addonTable.buildFullProfessionOptimizationInput(liveCache, modifierContext)
local unknownOne
local unknownTwo
for i = 1, table.getn(recipesOne) do
    if recipesOne[i].spellID == 11 then unknownOne = recipesOne[i] end
end
for i = 1, table.getn(recipesTwo) do
    if recipesTwo[i].spellID == 11 then unknownTwo = recipesTwo[i] end
end
assert(unknownOne ~= nil and unknownTwo ~= nil, "canonical unknown recipe present")
assert(unknownOne == unknownTwo, "canonical static recipe object is reused")
local canonicalQuantity = unknownOne.reagents[1].quantity
addonTable.computeDynamicProfessionRecommendation(liveCache, modifierContext, { targetSkill = 202 })
assertEqual(unknownOne.reagents[1].quantity, canonicalQuantity, "recommendation pass does not mutate canonical recipe")

for i = 1, 14 do
    addonTable.noteRuntimeInventoryChanged()
    addonTable.computeDynamicProfessionRecommendation(
        liveCache,
        modifierContext,
        { targetSkill = 201 + (i % 2) }
    )
end
local dynamicStats = addonTable.getDynamicRuntimeCacheStats()
assert(
    dynamicStats.recommendationEntries <= dynamicStats.maxRecommendationEntries,
    "recommendation result cache remains bounded"
)
assert(
    dynamicStats.recommendationQueueEntries <= dynamicStats.maxRecommendationQueueEntries,
    "recommendation eviction queue remains bounded"
)
assert(dynamicStats.canonicalRecipeEntries >= 2, "canonical recipe cache populated")

addonTable.noteRuntimeInventoryChanged()
mutateDuringSolve = true
local stale = addonTable.computeDynamicProfessionRecommendation(
    liveCache,
    modifierContext,
    { targetSkill = 201 }
)
mutateDuringSolve = false
assertEqual(stale.available, false, "changed inputs cannot publish stale recommendation")
assertEqual(stale.reason, "runtime_inputs_changed", "stale recommendation rejection reason")

print("Revisioned runtime cache tests passed")
