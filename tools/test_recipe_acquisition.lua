local addonTable = {}

addonTable.getEffectiveSkillForBase = function(baseSkill, context)
    return (tonumber(baseSkill) or 0) + ((context and tonumber(context.activeSkillModifier)) or 0)
end

local auctionPrices = {}
addonTable.lookupItemPrice = function(itemID)
    return auctionPrices[itemID] or { available = false, unavailableReason = "missing" }
end
addonTable.chooseUsableUnitPrice = function(result, purpose)
    if not result.available then return nil, result.unavailableReason end
    if purpose == "auction" and result.minBuyout then
        return { unitPrice = result.minBuyout, source = "fixture", freshness = "fresh" }
    end
    return nil, "missing"
end

assert(loadfile("RecipeAcquisition.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeAcquisitionData.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local trainer = addonTable.resolveRecipeAcquisition(
    7420,
    {},
    { baseSkill = 15, activeSkillModifier = 0 },
    {}
)
assertEqual(trainer.available, true, "trainer available")
assertEqual(trainer.state, "trainable_now", "trainer state")
assertEqual(trainer.goldCost, 50, "trainer price")
assertEqual(trainer.sourceName, "Enchanting trainer", "trainer source")
assertEqual(trainer.sourceID, 201009, "trainer source ID")

local lockedTrainer = addonTable.resolveRecipeAcquisition(
    7426,
    {},
    { baseSkill = 30, activeSkillModifier = 0 },
    {}
)
assertEqual(lockedTrainer.available, false, "trainer skill gate")
assertEqual(lockedTrainer.reason, "required_skill_not_met", "trainer gate reason")

local modifierUnlock = addonTable.resolveRecipeAcquisition(
    7426,
    {},
    { baseSkill = 30, activeSkillModifier = 10 },
    {}
)
assertEqual(modifierUnlock.available, true, "modifier unlocks trainer recipe")

local learned = addonTable.resolveRecipeAcquisition(
    9999,
    { learnedRecipes = { [9999] = true } },
    { baseSkill = 1, activeSkillModifier = 0 },
    {}
)
assertEqual(learned.available, true, "learned override")
assertEqual(learned.alreadyAcquired, true, "learned acquired")
assertEqual(learned.goldCost, 0, "learned zero incremental cost")

addonTable.registerRecipeAcquisition({
    spellID = 10001,
    profession = "Test",
    sourceType = "vendor",
    sourceName = "Vendor Example",
    vendorID = 77,
    zone = "Test Zone",
    coordinates = { x = 40.5, y = 55.2 },
    faction = "neutral",
    purchasePrice = 1234,
    recipeItemID = 50001,
})
local vendor = addonTable.resolveRecipeAcquisition(10001, {}, { baseSkill = 1 }, {})
assertEqual(vendor.available, true, "vendor available")
assertEqual(vendor.state, "purchasable_now", "vendor state")
assertEqual(vendor.zone, "Test Zone", "vendor zone")
assertEqual(vendor.goldCost, 1234, "vendor cost")

addonTable.registerRecipeAcquisition({
    spellID = 10002,
    profession = "Test",
    sourceType = "limited_vendor",
    sourceName = "Limited Vendor",
    limitedStock = true,
    purchasePrice = 100,
})
local limited = addonTable.resolveRecipeAcquisition(10002, {}, { baseSkill = 1 }, {})
assertEqual(limited.available, false, "limited stock not guaranteed")
assertEqual(limited.reason, "limited_stock_not_guaranteed", "limited reason")
assertEqual(limited.goldCost, 100, "limited known price retained")

addonTable.registerRecipeAcquisition({
    spellID = 10003,
    profession = "Test",
    sourceType = "reputation",
    sourceName = "Faction Quartermaster",
    reputation = { faction = "Test Faction", standing = "Revered" },
})
local reputation = addonTable.resolveRecipeAcquisition(10003, {}, { baseSkill = 1 }, {})
assertEqual(reputation.available, false, "reputation not instant")
assertEqual(reputation.goldCost, nil, "reputation not fake free")
assertEqual(reputation.reason, "reputation_requirement", "reputation reason")

addonTable.registerRecipeAcquisition({
    spellID = 10004,
    profession = "Test",
    sourceType = "drop",
    sourceName = "World drop",
})
local drop = addonTable.resolveRecipeAcquisition(10004, {}, { baseSkill = 1 }, {})
assertEqual(drop.available, false, "drop not instant")
assertEqual(drop.goldCost, nil, "drop not fake free")
assertEqual(drop.reason, "drop_not_guaranteed", "drop reason")

auctionPrices[50005] = { available = true, minBuyout = 2500 }
addonTable.registerRecipeAcquisition({
    spellID = 10005,
    profession = "Test",
    sourceType = "auction",
    sourceName = "Auction House",
    recipeItemID = 50005,
})
local auction = addonTable.resolveRecipeAcquisition(10005, {}, { baseSkill = 1 }, {})
assertEqual(auction.available, true, "AH recipe available")
assertEqual(auction.goldCost, 2500, "AH recipe current cost")

local unknown = addonTable.resolveRecipeAcquisition(999999, {}, { baseSkill = 1 }, {})
assertEqual(unknown.available, false, "unknown unavailable")
assertEqual(unknown.reason, "missing_acquisition_metadata", "unknown reason")
assertEqual(unknown.goldCost, nil, "unknown not fake free")

local explanation = addonTable.explainRecipeAcquisition(7420, {}, { baseSkill = 15 }, {})
assertEqual(explanation.state, "trainable_now", "static guide explanation state")
assertEqual(explanation.sourceName, "Enchanting trainer", "static guide explanation source")

local valid, reason = addonTable.validateRecipeAcquisitionEntry({
    spellID = 20001,
    profession = "Test",
    sourceType = "vendor",
    sourceName = "",
})
assertEqual(valid, false, "malformed vendor rejected")
assertEqual(reason, "missing_source_name", "malformed vendor reason")

valid, reason = addonTable.validateRecipeAcquisitionEntry({
    spellID = 20002,
    profession = "Test",
    sourceType = "auction",
})
assertEqual(valid, false, "AH without item rejected")
assertEqual(reason, "auction_requires_recipe_item", "AH item reason")

valid, reason = addonTable.validateRecipeAcquisitionEntry({
    spellID = 20003,
    profession = "Test",
    sourceType = "limited_vendor",
    sourceName = "Vendor",
})
assertEqual(valid, false, "limited vendor flag required")
assertEqual(reason, "limited_vendor_requires_stock_flag", "limited flag reason")

print("Recipe acquisition model tests passed.")
