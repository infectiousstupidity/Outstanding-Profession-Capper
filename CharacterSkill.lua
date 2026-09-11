local addonName, addonTable = ...

local currentContext

local function toNumber(value)
    if type(value) == "number" then
        return value
    end

    return tonumber(value) or 0
end

local function getLegacySkillLine(professionName)
    if not professionName or not GetNumSkillLines or not GetSkillLineInfo then
        return nil
    end

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
        if not isHeader and skillName == professionName then
            return {
                baseSkill = toNumber(skillRank),
                temporaryModifier = toNumber(numTempPoints),
                skillModifier = toNumber(skillModifier),
                currentCap = toNumber(skillMaxRank),
            }
        end
    end

    return nil
end

function addonTable.buildProfessionSkillContext(professionName, tradeSkillRank, tradeSkillCap, tradeSkillModifier, legacySkillLine)
    if not professionName or professionName == "" or professionName == "UNKNOWN" then
        return nil
    end

    local baseSkill = toNumber(tradeSkillRank)
    local currentCap = toNumber(tradeSkillCap)
    local temporaryModifier = 0
    local skillLineModifier = 0

    if legacySkillLine then
        baseSkill = toNumber(legacySkillLine.baseSkill)
        temporaryModifier = toNumber(legacySkillLine.temporaryModifier)
        skillLineModifier = toNumber(legacySkillLine.skillModifier)

        if currentCap <= 0 then
            currentCap = toNumber(legacySkillLine.currentCap)
        end
    end

    local activeModifier
    if tradeSkillModifier ~= nil then
        activeModifier = toNumber(tradeSkillModifier)
    else
        activeModifier = temporaryModifier + skillLineModifier
    end

    return {
        professionName = professionName,
        baseSkill = baseSkill,
        trainedSkill = baseSkill,
        currentSkill = baseSkill + activeModifier,
        effectiveSkill = baseSkill + activeModifier,
        activeSkillModifier = activeModifier,
        temporarySkillModifier = temporaryModifier,
        skillLineModifier = skillLineModifier,
        currentCap = currentCap,
        effectiveCap = currentCap + activeModifier,
        hasModifier = activeModifier ~= 0,
    }
end

function addonTable.readProfessionSkillContext()
    local professionName, tradeSkillRank, tradeSkillCap, tradeSkillModifier = GetTradeSkillLine()
    local legacySkillLine = getLegacySkillLine(professionName)

    return addonTable.buildProfessionSkillContext(
        professionName,
        tradeSkillRank,
        tradeSkillCap,
        tradeSkillModifier,
        legacySkillLine
    )
end

local function contextsEqual(left, right)
    if left == right then
        return true
    end

    if not left or not right then
        return false
    end

    return left.professionName == right.professionName
        and left.baseSkill == right.baseSkill
        and left.effectiveSkill == right.effectiveSkill
        and left.activeSkillModifier == right.activeSkillModifier
        and left.currentCap == right.currentCap
        and left.effectiveCap == right.effectiveCap
end

function addonTable.refreshProfessionSkillContext()
    local nextContext = addonTable.readProfessionSkillContext()
    local changed = not contextsEqual(currentContext, nextContext)
    currentContext = nextContext
    return currentContext, changed
end

function addonTable.getProfessionSkillContext()
    return currentContext
end

function addonTable.clearProfessionSkillContext()
    currentContext = nil
end
