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

local recommendationCache = {}
local recommendationCacheOrder = {}
local recommendationCacheHead = 1
local recommendationCacheTail = 0
local recommendationCacheEntries = 0
local recommendationCacheToken = 0
local RECOMMENDATION_CACHE_TTL = 15
local RECOMMENDATION_CACHE_MAX_ENTRIES = 8

local canonicalOptimizerRecipes = {}
local canonicalOptimizerRecipeCount = 0

local function measurePerformance(name, callback, ...)
    if type(addonTable.measurePerformance) == "function" then
        return addonTable.measurePerformance(name, callback, ...)
    end
    return callback(...)
end

local function performanceIncrement(name, amount)
    if type(addonTable.performanceIncrement) == "function" then
        addonTable.performanceIncrement(name, amount)
    end
end

local function performanceCache(name, hit)
    if type(addonTable.performanceCache) == "function" then
        addonTable.performanceCache(name, hit)
    end
end

local function performanceSet(name, value)
    if type(addonTable.performanceSet) == "function" then
        addonTable.performanceSet(name, value)
    end
end

local function runtimeNow()
    if type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        if ok and tonumber(value) then
            return tonumber(value)
        end
    end
    if os and type(os.clock) == "function" then
        return os.clock()
    end
    return 0
end

local function learnedRecipeSignature(recipeCache)
    local parts = {}
    for spellID, data in pairs(recipeCache or {}) do
        if type(spellID) == "number" and type(data) == "table" then
            table.insert(parts, tostring(spellID) .. ":" .. tostring(data.skillType or ""))
        end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

local function removeRecommendationCacheKey(key)
    if recommendationCache[key] ~= nil then
        recommendationCache[key] = nil
        recommendationCacheEntries = math.max(0, recommendationCacheEntries - 1)
    end
end

local function rebuildRecommendationCacheOrder()
    local compacted = {}
    local count = 0
    for key, current in pairs(recommendationCache) do
        count = count + 1
        compacted[count] = {
            key = key,
            token = current.token,
        }
    end
    recommendationCacheOrder = compacted
    recommendationCacheHead = 1
    recommendationCacheTail = count
end

local function storeRecommendationCache(key, entry)
    if recommendationCache[key] == nil then
        recommendationCacheEntries = recommendationCacheEntries + 1
    end
    recommendationCacheToken = recommendationCacheToken + 1
    entry.token = recommendationCacheToken
    recommendationCache[key] = entry
    recommendationCacheTail = recommendationCacheTail + 1
    recommendationCacheOrder[recommendationCacheTail] = {
        key = key,
        token = recommendationCacheToken,
    }

    while recommendationCacheEntries > RECOMMENDATION_CACHE_MAX_ENTRIES do
        local oldest = recommendationCacheOrder[recommendationCacheHead]
        recommendationCacheOrder[recommendationCacheHead] = nil
        recommendationCacheHead = recommendationCacheHead + 1
        if oldest then
            local current = recommendationCache[oldest.key]
            if current and current.token == oldest.token then
                removeRecommendationCacheKey(oldest.key)
            end
        end
    end

    if recommendationCacheTail - recommendationCacheHead + 1
        > RECOMMENDATION_CACHE_MAX_ENTRIES * 4
    then
        rebuildRecommendationCacheOrder()
    end
end

function addonTable.getDynamicRuntimeCacheStats()
    return {
        recommendationEntries = recommendationCacheEntries,
        maxRecommendationEntries = RECOMMENDATION_CACHE_MAX_ENTRIES,
        recommendationQueueEntries = math.max(
            0,
            recommendationCacheTail - recommendationCacheHead + 1
        ),
        maxRecommendationQueueEntries = RECOMMENDATION_CACHE_MAX_ENTRIES * 4,
        canonicalRecipeEntries = canonicalOptimizerRecipeCount,
    }
end

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
    if itemID and type(addonTable.getRuntimeInventoryCount) == "function" then
        return addonTable.getRuntimeInventoryCount(itemID, fallback)
    end

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

            if eligible then
                local recipe = {
                    spellID = spellID,
                    name = data.name,
                    profession = skillContext and skillContext.professionName,
                    liveSkillType = data.skillType,
                    reagents = {},
                    outputs = {},
                }

                if type(data.reagents) == "table" then
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


