local failures = {}
local passCount = 0

local function check(condition, label, detail)
    if condition then
        passCount = passCount + 1
        return
    end
    local message = label
    if detail then
        message = message .. ": " .. tostring(detail)
    end
    table.insert(failures, message)
end

local function unavailableCost()
    return {
        available = false,
        useful = false,
        difficulty = "gray",
        skillUpChance = 0,
    }
end

local function routeCost(effective, crafts, surplus, method)
    crafts = crafts or 1
    return {
        available = true,
        useful = true,
        expectedCraftsPerSkillUp = crafts,
        expectedMarketCostPerSkillUp = effective,
        expectedGoldNeededNowPerSkillUp = effective,
        expectedCurrentPurchaseCostPerSkillUp = effective,
        expectedEffectiveCostPerSkillUp = effective,
        expectedEstimatedSurplusPerSkillUp = surplus or 0,
        selectedExecutionMethod = method or "direct",
        oneTimeCosts = {},
        quality = "complete",
        skillUpChance = 1 / crafts,
    }
end

local routeAddon = {}
assert(loadfile("RouteSolver.lua"))("Profession_Capper", routeAddon)

-- Malformed Smartest metrics must not be normalized into a free edge.
local malformedSmartest = routeAddon.solveCheapestProfessionRoute(
    {{ id = 1 }},
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
                expectedEffectiveCostPerSkillUp = "not-a-number",
                expectedEstimatedSurplusPerSkillUp = 0,
                selectedExecutionMethod = "direct",
                oneTimeCosts = {},
                quality = "complete",
                skillUpChance = 1,
            }
        end,
    }
)
check(
    malformedSmartest.complete == false,
    "malformed Smartest effective-cost edge must be rejected",
    "solver accepted nonnumeric expectedEffectiveCostPerSkillUp as a complete route"
)

-- Equal primary cost: expected crafts must decide bestSwitchNode before surplus.
do
    local a = { id = 101 }
    local b = { id = 102 }
    local c = { id = 103 }
    local result = routeAddon.solveCheapestProfessionRoute(
        { a, b, c },
        nil,
        { currentCap = 2 },
        {
            startSkill = 0,
            targetSkill = 2,
            objective = "smartest",
            candidateRecipesBySkill = {
                [0] = { a, b },
                [1] = { c },
            },
            costRecipe = function(recipe, skill)
                if skill == 0 and recipe.id == 101 then
                    return routeCost(0, 2, 1000, "scroll")
                elseif skill == 0 and recipe.id == 102 then
                    return routeCost(0, 1, 0, "direct")
                elseif skill == 1 and recipe.id == 103 then
                    return routeCost(0, 1, 0, "direct")
                end
                return unavailableCost()
            end,
        }
    )
    check(
        result.complete
            and result.actions[1].recipeID == 102
            and result.actions[2].recipeID == 103,
        "bestSwitchNode preserves crafts-before-surplus ordering",
        "equal-cost prefix pruning chose the wrong lexicographic prefix"
    )
end

-- Equal cost and crafts: selected-path surplus must decide bestSwitchNode.
do
    local a = { id = 201 }
    local b = { id = 202 }
    local c = { id = 203 }
    local result = routeAddon.solveCheapestProfessionRoute(
        { a, b, c },
        nil,
        { currentCap = 2 },
        {
            startSkill = 0,
            targetSkill = 2,
            objective = "smartest",
            candidateRecipesBySkill = {
                [0] = { a, b },
                [1] = { c },
            },
            costRecipe = function(recipe, skill)
                if skill == 0 and recipe.id == 201 then
                    return routeCost(0, 1, 5, "scroll")
                elseif skill == 0 and recipe.id == 202 then
                    return routeCost(0, 1, 20, "scroll")
                elseif skill == 1 and recipe.id == 203 then
                    return routeCost(0, 1, 0, "direct")
                end
                return unavailableCost()
            end,
        }
    )
    check(
        result.complete
            and result.actions[1].recipeID == 202
            and result.actions[2].recipeID == 203,
        "bestSwitchNode preserves surplus tie-break",
        "equal-cost/equal-crafts pruning discarded the higher-surplus prefix"
    )
