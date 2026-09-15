local addonTable = {}
assert(loadfile("RouteSolver.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function signature(route)
    local parts = {
        tostring(route.complete),
        tostring(route.reason),
        tostring(route.totalMarketCost),
        tostring(route.totalGoldCost),
        tostring(route.totalCurrentPurchaseCost),
        tostring(route.totalExpectedCrafts),
    }
    for i = 1, table.getn(route.actions or {}) do
        local action = route.actions[i]
        table.insert(parts, table.concat({
            tostring(action.type),
            tostring(action.recipeID or ""),
            tostring(action.skillFrom or ""),
            tostring(action.skillTo or ""),
            tostring(action.oldCap or ""),
            tostring(action.newCap or ""),
            tostring(action.marketCost or ""),
            tostring(action.goldCost or ""),
        }, ":"))
    end
    return table.concat(parts, "|")
end

local function runIncremental(recipes, context, state, options)
    local job = addonTable.createCheapestProfessionRouteJob(recipes, context, state, options)
    local clockValue = 0
    local function fakeClock()
        clockValue = clockValue + 0.6
        return clockValue
    end
    local slices = 0
    while job.status == "running" do
        local status = addonTable.stepCheapestProfessionRouteJob(job, 1, fakeClock)
        slices = slices + 1
        assert(slices < 10000, "incremental route must finish")
        assert(status == "running" or status == "completed", "valid job status")
    end
    local metrics = addonTable.getCheapestProfessionRouteJobMetrics(job)
    assert(metrics.released == true, "completed job releases working state")
    return job.result, metrics
end

local recipes = {{ id = "A" }, { id = "B" }}

local function acquisitionFixture(recipe, skill, context, state)
    if recipe.id == "A" then
        return {
            available = skill == 0,
            useful = skill == 0,
            expectedCraftsPerSkillUp = 1,
            expectedMarketCostPerSkillUp = 2,
            expectedGoldNeededNowPerSkillUp = 2,
            expectedCurrentPurchaseCostPerSkillUp = 2,
            oneTimeCosts = {},
            quality = "complete",
            skillUpChance = 1,
        }
    end
    local continuing = state.routeActiveRecipeID == "B"
    return {
        available = skill < 3,
        useful = skill < 3,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 1,
        expectedGoldNeededNowPerSkillUp = 1,
        expectedCurrentPurchaseCostPerSkillUp = 1,
        oneTimeCosts = continuing and {} or {{
            key = "recipe:B",
            kind = "recipe_acquisition",
            marketCost = 5,
            goldCost = 5,
        }},
        quality = "complete",
        skillUpChance = 1,
    }
end

local options = {
    startSkill = 0,
    targetSkill = 3,
    optimizeFor = "current",
    costRecipe = acquisitionFixture,
    pruneDominatedRecipeSwitches = true,
    layeredDynamicProgramming = true,
}
local sync = addonTable.solveCheapestProfessionRoute(recipes, nil, { currentCap = 3 }, options)
local incremental, metrics = runIncremental(recipes, nil, { currentCap = 3 }, options)
assertEqual(signature(incremental), signature(sync), "acquisition-first route equivalence")
assert(metrics.sliceCount > 1, "fake clock forces pause/resume across slices")
assertEqual(incremental.actions[1].recipeID, "B", "global exact first segment preserved")

local function trainingFixture()
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = 2,
        expectedGoldNeededNowPerSkillUp = 2,
        expectedCurrentPurchaseCostPerSkillUp = 2,
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1,
    }
end

local trainingOptions = {
    startSkill = 0,
    targetSkill = 3,
    optimizeFor = "current",
    costRecipe = trainingFixture,
    layeredDynamicProgramming = true,
    trainingSteps = {{
        key = "journeyman",
        atSkill = 1,
        newCap = 3,
        status = "trainable",
        goldCost = 5,
    }},
}
local trainingRecipes = {{ id = "training" }}
local trainingSync = addonTable.solveCheapestProfessionRoute(trainingRecipes, nil, { currentCap = 1 }, trainingOptions)
local trainingIncremental = runIncremental(trainingRecipes, nil, { currentCap = 1 }, trainingOptions)
assertEqual(signature(trainingIncremental), signature(trainingSync), "training boundary equivalence")
assertEqual(trainingIncremental.actions[2].type, "training", "training transition retained")

local function reusableFixture(recipe, skill, context, state)
    local acquired = state.acquiredOneTime and state.acquiredOneTime.tool
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = acquired and 1 or 11,
        expectedGoldNeededNowPerSkillUp = acquired and 1 or 11,
        expectedCurrentPurchaseCostPerSkillUp = acquired and 1 or 11,
        oneTimeCosts = acquired and {} or {{
            key = "tool",
            kind = "reusable_reagent",
            marketCost = 10,
            goldCost = 10,
        }},
        quality = "complete",
        skillUpChance = 1,
    }
end

local reusableOptions = {
    startSkill = 0,
    targetSkill = 2,
    optimizeFor = "current",
    costRecipe = reusableFixture,
    layeredDynamicProgramming = true,
}
local reusableRecipes = {{ id = "tool-user" }}
local reusableSync = addonTable.solveCheapestProfessionRoute(reusableRecipes, nil, { currentCap = 2 }, reusableOptions)
local reusableIncremental = runIncremental(reusableRecipes, nil, { currentCap = 2 }, reusableOptions)
assertEqual(signature(reusableIncremental), signature(reusableSync), "reusable tool equivalence")
assertEqual(reusableIncremental.totalMarketCost, 12, "reusable tool charged once")

