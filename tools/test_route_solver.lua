local addonTable = {}
assert(loadfile("RouteSolver.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local recipes = {
    { id = "A" },
    { id = "B" },
}

local function globalFixture(recipe, skill, context, state)
    if recipe.id == "A" then
        if skill > 0 then
            return {
                available = false,
                useful = false,
                incomplete = false,
                unavailableReason = "gray_recipe",
            }
        end

        return {
            available = true,
            useful = true,
            expectedCraftsPerSkillUp = 1,
            expectedMarketCostPerSkillUp = 2,
            expectedGoldNeededNowPerSkillUp = 2,
            oneTimeCosts = {},
            quality = "complete",
            skillUpChance = 1,
        }
    end

    local oneTime = {}
    local continuing = state.routeActiveRecipeID == "B"
    if not continuing and not (state.acquiredOneTime and state.acquiredOneTime["recipe:B"]) then
        oneTime = {
            {
                key = "recipe:B",
                kind = "recipe_acquisition",
                marketCost = 5,
                goldCost = 5,
            },
        }
    end

    return {
        available = skill < 3,
        useful = skill < 3,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 1,
        expectedGoldNeededNowPerSkillUp = 1,
        oneTimeCosts = oneTime,
        quality = "complete",
        skillUpChance = 1,
    }
end

local global = addonTable.solveCheapestProfessionRoute(recipes, nil, { currentCap = 3 }, {
    startSkill = 0,
    targetSkill = 3,
    costRecipe = globalFixture,
    pruneDominatedRecipeSwitches = true,
    layeredDynamicProgramming = true,
})
assertEqual(global.complete, true, "global route complete")
assertEqual(global.actions[1].recipeID, "B", "global optimizer avoids greedy first craft")
assertEqual(global.totalMarketCost, 8, "global route total")
assertEqual(global.segments[1].skillStart, 0, "segment start")
assertEqual(global.segments[1].skillEnd, 3, "segment end")
assertEqual(global.segments[1].expectedCrafts, 3, "segment crafts")

local function unavailableFixture(recipe, skill)
    if recipe.id == "A" and skill == 0 then
        return {
            available = true,
            useful = true,
            expectedCraftsPerSkillUp = 1,
            expectedMarketCostPerSkillUp = 1,
            expectedGoldNeededNowPerSkillUp = 1,
            oneTimeCosts = {},
            quality = "complete",
        }
    end

    return {
        available = false,
        useful = false,
        incomplete = recipe.id == "B",
        unavailableReason = recipe.id == "B" and "incomplete_price_data" or "gray_recipe",
    }
end

local incomplete = addonTable.solveCheapestProfessionRoute(recipes, nil, { currentCap = 3 }, {
    startSkill = 0,
    targetSkill = 3,
    costRecipe = unavailableFixture,
})
assertEqual(incomplete.complete, false, "incomplete route rejected")
assertEqual(incomplete.fallbackToStaticGuide, true, "incomplete route falls back")
assertEqual(incomplete.reason, "no_complete_route", "incomplete route reason")

local function trainingFixture()
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 2,
        expectedGoldNeededNowPerSkillUp = 2,
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1,
    }
end

local trained = addonTable.solveCheapestProfessionRoute({
    { id = "trainer-test" },
}, nil, { currentCap = 1 }, {
    startSkill = 0,
    targetSkill = 3,
    costRecipe = trainingFixture,
    trainingSteps = {
        {
            key = "journeyman",
            atSkill = 1,
            newCap = 3,
            status = "trainable",
            goldCost = 5,
        },
    },
})
assertEqual(trained.complete, true, "training route complete")
assertEqual(trained.actions[2].type, "training", "training gate inserted")
assertEqual(trained.totalMarketCost, 11, "training cost included")

local modifierRecipes = {
    { id = "cheap-without-modifier" },
    { id = "modifier-route" },
}