end

-- A prefix that is worse on a secondary metric may still win globally by
-- continuing its current recipe. Non-best group nodes must retain continuation.
do
    local a = { id = 301 }
    local b = { id = 302 }
    local result = routeAddon.solveCheapestProfessionRoute(
        { a, b },
        nil,
        { currentCap = 2 },
        {
            startSkill = 0,
            targetSkill = 2,
            objective = "smartest",
            candidateRecipesBySkill = {
                [0] = { a, b },
                [1] = { a, b },
            },
            costRecipe = function(recipe, skill, _, state)
                if skill == 0 then
                    if recipe.id == 301 then
                        return routeCost(0, 2, 0, "direct")
                    end
                    return routeCost(0, 1, 0, "direct")
                end
                if skill == 1 and recipe.id == 301 then
                    local continuing = state
                        and tostring(state.routeActiveRecipeID) == "301"
                    return routeCost(continuing and 0 or 100, 1, 0, "direct")
                elseif skill == 1 and recipe.id == 302 then
                    return routeCost(100, 1, 0, "direct")
                end
                return unavailableCost()
            end,
        }
    )
    check(
        result.complete
            and result.actions[1].recipeID == 301
            and result.actions[2].recipeID == 301
            and result.totalEffectiveLevelingCost == 0,
        "pruning preserves a temporarily worse prefix when continuation later wins",
        "non-best continuation was pruned"
    )
end

-- Final ties must be independent of candidate input order.
do
    local r20 = { id = 20 }
    local r10 = { id = 10 }
    local function tieCost()
        return routeCost(0, 1, 0, "direct")
    end
    local forward = routeAddon.solveCheapestProfessionRoute(
        { r20, r10 },
        nil,
        { currentCap = 1 },
        {
            startSkill = 0,
            targetSkill = 1,
            objective = "smartest",
            costRecipe = tieCost,
        }
    )
    local reverse = routeAddon.solveCheapestProfessionRoute(
        { r10, r20 },
        nil,
        { currentCap = 1 },
        {
            startSkill = 0,
            targetSkill = 1,
            objective = "smartest",
            costRecipe = tieCost,
        }
    )
    check(
        forward.complete
            and reverse.complete
            and forward.actions[1].recipeID == 10
            and reverse.actions[1].recipeID == 10,
        "Smartest final tie is independent of recipe input order",
        "stable route ordering changed with candidate order"
    )
end

-- Migration must be deterministic/idempotent and Static must preserve dormant
-- optimized preferences.
do
    local settingsAddon = {}
    settingsAddon.noteRuntimeModeChanged = function() end
    assert(loadfile("Settings.lua"))("Profession_Capper", settingsAddon)

    ProfessionCapperDB = {
        recommendationMode = "available",
        unrelated = "keep-me",
    }
    local first = settingsAddon.getSettings()
    local firstMode = first.recommendationMode
    local firstObjective = first.recommendationObjective
    local firstAvailable = first.recommendationAvailableOnly
    local firstVersion = first.recommendationSettingsVersion
    local second = settingsAddon.getSettings()
    check(
        second.recommendationMode == firstMode
            and second.recommendationObjective == firstObjective
            and second.recommendationAvailableOnly == firstAvailable
            and second.recommendationSettingsVersion == firstVersion
            and second.unrelated == "keep-me",
        "recommendation settings migration is idempotent",
        "second migration changed saved settings"
    )

    settingsAddon.setRecommendationObjective("smartest")
    settingsAddon.setRecommendationAvailableOnly(true)
    settingsAddon.setRecommendationMode("static")
    local static = settingsAddon.getSettings()
    check(
        static.recommendationMode == "static"
            and static.recommendationObjective == "smartest"
            and static.recommendationAvailableOnly == true,
        "Static preserves dormant optimized objective/filter preferences",
        "Static destroyed Smartest or available-only preference"
    )
end

