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
    world_drop = true,
    other = true,
    manual = true,
    unknown = true,
}

local ALLOWED_FACTIONS = {
    neutral = true,
    alliance = true,
    horde = true,
}

local STANDING_VALUES = {
    hated = 0,
    hostile = 1,
    unfriendly = 2,
    neutral = 3,
    friendly = 4,
    honored = 5,
    revered = 6,
    exalted = 7,
}

local function nonNegative(value)
    value = tonumber(value)
    if value and value >= 0 then return value end
    return nil
end

local function positive(value)
    value = tonumber(value)
    if value and value > 0 then return value end
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
    if type(acquisition) ~= "table" then return nil end

    local entry = {}
    for key, value in pairs(acquisition) do entry[key] = value end
    entry.spellID = entry.spellID or recipe.spellID or recipe.recipeID
    entry.profession = entry.profession or recipe.profession or "Unknown"
    entry.sourceType = entry.sourceType or sourceTypeFromLegacy(entry.status or entry.state)
    entry.purchasePrice = entry.purchasePrice or entry.goldCost
    entry.sourceName = entry.sourceName or entry.source or "Inline acquisition"
    entry.recipeItemID = entry.recipeItemID or entry.itemID
    return entry
end

function addonTable.validateRecipeAcquisitionEntry(entry)
    if type(entry) ~= "table" then return false, "acquisition_not_table" end

    local spellID = positive(entry.spellID or entry.recipeID)
    local key = entry.key
    if not spellID and (type(key) ~= "string" or key == "") then
        return false, "missing_acquisition_identifier"
    end

    local sourceType = entry.sourceType or sourceTypeFromLegacy(entry.status or entry.state)
    if not ALLOWED_TYPES[sourceType] then return false, "unsupported_acquisition_type" end

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
    if entry.requiredLevel ~= nil and nonNegative(entry.requiredLevel) == nil then
        return false, "invalid_required_level"
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
    if not valid then error("Invalid recipe acquisition metadata: " .. tostring(reason)) end

    local copy = {}
    for key, value in pairs(entry) do copy[key] = value end
    copy.sourceType = copy.sourceType or sourceTypeFromLegacy(copy.status or copy.state)

    local spellID = positive(copy.spellID or copy.recipeID)
    if spellID then
        copy.spellID = spellID
        recordsBySpell[spellID] = recordsBySpell[spellID] or {}
        table.insert(recordsBySpell[spellID], copy)
    end
    if type(copy.key) == "string" and copy.key ~= "" then recordsByKey[copy.key] = copy end
    return copy
end

function addonTable.getRecipeAcquisitionRecords(recipeOrSpellID)
    local spellID = recipeOrSpellID
    if type(recipeOrSpellID) == "table" then spellID = recipeOrSpellID.spellID or recipeOrSpellID.recipeID end
    spellID = positive(spellID)
    if not spellID then return {} end

    local source = recordsBySpell[spellID] or {}
    local result = {}
    for index = 1, table.getn(source) do result[index] = source[index] end
    return result
end

function addonTable.getRecipeAcquisitionRecord(recipeOrSpellID)
    local records = addonTable.getRecipeAcquisitionRecords(recipeOrSpellID)
    return records[1]
end

function addonTable.getProfessionAcquisitionRecord(key)
    if type(key) ~= "string" then return nil end
    return recordsByKey[key]
end

local function learnedInState(spellID, state)
    if not spellID or type(state) ~= "table" or type(state.learnedRecipes) ~= "table" then return false end
    return state.learnedRecipes[spellID] == true or state.learnedRecipes[tostring(spellID)] == true
end

