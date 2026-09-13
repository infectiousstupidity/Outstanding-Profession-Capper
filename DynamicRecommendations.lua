local addonName, addonTable = ...

local REUSABLE_PROFESSION_TOOLS = {
    [6218] = true,
    [6339] = true,
    [11130] = true,
    [11145] = true,
    [16207] = true,
    [22461] = true,
    [22462] = true,
    [22463] = true,
    [44451] = true,
    [44452] = true,
}

local function parseItemID(item)
    if type(item) == "number" then
        return item
    end
    if type(item) ~= "string" then
        return nil
    end

    local numeric = tonumber(item)
    if numeric then
        return numeric
    end

    local itemID = string.match(item, "[Ii][Tt][Ee][Mm]:(%d+)")
    return itemID and tonumber(itemID) or nil
end

local function getOwnedCount(itemID, fallback)
    if itemID and type(GetItemCount) == "function" then
        local ok, count = pcall(GetItemCount, itemID, true)
        if not ok then
            ok, count = pcall(GetItemCount, itemID)
        end
        if ok and tonumber(count) then
            return math.max(0, tonumber(count))
        end
    end

    return math.max(0, tonumber(fallback) or 0)
end

local function copyLiveReagent(reagent)
    local itemID = reagent.itemID or parseItemID(reagent.itemLink)
    local reusable = itemID and REUSABLE_PROFESSION_TOOLS[itemID] and true or false
    local result = {
        itemID = itemID,
        item = reagent.itemLink or reagent.name,
        itemLink = reagent.itemLink,
        name = reagent.name,
        quantity = tonumber(reagent.count or reagent.quantity) or 0,
        reusable = reusable,
    }

    if reusable then
        result.reusableKey = "item:" .. tostring(itemID)
    end

    return result
end

local function copyLiveOutput(data)
    local itemID = parseItemID(data.outputItemLink)
    local quantity = tonumber(data.outputCount)
    if not itemID or not quantity or quantity <= 0 then
        return nil
    end

    return {
        itemID = itemID,
        item = data.outputItemLink,
        itemLink = data.outputItemLink,
        quantity = quantity,
    }
end

function addonTable.getItemIDFromLink(item)
    return parseItemID(item)
end

function addonTable.isKnownReusableProfessionTool(itemID)
    itemID = parseItemID(itemID)
    return itemID and REUSABLE_PROFESSION_TOOLS[itemID] and true or false
end

function addonTable.formatCopperShort(value)
    value = tonumber(value)
    if not value then
        return "n/a"
    end

    value = math.max(0, math.floor(value + 0.5))
    local gold = math.floor(value / 10000)
    local silver = math.floor((value % 10000) / 100)
    local copper = value % 100

    if gold > 0 then
        return string.format("%dg %02ds", gold, silver)
    end
    if silver > 0 then
        return string.format("%ds %02dc", silver, copper)
    end
    return string.format("%dc", copper)
end

function addonTable.formatPriceAge(ageSeconds)
    ageSeconds = tonumber(ageSeconds)
    if not ageSeconds then
        return "age unknown"
    end

    ageSeconds = math.max(0, ageSeconds)
    if ageSeconds < 60 then
        return "<1m old"
    end

    local minutes = math.floor(ageSeconds / 60)
    if minutes < 60 then
        return tostring(minutes) .. "m old"
    end

    local hours = math.floor(minutes / 60)
    if hours < 48 then
        return tostring(hours) .. "h old"
    end

    return tostring(math.floor(hours / 24)) .. "d old"
end

