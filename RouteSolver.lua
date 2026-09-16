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

local recipeMaskHas

local function copyState(baseState, acquired, recipeMask, codec, candidateRecipeID)
    local result = {}
    if type(baseState) == "table" then
        for key, value in pairs(baseState) do
            result[key] = value
        end
    end

    local candidateKey = candidateRecipeID ~= nil
        and ("recipe:" .. tostring(candidateRecipeID))
        or nil
    local candidateBit = candidateRecipeID ~= nil
        and codec.indexByRecipeID[tostring(candidateRecipeID)]
        or nil

    if candidateKey and candidateBit and recipeMaskHas(recipeMask, candidateBit) then
        local acquiredView = copyMap(acquired)
        acquiredView[candidateKey] = true
        result.acquiredOneTime = acquiredView
    else
        result.acquiredOneTime = acquired
    end

    result.routeAcquiredRecipeMask = recipeMask
    result.routeRecipeAcquisitionCodec = codec
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

local acquiredKeyCache = setmetatable({}, { __mode = "k" })

local function acquiredKey(set)
    if type(set) ~= "table" then
        return ""
    end

    local cached = acquiredKeyCache[set]
    if cached ~= nil then
        return cached
    end

    local key = table.concat(sortedKeys(set), "\31")
    acquiredKeyCache[set] = key
    return key
end

local function getRecipeID(recipe, index)
    return recipe.spellID or recipe.recipeID or recipe.id or index
end

recipeMaskHas = function(mask, bitIndex)
    if type(mask) ~= "string" or not bitIndex then
        return false
    end

    local byteIndex = math.floor((bitIndex - 1) / 8) + 1
    local bitValue = 2 ^ ((bitIndex - 1) % 8)
    local value = string.byte(mask, byteIndex) or 0
    return value % (bitValue * 2) >= bitValue
end

local function recipeMaskSet(mask, bitIndex)
    if not bitIndex or recipeMaskHas(mask, bitIndex) then
        return mask
    end

    local byteIndex = math.floor((bitIndex - 1) / 8) + 1
    local bitValue = 2 ^ ((bitIndex - 1) % 8)
    local value = (string.byte(mask, byteIndex) or 0) + bitValue
    return string.sub(mask, 1, byteIndex - 1)
        .. string.char(value)
        .. string.sub(mask, byteIndex + 1)
end

local function recipeMaskIntersect(left, right)
    if type(left) ~= "string" or type(right) ~= "string" then
        return left or ""
    end

    local count = math.min(string.len(left), string.len(right))
    local bytes = {}
    for index = 1, count do
        local a = string.byte(left, index) or 0
        local b = string.byte(right, index) or 0
        local value = 0
        local bitValue = 1
        for _ = 1, 8 do
            if a % (bitValue * 2) >= bitValue
                and b % (bitValue * 2) >= bitValue
            then
                value = value + bitValue
            end
            bitValue = bitValue * 2
        end
        bytes[index] = string.char(value)
    end
    return table.concat(bytes)
end

local function recipeIDKey(recipe, index)
    return tostring(getRecipeID(recipe, index))
end

local function buildRecipeAcquisitionCodec(recipes, state, options, startSkill, targetSkill)
    local candidateBySkill = options and options.candidateRecipesBySkill
    local indexByRecipeID = {}
    local recipeCount = 0

    local function addRecipe(recipe, index)
        local recipeID = getRecipeID(recipe, index)
        local key = tostring(recipeID)
        if indexByRecipeID[key] == nil then
            recipeCount = recipeCount + 1
            indexByRecipeID[key] = recipeCount
        end
    end

    if type(candidateBySkill) == "table" then
        for skill = startSkill, math.max(startSkill, targetSkill - 1) do
            local candidates = candidateBySkill[skill] or {}
            for index = 1, table.getn(candidates) do
                addRecipe(candidates[index], index)
            end
        end
    else
        for index = 1, table.getn(recipes or {}) do
            addRecipe(recipes[index], index)
        end
    end

    local byteCount = math.ceil(recipeCount / 8)
    local emptyMask = string.rep(string.char(0), byteCount)
    local futureMaskBySkill = {}

    if byteCount > 0 then
        local bytes = {}
        for index = 1, byteCount do
            bytes[index] = 0
        end

        local function addFutureRecipe(recipe, index)
            local bitIndex = indexByRecipeID[recipeIDKey(recipe, index)]
            if not bitIndex then
                return
            end
            local byteIndex = math.floor((bitIndex - 1) / 8) + 1
            local bitValue = 2 ^ ((bitIndex - 1) % 8)
            if bytes[byteIndex] % (bitValue * 2) < bitValue then
                bytes[byteIndex] = bytes[byteIndex] + bitValue
            end
        end

        local function snapshotBytes()
            local chars = {}
            for index = 1, byteCount do
                chars[index] = string.char(bytes[index])
            end
            return table.concat(chars)
        end

        for skill = targetSkill - 1, startSkill, -1 do
            local candidates = type(candidateBySkill) == "table"
                and (candidateBySkill[skill] or {})
                or recipes
            for index = 1, table.getn(candidates or {}) do
                addFutureRecipe(candidates[index], index)
            end
            futureMaskBySkill[skill] = snapshotBytes()
        end
        futureMaskBySkill[targetSkill] = emptyMask
    end

    return {
        indexByRecipeID = indexByRecipeID,
        recipeCount = recipeCount,
        byteCount = byteCount,
        emptyMask = emptyMask,
        futureMaskBySkill = futureMaskBySkill,
    }
