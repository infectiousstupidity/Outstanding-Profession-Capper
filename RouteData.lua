local addonName, addonTable = ...

local candidateIndexCache = {}
local candidateIndexOrder = {}
local candidateIndexHead = 1
local candidateIndexTail = 0
local candidateIndexEntries = 0
local CANDIDATE_INDEX_CACHE_MAX_ENTRIES = 16

local function rebuildCandidateIndexOrder()
    local compacted = {}
    local count = 0
    for key in pairs(candidateIndexCache) do
        count = count + 1
        compacted[count] = key
    end
    candidateIndexOrder = compacted
    candidateIndexHead = 1
    candidateIndexTail = count
end

local function storeCandidateIndex(key, index)
    if candidateIndexCache[key] == nil then
        candidateIndexEntries = candidateIndexEntries + 1
    end
    candidateIndexCache[key] = index
    candidateIndexTail = candidateIndexTail + 1
    candidateIndexOrder[candidateIndexTail] = key

    while candidateIndexEntries > CANDIDATE_INDEX_CACHE_MAX_ENTRIES do
        local oldestKey = candidateIndexOrder[candidateIndexHead]
        candidateIndexOrder[candidateIndexHead] = nil
        candidateIndexHead = candidateIndexHead + 1
        if oldestKey and candidateIndexCache[oldestKey] ~= nil then
            candidateIndexCache[oldestKey] = nil
            candidateIndexEntries = candidateIndexEntries - 1
        end
    end

    if candidateIndexTail - candidateIndexHead + 1
        > CANDIDATE_INDEX_CACHE_MAX_ENTRIES * 4
    then
        rebuildCandidateIndexOrder()
    end
end

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
        if type(addonTable.performanceCache) == "function" then
            addonTable.performanceCache("generated_candidate_index", true)
        end
        return cached
    end

    if type(addonTable.performanceCache) == "function" then
        addonTable.performanceCache("generated_candidate_index", false)
    end

    local function constructIndex()
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

        return index
    end

    local index
    if type(addonTable.measurePerformance) == "function" then
        index = addonTable.measurePerformance(
            "generated_candidate_index_build",
            constructIndex
        )
    else
        index = constructIndex()
    end

    storeCandidateIndex(cacheKey, index)
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

function addonTable.getGeneratedRouteCandidateCacheStats()
    return {
        entries = candidateIndexEntries,
        maxEntries = CANDIDATE_INDEX_CACHE_MAX_ENTRIES,
        queueEntries = math.max(0, candidateIndexTail - candidateIndexHead + 1),
        maxQueueEntries = CANDIDATE_INDEX_CACHE_MAX_ENTRIES * 4,
    }
end

function addonTable.clearGeneratedRouteCandidateCache()
    candidateIndexCache = {}
    candidateIndexOrder = {}
    candidateIndexHead = 1
    candidateIndexTail = 0
    candidateIndexEntries = 0
end