local futureRecipes = {{ id = "bridge" }, { id = "future" }}
local function futureFixture(recipe, skill)
    if recipe.id == "future" and skill < 1 then
        return { available = false, useful = false, incomplete = false }
    end
    local cost = recipe.id == "future" and 1 or 10
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = cost,
        expectedGoldNeededNowPerSkillUp = cost,
        expectedCurrentPurchaseCostPerSkillUp = cost,
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1,
    }
end
local futureOptions = {
    startSkill = 0,
    targetSkill = 3,
    optimizeFor = "current",
    costRecipe = futureFixture,
    layeredDynamicProgramming = true,
}
local futureSync = addonTable.solveCheapestProfessionRoute(futureRecipes, nil, { currentCap = 3 }, futureOptions)
local futureIncremental = runIncremental(futureRecipes, nil, { currentCap = 3 }, futureOptions)
assertEqual(signature(futureIncremental), signature(futureSync), "future switch equivalence")
assertEqual(futureIncremental.actions[1].recipeID, "bridge", "bridge first")
assertEqual(futureIncremental.actions[2].recipeID, "future", "future unlock switch")

local modifierRecipes = {{ id = "plain" }, { id = "modifier" }}
local function modifierFixture(recipe, skill, context)
    local modifier = context and context.activeSkillModifier or 0
    if recipe.id == "plain" and modifier > 0 then
        return { available = false, useful = false, incomplete = false }
    end
    local cost = recipe.id == "plain" and 1 or 3
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = 1,
        expectedMarketCostPerSkillUp = cost,
        expectedGoldNeededNowPerSkillUp = cost,
        expectedCurrentPurchaseCostPerSkillUp = cost,
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1,
    }
end
local modifierContext = { activeSkillModifier = 10, currentCap = 1 }
local modifierOptions = {
    startSkill = 0,
    targetSkill = 1,
    optimizeFor = "current",
    costRecipe = modifierFixture,
    layeredDynamicProgramming = true,
}
local modifierSync = addonTable.solveCheapestProfessionRoute(modifierRecipes, modifierContext, { currentCap = 1 }, modifierOptions)
local modifierIncremental = runIncremental(modifierRecipes, modifierContext, { currentCap = 1 }, modifierOptions)
assertEqual(signature(modifierIncremental), signature(modifierSync), "modifier route equivalence")
assertEqual(modifierIncremental.actions[1].recipeID, "modifier", "modifier-aware recipe retained")

local boundedOptions = {
    startSkill = 0,
    targetSkill = 100,
    maxStates = 2,
    costRecipe = trainingFixture,
    layeredDynamicProgramming = true,
}
local boundedRecipes = {{ id = "bounded" }}
local boundedSync = addonTable.solveCheapestProfessionRoute(boundedRecipes, nil, { currentCap = 100 }, boundedOptions)
local boundedIncremental = runIncremental(boundedRecipes, nil, { currentCap = 100 }, boundedOptions)
assertEqual(signature(boundedIncremental), signature(boundedSync), "state-limit equivalence")
assertEqual(boundedIncremental.reason, "state_limit_exceeded", "incremental state limit")

local generation = 1
local cancelOptions = {
    startSkill = 0,
    targetSkill = 30,
    costRecipe = trainingFixture,
    layeredDynamicProgramming = true,
    generationToken = 1,
    isJobCurrent = function(token) return token == generation end,
}
local cancelJob = addonTable.createCheapestProfessionRouteJob({{ id = "cancel" }}, nil, { currentCap = 30 }, cancelOptions)
local fake = 0
local function cancelClock()
    fake = fake + 0.6
    return fake
end
assertEqual(addonTable.stepCheapestProfessionRouteJob(cancelJob, 1, cancelClock), "running", "generation N starts")
generation = 2
assertEqual(addonTable.stepCheapestProfessionRouteJob(cancelJob, 1, cancelClock), "cancelled", "generation N cannot continue after N+1")
local cancelMetrics = addonTable.getCheapestProfessionRouteJobMetrics(cancelJob)
assert(cancelMetrics.released == true, "cancelled job releases all heavy state")
assertEqual(cancelMetrics.cancelReason, "stale_inputs", "stale cancellation reason")

local errorJob = addonTable.createCheapestProfessionRouteJob(
    {{ id = "error" }},
    nil,
    { currentCap = 2 },
    {
        startSkill = 0,
        targetSkill = 2,
        layeredDynamicProgramming = true,
        costRecipe = function() error("fixture optimizer failure") end,
    }
)
local ok = true
local errorText
for attempt = 1, 20 do
    ok, errorText = pcall(
        addonTable.stepCheapestProfessionRouteJob,
        errorJob,
        1,
        cancelClock
    )
    if not ok or errorJob.status ~= "running" then
        break
    end
end
assert(ok == false, "optimizer error still propagates to fallback boundary")
assert(string.find(tostring(errorText), "fixture optimizer failure", 1, true), "optimizer error retained")
addonTable.cancelCheapestProfessionRouteJob(errorJob, "optimizer_error")
assert(addonTable.getCheapestProfessionRouteJobMetrics(errorJob).released == true, "failed job releases state")

print("Incremental route execution tests passed")