end

local function initialRecipeMask(codec, state)
    local mask = codec.emptyMask
    if codec.byteCount == 0 or type(state.acquiredOneTime) ~= "table" then
        return mask
    end

    for key, value in pairs(state.acquiredOneTime) do
        if value and type(key) == "string" then
            local recipeID = string.match(key, "^recipe:(.+)$")
            local bitIndex = recipeID and codec.indexByRecipeID[recipeID] or nil
            if bitIndex then
                mask = recipeMaskSet(mask, bitIndex)
            end
        end
    end
    return mask
end

local function normalizeRecipeMask(codec, mask, skill)
    local futureMask = codec.futureMaskBySkill[skill]
    if futureMask then
        return recipeMaskIntersect(mask, futureMask)
    end
    return mask
end

local function routeStateKey(skill, trainedCap, acquired, recipeMask)
    return table.concat({
        tostring(skill),
        tostring(trainedCap),
        acquiredKey(acquired),
        recipeMask or "",
    }, ":")
end

local function nodeKey(skill, trainedCap, acquired, recipeMask, lastRecipeID)
    return routeStateKey(skill, trainedCap, acquired, recipeMask)
        .. ":" .. tostring(lastRecipeID or "")
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

local function applyCostOneTime(acquired, recipeMask, codec, cost, metric)
    local nextAcquired = copyMap(acquired)
    local nextRecipeMask = recipeMask
    local extraCost = 0
    local extraMarketCost = 0
    local extraGoldCost = 0
    local acquiredNow = {}

    for i = 1, table.getn(cost.oneTimeCosts or {}) do
        local oneTime = cost.oneTimeCosts[i]
        local key = oneTime.key and tostring(oneTime.key) or nil
        local recipeID = oneTime.kind == "recipe_acquisition"
            and key
            and string.match(key, "^recipe:(.+)$")
            or nil
        local recipeBit = recipeID and codec.indexByRecipeID[recipeID] or nil
        local alreadyAcquired = recipeBit
            and recipeMaskHas(nextRecipeMask, recipeBit)
            or (key and nextAcquired[key] == true)

        if key and not alreadyAcquired then
            table.insert(acquiredNow, oneTime)

            if oneTime.kind == "recipe_acquisition" then
                extraCost = extraCost + oneTimeMetricCost(oneTime, metric)
                extraMarketCost = extraMarketCost + numberOrZero(
                    oneTime.marketCost ~= nil and oneTime.marketCost or oneTime.goldCost
                )
                extraGoldCost = extraGoldCost + numberOrZero(oneTime.goldCost)

                if recipeBit then
                    nextRecipeMask = recipeMaskSet(nextRecipeMask, recipeBit)
                end
            else
                -- Reusable/tool one-time costs are already included by RecipeCost.
                -- The solver only persists their acquired state here.
                nextAcquired[key] = true
            end
        end
    end

    return nextAcquired, nextRecipeMask, extraCost, extraMarketCost, extraGoldCost, acquiredNow
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

local function getCandidateRecipes(recipes, options, skill)
    local indexed = options and options.candidateRecipesBySkill
    if type(indexed) == "table" then
        return indexed[skill] or {}
    end
    return recipes
end

local DEFAULT_ROUTE_SLICE_BUDGET_MS = 3

addonTable.routeSolverSettings = addonTable.routeSolverSettings or {
    sliceBudgetMs = DEFAULT_ROUTE_SLICE_BUDGET_MS,
}

local function routeNowMilliseconds(clock)
    if type(clock) == "function" then
        local value = tonumber(clock())
        return value or 0
    end

    if type(debugprofilestop) == "function" then
        local ok, value = pcall(debugprofilestop)
        if ok and tonumber(value) then
            return tonumber(value)
        end
    end

    if type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        if ok and tonumber(value) then
            return tonumber(value) * 1000
        end
    end

    if os and type(os.clock) == "function" then
        return os.clock() * 1000
    end

    return 0
