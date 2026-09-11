local addonName, addonTable = ...

local currentContext

local STANDARD_PROFESSION_CAPS = { 75, 150, 225, 300, 375, 450 }
local MAX_INFERRED_EMBEDDED_MODIFIER = 20

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
                skillRank = toNumber(skillRank),
                temporaryModifier = toNumber(numTempPoints),
                skillModifier = toNumber(skillModifier),
                skillMaxRank = toNumber(skillMaxRank),
            }
        end
    end

    return nil
end

local function inferBaseCap(reportedCap)
    reportedCap = toNumber(reportedCap)
    if reportedCap <= 0 then
        return 0, 0
    end

    for i = table.getn(STANDARD_PROFESSION_CAPS), 1, -1 do
        local standardCap = STANDARD_PROFESSION_CAPS[i]
        local difference = reportedCap - standardCap

        if difference >= 0 and difference <= MAX_INFERRED_EMBEDDED_MODIFIER then
            return standardCap, difference
        end
    end

    return reportedCap, 0
end

function addonTable.buildProfessionSkillContext(professionName, tradeSkillRank, tradeSkillCap, tradeSkillModifier, legacySkillLine)
    if not professionName or professionName == "" or professionName == "UNKNOWN" then
        return nil
    end

    local reportedSkill = toNumber(tradeSkillRank)
    local reportedCap = toNumber(tradeSkillCap)
    local temporaryModifier = 0
    local skillLineModifier = 0

    if legacySkillLine then
        reportedSkill = toNumber(legacySkillLine.skillRank or legacySkillLine.baseSkill)
        temporaryModifier = toNumber(legacySkillLine.temporaryModifier)
        skillLineModifier = toNumber(legacySkillLine.skillModifier)

        if reportedCap <= 0 then
            reportedCap = toNumber(legacySkillLine.skillMaxRank or legacySkillLine.currentCap)
        end
    end

    local currentCap, embeddedModifier = inferBaseCap(reportedCap)

    local explicitModifier
    if tradeSkillModifier ~= nil then
        explicitModifier = toNumber(tradeSkillModifier)
    else
        explicitModifier = temporaryModifier + skillLineModifier
    end

    local activeModifier = embeddedModifier + explicitModifier
    local baseSkill = math.max(0, reportedSkill - embeddedModifier)
    local effectiveSkill = reportedSkill + explicitModifier

    return {
        professionName = professionName,
        reportedSkill = reportedSkill,
        reportedCap = reportedCap,
        baseSkill = baseSkill,
        trainedSkill = baseSkill,
        currentSkill = effectiveSkill,
        effectiveSkill = effectiveSkill,
        activeSkillModifier = activeModifier,
        embeddedSkillModifier = embeddedModifier,
        explicitSkillModifier = explicitModifier,
        temporarySkillModifier = temporaryModifier,
        skillLineModifier = skillLineModifier,
        currentCap = currentCap,
        effectiveCap = reportedCap,
        hasModifier = activeModifier ~= 0,
    }
end

function addonTable.getEffectiveSkillForBase(baseSkill, context)
    context = context or currentContext
    if not context then
        return toNumber(baseSkill)
    end

    return toNumber(baseSkill) + toNumber(context.activeSkillModifier)
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
