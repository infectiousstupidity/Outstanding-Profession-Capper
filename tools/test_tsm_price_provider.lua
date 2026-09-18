local addonTable = {}

assert(loadfile("PriceProvider.lua"))("Profession_Capper", addonTable)
assert(loadfile("TSMPriceProvider.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function assertNear(actual, expected, tolerance, label)
    if not actual or math.abs(actual - expected) > tolerance then
        error(string.format("%s: expected %s +/- %s, got %s", label, expected, tolerance, tostring(actual)))
    end
end

local function clearTSM()
    TSM_API = nil
    TSM_AuctionDB_GetRealmData = nil
    TSM_AuctionDB = nil
    GetRealmName = nil
    UnitFactionGroup = nil
    GetAddOnMetadata = nil
    GetTime = nil
end

clearTSM()
assertEqual(addonTable.getActivePriceProviderName(), "null", "TSM absent falls back to null")

GetAddOnMetadata = function(addon, key)
    if addon == "TradeSkillMaster_AuctionDB" and key == "Version" then
        return "v4.14.66-wrath"
    end
end

local realmData = {
    ["i:34054"] = {
        mb = 100,
        mv = 110,
        na = 7,
        ts = 99000,
        mkt = 125,
        hist = 140,
    },
}
TSM_AuctionDB_GetRealmData = function()
    return realmData
end

local monotonicNow = 1000
GetTime = function()
    return monotonicNow
end

assertEqual(addonTable.getActivePriceProviderName(), "tsm-auctiondb", "raw AuctionDB provider selected")
assertEqual(addonTable.getActivePriceProviderRevision(), nil, "AuctionDB v4 has no realm-wide revision")
local raw = addonTable.lookupItemPrice(34054, 100000)
assertEqual(raw.available, true, "raw price available")
assertEqual(raw.minBuyout, 100, "raw min buyout")
assertEqual(raw.marketValue, 125, "raw DBMarket")
assertEqual(raw.historicalValue, 140, "raw DBHistorical")
assertEqual(raw.recentValue, 110, "raw DBRecent")
assertEqual(raw.numAuctions, 7, "raw auction count")
assertEqual(raw.updatedAt, 99000, "raw last scan")
assertEqual(raw.ageSeconds, 1000, "raw scan age")
assertEqual(raw.freshness, "fresh", "raw freshness")
assertEqual(raw.providerVersion, "v4.14.66-wrath", "raw provider version")
assertEqual(raw.providerBackend, "AuctionDB API", "raw backend")

local cacheStats = addonTable.getPriceCacheStats()
assertEqual(cacheStats.unknownRevisionTTL, 15, "unknown-revision cache TTL")
realmData["i:34054"].mb = 95
monotonicNow = 1010
local withinTTL = addonTable.lookupItemPrice(34054, 100000)
assertEqual(withinTTL.minBuyout, 100, "unknown-revision cache reused within TTL")
monotonicNow = 1016
local afterTTL = addonTable.lookupItemPrice(34054, 100000)
assertEqual(afterTTL.minBuyout, 95, "unknown-revision cache refreshes after TTL")
realmData["i:34054"].mb = 100

addonTable.resetPriceCache()
TSM_API = {
    ToItemString = function(item)
        if string.find(item, "34054", 1, true) then
            return "i:34054"
        end
    end,
    GetCustomPriceValue = function(source, itemString)
        assertEqual(itemString, "i:34054", "public item string")
        local values = {
            DBMinBuyout = 200,
            DBMarket = 250,
            DBHistorical = 300,
            DBRecent = 225,
        }
        return values[source]
    end,
}

local public = addonTable.lookupItemPrice("|Hitem:34054:0:0:0:0:0:0:0|h[Infinite Dust]|h", 100000)
assertEqual(public.minBuyout, 200, "public min buyout wins")
assertEqual(public.marketValue, 250, "public market wins")
assertEqual(public.historicalValue, 300, "public historical wins")
assertEqual(public.recentValue, 225, "public recent wins")
assertEqual(public.updatedAt, 99000, "public result keeps raw scan timestamp")
assertEqual(public.providerBackend, "TSM_API + AuctionDB API", "combined backend")

addonTable.resetPriceCache()
TSM_API.GetCustomPriceValue = function(source)
    if source == "DBMinBuyout" then
        return 1000
    elseif source == "DBMarket" then
        return 100
    end
    return nil
end

local suspiciousHigh = addonTable.lookupItemPrice(34054, 100000)
assertEqual(suspiciousHigh.isSuspicious, true, "high outlier flagged")
assertEqual(suspiciousHigh.suspiciousReason, "min_buyout_far_above_market", "high outlier reason")
assertNear(suspiciousHigh.marketRatio, 10, 0.0001, "high outlier ratio")
assertEqual(suspiciousHigh.minBuyout, 1000, "high outlier raw buyout preserved")
assertEqual(suspiciousHigh.marketValue, 100, "high outlier market preserved")

addonTable.resetPriceCache()
TSM_API.GetCustomPriceValue = function(source)
    if source == "DBMinBuyout" then
        return 10
    elseif source == "DBMarket" then
        return 100
    end
    return nil
end

local suspiciousLow = addonTable.lookupItemPrice(34054, 100000)
assertEqual(suspiciousLow.isSuspicious, true, "low outlier flagged")
assertEqual(suspiciousLow.suspiciousReason, "min_buyout_far_below_market", "low outlier reason")
assertNear(suspiciousLow.marketRatio, 0.1, 0.0001, "low outlier ratio")

addonTable.resetPriceCache()
TSM_API.GetCustomPriceValue = function()
    error("broken TSM API")
end

local fallback = addonTable.lookupItemPrice(34054, 100000)
assertEqual(fallback.available, true, "public API failure falls back to raw record")
assertEqual(fallback.minBuyout, 100, "raw buyout after public API failure")
assertEqual(fallback.marketValue, 125, "raw market after public API failure")

TSM_API = nil
TSM_AuctionDB_GetRealmData = nil
GetRealmName = function()
    return "ChromieCraft"
end
UnitFactionGroup = function()
    return "Horde"
end
TSM_AuctionDB = {
    realms = {
        ["Horde - ChromieCraft"] = {
            ["i:34054"] = {
                mb = 90,
                mkt = 120,
                hist = 135,
                ts = 50000,
            },
        },
    },
}
addonTable.resetPriceCache()

local saved = addonTable.lookupItemPrice("34054", 100000)
assertEqual(saved.minBuyout, 90, "SavedVariables fallback buyout")
assertEqual(saved.marketValue, 120, "SavedVariables fallback market")
assertEqual(saved.historicalValue, 135, "SavedVariables fallback historical")
assertEqual(saved.providerBackend, "AuctionDB SavedVariables", "SavedVariables backend")
assertEqual(saved.freshness, "stale", "SavedVariables stale state")

TSM_AuctionDB.realms["Horde - ChromieCraft"] = {}
addonTable.resetPriceCache()
local missing = addonTable.lookupItemPrice(34054, 100000)
assertEqual(missing.available, false, "unscanned item unavailable")
assertEqual(missing.unavailableReason, "item_not_scanned", "unscanned reason")

local invalid = addonTable.lookupItemPrice("not-an-item", 100000)
assertEqual(invalid.available, false, "invalid item unavailable")
assertEqual(invalid.unavailableReason, "invalid_item", "invalid item reason")

clearTSM()
assertEqual(addonTable.getActivePriceProviderName(), "null", "provider dynamically returns to null")

print("TSM AuctionDB provider tests passed.")