local function copyCatalogReagent(reagent)
    local itemID = tonumber(reagent and reagent.itemID)
    local reusable = itemID and REUSABLE_PROFESSION_TOOLS[itemID] and true or false
    local result = {
        itemID = itemID,
        item = itemID,
        name = reagent and reagent.name,
        quantity = tonumber(reagent and (reagent.count or reagent.quantity)) or 0,
        reusable = reusable,
    }
    if reusable then
        result.reusableKey = "item:" .. tostring(itemID)
    end
    return result
end

local function getOrBuildCanonicalOptimizerRecipe(record)
    local spellID = tonumber(record and record.spellID)
    if not spellID then
        return nil
    end

    local existing = canonicalOptimizerRecipes[spellID]
    if existing then
        performanceCache("canonical_recipe", true)
        return existing
    end

    performanceCache("canonical_recipe", false)
    local canonicalName = record.name
    if type(GetSpellInfo) == "function" then
        local ok, resolvedName = pcall(GetSpellInfo, spellID)
        if ok and type(resolvedName) == "string" and resolvedName ~= "" then
            canonicalName = resolvedName
        end
    end

    local recipe = {
        spellID = spellID,
        name = canonicalName or ("Spell " .. tostring(spellID)),
        profession = record.profession,
        requiredSkill = record.requiredSkill,
        outputItemID = record.outputItemID,
        outputQuantity = record.outputQuantity,
        recipeItemID = record.recipeItemID,
        liveSkillType = nil,
        learned = false,
        catalogRecord = record,
        reagents = {},
        outputs = {},
    }

    for reagentIndex = 1, table.getn(record.reagents or {}) do
        table.insert(recipe.reagents, copyCatalogReagent(record.reagents[reagentIndex]))
    end
    if record.outputItemID then
        table.insert(recipe.outputs, {
            itemID = record.outputItemID,
            item = record.outputItemID,
            quantity = tonumber(record.outputQuantity) or 1,
        })
    end

    canonicalOptimizerRecipes[spellID] = recipe
    canonicalOptimizerRecipeCount = canonicalOptimizerRecipeCount + 1
    return recipe
end