function addonTable.getMaterialPriceInfo(item, neededQuantity, now, options)
    options = options or {}
    local quantity = math.max(0, tonumber(neededQuantity) or 0)
    if quantity <= 0 then
        return {
            available = true,
            neededQuantity = 0,
            estimatedRemainingCost = 0,
        }
    end

    local priceLookup = options.priceLookup or addonTable.lookupItemPrice
    local priceChooser = options.unitPriceChooser or addonTable.chooseUsableUnitPrice
    if type(priceLookup) ~= "function"
        or type(priceChooser) ~= "function"
    then
        return {
            available = false,
            neededQuantity = quantity,
            reason = "price_provider_unavailable",
        }
    end

    local choice
    local reason
    if type(addonTable.chooseCheapestEquivalentPurchase) == "function" then
        choice, reason = addonTable.chooseCheapestEquivalentPurchase(item, quantity, "purchase", {
            now = now,
            priceLookup = priceLookup,
            unitPriceChooser = priceChooser,
        })
    elseif type(addonTable.chooseCheapestEquivalentUnitPrice) == "function" then
        choice, reason = addonTable.chooseCheapestEquivalentUnitPrice(item, "purchase", {
            now = now,
            priceLookup = priceLookup,
            unitPriceChooser = priceChooser,
        })
        if choice then
            choice.requestedQuantity = quantity
            choice.sourceQuantity = quantity
            choice.sourceUnitPrice = choice.unitPrice
            choice.totalCost = quantity * choice.unitPrice
            choice.effectiveUnitPrice = choice.unitPrice
            choice.producedQuantity = quantity
            choice.excessQuantity = 0
        end
    else
        local result = priceLookup(item, now)
        choice, reason = priceChooser(result, "spend")
        if choice then
            choice.requestedQuantity = quantity
            choice.sourceQuantity = quantity
            choice.sourceUnitPrice = choice.unitPrice
            choice.totalCost = quantity * choice.unitPrice
            choice.effectiveUnitPrice = choice.unitPrice
            choice.producedQuantity = quantity
            choice.excessQuantity = 0
        else
            return {
                available = false,
                neededQuantity = quantity,
                reason = reason or (result and result.unavailableReason) or "price_unavailable",
                source = result and result.source,
                freshness = result and result.freshness,
                ageSeconds = result and result.ageSeconds,
            }
        end
    end

    if not choice then
        return {
            available = false,
            neededQuantity = quantity,
            reason = reason or "price_unavailable",
        }
    end

    return {
        available = true,
        neededQuantity = quantity,
        unitPrice = choice.effectiveUnitPrice or choice.unitPrice,
        sourceUnitPrice = choice.sourceUnitPrice or choice.unitPrice,
        sourceQuantity = choice.sourceQuantity or quantity,
        requestedQuantity = choice.requestedQuantity or quantity,
        producedQuantity = choice.producedQuantity or quantity,
        excessQuantity = choice.excessQuantity or 0,
        estimatedRemainingCost = choice.totalCost or (quantity * choice.unitPrice),
        directTotalCost = choice.directTotalCost,
        alternateTotalCost = choice.alternateTotalCost,
        savings = choice.savings,
        priceType = choice.priceType,
        source = choice.source,
        freshness = choice.freshness,
        ageSeconds = choice.ageSeconds,
        isStale = choice.isStale or choice.isTooOld,
        sourceItemID = choice.sourceItemID,
        converted = choice.converted and true or false,
        conversionRatio = choice.conversionRatio,
        conversionDirection = choice.conversionDirection,
    }
end

function addonTable.buildLiveProfessionOptimizationInput(recipeCache, skillContext)
    local recipes = {}
    local state = {
        professionName = skillContext and skillContext.professionName,
        baseSkill = skillContext and skillContext.baseSkill or 0,
        currentCap = skillContext and skillContext.currentCap or 450,
        learnedRecipes = {},
        inventory = {},
        acquiredOneTime = {},
    }

    if type(UnitFactionGroup) == "function" then
        local ok, faction = pcall(UnitFactionGroup, "player")
        if ok then
            state.faction = faction
        end
    end

    for spellID, data in pairs(recipeCache or {}) do
        if type(spellID) == "number" and type(data) == "table" then
            local eligible = true
            if type(addonTable.isRecipeEligibleForDynamicOptimization) == "function" then
                eligible = addonTable.isRecipeEligibleForDynamicOptimization(spellID)
            end

            if eligible and type(data.reagents) == "table" then
                local recipe = {
                    spellID = spellID,
                    name = data.name,
                    profession = skillContext and skillContext.professionName,
                    liveSkillType = data.skillType,
                    reagents = {},
                    outputs = {},
                }

                for i = 1, table.getn(data.reagents) do
                    local liveReagent = copyLiveReagent(data.reagents[i])
                    table.insert(recipe.reagents, liveReagent)

                    local inventoryKey = liveReagent.itemID or liveReagent.item
                    if inventoryKey ~= nil and state.inventory[inventoryKey] == nil then
                        state.inventory[inventoryKey] = getOwnedCount(
                            liveReagent.itemID,
                            data.reagents[i].owned
                        )
                    end

                    if liveReagent.reusable and liveReagent.reusableKey
                        and getOwnedCount(liveReagent.itemID, data.reagents[i].owned) > 0
                    then
                        state.acquiredOneTime[liveReagent.reusableKey] = true
                    end
                end

                local output = copyLiveOutput(data)
                if output then
                    table.insert(recipe.outputs, output)
                end

                state.learnedRecipes[spellID] = true
                table.insert(recipes, recipe)
            end
        end
    end

    table.sort(recipes, function(left, right)
        return tonumber(left.spellID) < tonumber(right.spellID)
    end)

    return recipes, state
