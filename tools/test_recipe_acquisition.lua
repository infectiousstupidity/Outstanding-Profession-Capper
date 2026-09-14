local addonTable = {}

addonTable.getEffectiveSkillForBase = function(baseSkill, context)
    return (tonumber(baseSkill) or 0) + ((context and tonumber(context.activeSkillModifier)) or 0)
end

local auctionPrices = {}
addonTable.lookupItemPrice = function(itemID)
    return auctionPrices[itemID] or { available = false, unavailableReason = "not_listed" }
end
addonTable.chooseUsableUnitPrice = function(result, purpose)
    if not result.available then return nil, result.unavailableReason end
    if purpose == "auction" and result.minBuyout then
        return { unitPrice = result.minBuyout, source = "fixture", freshness = "fresh" }
    end
    return nil, "missing"
end

assert(loadfile("RecipeDifficulty.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeDifficultyData.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeCatalog.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeCatalogData.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeAcquisition.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeAcquisitionData.lua"))("Profession_Capper", addonTable)
assert(loadfile("RouteSolver.lua"))("Profession_Capper", addonTable)

local function eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local coverage = addonTable.getRecipeCatalogCoverage()
local covered = 0
local counts = {}
local multiple = 0
for _, rows in pairs(addonTable.recipeCatalogByProfession) do
    for index = 1, table.getn(rows) do
        local recipe = rows[index]
        local sources = addonTable.getRecipeAcquisitionRecords(recipe.spellID)
        assert(table.getn(sources) > 0, "missing acquisition " .. tostring(recipe.spellID))
        covered = covered + 1
        if table.getn(sources) > 1 then multiple = multiple + 1 end
        for sourceIndex = 1, table.getn(sources) do
            local source = sources[sourceIndex]
            counts[source.sourceType] = (counts[source.sourceType] or 0) + 1
        end
    end
end
eq(covered, coverage.total, "catalog acquisition coverage")
eq(covered, 3552, "catalog size")
assert((counts.trainer or 0) > 1000, "trainer coverage")
assert((counts.vendor or 0) > 100, "vendor coverage")
assert((counts.limited_vendor or 0) > 0, "limited vendor coverage")
assert((counts.reputation or 0) > 0, "reputation coverage")
assert((counts.manual or 0) > 0, "manual fallback coverage")
assert(multiple > 500, "multi-source coverage")

local learned = addonTable.resolveRecipeAcquisition(910001, {
    learnedRecipes = { [910001] = true },
}, { baseSkill = 1 }, {})
eq(learned.sourceType, "learned", "learned wins")
eq(learned.goldCost, 0, "learned zero cost")
eq(learned.requiresLearning, false, "learned needs no learning")

addonTable.registerRecipeAcquisition({
    spellID = 910002,
    profession = "Test",
    sourceType = "manual",
    sourceName = "World source",
    recipeItemID = 61002,
    requiredSkill = 1,
})
local owned = addonTable.resolveRecipeAcquisition(910002, {
    inventory = { [61002] = 1 },
    playerLevel = 80,
}, { baseSkill = 1 }, {})
eq(owned.sourceType, "owned_recipe_item", "owned recipe item")
eq(owned.goldCost, 0, "owned item zero purchase cost")
eq(owned.requiresLearning, true, "owned item still needs learning")

addonTable.registerRecipeAcquisition({
    spellID = 910003,
    profession = "Test",
    sourceType = "trainer",
    sourceName = "Trainer",
    purchasePrice = 500,
    requiredSkill = 1,
    recipeItemID = 61003,
})
addonTable.registerRecipeAcquisition({
    spellID = 910003,
    profession = "Test",
    sourceType = "drop",
    sourceName = "Drop",
    recipeItemID = 61003,
    requiredSkill = 1,
})
auctionPrices[61003] = { available = true, minBuyout = 300 }
local trainerVsAH = addonTable.resolveRecipeAcquisition(910003, {
    playerLevel = 80,
}, { baseSkill = 1 }, {})
eq(trainerVsAH.sourceType, "auction", "AH beats trainer")
eq(trainerVsAH.goldCost, 300, "AH price selected")
assert(table.getn(trainerVsAH.alternatives) >= 3, "all acquisition paths retained")