local function makeRecommendationHarness(recipes, state, costRecipe)
    local addon = {}
    assert(loadfile("RouteSolver.lua"))("Profession_Capper", addon)
    assert(loadfile("DynamicRecommendations.lua"))("Profession_Capper", addon)

    addon.getActivePriceProviderName = function()
        return "task43-review"
    end
    addon.lookupItemPrice = function()
        return {
            available = true,
            marketValue = 1,
            minBuyout = 1,
            source = "fixture",
            freshness = "fresh",
            ageSeconds = 1,
            numAuctions = 999,
        }
    end
    addon.chooseUsableUnitPrice = function(result)
        return {
            unitPrice = result.minBuyout or result.marketValue or 1,
            priceType = "auction",
            source = result.source,
            freshness = result.freshness,
            ageSeconds = result.ageSeconds,
            numAuctions = result.numAuctions,
            availableQuantity = result.availableQuantity,
        }
    end
    addon.getRecipeDifficultyMetadata = function()
        return {
            requiredSkill = 0,
            yellowSkill = 10,
            greenSkill = 10,
            graySkill = 10,
        }
    end
    addon.buildFullProfessionOptimizationInput = function()
        return recipes, state
    end
    addon.calculateRecipeCost = costRecipe
    addon.buildProfessionShoppingPlan = function()
        return {
            complete = false,
            reason = "review_fixture_route_should_be_incomplete",
        }
    end

    return addon
end

-- Available-only must filter the same Cheapest ordering, not replace it with a
-- different gold-needed-now objective.
do
    local recipes = {
        { spellID = 401, name = "Cheapest A" },
        { spellID = 402, name = "Cheapest B" },
    }
    local state = {
        baseSkill = 0,
        currentCap = 2,
        reachableCap = 2,
        inventory = {},
        learnedRecipes = {
            [401] = true,
            [402] = true,
        },
        acquiredOneTime = {},
        trainingSteps = {},
        fullCatalog = true,
    }
    local function costRecipe(recipe, skill)
        if skill ~= 0 then
            return unavailableCost()
        end
        local currentCost = recipe.spellID == 401 and 100 or 150
        local availableGold = recipe.spellID == 401 and 500 or 150
        return {
            available = true,
            useful = true,
            difficulty = "orange",
            skillUpChance = 1,
            expectedCraftsPerSkillUp = 1,
            currentPurchaseCostPerCraft = currentCost,
            expectedCurrentPurchaseCostPerSkillUp = currentCost,
            materialMarketValuePerCraft = currentCost,
            expectedMarketCostPerSkillUp = currentCost,
            goldNeededNowPerCraft = availableGold,
            expectedGoldNeededNowPerSkillUp = availableGold,
            effectiveCostPerCraft = currentCost,
            expectedEffectiveCostPerSkillUp = currentCost,
            expectedEstimatedSurplusPerSkillUp = 0,
            selectedExecutionMethod = "direct",
            oneTimeCosts = {},
            reagentCosts = {},
            quality = "complete",
            availableNow = true,
            availabilityConfidence = "confirmed",
        }
    end

    local addon = makeRecommendationHarness(recipes, state, costRecipe)
    local unrestricted = addon.computeDynamicProfessionRecommendation(
        {},
        {
            professionName = "Enchanting",
            baseSkill = 0,
            effectiveSkill = 0,
            activeSkillModifier = 0,
            currentCap = 2,
        },
        {
            targetSkill = 2,
            objective = "cheapest",
        }
    )
    local filtered = addon.computeDynamicProfessionRecommendation(
        {},
        {
            professionName = "Enchanting",
            baseSkill = 0,
            effectiveSkill = 0,
            activeSkillModifier = 0,
            currentCap = 2,
        },
        {
            targetSkill = 2,
            objective = "cheapest",
            availableOnly = true,
        }
    )

    check(
        unrestricted.currentSegment
            and unrestricted.currentSegment.recipeID == 401,
        "unrestricted Cheapest fallback uses current-purchase objective",
        "fixture did not establish the Cheapest baseline"
    )
    check(
        filtered.availableCandidates
            and table.getn(filtered.availableCandidates) == 2,
        "availability fixture keeps both candidate recipes feasible",
        "fixture did not establish independent feasibility"
    )
    check(
        filtered.currentSegment
            and filtered.currentSegment.recipeID == 401,
        "availableOnly filters feasibility without changing Cheapest fallback score",
        "both recipes are feasible, but enabling availableOnly changed the selected recipe"
    )
