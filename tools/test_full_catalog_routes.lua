local addonTable = {}

local owned = {
    [1001] = 4,
    [61013] = 0,
}

function GetItemCount(itemID)
    return owned[itemID] or 0
end

function UnitFactionGroup()
    return "Alliance"
end

function UnitLevel()
    return 80
end

function IsSpellKnown(spellID)
    return spellID == 7413
end

function GetFactionInfoByID()
    return "Fixture", nil, 7
end

function GetSpellInfo(spellID)
    return "SpellName " .. tostring(spellID)
end

addonTable.getActivePriceProviderName = function()
    return "fixture"
end

addonTable.isRecipeEligibleForDynamicOptimization = function()
    return true
end

addonTable.getRecipeCatalogRecipes = function(profession)
    assert(profession == "Enchanting", "profession catalog selection")
    return {
        {
            spellID = 10,
            profession = "Enchanting",
            name = "Known",
            requiredSkill = 1,
            reagents = {{ itemID = 1001, count = 1 }},
        },
        {
            spellID = 13,
            profession = "Enchanting",
            name = "Future trainer",
            requiredSkill = 202,
            recipeItemID = 61013,
            reagents = {{ itemID = 1001, count = 1 }},
        },
        {
            spellID = 14,
            profession = "Enchanting",
            name = "Conditional",
            requiredSkill = 1,
            reagents = {{ itemID = 1001, count = 1 }},
        },
    }
end

addonTable.getRecipeAcquisitionRecords = function(spellID)
    if spellID == 13 then
        return {{
            sourceType = "trainer",
            requiredSkill = 202,
            purchasePrice = 50,
            prerequisiteSpellIDs = { 7413 },
        }}
    elseif spellID == 14 then
        return {{
            sourceType = "drop",
            recipeItemID = 61014,
        }}
    end
    return {{ sourceType = "learned" }}
end

local unknownAcquisitionCost = 50

addonTable.calculateRecipeCost = function(recipe, skill, context, state)
    local modifier = tonumber(context and context.activeSkillModifier) or 0

    if recipe.spellID == 14 then
        return {
            available = false,
            useful = false,
            incomplete = false,
            unavailableReason = "drop_not_guaranteed",
        }
    end

    if recipe.spellID == 13 and skill + modifier < 202 then
        return {
            available = false,
            useful = false,
            incomplete = false,
            unavailableReason = "required_skill_not_met",
        }
    end

    local material = recipe.spellID == 13 and 10 or 100
    local acquired = state.acquiredOneTime and state.acquiredOneTime["recipe:13"]
    local oneTime = {}
    local acquisition

    if recipe.spellID == 13 then
        acquisition = {
            sourceType = acquired and "simulated_learned" or "trainer",
            alreadyAcquired = acquired and true or false,
            goldCost = acquired and 0 or unknownAcquisitionCost,
            marketCost = acquired and 0 or unknownAcquisitionCost,
            key = "recipe:13",
        }
        if not acquired then
            oneTime = {{
                key = "recipe:13",
                kind = "recipe_acquisition",
                marketCost = unknownAcquisitionCost,
                goldCost = unknownAcquisitionCost,
            }}
        end
    else
        acquisition = {
            sourceType = "learned",
            alreadyAcquired = true,
            goldCost = 0,
            marketCost = 0,
            key = "recipe:10",
        }
    end

    return {
        available = true,
        useful = true,
        difficulty = "orange",
        skillUpChance = 1,
        expectedCraftsPerSkillUp = 1,
        currentPurchaseCostPerCraft = material,
        expectedCurrentPurchaseCostPerSkillUp = material,
        materialMarketValuePerCraft = material,
        expectedMarketCostPerSkillUp = material,
        goldNeededNowPerCraft = material,
        expectedGoldNeededNowPerSkillUp = material,
        oneTimeCosts = oneTime,
        acquisition = acquisition,
        quality = "complete",
        reagentCosts = {},
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
        segments = route.segments,
    }
end

assert(loadfile("ProfessionTraining.lua"))("Profession_Capper", addonTable)
assert(loadfile("RouteSolver.lua"))("Profession_Capper", addonTable)
assert(loadfile("DynamicRecommendations.lua"))("Profession_Capper", addonTable)

local cache = {
    [10] = {
        name = "Known live recipe",
        skillType = "optimal",
        reagents = {{
            name = "Dust",
            itemID = 1001,
            count = 1,
            owned = 4,
        }},
    },
}

local context = {
    professionName = "Enchanting",
    baseSkill = 200,
    effectiveSkill = 200,
    activeSkillModifier = 0,
    currentCap = 225,
}

