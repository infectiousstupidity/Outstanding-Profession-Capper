local addonTable = {}

assert(loadfile("RecommendationPresentation.lua"))("Profession_Capper", addonTable)
assert(loadfile("Settings.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function assertNear(actual, expected, tolerance, label)
    if actual == nil or math.abs(actual - expected) > tolerance then
        error(string.format(
            "%s: expected %s +/- %s, got %s",
            label,
            tostring(expected),
            tostring(tolerance),
            tostring(actual)
        ))
    end
end

ProfessionCapperDB = {
    recommendationMode = "dynamic",
}
local legacyDynamic = addonTable.getRecommendationPresentationState(addonTable.getSettings())
assertEqual(legacyDynamic.mode, "cheapest", "legacy Dynamic presents as Cheapest")
assertEqual(legacyDynamic.availableOnly, false, "legacy Dynamic filter off")
assertEqual(legacyDynamic.availableEnabled, true, "Cheapest availability toggle enabled")

ProfessionCapperDB = {
    recommendationMode = "available",
}
local legacyAvailable = addonTable.getRecommendationPresentationState(addonTable.getSettings())
assertEqual(legacyAvailable.mode, "cheapest", "legacy Available presents as Cheapest")
assertEqual(legacyAvailable.availableOnly, true, "legacy Available presents as filter")
assertEqual(legacyAvailable.availableEnabled, true, "legacy Available filter remains interactive")

ProfessionCapperDB = {
    recommendationMode = "optimized",
    recommendationObjective = "smartest",
    recommendationAvailableOnly = true,
    recommendationSettingsVersion = 2,
}
local smartestState = addonTable.getRecommendationPresentationState(addonTable.getSettings())
assertEqual(smartestState.mode, "smartest", "Smartest control selected")
assertEqual(smartestState.smartest, true, "Smartest state flag")
assertEqual(smartestState.availableOnly, true, "Smartest can use availability filter")

ProfessionCapperDB = {
    recommendationMode = "static",
    recommendationObjective = "smartest",
    recommendationAvailableOnly = true,
    recommendationSettingsVersion = 2,
}
local staticState = addonTable.getRecommendationPresentationState(addonTable.getSettings())
assertEqual(staticState.mode, "static", "Static remains separate")
assertEqual(staticState.availableOnly, true, "Static preserves dormant availability preference")
assertEqual(staticState.availableEnabled, false, "availability toggle disabled in Static")
assertEqual(staticState.objective, "smartest", "Static preserves dormant objective")

local direct = addonTable.getSmartestEconomicsPresentation({
    selectedExecutionMethod = "direct",
    skillUpChance = 0.75,
    expectedCraftsPerSkillUp = 4 / 3,
    directGrossCost = 400,
    materialMarketValuePerCraft = 400,
    effectiveCostPerCraft = 400,
    expectedEffectiveCostPerSkillUp = 1600 / 3,
    estimatedSurplus = 999,
    expectedEstimatedSurplusPerSkillUp = 999,
    resaleEstimate = 2000,
    resaleConfidence = "two_current_sources",
})
assertEqual(direct.method, "direct", "direct execution remains direct")
assertEqual(direct.vellumItemID, nil, "direct execution hides vellum")
assertEqual(direct.estimatedResalePerCraft, nil, "direct execution does not imply resale")
assertEqual(direct.estimatedSurplusPerCraft, 0, "direct execution does not show scroll surplus")
assertEqual(direct.resaleEvidenceState, "not_applicable", "direct resale evidence not applicable")
assertNear(direct.skillUpChance, 0.75, 0.0001, "direct exact chance")
assertNear(direct.expectedCrafts, 4 / 3, 0.0001, "direct expected crafts")

local scroll = addonTable.getSmartestEconomicsPresentation({
    selectedExecutionMethod = "scroll",
    skillUpChance = 0.8,
    expectedCraftsPerSkillUp = 1.25,
    directGrossCost = 400,
    vellumItemID = 43145,
    vellumCost = 50,
    scrollOutputItemID = 44493,
    scrollGrossCost = 450,
    resaleEstimate = 700,
    resaleCredit = 450,
    effectiveCostPerCraft = 0,
    expectedEffectiveCostPerSkillUp = 0,
    estimatedSurplus = 250,
    expectedEstimatedSurplusPerSkillUp = 312.5,
    resaleConfidence = "two_current_sources",
    resaleReason = "fresh_market_capped_by_min_buyout",
})
assertEqual(scroll.method, "scroll", "scroll execution selected")
assertEqual(scroll.vellumItemID, 43145, "scroll exposes chosen vellum")
assertEqual(scroll.vellumCost, 50, "scroll exposes vellum cost")
assertEqual(scroll.scrollOutputItemID, 44493, "scroll exposes output")
assertEqual(scroll.grossCostPerCraft, 450, "scroll exposes gross craft cost")
assertEqual(scroll.estimatedResalePerCraft, 700, "scroll exposes estimated resale")
assertEqual(scroll.resaleCreditPerCraft, 450, "scroll exposes credited resale")
assertEqual(scroll.effectiveCostPerCraft, 0, "zero effective cost is preserved")
assertEqual(scroll.estimatedSurplusPerCraft, 250, "positive surplus remains separate")
assertEqual(scroll.resaleEvidenceState, "trusted", "trusted resale evidence")
assertEqual(scroll.beforeAuctionHouseFees, true, "resale is explicitly before AH fees")

local missing = addonTable.getSmartestEconomicsPresentation({
    selectedExecutionMethod = "scroll",
    skillUpChance = 1,
    expectedCraftsPerSkillUp = 1,
    directGrossCost = 400,
    vellumItemID = 43145,
    vellumCost = 50,
    scrollOutputItemID = 44493,
    scrollGrossCost = 450,
    resaleEstimate = nil,
    resaleCredit = 0,
    effectiveCostPerCraft = 450,
    expectedEffectiveCostPerSkillUp = 450,
    estimatedSurplus = 0,
    expectedEstimatedSurplusPerSkillUp = 0,
    resaleConfidence = "none",
    resaleReason = "no_price_data",
})
assertEqual(missing.resaleEvidenceState, "unavailable", "missing resale price warning state")
assertEqual(missing.resaleCreditPerCraft, 0, "missing resale cannot reduce cost")

local suspicious = addonTable.getSmartestEconomicsPresentation({
    selectedExecutionMethod = "scroll",
    skillUpChance = 1,
    expectedCraftsPerSkillUp = 1,
    directGrossCost = 400,
    vellumItemID = 43145,
    vellumCost = 50,
    scrollOutputItemID = 44493,
    scrollGrossCost = 450,
    resaleEstimate = 700,
    resaleCredit = 0,
    effectiveCostPerCraft = 450,
    expectedEffectiveCostPerSkillUp = 450,
    estimatedSurplus = 250,
    expectedEstimatedSurplusPerSkillUp = 250,
    resaleConfidence = "rejected_suspicious",
    resaleReason = "suspicious_price",
})
assertEqual(suspicious.resaleEvidenceState, "rejected", "suspicious resale warning state")
assertEqual(suspicious.resaleCreditPerCraft, 0, "suspicious resale cannot reduce cost")
assertEqual(suspicious.estimatedSurplusPerCraft, 250, "informational surplus remains visible")

local comparison = addonTable.getSmartestComparisonPresentation({
    skillUpChance = 0.8,
    expectedCraftsPerSkillUp = 1.25,
    costPerCraft = 0,
    expectedCostPerSkillUp = 35,
    estimatedSurplusPerSkillUp = 312.5,
    cost = {
        selectedExecutionMethod = "scroll",
        skillUpChance = 0.8,
        expectedCraftsPerSkillUp = 1.25,
        directGrossCost = 400,
        scrollGrossCost = 450,
        resaleEstimate = 700,
        resaleCredit = 450,
        effectiveCostPerCraft = 0,
        expectedEffectiveCostPerSkillUp = 0,
        estimatedSurplus = 250,
        expectedEstimatedSurplusPerSkillUp = 312.5,
        resaleConfidence = "two_current_sources",
    },
})
assertNear(comparison.skillUpChance, 0.8, 0.0001, "Compare shows exact skill-up chance")
assertNear(comparison.expectedCrafts, 1.25, 0.0001, "Compare shows expected crafts")
assertEqual(comparison.effectiveCostPerCraft, 0, "Compare shows effective craft cost")
assertEqual(comparison.effectiveCostPerSkillUp, 35, "Compare includes candidate one-time cost in effective skill-up cost")
assertNear(comparison.estimatedSurplusPerSkillUp, 312.5, 0.0001, "Compare exposes estimated surplus tie-break context")

local route = addonTable.getSmartestRoutePresentation({
    complete = true,
    totalGrossLevelingCost = 5000,
    totalResaleCredit = 3000,
    totalEffectiveLevelingCost = 2000,
    totalEstimatedResaleSurplus = 1250,
})
assertEqual(route.grossLevelingCost, 5000, "route gross leveling spend")
assertEqual(route.estimatedResaleCredit, 3000, "route resale value credited")
assertEqual(route.effectiveLevelingCost, 2000, "route effective leveling cost")
assertEqual(route.estimatedSurplus, 1250, "route estimated surplus")

local derivedRoute = addonTable.getSmartestRoutePresentation({
    complete = true,
    totalResaleCredit = 300,
    totalEffectiveLevelingCost = 200,
    totalEstimatedResaleSurplus = 50,
})
assertEqual(derivedRoute.grossLevelingCost, 500, "route gross derives from effective plus credit")

print("Task 44 recommendation presentation tests passed")
