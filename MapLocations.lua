local addonName, addonTable = ...

local ROW_HEIGHT = 46
local VISIBLE_ROWS = 8
local FRAME_WIDTH = 520
local FRAME_HEIGHT = 438

local locationsFrame
local locationsScroll
local locationRows = {}
local visibleLocations = {}
local mapPin
local mapWatcher
local activeMapLocation

local function localized(key, fallback, ...)
    local value = addonTable.L and addonTable.L[key] or fallback
    if select("#", ...) > 0 then
        return string.format(value or fallback, ...)
    end
    return value or fallback
end

local function playerFactionKey()
    if type(UnitFactionGroup) ~= "function" then return nil end
    local ok, faction = pcall(UnitFactionGroup, "player")
    if not ok then return nil end
    faction = string.lower(tostring(faction or ""))
    if faction == "alliance" then return "alliance" end
    if faction == "horde" then return "horde" end
    return nil
end

local function currentZoneName()
    local functions = { GetRealZoneText, GetZoneText }
    for index = 1, table.getn(functions) do
        if type(functions[index]) == "function" then
            local ok, zone = pcall(functions[index])
            if ok and type(zone) == "string" and zone ~= "" then
                return zone
            end
        end
    end
    return nil
end

local function locationCompatible(location, playerFaction)
    local faction = location and location.faction
    if not faction or faction == "" or faction == "neutral" then return true end
    if not playerFaction then return true end
    return faction == playerFaction
end

function addonTable.collectAcquisitionLocations(acquisition)
    if type(acquisition) ~= "table" then return {} end

    local model = type(acquisition.model) == "table" and acquisition.model or acquisition
    local sourceType = model.sourceType
        or acquisition.sourceType
        or acquisition.source
        or model.source
    local playerFaction = playerFactionKey()
    local currentZone = currentZoneName()
    local locations = {}
    local seen = {}

    local function addLocation(location)
        if type(location) ~= "table" or not locationCompatible(location, playerFaction) then
            return
        end

        local coordinates = location.coordinates
        local x = type(coordinates) == "table" and tonumber(coordinates.x or coordinates[1]) or nil
        local y = type(coordinates) == "table" and tonumber(coordinates.y or coordinates[2]) or nil
        local areaID = tonumber(location.areaID or location.zoneID)
        local mapID = tonumber(location.mapID)

        local key = table.concat({
            tostring(location.npcID or ""),
            tostring(location.name or ""),
            tostring(areaID or ""),
            tostring(x or ""),
            tostring(y or ""),
        }, ":")

        if not seen[key] then
            seen[key] = true
            table.insert(locations, {
                npcID = location.npcID,
                name = location.name,
                faction = location.faction,
                zone = location.zone,
                areaID = areaID,
                mapID = mapID,
                coordinates = coordinates,
            })
        end
    end

    local function addSource(source)
        if type(source) ~= "table" then return end

        for index = 1, table.getn(source.locations or {}) do
            addLocation(source.locations[index])
        end

        if source.zone and source.zone ~= "" then
            addLocation({
                name = source.sourceName,
                faction = source.faction,
                zone = source.zone,
                areaID = source.areaID or source.zoneID,
                mapID = source.mapID,
                coordinates = source.coordinates,
            })
        end
    end

    addSource(model)
    if acquisition ~= model then addSource(acquisition) end

    local alternatives = model.alternatives or acquisition.alternatives or {}
    for index = 1, table.getn(alternatives) do
        local alternative = alternatives[index]
        local alternativeType = alternative
            and (alternative.sourceType or alternative.source)
            or nil
        if alternativeType == sourceType then
            addSource(alternative)
        end
    end

    table.sort(locations, function(left, right)
        local function priority(location)
            if currentZone and location.zone == currentZone then return 0 end
            if not location.faction or location.faction == "neutral" then return 1 end
            if playerFaction and location.faction == playerFaction then return 2 end
            return 3
        end

        local leftPriority, rightPriority = priority(left), priority(right)
        if leftPriority ~= rightPriority then return leftPriority < rightPriority end
        if tostring(left.zone or "") ~= tostring(right.zone or "") then
            return tostring(left.zone or "") < tostring(right.zone or "")
        end
        return tostring(left.name or "") < tostring(right.name or "")
    end)

    return locations
end

local function coordinatesText(location)
    local coordinates = location and location.coordinates
    local x = type(coordinates) == "table" and tonumber(coordinates.x or coordinates[1]) or nil
    local y = type(coordinates) == "table" and tonumber(coordinates.y or coordinates[2]) or nil

    if x and y then
        return string.format("%.1f, %.1f", x, y)
    end
    return nil
end

local function locationSubtitle(location)
    local zone = location and location.zone or localized("acquisition_unknown_location", "Unknown location")
    local coordinates = coordinatesText(location)
    if coordinates then
        return tostring(zone) .. "  ·  " .. coordinates
    end
    return tostring(zone)
end

local function mapError(message)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(message, 1, 0.25, 0.25, 1)
    end
end

