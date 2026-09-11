local addonName, addonTable = ...

local session

local function positiveInteger(value, fallback)
    value = math.floor(tonumber(value) or 0)
    if value > 0 then
        return value
    end
    return fallback
end

local function copyTarget(target)
    if type(target) ~= "table" then
        return nil
    end

    return {
        kind = target.kind,
        bag = target.bag,
        slot = target.slot,
        itemID = target.itemID,
    }
end

function addonTable.startCraftSession(spellID, spellName, targetSkill, queued, castTime, startingRank, options)
    options = options or {}

    local preservedTarget
    if session and session.spellID == spellID and options.preserveTarget ~= false then
        preservedTarget = copyTarget(session.target)
    end

    session = {
        spellID = spellID,
        spellName = spellName,
        targetSkill = targetSkill,
        queued = positiveInteger(queued, 1),
        completed = 0,
        castTime = castTime,
        startingRank = startingRank,
        currentRank = startingRank,
        startedAt = GetTime(),
        active = true,
        reachedTarget = false,
        needsContinue = false,
        finished = false,
        mode = options.mode or "batch",
        repeatMode = options.repeatMode,
        target = preservedTarget,
    }
    return session
end

function addonTable.getCraftSession()
    return session
end

function addonTable.clearCraftSession()
    session = nil
end

function addonTable.resumeCraftSession(spellID)
    if not session
        or session.spellID ~= spellID
        or session.reachedTarget
        or session.completed >= session.queued
    then
        return false
    end

    session.active = true
    session.needsContinue = false
    session.finished = false
    session.startedAt = GetTime()
    session.lastCompletedAt = nil
    return true
end

function addonTable.setCraftSessionTarget(kind, bag, slot, itemID)
    if not session or session.mode ~= "targeted_enchant" then
        return false
    end

    if kind ~= "bag" and kind ~= "inventory" then
        return false
    end

    slot = tonumber(slot)
    if not slot then
        return false
    end

    session.target = {
        kind = kind,
        bag = kind == "bag" and tonumber(bag) or nil,
        slot = slot,
        itemID = tonumber(itemID),
    }
    return true
end

function addonTable.getCraftSessionTarget()
    return session and copyTarget(session.target) or nil
end

function addonTable.clearCraftSessionTarget()
    if session then
        session.target = nil
    end
end

function addonTable.handleCraftSucceeded(unit, spellName)
    if not session or unit ~= "player" or spellName ~= session.spellName then
        return false
    end

    if session.completed < session.queued then
        session.completed = session.completed + 1
        session.lastCompletedAt = GetTime()
    end

    if session.mode == "targeted_enchant" then
        session.active = false
        if session.completed >= session.queued or session.reachedTarget then
            session.needsContinue = false
            session.finished = true
        else
            session.needsContinue = true
        end
        return true
    end

    if session.completed >= session.queued and not session.reachedTarget then
        session.active = false
        session.needsContinue = true
        session.finished = true
    end

    return true
end

function addonTable.handleCraftInterrupted(unit, spellName)
    if not session or unit ~= "player" or spellName ~= session.spellName then
        return false
    end

    session.active = false
    session.needsContinue = not session.reachedTarget and session.completed < session.queued
    session.finished = not session.needsContinue
    return true
end

function addonTable.handleCraftRankUpdate(newRank)
    if not session then
        return nil
    end

    session.currentRank = newRank

    if newRank >= session.targetSkill and not session.reachedTarget then
        if session.active and session.mode ~= "targeted_enchant" and StopTradeSkillRepeat then
            StopTradeSkillRepeat()
        end
        session.active = false
        session.reachedTarget = true
        session.needsContinue = false
        session.finished = true
        return "target"
    end

    if session.mode == "targeted_enchant" then
        if session.completed >= session.queued then
            session.active = false
            session.needsContinue = false
            session.finished = true
            return "done"
        end
        return session.active and "active" or (session.needsContinue and "continue" or nil)
    end

    if session.completed >= session.queued and newRank < session.targetSkill then
        session.active = false
        session.needsContinue = true
        session.finished = true
        return "continue"
    end

    return session.active and "active" or nil
end

function addonTable.getCraftSessionRemainingSeconds(fallbackCastTime)
    if not session or not session.active then
        return nil
    end

    local secondsPerCraft = fallbackCastTime or session.castTime
    if not secondsPerCraft then
        return nil
    end

    if session.mode == "targeted_enchant" then
        return secondsPerCraft
    end

    local remaining = math.max(0, session.queued - session.completed)

    if session.completed > 0 and session.lastCompletedAt then
        local elapsed = session.lastCompletedAt - session.startedAt
        if elapsed > 0 then
            secondsPerCraft = elapsed / session.completed
        end
    end

    return remaining * secondsPerCraft
end
