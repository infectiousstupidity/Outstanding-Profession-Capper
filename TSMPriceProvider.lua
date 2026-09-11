local addonName, addonTable = ...

local PROVIDER_NAME = "tsm-auctiondb"
local DISPLAY_SOURCE = "TSM AuctionDB"
local SUSPICIOUS_HIGH_RATIO = 5
local SUSPICIOUS_LOW_RATIO = 0.2

local function positiveNumber(value)
    value = tonumber(value)
    if value and value > 0 then
        return value
    end
    return nil
end

local function parseItemID(item)
    if type(item) == "number" then
        return item
    end

    if type(item) ~= "string" then
        return nil
    end

    local numeric = tonumber(item)
    if numeric then
        return numeric
    end

    local itemID = string.match(item, "[Ii][Tt][Ee][Mm]:(%d+)")
    if itemID then
        return tonumber(itemID)
    end

    local tsmID = string.match(item, "^[Ii]:(%d+)")
    if tsmID then
        return tonumber(tsmID)
    end

    return nil
end

local function toTSMItemString(item)
    if type(TSM_API) == "table" and type(TSM_API.ToItemString) == "function" and type(item) == "string" then
        local ok, converted = pcall(TSM_API.ToItemString, item)
        if ok and type(converted) == "string" then
            return converted, parseItemID(converted)
        end
    end

    local itemID = parseItemID(item)
    if not itemID then
        return nil, nil
    end

    return "i:" .. itemID, itemID
end

local function getAddonVersion()
    if type(GetAddOnMetadata) ~= "function" then
        return nil
    end

    local ok, version = pcall(GetAddOnMetadata, "TradeSkillMaster_AuctionDB", "Version")
    if ok and type(version) == "string" and version ~= "" then
        return version
    end

    return nil
end

local function getRealmDataFromSavedVariable()
    if type(TSM_AuctionDB) ~= "table" or type(TSM_AuctionDB.realms) ~= "table" then
        return nil
    end

    if type(GetRealmName) ~= "function" or type(UnitFactionGroup) ~= "function" then
        return nil
    end

    local okRealm, realm = pcall(GetRealmName)
    local okFaction, faction = pcall(UnitFactionGroup, "player")
    if not okRealm or not okFaction or not realm or not faction then
        return nil
    end

    return TSM_AuctionDB.realms[faction .. " - " .. realm]
end

local function getRealmData()
    if type(TSM_AuctionDB_GetRealmData) == "function" then
        local ok, data = pcall(TSM_AuctionDB_GetRealmData)
        if ok and type(data) == "table" then
            return data, "AuctionDB API"
        end
    end

    local data = getRealmDataFromSavedVariable()
    if type(data) == "table" then
        return data, "AuctionDB SavedVariables"
    end

    return nil, nil
end

local function getRawRecord(realmData, itemString, itemID)
    if type(realmData) ~= "table" then
        return nil
    end

    return realmData[itemString]
        or realmData[string.lower(itemString)]
        or realmData[itemID]
        or realmData[tostring(itemID)]
end

local function readRawRecord(record)
    if type(record) == "number" then
        return positiveNumber(record), nil, nil, nil, nil, nil
    end

    if type(record) ~= "table" then
        return nil, nil, nil, nil, nil, nil
    end

    local minBuyout = positiveNumber(record.mb or record.minBuyout or record.DBMinBuyout)
    local marketValue = positiveNumber(record.mkt or record.DBMarket)
    local historicalValue = positiveNumber(record.hist or record.historical or record.DBHistorical)
    local recentValue = positiveNumber(record.mv or record.marketValueRecent or record.DBRecent)
    local numAuctions = positiveNumber(record.na or record.numAuctions)
    local updatedAt = positiveNumber(record.ts or record.lastScan or record.updatedAt)

    -- Older backport schemas used marketValue for the latest scan snapshot.
    if not recentValue then
        recentValue = positiveNumber(record.marketValue)
    end

    return minBuyout, marketValue, historicalValue, recentValue, numAuctions, updatedAt
