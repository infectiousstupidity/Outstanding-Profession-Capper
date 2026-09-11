local addonName, addonTable = ...

local recordsBySpell = {}
local recordsByKey = {}
addonTable.recipeAcquisitionRecords = recordsBySpell
addonTable.professionAcquisitionRecords = recordsByKey

local ALLOWED_TYPES = {
    learned = true,
    trainer = true,
    vendor = true,
    limited_vendor = true,
    auction = true,
    reputation = true,
    quest = true,
    drop = true,
    manual = true,
    unknown = true,
}

local ALLOWED_FACTIONS = {
    neutral = true,
    alliance = true,
    horde = true,
}

local function nonNegative(value)
    value = tonumber(value)
    if value and value >= 0 then
        return value
    end
    return nil
end

local function positive(value)
    value = tonumber(value)
    if value and value > 0 then
        return value
    end
    return nil
end

local function effectiveSkill(baseSkill, skillContext)
    if type(addonTable.getEffectiveSkillForBase) == "function" then
        return addonTable.getEffectiveSkillForBase(baseSkill, skillContext)
    end
    local modifier = skillContext and tonumber(skillContext.activeSkillModifier) or 0
    return (tonumber(baseSkill) or 0) + (modifier or 0)
end

local function sourceTypeFromLegacy(status)
    if status == "learned" then return "learned" end
    if status == "trainable" then return "trainer" end
    if status == "vendor" or status == "purchasable" then return "vendor" end
    if status == "limited_vendor" then return "limited_vendor" end
    if status == "auction" or status == "ah" then return "auction" end
    if status == "reputation" then return "reputation" end
    if status == "quest" then return "quest" end
    if status == "drop" or status == "world_drop" then return "drop" end
    if status == "manual" then return "manual" end
    return status or "unknown"
end

local function normalizeInline(recipe)
    local acquisition = recipe and recipe.acquisition
    if type(acquisition) ~= "table" then
        return nil
    end

    local entry = {}
    for key, value in pairs(acquisition) do
        entry[key] = value
    end
    entry.spellID = entry.spellID or recipe.spellID or recipe.recipeID
    entry.profession = entry.profession or recipe.profession or "Unknown"
    entry.sourceType = entry.sourceType or sourceTypeFromLegacy(entry.status or entry.state)
    entry.purchasePrice = entry.purchasePrice
        or entry.goldCost
    entry.marketCost = entry.marketCost
    entry.sourceName = entry.sourceName or entry.source
    entry.recipeItemID = entry.recipeItemID or entry.itemID
    return entry
end

function addonTable.validateRecipeAcquisitionEntry(entry)
    if type(entry) ~= "table" then
        return false, "acquisition_not_table"
    end

    local spellID = positive(entry.spellID or entry.recipeID)
    local key = entry.key
    if not spellID and (type(key) ~= "string" or key == "") then
        return false, "missing_acquisition_identifier"
    end

    local sourceType = entry.sourceType or sourceTypeFromLegacy(entry.status or entry.state)
    if not ALLOWED_TYPES[sourceType] then
        return false, "unsupported_acquisition_type"
    end

    if entry.profession ~= nil and (type(entry.profession) ~= "string" or entry.profession == "") then
        return false, "invalid_profession"
    end

    if (sourceType == "trainer" or sourceType == "vendor" or sourceType == "limited_vendor")
        and (type(entry.sourceName) ~= "string" or entry.sourceName == "")
    then
        return false, "missing_source_name"
    end

    if sourceType == "limited_vendor" and entry.limitedStock ~= true then
        return false, "limited_vendor_requires_stock_flag"
    end

    if sourceType == "auction" and not positive(entry.recipeItemID or entry.itemID) then
        return false, "auction_requires_recipe_item"
    end

    if sourceType == "reputation" then
        local reputation = entry.reputation
        if type(reputation) ~= "table"
            or type(reputation.faction) ~= "string"
            or reputation.faction == ""
            or type(reputation.standing) ~= "string"
            or reputation.standing == ""
        then
            return false, "invalid_reputation_requirement"
        end
    end

    if entry.faction and not ALLOWED_FACTIONS[string.lower(tostring(entry.faction))] then
        return false, "invalid_faction"
    end

    if entry.purchasePrice ~= nil and nonNegative(entry.purchasePrice) == nil then
        return false, "invalid_purchase_price"
    end
    if entry.requiredSkill ~= nil and nonNegative(entry.requiredSkill) == nil then
        return false, "invalid_required_skill"
    end

    if entry.coordinates ~= nil then
        local coordinates = entry.coordinates
        local x = type(coordinates) == "table" and tonumber(coordinates.x or coordinates[1]) or nil
        local y = type(coordinates) == "table" and tonumber(coordinates.y or coordinates[2]) or nil
        if not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then
            return false, "invalid_coordinates"
        end
    end

    return true
