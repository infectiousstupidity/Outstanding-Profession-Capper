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

-- ChromieCraft/Wrath observation from a Blood Elf Enchanter:
-- GetTradeSkillLine() => Enchanting, 302, 385, nil
-- GetSkillLineInfo()  => rank 302, temp 0, modifier 0, max 385
setScenario("Enchanting", 302, 385, nil, 0, 0)
context = addonTable.readProfessionSkillContext()
assertEqual(context.reportedSkill, 302, "embedded racial reported skill")
assertEqual(context.baseSkill, 292, "embedded racial base skill")
assertEqual(context.effectiveSkill, 302, "embedded racial effective skill")
assertEqual(context.embeddedSkillModifier, 10, "embedded racial modifier")
assertEqual(context.activeSkillModifier, 10, "embedded racial active modifier")
assertEqual(context.currentCap, 375, "embedded racial base cap")
assertEqual(context.effectiveCap, 385, "embedded racial effective cap")
assertEqual(context.hasModifier, true, "embedded racial modifier flag")
assertEqual(addonTable.getEffectiveSkillForBase(299, context), 309, "embedded racial displayed target")

-- The same inference is generic for other profession bonuses, such as +5.
setScenario("Jewelcrafting", 205, 230, nil, 0, 0)
context = addonTable.readProfessionSkillContext()
assertEqual(context.baseSkill, 200, "generic embedded base skill")
assertEqual(context.effectiveSkill, 205, "generic embedded effective skill")
assertEqual(context.activeSkillModifier, 5, "generic embedded modifier")
assertEqual(context.currentCap, 225, "generic embedded base cap")
assertEqual(context.effectiveCap, 230, "generic embedded effective cap")

-- Explicit temporary/equipment skill is added on top of any embedded cap modifier.
setScenario("Enchanting", 302, 385, nil, 5, 0)
context = addonTable.readProfessionSkillContext()
assertEqual(context.baseSkill, 292, "combined base skill")
assertEqual(context.embeddedSkillModifier, 10, "combined embedded modifier")
assertEqual(context.temporarySkillModifier, 5, "temporary modifier")
assertEqual(context.explicitSkillModifier, 5, "explicit modifier")
assertEqual(context.activeSkillModifier, 15, "combined active modifier")
assertEqual(context.effectiveSkill, 307, "combined effective skill")
assertEqual(context.currentCap, 375, "combined base cap")
assertEqual(context.effectiveCap, 385, "combined effective cap")

-- Prefer the direct fourth GetTradeSkillLine() modifier when a client exposes it.
setScenario("Enchanting", 100, 150, 12, 5, 10)
context = addonTable.readProfessionSkillContext()
assertEqual(context.baseSkill, 100, "direct modifier base skill")
assertEqual(context.explicitSkillModifier, 12, "direct explicit modifier")
assertEqual(context.activeSkillModifier, 12, "direct active modifier")
assertEqual(context.effectiveSkill, 112, "direct effective skill")

setScenario("Enchanting", 302, 385, nil, 0, 0)
local _, changed = addonTable.refreshProfessionSkillContext()
assertEqual(changed, true, "initial refresh changed")
local _, unchanged = addonTable.refreshProfessionSkillContext()
assertEqual(unchanged, false, "identical refresh unchanged")
skillLines[1].temporaryModifier = 5
local refreshed, modifierChanged = addonTable.refreshProfessionSkillContext()
assertEqual(modifierChanged, true, "modifier refresh changed")
assertEqual(refreshed.activeSkillModifier, 15, "modifier refresh value")
assertEqual(refreshed.effectiveSkill, 307, "modifier refresh effective skill")

-- Integration regression: the observed 302/385 Blood Elf state must select
-- the trained 265-299 guide step, not the normal 301-310 step.
addonTable.Enchanting = {
    ["20017"] = "Enchant Shield - Greater Stamina",
}
addonTable.chat_frame_default_color = "FFFFFF"
assert(loadfile("Guide.lua"))("Profession_Capper", addonTable)
assert(loadfile("Professions/Enchanting.lua"))("Profession_Capper", addonTable)

setScenario("Enchanting", 302, 385, nil, 0, 0)
context = addonTable.readProfessionSkillContext()
local recipes, recipeNames, baseTarget = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(context.baseSkill)
assertEqual(context.baseSkill, 292, "route trained skill")
assertEqual(baseTarget, 299, "route trained target")
assertEqual(addonTable.getEffectiveSkillForBase(baseTarget, context), 309, "route displayed target")
assertEqual(recipes[1], 20017, "route recipe")
assertEqual(recipeNames[1], "Enchant Shield - Greater Stamina", "route recipe name")

-- Without the +10 embedded bonus, skill 302 belongs to the normal 301-310 step.
setScenario("Enchanting", 302, 375, nil, 0, 0)
context = addonTable.readProfessionSkillContext()
local normalRecipes, _, normalTarget = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(context.baseSkill)
assertEqual(context.baseSkill, 302, "normal route trained skill")
assertEqual(normalTarget, 310, "normal route target")
local foundMajorMana = false
for i = 1, table.getn(normalRecipes) do
    if normalRecipes[i] == 20028 then
        foundMajorMana = true
    end
end
assertEqual(foundMajorMana, true, "normal route contains Major Mana")

tradeSkill.name = "UNKNOWN"
local missing = addonTable.readProfessionSkillContext()
assertEqual(missing, nil, "closed trade skill context")

print("Character skill context tests passed.")