local recipes, state = addonTable.buildFullProfessionOptimizationInput(cache, context)
assert(table.getn(recipes) == 3, "full catalog should be optimizer input")
assert(state.learnedRecipes[10] == true, "live recipe marked learned")
assert(state.learnedRecipes[13] ~= true, "unknown catalog recipe stays unknown")
assert(state.inventory[1001] == 4, "inventory retained")
assert(state.playerLevel == 80, "player level captured")
assert(state.learnedSpells[7413] == true, "prerequisite spell state captured")
assert(state.reachableCap == 450, "level 80 can route through Grand Master")
assert(table.getn(state.trainingSteps) == 3, "future profession ranks after 225 included")

local unknown
for i = 1, table.getn(recipes) do
    if recipes[i].spellID == 13 then
        unknown = recipes[i]
    end
end
assert(unknown and unknown.learned == false, "unknown recipe remains unlearned")
assert(unknown.reagents[1].itemID == 1001, "static reagent retained")

local recommendation = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    { targetSkill = 205 }
)
assert(recommendation.available == true, "complete full route should drive dynamic mode")
assert(recommendation.currentSegment.recipeID == 10, "known recipe bridges to future unlock")
assert(recommendation.currentSegment.skillEnd == 202, "known segment stops at unlock")
assert(recommendation.route.segments[2].recipeID == 13, "route switches to unknown cheaper trainer recipe")
assert(recommendation.route.totalCurrentPurchaseCost == 280, "acquisition cost included once")
assert(recommendation.nextAction == "craft", "known first segment crafts normally")

local thresholdContext = {
    professionName = "Enchanting",
    baseSkill = 202,
    effectiveSkill = 202,
    activeSkillModifier = 0,
    currentCap = 225,
}
local acquireFirst = addonTable.computeDynamicProfessionRecommendation(
    cache,
    thresholdContext,
    { targetSkill = 205 }
)
assert(acquireFirst.available == true, "unknown recipe route available at threshold")
assert(acquireFirst.currentSegment.recipeID == 13, "global route first segment is authoritative")
assert(acquireFirst.selectedRecipeLearned == false, "unknown recipe not fabricated as learned")
assert(acquireFirst.requiresAcquisition == true, "unknown recommendation exposes acquisition first")
assert(acquireFirst.nextAction == "acquire_recipe", "unknown recipe must be acquired before crafting")
assert(acquireFirst.acquisition.sourceType == "trainer", "chosen acquisition retained for UI")

unknownAcquisitionCost = 1000
local expensive = addonTable.computeDynamicProfessionRecommendation(
    cache,
    context,
    { targetSkill = 205 }
)
assert(expensive.available == true, "known route remains valid")
assert(expensive.currentSegment.recipeID == 10, "expensive acquisition keeps known recipe")
assert(table.getn(expensive.route.segments) == 1, "no unnecessary acquisition")
unknownAcquisitionCost = 50

local bloodElf = addonTable.computeDynamicProfessionRecommendation(cache, {
    professionName = "Enchanting",
    baseSkill = 192,
    effectiveSkill = 202,
    activeSkillModifier = 10,
    currentCap = 225,
}, { targetSkill = 193 })
assert(bloodElf.available == true, "profession modifier route available")
assert(bloodElf.currentSegment.recipeID == 13, "+10 Enchanting unlocks threshold recipe")

local trainingRoute = addonTable.solveCheapestProfessionRoute({
    { id = "known" },
    { id = "after-training" },
}, nil, { currentCap = 225 }, {
    startSkill = 224,
    targetSkill = 226,
    trainingSteps = {{
        key = "rank300",
        atSkill = 200,
        newCap = 300,
        status = "trainable",
        goldCost = 5,
    }},
    costRecipe = function(recipe, skill)
        if recipe.id == "after-training" and skill < 225 then
            return { available = false, useful = false, incomplete = false }
        end
        local material = recipe.id == "after-training" and 1 or 10
        return {
            available = true,
            useful = true,
            expectedCraftsPerSkillUp = 1,
            expectedMarketCostPerSkillUp = material,
            expectedGoldNeededNowPerSkillUp = material,
            expectedCurrentPurchaseCostPerSkillUp = material,
            oneTimeCosts = {},
            quality = "complete",
        }
    end,
})
assert(trainingRoute.complete == true, "rank-training route completes")
assert(trainingRoute.actions[1].recipeID == "known", "craft to current cap")
assert(trainingRoute.actions[2].type == "training", "profession rank inserted")
assert(trainingRoute.actions[3].recipeID == "after-training", "new recipe used after rank training")

print("Full-catalog adaptive route tests passed.")