local function modifierFixture(recipe, skill, context)
    local modifier = context and context.activeSkillModifier or 0

    if recipe.id == "cheap-without-modifier" then
        if modifier > 0 then
            return {
                available = false,
                useful = false,
                incomplete = false,
                unavailableReason = "gray_recipe",
            }
        end

        return {
            available = true,
            useful = true,
            expectedCraftsPerSkillUp = 1,
            expectedMarketCostPerSkillUp = 1,
            expectedGoldNeededNowPerSkillUp = 1,
            oneTimeCosts = {},
            quality = "complete",
            skillUpChance = 1,
        }
    end

    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 3,
        expectedGoldNeededNowPerSkillUp = 3,
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1,
    }
end

local noModifier = addonTable.solveCheapestProfessionRoute(
    modifierRecipes,
    { activeSkillModifier = 0 },
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        costRecipe = modifierFixture,
    }
)
assertEqual(noModifier.actions[1].recipeID, "cheap-without-modifier", "no modifier route")

local withModifier = addonTable.solveCheapestProfessionRoute(
    modifierRecipes,
    { activeSkillModifier = 10 },
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        costRecipe = modifierFixture,
    }
)
assertEqual(withModifier.actions[1].recipeID, "modifier-route", "modifier changes route")

local function reusableFixture(recipe, skill, context, state)
    local acquired = state.acquiredOneTime and state.acquiredOneTime.tool
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = acquired and 1 or 11,
        expectedGoldNeededNowPerSkillUp = acquired and 1 or 11,
        oneTimeCosts = acquired and {} or {
            {
                key = "tool",
                kind = "reusable_reagent",
                marketCost = 10,
                goldCost = 10,
            },
        },
        quality = "complete",
        skillUpChance = 1,
    }
end

local reusableRoute = addonTable.solveCheapestProfessionRoute({
    { id = "tool-user" },
}, nil, { currentCap = 2 }, {
    startSkill = 0,
    targetSkill = 2,
    costRecipe = reusableFixture,
})
assertEqual(reusableRoute.totalMarketCost, 12, "reusable cost charged once")

local currentRecipes = {
    { id = "cheap-market" },
    { id = "cheap-current" },
}

local function currentPriceFixture(recipe)
    if recipe.id == "cheap-market" then
        return {
            available = true,
            useful = true,
            expectedCraftsPerSkillUp = 1,
            expectedMarketCostPerSkillUp = 50,
            expectedGoldNeededNowPerSkillUp = 50,
            expectedCurrentPurchaseCostPerSkillUp = 200,
            oneTimeCosts = {},
            quality = "complete",
            skillUpChance = 1,
        }
    end

    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 100,
        expectedGoldNeededNowPerSkillUp = 100,
        expectedCurrentPurchaseCostPerSkillUp = 80,
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1,
    }
end

local currentPriceRoute = addonTable.solveCheapestProfessionRoute(
    currentRecipes,
    nil,
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        optimizeFor = "current",
        costRecipe = currentPriceFixture,
    }
)
assertEqual(currentPriceRoute.complete, true, "current-price route complete")
assertEqual(currentPriceRoute.actions[1].recipeID, "cheap-current", "current AH price drives route")
assertEqual(currentPriceRoute.totalCurrentPurchaseCost, 80, "current purchase total exposed")

local bounded = addonTable.solveCheapestProfessionRoute({
    { id = "bounded" },
}, nil, { currentCap = 100 }, {
    startSkill = 0,
    targetSkill = 100,
    maxStates = 2,
    costRecipe = trainingFixture,
})
assertEqual(bounded.complete, false, "state limit returns incomplete")
assertEqual(bounded.reason, "state_limit_exceeded", "state limit reason")

local manyRecipes = {}
for i = 1, 40 do
    manyRecipes[i] = { id = "recipe-" .. tostring(i), rank = i }
end

