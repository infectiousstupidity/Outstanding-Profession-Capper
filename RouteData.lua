local addonName, addonTable = ...

local candidateIndexCache = {}

local function normalizedModifier(value)
    value = math.floor(tonumber(value) or 0)
    if value < 0 then
        return 0
    end
    return math.min(value, 100)
end

local function addEvents(active, events)
    for index = 1, table.getn(events or {}) do
        active[events[index]] = true
    end
end

local function removeEvents(active, events)
    for index = 1, table.getn(events or {}) do
        active[events[index]] = nil
    end
end

local function snapshot(active)
    local result = {}
    for spellID in pairs(active) do
        table.insert(result, spellID)
    end
    table.sort(result)
    return result
end

local function buildCandidateIndex(profession, modifier)
    local topology = addonTable.generatedRouteTopology
        and addonTable.generatedRouteTopology[profession]
    if type(topology) ~= "table" then
        return {}
    end

    modifier = normalizedModifier(modifier)
    local cacheKey = tostring(profession) .. ":" .. tostring(modifier)
    local cached = candidateIndexCache[cacheKey]
    if cached then
        return cached
    end

    local starts = topology.starts or {}
    local stops = topology.stops or {}
    local active = {}
    local index = {}

    for requiredSkill = 0, modifier do
        addEvents(active, starts[requiredSkill])
    end

    for baseSkill = 0, 449 do
        if baseSkill > 0 then
            addEvents(active, starts[baseSkill + modifier])
        end
        removeEvents(active, stops[baseSkill])
        index[baseSkill] = snapshot(active)
    end

    candidateIndexCache[cacheKey] = index
    return index
end

function addonTable.getGeneratedRouteCandidateIndex(profession, modifier)
    return buildCandidateIndex(profession, modifier)
end

function addonTable.getGeneratedRouteCandidateIDs(profession, baseSkill, modifier)
    local index = buildCandidateIndex(profession, modifier)
    return index[math.max(0, math.floor(tonumber(baseSkill) or 0))] or {}
end

function addonTable.getGeneratedRouteCandidateSet(profession, startSkill, targetSkill, modifier)
    local index = buildCandidateIndex(profession, modifier)
    local first = math.max(0, math.floor(tonumber(startSkill) or 0))
    local last = math.min(449, math.max(first, math.floor(tonumber(targetSkill) or first) - 1))
    local result = {}

    for skill = first, last do
        local candidates = index[skill] or {}
        for candidateIndex = 1, table.getn(candidates) do
            result[candidates[candidateIndex]] = true
        end
    end

    return result
end

function addonTable.clearGeneratedRouteCandidateCache()
    candidateIndexCache = {}
end