local function mapPinOnEnter(self)
    local location = self.location
    if not location then return end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(location.name or localized("acquisition_location", "Recipe source"))
    GameTooltip:AddLine(locationSubtitle(location), 0.82, 0.82, 0.82, true)
    GameTooltip:Show()
end

local function mapPinOnLeave()
    GameTooltip:Hide()
end

local function ensureMapPin()
    if mapPin then return mapPin end
    if not WorldMapButton then return nil end

    mapPin = CreateFrame("Button", "ProfessionCapperMapPin", WorldMapButton)
    mapPin:SetWidth(28)
    mapPin:SetHeight(28)
    mapPin:SetFrameLevel(WorldMapButton:GetFrameLevel() + 20)
    mapPin:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    mapPin:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    mapPin:SetScript("OnEnter", mapPinOnEnter)
    mapPin:SetScript("OnLeave", mapPinOnLeave)
    mapPin:Hide()
    return mapPin
end

local function refreshMapPin()
    local location = activeMapLocation
    local pin = ensureMapPin()

    if not pin
        or not location
        or not WorldMapFrame
        or not WorldMapFrame:IsShown()
        or type(GetCurrentMapAreaID) ~= "function"
        or tonumber(GetCurrentMapAreaID()) ~= tonumber(location.mapID)
    then
        if pin then pin:Hide() end
        return
    end

    local coordinates = location.coordinates
    local x = type(coordinates) == "table" and tonumber(coordinates.x or coordinates[1]) or nil
    local y = type(coordinates) == "table" and tonumber(coordinates.y or coordinates[2]) or nil
    if not x or not y then
        pin:Hide()
        return
    end

    pin.location = location
    pin:ClearAllPoints()
    pin:SetPoint(
        "CENTER",
        WorldMapButton,
        "TOPLEFT",
        (x / 100) * WorldMapButton:GetWidth(),
        -(y / 100) * WorldMapButton:GetHeight()
    )
    pin:Show()
end

local function ensureMapWatcher()
    if mapWatcher then return end

    mapWatcher = CreateFrame("Frame")
    mapWatcher:RegisterEvent("WORLD_MAP_UPDATE")
    mapWatcher:SetScript("OnEvent", refreshMapPin)

    if WorldMapFrame and WorldMapFrame.HookScript then
        WorldMapFrame:HookScript("OnHide", function()
            if mapPin then mapPin:Hide() end
        end)
    end
end

function addonTable.showLocationOnMap(location)
    if type(location) ~= "table" then return false end

    local mapID = tonumber(location.mapID)
    if not mapID then
        mapError(localized("acquisition_map_unavailable", "Map unavailable for this location"))
        return false
    end
    if not WorldMapFrame or type(SetMapByID) ~= "function" or type(ShowUIPanel) ~= "function" then
        mapError(localized("acquisition_map_unavailable", "Map unavailable for this location"))
        return false
    end

    if locationsFrame then locationsFrame:Hide() end

    activeMapLocation = location
    ensureMapWatcher()

    WorldMapFrame.blockWorldMapUpdate = true
    ShowUIPanel(WorldMapFrame)
    local ok = pcall(SetMapByID, mapID)
    WorldMapFrame.blockWorldMapUpdate = nil

    if not ok then
        mapError(localized("acquisition_map_unavailable", "Map unavailable for this location"))
        return false
    end

    if type(WorldMapFrame_UpdateMap) == "function" then
        WorldMapFrame_UpdateMap()
    elseif type(WorldMapFrame_Update) == "function" then
        WorldMapFrame_Update()
    end

    refreshMapPin()
    return true
end

local refreshLocationRows

local function createLocationRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(FRAME_WIDTH - 38)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -58 - ((index - 1) * ROW_HEIGHT))

    row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    row.nameText:SetWidth(330)
    row.nameText:SetHeight(18)
    row.nameText:SetJustifyH("LEFT")

    row.locationText = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.locationText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -2)
    row.locationText:SetWidth(330)
    row.locationText:SetHeight(16)
    row.locationText:SetJustifyH("LEFT")

    row.mapButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.mapButton:SetWidth(118)
    row.mapButton:SetHeight(22)
    row.mapButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.mapButton:SetText(localized("acquisition_show_on_map", "Show on map"))
    row.mapButton:SetScript("OnClick", function(self)
        if self.location then
            addonTable.showLocationOnMap(self.location)
        end
    end)

    return row
end