local manyCostCalls = 0
local function manyRecipeFixture(recipe, skill, context, state)
    manyCostCalls = manyCostCalls + 1
    local continuing = state.routeActiveRecipeID == recipe.id
    local acquisition = continuing and {} or {
        {
            key = "recipe:" .. recipe.id,
            kind = "recipe_acquisition",
            marketCost = recipe.rank,
            goldCost = recipe.rank,
        },
    }
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = recipe.rank,
        expectedGoldNeededNowPerSkillUp = recipe.rank,
        expectedCurrentPurchaseCostPerSkillUp = recipe.rank,
        oneTimeCosts = acquisition,
        quality = "complete",
        skillUpChance = 1,
    }
end

local indexedCandidates = {}
for skill = 0, 29 do
    indexedCandidates[skill] = {
        manyRecipes[1],
        manyRecipes[2],
        manyRecipes[3],
        manyRecipes[4],
        manyRecipes[5],
    }
end

local scalable = addonTable.solveCheapestProfessionRoute(
    manyRecipes,
    nil,
    { currentCap = 30 },
    {
        startSkill = 0,
        targetSkill = 30,
        maxStates = 10000,
        optimizeFor = "current",
        costRecipe = manyRecipeFixture,
        candidateRecipesBySkill = indexedCandidates,
        pruneDominatedRecipeSwitches = true,
        layeredDynamicProgramming = true,
    }
)
assertEqual(scalable.complete, true, "full-catalog style route completes within bounded state space")
assertEqual(scalable.actions[1].recipeID, "recipe-1", "cheapest activation wins")
assertEqual(scalable.totalCurrentPurchaseCost, 31, "recipe acquisition is charged once for a continuous segment")
assert(scalable.exploredStates < 6000, "exact indexed route stays below production state ceiling")
assert(manyCostCalls < 12000, "exact layered DP keeps cost evaluations bounded")

local returnRecipes = {
    { id = "A" },
    { id = "B" },
}

local returnCosts = {
    A = { [0] = 2, [1] = 3, [2] = 200 },
    B = { [0] = 1, [1] = 100, [2] = 101 },
}

local function acquireSwitchReturnFixture(recipe, skill, context, state)
    local acquired = state.acquiredOneTime
        and state.acquiredOneTime["recipe:" .. tostring(recipe.id)] == true
    local continuing = state.routeActiveRecipeID ~= nil
        and tostring(state.routeActiveRecipeID) == tostring(recipe.id)
    local oneTimeCosts = {}

    if recipe.id == "B" and not acquired and not continuing then
        oneTimeCosts = {{
            key = "recipe:B",
            kind = "recipe_acquisition",
            marketCost = 10,
            goldCost = 10,
        }}
    end

    local material = returnCosts[recipe.id][skill]
    return {
        available = material ~= nil,
        useful = material ~= nil,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = material,
        expectedGoldNeededNowPerSkillUp = material,
        expectedCurrentPurchaseCostPerSkillUp = material,
        oneTimeCosts = oneTimeCosts,
        quality = "complete",
        skillUpChance = 1,
    }
end

local returnOptions = {
    startSkill = 0,
    targetSkill = 3,
    optimizeFor = "current",
    costRecipe = acquireSwitchReturnFixture,
    pruneDominatedRecipeSwitches = true,
    layeredDynamicProgramming = true,
}
local exactReturn = addonTable.solveCheapestProfessionRoute(
    returnRecipes,
    nil,
    { currentCap = 3 },
    returnOptions
)
assertEqual(exactReturn.complete, true, "acquire-switch-return route complete")
assertEqual(exactReturn.actions[1].recipeID, "B", "acquired recipe starts exact route")
assertEqual(exactReturn.actions[2].recipeID, "A", "exact route can switch away")
assertEqual(exactReturn.actions[3].recipeID, "B", "exact route can return to learned recipe")
assertEqual(exactReturn.totalCurrentPurchaseCost, 115, "recipe acquisition charged exactly once")
assertEqual(exactReturn.actions[1].acquisitionGoldCost, 10, "first use pays acquisition")
assertEqual(exactReturn.actions[3].acquisitionGoldCost, 0, "return use does not repay acquisition")

