local addonName, addonTable = ...

-- Ackis Recipe List v2.01 is compatible with WoW client 30300 and exposes
-- AckisRecipeList:GetRecipeData(). ARL itself is All Rights Reserved, so this
-- adapter only calls its public runtime API. No ARL database/code is vendored.

local ACQUIRE = {
    TRAINER = 1,
    VENDOR = 2,
    MOB_DROP = 3,
    QUEST = 4,
    SEASONAL = 5,
    REPUTATION = 6,
    WORLD_DROP = 7,
    CUSTOM = 8,
}

local TYPE_INFO = {
    [ACQUIRE.TRAINER] = { sourceType = "trainer", priority = 100, label = "trainer" },
    [ACQUIRE.VENDOR] = { sourceType = "vendor", priority = 90, label = "vendor" },
    [ACQUIRE.REPUTATION] = { sourceType = "reputation", priority = 60, label = "reputation" },
    [ACQUIRE.QUEST] = { sourceType = "quest", priority = 50, label = "quest" },
    [ACQUIRE.MOB_DROP] = { sourceType = "drop", priority = 40, label = "mob drop" },
    [ACQUIRE.WORLD_DROP] = { sourceType = "drop", priority = 35, label = "world drop" },
    [ACQUIRE.SEASONAL] = { sourceType = "manual", priority = 20, label = "seasonal" },
    [ACQUIRE.CUSTOM] = { sourceType = "manual", priority = 10, label = "custom" },
}

local provider = {
    name = "Ackis Recipe List",
    priority = 100,
}

local function getARL()
    if type(_G) == "table" and type(_G.AckisRecipeList) == "table" then
        return _G.AckisRecipeList
    end
    return nil
end

function provider:isAvailable()
    local arl = getARL()
    return arl ~= nil and type(arl.GetRecipeData) == "function"
end

local function acquireTable(arl, spellID)
    local value = arl:GetRecipeData(spellID, "acquire_data")
    if type(value) == "table" and type(value.acquire_data) == "table" then
        -- Compatibility with older ARL builds whose public method returns the
        -- whole recipe record and simply ignores the second argument.
        return value.acquire_data
    end
    if type(value) == "table" then
        return value
    end

    local recipe = arl:GetRecipeData(spellID)
    if type(recipe) == "table" then
        return recipe.acquire_data or recipe["acquire_data"]
    end
    return nil
end

local function sourceIDs(info)
    local result = {}
    if type(info) ~= "table" then
        return result
    end

    for key, value in pairs(info) do
        if type(key) == "number" or type(key) == "string" then
            table.insert(result, key)
        elseif type(value) == "number" or type(value) == "string" then
            table.insert(result, value)
        end
    end
    table.sort(result, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return result
end

function provider:getRecipeAcquisition(spellID)
    local arl = getARL()
    if not arl or type(arl.GetRecipeData) ~= "function" then
        return nil
    end

    local data = acquireTable(arl, spellID)
    if type(data) ~= "table" then
        return nil
    end

    local selectedType
    local selected
    for acquireType, info in pairs(data) do
        local typeInfo = TYPE_INFO[tonumber(acquireType)]
        if typeInfo and (not selected or typeInfo.priority > selected.priority) then
            selectedType = tonumber(acquireType)
            selected = typeInfo
        end
    end

    if not selected then
        return nil
    end

    local ids = sourceIDs(data[selectedType])
    return {
        spellID = tonumber(spellID),
        sourceType = selected.sourceType,
        sourceName = "Ackis Recipe List " .. selected.label .. " source",
        provider = provider.name,
        providerPriority = provider.priority,
        providerAcquireType = selectedType,
        providerSourceIDs = ids,
        notes = "Live acquisition classification from Ackis Recipe List runtime data.",
    }
end

addonTable.registerRecipeAcquisitionProvider(provider)

addonTable.ackisRecipeListAcquisitionProvider = provider
