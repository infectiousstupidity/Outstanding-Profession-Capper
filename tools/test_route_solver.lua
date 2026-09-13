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
    if not (state.acquiredOneTime and state.acquiredOneTime["recipe:B"]) then
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

print("Cheapest route solver tests passed.")