function addonTable.getCanonicalOptimizerRecipe(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil
    end
    local existing = canonicalOptimizerRecipes[spellID]
    if existing then
        return existing
    end
    if type(addonTable.getRecipeCatalogRecord) == "function" then
        local record = addonTable.getRecipeCatalogRecord(spellID)
        if record then
            return getOrBuildCanonicalOptimizerRecipe(record)
        end
    end
    return nil
end

local function spellName(spellID, fallback)
    if type(GetSpellInfo) == "function" then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return fallback or ("Spell " .. tostring(spellID))
end

local function addKnownSpell(state, spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 or state.learnedSpells[spellID] ~= nil then
        return
    end
    if type(IsSpellKnown) == "function" then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok then
            state.learnedSpells[spellID] = known and true or false
        end
    end
end

function addonTable.buildFullProfessionOptimizationInput(recipeCache, skillContext)
    local liveRecipes, state = addonTable.buildLiveProfessionOptimizationInput(recipeCache, skillContext)
    local liveBySpell = {}
    for index = 1, table.getn(liveRecipes) do
        liveBySpell[liveRecipes[index].spellID] = liveRecipes[index]
    end

    state.learnedSpells = {}
    state.reputation = {}

    local function lazyInventoryCount(itemID, fallback)
        itemID = parseItemID(itemID)
        if not itemID then
            return math.max(0, tonumber(fallback) or 0)
        end
        if state.inventory[itemID] == nil then
            state.inventory[itemID] = getOwnedCount(itemID, fallback)
        end
        return state.inventory[itemID]
    end

    state.getInventoryCount = lazyInventoryCount
    state.isSpellKnown = function(spellID)
        spellID = tonumber(spellID)
        if not spellID then return nil end
        if state.learnedSpells[spellID] ~= nil then
            return state.learnedSpells[spellID]
        end
        if type(IsSpellKnown) == "function" then
            local ok, known = pcall(IsSpellKnown, spellID)
            if ok then
                state.learnedSpells[spellID] = known and true or false
                return state.learnedSpells[spellID]
            end
        end
        return nil
    end
    state.getReputationStanding = function(factionID)
        factionID = tonumber(factionID)
        if not factionID then return nil end
        if state.reputation[factionID] ~= nil then
            return state.reputation[factionID]
        end
        if type(GetFactionInfoByID) == "function" then
            local ok, _, _, standingID = pcall(GetFactionInfoByID, factionID)
            if ok and tonumber(standingID) then
                state.reputation[factionID] = math.max(0, tonumber(standingID) - 1)
                return state.reputation[factionID]
            end
        end
        return nil
    end

    if type(UnitLevel) == "function" then
        local ok, level = pcall(UnitLevel, "player")
        if ok and tonumber(level) then
            state.playerLevel = tonumber(level)
        end
    end

    local profession = skillContext and skillContext.professionName
    if type(addonTable.getProfessionTrainingSteps) == "function" then
        state.trainingSteps, state.reachableCap = addonTable.getProfessionTrainingSteps(
            profession,
            state.currentCap,
            state.playerLevel
        )
    else
        state.trainingSteps = {}
        state.reachableCap = state.currentCap
    end

    local targetSkill = math.min(450, tonumber(state.reachableCap or state.currentCap) or 450)
    local relevantSpellIDs
    if type(addonTable.getGeneratedRouteCandidateSet) == "function" then
        relevantSpellIDs = addonTable.getGeneratedRouteCandidateSet(
            profession,
            state.baseSkill,
            targetSkill,
            skillContext and skillContext.activeSkillModifier or 0
        )
    end

    local catalog = {}
    if type(relevantSpellIDs) == "table"
        and type(addonTable.getRecipeCatalogRecord) == "function"
    then
        for spellID in pairs(relevantSpellIDs) do
            local record = addonTable.getRecipeCatalogRecord(spellID)
            if record then table.insert(catalog, record) end
        end
        table.sort(catalog, function(left, right)
            return tonumber(left.spellID or 0) < tonumber(right.spellID or 0)
        end)
    elseif type(addonTable.getRecipeCatalogRecipes) == "function" then
        catalog = addonTable.getRecipeCatalogRecipes(profession)
    end

    if table.getn(catalog) == 0 then
        state.fullCatalog = false
        return liveRecipes, state
    end

    local recipes = {}
    local seen = {}
    state.fullCatalog = true

    for index = 1, table.getn(catalog) do
        local record = catalog[index]
        local eligible = true
        if type(addonTable.isRecipeEligibleForDynamicOptimization) == "function" then
            eligible = addonTable.isRecipeEligibleForDynamicOptimization(record.spellID)
        end

        if eligible then
            local live = liveBySpell[record.spellID]
            local canonical = getOrBuildCanonicalOptimizerRecipe(record)
            local recipe = canonical

            if live then
                recipe = {
                    spellID = canonical.spellID,
                    name = live.name or spellName(record.spellID, canonical.name),
                    profession = canonical.profession,
                    requiredSkill = canonical.requiredSkill,
                    outputItemID = canonical.outputItemID,
                    outputQuantity = canonical.outputQuantity,
                    recipeItemID = canonical.recipeItemID,
                    liveSkillType = live.liveSkillType,
                    learned = true,
                    catalogRecord = record,
                    reagents = type(live.reagents) == "table"
                        and table.getn(live.reagents) > 0
                        and live.reagents
                        or canonical.reagents,
                    outputs = type(live.outputs) == "table"
                        and table.getn(live.outputs) > 0
                        and live.outputs
                        or canonical.outputs,
                }
            end

            if state.learnedRecipes[record.spellID] then
                state.learnedSpells[record.spellID] = true
            end
            table.insert(recipes, recipe)
            seen[record.spellID] = true
        end
    end

    for index = 1, table.getn(liveRecipes) do
        local live = liveRecipes[index]
        if not seen[live.spellID] then
            table.insert(recipes, live)
            seen[live.spellID] = true
        end
    end

    for itemID in pairs(REUSABLE_PROFESSION_TOOLS) do
        local owned = lazyInventoryCount(itemID, 0)
        if owned > 0 then
            state.acquiredOneTime["item:" .. tostring(itemID)] = true
        end
    end

    table.sort(recipes, function(left, right)
        return tonumber(left.spellID or 0) < tonumber(right.spellID or 0)
    end)

    return recipes, state
end

local function getRecipeID(recipe)
    return recipe and (recipe.spellID or recipe.recipeID or recipe.id) or nil
end

local function buildRouteCandidateIndex(recipes, skillContext, startSkill, targetSkill)
    local modifier = tonumber(skillContext and skillContext.activeSkillModifier) or 0
    local firstSkill = math.max(0, tonumber(startSkill) or 0)
    local finalSkill = math.max(firstSkill, tonumber(targetSkill) or firstSkill)
    local index = {}
    local seen = {}
    local bySpell = {}

    for recipeIndex = 1, table.getn(recipes or {}) do
        local recipe = recipes[recipeIndex]
        local recipeID = getRecipeID(recipe)
        if recipeID then bySpell[recipeID] = recipe end
    end

    local function add(skill, recipe)
        index[skill] = index[skill] or {}
        seen[skill] = seen[skill] or {}
        local recipeID = getRecipeID(recipe)
        local key = tostring(recipeID or recipe)
        if not seen[skill][key] then
            seen[skill][key] = true
            table.insert(index[skill], recipe)
        end
    end

    if type(addonTable.getGeneratedRouteCandidateIndex) == "function" then
        local generated = addonTable.getGeneratedRouteCandidateIndex(
            skillContext and skillContext.professionName,
            modifier
        )
        for skill = firstSkill, finalSkill - 1 do
            local ids = generated[skill] or {}
            for candidateIndex = 1, table.getn(ids) do
                local recipe = bySpell[ids[candidateIndex]]
                if recipe then add(skill, recipe) end
            end
        end
    elseif type(addonTable.getRecipeDifficultyMetadata) == "function" then
        for recipeIndex = 1, table.getn(recipes or {}) do
            local recipe = recipes[recipeIndex]
            local metadata = addonTable.getRecipeDifficultyMetadata(recipe)
            if metadata then
                local requiredSkill = tonumber(metadata.requiredSkill) or 0
                local graySkill = tonumber(metadata.graySkill)
                if graySkill then
                    local usableFrom = math.max(firstSkill, math.ceil(requiredSkill - modifier))
                    local usableTo = math.min(finalSkill - 1, math.ceil(graySkill) - 1)
                    for skill = usableFrom, usableTo do add(skill, recipe) end
                end
            end
        end
    end

    for recipeIndex = 1, table.getn(recipes or {}) do
        local recipe = recipes[recipeIndex]
        if recipe.liveSkillType and firstSkill < finalSkill then
            add(firstSkill, recipe)
        end
    end

    return index
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
            performanceCache("price", true)
            return cache[key]
        end

        performanceCache("price", false)
        performanceIncrement("unique_price_lookups", 1)
        local result = baseLookup(item, now)
        cached[key] = true
        cache[key] = result
        return result
    end
end

local function createCachedRecipeCost(baseCostRecipe)
    local cache = {}
    local cacheEntries = 0
    local maxEntries = 4096
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
            if value and string.sub(tostring(key), 1, 7) ~= "recipe:" then
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
        local continuingRecipe = state
            and state.routeActiveRecipeID ~= nil
            and tostring(state.routeActiveRecipeID) == tostring(recipeID)
        local recipeKey = "recipe:" .. tostring(recipeID)
        local recipeAcquired = state
            and type(state.acquiredOneTime) == "table"
            and state.acquiredOneTime[recipeKey] == true
        local key = table.concat({
            tostring(recipeID),
            tostring(tonumber(skill) or 0),
            acquiredSignature(state),
            continuingRecipe and "continue" or "new",
            recipeAcquired and "acquired" or "not-acquired",
        }, "|")

        local cachedCost = cache[key]
        if cachedCost ~= nil then
            performanceCache("recipe_cost", true)
            return shallowCopy(cachedCost)
        end

        performanceCache("recipe_cost", false)
        local cost = baseCostRecipe(recipe, skill, skillContext, state, options or {})
        if cost ~= nil then
            -- Full-catalog routes can touch thousands of recipe/skill states.
            -- Keep the hot cache bounded so the 3.3.5 Lua allocator cannot be
            -- exhausted merely by opening a profession window.
            if cacheEntries < maxEntries then
                cache[key] = shallowCopy(cost)
                cacheEntries = cacheEntries + 1
            end
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

local function rankCurrentRecipesInternal(recipes, skillContext, state, skill, options)
    local ranked = {}
    local currentSkill = tonumber(skillContext and skillContext.baseSkill) or 0
    local costRecipe = options and options.costRecipe or addonTable.calculateRecipeCost
    if type(costRecipe) ~= "function" then
        return ranked
    end

    local candidates = recipes or {}
    if options and type(options.candidateRecipesBySkill) == "table" then
        candidates = options.candidateRecipesBySkill[skill] or {}
    end

    for i = 1, table.getn(candidates) do
        local recipe = candidates[i]
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
            local expectedCost
            local perCraft
            if options and options.requireAvailableNow then
                expectedCost = cost.expectedGoldNeededNowPerSkillUp
                    or cost.expectedCurrentPurchaseCostPerSkillUp
                    or cost.expectedMarketCostPerSkillUp
                perCraft = cost.goldNeededNowPerCraft
                    or cost.currentPurchaseCostPerCraft
                    or cost.materialMarketValuePerCraft
            else
                expectedCost = cost.expectedCurrentPurchaseCostPerSkillUp
                    or cost.expectedMarketCostPerSkillUp
                perCraft = cost.currentPurchaseCostPerCraft
                    or cost.materialMarketValuePerCraft
            end

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

local function rankCurrentRecipes(recipes, skillContext, state, skill, options)
    return measurePerformance(
        "current_candidate_ranking",
        rankCurrentRecipesInternal,
        recipes,
        skillContext,
        state,
        skill,
        options
    )
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

local function adaptiveRouteCost(recipe, skill, skillContext, state, options)
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

    if options and options.requireAvailableNow
        and skill == currentSkill
        and cost.availableNow ~= true
    then
        cost.available = false
        cost.useful = false
        cost.incomplete = false
        cost.unavailableReason = "materials_not_available_now"
        return cost
    end

    if not (options and options.allowGreenRoute)
        and cost.difficulty ~= "orange"
        and cost.difficulty ~= "yellow"
    then
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
        selectedRecipeLearned = false,
        requiresAcquisition = false,
        acquisition = nil,
        nextAction = nil,
    }

    if type(skillContext) ~= "table" then
        result.reason = "profession_context_unavailable"
        return result
    end

    local providerState = type(addonTable.getActivePriceProviderState) == "function"
        and addonTable.getActivePriceProviderState()
        or nil
    if providerState then
        result.providerName = providerState.name
    elseif type(addonTable.getActivePriceProviderName) == "function" then
        result.providerName = addonTable.getActivePriceProviderName()
    end
    if not result.providerName or result.providerName == "null" then
        result.reason = "no_price_provider"
        return result
    end

    if type(addonTable.syncRuntimeSkillContext) == "function" then
        addonTable.syncRuntimeSkillContext(skillContext)
    end

    local providerRevision = providerState and providerState.revision
        or (type(addonTable.getActivePriceProviderRevision) == "function"
            and addonTable.getActivePriceProviderRevision()
            or nil)
    local providerIdentity = providerState and providerState.identity
        or (type(addonTable.getActivePriceProviderIdentity) == "function"
            and addonTable.getActivePriceProviderIdentity()
            or result.providerName)
    local revisions = type(addonTable.getRuntimeRevisions) == "function"
        and addonTable.getRuntimeRevisions()
        or {}
    local lifecycle = type(addonTable.getProfessionBookLifecycleState) == "function"
        and addonTable.getProfessionBookLifecycleState(skillContext.professionName)
        or nil
    local bookRevision = lifecycle and lifecycle.generation or nil
    if bookRevision == nil then
        local globalBookRevision = tonumber(revisions.professionBook)
        if globalBookRevision and globalBookRevision > 0 then
            bookRevision = globalBookRevision
        else
            bookRevision = learnedRecipeSignature(recipeCache)
        end
    end
    local skillRevision = revisions.skill
        or table.concat({
            tostring(skillContext.baseSkill or 0),
            tostring(skillContext.currentCap or 0),
            tostring(skillContext.activeSkillModifier or 0),
        }, ":")
    local inventoryRevision = revisions.inventory or "legacy"
    local eligibilityRevision = revisions.eligibility or "legacy"
    local modeRevision = revisions.mode or "legacy"
    local acquisitionRevision = options.acquisitionRevision
        or addonTable.recipeAcquisitionDataRevision
        or "static"

    local cacheKey = table.concat({
        tostring(providerIdentity or result.providerName),
        tostring(providerRevision or "unknown"),
        tostring(skillContext.professionName or ""),
        tostring(bookRevision),
        tostring(skillRevision),
        tostring(inventoryRevision),
        tostring(eligibilityRevision),
        tostring(modeRevision),
        result.requireAvailableNow and "available" or "cheapest",
        tostring(options.optimizeFor or "current"),
        tostring(options.targetSkill or ""),
        tostring(acquisitionRevision),
    }, "|")
    local cacheNow = runtimeNow()
    local cachedRecommendation = recommendationCache[cacheKey]
    if cachedRecommendation
        and cacheNow - cachedRecommendation.createdAt <= RECOMMENDATION_CACHE_TTL
    then
        performanceCache("recommendation", true)
        return cachedRecommendation.result
    end
    if cachedRecommendation then
        removeRecommendationCacheKey(cacheKey)
    end
    performanceCache("recommendation", false)

    local capturedRevisions = revisions
    local function dependenciesStillCurrent()
        if type(addonTable.getRuntimeRevisions) == "function" then
            local current = addonTable.getRuntimeRevisions()
            for _, key in ipairs({
                "professionBook",
                "skill",
                "inventory",
                "eligibility",
                "mode",
            }) do
                if current[key] ~= capturedRevisions[key] then
                    return false
                end
            end
        end
        if type(addonTable.getActivePriceProviderState) == "function" then
            local currentProvider = addonTable.getActivePriceProviderState()
            if currentProvider.name ~= result.providerName
                or currentProvider.identity ~= providerIdentity
            then
                return false
            end
            if providerRevision ~= nil
                and currentProvider.revision ~= providerRevision
            then
                return false
            end
        else
            if type(addonTable.getActivePriceProviderName) == "function"
                and addonTable.getActivePriceProviderName() ~= result.providerName
            then
                return false
            end
            if type(addonTable.getActivePriceProviderIdentity) == "function"
                and addonTable.getActivePriceProviderIdentity() ~= providerIdentity
            then
                return false
            end
            if providerRevision ~= nil
                and type(addonTable.getActivePriceProviderRevision) == "function"
                and addonTable.getActivePriceProviderRevision() ~= providerRevision
            then
                return false
            end
        end
        return true
    end

    local function cacheAndReturn(value)
        if not dependenciesStillCurrent() then
            return {
                available = false,
                fallbackToStaticGuide = true,
                reason = "runtime_inputs_changed",
                providerName = result.providerName,
                requireAvailableNow = result.requireAvailableNow,
                routeComplete = false,
            }
        end

        storeRecommendationCache(cacheKey, {
            createdAt = runtimeNow(),
            result = value,
        })
        return value
    end

    if type(addonTable.solveCheapestProfessionRoute) ~= "function"
        or type(addonTable.buildProfessionShoppingPlan) ~= "function"
        or type(addonTable.calculateRecipeCost) ~= "function"
        or type(addonTable.buildFullProfessionOptimizationInput) ~= "function"
    then
        result.reason = "optimizer_unavailable"
        return result
    end

    local persistentPriceLookup
    if type(addonTable.createRevisionedPriceLookup) == "function" then
        persistentPriceLookup = addonTable.createRevisionedPriceLookup(
            result.providerName,
            providerRevision,
            providerIdentity
        )
    else
        persistentPriceLookup = addonTable.lookupItemPrice
    end
    local cachedPriceLookup = type(persistentPriceLookup) == "function"
        and createCachedPriceLookup(persistentPriceLookup)
        or nil
    local cachedRecipeCost = createCachedRecipeCost(addonTable.calculateRecipeCost)
    local costOptions = {}
    for key, value in pairs(options.costOptions or {}) do
        costOptions[key] = value
    end
    costOptions.priceLookup = cachedPriceLookup or costOptions.priceLookup
    costOptions.unitPriceChooser = costOptions.unitPriceChooser or addonTable.chooseUsableUnitPrice
    costOptions.costRecipe = cachedRecipeCost
    costOptions.requireAvailableNow = result.requireAvailableNow
    costOptions.materialCostCache = {}
    result.priceLookup = cachedPriceLookup

    local recipes, state = measurePerformance(
        "optimizer_input",
        addonTable.buildFullProfessionOptimizationInput,
        recipeCache,
        skillContext
    )
    result.recipes = recipes
    result.state = state
    if table.getn(recipes) == 0 then
        result.reason = "no_eligible_recipes"
        return cacheAndReturn(result)
    end

    local targetSkill = tonumber(
        options.targetSkill
        or state.reachableCap
        or skillContext.currentCap
    ) or 450
    targetSkill = math.min(450, targetSkill)
    result.targetSkill = targetSkill

    if targetSkill <= (tonumber(skillContext.baseSkill) or 0) then
        result.reason = "target_reached"
        return cacheAndReturn(result)
    end

    local candidateRecipesBySkill = measurePerformance(
        "candidate_index",
        buildRouteCandidateIndex,
        recipes,
        skillContext,
        skillContext.baseSkill,
        targetSkill
    )
    costOptions.candidateRecipesBySkill = candidateRecipesBySkill

    local fallbackSegment, candidates = buildCurrentCheapestSegment(
        recipes,
        skillContext,
        state,
        targetSkill,
        costOptions,
        result.requireAvailableNow
    )
    candidates = candidates or {}
    local availableCandidates = {}
    for i = 1, table.getn(candidates) do
        if candidates[i].availableNow then
            table.insert(availableCandidates, candidates[i])
        end
    end

    local routeCostOptions = {}
    for key, value in pairs(costOptions) do
        routeCostOptions[key] = value
    end
    routeCostOptions.requireAvailableNow = result.requireAvailableNow
    routeCostOptions.baseCostRecipe = cachedRecipeCost
    routeCostOptions.allowGreenRoute = state.fullCatalog == true

    local routeOptions = {
        startSkill = skillContext.baseSkill,
        targetSkill = targetSkill,
        optimizeFor = options.optimizeFor or "current",
        maxStates = options.maxStates,
        costRecipe = adaptiveRouteCost,
        costOptions = routeCostOptions,
        trainingSteps = state.trainingSteps,
        candidateRecipesBySkill = candidateRecipesBySkill,
        pruneDominatedRecipeSwitches = true,
        layeredDynamicProgramming = true,
        generationToken = cacheKey,
        isJobCurrent = function(token)
            return token == cacheKey and dependenciesStillCurrent()
        end,
        sliceBudgetMs = options.routeSliceBudgetMs,
    }

    local function finalizeRecommendation(route)
        result._incremental = nil
        result.calculating = false
        result.candidates = candidates
        result.availableCandidates = availableCandidates
        result.currentSegment = nil
        result.currentCost = nil
        result.available = false
        result.fallbackToStaticGuide = true
        result.reason = nil
        result.route = route
        result.routeComplete = false
        result.routeReason = nil
        result.plan = nil
        result.selectedRecipeLearned = false
        result.requiresAcquisition = false
        result.acquisition = nil
        result.nextAction = nil

        performanceSet("route_explored_states", route and route.exploredStates or 0)

        if fallbackSegment and fallbackSegment.recipeID then
            result.currentSegment = fallbackSegment
            result.currentCost = fallbackSegment.firstCost
            result.available = true
            result.fallbackToStaticGuide = false
        end

        if not route or not route.complete then
            result.routeReason = route and route.reason or "no_complete_route"
            if not result.currentSegment then
                result.reason = result.requireAvailableNow
                    and "no_available_recipe"
                    or "no_current_priced_recipe"
            end
            return cacheAndReturn(result)
        end

        local authoritative = route.segments and route.segments[1]
        if authoritative and authoritative.recipeID then
            result.currentSegment = authoritative
            result.currentCost = authoritative.firstCost
            result.available = true
            result.fallbackToStaticGuide = false
            result.reason = nil
        end

        if not result.currentSegment or not result.currentSegment.recipeID then
            result.reason = "no_current_priced_recipe"
            result.routeReason = result.reason
            result.available = false
            result.fallbackToStaticGuide = true
            return cacheAndReturn(result)
        end

        result.selectedRecipeLearned = state.learnedRecipes[result.currentSegment.recipeID] == true
        result.acquisition = result.currentCost and result.currentCost.acquisition or nil
        result.requiresAcquisition = not result.selectedRecipeLearned
            and result.acquisition ~= nil
            and result.acquisition.alreadyAcquired ~= true
        result.nextAction = result.requiresAcquisition and "acquire_recipe" or "craft"

        local plan = measurePerformance(
            "shopping_plan",
            addonTable.buildProfessionShoppingPlan,
            route,
            state,
            {
                priceLookup = cachedPriceLookup,
                unitPriceChooser = costOptions.unitPriceChooser,
                priceRevision = options.priceRevision or providerRevision,
                recipeRevision = options.recipeRevision or bookRevision,
                acquisitionRevision = acquisitionRevision,
                runtimeRevisions = capturedRevisions,
            }
        )
        result.plan = plan

        if not plan or not plan.complete then
            result.routeReason = plan and plan.reason or "shopping_plan_incomplete"
            result.plan = nil
            return cacheAndReturn(result)
        end

        result.routeComplete = true
        return cacheAndReturn(result)
    end

    if options.incrementalRoute == true
        and type(addonTable.createCheapestProfessionRouteJob) == "function"
        and type(addonTable.stepCheapestProfessionRouteJob) == "function"
    then
        local routeJob = addonTable.createCheapestProfessionRouteJob(
            recipes,
            skillContext,
            state,
            routeOptions
        )

        if routeJob and routeJob.status == "completed" then
            return finalizeRecommendation(routeJob.result)
        end

        result.available = false
        result.fallbackToStaticGuide = true
        result.reason = "calculating"
        result.calculating = true
        result.currentSegment = nil
        result.currentCost = nil
        result.candidates = {}
        result.availableCandidates = {}
        result.route = nil
        result.plan = nil
        result._incremental = {
            routeJob = routeJob,
            finalize = finalizeRecommendation,
        }
        return result
    end

    local route = measurePerformance(
        "route_solver",
        addonTable.solveCheapestProfessionRoute,
        recipes,
        skillContext,
        state,
        routeOptions
    )
    return finalizeRecommendation(route)
end

function addonTable.stepDynamicProfessionRecommendation(pending, budgetMs, clock)
    if type(pending) ~= "table" or pending.calculating ~= true then
        return "completed", pending
    end

    local work = pending._incremental
    if type(work) ~= "table" or type(work.routeJob) ~= "table" then
        return "invalid", {
            available = false,
            fallbackToStaticGuide = true,
            reason = "optimizer_error",
            routeComplete = false,
        }
    end

    local status, route = addonTable.stepCheapestProfessionRouteJob(
        work.routeJob,
        budgetMs,
        clock
    )

    if status == "running" then
        return status, pending
    end

    local metrics = type(addonTable.getCheapestProfessionRouteJobMetrics) == "function"
        and addonTable.getCheapestProfessionRouteJobMetrics(work.routeJob)
        or nil
    if metrics and type(addonTable.recordRouteJobPerformance) == "function" then
        addonTable.recordRouteJobPerformance(metrics)
    end

    pending._incremental = nil
    pending.calculating = false

    if status == "cancelled" then
        return status, {
            available = false,
            fallbackToStaticGuide = true,
            reason = "runtime_inputs_changed",
            providerName = pending.providerName,
            requireAvailableNow = pending.requireAvailableNow,
            routeComplete = false,
        }
    end

    if status ~= "completed" then
        return status, {
            available = false,
            fallbackToStaticGuide = true,
            reason = "optimizer_error",
            providerName = pending.providerName,
            requireAvailableNow = pending.requireAvailableNow,
            routeComplete = false,
        }
    end

    return "completed", work.finalize(route)
end

function addonTable.cancelDynamicProfessionRecommendation(pending, reason)
    if type(pending) ~= "table" or pending.calculating ~= true then
        return false
    end

    local work = pending._incremental
    if type(work) == "table"
        and type(work.routeJob) == "table"
        and type(addonTable.cancelCheapestProfessionRouteJob) == "function"
    then
        addonTable.cancelCheapestProfessionRouteJob(
            work.routeJob,
            reason or "cancelled"
        )
        local metrics = type(addonTable.getCheapestProfessionRouteJobMetrics) == "function"
            and addonTable.getCheapestProfessionRouteJobMetrics(work.routeJob)
            or nil
        if metrics and type(addonTable.recordRouteJobPerformance) == "function" then
            addonTable.recordRouteJobPerformance(metrics)
        end
    end

    pending._incremental = nil
    pending.calculating = false
    pending.recipes = nil
    pending.state = nil
    pending.priceLookup = nil
    pending.candidates = {}
    pending.availableCandidates = {}
    pending.route = nil
    pending.plan = nil
    return true
end

