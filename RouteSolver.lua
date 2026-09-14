local addonName, addonTable = ...

local DEFAULT_MAX_STATES = 20000

local function copyMap(source)
    local result = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

local function copyState(baseState, acquired)
    local result = {}
    if type(baseState) == "table" then
        for key, value in pairs(baseState) do
            result[key] = value
        end
    end
    result.acquiredOneTime = acquired
    return result
end

local function sortedKeys(set)
    local keys = {}
    for key, value in pairs(set or {}) do
        if value then
            table.insert(keys, tostring(key))
        end
    end
    table.sort(keys)
    return keys
end

local function acquiredKey(set)
    return table.concat(sortedKeys(set), "\31")
end

local function nodeKey(skill, trainedCap, acquired)
    return tostring(skill) .. ":" .. tostring(trainedCap) .. ":" .. acquiredKey(acquired)
end

local function heapPush(heap, node)
    local index = table.getn(heap) + 1
    heap[index] = node

    while index > 1 do
        local parent = math.floor(index / 2)
        if heap[parent].totalCost <= node.totalCost then
            break
        end
        heap[index] = heap[parent]
        index = parent
    end
    heap[index] = node
end

local function heapPop(heap)
    local count = table.getn(heap)
    if count == 0 then
        return nil
    end

    local root = heap[1]
    local last = heap[count]
    heap[count] = nil
    count = count - 1

    if count > 0 then
        local index = 1
        while true do
            local left = index * 2
            if left > count then
                break
            end

            local right = left + 1
            local child = left
            if right <= count and heap[right].totalCost < heap[left].totalCost then
                child = right
            end

            if heap[child].totalCost >= last.totalCost then
                break
            end

            heap[index] = heap[child]
            index = child
        end
        heap[index] = last
    end

    return root
end

local function numberOrZero(value)
    return tonumber(value) or 0
end

local function getRecipeID(recipe, index)
    return recipe.spellID or recipe.recipeID or recipe.id or index
end

local function resolveMetricCost(cost, metric)
    if metric == "gold" then
        return cost.expectedGoldNeededNowPerSkillUp
    elseif metric == "current" then
        return cost.expectedCurrentPurchaseCostPerSkillUp
            or cost.expectedMarketCostPerSkillUp
    end
    return cost.expectedMarketCostPerSkillUp
end

local function oneTimeMetricCost(oneTime, metric)
    if metric == "gold" or metric == "current" then
        return numberOrZero(oneTime.goldCost)
    end
    return numberOrZero(oneTime.marketCost ~= nil and oneTime.marketCost or oneTime.goldCost)
end

local function applyCostOneTime(acquired, cost, metric)
    local nextAcquired = copyMap(acquired)
    local extraCost = 0
    local extraMarketCost = 0
    local extraGoldCost = 0
    local acquiredNow = {}

    for i = 1, table.getn(cost.oneTimeCosts or {}) do
        local oneTime = cost.oneTimeCosts[i]
        local key = oneTime.key and tostring(oneTime.key) or nil
        if key and not nextAcquired[key] then
            nextAcquired[key] = true
            table.insert(acquiredNow, oneTime)

            -- Reusable reagent/tool costs are already included by RecipeCost in the
            -- expected per-skill-up total. Recipe acquisition is exposed separately.
            if oneTime.kind == "recipe_acquisition" then
                extraCost = extraCost + oneTimeMetricCost(oneTime, metric)
                extraMarketCost = extraMarketCost + numberOrZero(
                    oneTime.marketCost ~= nil and oneTime.marketCost or oneTime.goldCost
                )
                extraGoldCost = extraGoldCost + numberOrZero(oneTime.goldCost)
            end
        end
    end

    return nextAcquired, extraCost, extraMarketCost, extraGoldCost, acquiredNow
end

local function applyProducedKeys(acquired, recipe)
    local nextAcquired = copyMap(acquired)
    local produced = recipe.producesReusableKeys
    if type(produced) == "table" then
        for key, value in pairs(produced) do
            if type(key) == "number" then
                nextAcquired[tostring(value)] = true
            elseif value then
                nextAcquired[tostring(key)] = true
            end
        end
    elseif recipe.producesReusableKey then
        nextAcquired[tostring(recipe.producesReusableKey)] = true
    end
    return nextAcquired