end

function addonTable.registerRecipeAcquisition(entry)
    local valid, reason = addonTable.validateRecipeAcquisitionEntry(entry)
    if not valid then
        error("Invalid recipe acquisition metadata: " .. tostring(reason))
    end

    local copy = {}
    for key, value in pairs(entry) do
        copy[key] = value
    end
    copy.sourceType = copy.sourceType or sourceTypeFromLegacy(copy.status or copy.state)

    local spellID = positive(copy.spellID or copy.recipeID)
    if spellID then
        copy.spellID = spellID
        recordsBySpell[spellID] = copy
    end
    if type(copy.key) == "string" and copy.key ~= "" then
        recordsByKey[copy.key] = copy
    end
    return copy
end

function addonTable.getRecipeAcquisitionRecord(recipeOrSpellID)
    local spellID = recipeOrSpellID
    if type(recipeOrSpellID) == "table" then
        spellID = recipeOrSpellID.spellID or recipeOrSpellID.recipeID
    end
    spellID = positive(spellID)
    if not spellID then
        return nil
    end
    return recordsBySpell[spellID]
end

function addonTable.getProfessionAcquisitionRecord(key)
    if type(key) ~= "string" then
        return nil
    end
    return recordsByKey[key]
end

local function learnedInState(spellID, state)
    if not spellID or type(state) ~= "table" or type(state.learnedRecipes) ~= "table" then
        return false
    end
    return state.learnedRecipes[spellID] == true
        or state.learnedRecipes[tostring(spellID)] == true
end

local function currentAuctionCost(entry, options)
    local itemID = positive(entry.recipeItemID or entry.itemID)
    if not itemID then
        return nil, "auction_requires_recipe_item"
    end

    local lookup = options and options.priceLookup or addonTable.lookupItemPrice
    local chooser = options and options.unitPriceChooser or addonTable.chooseUsableUnitPrice
    if type(lookup) ~= "function" or type(chooser) ~= "function" then
        return nil, "price_provider_unavailable"
    end

    local price = lookup(itemID, options and options.now)
    local choice, reason = chooser(price, "auction")
    if not choice or not choice.unitPrice then
        return nil, reason or "recipe_item_not_currently_listed"
    end
    return choice.unitPrice, nil, choice
end

local function resultBase(entry, spellID)
    return {
        handled = true,
        record = entry,
        spellID = spellID,
        key = entry.key or (spellID and ("recipe:" .. tostring(spellID)) or nil),
        sourceType = entry.sourceType,
        source = entry.sourceType,
        sourceName = entry.sourceName,
        sourceID = entry.sourceID or entry.trainerID or entry.vendorID,
        zone = entry.zone,
        coordinates = entry.coordinates,
        faction = entry.faction,
        reputation = entry.reputation,
        recipeItemID = entry.recipeItemID or entry.itemID,
        trainerRank = entry.trainerRank,
        notes = entry.notes,
        limitedStock = entry.limitedStock == true,
        available = false,
        alreadyAcquired = false,
        immediate = false,
        goldCost = nil,
        marketCost = nil,
        state = "unavailable_unknown",
        reason = nil,
    }
end