addonTable.registerRecipeAcquisition({
    spellID = 910004,
    profession = "Test",
    sourceType = "vendor",
    sourceName = "Vendor",
    purchasePrice = 200,
    recipeItemID = 61004,
    requiredSkill = 1,
})
auctionPrices[61004] = { available = true, minBuyout = 400 }
local vendorVsAH = addonTable.resolveRecipeAcquisition(910004, {
    playerLevel = 80,
}, { baseSkill = 1 }, {})
eq(vendorVsAH.sourceType, "vendor", "vendor beats AH")
eq(vendorVsAH.goldCost, 200, "vendor price selected")

addonTable.registerRecipeAcquisition({
    spellID = 910005,
    profession = "Test",
    sourceType = "limited_vendor",
    sourceName = "Limited Vendor",
    limitedStock = true,
    purchasePrice = 100,
    requiredSkill = 1,
})
local limited = addonTable.resolveRecipeAcquisition(910005, {
    playerLevel = 80,
}, { baseSkill = 1 }, {})
eq(limited.available, false, "limited stock excluded from guaranteed route")
eq(limited.reason, "limited_stock_not_guaranteed", "limited stock reason")

addonTable.registerRecipeAcquisition({
    spellID = 910006,
    profession = "Test",
    sourceType = "drop",
    sourceName = "World drop",
    recipeItemID = 61006,
    requiredSkill = 1,
})
auctionPrices[61006] = { available = true, minBuyout = 250 }
local dropOnAH = addonTable.resolveRecipeAcquisition(910006, {
    playerLevel = 80,
}, { baseSkill = 1 }, {})
eq(dropOnAH.sourceType, "auction", "drop becomes reliable through AH")
eq(dropOnAH.goldCost, 250, "drop AH cost")

addonTable.registerRecipeAcquisition({
    spellID = 910007,
    profession = "Test",
    sourceType = "reputation",
    sourceName = "Quartermaster",
    purchasePrice = 700,
    requiredSkill = 1,
    reputation = { faction = "Test Faction", factionID = 999, standing = "Revered", standingID = 6 },
})
local repLocked = addonTable.resolveRecipeAcquisition(910007, {
    playerLevel = 80,
    reputation = { [999] = "Honored" },
}, { baseSkill = 1 }, {})
eq(repLocked.available, false, "reputation gate")
eq(repLocked.reason, "reputation_requirement_not_met", "reputation reason")
local repReady = addonTable.resolveRecipeAcquisition(910007, {
    playerLevel = 80,
    reputation = { [999] = "Exalted" },
}, { baseSkill = 1 }, {})
eq(repReady.available, true, "reputation satisfied")
eq(repReady.sourceType, "reputation", "reputation vendor selected")

addonTable.registerRecipeAcquisition({
    spellID = 910008,
    profession = "Test",
    sourceType = "vendor",
    sourceName = "Faction Vendor",
    purchasePrice = 100,
    faction = "horde",
    requiredSkill = 1,
})
local factionLocked = addonTable.resolveRecipeAcquisition(910008, {
    playerLevel = 80,
    faction = "alliance",
}, { baseSkill = 1 }, {})
eq(factionLocked.available, false, "faction enforced")
eq(factionLocked.reason, "faction_restricted", "faction reason")

addonTable.registerRecipeAcquisition({
    spellID = 910009,
    profession = "Test",
    sourceType = "trainer",
    sourceName = "Trainer",
    purchasePrice = 100,
    requiredSkill = 300,
})
local futureLocked = addonTable.resolveRecipeAcquisition(910009, {
    playerLevel = 80,
}, { baseSkill = 290, activeSkillModifier = 0 }, {})
eq(futureLocked.available, false, "future trainer locked")
local modifierReady = addonTable.resolveRecipeAcquisition(910009, {
    playerLevel = 80,
}, { baseSkill = 290, activeSkillModifier = 10 }, {})
eq(modifierReady.available, true, "profession modifier unlocks trainer")
local futureReady = addonTable.resolveRecipeAcquisition(910009, {
    playerLevel = 80,
}, { baseSkill = 300, activeSkillModifier = 0 }, {})
eq(futureReady.available, true, "simulated future skill unlocks trainer")

