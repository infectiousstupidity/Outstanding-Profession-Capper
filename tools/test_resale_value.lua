local addonTable = {}

assert(loadfile("PriceProvider.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format(
            "%s: expected %s, got %s",
            label,
            tostring(expected),
            tostring(actual)
        ))
    end
end

local function assertNear(actual, expected, tolerance, label)
    if not actual or math.abs(actual - expected) > tolerance then
        error(string.format(
            "%s: expected %s +/- %s, got %s",
            label,
            tostring(expected),
            tostring(tolerance),
            tostring(actual)
        ))
    end
end

local function resale(raw, now)
    local normalized = addonTable.normalizePriceResult(
        50000,
        raw,
        "fixture",
        now
    )
    return addonTable.evaluateResaleValue(normalized)
end

local freshBoth = resale({
    minBuyout = 90,
    marketValue = 100,
    recentValue = 110,
    historicalValue = 130,
    numAuctions = 1,
    updatedAt = 99000,
}, 100000)
assertEqual(freshBoth.estimatedResaleValue, 90, "market/min estimate uses lower value")
assertEqual(freshBoth.optimizationCredit, 90, "market/min credit")
assertEqual(freshBoth.creditGranted, true, "market/min credit granted")
assertEqual(freshBoth.sourcePriceType, "market_capped_by_min_buyout", "market/min source type")
assertEqual(freshBoth.confidence, "two_current_sources", "market/min evidence confidence")
assertEqual(freshBoth.reason, "fresh_market_capped_by_min_buyout", "market/min reason")
assertEqual(freshBoth.beforeAuctionHouseFees, true, "estimate is before AH fees")
assertEqual(freshBoth.auctionHouseFeeApplied, false, "unverified AH fee not applied")

local manyAuctions = resale({
    minBuyout = 90,
    marketValue = 100,
    numAuctions = 99999,
    updatedAt = 99000,
}, 100000)
assertEqual(manyAuctions.optimizationCredit, freshBoth.optimizationCredit, "auction count does not change credit")
assertEqual(manyAuctions.confidence, freshBoth.confidence, "auction count does not change confidence")

local freshMin = resale({
    minBuyout = 80,
    updatedAt = 99000,
}, 100000)
assertEqual(freshMin.estimatedResaleValue, 80, "fresh min-buyout estimate")
assertEqual(freshMin.optimizationCredit, 80, "fresh min-buyout credit")
assertEqual(freshMin.sourcePriceType, "min_buyout", "fresh min-buyout source")
assertEqual(freshMin.confidence, "single_current_source", "fresh min-buyout confidence")
assertEqual(freshMin.reason, "fresh_min_buyout", "fresh min-buyout reason")

local freshMarket = resale({
    marketValue = 85,
    updatedAt = 99000,
}, 100000)
assertEqual(freshMarket.optimizationCredit, 85, "fresh market-only credit")
assertEqual(freshMarket.reason, "fresh_market_value", "fresh market-only reason")

local stale = resale({
    minBuyout = 80,
    marketValue = 100,
    updatedAt = 74800,
}, 100000)
assertEqual(stale.isStale, true, "stale evidence state")
assertEqual(stale.isTooOld, false, "stale evidence is not too old")
assertEqual(stale.estimatedResaleValue, 80, "stale estimate remains context")
assertEqual(stale.optimizationCredit, 0, "stale evidence grants no credit")
assertEqual(stale.reason, "stale_price", "stale reason")

local tooOld = resale({
    minBuyout = 80,
    marketValue = 100,
    updatedAt = 100000,
}, 400000)
assertEqual(tooOld.isTooOld, true, "too-old evidence state")
assertEqual(tooOld.optimizationCredit, 0, "too-old evidence grants no credit")
assertEqual(tooOld.reason, "price_too_old", "too-old reason")

local suspiciousLow = resale({
    minBuyout = 10,
    marketValue = 100,
    updatedAt = 99000,
    isSuspicious = true,
    suspiciousReason = "min_buyout_far_below_market",
    marketRatio = 0.1,
}, 100000)
assertEqual(suspiciousLow.optimizationCredit, 0, "suspicious low ratio grants no credit")
assertEqual(suspiciousLow.reason, "suspicious_price", "suspicious low reason")
assertEqual(suspiciousLow.suspiciousReason, "min_buyout_far_below_market", "suspicious low detail")
assertNear(suspiciousLow.marketRatio, 0.1, 0.0001, "suspicious low ratio retained")