end

local function routeMemoryKilobytes()
    if type(collectgarbage) ~= "function" then
        return nil
    end
    local ok, value = pcall(collectgarbage, "count")
    if ok and tonumber(value) then
        return tonumber(value)
    end
    return nil
end

local function mapValues(map)
    local values = {}
    for _, value in pairs(map or {}) do
        table.insert(values, value)
    end
    return values
end

local function newRouteResult(startSkill, targetSkill, metric)
    return {
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
end

local function releaseRouteJobState(job)
    job.recipes = nil
    job.skillContext = nil
    job.state = nil
    job.options = nil
    job.costRecipe = nil
    job.current = nil
    job.currentEntries = nil
    job.readyStates = nil
    job.readyEntries = nil
    job.groups = nil
    job.groupEntries = nil
    job.nextStates = nil
    job.candidates = nil
    job.candidateByID = nil
    job.trainingSteps = nil
    job.recipeCodec = nil
    job.isCurrent = nil
end

local function finishRouteJobMetrics(job)
    if job.recipeCodec then
        job.recipeAcquisitionBits = tonumber(job.recipeCodec.recipeCount) or 0
        job.recipeAcquisitionBytes = tonumber(job.recipeCodec.byteCount) or 0
    end
    if job.finishedAtMs == nil then
        job.finishedAtMs = routeNowMilliseconds()
    end
    if job.memoryAfterKb == nil then
        job.memoryAfterKb = routeMemoryKilobytes()
    end
    if job.memoryBeforeKb and job.memoryAfterKb then
        job.memoryDeltaKb = job.memoryAfterKb - job.memoryBeforeKb
    end
    if job.startedAtMs and job.finishedAtMs then
        job.elapsedMs = math.max(0, job.finishedAtMs - job.startedAtMs)
    end
end

local function jobRelax(job, target, node, countField)
    local key = nodeKey(
        node.skill,
        node.trainedCap,
        node.acquired,
        node.recipeMask,
        node.lastRecipeID
    )
    local existing = target[key]
    if existing and existing.totalCost <= node.totalCost then
        return true
    end

    if not existing then
        local count = tonumber(job[countField]) or 0
        if count >= job.maxStates then
            job.result.reason = "state_limit_exceeded"
            addMissingReason(job.missing, "state_limit_exceeded")
            job.phase = "finalize"
            return false
        end
        count = count + 1
        job[countField] = count
        if count > (tonumber(job.peakLayerStates) or 0) then
            job.peakLayerStates = count
        end
    end

    target[key] = node
    return true
end

local function jobAdvanceTraining(job, node)
    local cursor = node
    while cursor.skill >= cursor.trainedCap and cursor.skill < job.targetSkill do
        local chosen
        local chosenMetric
        local chosenMarket
        local chosenGold
        local chosenKey
        local chosenCap

        for trainingIndex = 1, table.getn(job.trainingSteps) do
            local action = job.trainingSteps[trainingIndex]
            if trainingAvailable(action, cursor.skill, cursor.trainedCap) then
                local keyName = tostring(
                    action.key or ("training:" .. tostring(action.newCap or action.targetCap))
                )
                if not cursor.acquired[keyName] then
                    local newCap = tonumber(action.newCap or action.targetCap)
                    local trainingMetric, trainingMarket, trainingGold = getTrainingCost(
                        action,
                        job.metric
                    )
                    if newCap and trainingMetric ~= nil
                        and (not chosenCap
                            or newCap < chosenCap
                            or (newCap == chosenCap and trainingMetric < chosenMetric))
                    then
                        chosen = action
                        chosenMetric = trainingMetric
                        chosenMarket = trainingMarket
                        chosenGold = trainingGold
                        chosenKey = keyName
                        chosenCap = newCap
                    end
                end
            end
        end

        if not chosen then
            addMissingReason(job.missing, "training_metadata_missing")
            return nil
        end

        local nextAcquired = copyMap(cursor.acquired)
        nextAcquired[chosenKey] = true
        cursor = {
            skill = cursor.skill,
            trainedCap = chosenCap,
            acquired = nextAcquired,
            recipeMask = cursor.recipeMask,
            totalCost = cursor.totalCost + chosenMetric,
            totalMarketCost = cursor.totalMarketCost + chosenMarket,
            totalGoldCost = cursor.totalGoldCost + chosenGold,
            totalCurrentPurchaseCost = cursor.totalCurrentPurchaseCost + chosenGold,
            previous = cursor,
            quality = cursor.quality,
            lastRecipeID = cursor.lastRecipeID,
            transition = {
                type = "training",
                training = chosen,
                skillFrom = cursor.skill,
                skillTo = cursor.skill,
                oldCap = cursor.trainedCap,
                newCap = chosenCap,
                marketCost = chosenMarket,
                goldCost = chosenGold,
                currentPurchaseCost = chosenGold,
                quality = "complete",
            },
        }
    end
    return cursor
end

local function jobEvaluateCraft(job, node, recipe, recipeIndex)
    local recipeID = getRecipeID(recipe, recipeIndex)
    local routeState = copyState(
        job.state,
        node.acquired,
        node.recipeMask,
        job.recipeCodec,
        recipeID
    )
    routeState.routeActiveRecipeID = node.lastRecipeID
    local cost = job.costRecipe(
        recipe,
        node.skill,
        job.skillContext,
        routeState,
        job.options.costOptions or {}
    )

    if not (cost and cost.available and cost.useful and cost.expectedCraftsPerSkillUp) then
        if cost and cost.incomplete then
            addMissingReason(job.missing, cost.unavailableReason or "incomplete_recipe_cost")
        end
        return
    end

    local metricCost = resolveMetricCost(cost, job.metric)
    if metricCost == nil then
        return
    end

    local nextAcquired, nextRecipeMask, extraMetric, extraMarket, extraGold, acquiredNow = applyCostOneTime(
        node.acquired,
        node.recipeMask,
        job.recipeCodec,
        cost,
        job.metric
    )
    nextAcquired = applyProducedKeys(nextAcquired, recipe)

    local edgeMarket = numberOrZero(cost.expectedMarketCostPerSkillUp) + extraMarket
    local edgeGold = numberOrZero(cost.expectedGoldNeededNowPerSkillUp) + extraGold
    local edgeCurrent = numberOrZero(
        cost.expectedCurrentPurchaseCostPerSkillUp
            or cost.expectedMarketCostPerSkillUp
    ) + extraGold
    local edgeMetric = numberOrZero(metricCost) + extraMetric
    local nextSkill = math.min(job.targetSkill, node.skill + 1)
    nextRecipeMask = normalizeRecipeMask(job.recipeCodec, nextRecipeMask, nextSkill)

    local acquisitionGoldCost = 0
    for acquiredIndex = 1, table.getn(acquiredNow) do
        if acquiredNow[acquiredIndex].kind == "recipe_acquisition" then
            acquisitionGoldCost = acquisitionGoldCost
                + numberOrZero(acquiredNow[acquiredIndex].goldCost)
        end
    end

    jobRelax(job, job.nextStates, {
        skill = nextSkill,
        trainedCap = node.trainedCap,
        acquired = nextAcquired,
        recipeMask = nextRecipeMask,
        totalCost = node.totalCost + edgeMetric,
        totalMarketCost = node.totalMarketCost + edgeMarket,
        totalGoldCost = node.totalGoldCost + edgeGold,
        totalCurrentPurchaseCost = node.totalCurrentPurchaseCost + edgeCurrent,
        previous = node,
        quality = (node.quality == "stale" or cost.quality == "stale")
            and "stale"
            or "complete",
        lastRecipeID = recipeID,
        transition = {
            type = "craft",
            recipe = recipe,
            recipeID = recipeID,
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
    }, "nextCount")
end

local function beginRouteLayer(job)
    if job.skill >= job.targetSkill or next(job.current or {}) == nil then
        job.phase = "finalize"
        return
    end

    job.currentEntries = mapValues(job.current)
    job.currentCursor = 1
    job.readyStates = {}
    job.readyCount = 0
    job.phase = "prepare_ready"
end

local function finalizeLayeredRouteJob(job)
    local result = job.result
    for reason in pairs(job.missing) do
        table.insert(result.missingData, reason)
    end
    table.sort(result.missingData)

    local finalNode
    for _, node in pairs(job.current or {}) do
        if node.skill >= job.targetSkill
            and (not finalNode or node.totalCost < finalNode.totalCost)
        then
            finalNode = node
        end
    end

    if not finalNode then
        result.reason = result.reason or "no_complete_route"
    else
        result.actions = reconstruct(finalNode)
        result.segments = buildSegments(result.actions)
        result.totalMarketCost = finalNode.totalMarketCost
        result.totalGoldCost = finalNode.totalGoldCost
        result.totalCurrentPurchaseCost = finalNode.totalCurrentPurchaseCost
        result.quality = finalNode.quality
        result.complete = true
        result.fallbackToStaticGuide = false

        for actionIndex = 1, table.getn(result.actions) do
            if result.actions[actionIndex].type == "craft" then
                result.totalExpectedCrafts = result.totalExpectedCrafts
                    + numberOrZero(result.actions[actionIndex].expectedCrafts)
            end
        end
    end

    job.status = "completed"
    job.phase = "done"
    finishRouteJobMetrics(job)
    releaseRouteJobState(job)
end

local function routeJobStillCurrent(job)
    if type(job.isCurrent) ~= "function" then
        return true
    end
    local ok, current = pcall(job.isCurrent, job.generationToken)
    return ok and current and true or false
end

local function performRouteJobOperation(job)
    if job.status ~= "running" then
        return
    end

    if job.phase == "prepare_ready" then
        local node = job.currentEntries[job.currentCursor]
        if not node then
            job.readyEntries = mapValues(job.readyStates)
            job.readyCursor = 1
            job.groups = {}
            job.phase = "group_ready"
            return
        end

        local ready = jobAdvanceTraining(job, node)
        if ready and ready.skill == job.skill and ready.skill < ready.trainedCap then
            jobRelax(job, job.readyStates, ready, "readyCount")
        end
        job.currentCursor = job.currentCursor + 1
        return
    end

    if job.phase == "group_ready" then
        local node = job.readyEntries[job.readyCursor]
        if not node then
            job.groupEntries = mapValues(job.groups)
            job.groupCursor = 1
            job.groupNodeCursor = 1
            job.candidateCursor = 1
            job.nextStates = {}
            job.nextCount = 0
            job.candidates = getCandidateRecipes(job.recipes, job.options, job.skill)
            job.candidateByID = {}
            for recipeIndex = 1, table.getn(job.candidates) do
                local recipe = job.candidates[recipeIndex]
                job.candidateByID[tostring(getRecipeID(recipe, recipeIndex))] = {
                    recipe = recipe,
                    index = recipeIndex,
                }
            end
            job.phase = "expand_groups"
            return
        end

        job.result.exploredStates = job.result.exploredStates + 1
        if job.result.exploredStates > job.maxStates then
            job.result.reason = "state_limit_exceeded"
            addMissingReason(job.missing, "state_limit_exceeded")
            job.phase = "finalize"
            return
        end

        local groupKey = routeStateKey(
            node.skill,
            node.trainedCap,
            node.acquired,
            node.recipeMask
        )
        local group = job.groups[groupKey]
        if not group then
            group = { nodes = {}, bestSwitchNode = node }
            job.groups[groupKey] = group
        elseif node.totalCost < group.bestSwitchNode.totalCost then
            group.bestSwitchNode = node
        end
        table.insert(group.nodes, node)
        job.readyCursor = job.readyCursor + 1
        return
    end

    if job.phase == "expand_groups" then
        local group = job.groupEntries[job.groupCursor]
        if not group then
            job.current = job.nextStates
            job.currentCount = job.nextCount or 0
            job.skill = job.skill + 1
            job.currentEntries = nil
            job.readyStates = nil
            job.readyEntries = nil
            job.groups = nil
            job.groupEntries = nil
            job.nextStates = nil
            job.candidates = nil
            job.candidateByID = nil
            beginRouteLayer(job)
            return
        end

        local node = group.nodes[job.groupNodeCursor]
        if not node then
            job.groupCursor = job.groupCursor + 1
            job.groupNodeCursor = 1
            job.candidateCursor = 1
            return
        end

        if node == group.bestSwitchNode then
            local recipe = job.candidates[job.candidateCursor]
            if recipe then
                jobEvaluateCraft(job, node, recipe, job.candidateCursor)
                job.candidateCursor = job.candidateCursor + 1
            else
                job.groupNodeCursor = job.groupNodeCursor + 1
                job.candidateCursor = 1
            end
            return
        end

        if node.lastRecipeID ~= nil then
            local continuing = job.candidateByID[tostring(node.lastRecipeID)]
            if continuing then
                jobEvaluateCraft(job, node, continuing.recipe, continuing.index)
            end
        end
        job.groupNodeCursor = job.groupNodeCursor + 1
        job.candidateCursor = 1
        return
    end

    if job.phase == "finalize" then
        finalizeLayeredRouteJob(job)
        return
    end

    error("Unknown route job phase: " .. tostring(job.phase))
end

local function createLayeredRouteJob(
    recipes,
    skillContext,
    state,
    options,
    result,
    startSkill,
    targetSkill,
    startingCap,
    metric,
    maxStates,
    costRecipe
)
    local initialAcquired = copyMap(state.acquiredOneTime or state.acquiredReusable)
    for key in pairs(initialAcquired) do
        if type(key) == "string" and string.match(key, "^recipe:") then
            initialAcquired[key] = nil
        end
    end

    local recipeCodec = buildRecipeAcquisitionCodec(
        recipes,
        state,
        options,
        startSkill,
        targetSkill
    )
    local initialRecipeBits = initialRecipeMask(recipeCodec, state)
    initialRecipeBits = normalizeRecipeMask(recipeCodec, initialRecipeBits, startSkill)

    local startNode = {
        skill = startSkill,
        trainedCap = startingCap,
        acquired = initialAcquired,
        recipeMask = initialRecipeBits,
        totalCost = 0,
        totalMarketCost = 0,
        totalGoldCost = 0,
        totalCurrentPurchaseCost = 0,
        previous = nil,
        transition = nil,
        quality = "complete",
        lastRecipeID = nil,
    }
    local current = {}
    current[nodeKey(
        startSkill,
        startingCap,
        initialAcquired,
        initialRecipeBits,
        nil
    )] = startNode

    local job = {
        status = "running",
        phase = "prepare_ready",
        result = result,
        recipes = recipes,
        skillContext = skillContext,
        state = state,
        options = options,
        startSkill = startSkill,
        targetSkill = targetSkill,
        startingCap = startingCap,
        metric = metric,
        maxStates = maxStates,
        costRecipe = costRecipe,
        recipeCodec = recipeCodec,
        current = current,
        currentCount = 1,
        peakLayerStates = 1,
        skill = startSkill,
        missing = {},
        trainingSteps = options.trainingSteps or state.trainingSteps or {},
        generationToken = options.generationToken,
        isCurrent = options.isJobCurrent,
        sliceBudgetMs = tonumber(options.sliceBudgetMs)
            or tonumber(addonTable.routeSolverSettings.sliceBudgetMs)
            or DEFAULT_ROUTE_SLICE_BUDGET_MS,
        sliceCount = 0,
        largestSliceMs = 0,
        totalWorkMs = 0,
        operationCount = 0,
        memoryBeforeKb = routeMemoryKilobytes(),
        startedAtMs = routeNowMilliseconds(),
    }

    if targetSkill <= startSkill then
        result.complete = true
        result.fallbackToStaticGuide = false
        result.totalMarketCost = 0
        result.totalGoldCost = 0
        result.totalCurrentPurchaseCost = 0
        result.quality = "complete"
        job.status = "completed"
        job.phase = "done"
        finishRouteJobMetrics(job)
        releaseRouteJobState(job)
        return job
    end

    if type(costRecipe) ~= "function" then
        result.reason = "cost_engine_unavailable"
        job.status = "completed"
        job.phase = "done"
        finishRouteJobMetrics(job)
        releaseRouteJobState(job)
        return job
    end

    beginRouteLayer(job)
    return job
end

function addonTable.createCheapestProfessionRouteJob(recipes, skillContext, state, options)
    recipes = recipes or {}
    state = state or {}
    options = options or {}

    local startSkill = tonumber(
        options.startSkill or state.baseSkill or (skillContext and skillContext.baseSkill)
    ) or 0
    local targetSkill = tonumber(options.targetSkill or state.targetSkill or 450) or 450
    local startingCap = tonumber(
        state.currentCap or (skillContext and skillContext.currentCap) or targetSkill
    ) or targetSkill
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
    local result = newRouteResult(startSkill, targetSkill, metric)

    return createLayeredRouteJob(
        recipes,
        skillContext,
        state,
        options,
        result,
        startSkill,
        targetSkill,
        startingCap,
        metric,
        maxStates,
        costRecipe
    )
end

function addonTable.cancelCheapestProfessionRouteJob(job, reason)
    if type(job) ~= "table" or job.status ~= "running" then
        return false
    end

    job.status = "cancelled"
    job.cancelReason = tostring(reason or "cancelled")
    job.result.reason = job.cancelReason
    job.result.complete = false
    job.result.fallbackToStaticGuide = true
    job.phase = "done"
    finishRouteJobMetrics(job)
    releaseRouteJobState(job)
    return true
end

function addonTable.stepCheapestProfessionRouteJob(job, budgetMs, clock)
    if type(job) ~= "table" then
        return "invalid", nil
    end
    if job.status ~= "running" then
        return job.status, job.result
    end

    if not routeJobStillCurrent(job) then
        addonTable.cancelCheapestProfessionRouteJob(job, "stale_inputs")
        return job.status, job.result
    end

    local budget = tonumber(budgetMs) or tonumber(job.sliceBudgetMs)
        or DEFAULT_ROUTE_SLICE_BUDGET_MS
    if budget <= 0 then
        budget = DEFAULT_ROUTE_SLICE_BUDGET_MS
    end

    local startedAt = routeNowMilliseconds(clock)
    local operationsBefore = job.operationCount
    while job.status == "running" do
        performRouteJobOperation(job)
        job.operationCount = job.operationCount + 1

        if job.status ~= "running" then
            break
        end

        local elapsed = routeNowMilliseconds(clock) - startedAt
        if job.operationCount > operationsBefore and elapsed >= budget then
            break
        end
    end

    local elapsed = math.max(0, routeNowMilliseconds(clock) - startedAt)
    job.sliceCount = job.sliceCount + 1
    job.totalWorkMs = job.totalWorkMs + elapsed
    if elapsed > job.largestSliceMs then
        job.largestSliceMs = elapsed
    end

    if job.status == "running" and not routeJobStillCurrent(job) then
        addonTable.cancelCheapestProfessionRouteJob(job, "stale_inputs")
    end

    return job.status, job.result
end

function addonTable.runCheapestProfessionRouteJob(job)
    if type(job) ~= "table" then
        return nil
    end

    while job.status == "running" do
        if not routeJobStillCurrent(job) then
            addonTable.cancelCheapestProfessionRouteJob(job, "stale_inputs")
            break
        end
        performRouteJobOperation(job)
        job.operationCount = job.operationCount + 1
    end
    return job.result
end

function addonTable.getCheapestProfessionRouteJobMetrics(job)
    if type(job) ~= "table" then
        return nil
    end
    return {
        status = job.status,
        cancelReason = job.cancelReason,
        sliceCount = tonumber(job.sliceCount) or 0,
        largestSliceMs = tonumber(job.largestSliceMs) or 0,
        totalWorkMs = tonumber(job.totalWorkMs) or 0,
        elapsedMs = tonumber(job.elapsedMs) or 0,
        operationCount = tonumber(job.operationCount) or 0,
        exploredStates = job.result and tonumber(job.result.exploredStates) or 0,
        peakLayerStates = tonumber(job.peakLayerStates) or 0,
        recipeAcquisitionBits = job.recipeCodec
            and tonumber(job.recipeCodec.recipeCount)
            or tonumber(job.recipeAcquisitionBits)
            or 0,
        recipeAcquisitionBytes = job.recipeCodec
            and tonumber(job.recipeCodec.byteCount)
            or tonumber(job.recipeAcquisitionBytes)
            or 0,
        memoryBeforeKb = job.memoryBeforeKb,
        memoryAfterKb = job.memoryAfterKb,
        memoryDeltaKb = job.memoryDeltaKb,
        generationToken = job.generationToken,
        released = job.current == nil
            and job.recipes == nil
            and job.options == nil,
    }
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

    local result = newRouteResult(startSkill, targetSkill, metric)

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

    if options.layeredDynamicProgramming == true then
        local job = createLayeredRouteJob(
            recipes,
            skillContext,
            state,
            options,
            result,
            startSkill,
            targetSkill,
            startingCap,
            metric,
            maxStates,
            costRecipe
        )
        return addonTable.runCheapestProfessionRouteJob(job)
    end

    local initialAcquired = copyMap(state.acquiredOneTime or state.acquiredReusable)
    for key in pairs(initialAcquired) do
        if type(key) == "string" and string.match(key, "^recipe:") then
            initialAcquired[key] = nil
        end
    end
    local recipeCodec = buildRecipeAcquisitionCodec(
        recipes,
        state,
        options,
        startSkill,
        targetSkill
    )
    local initialRecipeBits = initialRecipeMask(recipeCodec, state)
    initialRecipeBits = normalizeRecipeMask(recipeCodec, initialRecipeBits, startSkill)

    local heap = {}
    local best = {}
    local bestEntries = 1
    local stateLimitReached = false
    local startNode = {
        skill = startSkill,
        trainedCap = startingCap,
        acquired = initialAcquired,
        recipeMask = initialRecipeBits,
        totalCost = 0,
        totalMarketCost = 0,
        totalGoldCost = 0,
        totalCurrentPurchaseCost = 0,
        previous = nil,
        transition = nil,
        quality = "complete",
        lastRecipeID = nil,
    }
    local startKey = nodeKey(
        startSkill,
        startingCap,
        initialAcquired,
        initialRecipeBits,
        nil
    )
    best[startKey] = startNode
    heapPush(heap, startNode)

    local finalNode
    local missing = {}
    local craftExpansionGroups = {}
    local pruneDominatedRecipeSwitches = options.pruneDominatedRecipeSwitches == true

    while table.getn(heap) > 0 and not stateLimitReached do
        local node = heapPop(heap)
        local key = nodeKey(
            node.skill,
            node.trainedCap,
            node.acquired,
            node.recipeMask,
            node.lastRecipeID
        )
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
                local expandAllCandidates = true
                if pruneDominatedRecipeSwitches then
                    local craftGroupKey = routeStateKey(
                        node.skill,
                        node.trainedCap,
                        node.acquired,
                        node.recipeMask
                    )
                    expandAllCandidates = craftExpansionGroups[craftGroupKey] ~= true
                    if expandAllCandidates then
                        craftExpansionGroups[craftGroupKey] = true
                    end
                end

                local candidateRecipes = getCandidateRecipes(recipes, options, node.skill)
                for recipeIndex = 1, table.getn(candidateRecipes) do
                    local recipe = candidateRecipes[recipeIndex]
                    local recipeID = getRecipeID(recipe, recipeIndex)
                    local evaluateCandidate = expandAllCandidates
                        or (node.lastRecipeID ~= nil
                            and tostring(recipeID) == tostring(node.lastRecipeID))

                    if evaluateCandidate then
                        local routeState = copyState(
                            state,
                            node.acquired,
                            node.recipeMask,
                            recipeCodec,
                            recipeID
                        )
                        routeState.routeActiveRecipeID = node.lastRecipeID
                        local cost = costRecipe(recipe, node.skill, skillContext, routeState, options.costOptions or {})

                        if cost and cost.available and cost.useful and cost.expectedCraftsPerSkillUp then
                            local metricCost = resolveMetricCost(cost, metric)
                            if metricCost ~= nil then
                                local nextAcquired, nextRecipeMask, extraMetric, extraMarket, extraGold, acquiredNow = applyCostOneTime(
                                    node.acquired,
                                    node.recipeMask,
                                    recipeCodec,
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
                                nextRecipeMask = normalizeRecipeMask(
                                    recipeCodec,
                                    nextRecipeMask,
                                    nextSkill
                                )
                                local totalCost = node.totalCost + edgeMetric
                                local nextKey = nodeKey(
                                    nextSkill,
                                    node.trainedCap,
                                    nextAcquired,
                                    nextRecipeMask,
                                    recipeID
                                )
                                local existing = best[nextKey]

                                if not existing and bestEntries >= maxStates then
                                    result.reason = "state_limit_exceeded"
                                    addMissingReason(missing, "state_limit_exceeded")
                                    stateLimitReached = true
                                    break
                                end

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
                                        recipeMask = nextRecipeMask,
                                        totalCost = totalCost,
                                        totalMarketCost = node.totalMarketCost + edgeMarket,
                                        totalGoldCost = node.totalGoldCost + edgeGold,
                                        totalCurrentPurchaseCost = node.totalCurrentPurchaseCost + edgeCurrent,
                                        previous = node,
                                        quality = (node.quality == "stale" or cost.quality == "stale") and "stale" or "complete",
                                        lastRecipeID = recipeID,
                                        transition = {
                                            type = "craft",
                                            recipe = recipe,
                                            recipeID = recipeID,
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
                                    if not existing then
                                        bestEntries = bestEntries + 1
                                    end
                                    best[nextKey] = nextNode
                                    heapPush(heap, nextNode)
                                end
                            end
                        elseif cost and cost.incomplete then
                            addMissingReason(missing, cost.unavailableReason or "incomplete_recipe_cost")
                        end
                    end
                end
            end

            if not stateLimitReached
                and node.skill >= node.trainedCap
                and node.skill < targetSkill
            then
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
                                local nextKey = nodeKey(
                                    node.skill,
                                    newCap,
                                    nextAcquired,
                                    node.recipeMask,
                                    node.lastRecipeID
                                )
                                local existing = best[nextKey]

                                if not existing and bestEntries >= maxStates then
                                    result.reason = "state_limit_exceeded"
                                    addMissingReason(missing, "state_limit_exceeded")
                                    stateLimitReached = true
                                    break
                                end

                                if not existing or totalCost < existing.totalCost then
                                    local nextNode = {
                                        skill = node.skill,
                                        trainedCap = newCap,
                                        acquired = nextAcquired,
                                        recipeMask = node.recipeMask,
                                        totalCost = totalCost,
                                        totalMarketCost = node.totalMarketCost + trainingMarket,
                                        totalGoldCost = node.totalGoldCost + trainingGold,
                                        totalCurrentPurchaseCost = node.totalCurrentPurchaseCost + trainingGold,
                                        previous = node,
                                        quality = node.quality,
                                        lastRecipeID = node.lastRecipeID,
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
                                    if not existing then
                                        bestEntries = bestEntries + 1
                                    end
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