local function acquiredInRoute(spellID, state)
    if not spellID or type(state) ~= "table" then
        return false
    end

    -- RouteSolver keeps exact learned-recipe history in a compact candidate-
    -- scoped bitset and materializes the current recipe as acquiredOneTime below.
    -- routeActiveRecipeID remains a compatibility fast path for a continuous
    -- recipe segment and for callers outside the compact route solver.
    if state.routeActiveRecipeID ~= nil
        and tostring(state.routeActiveRecipeID) == tostring(spellID)
    then
        return true
    end

    if type(state.acquiredOneTime) ~= "table" then
        return false
    end
    return state.acquiredOneTime["recipe:" .. tostring(spellID)] == true
end

local function inventoryCount(itemID, state)
    if not itemID or type(state) ~= "table" then return 0 end
    local value
    if type(state.inventory) == "table" then
        value = state.inventory[itemID] or state.inventory[tostring(itemID)]
    end
    if value == nil and type(state.getInventoryCount) == "function" then
        local ok, count = pcall(state.getInventoryCount, itemID, 0)
        if ok then value = count end
    end
    return math.max(0, tonumber(value) or 0)
end

local function standingValue(value)
    if type(value) == "table" then
        value = value.standingID or value.rank or value.standing
    end
    local numeric = tonumber(value)
    if numeric then return numeric end
    if type(value) == "string" then return STANDING_VALUES[string.lower(value)] end
    return nil
end

local function knowsSpell(spellID, state, options)
    if not positive(spellID) then return true end
    if type(state.learnedSpells) == "table" then
        local known = state.learnedSpells[spellID]
        if known == nil then known = state.learnedSpells[tostring(spellID)] end
        if known ~= nil then return known == true end
    end
    if learnedInState(spellID, state) then return true end
    if type(state.isSpellKnown) == "function" then
        local ok, known = pcall(state.isSpellKnown, spellID)
        if ok and known ~= nil then return known == true end
    end
    if options and type(options.isSpellKnown) == "function" then
        local ok, known = pcall(options.isSpellKnown, spellID)
        if ok then return known == true end
    end
    return nil
end

local function currentAuctionCost(itemID, options)
    itemID = positive(itemID)
    if not itemID then return nil, "auction_requires_recipe_item" end

    local lookup = options and options.priceLookup or addonTable.lookupItemPrice
    local chooser = options and options.unitPriceChooser or addonTable.chooseUsableUnitPrice
    if type(lookup) ~= "function" or type(chooser) ~= "function" then
        return nil, "price_provider_unavailable"
    end

    local price = lookup(itemID, options and options.now)
    local choice, reason = chooser(price, "auction")
    if not choice or not positive(choice.unitPrice) then
        return nil, reason or "recipe_item_not_currently_listed"
    end
    return choice.unitPrice, nil, choice
end

local function resultBase(entry, spellID)
    entry = entry or {}

    local locations = entry.locations
    if type(locations) ~= "table"
        and type(addonTable.getRecipeSourceLocations) == "function"
    then
        locations = addonTable.getRecipeSourceLocations(entry)
    end
    locations = type(locations) == "table" and locations or {}
    local primaryLocation = locations[1]

    return {
        handled = true,
        record = entry,
        spellID = spellID,
        key = entry.key or (spellID and ("recipe:" .. tostring(spellID)) or nil),
        sourceType = entry.sourceType or "unknown",
        source = entry.sourceType or "unknown",
        sourceName = entry.sourceName,
        sourceID = entry.sourceID or entry.trainerID or entry.vendorID,
        zone = entry.zone or (primaryLocation and primaryLocation.zone),
        coordinates = entry.coordinates or (primaryLocation and primaryLocation.coordinates),
        locations = locations,
        faction = entry.faction,
        reputation = entry.reputation,
        recipeItemID = entry.recipeItemID or entry.itemID,
        trainerRank = entry.trainerRank,
        notes = entry.notes,
        limitedStock = entry.limitedStock == true,
        available = false,
        reliable = false,
        alreadyAcquired = false,
        immediate = false,
        requiresLearning = true,
        goldCost = nil,
        marketCost = nil,
        state = "unavailable_unknown",
        reason = nil,
    }
end