end

local function getRecipeID(recipe)
    return recipe and (recipe.spellID or recipe.recipeID or recipe.id) or nil
end

local function shallowCopy(source)
    if type(source) ~= "table" then
        return source
    end

    local result = {}
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function createCachedPriceLookup(baseLookup)
    local cache = {}
    local cached = {}

    return function(item, now)
        local itemID = parseItemID(item)
        local key = itemID and ("item:" .. tostring(itemID)) or tostring(item)

        if cached[key] then
            return cache[key]
        end

        local result = baseLookup(item, now)
        cached[key] = true
        cache[key] = result
        return result
    end
end

local function createCachedRecipeCost(baseCostRecipe)
    local cache = {}
    local acquiredSignatureCache = setmetatable({}, { __mode = "k" })

    local function acquiredSignature(state)
        local acquired = state and (state.acquiredOneTime or state.acquiredReusable)
        if type(acquired) ~= "table" then
            return ""
        end

        local cachedSignature = acquiredSignatureCache[acquired]
        if cachedSignature then
            return cachedSignature
        end

        local parts = {}
        for key, value in pairs(acquired) do
            if value then
                table.insert(parts, tostring(key))
            end
        end
        table.sort(parts)

        local signature = table.concat(parts, "\031")
        acquiredSignatureCache[acquired] = signature
        return signature
    end

    return function(recipe, skill, skillContext, state, options)
        local recipeID = getRecipeID(recipe) or tostring(recipe)
        local key = table.concat({
            tostring(recipeID),
            tostring(tonumber(skill) or 0),
            acquiredSignature(state),
        }, "|")

        local cachedCost = cache[key]
        if cachedCost ~= nil then
            return shallowCopy(cachedCost)
        end

        local cost = baseCostRecipe(recipe, skill, skillContext, state, options or {})
        if cost ~= nil then
            cache[key] = shallowCopy(cost)
            return shallowCopy(cost)
        end
        return nil
    end
end

local LIVE_SKILL_TYPE = {
    optimal = { difficulty = "orange", defaultChance = 1 },
    medium = { difficulty = "yellow", defaultChance = 0.75 },
    easy = { difficulty = "green", defaultChance = 0.25 },
    trivial = { difficulty = "gray", defaultChance = 0 },
}

local function applyLiveSkillType(cost, recipe, skill, currentSkill)
    if skill ~= currentSkill or not recipe.liveSkillType then
        return cost
    end

    local live = LIVE_SKILL_TYPE[recipe.liveSkillType]
    if not live or not cost then
        return cost
    end

    local chance = tonumber(cost.skillUpChance)
    if cost.difficulty ~= live.difficulty then
        chance = live.defaultChance
    end

    if live.difficulty == "orange" then
        chance = 1
    elseif live.difficulty == "yellow" and (not chance or chance <= 0 or chance > 1) then
        chance = live.defaultChance
    end

    cost.difficulty = live.difficulty
    cost.skillUpChance = chance

    if chance and chance > 0 then
        cost.expectedCraftsPerSkillUp = 1 / chance
        if cost.materialMarketValuePerCraft ~= nil then
            cost.expectedMarketCostPerSkillUp = cost.materialMarketValuePerCraft / chance
        end
        if cost.goldNeededNowPerCraft ~= nil then
            cost.expectedGoldNeededNowPerSkillUp = cost.goldNeededNowPerCraft / chance
        end
        if cost.currentPurchaseCostPerCraft ~= nil then
            cost.expectedCurrentPurchaseCostPerSkillUp = cost.currentPurchaseCostPerCraft / chance
        end
    end

    return cost
end