end

-- Smartest fallback must include the same acquisition edge cost as the full
-- solver. Force the full route to become incomplete after the first point so
-- the fallback is the published current recommendation.
do
    local recipes = {
        { spellID = 501, name = "Zero craft cost, expensive recipe" },
        { spellID = 502, name = "Moderate craft cost, learned recipe" },
    }
    local state = {
        baseSkill = 0,
        currentCap = 2,
        reachableCap = 2,
        inventory = {},
        learnedRecipes = {
            [501] = false,
            [502] = true,
        },
        acquiredOneTime = {},
        trainingSteps = {},
        fullCatalog = true,
    }
    local function costRecipe(recipe, skill, _, routeState)
        if skill ~= 0 then
            return unavailableCost()
        end

        local isExpensiveRecipe = recipe.spellID == 501
        local key = "recipe:" .. tostring(recipe.spellID)
        local acquired = routeState
            and routeState.acquiredOneTime
            and routeState.acquiredOneTime[key] == true
        local oneTimeCosts = {}
        if isExpensiveRecipe and not acquired then
            oneTimeCosts = {{
                key = key,
                kind = "recipe_acquisition",
                marketCost = 1000,
                goldCost = 1000,
            }}
        end

        local effective = isExpensiveRecipe and 0 or 100
        return {
            available = true,
            useful = true,
            difficulty = "orange",
            skillUpChance = 1,
            expectedCraftsPerSkillUp = 1,
            currentPurchaseCostPerCraft = effective,
            expectedCurrentPurchaseCostPerSkillUp = effective,
            materialMarketValuePerCraft = effective,
            expectedMarketCostPerSkillUp = effective,
            goldNeededNowPerCraft = effective,
            expectedGoldNeededNowPerSkillUp = effective,
            effectiveCostPerCraft = effective,
            expectedEffectiveCostPerSkillUp = effective,
            expectedEstimatedSurplusPerSkillUp = 0,
            selectedExecutionMethod = "direct",
            oneTimeCosts = oneTimeCosts,
            reagentCosts = {},
            quality = "complete",
            availableNow = true,
        }
    end

    local addon = makeRecommendationHarness(recipes, state, costRecipe)
    local authoritative = addon.solveCheapestProfessionRoute(
        recipes,
        nil,
        {
            currentCap = 1,
            acquiredOneTime = {},
        },
        {
            startSkill = 0,
            targetSkill = 1,
            objective = "smartest",
            costRecipe = costRecipe,
        }
    )
    check(
        authoritative.complete
            and authoritative.actions[1].recipeID == 502,
        "authoritative Smartest edge includes recipe acquisition cost",
        "fixture did not establish authoritative acquisition ordering"
    )

    local recommendation = addon.computeDynamicProfessionRecommendation(
        {},
        {
            professionName = "Enchanting",
            baseSkill = 0,
            effectiveSkill = 0,
            activeSkillModifier = 0,
            currentCap = 2,
        },
        {
            targetSkill = 2,
            objective = "smartest",
        }
    )
    check(
        recommendation.routeComplete == false,
        "Smartest fallback fixture forces an incomplete authoritative route",
        "fixture unexpectedly completed the full route"
    )
    check(
        recommendation.currentSegment
            and recommendation.currentSegment.recipeID == 502,
        "Smartest fallback uses authoritative acquisition-aware ordering",
        "fallback ignored recipe acquisition and disagreed with the authoritative edge"
    )
end

print(string.format(
    "Task 43 adversarial review: %d checks passed, %d defects confirmed",
    passCount,
    table.getn(failures)
))
for index = 1, table.getn(failures) do
    print("DEFECT: " .. failures[index])
end

if table.getn(failures) > 0 then
    error("Task 43 independent review found correctness defects", 0)
end