refreshLocationRows = function()
    if not locationsFrame or not locationsScroll then return end

    local count = table.getn(visibleLocations)
    FauxScrollFrame_Update(locationsScroll, count, VISIBLE_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(locationsScroll)

    for rowIndex = 1, VISIBLE_ROWS do
        local row = locationRows[rowIndex]
        local location = visibleLocations[offset + rowIndex]

        if location then
            row.location = location
            row.nameText:SetText(location.name or localized("acquisition_location", "Recipe source"))
            row.locationText:SetText(locationSubtitle(location))
            row.mapButton.location = location
            if location.mapID then
                row.mapButton:Enable()
            else
                row.mapButton:Disable()
            end
            row:Show()
        else
            row.location = nil
            row.mapButton.location = nil
            row:Hide()
        end
    end
end

local function ensureLocationsFrame()
    if locationsFrame then return locationsFrame end

    locationsFrame = CreateFrame("Frame", "ProfessionCapperLocationsFrame", UIParent)
    locationsFrame:SetWidth(FRAME_WIDTH)
    locationsFrame:SetHeight(FRAME_HEIGHT)
    locationsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    locationsFrame:SetFrameStrata("DIALOG")
    locationsFrame:SetClampedToScreen(true)
    locationsFrame:EnableMouse(true)
    locationsFrame:SetMovable(true)
    locationsFrame:RegisterForDrag("LeftButton")
    locationsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    locationsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    locationsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    locationsFrame:SetBackdropColor(0.025, 0.025, 0.025, 0.98)
    locationsFrame:SetBackdropBorderColor(0.22, 0.22, 0.22, 1)
    locationsFrame:Hide()

    locationsFrame.title = locationsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    locationsFrame.title:SetPoint("TOPLEFT", locationsFrame, "TOPLEFT", 18, -16)
    locationsFrame.title:SetText(localized("acquisition_locations_title", "Where to get it"))

    locationsFrame.subtitle = locationsFrame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    locationsFrame.subtitle:SetPoint("TOPLEFT", locationsFrame.title, "BOTTOMLEFT", 0, -4)
    locationsFrame.subtitle:SetText(localized(
        "acquisition_locations_subtitle",
        "All usable trainer/vendor locations for this recipe"
    ))

    local close = CreateFrame("Button", nil, locationsFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", locationsFrame, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() locationsFrame:Hide() end)

    for index = 1, VISIBLE_ROWS do
        locationRows[index] = createLocationRow(locationsFrame, index)
    end

    locationsScroll = CreateFrame(
        "ScrollFrame",
        "ProfessionCapperLocationsScrollFrame",
        locationsFrame,
        "FauxScrollFrameTemplate"
    )
    locationsScroll:SetPoint("TOPLEFT", locationsFrame, "TOPLEFT", 8, -56)
    locationsScroll:SetWidth(FRAME_WIDTH - 28)
    locationsScroll:SetHeight(VISIBLE_ROWS * ROW_HEIGHT)
    locationsScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, refreshLocationRows)
    end)

    return locationsFrame
end

function addonTable.showAcquisitionLocations(acquisition)
    visibleLocations = addonTable.collectAcquisitionLocations(acquisition)
    if table.getn(visibleLocations) == 0 then
        mapError(localized("acquisition_no_locations", "No physical trainer/vendor locations are available"))
        return false
    end

    local frame = ensureLocationsFrame()
    frame.subtitle:SetText(localized(
        "acquisition_locations_count",
        "%d usable locations",
        table.getn(visibleLocations)
    ))
    refreshLocationRows()
    frame:Show()
    return true
end

local detailsLocationsButton
local detailsMapButton

local function ensureDetailButtons()
    if detailsLocationsButton and detailsMapButton then return true end
    if not MainFrameCoreDetails then return false end

    detailsMapButton = CreateFrame("Button", nil, MainFrameCoreDetails, "UIPanelButtonTemplate")
    detailsMapButton:SetWidth(108)
    detailsMapButton:SetHeight(20)
    detailsMapButton:SetPoint("TOPRIGHT", MainFrameCoreDetails, "TOPRIGHT", -4, -18)
    detailsMapButton:SetText(localized("acquisition_show_on_map", "Show on map"))
    detailsMapButton:SetScript("OnClick", function(self)
        if self.location then addonTable.showLocationOnMap(self.location) end
    end)

    detailsLocationsButton = CreateFrame("Button", nil, MainFrameCoreDetails, "UIPanelButtonTemplate")
    detailsLocationsButton:SetWidth(102)
    detailsLocationsButton:SetHeight(20)
    detailsLocationsButton:SetPoint("RIGHT", detailsMapButton, "LEFT", -4, 0)
    detailsLocationsButton:SetScript("OnClick", function(self)
        if self.acquisition then addonTable.showAcquisitionLocations(self.acquisition) end
    end)

    return true
end

function addonTable.updateAcquisitionLocationControls(acquisition)
    if not ensureDetailButtons() then return end

    local locations = addonTable.collectAcquisitionLocations(acquisition)
    if table.getn(locations) == 0 then
        detailsLocationsButton:Hide()
        detailsMapButton:Hide()
        if txtDetailsSource and txtDetailsSource.SetWidth then txtDetailsSource:SetWidth(500) end
        return
    end

    detailsLocationsButton.acquisition = acquisition
    detailsLocationsButton:SetText(localized(
        "acquisition_locations_button",
        "Locations (%d)",
        table.getn(locations)
    ))
    detailsLocationsButton:Show()

    detailsMapButton.location = locations[1]
    detailsMapButton:SetText(localized("acquisition_show_on_map", "Show on map"))
    if locations[1].mapID then
        detailsMapButton:Enable()
    else
        detailsMapButton:Disable()
    end
    detailsMapButton:Show()

    if txtDetailsSource and txtDetailsSource.SetWidth then txtDetailsSource:SetWidth(282) end
end