function addonTable.resolveRecipeAcquisition(recipeOrSpellID, state, skillContext, options)
    state = state or {}
    options = options or {}

    local spellID
    local recipe
    if type(recipeOrSpellID) == "table" then
        recipe = recipeOrSpellID
        spellID = positive(recipe.spellID or recipe.recipeID)
    else
        spellID = positive(recipeOrSpellID)
    end

    if learnedInState(spellID, state) then
        return {
            handled = true,
            spellID = spellID,
            key = "recipe:" .. tostring(spellID),
            sourceType = "learned",
            source = "learned",
            sourceName = "Already learned",
            available = true,
            alreadyAcquired = true,
            immediate = true,
            goldCost = 0,
            marketCost = 0,
            state = "immediately_usable",
        }
    end

    local entry = spellID and recordsBySpell[spellID] or nil
    if not entry and recipe then
        entry = normalizeInline(recipe)
    end

    if not entry then
        return {
            handled = true,
            spellID = spellID,
            key = spellID and ("recipe:" .. tostring(spellID)) or nil,
            sourceType = "unknown",
            source = "unknown",
            available = false,
            alreadyAcquired = false,
            immediate = false,
            state = "unavailable_unknown",
            reason = "missing_acquisition_metadata",
        }
    end

    local sourceType = entry.sourceType or sourceTypeFromLegacy(entry.status or entry.state)
    entry.sourceType = sourceType

    if sourceType == "learned" or entry.alreadyLearned then
        local learned = resultBase(entry, spellID)
        learned.available = true
        learned.alreadyAcquired = true
        learned.immediate = true
        learned.goldCost = 0
        learned.marketCost = 0
        learned.state = "immediately_usable"
        return learned
    end

    local result = resultBase(entry, spellID)
    local requiredSkill = nonNegative(entry.requiredSkill)
    if requiredSkill then
        local base = tonumber(skillContext and skillContext.baseSkill) or tonumber(options.baseSkill) or 0
        local effective = effectiveSkill(base, skillContext)
        result.requiredSkill = requiredSkill
        result.effectiveSkill = effective
        if effective < requiredSkill then
            result.reason = "required_skill_not_met"
            result.state = "unavailable"
            return result
        end
    end

    if entry.faction and state.faction then
        local requiredFaction = string.lower(tostring(entry.faction))
        local characterFaction = string.lower(tostring(state.faction))
        if requiredFaction ~= "neutral" and requiredFaction ~= characterFaction then
            result.reason = "faction_restricted"
            result.state = "unavailable"
            return result
        end
    end

    if sourceType == "trainer" or sourceType == "vendor" then
        local cost = nonNegative(entry.purchasePrice or entry.goldCost)
        if cost == nil then
            result.reason = "missing_acquisition_cost"
            result.state = sourceType == "trainer" and "trainable_now" or "purchasable_now"
            return result
        end
        result.available = true
        result.immediate = true
        result.goldCost = cost
        result.marketCost = nonNegative(entry.marketCost) or cost
        result.state = sourceType == "trainer" and "trainable_now" or "purchasable_now"
        return result
    end

    if sourceType == "limited_vendor" then
        result.goldCost = nonNegative(entry.purchasePrice or entry.goldCost)
        result.marketCost = nonNegative(entry.marketCost) or result.goldCost
        result.state = "obtainable"
        result.reason = "limited_stock_not_guaranteed"
        return result
    end

    if sourceType == "auction" then
        local cost, reason, choice = currentAuctionCost(entry, options)
        if not cost then
            result.reason = reason or "recipe_item_not_currently_listed"
            result.state = "unavailable"
            return result
        end
        result.available = true
        result.immediate = true
        result.goldCost = cost
        result.marketCost = cost
        result.state = "purchasable_now"
        result.priceSource = choice and choice.source
        result.priceFreshness = choice and choice.freshness
        return result
    end

    if sourceType == "reputation" then
        result.state = "obtainable_non_gold"
        result.reason = "reputation_requirement"
        return result
    end
    if sourceType == "quest" then
        result.state = "obtainable_non_gold"
        result.reason = "quest_requirement"
        return result
    end
    if sourceType == "drop" then
        result.state = "obtainable_non_gold"
        result.reason = "drop_not_guaranteed"
        return result
    end
    if sourceType == "manual" then
        result.state = "unavailable_unknown"
        result.reason = "manual_acquisition_required"
        return result
    end

    result.state = "unavailable_unknown"
    result.reason = "unknown_acquisition"
    return result
end

function addonTable.explainRecipeAcquisition(recipeOrSpellID, state, skillContext, options)
    local result = addonTable.resolveRecipeAcquisition(recipeOrSpellID, state, skillContext, options)
    return {
        state = result.state,
        reason = result.reason,
        sourceType = result.sourceType,
        sourceName = result.sourceName,
        sourceID = result.sourceID,
        zone = result.zone,
        coordinates = result.coordinates,
        faction = result.faction,
        reputation = result.reputation,
        recipeItemID = result.recipeItemID,
        purchasePrice = result.goldCost,
        limitedStock = result.limitedStock,
        notes = result.notes,
    }
end
