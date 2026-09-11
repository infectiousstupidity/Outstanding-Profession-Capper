local addonTable = {}

addonTable.getEffectiveSkillForBase = function(baseSkill, context)
    return (tonumber(baseSkill) or 0) + ((context and context.activeSkillModifier) or 0)
end

local prices = {}
addonTable.lookupItemPrice = function(item)
    local price = prices[item]
    if not price then
        return { available = false, unavailableReason = "missing" }
    end
    return price
end

addonTable.chooseUsableUnitPrice = function(result, purpose)
    if not result.available then
        return nil, result.unavailableReason
    end

    local function choice(value, priceType)
        if not value then
            return nil
        end
        return {
            unitPrice = value,
            priceType = priceType,
            source = result.source or "fixture",
            freshness = result.freshness or "fresh",
            isStale = result.freshness == "stale",
            isTooOld = false,
        }
    end

    if purpose == "market" then
        return choice(result.marketValue, "market")
    elseif purpose == "auction" then
        return choice(result.minBuyout, "auction")
    elseif purpose == "vendor" then
        return choice(result.vendorBuyPrice, "vendor")
    elseif purpose == "spend" then
        return choice(result.minBuyout or result.vendorBuyPrice, result.minBuyout and "auction" or "vendor")
    end

    return nil, "unknown"
end

