local addonTable = {}

addonTable.getEffectiveSkillForBase = function(baseSkill, context)
    return (tonumber(baseSkill) or 0) + ((context and tonumber(context.activeSkillModifier)) or 0)
end

assert(loadfile("RecipeDifficulty.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeDifficultyData.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function assertNear(actual, expected, tolerance, label)
    if not actual or math.abs(actual - expected) > tolerance then
        error(string.format("%s: expected %s +/- %s, got %s", label, expected, tolerance, tostring(actual)))
    end
end

local minorHealth = addonTable.getRecipeDifficultyMetadata(7418)
assertEqual(minorHealth.profession, "Enchanting", "7418 profession")
assertEqual(minorHealth.requiredSkill, 1, "7418 required")
assertEqual(minorHealth.yellowSkill, 70, "7418 yellow")
assertEqual(minorHealth.greenSkill, 90, "7418 green")
assertEqual(minorHealth.graySkill, 110, "7418 gray")

local greaterAssault = addonTable.getRecipeDifficultyMetadata(60763)
assertEqual(greaterAssault.requiredSkill, 440, "60763 required")
assertEqual(greaterAssault.yellowSkill, 450, "60763 yellow")
assertEqual(greaterAssault.greenSkill, 460, "60763 green")
assertEqual(greaterAssault.graySkill, 470, "60763 gray")

local orange = addonTable.evaluateRecipeDifficulty(7418, 60, nil)
assertEqual(orange.color, "orange", "base orange")
assertEqual(orange.guaranteedSkillUp, true, "orange guaranteed")
assertEqual(orange.skillUpChance, 1, "orange chance")

local yellow = addonTable.evaluateRecipeDifficulty(7418, 80, nil)
assertEqual(yellow.color, "yellow", "yellow color")
assertNear(yellow.skillUpChance, 0.75, 0.0001, "yellow chance")

local green = addonTable.evaluateRecipeDifficulty(7418, 100, nil)
assertEqual(green.color, "green", "green color")
assertNear(green.skillUpChance, 0.25, 0.0001, "green chance")

local gray = addonTable.evaluateRecipeDifficulty(7418, 110, nil)
assertEqual(gray.color, "gray", "gray color")
assertEqual(gray.canSkillUp, false, "gray cannot skill")

-- A +10 modifier raises effective/displayed profession skill, but does not
-- consume ten trained points from the recipe's color curve.
local racial = addonTable.evaluateRecipeDifficulty(7418, 60, { activeSkillModifier = 10 })
assertEqual(racial.baseSkill, 60, "racial base")
assertEqual(racial.effectiveSkill, 70, "racial effective")
assertEqual(racial.color, "orange", "racial preserves base color")
assertEqual(racial.displayedThresholds.yellow, 80, "racial shifted displayed yellow")
assertEqual(racial.displayedThresholds.green, 100, "racial shifted displayed green")
assertEqual(racial.displayedThresholds.gray, 120, "racial shifted displayed gray")

-- Modifier can make a higher-skill recipe usable before base skill alone could.
local earlyUse = addonTable.evaluateRecipeDifficulty(60763, 430, { activeSkillModifier = 10 })
assertEqual(earlyUse.effectiveSkill, 440, "modifier meets required skill")
assertEqual(earlyUse.available, true, "modifier unlocks recipe")
assertEqual(earlyUse.color, "orange", "early-use recipe remains orange")
assertEqual(earlyUse.skillUpChance, 1, "early-use recipe guaranteed")

local noModifier = addonTable.evaluateRecipeDifficulty(60763, 430, nil)
assertEqual(noModifier.available, false, "no modifier cannot use recipe")
assertEqual(noModifier.reason, "required_skill_not_met", "required skill reason")

local unknown = addonTable.evaluateRecipeDifficulty(999999, 100, nil)
assertEqual(unknown.metadataKnown, false, "unknown metadata")
assertEqual(unknown.eligible, false, "unknown excluded")
assertEqual(addonTable.isRecipeEligibleForDynamicOptimization(999999), false, "unknown optimizer exclusion")

local ok = addonTable.validateRecipeDifficultyMetadata({
    spellID = 1, profession = "Test", requiredSkill = 1,
    orangeSkill = 1, yellowSkill = 10, greenSkill = 20, graySkill = 30,
})
assertEqual(ok, true, "valid metadata")

local valid, reason = addonTable.validateRecipeDifficultyMetadata({
    spellID = 2, profession = "Test", requiredSkill = 1,
    orangeSkill = 1, yellowSkill = 30, greenSkill = 20, graySkill = 40,
})
assertEqual(valid, false, "invalid order rejected")
assertEqual(reason, "non_monotonic_thresholds", "invalid order reason")

local registeredCount = 0
for _ in pairs(addonTable.recipeDifficultyMetadata) do
    registeredCount = registeredCount + 1
end
if registeredCount < 3000 then
    error("expected broad WotLK recipe coverage, got " .. tostring(registeredCount))
end

print("Recipe difficulty metadata tests passed (" .. tostring(registeredCount) .. " recipes).")
