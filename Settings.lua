local addonName, addonTable = ...

local defaults = {
    enabled = true,
    attached = true,
    locked = false,
    recommendationMode = "dynamic",
    enchantRepeatMode = "until_change",
    enchantRepeatCount = 5,
    point = "TOPLEFT",
    relativePoint = "BOTTOMLEFT",
    x = 40,
    y = 700,
}

local function getDB()
    ProfessionCapperDB = ProfessionCapperDB or {}
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

function addonTable.setRecommendationMode(mode)
    if mode ~= "dynamic" and mode ~= "static" then
        return false
    end

    getDB().recommendationMode = mode
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
