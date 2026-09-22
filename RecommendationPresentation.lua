local addonName, addonTable = ...

local function finiteNumber(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then
        return nil
    end
    return number
end

local function nonNegativeNumber(value)
    local number = finiteNumber(value)
    if number == nil or number < 0 then
        return nil
    end
    return number
end

function addonTable.getRecommendationPresentationState(settings)
    settings = settings or {}

    local objective = settings.recommendationObjective == "smartest"
        and "smartest"
        or "cheapest"
    local static = settings.recommendationMode == "static"

    return {
        mode = static and "static" or objective,
        objective = objective,
        static = static,
        cheapest = not static and objective == "cheapest",
        smartest = not static and objective == "smartest",
        availableOnly = settings.recommendationAvailableOnly == true,
        availableEnabled = not static,
    }
end

local function resaleEvidenceState(method, estimate, confidence)
    if method ~= "scroll" then
        return "not_applicable"
    end
    if estimate == nil then
        return "unavailable"
    end

    confidence = tostring(confidence or "")
    if string.sub(confidence, 1, 9) == "rejected_" then
        return "rejected"
    end
    if confidence == "none" then
        return "unavailable"
    end
    if confidence == "context_only"
        or confidence == "single_current_source"
        or confidence == "rejected_freshness_unknown"
    then
        return "weak"
    end
    return "trusted"
end

function addonTable.getSmartestEconomicsPresentation(cost)
    if type(cost) ~= "table" then
        return nil
    end

    local method = cost.selectedExecutionMethod == "scroll" and "scroll" or "direct"
    local materialCost = nonNegativeNumber(cost.directGrossCost)
        or nonNegativeNumber(cost.materialMarketValuePerCraft)
    local grossCost = method == "scroll"
        and nonNegativeNumber(cost.scrollGrossCost)
        or materialCost
    local resaleEstimate = method == "scroll"
        and nonNegativeNumber(cost.resaleEstimate)
        or nil
    local resaleCredit = method == "scroll"
        and (nonNegativeNumber(cost.resaleCredit) or 0)
        or 0
    local surplus = method == "scroll"
        and (nonNegativeNumber(cost.estimatedSurplus) or 0)
        or 0

    return {
        method = method,
        skillUpChance = nonNegativeNumber(cost.skillUpChance),
        expectedCrafts = nonNegativeNumber(cost.expectedCraftsPerSkillUp),
        materialCostPerCraft = materialCost,
        vellumItemID = method == "scroll" and tonumber(cost.vellumItemID) or nil,
        vellumCost = method == "scroll" and nonNegativeNumber(cost.vellumCost) or nil,
        scrollOutputItemID = method == "scroll" and tonumber(cost.scrollOutputItemID) or nil,
        grossCostPerCraft = grossCost,
        estimatedResalePerCraft = resaleEstimate,
        resaleCreditPerCraft = resaleCredit,
        effectiveCostPerCraft = nonNegativeNumber(cost.effectiveCostPerCraft),
        effectiveCostPerSkillUp = nonNegativeNumber(cost.expectedEffectiveCostPerSkillUp),
        estimatedSurplusPerCraft = surplus,
        estimatedSurplusPerSkillUp = method == "scroll"
            and (nonNegativeNumber(cost.expectedEstimatedSurplusPerSkillUp) or 0)
            or 0,
        resaleConfidence = cost.resaleConfidence,
        resaleReason = cost.resaleReason,
        resaleEvidenceState = resaleEvidenceState(method, resaleEstimate, cost.resaleConfidence),
        resaleCredited = resaleCredit > 0,
        hasPositiveSurplus = surplus > 0,
        beforeAuctionHouseFees = method == "scroll" and resaleEstimate ~= nil,
    }
end

function addonTable.getSmartestComparisonPresentation(candidate)
    if type(candidate) ~= "table" then
        return nil
    end

    local cost = type(candidate.cost) == "table" and candidate.cost or {}
    local economics = addonTable.getSmartestEconomicsPresentation(cost)
    if not economics then
        return nil
    end

    return {
        skillUpChance = nonNegativeNumber(candidate.skillUpChance)
            or economics.skillUpChance,
        expectedCrafts = nonNegativeNumber(candidate.expectedCraftsPerSkillUp)
            or economics.expectedCrafts,
        effectiveCostPerCraft = nonNegativeNumber(candidate.costPerCraft)
            or economics.effectiveCostPerCraft,
        effectiveCostPerSkillUp = nonNegativeNumber(candidate.expectedCostPerSkillUp)
            or economics.effectiveCostPerSkillUp,
        estimatedSurplusPerSkillUp =
            nonNegativeNumber(candidate.estimatedSurplusPerSkillUp) or 0,
    }
end

function addonTable.getSmartestRoutePresentation(plan)
    if type(plan) ~= "table" or plan.complete ~= true then
        return nil
    end

    local effective = nonNegativeNumber(plan.totalEffectiveLevelingCost)
    local credited = nonNegativeNumber(plan.totalResaleCredit) or 0
    local gross = nonNegativeNumber(plan.totalGrossLevelingCost)
    local surplus = nonNegativeNumber(plan.totalEstimatedResaleSurplus) or 0

    if gross == nil and effective ~= nil then
        gross = effective + credited
    end
    if gross == nil or effective == nil then
        return nil
    end

    return {
        grossLevelingCost = gross,
        estimatedResaleCredit = credited,
        effectiveLevelingCost = effective,
        estimatedSurplus = surplus,
    }
end