local function rankCurrentRecipes(recipes, skillContext, state, skill, options)
    local ranked = {}
    local currentSkill = tonumber(skillContext and skillContext.baseSkill) or 0
    local costRecipe = options and options.costRecipe or addonTable.calculateRecipeCost
    if type(costRecipe) ~= "function" then
        return ranked
    end

    for i = 1, table.getn(recipes or {}) do
        local recipe = recipes[i]
        local cost = costRecipe(recipe, skill, skillContext, state, options or {})
        cost = applyLiveSkillType(cost, recipe, skill, currentSkill)
        local eligibleColor
        if skill == currentSkill and recipe.liveSkillType then
            eligibleColor = recipe.liveSkillType == "optimal" or recipe.liveSkillType == "medium"
        else
            eligibleColor = cost and (cost.difficulty == "orange" or cost.difficulty == "yellow")
        end

        if eligibleColor
            and cost
            and cost.available
            and cost.useful
            and cost.skillUpChance
            and cost.skillUpChance > 0
        then
            local expectedCost = cost.expectedCurrentPurchaseCostPerSkillUp
                or cost.expectedMarketCostPerSkillUp
            local perCraft = cost.currentPurchaseCostPerCraft
                or cost.materialMarketValuePerCraft

            if expectedCost ~= nil and perCraft ~= nil then
                table.insert(ranked, {
                    recipe = recipe,
                    recipeID = getRecipeID(recipe),
                    cost = cost,
                    expectedCostPerSkillUp = expectedCost,
                    costPerCraft = perCraft,
                    difficulty = cost.difficulty,
                    liveSkillType = recipe.liveSkillType,
                    skillUpChance = cost.skillUpChance,
                    availableNow = cost.availableNow == true,
                    availabilityConfidence = cost.availabilityConfidence,
                    availabilityIssues = cost.availabilityIssues,
                })
            end
        end
    end

    table.sort(ranked, function(left, right)
        if left.expectedCostPerSkillUp ~= right.expectedCostPerSkillUp then
            return left.expectedCostPerSkillUp < right.expectedCostPerSkillUp
        end
        if left.costPerCraft ~= right.costPerCraft then
            return left.costPerCraft < right.costPerCraft
        end
        return tonumber(left.recipeID or 0) < tonumber(right.recipeID or 0)
    end)

    return ranked
end

local function firstRankedCandidate(ranking, requireAvailableNow)
    for i = 1, table.getn(ranking or {}) do
        local candidate = ranking[i]
        if not requireAvailableNow or candidate.availableNow then
            return candidate
        end
    end
    return nil
end

local function buildCurrentCheapestSegment(recipes, skillContext, state, targetSkill, options, requireAvailableNow)
    local startSkill = tonumber(skillContext and skillContext.baseSkill) or 0
    local firstRanking = rankCurrentRecipes(recipes, skillContext, state, startSkill, options)
    local first = firstRankedCandidate(firstRanking, requireAvailableNow)
    if not first then
        return nil, firstRanking
    end

    local selectedID = first.recipeID
    local segment = {
        type = "craft",
        recipe = first.recipe,
        recipeID = selectedID,
        skillStart = startSkill,
        skillEnd = startSkill,
        expectedCrafts = 0,
        expectedMaterialCost = 0,
        expectedCurrentPurchaseCost = 0,
        firstCost = first.cost,
        quality = first.cost.quality,
    }

    local skill = startSkill
    while skill < targetSkill do
        local ranking
        if skill == startSkill then
            ranking = firstRanking
        else
            ranking = rankCurrentRecipes(recipes, skillContext, state, skill, options)
        end

        local best = firstRankedCandidate(ranking, requireAvailableNow)
        if not best or best.recipeID ~= selectedID then
            break
        end

        segment.expectedCrafts = segment.expectedCrafts
            + (tonumber(best.cost.expectedCraftsPerSkillUp) or 0)
        segment.expectedMaterialCost = segment.expectedMaterialCost
            + (tonumber(best.expectedCostPerSkillUp) or 0)
        segment.expectedCurrentPurchaseCost = segment.expectedMaterialCost
        if best.cost.quality == "stale" then
            segment.quality = "stale"
        end

        skill = skill + 1
        segment.skillEnd = skill
    end

    if segment.skillEnd <= segment.skillStart then
        return nil, firstRanking
    end

    return segment, firstRanking
end

local function orangeYellowRouteCost(recipe, skill, skillContext, state, options)
    local costRecipe = options and options.baseCostRecipe or addonTable.calculateRecipeCost
    if type(costRecipe) ~= "function" then
        return nil
    end

    local cost = costRecipe(recipe, skill, skillContext, state, options or {})
    local currentSkill = tonumber(skillContext and skillContext.baseSkill) or 0
    cost = applyLiveSkillType(cost, recipe, skill, currentSkill)
    if not cost or not cost.available then
        return cost
    end

    if options and options.requireAvailableNow and cost.availableNow ~= true then
        cost.available = false
        cost.useful = false
        cost.incomplete = false
        cost.unavailableReason = "materials_not_available_now"
        return cost
    end

    if cost.difficulty ~= "orange" and cost.difficulty ~= "yellow" then
        cost.available = false
        cost.useful = false
        cost.incomplete = false
        cost.unavailableReason = "not_orange_or_yellow"
    end
    return cost
