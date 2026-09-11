local addonTable = {}
local tradeSkill = {}
local skillLines = {}

function GetTradeSkillLine()
    return tradeSkill.name, tradeSkill.rank, tradeSkill.cap, tradeSkill.modifier
end

function GetNumSkillLines()
    return table.getn(skillLines)
end

function GetSkillLineInfo(index)
    local skill = skillLines[index]
    return skill.name, skill.isHeader, nil, skill.rank, skill.temporaryModifier, skill.skillModifier, skill.cap
end

assert(loadfile("CharacterSkill.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function setScenario(name, rank, cap, tradeModifier, temporaryModifier, skillModifier)
    tradeSkill = {
        name = name,
        rank = rank,
        cap = cap,
        modifier = tradeModifier,
    }
    skillLines = {
        {
            name = name,
            rank = rank,
            cap = cap,
            temporaryModifier = temporaryModifier or 0,
            skillModifier = skillModifier or 0,
        },
    }
end

setScenario("Enchanting", 100, 150, nil, 0, 0)
local context = addonTable.readProfessionSkillContext()
assertEqual(context.baseSkill, 100, "no modifier base skill")
assertEqual(context.effectiveSkill, 100, "no modifier effective skill")
assertEqual(context.activeSkillModifier, 0, "no modifier bonus")
assertEqual(context.currentCap, 150, "no modifier cap")
assertEqual(context.effectiveCap, 150, "no modifier effective cap")
assertEqual(context.hasModifier, false, "no modifier flag")

setScenario("Enchanting", 100, 150, nil, 0, 10)
context = addonTable.readProfessionSkillContext()
assertEqual(context.baseSkill, 100, "racial base skill")
assertEqual(context.effectiveSkill, 110, "racial effective skill")
assertEqual(context.activeSkillModifier, 10, "racial modifier")
assertEqual(context.effectiveCap, 160, "racial effective cap")
assertEqual(context.hasModifier, true, "racial modifier flag")

setScenario("Enchanting", 100, 150, nil, 5, 10)
context = addonTable.readProfessionSkillContext()
assertEqual(context.baseSkill, 100, "combined base skill")
assertEqual(context.temporarySkillModifier, 5, "temporary modifier")
assertEqual(context.skillLineModifier, 10, "skill-line modifier")
assertEqual(context.activeSkillModifier, 15, "combined active modifier")
assertEqual(context.effectiveSkill, 115, "combined effective skill")

setScenario("Enchanting", 100, 150, 12, 5, 10)
context = addonTable.readProfessionSkillContext()
assertEqual(context.activeSkillModifier, 12, "direct trade-skill modifier")
assertEqual(context.effectiveSkill, 112, "direct effective skill")

setScenario("Enchanting", 100, 150, nil, 0, 10)
local _, changed = addonTable.refreshProfessionSkillContext()
assertEqual(changed, true, "initial refresh changed")
local _, unchanged = addonTable.refreshProfessionSkillContext()
assertEqual(unchanged, false, "identical refresh unchanged")
skillLines[1].temporaryModifier = 5
local refreshed, modifierChanged = addonTable.refreshProfessionSkillContext()
assertEqual(modifierChanged, true, "modifier refresh changed")
assertEqual(refreshed.activeSkillModifier, 15, "modifier refresh value")

tradeSkill.name = "UNKNOWN"
local missing = addonTable.readProfessionSkillContext()
assertEqual(missing, nil, "closed trade skill context")

print("Character skill context tests passed.")
