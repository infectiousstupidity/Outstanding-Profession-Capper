local addonName, addonTable = ...

local NULL_PROVIDER_NAME = "null"
local providers = {}
local selectedProviderName = NULL_PROVIDER_NAME
local preferredProviderName

local freshnessSettings = {
    freshMaxAgeSeconds = 6 * 60 * 60,
    staleMaxAgeSeconds = 72 * 60 * 60,
}

addonTable.priceFreshnessSettings = freshnessSettings

local function positiveNumber(value)
    local number = tonumber(value)
    if not number or number <= 0 then
        return nil
    end
    return number
end

local function positiveTimestamp(value)
    local number = tonumber(value)
    if not number or number <= 0 then
        return nil
    end
    return number
end

local function getCurrentTime(nowOverride)
    if nowOverride ~= nil then
        return tonumber(nowOverride)
    end

    if type(time) == "function" then
        return time()
    end

    if os and type(os.time) == "function" then
        return os.time()
    end

    return nil
end

local function inferItemFields(item, raw)
    local itemID = raw and raw.itemID or nil
    local itemLink = raw and raw.itemLink or nil

    if not itemID and type(item) == "number" then
        itemID = item
    end

    if not itemLink and type(item) == "string" and string.find(item, "|Hitem:", 1, true) then
        itemLink = item
    end

    return itemID, itemLink
end

local function unavailableResult(item, source, reason, detail)
    local itemID, itemLink = inferItemFields(item)

    return {
        item = item,
        itemID = itemID,
        itemLink = itemLink,
        source = source or NULL_PROVIDER_NAME,
        available = false,
        unavailable = true,
        unavailableReason = reason or "price_unavailable",
        unavailableDetail = detail,
        freshness = "unavailable",
        isFresh = false,
        isStale = false,
        isTooOld = false,
        minBuyout = nil,
        marketValue = nil,
        historicalValue = nil,
        recentValue = nil,
        vendorBuyPrice = nil,
        numAuctions = nil,
        availableQuantity = nil,
        updatedAt = nil,
        ageSeconds = nil,
        isSuspicious = false,
        suspiciousReason = nil,
        marketRatio = nil,
        providerVersion = nil,
        providerBackend = nil,
    }
end

local function normalizeFreshness(raw, updatedAt, now)
    local freshness
    local ageSeconds

    if updatedAt and now then
        ageSeconds = math.max(0, now - updatedAt)
        if ageSeconds <= freshnessSettings.freshMaxAgeSeconds then
            freshness = "fresh"
        else
            freshness = "stale"
        end
    else
        freshness = raw.freshness
        if freshness ~= "fresh" and freshness ~= "stale" and freshness ~= "unknown" then
            freshness = nil
        end

        if not freshness and raw.stale ~= nil then
            freshness = raw.stale and "stale" or "fresh"
        end
    end

    freshness = freshness or "unknown"

    local isTooOld = false
    if ageSeconds and ageSeconds > freshnessSettings.staleMaxAgeSeconds then
        isTooOld = true
    end

    return freshness, ageSeconds, isTooOld
end

function addonTable.normalizePriceResult(item, raw, providerName, nowOverride)
    if type(raw) ~= "table" then
        return unavailableResult(item, providerName, "no_price_data")
    end

    local source = raw.source or providerName or NULL_PROVIDER_NAME
    if raw.available == false or raw.unavailable == true then
        local result = unavailableResult(
            raw.item or item,
            source,
            raw.unavailableReason or raw.reason or "price_unavailable",
            raw.unavailableDetail
        )
        result.itemID = raw.itemID or result.itemID
        result.itemLink = raw.itemLink or result.itemLink
        result.updatedAt = positiveTimestamp(raw.updatedAt)
        result.providerVersion = raw.providerVersion
        result.providerBackend = raw.providerBackend
        return result
    end

    local minBuyout = positiveNumber(raw.minBuyout)
    local marketValue = positiveNumber(raw.marketValue)
    local historicalValue = positiveNumber(raw.historicalValue)
    local recentValue = positiveNumber(raw.recentValue)
    local vendorBuyPrice = positiveNumber(raw.vendorBuyPrice)
    local numAuctions = positiveNumber(raw.numAuctions)
    local availableQuantity = positiveNumber(raw.availableQuantity or raw.totalQuantity)

    if not minBuyout and not marketValue and not historicalValue and not recentValue and not vendorBuyPrice then
        local result = unavailableResult(
            raw.item or item,
            source,
            raw.unavailableReason or raw.reason or "no_price_data",
            raw.unavailableDetail
        )
        result.itemID = raw.itemID or result.itemID
        result.itemLink = raw.itemLink or result.itemLink
        result.updatedAt = positiveTimestamp(raw.updatedAt)
        return result
    end

    local normalizedItem = raw.item or item
    local itemID, itemLink = inferItemFields(normalizedItem, raw)
    local updatedAt = positiveTimestamp(raw.updatedAt)
    local now = getCurrentTime(nowOverride)
    local freshness, ageSeconds, isTooOld = normalizeFreshness(raw, updatedAt, now)

    return {
        item = normalizedItem,
        itemID = itemID,
        itemLink = itemLink,
        source = source,
        available = true,
        unavailable = false,
        unavailableReason = nil,
        unavailableDetail = nil,
        minBuyout = minBuyout,
        marketValue = marketValue,
        historicalValue = historicalValue,
        recentValue = recentValue,
        vendorBuyPrice = vendorBuyPrice,
        numAuctions = numAuctions,
        availableQuantity = availableQuantity,
        updatedAt = updatedAt,
        freshness = freshness,
        ageSeconds = ageSeconds,
        isFresh = freshness == "fresh",
        isStale = freshness == "stale",
        isTooOld = isTooOld,
        isSuspicious = raw.isSuspicious and true or false,
        suspiciousReason = raw.suspiciousReason,
        marketRatio = tonumber(raw.marketRatio),
        providerVersion = raw.providerVersion,
        providerBackend = raw.providerBackend,
    }
