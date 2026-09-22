local addonTable = {}
local modeChanges = 0

addonTable.noteRuntimeModeChanged = function()
    modeChanges = modeChanges + 1
end

assert(loadfile("Settings.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

ProfessionCapperDB = {
    recommendationMode = "dynamic",
    unrelated = "keep-me",
}
local dynamic = addonTable.getSettings()
assertEqual(dynamic.recommendationMode, "optimized", "legacy dynamic migrates to optimized path")
assertEqual(dynamic.recommendationObjective, "cheapest", "legacy dynamic maps to Cheapest")
assertEqual(dynamic.recommendationAvailableOnly, false, "legacy dynamic disables availability filter")
assertEqual(dynamic.unrelated, "keep-me", "migration preserves unrelated settings")

ProfessionCapperDB = {
    recommendationMode = "available",
    unrelated = 42,
}
local available = addonTable.getSettings()
assertEqual(available.recommendationMode, "optimized", "legacy available migrates to optimized path")
assertEqual(available.recommendationObjective, "cheapest", "legacy available maps to Cheapest")
assertEqual(available.recommendationAvailableOnly, true, "legacy available enables availability filter")
assertEqual(available.unrelated, 42, "available migration preserves unrelated settings")

ProfessionCapperDB = {
    recommendationMode = "static",
    unrelated = true,
}
local static = addonTable.getSettings()
assertEqual(static.recommendationMode, "static", "legacy static remains Static")
assertEqual(static.recommendationObjective, "cheapest", "legacy static gets deterministic dormant objective")
assertEqual(static.recommendationAvailableOnly, false, "legacy static gets deterministic dormant filter")
assertEqual(static.unrelated, true, "static migration preserves unrelated settings")

modeChanges = 0
assert(addonTable.setRecommendationMode("dynamic"))
local settings = addonTable.getSettings()
assertEqual(settings.recommendationMode, "optimized", "legacy Cheapest UI maps to optimized path")
assertEqual(settings.recommendationObjective, "cheapest", "legacy Cheapest UI sets Cheapest objective")
assertEqual(settings.recommendationAvailableOnly, false, "legacy Cheapest UI clears availability filter")

assert(addonTable.setRecommendationObjective("smartest"))
assertEqual(settings.recommendationObjective, "smartest", "Smartest objective setter")
assert(addonTable.setRecommendationAvailableOnly(true))
assertEqual(settings.recommendationAvailableOnly, true, "availability is independent of objective")
assert(addonTable.setRecommendationMode("static"))
assertEqual(settings.recommendationMode, "static", "Static remains independent path")
assertEqual(settings.recommendationObjective, "smartest", "Static does not destroy selected optimized objective")
assertEqual(settings.recommendationAvailableOnly, true, "Static does not destroy availability preference")
assert(modeChanges >= 3, "recommendation setting changes invalidate runtime mode generation")

print("Recommendation settings migration tests passed")
