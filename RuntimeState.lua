local addonName, addonTable = ...

local MAX_INVENTORY_ENTRIES = 2048

local revisions = {
    professionBook = 0,
    skill = 0,
    inventory = 0,
    eligibility = 0,
    mode = 0,
    manual = 0,
}

local skillSignature
local inventoryCache = {}
local inventoryEntries = 0

local function copyRevisions()
    local result = {}
    for key, value in pairs(revisions) do
        result[key] = value
    end
    return result
end

local function contextSignature(context)
    if type(context) ~= "table" then
        return nil
    end

    return table.concat({
        tostring(context.professionName or ""),
        tostring(tonumber(context.baseSkill) or 0),
        tostring(tonumber(context.currentCap) or 0),
        tostring(tonumber(context.activeSkillModifier) or 0),
        tostring(tonumber(context.effectiveCap) or 0),
    }, "|")
end

function addonTable.bumpRuntimeRevision(kind)
    if revisions[kind] == nil then
        return nil, "unknown_runtime_revision"
    end

    revisions[kind] = revisions[kind] + 1
    if kind == "inventory" then
        inventoryCache = {}
        inventoryEntries = 0
    end
    return revisions[kind]
end

function addonTable.getRuntimeRevision(kind)
    return revisions[kind]
end

function addonTable.getRuntimeRevisions()
    return copyRevisions()
end

function addonTable.syncRuntimeSkillContext(context)
    local signature = contextSignature(context)
    if not signature then
        return false, revisions.skill
    end

    if skillSignature == signature then
        return false, revisions.skill
    end

    skillSignature = signature
    return true, addonTable.bumpRuntimeRevision("skill")
end

function addonTable.noteRuntimeInventoryChanged()
    return addonTable.bumpRuntimeRevision("inventory")
end

function addonTable.noteRuntimeEligibilityChanged()
    return addonTable.bumpRuntimeRevision("eligibility")
end

function addonTable.noteRuntimeModeChanged()
    return addonTable.bumpRuntimeRevision("mode")
end

function addonTable.getRuntimeInventoryCount(itemID, fallback)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then
        return math.max(0, tonumber(fallback) or 0)
    end

    local cached = inventoryCache[itemID]
    if cached ~= nil then
        if type(addonTable.performanceCache) == "function" then
            addonTable.performanceCache("inventory", true)
        end
        return cached
    end

    if type(addonTable.performanceCache) == "function" then
        addonTable.performanceCache("inventory", false)
    end

    local value
    if type(GetItemCount) == "function" then
        local ok, count = pcall(GetItemCount, itemID, true)
        if not ok then
            ok, count = pcall(GetItemCount, itemID)
        end
        if ok and tonumber(count) then
            value = math.max(0, tonumber(count))
        end
    end
    value = value ~= nil and value or math.max(0, tonumber(fallback) or 0)

    if inventoryEntries < MAX_INVENTORY_ENTRIES then
        inventoryCache[itemID] = value
        inventoryEntries = inventoryEntries + 1
    end
    return value
end

function addonTable.getRuntimeStateCacheStats()
    return {
        revisions = copyRevisions(),
        inventoryEntries = inventoryEntries,
        maxInventoryEntries = MAX_INVENTORY_ENTRIES,
    }
end

function addonTable.resetRuntimeStateForTests()
    revisions = {
        professionBook = 0,
        skill = 0,
        inventory = 0,
        eligibility = 0,
        mode = 0,
        manual = 0,
    }
    skillSignature = nil
    inventoryCache = {}
    inventoryEntries = 0
end
