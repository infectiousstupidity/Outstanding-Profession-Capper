local addonName, addonTable = ...

local snapshots = {}
local lastOpenedProfession
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

local function snapshotFor(profession)
    profession = professionName(profession)
    return profession and snapshots[profession] or nil
end

function addonTable.prepareProfessionBook(profession, context)
    profession = professionName(profession)
    if not profession then
        return {
            action = "scan",
            reason = "missing_profession",
        }
    end

    local entry = snapshots[profession]
    local switched = lastOpenedProfession ~= nil
        and lastOpenedProfession ~= profession
    lastOpenedProfession = profession

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

    generation = generation + 1
    if type(addonTable.bumpRuntimeRevision) == "function" then
        addonTable.bumpRuntimeRevision("professionBook")
    end
    snapshots[profession] = {
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
        recipes = entry.recipes,
        lastOpenedProfession = lastOpenedProfession,
    }
end

function addonTable.resetProfessionBookLifecycle()
    snapshots = {}
    lastOpenedProfession = nil
    generation = 0
end