end

local function trainingAvailable(action, skill, trainedCap)
    if type(action) ~= "table" then
        return false
    end

    local atSkill = tonumber(action.atSkill or action.requiredSkill or 0) or 0
    local newCap = tonumber(action.newCap or action.targetCap)
    if not newCap or newCap <= trainedCap or skill < atSkill then
        return false
    end

    local status = action.status or action.state
    if action.available == false
        or status == "unavailable"
        or status == "unknown"
        or status == "reputation"
        or status == "drop"
        or status == "quest"
    then
        return false
    end

    return true
end

local function getTrainingCost(action, metric)
    local goldCost = tonumber(action.goldCost or action.purchasePrice)
    if goldCost == nil then
        if action.status == "learned" or action.alreadyLearned then
            goldCost = 0
        else
            return nil
        end
    end

    local marketCost = tonumber(action.marketCost)
    if marketCost == nil then
        marketCost = goldCost
    end

    if metric == "gold" then
        return goldCost, marketCost, goldCost
    end
    return marketCost, marketCost, goldCost
end

local function addMissingReason(missing, reason)
    if reason then
        missing[reason] = true
    end
end

local function reconstruct(finalNode)
    local actions = {}
    local cursor = finalNode
    while cursor and cursor.transition do
        table.insert(actions, 1, cursor.transition)
        cursor = cursor.previous
    end
    return actions
end

local function buildSegments(actions)
    local segments = {}
    local cumulativeMarket = 0
    local cumulativeGold = 0

    for i = 1, table.getn(actions) do
        local action = actions[i]
        cumulativeMarket = cumulativeMarket + numberOrZero(action.marketCost)
        cumulativeGold = cumulativeGold + numberOrZero(action.goldCost)

        if action.type == "craft" then
            local last = segments[table.getn(segments)]
            if last and last.recipeID == action.recipeID and last.skillEnd == action.skillFrom then
                last.skillEnd = action.skillTo
                last.expectedCrafts = last.expectedCrafts + numberOrZero(action.expectedCrafts)
                last.expectedMaterialCost = last.expectedMaterialCost + numberOrZero(action.marketCost)
                last.expectedGoldNeededNow = last.expectedGoldNeededNow + numberOrZero(action.goldCost)
                last.acquisitionCost = last.acquisitionCost + numberOrZero(action.acquisitionGoldCost)
                last.cumulativeMarketCost = cumulativeMarket
                last.cumulativeGoldCost = cumulativeGold
                if action.quality == "stale" then
                    last.quality = "stale"
                end
            else
                table.insert(segments, {
                    recipe = action.recipe,
                    recipeID = action.recipeID,
                    skillStart = action.skillFrom,
                    skillEnd = action.skillTo,
                    expectedCrafts = numberOrZero(action.expectedCrafts),
                    expectedMaterialCost = numberOrZero(action.marketCost),
                    expectedGoldNeededNow = numberOrZero(action.goldCost),
                    acquisitionCost = numberOrZero(action.acquisitionGoldCost),
                    cumulativeMarketCost = cumulativeMarket,
                    cumulativeGoldCost = cumulativeGold,
                    quality = action.quality,
                    firstCost = action.cost,
                    acquisition = action.cost and action.cost.acquisition or nil,
                    requiresAcquisition = action.cost
                        and action.cost.acquisition
                        and action.cost.acquisition.alreadyAcquired ~= true
                        or false,
                })
            end
        end
    end

    return segments
end