local function fail(result, stateName, reason)
    result.state = stateName or "unavailable"
    result.reason = reason
    return result
end

local function passesRequirements(entry, result, state, skillContext, options)
    local requiredSkill = nonNegative(entry.requiredSkill)
    if requiredSkill then
        local base = tonumber(options and options.baseSkill) or tonumber(skillContext and skillContext.baseSkill) or 0
        local effective = effectiveSkill(base, skillContext)
        result.requiredSkill = requiredSkill
        result.effectiveSkill = effective
        if effective < requiredSkill then return false, "required_skill_not_met" end
    end

    local requiredLevel = nonNegative(entry.requiredLevel)
    if requiredLevel and requiredLevel > 0 then
        result.requiredLevel = requiredLevel
        local level = tonumber(state.playerLevel)
        if not level then return false, "player_level_unknown" end
        if level < requiredLevel then return false, "required_level_not_met" end
    end

    if entry.faction then
        local requiredFaction = string.lower(tostring(entry.faction))
        if requiredFaction ~= "neutral" then
            if not state.faction then return false, "faction_unknown" end
            if requiredFaction ~= string.lower(tostring(state.faction)) then return false, "faction_restricted" end
        end
    end

    local prerequisites = entry.prerequisiteSpellIDs
    if type(prerequisites) == "table" then
        for index = 1, table.getn(prerequisites) do
            local prerequisite = positive(prerequisites[index])
            if prerequisite then
                local known = knowsSpell(prerequisite, state, options)
                if known == nil then return false, "prerequisite_state_unknown" end
                if not known then return false, "prerequisite_spell_not_known" end
            end
        end
    end

    if entry.specializationSpellID then
        local known = knowsSpell(entry.specializationSpellID, state, options)
        if known == nil then return false, "specialization_state_unknown" end
        if not known then return false, "specialization_not_known" end
    end

    if entry.reputation then
        local rep = entry.reputation
        local required = standingValue(rep.standingID or rep.standing)
        local standings = state.reputation
        if type(standings) ~= "table" then return false, "reputation_state_unknown" end
        local current = standings[rep.factionID] or standings[tostring(rep.factionID or "")] or standings[rep.faction]
        current = standingValue(current)
        if current == nil and type(state.getReputationStanding) == "function" and rep.factionID then
            local ok, value = pcall(state.getReputationStanding, rep.factionID)
            if ok then current = standingValue(value) end
        end
        if current == nil then return false, "reputation_state_unknown" end
        if required ~= nil and current < required then return false, "reputation_requirement_not_met" end
    end

    return true
end

local function fixedGoldCost(entry)
    local cost = nonNegative(entry.purchasePrice or entry.goldCost)
    if cost == nil then return nil end
    if cost == 0 and entry.free ~= true then
        return nil
    end
    return cost
end