end

function addonTable.computeDynamicProfessionRecommendation(recipeCache, skillContext, options)
    options = options or {}

    local result = {
        available = false,
        fallbackToStaticGuide = true,
        reason = nil,
        providerName = nil,
        targetSkill = nil,
        recipes = {},
        state = nil,
        route = nil,
        plan = nil,
        currentSegment = nil,
        currentCost = nil,
        candidates = {},
        availableCandidates = {},
        requireAvailableNow = options.requireAvailableNow == true,
        priceLookup = nil,
        routeComplete = false,
        routeReason = nil,
    }

    if type(skillContext) ~= "table" then
        result.reason = "profession_context_unavailable"
        return result
    end

    if type(addonTable.getActivePriceProviderName) == "function" then
        result.providerName = addonTable.getActivePriceProviderName()
    end
    if not result.providerName or result.providerName == "null" then
        result.reason = "no_price_provider"
        return result
    end

    if type(addonTable.solveCheapestProfessionRoute) ~= "function"
        or type(addonTable.buildProfessionShoppingPlan) ~= "function"
        or type(addonTable.calculateRecipeCost) ~= "function"
    then
        result.reason = "optimizer_unavailable"
        return result
    end

    local cachedPriceLookup = type(addonTable.lookupItemPrice) == "function"
        and createCachedPriceLookup(addonTable.lookupItemPrice)
        or nil
    local cachedRecipeCost = createCachedRecipeCost(addonTable.calculateRecipeCost)
    local costOptions = {}
    for key, value in pairs(options.costOptions or {}) do
        costOptions[key] = value
    end
    costOptions.priceLookup = cachedPriceLookup or costOptions.priceLookup
    costOptions.unitPriceChooser = costOptions.unitPriceChooser or addonTable.chooseUsableUnitPrice
    costOptions.costRecipe = cachedRecipeCost
    result.priceLookup = cachedPriceLookup

    local recipes, state = addonTable.buildLiveProfessionOptimizationInput(recipeCache, skillContext)
    result.recipes = recipes
    result.state = state
    if table.getn(recipes) == 0 then
        result.reason = "no_eligible_recipes"
        return result
    end

    local targetSkill = tonumber(options.targetSkill or skillContext.currentCap) or 450
    targetSkill = math.min(450, targetSkill)
    result.targetSkill = targetSkill

    if targetSkill <= (tonumber(skillContext.baseSkill) or 0) then
        result.reason = "target_reached"
        return result
    end

    local segment, candidates = buildCurrentCheapestSegment(
        recipes,
        skillContext,
        state,
        targetSkill,
        costOptions,
        result.requireAvailableNow
    )
    result.candidates = candidates or {}
    for i = 1, table.getn(result.candidates) do
        if result.candidates[i].availableNow then
            table.insert(result.availableCandidates, result.candidates[i])
        end
    end

    if not segment or not segment.recipeID then
        result.reason = result.requireAvailableNow and "no_available_recipe" or "no_current_priced_recipe"
        return result
    end

    result.currentSegment = segment
    result.currentCost = segment.firstCost
    result.available = true
    result.fallbackToStaticGuide = false
    result.reason = nil

    local routeCostOptions = {}
    for key, value in pairs(costOptions) do
        routeCostOptions[key] = value
    end
    routeCostOptions.requireAvailableNow = result.requireAvailableNow
    routeCostOptions.baseCostRecipe = cachedRecipeCost

    local route = addonTable.solveCheapestProfessionRoute(recipes, skillContext, state, {
        startSkill = skillContext.baseSkill,
        targetSkill = targetSkill,
        optimizeFor = options.optimizeFor or "current",
        maxStates = options.maxStates,
        costRecipe = orangeYellowRouteCost,
        costOptions = routeCostOptions,
    })
    result.route = route

    if not route or not route.complete then
        result.routeReason = route and route.reason or "no_complete_route"
        return result
    end

    result.routeComplete = true
    local plan = addonTable.buildProfessionShoppingPlan(route, state, {
        priceLookup = cachedPriceLookup,
        unitPriceChooser = costOptions.unitPriceChooser,
        priceRevision = options.priceRevision,
        recipeRevision = options.recipeRevision,
        acquisitionRevision = options.acquisitionRevision
            or addonTable.recipeAcquisitionDataRevision,
    })
    result.plan = plan

    if not plan or not plan.complete then
        result.routeComplete = false
        result.routeReason = plan and plan.reason or "shopping_plan_incomplete"
        result.plan = nil
    end

    return result
end
