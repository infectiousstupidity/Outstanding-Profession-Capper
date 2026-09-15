local addonName, addonTable = ...

local enabled = false
local currentRefresh
local lastRefresh
local professionClosed = true
local lastProviderRevision
local lastCompletedRequestCount = 0

local function newTotals()
    return {
        refreshRequests = 0,
        refreshes = 0,
        reasons = {},
        counters = {},
        phases = {},
        caches = {},
    }
end

local totals = newTotals()

local function addNumber(target, key, amount)
    target[key] = (tonumber(target[key]) or 0) + (tonumber(amount) or 0)
end

local function nowMilliseconds()
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

local function memoryKilobytes()
    if type(collectgarbage) ~= "function" then
        return nil
    end

    local ok, value = pcall(collectgarbage, "count")
    if ok and tonumber(value) then
        return tonumber(value)
    end
    return nil
end

local function packed(...)
    return {
        n = select("#", ...),
        ...,
    }
end

local function unpackPacked(values, first)
    return unpack(values, first or 1, values.n)
end

local function clone(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local result = {}
    seen[value] = result
    for key, item in pairs(value) do
        result[clone(key, seen)] = clone(item, seen)
    end
    return result
end

local function cacheHits(record, name)
    local cache = record and record.caches and record.caches[name]
    return cache and tonumber(cache.hits) or 0
end

local function classifyRefresh(record)
    local reason = tostring(record and record.reason or "DIRECT")

    if reason == "BAG_UPDATE" then
        return "bag_update"
    elseif reason == "LEARNED_SPELL_IN_TAB" then
        return "learned_recipe"
    elseif reason == "MULTIPLE_EVENTS" then
        return "multiple_event_refresh"
    elseif reason == "MODE_CHANGE" then
        return "mode_change"
    end

    if record and record.providerRevisionChanged then
        return "price_provider_revision_change"
    end

    if record and record.closedBefore then
        if cacheHits(record, "recommendation") > 0 then
            return "warm_reopen_cache_hit"
        end
        return "cold_profession_open"
    end

    if reason == "TRADE_SKILL_UPDATE"
        or reason == "PLAYER_EQUIPMENT_CHANGED"
        or reason == "UNIT_AURA"
    then
        return "skill_or_profession_change"
    end

    return "direct_refresh"
end

function addonTable.setPerformanceEnabled(value)
    enabled = value and true or false
    if not enabled then
        currentRefresh = nil
    end
    return enabled
end

function addonTable.isPerformanceEnabled()
    return enabled
end

function addonTable.resetPerformance()
    local keepEnabled = enabled
    currentRefresh = nil
    lastRefresh = nil
    professionClosed = true
    lastProviderRevision = nil
    lastCompletedRequestCount = 0
    totals = newTotals()
    enabled = keepEnabled
end

function addonTable.performanceMarkProfessionClosed()
    if enabled then
        professionClosed = true
    end
end

function addonTable.performanceRecordRefreshRequest(reason)
    if not enabled then
        return
    end

    reason = tostring(reason or "UNKNOWN")
    totals.refreshRequests = totals.refreshRequests + 1
    addNumber(totals.reasons, reason, 1)
end

function addonTable.beginPerformanceRefresh(reason, metadata)
    if not enabled then
        return nil
    end

    if currentRefresh then
        addNumber(currentRefresh.counters, "overlapping_refresh_attempts", 1)
        addNumber(totals.counters, "overlapping_refresh_attempts", 1)
        return nil
    end

    metadata = metadata or {}
    local providerRevision = metadata.providerRevision ~= nil
        and tostring(metadata.providerRevision)
        or nil
    local providerRevisionChanged = providerRevision ~= nil
        and lastProviderRevision ~= nil
        and providerRevision ~= lastProviderRevision

    local requestCount = totals.refreshRequests
    local record = {
        reason = tostring(reason or "DIRECT"),
        metadata = clone(metadata),
        startedAtMs = nowMilliseconds(),
        memoryBeforeKb = memoryKilobytes(),
        phases = {},
        counters = {},
        caches = {},
        values = {},
        closedBefore = professionClosed,
        providerRevisionChanged = providerRevisionChanged and true or false,
        requestCount = requestCount,
        requestsSincePreviousRefresh = math.max(0, requestCount - lastCompletedRequestCount),
    }

    if providerRevision then
        lastProviderRevision = providerRevision
    end

    professionClosed = false
    totals.refreshes = totals.refreshes + 1
    record.refreshNumber = totals.refreshes
    currentRefresh = record
    return record
end

function addonTable.endPerformanceRefresh(token, extra)
    if not enabled or not token or currentRefresh ~= token then
        return nil
    end

    local record = currentRefresh
    local finishedAt = nowMilliseconds()
    record.totalMs = math.max(0, finishedAt - (tonumber(record.startedAtMs) or finishedAt))
    record.memoryAfterKb = memoryKilobytes()
    if record.memoryBeforeKb and record.memoryAfterKb then
        record.memoryDeltaKb = record.memoryAfterKb - record.memoryBeforeKb
    end

    for key, value in pairs(extra or {}) do
        record[key] = value
    end

    record.category = classifyRefresh(record)
    lastCompletedRequestCount = record.requestCount or lastCompletedRequestCount
    lastRefresh = record
    currentRefresh = nil
    return clone(record)
end

function addonTable.measurePerformance(name, callback, ...)
    if type(callback) ~= "function" then
        error("performance measurement callback must be a function")
    end

    if not enabled or not currentRefresh then
        return callback(...)
    end

    local startedAt = nowMilliseconds()
    local results = packed(pcall(callback, ...))
    local elapsed = math.max(0, nowMilliseconds() - startedAt)

    addNumber(currentRefresh.phases, tostring(name or "unnamed"), elapsed)
    addNumber(totals.phases, tostring(name or "unnamed"), elapsed)

    if not results[1] then
        addNumber(currentRefresh.counters, "failed_measured_operations", 1)
        addNumber(totals.counters, "failed_measured_operations", 1)
        error(results[2], 0)
    end

    return unpackPacked(results, 2)
end

function addonTable.measurePerformanceRefresh(reason, metadata, callback, ...)
    if type(callback) ~= "function" then
        error("performance refresh callback must be a function")
    end

    if not enabled then
        return callback(...)
    end

    local token = addonTable.beginPerformanceRefresh(reason, metadata)
    if not token then
        return addonTable.measurePerformance("nested_refresh", callback, ...)
    end

    local results = packed(pcall(callback, ...))
    addonTable.endPerformanceRefresh(token, {
        success = results[1] and true or false,
        error = results[1] and nil or tostring(results[2]),
    })

    if not results[1] then
        error(results[2], 0)
    end

    return unpackPacked(results, 2)
end

function addonTable.performanceIncrement(name, amount)
    if not enabled or not currentRefresh then
        return
    end

    name = tostring(name or "unnamed")
    amount = tonumber(amount) or 1
    addNumber(currentRefresh.counters, name, amount)
    addNumber(totals.counters, name, amount)
end

function addonTable.performanceCache(name, hit)
    if not enabled or not currentRefresh then
        return
    end

    name = tostring(name or "unnamed")
    local key = hit and "hits" or "misses"

    currentRefresh.caches[name] = currentRefresh.caches[name] or {
        hits = 0,
        misses = 0,
    }
    totals.caches[name] = totals.caches[name] or {
        hits = 0,
        misses = 0,
    }

    addNumber(currentRefresh.caches[name], key, 1)
    addNumber(totals.caches[name], key, 1)
end

function addonTable.performanceSet(name, value)
    if not enabled or not currentRefresh then
        return
    end

    currentRefresh.values[tostring(name or "unnamed")] = value
end

function addonTable.getPerformanceSnapshot()
    return {
        enabled = enabled,
        active = currentRefresh ~= nil,
        current = clone(currentRefresh),
        last = clone(lastRefresh),
        totals = clone(totals),
    }
end

local CATEGORY_LABELS = {
    bag_update = "bag update",
    cold_profession_open = "cold profession open",
    direct_refresh = "direct refresh",
    learned_recipe = "learned recipe",
    mode_change = "mode change",
    multiple_event_refresh = "multiple events",
    price_provider_revision_change = "price-provider revision change",
    skill_or_profession_change = "skill/profession change",
    warm_reopen_cache_hit = "warm reopen / cache hit",
}

local PHASE_ORDER = {
    { "with_unfiltered_trade_skill", "scan" },
    { "build_recipe_cache", "recipe-cache" },
    { "optimizer_input", "input" },
    { "generated_candidate_index_build", "gen-index" },
    { "candidate_index", "candidates" },
    { "current_candidate_ranking", "rank" },
    { "route_solver", "route" },
    { "shopping_plan", "shopping" },
    { "ui_render_update", "ui" },
}

local LARGEST_PHASE_EXCLUDED = {
    with_unfiltered_trade_skill = true,
}

local function formatMilliseconds(value)
    return string.format("%.1fms", tonumber(value) or 0)
end

local function formatMemoryDelta(value)
    if value == nil then
        return "n/a"
    end
    return string.format("%+.0fKB", tonumber(value) or 0)
end

local function largestPhase(record)
    local bestName
    local bestValue = -1

    for name, value in pairs(record.phases or {}) do
        value = tonumber(value) or 0
        if not LARGEST_PHASE_EXCLUDED[name] and value > bestValue then
            bestName = name
            bestValue = value
        end
    end

    return bestName or "none", math.max(0, bestValue)
end

local function cachePair(record, name)
    local cache = record.caches and record.caches[name] or {}
    return tostring(tonumber(cache.hits) or 0) .. "/" .. tostring(tonumber(cache.misses) or 0)
end

function addonTable.getPerformanceSummaryLines()
    local lines = {}

    if not enabled then
        table.insert(lines, "instrumentation disabled; use /pcapper perf on")
    end

    local record = lastRefresh
    if not record then
        table.insert(lines, "no refresh captured yet")
        table.insert(lines, "requests=" .. tostring(totals.refreshRequests)
            .. " expensive-refreshes=" .. tostring(totals.refreshes))
        return lines
    end

    local metadata = record.metadata or {}
    local largestName, largestValue = largestPhase(record)
    local category = CATEGORY_LABELS[record.category] or tostring(record.category or "refresh")
    local profession = tostring(metadata.profession or "unknown")
    local baseSkill = metadata.baseSkill ~= nil and tostring(metadata.baseSkill) or "?"
    local mode = tostring(metadata.mode or "unknown")
    local revisionFlag = record.providerRevisionChanged and " price-revision=changed" or ""

    table.insert(lines, category
        .. " | reason=" .. tostring(record.reason)
        .. " | " .. profession .. " " .. baseSkill
        .. " | mode=" .. mode
        .. revisionFlag)

    table.insert(lines, "total=" .. formatMilliseconds(record.totalMs)
        .. " | largest=" .. largestName .. " " .. formatMilliseconds(largestValue)
        .. " | memory=" .. formatMemoryDelta(record.memoryDeltaKb)
        .. " | requests-since-last=" .. tostring(record.requestsSincePreviousRefresh or 0))

    local phaseParts = {}
    for i = 1, table.getn(PHASE_ORDER) do
        local name = PHASE_ORDER[i][1]
        local label = PHASE_ORDER[i][2]
        local value = tonumber(record.phases and record.phases[name])
        if value and value > 0 then
            table.insert(phaseParts, label .. "=" .. formatMilliseconds(value))
        end
    end
    table.insert(lines, table.getn(phaseParts) > 0
        and table.concat(phaseParts, " ")
        or "phases: none recorded")

    table.insert(lines, "states=" .. tostring(record.values and record.values.route_explored_states or 0)
        .. " recipe-costs=" .. tostring(record.counters and record.counters.recipe_cost_evaluations or 0)
        .. " unique-prices=" .. tostring(record.counters and record.counters.unique_price_lookups or 0)
        .. " book-scans=" .. tostring(record.counters and record.counters.profession_book_full_scans or 0)
        .. " live-refresh=" .. tostring(record.counters and record.counters.profession_book_live_refreshes or 0)
        .. " | cache h/m book=" .. cachePair(record, "profession_book")
        .. " rec=" .. cachePair(record, "recommendation")
        .. " canonical=" .. cachePair(record, "canonical_recipe")
        .. " inventory=" .. cachePair(record, "inventory")
        .. " provider-price=" .. cachePair(record, "provider_price")
        .. " gen-index=" .. cachePair(record, "generated_candidate_index")
        .. " price=" .. cachePair(record, "price")
        .. " recipe=" .. cachePair(record, "recipe_cost")
        .. " material=" .. cachePair(record, "material_cost"))

    table.insert(lines, "accumulated requests=" .. tostring(totals.refreshRequests)
        .. " expensive-refreshes=" .. tostring(totals.refreshes)
        .. " | BAG_UPDATE=" .. tostring(totals.reasons.BAG_UPDATE or 0)
        .. " TRADE_SKILL_UPDATE=" .. tostring(totals.reasons.TRADE_SKILL_UPDATE or 0)
        .. " LEARNED_SPELL_IN_TAB=" .. tostring(totals.reasons.LEARNED_SPELL_IN_TAB or 0))

    return lines
end