function addonTable.solveCheapestProfessionRoute(recipes, skillContext, state, options)
    recipes = recipes or {}
    state = state or {}
    options = options or {}

    local startSkill = tonumber(options.startSkill or state.baseSkill or (skillContext and skillContext.baseSkill)) or 0
    local targetSkill = tonumber(options.targetSkill or state.targetSkill or 450) or 450
    local startingCap = tonumber(state.currentCap or (skillContext and skillContext.currentCap) or targetSkill) or targetSkill
    local metric
    if options.optimizeFor == "gold" then
        metric = "gold"
    elseif options.optimizeFor == "current" then
        metric = "current"
    else
        metric = "market"
    end
    local maxStates = tonumber(options.maxStates) or DEFAULT_MAX_STATES
    local costRecipe = options.costRecipe or addonTable.calculateRecipeCost

    local result = {
        complete = false,
        fallbackToStaticGuide = true,
        startSkill = startSkill,
        targetSkill = targetSkill,
        optimizationMetric = metric,
        actions = {},
        segments = {},
        totalMarketCost = nil,
        totalGoldCost = nil,
        totalCurrentPurchaseCost = nil,
        totalExpectedCrafts = 0,
        quality = "incomplete",
        missingData = {},
        exploredStates = 0,
        reason = nil,
    }

    if targetSkill <= startSkill then
        result.complete = true
        result.fallbackToStaticGuide = false
        result.totalMarketCost = 0
        result.totalGoldCost = 0
        result.totalCurrentPurchaseCost = 0
        result.quality = "complete"
        return result
    end

    if type(costRecipe) ~= "function" then
        result.reason = "cost_engine_unavailable"
        return result
    end

    local initialAcquired = copyMap(state.acquiredOneTime or state.acquiredReusable)
    local heap = {}
    local best = {}
    local startNode = {
        skill = startSkill,
        trainedCap = startingCap,
        acquired = initialAcquired,
        totalCost = 0,
        totalMarketCost = 0,
        totalGoldCost = 0,
        totalCurrentPurchaseCost = 0,
        previous = nil,
        transition = nil,
        quality = "complete",
    }
    local startKey = nodeKey(startSkill, startingCap, initialAcquired)
    best[startKey] = startNode
    heapPush(heap, startNode)

    local finalNode
    local missing = {}

    while table.getn(heap) > 0 do
        local node = heapPop(heap)
        local key = nodeKey(node.skill, node.trainedCap, node.acquired)
        if best[key] == node then
            result.exploredStates = result.exploredStates + 1
            if result.exploredStates > maxStates then
                result.reason = "state_limit_exceeded"
                addMissingReason(missing, "state_limit_exceeded")
                break
            end

            if node.skill >= targetSkill then
                finalNode = node
                break
            end

            if node.skill < node.trainedCap then
                for recipeIndex = 1, table.getn(recipes) do
                    local recipe = recipes[recipeIndex]
                    local routeState = copyState(state, node.acquired)
                    local cost = costRecipe(recipe, node.skill, skillContext, routeState, options.costOptions or {})

                    if cost and cost.available and cost.useful and cost.expectedCraftsPerSkillUp then
                        local metricCost = resolveMetricCost(cost, metric)
                        if metricCost ~= nil then
                            local nextAcquired, extraMetric, extraMarket, extraGold, acquiredNow = applyCostOneTime(
                                node.acquired,
                                cost,
                                metric
                            )
                            nextAcquired = applyProducedKeys(nextAcquired, recipe)

                            local edgeMarket = numberOrZero(cost.expectedMarketCostPerSkillUp) + extraMarket
                            local edgeGold = numberOrZero(cost.expectedGoldNeededNowPerSkillUp) + extraGold
                            local edgeCurrent = numberOrZero(
                                cost.expectedCurrentPurchaseCostPerSkillUp
                                    or cost.expectedMarketCostPerSkillUp
                            ) + extraGold
                            local edgeMetric = numberOrZero(metricCost) + extraMetric
                            local nextSkill = math.min(targetSkill, node.skill + 1)
                            local totalCost = node.totalCost + edgeMetric
                            local nextKey = nodeKey(nextSkill, node.trainedCap, nextAcquired)
                            local existing = best[nextKey]

                            if not existing or totalCost < existing.totalCost then
                                local acquisitionGoldCost = 0
                                for acquiredIndex = 1, table.getn(acquiredNow) do
                                    if acquiredNow[acquiredIndex].kind == "recipe_acquisition" then
                                        acquisitionGoldCost = acquisitionGoldCost + numberOrZero(acquiredNow[acquiredIndex].goldCost)
                                    end
                                end

                                local nextNode = {
                                    skill = nextSkill,
                                    trainedCap = node.trainedCap,
                                    acquired = nextAcquired,
                                    totalCost = totalCost,
                                    totalMarketCost = node.totalMarketCost + edgeMarket,
                                    totalGoldCost = node.totalGoldCost + edgeGold,
                                    totalCurrentPurchaseCost = node.totalCurrentPurchaseCost + edgeCurrent,
                                    previous = node,
                                    quality = (node.quality == "stale" or cost.quality == "stale") and "stale" or "complete",
                                    transition = {
                                        type = "craft",
                                        recipe = recipe,
                                        recipeID = getRecipeID(recipe, recipeIndex),
                                        skillFrom = node.skill,
                                        skillTo = nextSkill,
                                        expectedCrafts = cost.expectedCraftsPerSkillUp,
                                        skillUpChance = cost.skillUpChance,
                                        marketCost = edgeMarket,
                                        goldCost = edgeGold,
                                        currentPurchaseCost = edgeCurrent,
                                        acquisitionGoldCost = acquisitionGoldCost,
                                        quality = cost.quality,
                                        cost = cost,
                                    },
                                }
                                best[nextKey] = nextNode
                                heapPush(heap, nextNode)
                            end
                        end
                    elseif cost and cost.incomplete then
                        addMissingReason(missing, cost.unavailableReason or "incomplete_recipe_cost")
                    end
                end
            end

            if node.skill >= node.trainedCap and node.skill < targetSkill then
                local trainingSteps = options.trainingSteps or state.trainingSteps or {}
                local foundTraining = false
                for trainingIndex = 1, table.getn(trainingSteps) do
                    local action = trainingSteps[trainingIndex]
                    if trainingAvailable(action, node.skill, node.trainedCap) then
                        local keyName = tostring(action.key or ("training:" .. tostring(action.newCap or action.targetCap)))
                        if not node.acquired[keyName] then
                            local trainingMetric, trainingMarket, trainingGold = getTrainingCost(action, metric)
                            if trainingMetric ~= nil then
                                foundTraining = true
                                local nextAcquired = copyMap(node.acquired)
                                nextAcquired[keyName] = true
                                local newCap = tonumber(action.newCap or action.targetCap)
                                local totalCost = node.totalCost + trainingMetric
                                local nextKey = nodeKey(node.skill, newCap, nextAcquired)
                                local existing = best[nextKey]

                                if not existing or totalCost < existing.totalCost then
                                    local nextNode = {
                                        skill = node.skill,
                                        trainedCap = newCap,
                                        acquired = nextAcquired,
                                        totalCost = totalCost,
                                        totalMarketCost = node.totalMarketCost + trainingMarket,
                                        totalGoldCost = node.totalGoldCost + trainingGold,
                                        totalCurrentPurchaseCost = node.totalCurrentPurchaseCost + trainingGold,
                                        previous = node,
                                        quality = node.quality,
                                        transition = {
                                            type = "training",
                                            training = action,
                                            skillFrom = node.skill,
                                            skillTo = node.skill,
                                            oldCap = node.trainedCap,
                                            newCap = newCap,
                                            marketCost = trainingMarket,
                                            goldCost = trainingGold,
                                            currentPurchaseCost = trainingGold,
                                            quality = "complete",
                                        },
                                    }
                                    best[nextKey] = nextNode
                                    heapPush(heap, nextNode)
                                end
                            else
                                addMissingReason(missing, "training_cost_missing")
                            end
                        end
                    end
                end

                if not foundTraining then
                    addMissingReason(missing, "training_metadata_missing")
                end
            end
        end
    end

    for reason in pairs(missing) do
        table.insert(result.missingData, reason)
    end
    table.sort(result.missingData)

    if not finalNode then
        result.reason = result.reason or "no_complete_route"
        return result
    end

    result.actions = reconstruct(finalNode)
    result.segments = buildSegments(result.actions)
    result.totalMarketCost = finalNode.totalMarketCost
    result.totalGoldCost = finalNode.totalGoldCost
    result.totalCurrentPurchaseCost = finalNode.totalCurrentPurchaseCost
    result.quality = finalNode.quality
    result.complete = true
    result.fallbackToStaticGuide = false

    for i = 1, table.getn(result.actions) do
        if result.actions[i].type == "craft" then
            result.totalExpectedCrafts = result.totalExpectedCrafts + numberOrZero(result.actions[i].expectedCrafts)
        end
    end

    return result
end