assert(loadfile("RecipeCost.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function assertNear(actual, expected, tolerance, label)
    if not actual or math.abs(actual - expected) > tolerance then
        error(string.format("%s: expected %s +/- %s, got %s", label, expected, tolerance, tostring(actual)))
    end
end

prices[1001] = {
    available = true,
    marketValue = 100,
    minBuyout = 90,
    vendorBuyPrice = 80,
    freshness = "fresh",
}
prices[1002] = {
    available = true,
    marketValue = 50,
    minBuyout = 60,
    freshness = "fresh",
}

local recipe = {
    spellID = 1,
    acquisition = { status = "learned" },
    difficulty = { yellow = 100, green = 110, gray = 120 },
    reagents = {
        { itemID = 1001, quantity = 2 },
    },
}

local orange = addonTable.calculateRecipeCost(recipe, 90, nil, {}, {})
assertEqual(orange.available, true, "orange available")
assertEqual(orange.difficulty, "orange", "orange difficulty")
assertEqual(orange.skillUpChance, 1, "orange chance")
assertEqual(orange.expectedCraftsPerSkillUp, 1, "orange crafts")
assertEqual(orange.materialMarketValuePerCraft, 200, "orange market per craft")
assertEqual(orange.goldNeededNowPerCraft, 160, "vendor beats AH")
assertEqual(orange.expectedGoldNeededNowPerSkillUp, 160, "orange gold per point")
assertEqual(orange.reagentCosts[1].purchasePriceType, "vendor", "vendor source explicit")

local yellow = addonTable.calculateRecipeCost(recipe, 105, nil, {}, {})
assertEqual(yellow.difficulty, "yellow", "yellow difficulty")
assertNear(yellow.skillUpChance, 0.75, 0.0001, "yellow chance")
assertNear(yellow.expectedCraftsPerSkillUp, 4 / 3, 0.0001, "yellow expected crafts")
assertNear(yellow.expectedMarketCostPerSkillUp, 200 * 4 / 3, 0.0001, "yellow market cost")

local green = addonTable.calculateRecipeCost(recipe, 115, nil, {}, {})
assertEqual(green.difficulty, "green", "green difficulty")
assertNear(green.skillUpChance, 0.25, 0.0001, "green chance")
assertNear(green.expectedCraftsPerSkillUp, 4, 0.0001, "green expected crafts")

local gray = addonTable.calculateRecipeCost(recipe, 120, nil, {}, {})
assertEqual(gray.available, false, "gray unavailable")
assertEqual(gray.unavailableReason, "gray_recipe", "gray reason")

local racial = addonTable.calculateRecipeCost(recipe, 95, { activeSkillModifier = 10 }, {}, {})
assertEqual(racial.effectiveSkill, 105, "modifier effective skill")
assertEqual(racial.difficulty, "orange", "modifier preserves base-skill color")
assertNear(racial.skillUpChance, 1, 0.0001, "modifier preserves base-skill chance")

local owned = addonTable.calculateRecipeCost(recipe, 90, nil, {
    inventory = { [1001] = 1 },
}, {})
assertEqual(owned.materialMarketValuePerCraft, 200, "owned material keeps market value")
assertEqual(owned.goldNeededNowPerCraft, 80, "owned material reduces cash")

local reusableRecipe = {
    spellID = 2,
    acquisition = { status = "learned" },
    difficulty = { yellow = 100, green = 110, gray = 120 },
    reagents = {
        { itemID = 1002, quantity = 1, reusable = true, reusableKey = "tool" },
    },
}
local reusable = addonTable.calculateRecipeCost(reusableRecipe, 115, nil, {}, {})
assertNear(reusable.expectedCraftsPerSkillUp, 4, 0.0001, "reusable green crafts")
assertEqual(reusable.expectedMarketCostPerSkillUp, 50, "reusable charged once")
assertEqual(reusable.expectedGoldNeededNowPerSkillUp, 60, "reusable cash charged once")
assertEqual(reusable.oneTimeCosts[1].kind, "reusable_reagent", "reusable exposed as one-time")

local alreadyReusable = addonTable.calculateRecipeCost(reusableRecipe, 115, nil, {
    acquiredOneTime = { tool = true },
}, {})
assertEqual(alreadyReusable.expectedMarketCostPerSkillUp, 0, "owned reusable not charged")

local missingRecipe = {
    spellID = 3,
    acquisition = { status = "learned" },
    difficulty = { yellow = 100, green = 110, gray = 120 },
    reagents = {
        { itemID = 9999, quantity = 1 },
    },
}
local missing = addonTable.calculateRecipeCost(missingRecipe, 90, nil, {}, {})
assertEqual(missing.available, false, "missing price unavailable")
assertEqual(missing.incomplete, true, "missing price incomplete")
assertEqual(missing.expectedMarketCostPerSkillUp, nil, "missing price not zero")

local unavailableRecipe = {
    spellID = 4,
    acquisition = { status = "drop" },
    difficulty = { yellow = 100, green = 110, gray = 120 },
    reagents = {
        { itemID = 1001, quantity = 1 },
    },
}
local unavailable = addonTable.calculateRecipeCost(unavailableRecipe, 90, nil, {}, {})
assertEqual(unavailable.available, false, "drop not instant")
assertEqual(unavailable.unavailableReason, "recipe_not_immediately_acquirable", "drop acquisition reason")

local trainableRecipe = {
    spellID = 5,
    acquisition = { status = "trainable", goldCost = 250 },
    difficulty = { yellow = 100, green = 110, gray = 120 },
    reagents = {
        { itemID = 1001, quantity = 1 },
    },
}
local trainable = addonTable.calculateRecipeCost(trainableRecipe, 90, nil, {}, {})
assertEqual(trainable.acquisitionCost, 250, "acquisition gold cost")
assertEqual(trainable.oneTimeCosts[1].kind, "recipe_acquisition", "acquisition exposed as one-time")

prices[16202] = {
    available = true,
    marketValue = 300,
    minBuyout = 300,
    freshness = "fresh",
}
prices[16203] = {
    available = true,
    marketValue = 600,
    minBuyout = 600,
    freshness = "fresh",
}

local essenceRecipe = {
    spellID = 6,
    acquisition = { status = "learned" },
    difficulty = { yellow = 100, green = 110, gray = 120 },
    reagents = {
        { itemID = 16202, quantity = 3 },
    },
}
local essence = addonTable.calculateRecipeCost(essenceRecipe, 90, nil, {}, {})
assertEqual(essence.available, true, "essence recipe available")
assertEqual(essence.currentPurchaseCostPerCraft, 600, "greater essence conversion lowers application cost")
assertEqual(essence.expectedCurrentPurchaseCostPerSkillUp, 600, "converted price feeds skill-up cost")
assertEqual(essence.reagentCosts[1].sourceItemID, 16203, "greater eternal essence selected as source")
assertEqual(essence.reagentCosts[1].converted, true, "essence conversion is explicit")
assertEqual(essence.reagentCosts[1].conversionDirection, "greater_to_lesser", "conversion direction recorded")

print("Recipe cost engine tests passed.")