local function evaluateStaticEntry(entry, spellID, state, skillContext, options)
    local result = resultBase(entry, spellID)
    local sourceType = entry.sourceType or sourceTypeFromLegacy(entry.status or entry.state)
    result.sourceType = sourceType
    result.source = sourceType

    local requirementsOK, requirementReason = passesRequirements(entry, result, state, skillContext, options)
    if not requirementsOK then
        return fail(result, "unavailable", requirementReason)
    end

    if sourceType == "learned" or entry.alreadyLearned then
        result.available, result.reliable, result.alreadyAcquired, result.immediate = true, true, true, true
        result.requiresLearning = false
        result.goldCost, result.marketCost, result.state = 0, 0, "immediately_usable"
        return result
    end

    if sourceType == "trainer" or sourceType == "vendor" or sourceType == "reputation" then
        local cost = fixedGoldCost(entry)
        if cost == nil then
            return fail(result, sourceType == "trainer" and "trainable_now" or "purchasable_now", "missing_acquisition_cost")
        end
        result.available, result.reliable, result.immediate = true, true, true
        result.goldCost = cost
        result.marketCost = nonNegative(entry.marketCost) or cost
        if sourceType == "trainer" then
            result.state = "trainable_now"
        elseif sourceType == "reputation" then
            result.state = "reputation_vendor_now"
        else
            result.state = "purchasable_now"
        end
        return result
    end

    if sourceType == "auction" then
        local cost, reason, choice = currentAuctionCost(entry.recipeItemID or entry.itemID, options)
        if not cost then return fail(result, "unavailable", reason or "recipe_item_not_currently_listed") end
        result.available, result.reliable, result.immediate = true, true, true
        result.goldCost, result.marketCost, result.state = cost, cost, "purchasable_now"
        result.priceSource = choice and choice.source
        result.priceFreshness = choice and choice.freshness
        return result
    end

    if sourceType == "limited_vendor" then
        result.goldCost = nonNegative(entry.purchasePrice or entry.goldCost)
        result.marketCost = nonNegative(entry.marketCost) or result.goldCost
        return fail(result, "conditional", "limited_stock_not_guaranteed")
    end
    if sourceType == "quest" then return fail(result, "conditional", "quest_requirement") end
    if sourceType == "drop" or sourceType == "world_drop" then return fail(result, "conditional", "drop_not_guaranteed") end
    if sourceType == "manual" or sourceType == "other" then return fail(result, "unavailable_unknown", "manual_acquisition_required") end
    return fail(result, "unavailable_unknown", "unknown_acquisition")
end

local function auctionAlternative(entry, spellID, state, skillContext, options)
    local itemID = positive(entry.recipeItemID or entry.itemID)
    if not itemID then return nil end

    local probe = resultBase(entry, spellID)
    local requirementsOK, requirementReason = passesRequirements(entry, probe, state, skillContext, options)
    local result = resultBase(entry, spellID)
    result.sourceType = "auction"
    result.source = "auction"
    result.sourceName = "Auction House"
    result.sourceID = nil
    result.recipeItemID = itemID
    result.requiredSkill = probe.requiredSkill
    result.effectiveSkill = probe.effectiveSkill
    result.requiredLevel = probe.requiredLevel
    if not requirementsOK then return fail(result, "unavailable", requirementReason) end

    local cost, reason, choice = currentAuctionCost(itemID, options)
    if not cost then return fail(result, "unavailable", reason or "recipe_item_not_currently_listed") end
    result.available, result.reliable, result.immediate = true, true, true
    result.goldCost, result.marketCost, result.state = cost, cost, "purchasable_now"
    result.priceSource = choice and choice.source
    result.priceFreshness = choice and choice.freshness
    return result
end

local function candidateCost(candidate)
    return tonumber(candidate.goldCost) or tonumber(candidate.marketCost) or math.huge
end

local function candidateRank(candidate)
    if candidate.sourceType == "learned" or candidate.sourceType == "simulated_learned" then return 0 end
    if candidate.sourceType == "owned_recipe_item" then return 1 end
    if candidate.sourceType == "trainer" then return 2 end
    if candidate.sourceType == "vendor" or candidate.sourceType == "reputation" then return 3 end
    if candidate.sourceType == "auction" then return 4 end
    return 9
end

local function chooseReliable(candidates)
    local best
    for index = 1, table.getn(candidates) do
        local candidate = candidates[index]
        if candidate.available and candidate.reliable then
            if not best
                or candidateCost(candidate) < candidateCost(best)
                or (candidateCost(candidate) == candidateCost(best) and candidateRank(candidate) < candidateRank(best))
            then
                best = candidate
            end
        end
    end
    return best
end

