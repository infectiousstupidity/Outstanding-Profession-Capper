local fakeMilliseconds = 0

debugprofilestop = function()
    fakeMilliseconds = fakeMilliseconds + 1
    return fakeMilliseconds
end

local addonTable = {}
assert(loadfile("Performance.lua"))("Profession_Capper", addonTable)

assert(addonTable.isPerformanceEnabled() == false, "instrumentation must default to disabled")

local recommendation = { recipeID = 42 }
local disabledResult = addonTable.measurePerformance("disabled", function()
    return recommendation
end)
assert(disabledResult == recommendation, "disabled instrumentation must preserve recommendation results")
assert(addonTable.getPerformanceSnapshot().last == nil, "disabled instrumentation must not create samples")

addonTable.setPerformanceEnabled(true)
addonTable.performanceRecordRefreshRequest("BAG_UPDATE")
addonTable.performanceRecordRefreshRequest("BAG_UPDATE")

local failed, errorMessage = pcall(function()
    addonTable.measurePerformanceRefresh(
        "BAG_UPDATE",
        {
            profession = "Enchanting",
            baseSkill = 352,
            mode = "cheapest",
            providerRevision = "r1",
        },
        function()
            addonTable.performanceIncrement("unique_price_lookups", 2)
            addonTable.performanceCache("recommendation", false)
            addonTable.performanceSet("route_explored_states", 17)

            addonTable.measurePerformance("outer", function()
                addonTable.measurePerformance("inner", function()
                    fakeMilliseconds = fakeMilliseconds + 3
                end)
                error("expected measured failure")
            end)
        end
    )
end)

assert(failed == false, "failed measured operation must still propagate its error")
assert(string.find(tostring(errorMessage), "expected measured failure", 1, true), "expected error text")

local failedSnapshot = addonTable.getPerformanceSnapshot()
assert(failedSnapshot.active == false, "failed refresh must not leave instrumentation active")
assert(failedSnapshot.last ~= nil, "failed refresh must still be finalized")
assert(failedSnapshot.last.success == false, "failed refresh must be marked unsuccessful")
assert(failedSnapshot.last.reason == "BAG_UPDATE", "refresh reason must be explicit")
assert(failedSnapshot.last.category == "bag_update", "bag refresh must be classified explicitly")
assert(failedSnapshot.last.requestsSincePreviousRefresh == 2, "event amplification must be visible")
assert((failedSnapshot.last.phases.outer or 0) > 0, "outer timing must be recorded")
assert((failedSnapshot.last.phases.inner or 0) > 0, "nested timing must be recorded")
assert((failedSnapshot.last.counters.failed_measured_operations or 0) == 1, "failed nested operation counter")
assert((failedSnapshot.last.counters.unique_price_lookups or 0) == 2, "custom counter must survive failure")
assert(failedSnapshot.last.values.route_explored_states == 17, "recorded values must survive failure")

addonTable.resetPerformance()
local resetSnapshot = addonTable.getPerformanceSnapshot()
assert(resetSnapshot.enabled == true, "reset must preserve enabled state")
assert(resetSnapshot.last == nil, "reset must clear the last sample")
assert(resetSnapshot.totals.refreshRequests == 0, "reset must clear counters")
assert(resetSnapshot.totals.refreshes == 0, "reset must clear refresh totals")

addonTable.performanceRecordRefreshRequest("TRADE_SKILL_UPDATE")
local first, middle, last = addonTable.measurePerformanceRefresh(
    "TRADE_SKILL_UPDATE",
    {
        profession = "Enchanting",
        baseSkill = 352,
        mode = "cheapest",
        providerRevision = "r1",
    },
    function()
        addonTable.performanceCache("recommendation", true)
        return "first", nil, "last"
    end
)
assert(first == "first" and middle == nil and last == "last", "measured refresh must preserve nil return values")

local warm = addonTable.getPerformanceSnapshot().last
assert(warm.category == "warm_reopen_cache_hit", "closed profession plus recommendation hit must be a warm reopen")
assert(warm.reason == "TRADE_SKILL_UPDATE", "warm reopen reason must remain explicit")

addonTable.performanceRecordRefreshRequest("TRADE_SKILL_UPDATE")
addonTable.measurePerformanceRefresh(
    "TRADE_SKILL_UPDATE",
    {
        profession = "Enchanting",
        baseSkill = 353,
        mode = "cheapest",
        providerRevision = "r2",
    },
    function()
        addonTable.performanceCache("recommendation", false)
    end
)

local revised = addonTable.getPerformanceSnapshot().last
assert(revised.providerRevisionChanged == true, "provider revision changes must be detected")
assert(revised.category == "price_provider_revision_change", "provider revision refresh must be classified")

local summary = addonTable.getPerformanceSummaryLines()
assert(type(summary) == "table" and table.getn(summary) >= 4, "summary must include recent and accumulated data")

addonTable.resetPerformance()
assert(addonTable.getPerformanceSnapshot().last == nil, "second reset must clear last sample")

print("Performance instrumentation tests passed")