end

local nullProvider = {
    getItemPrice = function(self, item)
        return {
            item = item,
            available = false,
            unavailableReason = "no_price_provider",
            source = NULL_PROVIDER_NAME,
        }
    end,
}

providers[NULL_PROVIDER_NAME] = {
    name = NULL_PROVIDER_NAME,
    provider = nullProvider,
    priority = -1000000,
}

local function providerIsAvailable(entry)
    if not entry then
        return false
    end

    local provider = entry.provider
    if type(provider.isAvailable) ~= "function" then
        return true
    end

    local ok, available = pcall(provider.isAvailable, provider)
    return ok and available and true or false
end

local function chooseBestAvailableProvider()
    local best

    for name, entry in pairs(providers) do
        if name ~= NULL_PROVIDER_NAME and providerIsAvailable(entry) then
            if not best
                or entry.priority > best.priority
                or (entry.priority == best.priority and entry.name < best.name)
            then
                best = entry
            end
        end
    end

    return best or providers[NULL_PROVIDER_NAME]
end

local function refreshSelection()
    if preferredProviderName then
        local preferred = providers[preferredProviderName]
        if preferred and providerIsAvailable(preferred) then
            selectedProviderName = preferredProviderName
            return preferred
        end
    end

    local selected = chooseBestAvailableProvider()
    selectedProviderName = selected.name
    return selected
end

function addonTable.registerPriceProvider(name, provider, priority)
    if type(name) ~= "string" or name == "" or name == NULL_PROVIDER_NAME then
        return false, "invalid_provider_name"
    end

    if type(provider) ~= "table" or type(provider.getItemPrice) ~= "function" then
        return false, "provider_requires_getItemPrice"
    end

    providers[name] = {
        name = name,
        provider = provider,
        priority = tonumber(priority) or 0,
    }

    refreshSelection()
    return true
end

function addonTable.unregisterPriceProvider(name)
    if not providers[name] or name == NULL_PROVIDER_NAME then
        return false
    end

    providers[name] = nil
    if preferredProviderName == name then
        preferredProviderName = nil
    end
    refreshSelection()
    return true
end

function addonTable.selectPriceProvider(name)
    if name == nil then
        preferredProviderName = nil
        local selected = refreshSelection()
        return true, selected.name
    end

    if not providers[name] then
        return false, "unknown_provider"
    end

    preferredProviderName = name
    local selected = refreshSelection()
    if selected.name ~= name then
        return false, "provider_unavailable"
    end

    return true, selected.name
end

function addonTable.getActivePriceProviderName()
    refreshSelection()
    return selectedProviderName
end

function addonTable.getRegisteredPriceProviders()
    local names = {}
    for name in pairs(providers) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function addonTable.lookupItemPrice(item, nowOverride)
    local entry = refreshSelection()
    local provider = entry.provider

    local ok, raw = pcall(provider.getItemPrice, provider, item)
    if not ok then
        return unavailableResult(item, entry.name, "provider_error", tostring(raw))
    end

    return addonTable.normalizePriceResult(item, raw, entry.name, nowOverride)
end

local function buildChoice(result, amount, priceType)
    if not amount then
        return nil
    end

    return {
        unitPrice = amount,
        priceType = priceType,
        source = result.source,
        freshness = result.freshness,
        updatedAt = result.updatedAt,
        ageSeconds = result.ageSeconds,
        isFresh = result.isFresh,
        isStale = result.isStale,
        isTooOld = result.isTooOld,
        numAuctions = result.numAuctions,
        availableQuantity = result.availableQuantity,
    }
end

function addonTable.chooseUsableUnitPrice(result, purpose)
    if type(result) ~= "table" or not result.available then
        return nil, result and result.unavailableReason or "price_unavailable"
    end

    purpose = purpose or "market"

    if purpose == "market" then
        local choice = buildChoice(result, result.marketValue, "market")
            or buildChoice(result, result.historicalValue, "historical")
            or buildChoice(result, result.recentValue, "recent")
            or buildChoice(result, result.minBuyout, "auction")
            or buildChoice(result, result.vendorBuyPrice, "vendor")
        if choice then
            return choice
        end
        return nil, "no_usable_price"
    end

    if purpose == "spend" then
        if result.minBuyout and result.isFresh and not result.isTooOld then
            return buildChoice(result, result.minBuyout, "auction")
        end

        if result.vendorBuyPrice then
            return buildChoice(result, result.vendorBuyPrice, "vendor")
        end

        if result.minBuyout and not result.isTooOld then
            return buildChoice(result, result.minBuyout, "auction")
        end

        return nil, result.isTooOld and "auction_price_too_old" or "no_current_purchase_price"
    end

    if purpose == "auction" then
        if result.minBuyout and not result.isTooOld then
            return buildChoice(result, result.minBuyout, "auction")
        end
        return nil, result.isTooOld and "auction_price_too_old" or "no_auction_price"
    end

    if purpose == "vendor" then
        local choice = buildChoice(result, result.vendorBuyPrice, "vendor")
        if choice then
            return choice
        end
        return nil, "no_vendor_price"
    end

    return nil, "unknown_price_purpose"
end