end

local function getPublicPrice(sourceKey, itemString)
    if type(TSM_API) ~= "table" or type(TSM_API.GetCustomPriceValue) ~= "function" then
        return nil
    end

    local ok, value = pcall(TSM_API.GetCustomPriceValue, sourceKey, itemString)
    if not ok then
        return nil
    end

    return positiveNumber(value)
end

local function hasPublicPriceAPI()
    return type(TSM_API) == "table" and type(TSM_API.GetCustomPriceValue) == "function"
end

local function hasRawAuctionDB()
    if type(TSM_AuctionDB_GetRealmData) == "function" then
        return true
    end
    return type(TSM_AuctionDB) == "table" and type(TSM_AuctionDB.realms) == "table"
end

local function getSuspiciousState(minBuyout, marketValue)
    if not minBuyout or not marketValue then
        return false, nil, nil
    end

    local ratio = minBuyout / marketValue
    if ratio >= SUSPICIOUS_HIGH_RATIO then
        return true, "min_buyout_far_above_market", ratio
    elseif ratio <= SUSPICIOUS_LOW_RATIO then
        return true, "min_buyout_far_below_market", ratio
    end

    return false, nil, ratio
end

local provider = {}

function provider:isAvailable()
    return hasPublicPriceAPI() or hasRawAuctionDB()
end

function provider:getItemPrice(item)
    local itemString, itemID = toTSMItemString(item)
    if not itemString or not itemID then
        return {
            item = item,
            available = false,
            unavailableReason = "invalid_item",
            source = DISPLAY_SOURCE,
            providerVersion = getAddonVersion(),
        }
    end

    local realmData, rawBackend = getRealmData()
    local rawRecord = getRawRecord(realmData, itemString, itemID)
    local rawMinBuyout, rawMarket, rawHistorical, rawRecent, numAuctions, updatedAt = readRawRecord(rawRecord)

    local publicMinBuyout = getPublicPrice("DBMinBuyout", itemString)
    local publicMarket = getPublicPrice("DBMarket", itemString)
    local publicHistorical = getPublicPrice("DBHistorical", itemString)
    local publicRecent = getPublicPrice("DBRecent", itemString)

    local minBuyout = publicMinBuyout or rawMinBuyout
    local marketValue = publicMarket or rawMarket
    local historicalValue = publicHistorical or rawHistorical
    local recentValue = publicRecent or rawRecent

    if not minBuyout and not marketValue and not historicalValue and not recentValue then
        return {
            item = item,
            itemID = itemID,
            available = false,
            unavailableReason = rawRecord and "auctiondb_price_missing" or "item_not_scanned",
            source = DISPLAY_SOURCE,
            updatedAt = updatedAt,
            providerVersion = getAddonVersion(),
            providerBackend = hasPublicPriceAPI() and rawBackend
                and "TSM_API + " .. rawBackend
                or (hasPublicPriceAPI() and "TSM_API" or rawBackend),
        }
    end

    local isSuspicious, suspiciousReason, marketRatio = getSuspiciousState(minBuyout, marketValue)

    local backend
    if hasPublicPriceAPI() and rawBackend then
        backend = "TSM_API + " .. rawBackend
    elseif hasPublicPriceAPI() then
        backend = "TSM_API"
    else
        backend = rawBackend
    end

    return {
        item = item,
        itemID = itemID,
        itemString = itemString,
        minBuyout = minBuyout,
        marketValue = marketValue,
        historicalValue = historicalValue,
        recentValue = recentValue,
        numAuctions = numAuctions,
        updatedAt = updatedAt,
        source = DISPLAY_SOURCE,
        providerVersion = getAddonVersion(),
        providerBackend = backend,
        isSuspicious = isSuspicious,
        suspiciousReason = suspiciousReason,
        marketRatio = marketRatio,
        marketDepthKnown = false,
    }
end

addonTable.registerPriceProvider(PROVIDER_NAME, provider, 100)
