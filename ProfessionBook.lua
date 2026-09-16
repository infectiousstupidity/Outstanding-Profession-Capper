local addonName, addonTable = ...

local snapshots = {}
local lastOpenedProfession
local activeOwnerKey
local generation = 0

local function professionName(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    return value
end

local function baseSkill(context)
    if type(context) == "table" then
        return tonumber(context.baseSkill) or 0
    end
    return tonumber(context) or 0
end

local function currentOwnerKey(context)
    if type(context) == "table"
        and type(context.characterKey) == "string"
        and context.characterKey ~= ""
    then
        return context.characterKey
    end

    if type(UnitGUID) == "function" then
        local ok, guid = pcall(UnitGUID, "player")
        if ok and type(guid) == "string" and guid ~= "" then
            return "guid:" .. guid
        end
    end

    local name
    if type(UnitName) == "function" then
        local ok, value = pcall(UnitName, "player")
        if ok and type(value) == "string" and value ~= "" then
            name = value
        end
    end

    if name then
        local realm
        if type(GetRealmName) == "function" then
            local ok, value = pcall(GetRealmName)
            if ok and type(value) == "string" and value ~= "" then
                realm = value
            end
        end
        return "name:" .. name .. "@" .. tostring(realm or "")
    end

    return "session"
end

local function bumpBookRevision()
    generation = generation + 1
    if type(addonTable.bumpRuntimeRevision) == "function" then
        addonTable.bumpRuntimeRevision("professionBook")
    end
end

local function syncOwner(context)
    local ownerKey = currentOwnerKey(context)
    local changed = activeOwnerKey ~= nil and activeOwnerKey ~= ownerKey
    if changed then
        snapshots = {}
        lastOpenedProfession = nil
        bumpBookRevision()
    end
    activeOwnerKey = ownerKey
    return ownerKey, changed
end

local function snapshotFor(profession)
    profession = professionName(profession)
    local entry = profession and snapshots[profession] or nil
    if entry and entry.ownerKey ~= activeOwnerKey then
        return nil
    end
    return entry
end

function addonTable.prepareProfessionBook(profession, context)
    profession = professionName(profession)
    if not profession then
        return {
            action = "scan",
            reason = "missing_profession",
        }
    end

    local ownerKey, ownerChanged = syncOwner(context)
    local entry = snapshots[profession]
    if entry and entry.ownerKey ~= ownerKey then
        entry = nil
    end
    local switched = lastOpenedProfession ~= nil
        and lastOpenedProfession ~= profession
    lastOpenedProfession = profession

    if ownerChanged then
        return {
            action = "scan",
            reason = "character_switch",
        }
    end

    if switched then
        return {
            action = "scan",
            reason = "profession_switch",
            snapshot = entry and entry.recipes or nil,
        }
    end

    if not entry then
        return {
            action = "scan",
            reason = "cold_open",
        }
    end

    if entry.identityInvalid then
        return {
            action = "scan",
            reason = entry.invalidationReason or "identity_invalid",
            snapshot = entry.recipes,
        }
    end

    local currentBaseSkill = baseSkill(context)
    if entry.baseSkill ~= currentBaseSkill then
        return {
            action = "refresh_live",
            reason = "base_skill_changed",
            snapshot = entry.recipes,
        }
    end

    return {
        action = "reuse",
        reason = "unchanged",
        snapshot = entry.recipes,
    }
end

function addonTable.storeProfessionBookSnapshot(profession, recipes, context)
    profession = professionName(profession)
    if not profession or type(recipes) ~= "table" then
        return nil
    end

    local ownerKey = syncOwner(context)
    bumpBookRevision()
    snapshots[profession] = {
        ownerKey = ownerKey,
        profession = profession,
        recipes = recipes,
        baseSkill = baseSkill(context),
        identityInvalid = false,
        invalidationReason = nil,
        generation = generation,
    }
    lastOpenedProfession = profession
    return recipes
end

function addonTable.markProfessionBookLiveCurrent(profession, context)
    local entry = snapshotFor(profession)
    if not entry then
        return false
    end

    entry.baseSkill = baseSkill(context)
    return true
end

function addonTable.getProfessionBookSnapshot(profession)
    local entry = snapshotFor(profession)
    return entry and entry.recipes or nil
end

function addonTable.invalidateProfessionBook(profession, reason)
    profession = professionName(profession)
    reason = tostring(reason or "identity_invalid")

    if profession then
        local entry = snapshots[profession]
        if entry then
            entry.identityInvalid = true
            entry.invalidationReason = reason
        end
        return
    end

    for _, entry in pairs(snapshots) do
        entry.identityInvalid = true
        entry.invalidationReason = reason
    end
end

function addonTable.noteProfessionBookEvent(eventName, profession)
    eventName = tostring(eventName or "")

    if eventName == "LEARNED_SPELL_IN_TAB" then
        addonTable.invalidateProfessionBook(profession, "learned_recipe")
        return "invalidate_identity"
    end

    if eventName == "BAG_UPDATE"
        or eventName == "PRICE_PROVIDER_REVISION"
        or eventName == "PLAYER_EQUIPMENT_CHANGED"
        or eventName == "UNIT_AURA"
        or eventName == "TRADE_SKILL_UPDATE"
    then
        return "preserve"
    end

    return "preserve"
end

function addonTable.getProfessionBookLifecycleState(profession)
    local entry = snapshotFor(profession)
    if not entry then
        return nil
    end

    return {
        profession = entry.profession,
        baseSkill = entry.baseSkill,
        identityInvalid = entry.identityInvalid and true or false,
        invalidationReason = entry.invalidationReason,
        generation = entry.generation,
        ownerKey = entry.ownerKey,
        recipes = entry.recipes,
        lastOpenedProfession = lastOpenedProfession,
    }
end

function addonTable.getProfessionBookLifecycleStats()
    local snapshotCount = 0
    for _, entry in pairs(snapshots) do
        if entry.ownerKey == activeOwnerKey then
            snapshotCount = snapshotCount + 1
        end
    end

    return {
        ownerKey = activeOwnerKey,
        snapshotCount = snapshotCount,
        generation = generation,
        lastOpenedProfession = lastOpenedProfession,
    }
end

function addonTable.resetProfessionBookLifecycle()
    snapshots = {}
    lastOpenedProfession = nil
    activeOwnerKey = nil
    generation = 0
end
