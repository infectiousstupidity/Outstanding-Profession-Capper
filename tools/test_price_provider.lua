local addonTable = {}

assert(loadfile("PriceProvider.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function assertContains(value, expected, label)
    if not value or not string.find(value, expected, 1, true) then
        error(string.format("%s: expected %s to contain %s", label, tostring(value), tostring(expected)))
    end
end

local nullResult = addonTable.lookupItemPrice(34054, 100000)
assertEqual(addonTable.getActivePriceProviderName(), "null", "null provider selected")
assertEqual(nullResult.available, false, "null provider unavailable")
assertEqual(nullResult.unavailableReason, "no_price_provider", "null provider reason")
assertEqual(nullResult.minBuyout, nil, "null buyout is nil")
assertEqual(nullResult.marketValue, nil, "null market is nil")
assertEqual(nullResult.vendorBuyPrice, nil, "null vendor is nil")

local scenario = {
    itemID = 34054,
    minBuyout = 100,
    marketValue = 125,
    vendorBuyPrice = 80,
    updatedAt = 99000,
}

local mockProvider = {
    getItemPrice = function(self, item)
        return {
            item = item,
            itemID = scenario.itemID,
            minBuyout = scenario.minBuyout,
            marketValue = scenario.marketValue,
            vendorBuyPrice = scenario.vendorBuyPrice,
            updatedAt = scenario.updatedAt,
        }
    end,
}

local registered, registerReason = addonTable.registerPriceProvider("mock", mockProvider, 10)
assertEqual(registered, true, "mock provider registered")
assertEqual(registerReason, nil, "mock provider register reason")
assertEqual(addonTable.getActivePriceProviderName(), "mock", "mock auto selected")

local fresh = addonTable.lookupItemPrice("item:34054", 100000)
assertEqual(fresh.available, true, "fresh price available")
assertEqual(fresh.source, "mock", "fresh source")
assertEqual(fresh.itemID, 34054, "fresh item id")
assertEqual(fresh.minBuyout, 100, "fresh buyout")
assertEqual(fresh.marketValue, 125, "fresh market")
assertEqual(fresh.vendorBuyPrice, 80, "fresh vendor")
assertEqual(fresh.freshness, "fresh", "fresh state")
assertEqual(fresh.isFresh, true, "fresh flag")
assertEqual(fresh.ageSeconds, 1000, "fresh age")

local marketChoice, marketReason = addonTable.chooseUsableUnitPrice(fresh, "market")
assertEqual(marketReason, nil, "market choice reason")
assertEqual(marketChoice.unitPrice, 125, "market choice amount")
assertEqual(marketChoice.priceType, "market", "market choice type")

local spendChoice, spendReason = addonTable.chooseUsableUnitPrice(fresh, "spend")
assertEqual(spendReason, nil, "fresh spend reason")
assertEqual(spendChoice.unitPrice, 100, "fresh spend prefers auction")
assertEqual(spendChoice.priceType, "auction", "fresh spend type")

scenario.updatedAt = 1000
addonTable.resetPriceCache()
local stale = addonTable.lookupItemPrice(34054, 100000)
assertEqual(stale.freshness, "stale", "stale state")
assertEqual(stale.isStale, true, "stale flag")
assertEqual(stale.isTooOld, false, "stale still usable")

spendChoice, spendReason = addonTable.chooseUsableUnitPrice(stale, "spend")
assertEqual(spendReason, nil, "stale spend reason")
assertEqual(spendChoice.unitPrice, 80, "stale spend prefers vendor")
assertEqual(spendChoice.priceType, "vendor", "stale spend type")

scenario.updatedAt = 1
scenario.vendorBuyPrice = nil
addonTable.resetPriceCache()
local tooOld = addonTable.lookupItemPrice(34054, 400000)
assertEqual(tooOld.freshness, "stale", "old state remains stale")
assertEqual(tooOld.isTooOld, true, "old price too old")
local oldChoice, oldReason = addonTable.chooseUsableUnitPrice(tooOld, "spend")
assertEqual(oldChoice, nil, "too old auction rejected for spend")
assertEqual(oldReason, "auction_price_too_old", "too old reason")

scenario.minBuyout = 0
scenario.marketValue = -5
scenario.vendorBuyPrice = nil
addonTable.resetPriceCache()
local missing = addonTable.lookupItemPrice(34054, 100000)
assertEqual(missing.available, false, "non-positive prices unavailable")
assertEqual(missing.unavailableReason, "no_price_data", "non-positive reason")
assertEqual(missing.minBuyout, nil, "zero never normalized as price")

local unavailableProvider = {
    isAvailable = function()
        return false
    end,
    getItemPrice = function()
        return { minBuyout = 1 }
    end,
}
addonTable.registerPriceProvider("unavailable-high-priority", unavailableProvider, 100)
assertEqual(addonTable.getActivePriceProviderName(), "mock", "unavailable provider skipped")

local selected, selectReason = addonTable.selectPriceProvider("unavailable-high-priority")
assertEqual(selected, false, "unavailable provider cannot be selected")
assertEqual(selectReason, "provider_unavailable", "unavailable selection reason")
assertEqual(addonTable.getActivePriceProviderName(), "mock", "fallback remains selected")

local errorProvider = {
    getItemPrice = function()
        error("boom")
    end,
}
addonTable.registerPriceProvider("error", errorProvider, 20)
local errored = addonTable.lookupItemPrice(34054, 100000)
assertEqual(errored.available, false, "provider error unavailable")
assertEqual(errored.unavailableReason, "provider_error", "provider error reason")
assertContains(errored.unavailableDetail, "boom", "provider error detail")

addonTable.unregisterPriceProvider("error")
scenario.minBuyout = 100
scenario.marketValue = 125
scenario.vendorBuyPrice = 80
scenario.updatedAt = nil
addonTable.resetPriceCache()
local unknownFreshness = addonTable.lookupItemPrice(34054, 100000)
assertEqual(unknownFreshness.freshness, "unknown", "missing timestamp freshness")
assertEqual(unknownFreshness.available, true, "missing timestamp still available")

local explicitUnavailable = addonTable.normalizePriceResult(34054, {
    available = false,
    unavailableReason = "not_scanned",
    source = "fixture",
}, "fixture", 100000)
assertEqual(explicitUnavailable.available, false, "explicit unavailable")
assertEqual(explicitUnavailable.unavailableReason, "not_scanned", "explicit unavailable reason")
assertEqual(explicitUnavailable.freshness, "unavailable", "explicit unavailable freshness")

local sameRevision = "stable"
local firstReplacementCalls = 0
local firstReplacementProvider = {
    getRevision = function()
        return sameRevision
    end,
    getItemPrice = function(self, item)
        firstReplacementCalls = firstReplacementCalls + 1
        return {
            item = item,
            minBuyout = 111,
            source = "replaceable",
        }
    end,
}
assert(addonTable.registerPriceProvider("replaceable", firstReplacementProvider, 50))
assert(addonTable.selectPriceProvider("replaceable"))
local firstIdentity = addonTable.getActivePriceProviderIdentity()
local capturedLookup = addonTable.createRevisionedPriceLookup("replaceable", sameRevision)
assertEqual(addonTable.lookupItemPrice(777).minBuyout, 111, "first provider instance price")
assertEqual(firstReplacementCalls, 1, "first provider queried once")

local secondReplacementCalls = 0
local secondReplacementProvider = {
    getRevision = function()
        return sameRevision
    end,
    getItemPrice = function(self, item)
        secondReplacementCalls = secondReplacementCalls + 1
        return {
            item = item,
            minBuyout = 222,
            source = "replaceable",
        }
    end,
}
assert(addonTable.registerPriceProvider("replaceable", secondReplacementProvider, 50))
assert(addonTable.selectPriceProvider("replaceable"))
local secondIdentity = addonTable.getActivePriceProviderIdentity()
assert(firstIdentity ~= secondIdentity, "re-registering a provider changes its instance identity")

local replacementPrice = addonTable.lookupItemPrice(777)
assertEqual(replacementPrice.minBuyout, 222, "same-name same-revision replacement cannot reuse stale raw price")
assertEqual(secondReplacementCalls, 1, "replacement provider is queried for its own cache namespace")

local capturedAfterReplacement = capturedLookup(777)
assertEqual(capturedAfterReplacement.available, false, "old captured lookup rejects replacement provider")
assertEqual(capturedAfterReplacement.unavailableReason, "provider_changed", "provider instance change reason")

print("Price provider abstraction tests passed.")
