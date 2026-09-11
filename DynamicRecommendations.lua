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

function addonTable.getMaterialPriceInfo(item, neededQuantity, now)
    local quantity = math.max(0, tonumber(neededQuantity) or 0)
    if quantity <= 0 then
        return {
            available = true,
            neededQuantity = 0,
            estimatedRemainingCost = 0,
        }
    end

    if type(addonTable.lookupItemPrice) ~= "function"
        or type(addonTable.chooseUsableUnitPrice) ~= "function"
    then
        return {
            available = false,
            neededQuantity = quantity,
            reason = "price_provider_unavailable",
        }
    end

    local result = addonTable.lookupItemPrice(item, now)
    local choice, reason = addonTable.chooseUsableUnitPrice(result, "spend")
    if not choice then
        return {
            available = false,
            neededQuantity = quantity,
            reason = reason or (result and result.unavailableReason) or "price_unavailable",
            source = result and result.source,
            freshness = result and result.freshness,
            ageSeconds = result and result.ageSeconds,
        }
    end

    return {
        available = true,
        neededQuantity = quantity,
        unitPrice = choice.unitPrice,
        estimatedRemainingCost = quantity * choice.unitPrice,
        priceType = choice.priceType,
        source = choice.source,
        freshness = choice.freshness,
        ageSeconds = choice.ageSeconds,
        isStale = choice.isStale or choice.isTooOld,
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
    then
        result.reason = "optimizer_unavailable"
        return result
    end

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

    local route = addonTable.solveCheapestProfessionRoute(recipes, skillContext, state, {
        startSkill = skillContext.baseSkill,
        targetSkill = targetSkill,
        optimizeFor = options.optimizeFor or "market",
        maxStates = options.maxStates,
        costOptions = options.costOptions,
    })
    result.route = route

    if not route or not route.complete then
        result.reason = route and route.reason or "no_complete_route"
        return result
    end

    local plan = addonTable.buildProfessionShoppingPlan(route, state, {
        priceRevision = options.priceRevision,
        recipeRevision = options.recipeRevision,
        acquisitionRevision = options.acquisitionRevision
            or addonTable.recipeAcquisitionDataRevision,
    })
    result.plan = plan

    if not plan or not plan.complete then
        result.reason = plan and plan.reason or "shopping_plan_incomplete"
        return result
    end

    local segment = route.segments and route.segments[1] or nil
    if not segment or not segment.recipeID then
        result.reason = "no_current_segment"
        return result
    end

    result.currentSegment = segment
    result.available = true
    result.fallbackToStaticGuide = false
    result.reason = nil
    return result
end