local defaultReturnOptions = {
    startSkill = 0,
    targetSkill = 3,
    optimizeFor = "current",
    costRecipe = acquireSwitchReturnFixture,
    pruneDominatedRecipeSwitches = true,
}
local defaultReturn = addonTable.solveCheapestProfessionRoute(
    returnRecipes,
    nil,
    { currentCap = 3 },
    defaultReturnOptions
)
assertEqual(defaultReturn.complete, true, "default synchronous acquire-switch-return route complete")
assertEqual(defaultReturn.actions[1].recipeID, "B", "default synchronous route starts acquired recipe")
assertEqual(defaultReturn.actions[2].recipeID, "A", "default synchronous route switches away")
assertEqual(defaultReturn.actions[3].recipeID, "B", "default synchronous route returns without repayment")
assertEqual(defaultReturn.totalCurrentPurchaseCost, 115, "default synchronous route acquisition charged once")

local stressRecipes = {}
local stressCandidates = {}
for index = 1, 12 do
    stressRecipes[index] = { id = "stress-" .. tostring(index) }
end
for skill = 0, 7 do
    stressCandidates[skill] = stressRecipes
end

local function acquisitionStressFixture(recipe, skill, context, state)
    local key = "recipe:" .. tostring(recipe.id)
    local acquired = state.acquiredOneTime and state.acquiredOneTime[key] == true
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 1,
        expectedGoldNeededNowPerSkillUp = 1,
        expectedCurrentPurchaseCostPerSkillUp = 1,
        oneTimeCosts = acquired and {} or {{
            key = key,
            kind = "recipe_acquisition",
            marketCost = 1,
            goldCost = 1,
        }},
        quality = "complete",
        skillUpChance = 1,
    }
end

local stressJob = addonTable.createCheapestProfessionRouteJob(
    stressRecipes,
    nil,
    { currentCap = 8 },
    {
        startSkill = 0,
        targetSkill = 8,
        maxStates = 64,
        optimizeFor = "current",
        costRecipe = acquisitionStressFixture,
        candidateRecipesBySkill = stressCandidates,
        pruneDominatedRecipeSwitches = true,
    }
)
local stressResult = addonTable.runCheapestProfessionRouteJob(stressJob)
local stressMetrics = addonTable.getCheapestProfessionRouteJobMetrics(stressJob)
assertEqual(stressResult.complete, false, "acquisition stress stops before state explosion")
assertEqual(stressResult.reason, "state_limit_exceeded", "acquisition stress hits deterministic state bound")
assert(stressMetrics.peakLayerStates <= 64, "live layered state count never exceeds hard bound")
assertEqual(stressMetrics.recipeAcquisitionBits, 12, "stress route tracks only candidate recipe bits")
assertEqual(stressMetrics.recipeAcquisitionBytes, 2, "candidate acquisition history uses compact fixed-width bitset")

local smartestRecipes = {
    { id = 20 },
    { id = 10 },
    { id = 30 },
}

local function smartestFixture(recipe)
    local byID = {
        [20] = {
            gross = 50,
            effective = 50,
            crafts = 1,
            surplus = 0,
            method = "direct",
        },
        [10] = {
            gross = 100,
            effective = 20,
            crafts = 1,
            surplus = 15,
            method = "scroll",
        },
        [30] = {
            gross = 80,
            effective = 30,
            crafts = 1,
            surplus = 0,
            method = "direct",
        },
    }
    local row = byID[recipe.id]
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = row.crafts,
        expectedMarketCostPerSkillUp = row.gross,
        expectedGoldNeededNowPerSkillUp = row.gross,
        expectedCurrentPurchaseCostPerSkillUp = row.gross,
        expectedEffectiveCostPerSkillUp = row.effective,
        expectedEstimatedSurplusPerSkillUp = row.surplus,
        selectedExecutionMethod = row.method,
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1 / row.crafts,
    }
