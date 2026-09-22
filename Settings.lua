local addonName, addonTable = ...

local defaults = {
    enabled = true,
    attached = true,
    locked = false,
    recommendationMode = "optimized",
    recommendationObjective = "cheapest",
    recommendationAvailableOnly = false,
    recommendationSettingsVersion = 2,
    detailMode = "compact",
    enchantRepeatMode = "until_change",
    enchantRepeatCount = 5,
    point = "TOPLEFT",
    relativePoint = "BOTTOMLEFT",
    x = 40,
    y = 700,
}

local function migrateRecommendationSettings(db)
    if tonumber(db.recommendationSettingsVersion) == 2 then
        return
    end

    local legacyMode = db.recommendationMode
    if legacyMode == "static" then
        db.recommendationMode = "static"
        if db.recommendationObjective == nil then
            db.recommendationObjective = "cheapest"
        end
        if db.recommendationAvailableOnly == nil then
            db.recommendationAvailableOnly = false
        end
    elseif legacyMode == "available" then
        db.recommendationMode = "optimized"
        db.recommendationObjective = "cheapest"
        db.recommendationAvailableOnly = true
    elseif legacyMode == "dynamic" then
        db.recommendationMode = "optimized"
        db.recommendationObjective = "cheapest"
        db.recommendationAvailableOnly = false
    else
        db.recommendationMode = "optimized"
        if db.recommendationObjective ~= "smartest" then
            db.recommendationObjective = "cheapest"
        end
        if db.recommendationAvailableOnly == nil then
            db.recommendationAvailableOnly = false
        end
    end

    db.recommendationSettingsVersion = 2
end

local function getDB()
    ProfessionCapperDB = ProfessionCapperDB or {}
    migrateRecommendationSettings(ProfessionCapperDB)
    for key, value in pairs(defaults) do
        if ProfessionCapperDB[key] == nil then
            ProfessionCapperDB[key] = value
        end
    end
    return ProfessionCapperDB
end

function addonTable.getSettings()
    return getDB()
end

function addonTable.applyFramePosition(frame)
    local db = getDB()
    frame:ClearAllPoints()

    if db.attached and _G["TradeSkillFrame"] then
        frame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPRIGHT", 4, 0)
        return
    end

    frame:SetPoint(
        db.point or defaults.point,
        UIParent,
        db.relativePoint or defaults.relativePoint,
        db.x or defaults.x,
        db.y or defaults.y
    )
end

function addonTable.detachFrame(frame)
    local db = getDB()
    if not db.attached then
        return
    end

    local left = frame:GetLeft()
    local top = frame:GetTop()
    db.attached = false

    if left and top then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end
end

function addonTable.saveFramePosition(frame)
    local db = getDB()
    if db.attached then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    db.point = point or defaults.point
    db.relativePoint = relativePoint or defaults.relativePoint
    db.x = x or defaults.x
    db.y = y or defaults.y
end

function addonTable.setFrameAttached(frame, attached)
    local db = getDB()
    db.attached = attached and true or false
    addonTable.applyFramePosition(frame)
end

function addonTable.setFrameLocked(locked)
    getDB().locked = locked and true or false
end

function addonTable.setEnabled(enabled)
    getDB().enabled = enabled and true or false
end

local function notifyRecommendationSettingsChanged(changed)
    if changed and type(addonTable.noteRuntimeModeChanged) == "function" then
        addonTable.noteRuntimeModeChanged()
    end
end

function addonTable.setRecommendationMode(mode)
    if mode ~= "dynamic"
        and mode ~= "available"
        and mode ~= "static"
        and mode ~= "optimized"
    then
        return false
    end

    local db = getDB()
    local oldMode = db.recommendationMode
    local oldObjective = db.recommendationObjective
    local oldAvailableOnly = db.recommendationAvailableOnly

    if mode == "static" then
        db.recommendationMode = "static"
    elseif mode == "available" then
        db.recommendationMode = "optimized"
        db.recommendationObjective = "cheapest"
        db.recommendationAvailableOnly = true
    elseif mode == "dynamic" then
        db.recommendationMode = "optimized"
        db.recommendationObjective = "cheapest"
        db.recommendationAvailableOnly = false
    else
        db.recommendationMode = "optimized"
    end

    notifyRecommendationSettingsChanged(
        oldMode ~= db.recommendationMode
        or oldObjective ~= db.recommendationObjective
        or oldAvailableOnly ~= db.recommendationAvailableOnly
    )
    return true
end

function addonTable.setRecommendationObjective(objective)
    if objective ~= "cheapest" and objective ~= "smartest" then
        return false
    end

    local db = getDB()
    local changed = db.recommendationObjective ~= objective
    db.recommendationObjective = objective
    notifyRecommendationSettingsChanged(changed)
    return true
end

function addonTable.setRecommendationAvailableOnly(availableOnly)
    local db = getDB()
    local value = availableOnly and true or false
    local changed = db.recommendationAvailableOnly ~= value
    db.recommendationAvailableOnly = value
    notifyRecommendationSettingsChanged(changed)
    return true
end

function addonTable.setDetailMode(mode)
    if mode ~= "compact" and mode ~= "expanded" then
        return false
    end

    getDB().detailMode = mode
    return true
end

function addonTable.setEnchantRepeatMode(mode)
    if mode ~= "until_change" and mode ~= "fixed" then
        return false
    end

    getDB().enchantRepeatMode = mode
    return true
end

function addonTable.setEnchantRepeatCount(count)
    count = math.floor(tonumber(count) or 0)
    if count < 1 then
        return false
    end

    if count > 999 then
        count = 999
    end

    getDB().enchantRepeatCount = count
    return true
end

function addonTable.resetSettings(frame)
    ProfessionCapperDB = {}
    getDB()
    addonTable.applyFramePosition(frame)
end