local suspiciousHigh = resale({
    minBuyout = 1000,
    marketValue = 100,
    updatedAt = 99000,
    isSuspicious = true,
    suspiciousReason = "min_buyout_far_above_market",
    marketRatio = 10,
}, 100000)
assertEqual(suspiciousHigh.optimizationCredit, 0, "suspicious high ratio grants no credit")
assertEqual(suspiciousHigh.reason, "suspicious_price", "suspicious high reason")

local historicalOnly = resale({
    historicalValue = 150,
    updatedAt = 99000,
}, 100000)
assertEqual(historicalOnly.estimatedResaleValue, 150, "historical value exposed as context")
assertEqual(historicalOnly.optimizationCredit, 0, "historical-only evidence grants no credit")
assertEqual(historicalOnly.sourcePriceType, "historical", "historical source type")
assertEqual(historicalOnly.confidence, "context_only", "historical confidence")
assertEqual(historicalOnly.reason, "historical_only_context", "historical-only reason")

local recentOnly = resale({
    recentValue = 140,
    historicalValue = 150,
    updatedAt = 99000,
}, 100000)
assertEqual(recentOnly.estimatedResaleValue, 140, "recent value preferred for context")
assertEqual(recentOnly.optimizationCredit, 0, "recent-only evidence grants no credit")
assertEqual(recentOnly.sourcePriceType, "recent", "recent context source")
assertEqual(recentOnly.reason, "recent_only_context", "recent-only reason")

local missing = resale({}, 100000)
assertEqual(missing.estimatedResaleValue, nil, "missing estimate")
assertEqual(missing.optimizationCredit, 0, "missing evidence grants zero credit")
assertEqual(missing.reason, "no_price_data", "missing-data reason")
assertEqual(missing.confidence, "none", "missing confidence")

local unknownFreshness = resale({
    minBuyout = 80,
    marketValue = 100,
}, 100000)
assertEqual(unknownFreshness.optimizationCredit, 0, "unknown freshness grants no credit")
assertEqual(unknownFreshness.reason, "freshness_unknown", "unknown freshness reason")

local nan = 0 / 0
local invalidNumbers = addonTable.evaluateResaleValue({
    available = true,
    marketValue = nan,
    minBuyout = -5,
    recentValue = 0,
    historicalValue = math.huge,
    freshness = "fresh",
    isFresh = true,
    isStale = false,
    isTooOld = false,
    isSuspicious = false,
})
assertEqual(invalidNumbers.estimatedResaleValue, nil, "invalid numbers are not estimates")
assertEqual(invalidNumbers.optimizationCredit, 0, "invalid numbers grant zero credit")
assertEqual(invalidNumbers.reason, "no_resale_price_evidence", "invalid-number reason")
assert(invalidNumbers.optimizationCredit == invalidNumbers.optimizationCredit, "credit is never NaN")
assert(invalidNumbers.optimizationCredit >= 0, "credit is never negative")

local revision = 1
local providerCalls = 0
local providerPrice = 75
local revisionedProvider = {
    getRevision = function()
        return revision
    end,
    getItemPrice = function(self, item)
        providerCalls = providerCalls + 1
        return {
            item = item,
            minBuyout = providerPrice,
            updatedAt = 99000,
            source = "revisioned-fixture",
        }
    end,
}

assert(addonTable.registerPriceProvider("resale-revisioned", revisionedProvider, 100))
assert(addonTable.selectPriceProvider("resale-revisioned"))
addonTable.resetPriceCache()

local cachedOne = addonTable.lookupItemResaleValue(777, 100000)
local cachedTwo = addonTable.lookupItemResaleValue(777, 100000)
assertEqual(cachedOne.optimizationCredit, 75, "first cached resale credit")
assertEqual(cachedTwo.optimizationCredit, 75, "repeated cached resale credit")
assertEqual(providerCalls, 1, "resale lookup reuses existing provider cache")

revision = 2
providerPrice = 95
local revised = addonTable.lookupItemResaleValue(777, 100000)
assertEqual(revised.optimizationCredit, 95, "provider revision changes resale evidence")
assertEqual(providerCalls, 2, "provider revision naturally rekeys existing cache")

local stats = addonTable.getPriceCacheStats()
assert(stats.entries <= stats.maxEntries, "resale lookups remain inside existing bounded price cache")

print("Conservative resale valuation tests passed.")