end

local cheapestBaseline = addonTable.solveCheapestProfessionRoute(
    smartestRecipes,
    nil,
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        optimizeFor = "current",
        objective = "cheapest",
        costRecipe = smartestFixture,
    }
)
assertEqual(cheapestBaseline.actions[1].recipeID, 20, "Cheapest still uses gross/current purchase cost")

local smartest = addonTable.solveCheapestProfessionRoute(
    smartestRecipes,
    nil,
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        objective = "smartest",
        costRecipe = smartestFixture,
    }
)
assertEqual(smartest.actions[1].recipeID, 10, "Smartest can choose higher gross cost after resale credit")
assertEqual(smartest.totalEffectiveLevelingCost, 20, "Smartest exposes effective route cost")
assertEqual(smartest.totalExpectedCrafts, 1, "Smartest exposes expected crafts")
assertEqual(smartest.totalEstimatedResaleSurplus, 15, "Smartest exposes selected scroll surplus")

local tieRecipes = {
    { id = 3, crafts = 2, surplus = 1000 },
    { id = 2, crafts = 1, surplus = 5 },
    { id = 1, crafts = 1, surplus = 20 },
}
local function tieFixture(recipe)
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = recipe.crafts,
        expectedMarketCostPerSkillUp = 100,
        expectedGoldNeededNowPerSkillUp = 100,
        expectedCurrentPurchaseCostPerSkillUp = 100,
        expectedEffectiveCostPerSkillUp = 0,
        expectedEstimatedSurplusPerSkillUp = recipe.surplus,
        selectedExecutionMethod = "scroll",
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1 / recipe.crafts,
    }
end

local efficiencyTie = addonTable.solveCheapestProfessionRoute(
    { tieRecipes[1], tieRecipes[3] },
    nil,
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        objective = "smartest",
        costRecipe = tieFixture,
    }
)
assertEqual(efficiencyTie.actions[1].recipeID, 1, "zero-cost tie prefers fewer expected crafts before surplus")

local surplusTie = addonTable.solveCheapestProfessionRoute(
    { tieRecipes[2], tieRecipes[3] },
    nil,
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        objective = "smartest",
        costRecipe = tieFixture,
    }
)
assertEqual(surplusTie.actions[1].recipeID, 1, "surplus breaks tie only after cost and crafts")

local deterministicTie = addonTable.solveCheapestProfessionRoute(
    {
        { id = 20, crafts = 1, surplus = 0 },
        { id = 10, crafts = 1, surplus = 0 },
    },
    nil,
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        objective = "smartest",
        costRecipe = tieFixture,
    }
)
assertEqual(deterministicTie.actions[1].recipeID, 10, "Smartest final tie uses stable recipe ID order")

local negativeSmartest = addonTable.solveCheapestProfessionRoute(
    {{ id = "negative" }},
    nil,
    { currentCap = 1 },
    {
        startSkill = 0,
        targetSkill = 1,
        objective = "smartest",
        costRecipe = function()
            return {
                available = true,
                useful = true,
                expectedCraftsPerSkillUp = 1,
                expectedMarketCostPerSkillUp = 10,
                expectedGoldNeededNowPerSkillUp = 10,
                expectedCurrentPurchaseCostPerSkillUp = 10,
                expectedEffectiveCostPerSkillUp = -1,
                expectedEstimatedSurplusPerSkillUp = 0,
                selectedExecutionMethod = "direct",
                oneTimeCosts = {},
                quality = "complete",
                skillUpChance = 1,
            }
        end,
    }
)
assertEqual(negativeSmartest.complete, false, "negative Smartest edge is rejected")
assertEqual(negativeSmartest.missingData[1], "negative_smartest_edge", "negative edge guard reason")

print("Cheapest and Smartest route solver tests passed.")