local routeSkillOverride = addonTable.resolveRecipeAcquisition(910009, {
    playerLevel = 80,
}, { baseSkill = 290, activeSkillModifier = 0 }, { baseSkill = 300 })
eq(routeSkillOverride.available, true, "route-simulated base skill overrides current character base skill")

addonTable.registerRecipeAcquisition({
    spellID = 910010,
    profession = "Test",
    sourceType = "vendor",
    sourceName = "Zero-price ambiguous vendor",
    purchasePrice = 0,
    requiredSkill = 1,
})
local zeroPrice = addonTable.resolveRecipeAcquisition(910010, {
    playerLevel = 80,
}, { baseSkill = 1 }, {})
eq(zeroPrice.available, false, "ambiguous zero price rejected")
eq(zeroPrice.reason, "missing_acquisition_cost", "zero price not fake free")

addonTable.registerRecipeAcquisition({
    spellID = 910011,
    profession = "Test",
    sourceType = "trainer",
    sourceName = "Trainer",
    purchasePrice = 500,
    requiredSkill = 1,
})
local function acquisitionFixture(recipe, skill, context, state)
    local resolved = addonTable.resolveRecipeAcquisition(910011, state, {
        baseSkill = skill,
        activeSkillModifier = 0,
    }, {})
    if not resolved.available then
        return { available = false, useful = false, incomplete = false, unavailableReason = resolved.reason }
    end
    local oneTime = {}
    if not resolved.alreadyAcquired then
        oneTime = {{
            key = resolved.key,
            kind = "recipe_acquisition",
            marketCost = resolved.marketCost,
            goldCost = resolved.goldCost,
        }}
    end
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 100,
        expectedGoldNeededNowPerSkillUp = 100,
        expectedCurrentPurchaseCostPerSkillUp = 100,
        oneTimeCosts = oneTime,
        quality = "complete",
        skillUpChance = 1,
    }
end
local route = addonTable.solveCheapestProfessionRoute({{ spellID = 910011 }}, nil, {
    currentCap = 3,
    playerLevel = 80,
}, {
    startSkill = 1,
    targetSkill = 3,
    costRecipe = acquisitionFixture,
})
eq(route.complete, true, "one-time route complete")
eq(route.totalMarketCost, 700, "acquisition charged once")
eq(route.totalGoldCost, 700, "gold acquisition charged once")

local simulatedLearned = addonTable.resolveRecipeAcquisition(910011, {
    acquiredOneTime = { ["recipe:910011"] = true },
    playerLevel = 80,
}, { baseSkill = 2 }, {})
eq(simulatedLearned.sourceType, "simulated_learned", "route remembers acquired recipe")
eq(simulatedLearned.goldCost, 0, "simulated learned zero repeat cost")

local activeSegmentLearned = addonTable.resolveRecipeAcquisition(910011, {
    routeActiveRecipeID = 910011,
    playerLevel = 80,
}, { baseSkill = 2 }, {})
eq(activeSegmentLearned.sourceType, "simulated_learned", "continuous route segment remains acquired")
eq(activeSegmentLearned.goldCost, 0, "continuous segment does not repay recipe acquisition")

local valid, reason = addonTable.validateRecipeAcquisitionEntry({
    spellID = 920001,
    profession = "Test",
    sourceType = "limited_vendor",
    sourceName = "Vendor",
})
eq(valid, false, "limited vendor flag required")
eq(reason, "limited_vendor_requires_stock_flag", "limited flag validation")

print("Recipe acquisition multi-source and eligibility tests passed.")