function addonTable.resolveRecipeAcquisitionPaths(recipeOrSpellID, state, skillContext, options)
    state = state or {}
    options = options or {}

    local recipe
    local spellID
    if type(recipeOrSpellID) == "table" then
        recipe = recipeOrSpellID
        spellID = positive(recipe.spellID or recipe.recipeID)
    else
        spellID = positive(recipeOrSpellID)
    end

    local key = spellID and ("recipe:" .. tostring(spellID)) or nil
    if learnedInState(spellID, state) then
        return {{
            handled = true,
            spellID = spellID,
            key = key,
            sourceType = "learned",
            source = "learned",
            sourceName = "Already learned",
            available = true,
            reliable = true,
            alreadyAcquired = true,
            immediate = true,
            requiresLearning = false,
            goldCost = 0,
            marketCost = 0,
            state = "immediately_usable",
        }}
    end

    if acquiredInRoute(spellID, state) then
        return {{
            handled = true,
            spellID = spellID,
            key = key,
            sourceType = "simulated_learned",
            source = "simulated_learned",
            sourceName = "Already acquired in route",
            available = true,
            reliable = true,
            alreadyAcquired = true,
            immediate = true,
            requiresLearning = false,
            goldCost = 0,
            marketCost = 0,
            state = "immediately_usable",
        }}
    end

    local records = addonTable.getRecipeAcquisitionRecords(spellID)
    if table.getn(records) == 0 and recipe then
        local inline = normalizeInline(recipe)
        if inline then records = { inline } end
    end

    if table.getn(records) == 0 then
        return {{
            handled = true,
            spellID = spellID,
            key = key,
            sourceType = "unknown",
            source = "unknown",
            available = false,
            reliable = false,
            alreadyAcquired = false,
            immediate = false,
            requiresLearning = true,
            state = "unavailable_unknown",
            reason = "missing_acquisition_metadata",
        }}
    end

    local candidates = {}
    local seenOwnedItems = {}
    local seenAuctionItems = {}

    for index = 1, table.getn(records) do
        local entry = records[index]
        local itemID = positive(entry.recipeItemID or entry.itemID)

        if itemID and inventoryCount(itemID, state) > 0 and not seenOwnedItems[itemID] then
            local owned = resultBase(entry, spellID)
            owned.sourceType, owned.source, owned.sourceName = "owned_recipe_item", "owned_recipe_item", "Recipe item already owned"
            owned.recipeItemID = itemID
            local requirementsOK, requirementReason = passesRequirements(entry, owned, state, skillContext, options)
            if requirementsOK then
                owned.available, owned.reliable, owned.immediate = true, true, true
                owned.goldCost, owned.marketCost, owned.state = 0, 0, "recipe_item_owned"
            else
                fail(owned, "unavailable", requirementReason)
            end
            table.insert(candidates, owned)
            seenOwnedItems[itemID] = true
        end

        table.insert(candidates, evaluateStaticEntry(entry, spellID, state, skillContext, options))

        if itemID and not seenAuctionItems[itemID] then
            local auction = auctionAlternative(entry, spellID, state, skillContext, options)
            if auction then table.insert(candidates, auction) end
            seenAuctionItems[itemID] = true
        end
    end

    return candidates
end

function addonTable.resolveRecipeAcquisition(recipeOrSpellID, state, skillContext, options)
    local candidates = addonTable.resolveRecipeAcquisitionPaths(recipeOrSpellID, state, skillContext, options)
    local best = chooseReliable(candidates)
    if best then
        best.alternatives = candidates
        best.chosen = true
        return best
    end

    local fallback = candidates[1] or {
        handled = true,
        sourceType = "unknown",
        source = "unknown",
        available = false,
        reliable = false,
        state = "unavailable_unknown",
        reason = "missing_acquisition_metadata",
    }
    fallback.alternatives = candidates
    fallback.chosen = false
    return fallback
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
        locations = result.locations,
        faction = result.faction,
        reputation = result.reputation,
        recipeItemID = result.recipeItemID,
        purchasePrice = result.goldCost,
        limitedStock = result.limitedStock,
        requiresLearning = result.requiresLearning,
        reliable = result.reliable,
        alternatives = result.alternatives,
        notes = result.notes,
    }
end
