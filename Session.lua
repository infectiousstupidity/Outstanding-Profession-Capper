local addonName, addonTable = ...

local session

function addonTable.startCraftSession(spellID, spellName, targetSkill, queued, castTime, startingRank)
    session = {
        spellID = spellID,
        spellName = spellName,
        targetSkill = targetSkill,
        queued = queued,
        completed = 0,
        castTime = castTime,
        startingRank = startingRank,
        currentRank = startingRank,
        startedAt = GetTime(),
        active = true,
        reachedTarget = false,
        needsContinue = false,
    }
    return session
end

function addonTable.getCraftSession()
    return session
end

function addonTable.clearCraftSession()
    session = nil
end

function addonTable.handleCraftSucceeded(unit, spellName)
    if not session or unit ~= "player" or spellName ~= session.spellName then
        return false
    end

    if session.completed < session.queued then
        session.completed = session.completed + 1
        session.lastCompletedAt = GetTime()
    end

    if session.completed >= session.queued and not session.reachedTarget then
        session.active = false
        session.needsContinue = true
    end

    return true
end

function addonTable.handleCraftInterrupted(unit, spellName)
    if not session or unit ~= "player" or spellName ~= session.spellName then
        return false
    end

    session.active = false
    session.needsContinue = not session.reachedTarget
    return true
end

function addonTable.handleCraftRankUpdate(newRank)
    if not session then
        return nil
    end

    session.currentRank = newRank

    if newRank >= session.targetSkill and not session.reachedTarget then
        if session.active and StopTradeSkillRepeat then
            StopTradeSkillRepeat()
        end
        session.active = false
        session.reachedTarget = true
        session.needsContinue = false
        return "target"
    end

    if session.completed >= session.queued and newRank < session.targetSkill then
        session.active = false
        session.needsContinue = true
        return "continue"
    end

    return session.active and "active" or nil
end

function addonTable.getCraftSessionRemainingSeconds(fallbackCastTime)
    if not session or not session.active then
        return nil
    end

    local remaining = math.max(0, session.queued - session.completed)
    local secondsPerCraft = fallbackCastTime or session.castTime

    if session.completed > 0 and session.lastCompletedAt then
        local elapsed = session.lastCompletedAt - session.startedAt
        if elapsed > 0 then
            secondsPerCraft = elapsed / session.completed
        end
    end

    if not secondsPerCraft then
        return nil
    end

    return remaining * secondsPerCraft
end
