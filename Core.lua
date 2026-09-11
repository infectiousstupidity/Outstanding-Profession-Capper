-- Profession Capper v3
local addonName, addonTable = ...

local professionContext
local shouldCraft = {}
local shouldCraftRecipe = {}
local targetSkill
local craftRecipeOptionsIndex = 1
local previousRecipeKey = ""
local recipeCache = {}
local transientSpellIndexMap = {}
local materialRows = {}
local dynamicRecommendation

local MATERIAL_ROW_HEIGHT = 38
local MATERIALS_TOP = 300
local FOOTER_SPACE = 66
local REPEAT_FOOTER_SPACE = 94
local MIN_PANEL_HEIGHT = 390
local MATERIAL_ROW_WIDTH = 384
local MATERIAL_NAME_WIDTH = 220
local MATERIAL_BUY_WIDTH = 272

local tradeSkillStateMutation = false
local suppressTradeSkillUpdatesUntil = 0

local UNKNOWN_ICON = "Interface\\InventoryItems\\WoWUnknownItem01"
local ENGRAVING_ICON = "Interface\\Icons\\Trade_Engraving"
local INSCRIPTION_FALLBACK_ICON = "Interface\\Icons\\Spell_Holy_GreaterHeal"

local function extractRecipeSpellID(link)
    if not link then
        return nil
    end

    local id = link:match("spell:(%d+)") or link:match("enchant:(%d+)")
    return id and tonumber(id) or nil
end

local function getSelectedFilter(listFunction, filterFunction)
    if not listFunction or not filterFunction then
        return 0
    end

    if filterFunction(0) then
        return 0
    end

    local values = { listFunction() }
    for i = 1, table.getn(values) do
        if filterFunction(i) then
            return i
        end
    end

    return 0
end

local function getTradeSkillFilterTable()
    local frame = _G["TradeSkillFrame"]
    return frame and frame.filterTbl or nil
end

local function getFilterCheckboxValue(frameName)
    local frame = _G[frameName]
    if frame and frame.GetChecked then
        return frame:GetChecked() and true or false
    end
    return false
end

local function setFilterCheckboxValue(frameName, value)
    local frame = _G[frameName]
    if frame and frame.SetChecked then
        frame:SetChecked(value and true or false)
    end
end

local function makeHeaderKey(name, occurrence)
    return tostring(name or "") .. "\031" .. tostring(occurrence)
end

local function snapshotHeaderStates()
    local states = {}
    local occurrences = {}

    for i = 1, GetNumTradeSkills() do
        local name, skillType, _, isExpanded = GetTradeSkillInfo(i)
        if skillType == "header" then
            occurrences[name] = (occurrences[name] or 0) + 1
            states[makeHeaderKey(name, occurrences[name])] = isExpanded and true or false
        end
    end

    return states
end

local function snapshotTradeSkillView()
    local state = {
        headers = snapshotHeaderStates(),
        itemNameFilter = GetTradeSkillItemNameFilter and GetTradeSkillItemNameFilter() or "",
        subClassFilter = getSelectedFilter(GetTradeSkillSubClasses, GetTradeSkillSubClassFilter),
        invSlotFilter = getSelectedFilter(GetTradeSkillInvSlots, GetTradeSkillInvSlotFilter),
    }

    if GetTradeSkillItemLevelFilter then
        state.minItemLevel, state.maxItemLevel = GetTradeSkillItemLevelFilter()
    else
        state.minItemLevel, state.maxItemLevel = 0, 0
    end

    local filterTable = getTradeSkillFilterTable()
    if filterTable then
        state.hasMaterials = filterTable.hasMaterials and true or false
        state.hasSkillUp = filterTable.hasSkillUp and true or false
        state.filterSubClassValue = filterTable.subClassValue
        state.filterSlotValue = filterTable.slotValue
    else
        state.hasMaterials = getFilterCheckboxValue("TradeSkillFrameAvailableFilterCheckButton")
        state.hasSkillUp = getFilterCheckboxValue("TradeSkillFrameSkillUpFilterCheckButton")
    end

    if GetTradeSkillSelectionIndex then
        local selectedIndex = GetTradeSkillSelectionIndex()
        if selectedIndex and selectedIndex > 0 then
            state.selectedSpellID = extractRecipeSpellID(GetTradeSkillRecipeLink(selectedIndex))
        end
    end

    local scrollBar = _G["TradeSkillListScrollFrameScrollBar"]
    if scrollBar and scrollBar.GetValue then
        state.scrollValue = scrollBar:GetValue()
    end

    return state
end

local function clearTradeSkillFilters()
    if SetTradeSkillSubClassFilter then
        SetTradeSkillSubClassFilter(0, 1, 1)
    end

    if SetTradeSkillInvSlotFilter then
        SetTradeSkillInvSlotFilter(0, 1, 1)
    end

    if SetTradeSkillItemNameFilter then
        SetTradeSkillItemNameFilter("")
    end

    if SetTradeSkillItemLevelFilter then
        SetTradeSkillItemLevelFilter(0, 0)
    end

    if TradeSkillOnlyShowMakeable then
        TradeSkillOnlyShowMakeable(false)
    end

    if TradeSkillOnlyShowSkillUps then
        TradeSkillOnlyShowSkillUps(false)
    end

    local filterTable = getTradeSkillFilterTable()
    if filterTable then
        filterTable.hasMaterials = false
        filterTable.hasSkillUp = false
        filterTable.subClassValue = -1
        filterTable.slotValue = -1
    end
end

local function expandAllTradeSkillHeaders()
    local pass = 0
    local changed = true

    while changed and pass < 10 do
        changed = false
        pass = pass + 1

        for i = GetNumTradeSkills(), 1, -1 do
            local _, skillType, _, isExpanded = GetTradeSkillInfo(i)
            if skillType == "header" and not isExpanded then
                ExpandTradeSkillSubClass(i)
                changed = true
            end
        end
    end
end

local function restoreHeaderStates(savedStates)
    if not savedStates then
        return
    end

    local occurrences = {}
    local headers = {}

    for i = 1, GetNumTradeSkills() do
        local name, skillType = GetTradeSkillInfo(i)
        if skillType == "header" then
            occurrences[name] = (occurrences[name] or 0) + 1
            table.insert(headers, {
                index = i,
                key = makeHeaderKey(name, occurrences[name]),
            })
        end
    end

    for i = table.getn(headers), 1, -1 do
        local header = headers[i]
        if savedStates[header.key] == false then
            CollapseTradeSkillSubClass(header.index)
        end
    end
end

local function restoreSelectedRecipe(spellID)
    if not spellID or not SelectTradeSkill then
        return
    end

    for i = 1, GetNumTradeSkills() do
        if extractRecipeSpellID(GetTradeSkillRecipeLink(i)) == spellID then
            SelectTradeSkill(i)
            return
        end
    end
end

local function restoreTradeSkillView(state)
    if SetTradeSkillItemNameFilter then
        SetTradeSkillItemNameFilter(state.itemNameFilter or "")
    end

    if SetTradeSkillItemLevelFilter then
        SetTradeSkillItemLevelFilter(state.minItemLevel or 0, state.maxItemLevel or 0)
    end

    if SetTradeSkillSubClassFilter then
        SetTradeSkillSubClassFilter(state.subClassFilter or 0, 1, 1)
    end

    if SetTradeSkillInvSlotFilter then
        SetTradeSkillInvSlotFilter(state.invSlotFilter or 0, 1, 1)
    end

    if TradeSkillOnlyShowMakeable then
        TradeSkillOnlyShowMakeable(state.hasMaterials and true or false)
    end

    if TradeSkillOnlyShowSkillUps then
        TradeSkillOnlyShowSkillUps(state.hasSkillUp and true or false)
    end

    local filterTable = getTradeSkillFilterTable()
    if filterTable then
        filterTable.hasMaterials = state.hasMaterials and true or false
        filterTable.hasSkillUp = state.hasSkillUp and true or false
        filterTable.subClassValue = state.filterSubClassValue
        filterTable.slotValue = state.filterSlotValue
    end

    setFilterCheckboxValue("TradeSkillFrameAvailableFilterCheckButton", state.hasMaterials)
    setFilterCheckboxValue("TradeSkillFrameSkillUpFilterCheckButton", state.hasSkillUp)

    restoreHeaderStates(state.headers)
    restoreSelectedRecipe(state.selectedSpellID)

    local scrollBar = _G["TradeSkillListScrollFrameScrollBar"]
    if state.scrollValue and scrollBar and scrollBar.SetValue then
        scrollBar:SetValue(state.scrollValue)
    end

    if TradeSkillUpdateFilterBar then
        TradeSkillUpdateFilterBar()
    end
end

local function withUnfilteredTradeSkill(callback)
    if tradeSkillStateMutation then
        return false
    end

    local state = snapshotTradeSkillView()
    tradeSkillStateMutation = true

    local ok, errorMessage = pcall(function()
        clearTradeSkillFilters()
        expandAllTradeSkillHeaders()
        callback()
    end)

    local restoreOk, restoreError = pcall(function()
        restoreTradeSkillView(state)
    end)

    tradeSkillStateMutation = false
    suppressTradeSkillUpdatesUntil = GetTime() + 0.10

    if not restoreOk then
        geterrorhandler()(restoreError)
    end

    if not ok then
        geterrorhandler()(errorMessage)
        return false
    end

    return restoreOk
end

local function buildRecipeCache()
    recipeCache = {}
    transientSpellIndexMap = {}

    for i = 1, GetNumTradeSkills() do
        local spellID = extractRecipeSpellID(GetTradeSkillRecipeLink(i))
        if spellID then
            local skillName, skillType, numAvailable = GetTradeSkillInfo(i)

            transientSpellIndexMap[spellID] = i
            local outputItemLink = GetTradeSkillItemLink and GetTradeSkillItemLink(i) or nil
            local outputCount
            if GetTradeSkillNumMade then
                local minMade, maxMade = GetTradeSkillNumMade(i)
                if minMade and minMade > 0 and (not maxMade or minMade == maxMade) then
                    outputCount = minMade
                end
            end

            recipeCache[spellID] = {
                name = skillName,
                skillType = skillType,
                numAvailable = numAvailable or 0,
                icon = GetTradeSkillIcon(i),
                outputItemLink = outputItemLink,
                outputCount = outputCount,
            }
        end
    end
end

local function cacheRecipeReagents(spellID)
    local data = recipeCache[spellID]
    local recipeIndex = transientSpellIndexMap[spellID]

    if not data or not recipeIndex then
        return
    end

    data.reagents = {}
    local numReagents = GetTradeSkillNumReagents(recipeIndex)

    for i = 1, numReagents do
        local reagentName, reagentTexture, reagentCount, reagentOwned = GetTradeSkillReagentInfo(recipeIndex, i)
        if reagentName then
            local itemLink
            if GetTradeSkillReagentItemLink then
                itemLink = GetTradeSkillReagentItemLink(recipeIndex, i)
            end

            table.insert(data.reagents, {
                name = reagentName,
                texture = reagentTexture,
                itemLink = itemLink,
                itemID = addonTable.getItemIDFromLink and addonTable.getItemIDFromLink(itemLink) or nil,
                count = reagentCount or 0,
                owned = reagentOwned or 0,
            })
        end
    end
end

local function cacheAllRecipeReagents()
    for spellID in pairs(recipeCache) do
        cacheRecipeReagents(spellID)
    end
end

local function cacheRecommendedRecipeDetails()
    if not shouldCraft then
        return
    end

    for i = 1, table.getn(shouldCraft) do
        cacheRecipeReagents(shouldCraft[i])
    end
end

local function getNumAvailableForSpell(spellID)
    local data = recipeCache[spellID]
    return data and data.numAvailable or 0
end

function addonTable.sortRecipesByNumAvailable(recipes)
    table.sort(recipes, function(spellIdA, spellIdB)
        return getNumAvailableForSpell(spellIdA) > getNumAvailableForSpell(spellIdB)
    end)
end

local function formatDuration(seconds)
    seconds = math.max(0, math.ceil(seconds))
    if seconds < 60 then
        return seconds .. "s"
    end

    local minutes = math.floor(seconds / 60)
    local remainder = seconds - (minutes * 60)
    if remainder == 0 then
        return minutes .. "m"
    end

    return minutes .. "m " .. remainder .. "s"
end

local function getCraftTimeSeconds(spellId)
    local _, _, _, _, _, _, castTime = GetSpellInfo(spellId)
    if not castTime or castTime <= 0 then
        return nil
    end

    return castTime / 1000
end

local function formatSkillUps(count)
    if count == 1 then
        return addonTable.L["skill_up_one"]
    end

    return string.format(addonTable.L["skill_up_many"], count)
end

local function clearMaterialRows()
    for i = 1, table.getn(materialRows) do
        materialRows[i]:Hide()
        materialRows[i].itemLink = nil
        materialRows[i].reagentName = nil
        materialRows[i].searchName = nil
        materialRows[i].purchaseName = nil
        materialRows[i].priceInfo = nil
        if materialRows[i].buy then
            materialRows[i].buy:SetText("")
        end
    end

    if txtMaterialsLabel then
        txtMaterialsLabel:Hide()
    end
end

local function setAuctionSearchText(reagentName)
    local auctionFrame = _G["AuctionFrame"]
    local browseName = _G["BrowseName"]

    if auctionFrame and auctionFrame:IsShown() and browseName then
        browseName:SetText(reagentName)
        if browseName.SetFocus then
            browseName:SetFocus()
        end
        if browseName.HighlightText then
            browseName:HighlightText()
        end
        return true
    end

    if UIErrorsFrame and addonTable.L["auction_house_not_open"] then
        UIErrorsFrame:AddMessage(addonTable.L["auction_house_not_open"], 1, 0.25, 0.25, 1)
    end

    return false
end

local function materialRowOnEnter(self)
    self.highlight:Show()

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.itemLink then
        GameTooltip:SetHyperlink(self.itemLink)
    else
        GameTooltip:SetText(self.reagentName or "")
    end
    if self.priceInfo and self.priceInfo.neededQuantity and self.priceInfo.neededQuantity > 0 then
        GameTooltip:AddLine(" ")
        if self.priceInfo.available then
            GameTooltip:AddLine(string.format(
                addonTable.L["material_price_unit"],
                addonTable.formatCopperShort(self.priceInfo.unitPrice)
            ), 0.82, 0.82, 0.82, true)
            GameTooltip:AddLine(string.format(
                addonTable.L["material_price_remaining"],
                addonTable.formatCopperShort(self.priceInfo.estimatedRemainingCost)
            ), 0.82, 0.82, 0.82, true)
            GameTooltip:AddLine(string.format(
                addonTable.L["material_price_source"],
                tostring(self.priceInfo.source or "unknown"),
                tostring(self.priceInfo.freshness or "unknown"),
                addonTable.formatPriceAge(self.priceInfo.ageSeconds)
            ), 0.65, 0.65, 0.65, true)
            if self.priceInfo.converted and self.priceInfo.sourceItemID then
                local sourceName = self.purchaseName
                    or GetItemInfo(self.priceInfo.sourceItemID)
                    or ("item " .. tostring(self.priceInfo.sourceItemID))
                local sourceQuantity = math.max(1, math.ceil(tonumber(self.priceInfo.sourceQuantity) or 1))
                local producedQuantity = math.max(
                    tonumber(self.priceInfo.requestedQuantity) or 0,
                    tonumber(self.priceInfo.producedQuantity) or 0
                )

                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(addonTable.L["material_buy_better_title"], 0.35, 1, 0.35, true)
                GameTooltip:AddLine(string.format(
                    addonTable.L["material_buy_conversion"],
                    sourceQuantity,
                    sourceName,
                    producedQuantity,
                    self.reagentName or "requested material"
                ), 0.82, 0.82, 0.82, true)

                if self.priceInfo.directTotalCost and self.priceInfo.estimatedRemainingCost then
                    GameTooltip:AddLine(string.format(
                        addonTable.L["material_buy_compare"],
                        addonTable.formatCopperShort(self.priceInfo.directTotalCost),
                        addonTable.formatCopperShort(self.priceInfo.estimatedRemainingCost)
                    ), 0.82, 0.82, 0.82, true)
                end

                if self.priceInfo.savings and self.priceInfo.savings > 0 then
                    GameTooltip:AddLine(string.format(
                        addonTable.L["material_buy_savings"],
                        addonTable.formatCopperShort(self.priceInfo.savings)
                    ), 0.35, 1, 0.35, true)
                end
            end
        else
            GameTooltip:AddLine(string.format(
                addonTable.L["material_price_missing"],
                tostring(self.priceInfo.reason or "unavailable")
            ), 1, 0.35, 0.35, true)
        end
    end

    GameTooltip:AddLine(addonTable.L["material_tooltip_hint"], 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

local function materialRowOnLeave(self)
    self.highlight:Hide()
    GameTooltip:Hide()
end

local function materialRowOnClick(self, button)
    if button == "RightButton" and IsShiftKeyDown() then
        setAuctionSearchText(self.searchName or self.reagentName)
        return
    end

    if self.itemLink and IsModifiedClick() and HandleModifiedItemClick then
        HandleModifiedItemClick(self.itemLink)
    end
end

local function getMaterialRow(index)
    if materialRows[index] then
        return materialRows[index]
    end

    local row = CreateFrame("Button", nil, MainFrameCoreMaterials)
    row:SetWidth(MATERIAL_ROW_WIDTH)
    row:SetHeight(34)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnEnter", materialRowOnEnter)
    row:SetScript("OnLeave", materialRowOnLeave)
    row:SetScript("OnClick", materialRowOnClick)

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints(row)
    row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.highlight:SetBlendMode("ADD")
    row.highlight:SetAlpha(0.22)
    row.highlight:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(22)
    row.icon:SetHeight(22)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1)
    row.name:SetWidth(MATERIAL_NAME_WIDTH)
    row.name:SetHeight(15)
    row.name:SetJustifyH("LEFT")

    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.count:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -1)
    row.count:SetWidth(80)
    row.count:SetHeight(15)
    row.count:SetJustifyH("RIGHT")

    row.buy = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.buy:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 8, 1)
    row.buy:SetWidth(MATERIAL_BUY_WIDTH)
    row.buy:SetHeight(15)
    row.buy:SetJustifyH("LEFT")

    row.price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.price:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 1)
    row.price:SetWidth(96)
    row.price:SetHeight(15)
    row.price:SetJustifyH("RIGHT")

    materialRows[index] = row
    return row
end

local function renderMaterials(reagents, plannedCrafts)
    clearMaterialRows()

    local count = table.getn(reagents or {})
    if count == 0 then
        return 0
    end

    txtMaterialsLabel:Show()

    local purchaseTotal = 0
    local purchaseComplete = true

    for i = 1, count do
        local reagent = reagents[i]
        local totalRequired = reagent.count * math.max(1, plannedCrafts or 1)
        local owned = reagent.owned or 0
        local row = getMaterialRow(i)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", MainFrameCoreMaterials, "TOPLEFT", 0, -((i - 1) * MATERIAL_ROW_HEIGHT))
        local needed = math.max(0, totalRequired - owned)
        local priceItem = reagent.itemID or reagent.itemLink or reagent.name
        local priceInfo = addonTable.getMaterialPriceInfo
            and addonTable.getMaterialPriceInfo(priceItem, needed)
            or nil

        row.itemLink = reagent.itemLink
        row.reagentName = reagent.name
        row.searchName = reagent.name
        row.purchaseName = nil
        row.priceInfo = priceInfo
        row.icon:SetTexture(reagent.texture or UNKNOWN_ICON)
        row.name:SetText(reagent.name)
        row.count:SetText(owned .. " / " .. totalRequired)
        row.buy:SetText("")

        if needed <= 0 then
            row.price:SetText("")
        elseif priceInfo and priceInfo.available then
            row.price:SetText("~" .. addonTable.formatCopperShort(priceInfo.estimatedRemainingCost))
            if priceInfo.isStale then
                row.price:SetTextColor(1, 0.72, 0.22)
            else
                row.price:SetTextColor(0.78, 0.78, 0.78)
            end

            purchaseTotal = purchaseTotal + (tonumber(priceInfo.estimatedRemainingCost) or 0)

            if priceInfo.converted and priceInfo.sourceItemID then
                local sourceName = GetItemInfo(priceInfo.sourceItemID)
                    or ("item " .. tostring(priceInfo.sourceItemID))
                local sourceQuantity = math.max(1, math.ceil(tonumber(priceInfo.sourceQuantity) or 1))
                row.purchaseName = sourceName
                row.searchName = sourceName

                local savings = tonumber(priceInfo.savings) or 0
                if savings > 0 then
                    row.buy:SetText(string.format(
                        addonTable.L["material_buy_instead_savings"],
                        sourceQuantity,
                        sourceName,
                        addonTable.formatCopperShort(savings)
                    ))
                else
                    row.buy:SetText(string.format(
                        addonTable.L["material_buy_instead"],
                        sourceQuantity,
                        sourceName
                    ))
                end
            else
                row.buy:SetText(string.format(
                    addonTable.L["material_buy_quantity"],
                    needed
                ))
            end
        else
            purchaseComplete = false
            row.price:SetText(addonTable.L["material_no_price"])
            row.price:SetTextColor(1, 0.35, 0.35)
        end

        local _, _, quality = GetItemInfo(reagent.itemLink or reagent.name)
        if quality then
            local r, g, b = GetItemQualityColor(quality)
            row.name:SetTextColor(r, g, b)
        else
            row.name:SetTextColor(1, 1, 1)
        end

        if owned < totalRequired then
            row.count:SetTextColor(1, 0.35, 0.35)
        else
            row.count:SetTextColor(0.92, 0.92, 0.92)
        end

        row:Show()
    end

    return count, purchaseTotal, purchaseComplete
end

local function updatePanelHeight(materialCount, showRepeatControls)
    local footerSpace = showRepeatControls and REPEAT_FOOTER_SPACE or FOOTER_SPACE
    local requiredHeight = MATERIALS_TOP + (materialCount * MATERIAL_ROW_HEIGHT) + footerSpace
    MainFrameCore:SetHeight(math.max(MIN_PANEL_HEIGHT, requiredHeight))
end

local function recipeKey(recipes)
    local parts = {}
    for i = 1, table.getn(recipes) do
        parts[i] = tostring(recipes[i])
    end
    return table.concat(parts, ":")
end

local function findVisibleRecipeIndex(spellID)
    for i = 1, GetNumTradeSkills() do
        if extractRecipeSpellID(GetTradeSkillRecipeLink(i)) == spellID then
            return i
        end
    end

    return nil
end

local ENCHANTING_PROFESSIONS = {
    ["Enchanting"] = true,
    ["Encantamiento"] = true,
    ["Наложение чар"] = true,
}

local targetHooksInstalled = false

local function isTargetedEnchantRecipe(spellID)
    local data = recipeCache[spellID]
    return professionContext
        and ENCHANTING_PROFESSIONS[professionContext.professionName]
        and data
        and not data.outputItemLink
end

local function getEnchantRepeatSettings()
    local db = addonTable.getSettings()
    local mode = db.enchantRepeatMode == "fixed" and "fixed" or "until_change"
    local count = math.max(1, math.min(999, math.floor(tonumber(db.enchantRepeatCount) or 5)))
    return mode, count
end

local function updateEnchantRepeatControls(visible)
    if not MainFrameCoreRepeatMode or not MainFrameCoreRepeatCount or not txtRepeatLabel then
        return
    end

    if not visible then
        txtRepeatLabel:Hide()
        MainFrameCoreRepeatMode:Hide()
        MainFrameCoreRepeatCount:Hide()
        return
    end

    local mode, count = getEnchantRepeatSettings()
    txtRepeatLabel:SetText(addonTable.L["repeat_label"])
    txtRepeatLabel:Show()

    MainFrameCoreRepeatMode:SetText(
        mode == "fixed"
            and addonTable.L["repeat_fixed"]
            or addonTable.L["repeat_until_change"]
    )
    MainFrameCoreRepeatMode:Show()

    if not MainFrameCoreRepeatCount:HasFocus() then
        MainFrameCoreRepeatCount:SetText(tostring(count))
    end
    if mode == "fixed" then
        MainFrameCoreRepeatCount:Enable()
        MainFrameCoreRepeatCount:SetTextColor(1, 1, 1)
    else
        MainFrameCoreRepeatCount:Disable()
        MainFrameCoreRepeatCount:SetTextColor(0.5, 0.5, 0.5)
    end
    MainFrameCoreRepeatCount:Show()
end

function toggleEnchantRepeatMode()
    local mode = getEnchantRepeatSettings()
    addonTable.setEnchantRepeatMode(mode == "fixed" and "until_change" or "fixed")
    if targetSkill then
        displayRecipe()
    end
end

function enchantRepeatCountChanged(editBox)
    if not editBox or not editBox.GetText then
        return
    end

    local text = editBox:GetText()
    if not text or text == "" then
        return
    end

    local count = tonumber(text)
    if count and count >= 1 then
        addonTable.setEnchantRepeatCount(count)
    end
end

function enchantRepeatCountCommit(editBox)
    local _, count = getEnchantRepeatSettings()
    if editBox then
        local entered = tonumber(editBox:GetText())
        if entered and addonTable.setEnchantRepeatCount(entered) then
            _, count = getEnchantRepeatSettings()
        end
        editBox:SetText(tostring(count))
        editBox:ClearFocus()
    end
    if targetSkill then
        displayRecipe()
    end
end

local function captureEnchantTarget(kind, bag, slot)
    local session = addonTable.getCraftSession()
    if not session or session.mode ~= "targeted_enchant" or not session.active then
        return
    end

    local itemLink
    if kind == "bag" and GetContainerItemLink then
        itemLink = GetContainerItemLink(bag, slot)
    elseif kind == "inventory" and GetInventoryItemLink then
        itemLink = GetInventoryItemLink("player", slot)
    end

    local itemID = addonTable.getItemIDFromLink and addonTable.getItemIDFromLink(itemLink) or nil
    addonTable.setCraftSessionTarget(kind, bag, slot, itemID)

    if type(addonTable.confirmReplaceEnchantIfVisible) == "function" then
        addonTable.confirmReplaceEnchantIfVisible()
    end
end

local function installEnchantTargetHooks()
    if targetHooksInstalled or not hooksecurefunc then
        return
    end
    targetHooksInstalled = true

    if UseContainerItem then
        hooksecurefunc("UseContainerItem", function(bag, slot)
            captureEnchantTarget("bag", bag, slot)
        end)
    end

    if PickupInventoryItem then
        hooksecurefunc("PickupInventoryItem", function(slot)
            captureEnchantTarget("inventory", nil, slot)
        end)
    end
end

local function targetStillMatches(target)
    if not target then
        return false
    end

    local itemLink
    if target.kind == "bag" and GetContainerItemLink then
        itemLink = GetContainerItemLink(target.bag, target.slot)
    elseif target.kind == "inventory" and GetInventoryItemLink then
        itemLink = GetInventoryItemLink("player", target.slot)
    end

    if not itemLink then
        return false
    end

    if target.itemID and addonTable.getItemIDFromLink then
        return addonTable.getItemIDFromLink(itemLink) == target.itemID
    end

    return true
end

local function reuseRememberedEnchantTarget()
    local target = addonTable.getCraftSessionTarget()
    if not target or not targetStillMatches(target) then
        addonTable.clearCraftSessionTarget()
        return false
    end

    if not SpellCanTargetItem or not SpellCanTargetItem() then
        return false
    end

    if target.kind == "bag" and UseContainerItem then
        UseContainerItem(target.bag, target.slot)
        if type(addonTable.confirmReplaceEnchantIfVisible) == "function" then
            addonTable.confirmReplaceEnchantIfVisible()
        end
        return true
    elseif target.kind == "inventory" and PickupInventoryItem then
        PickupInventoryItem(target.slot)
        if type(addonTable.confirmReplaceEnchantIfVisible) == "function" then
            addonTable.confirmReplaceEnchantIfVisible()
        end
        return true
    end

    return false
end

local professionHandlers = {
    ["Enchanting"] = function(r) return addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(r) end,
    ["Tailoring"] = function(r) return addonTable.getTailoringCurrentSkillLevelRecipeToCraft(r) end,
    ["Jewelcrafting"] = function(r) return addonTable.getJewelcraftingCurrentSkillLevelRecipeToCraft(r) end,
    ["Blacksmithing"] = function(r) return addonTable.getBlacksmithingCurrentSkillLevelRecipeToCraft(r) end,
    ["Leatherworking"] = function(r) return addonTable.getLeatherworkingCurrentSkillLevelRecipeToCraft(r) end,
    ["Engineering"] = function(r) return addonTable.getEngineeringCurrentSkillLevelRecipeToCraft(r) end,
    ["Inscription"] = function(r) return addonTable.getInscriptionCurrentSkillLevelRecipeToCraft(r) end,
    ["Alchemy"] = function(r) return addonTable.getAlchemyCurrentSkillLevelRecipeToCraft(r) end,
    ["First Aid"] = function(r) return addonTable.getFirstAidCurrentSkillLevelRecipeToCraft(r) end,
    ["Cooking"] = function(r) return addonTable.getCookingCurrentSkillLevelRecipeToCraft(r) end,

    ["Encantamiento"] = function(r) return addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(r) end,
    ["Sastrería"] = function(r) return addonTable.getTailoringCurrentSkillLevelRecipeToCraft(r) end,
    ["Joyería"] = function(r) return addonTable.getJewelcraftingCurrentSkillLevelRecipeToCraft(r) end,
    ["Herrería"] = function(r) return addonTable.getBlacksmithingCurrentSkillLevelRecipeToCraft(r) end,
    ["Peletería"] = function(r) return addonTable.getLeatherworkingCurrentSkillLevelRecipeToCraft(r) end,
    ["Ingeniería"] = function(r) return addonTable.getEngineeringCurrentSkillLevelRecipeToCraft(r) end,
    ["Inscripción"] = function(r) return addonTable.getInscriptionCurrentSkillLevelRecipeToCraft(r) end,
    ["Alquimia"] = function(r) return addonTable.getAlchemyCurrentSkillLevelRecipeToCraft(r) end,
    ["Primeros auxilios"] = function(r) return addonTable.getFirstAidCurrentSkillLevelRecipeToCraft(r) end,
    ["Cocina"] = function(r) return addonTable.getCookingCurrentSkillLevelRecipeToCraft(r) end,

    ["Наложение чар"] = function(r) return addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(r) end,
    ["Портняжное дело"] = function(r) return addonTable.getTailoringCurrentSkillLevelRecipeToCraft(r) end,
    ["Ювелирное дело"] = function(r) return addonTable.getJewelcraftingCurrentSkillLevelRecipeToCraft(r) end,
    ["Кузнечное дело"] = function(r) return addonTable.getBlacksmithingCurrentSkillLevelRecipeToCraft(r) end,
    ["Кожевничество"] = function(r) return addonTable.getLeatherworkingCurrentSkillLevelRecipeToCraft(r) end,
    ["Инженерное дело"] = function(r) return addonTable.getEngineeringCurrentSkillLevelRecipeToCraft(r) end,
    ["Начертание"] = function(r) return addonTable.getInscriptionCurrentSkillLevelRecipeToCraft(r) end,
    ["Алхимия"] = function(r) return addonTable.getAlchemyCurrentSkillLevelRecipeToCraft(r) end,
    ["Первая помощь"] = function(r) return addonTable.getFirstAidCurrentSkillLevelRecipeToCraft(r) end,
    ["Кулинария"] = function(r) return addonTable.getCookingCurrentSkillLevelRecipeToCraft(r) end,
}

local function hideCraftControls()
    MainFrameCoreCraft:Hide()
    MainFrameCoreNextRecipe:Hide()
    MainFrameCorePreviousRecipe:Hide()
    updateEnchantRepeatControls(false)
end

local function getEffectiveTarget()
    if not targetSkill then
        return nil
    end

    local currentCap = professionContext and professionContext.currentCap or 0
    if currentCap > 0 and targetSkill > currentCap then
        return currentCap
    end

    return targetSkill
end

local function updateProfessionHeader()
    if professionContext then
        if professionContext.hasModifier then
            txtProfessionProgress:SetText(string.format(
                addonTable.L["profession_progress_bonus"],
                professionContext.professionName,
                professionContext.effectiveSkill,
                professionContext.effectiveCap,
                professionContext.activeSkillModifier
            ))
        else
            txtProfessionProgress:SetText(string.format(
                addonTable.L["profession_progress"],
                professionContext.professionName,
                professionContext.effectiveSkill,
                professionContext.effectiveCap
            ))
        end
    else
        txtProfessionProgress:SetText("")
    end
end

local function getRecommendationMode()
    local db = addonTable.getSettings()
    return db.recommendationMode == "static" and "static" or "dynamic"
end

local DIFFICULTY_PRESENTATION = {
    optimal = { key = "difficulty_orange", color = "ffff7f00" },
    medium = { key = "difficulty_yellow", color = "ffffff00" },
    easy = { key = "difficulty_green", color = "ff40c040" },
    trivial = { key = "difficulty_gray", color = "ff909090" },
}

local function updateRecommendationMeta(data, skillStart, skillEnd)
    local difficulty = data and DIFFICULTY_PRESENTATION[data.skillType] or nil
    if not difficulty then
        txtTarget:SetText(string.format(addonTable.L["target_line"], skillStart, skillEnd))
        return
    end

    txtTarget:SetText(string.format(
        addonTable.L["recommendation_meta"],
        difficulty.color,
        addonTable.L[difficulty.key],
        skillStart,
        skillEnd
    ))
end

local function humanizeDynamicReason(reason)
    local L = addonTable.L
    local reasons = {
        no_price_provider = L["dynamic_reason_no_prices"],
        no_eligible_recipes = L["dynamic_reason_no_recipes"],
        no_complete_route = L["dynamic_reason_no_route"],
        state_limit_exceeded = L["dynamic_reason_no_route"],
        incomplete_price_data = L["dynamic_reason_missing_prices"],
        shopping_plan_incomplete = L["dynamic_reason_missing_prices"],
        price_provider_unavailable = L["dynamic_reason_no_prices"],
    }
    return reasons[reason] or tostring(reason or L["dynamic_reason_unknown"])
end

local function setModeButtonState(button, selected)
    if not button then
        return
    end

    button:Enable()
    if selected then
        button:LockHighlight()
        button:SetAlpha(1)
    else
        button:UnlockHighlight()
        button:SetAlpha(0.72)
    end
end

local function updateModeControls()
    local mode = getRecommendationMode()

    setModeButtonState(MainFrameCoreCheapestMode, mode == "dynamic")
    setModeButtonState(MainFrameCoreStaticMode, mode == "static")

    if MainFrameCoreRoute then
        if mode == "dynamic" and dynamicRecommendation and dynamicRecommendation.available then
            MainFrameCoreRoute:Show()
        else
            MainFrameCoreRoute:Hide()
        end
    end
end

local function currentCostPriceSummary()
    local cost = dynamicRecommendation and dynamicRecommendation.currentCost
    if not cost then
        return nil, nil, nil
    end

    local sources = {}
    local sourceSet = {}
    local oldestAge
    local stale = cost.quality == "stale"

    for i = 1, table.getn(cost.reagentCosts or {}) do
        local reagent = cost.reagentCosts[i]
        if reagent.source and not sourceSet[reagent.source] then
            sourceSet[reagent.source] = true
            table.insert(sources, reagent.source)
        end
        if reagent.ageSeconds and (not oldestAge or reagent.ageSeconds > oldestAge) then
            oldestAge = reagent.ageSeconds
        end
    end

    table.sort(sources)
    local source = table.getn(sources) > 0
        and table.concat(sources, ", ")
        or (dynamicRecommendation.providerName or "price provider")
    return source, stale, oldestAge
end

local function dynamicPriceLine()
    if not dynamicRecommendation then
        return ""
    end

    local source, stale, age = currentCostPriceSummary()

    local quality = stale
        and addonTable.L["dynamic_quality_stale"]
        or addonTable.L["dynamic_quality_current"]

    return string.format(
        addonTable.L["dynamic_price_line"],
        source or "price provider",
        quality,
        addonTable.formatPriceAge(age)
    )
end

local function updateRecommendationSummary()
    if not txtCostSummary then
        return
    end

    local mode = getRecommendationMode()
    if mode == "dynamic" and dynamicRecommendation and dynamicRecommendation.available then
        local cost = dynamicRecommendation.currentCost or {}
        local perCraft = addonTable.formatCopperShort(
            cost.currentPurchaseCostPerCraft or cost.materialMarketValuePerCraft
        )
        local perSkill = addonTable.formatCopperShort(
            cost.expectedCurrentPurchaseCostPerSkillUp or cost.expectedMarketCostPerSkillUp
        )

        txtCostSummary:SetText(string.format(
            addonTable.L["dynamic_per_application"],
            perCraft,
            perSkill
        ))
        return
    end

    if mode == "dynamic" then
        local reason = dynamicRecommendation and dynamicRecommendation.reason or "unknown"
        txtCostSummary:SetText(string.format(
            addonTable.L["dynamic_fallback"],
            humanizeDynamicReason(reason)
        ))
        return
    end

    txtCostSummary:SetText(addonTable.L["static_summary"])
end

local function getAcquisitionGuidance(spellID)
    if type(addonTable.explainRecipeAcquisition) ~= "function" then
        return addonTable.L["acquisition_unknown"]
    end

    local state = { learnedRecipes = {} }
    if type(UnitFactionGroup) == "function" then
        state.faction = UnitFactionGroup("player")
    end

    local info = addonTable.explainRecipeAcquisition(spellID, state, professionContext, {})
    if not info or info.sourceType == "unknown" then
        return addonTable.L["acquisition_unknown"]
    end

    local labels = {
        trainer = addonTable.L["acquisition_trainer"],
        vendor = addonTable.L["acquisition_vendor"],
        limited_vendor = addonTable.L["acquisition_limited_vendor"],
        auction = addonTable.L["acquisition_auction"],
        reputation = addonTable.L["acquisition_reputation"],
        quest = addonTable.L["acquisition_quest"],
        drop = addonTable.L["acquisition_drop"],
        manual = addonTable.L["acquisition_manual"],
    }

    local parts = {
        addonTable.L["acquisition_prefix"] .. (labels[info.sourceType] or tostring(info.sourceType)),
    }

    if info.sourceName and info.sourceName ~= "" then
        table.insert(parts, info.sourceName)
    end

    if info.zone and info.zone ~= "" then
        local location = info.zone
        if type(info.coordinates) == "table" then
            local x = tonumber(info.coordinates.x or info.coordinates[1])
            local y = tonumber(info.coordinates.y or info.coordinates[2])
            if x and y then
                location = location .. string.format(" %.1f, %.1f", x, y)
            end
        end
        table.insert(parts, location)
    end

    if info.purchasePrice then
        table.insert(parts, addonTable.formatCopperShort(info.purchasePrice))
    end

    if info.limitedStock then
        table.insert(parts, addonTable.L["acquisition_limited_stock"])
    end

    if type(info.reputation) == "table" and info.reputation.faction and info.reputation.standing then
        table.insert(parts, tostring(info.reputation.faction) .. " " .. tostring(info.reputation.standing))
    end

    return table.concat(parts, " · ")
end

function setRecommendationMode(mode)
    if not addonTable.setRecommendationMode(mode) then
        return
    end

    if professionContext then
        resetValues()
        GetCraftingToDo()
    else
        updateModeControls()
    end
end

function showDynamicRouteTooltip(owner)
    if not dynamicRecommendation or not dynamicRecommendation.available then
        return
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(addonTable.L["compare_tooltip_title"])

    local candidates = dynamicRecommendation.candidates or {}
    local candidateLimit = math.min(table.getn(candidates), 8)
    for i = 1, candidateLimit do
        local candidate = candidates[i]
        local name = candidate.recipe and candidate.recipe.name or tostring(candidate.recipeID or "?")
        local line = string.format(
            addonTable.L["compare_tooltip_recipe"],
            name,
            tostring(candidate.difficulty or "?"),
            addonTable.formatCopperShort(candidate.costPerCraft),
            addonTable.formatCopperShort(candidate.expectedCostPerSkillUp)
        )
        if i == 1 then
            GameTooltip:AddLine(line, 0.35, 1, 0.35, true)
        else
            GameTooltip:AddLine(line, 0.82, 0.82, 0.82, true)
        end
    end

    if table.getn(candidates) > candidateLimit then
        GameTooltip:AddLine(string.format(
            addonTable.L["compare_tooltip_more"],
            table.getn(candidates) - candidateLimit
        ), 0.65, 0.65, 0.65, true)
    end

    local plan = dynamicRecommendation.plan
    if plan and plan.complete then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(addonTable.L["route_tooltip_title"], 1, 0.82, 0)
        local segments = plan.segments or {}
        local limit = math.min(table.getn(segments), 8)
        for i = 1, limit do
            local segment = segments[i]
            if segment.type == "training" then
                GameTooltip:AddLine(string.format(
                    addonTable.L["route_tooltip_training"],
                    tonumber(segment.oldCap) or 0,
                    tonumber(segment.newCap) or 0,
                    addonTable.formatCopperShort(segment.marketCost)
                ), 0.9, 0.82, 0.45, true)
            else
                local name = segment.recipe and segment.recipe.name or tostring(segment.recipeID or "?")
                GameTooltip:AddLine(string.format(
                    addonTable.L["route_tooltip_craft"],
                    tonumber(segment.skillStart) or 0,
                    tonumber(segment.skillEnd) or 0,
                    name,
                    math.ceil(tonumber(segment.expectedCrafts) or 0),
                    addonTable.formatCopperShort(segment.marketCost)
                ), 0.82, 0.82, 0.82, true)
            end
        end
    else
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(addonTable.L["route_tooltip_incomplete"], 0.75, 0.75, 0.75, true)
    end

    GameTooltip:Show()
end

local function getDisplayedTarget(baseTarget)
    if not baseTarget then
        return nil
    end

    return addonTable.getEffectiveSkillForBase(baseTarget, professionContext)
end

local function updateCraftProgress(currentID, effectiveTarget, craftSeconds)
    local session = addonTable.getCraftSession()
    txtCraftProgress:SetText("")

    if not session or session.spellID ~= currentID then
        return
    end

    if session.reachedTarget then
        txtCraftProgress:SetText(addonTable.L["target_reached"])
        return
    end

    if session.mode == "targeted_enchant" then
        if session.active then
            if addonTable.getCraftSessionTarget() then
                txtCraftProgress:SetText(addonTable.L["enchant_applying"])
            else
                txtCraftProgress:SetText(addonTable.L["enchant_select_target"])
            end
        elseif session.needsContinue then
            if session.repeatMode == "fixed" then
                txtCraftProgress:SetText(string.format(
                    addonTable.L["enchant_repeat_progress_fixed"],
                    session.completed,
                    session.queued
                ))
            else
                txtCraftProgress:SetText(string.format(
                    addonTable.L["enchant_repeat_progress_auto"],
                    session.completed
                ))
            end
        elseif session.finished and session.repeatMode == "fixed" then
            txtCraftProgress:SetText(string.format(
                addonTable.L["enchant_repeat_complete"],
                session.completed,
                session.queued
            ))
        end
        return
    end

    local remainingSkillUps = math.max(0, effectiveTarget - professionContext.baseSkill)
    if session.active then
        local remainingSeconds = addonTable.getCraftSessionRemainingSeconds(craftSeconds)
        if remainingSeconds then
            txtCraftProgress:SetText(string.format(
                addonTable.L["craft_progress"],
                session.completed,
                session.queued,
                formatDuration(remainingSeconds)
            ))
        else
            txtCraftProgress:SetText(string.format(
                addonTable.L["craft_progress_no_eta"],
                session.completed,
                session.queued
            ))
        end
    elseif session.needsContinue and remainingSkillUps > 0 then
        txtCraftProgress:SetText(string.format(addonTable.L["craft_batch_done"], formatSkillUps(remainingSkillUps)))
    end
end

local function showStatus(message)
    updateProfessionHeader()
    txtShouldCraft:SetText(message)
    imgSkillIcon:SetTexture(
        professionContext and (GetSpellTexture(professionContext.professionName) or UNKNOWN_ICON)
        or UNKNOWN_ICON
    )
    txtTarget:SetText("")
    txtRecipeStatus:SetText("")
    txtCraftStats:SetText("")
    txtCraftProgress:SetText("")
    txtCraftEta:SetText("")
    txtRecipePosition:SetText("")
    if txtCostSummary then
        txtCostSummary:SetText("")
    end
    clearMaterialRows()
    hideCraftControls()
    updateModeControls()
    MainFrameCore:SetHeight(MIN_PANEL_HEIGHT)
end

function GetCraftingToDo()
    local L = addonTable.L

    if not professionContext then
        showStatus(L["no_guide_step"])
        return
    end

    local baseSkill = professionContext.baseSkill
    local currentCap = professionContext.currentCap

    if baseSkill >= 450 then
        showStatus(L["profession_cap"])
        return
    end

    if currentCap > 0 and baseSkill >= currentCap and currentCap < 450 then
        showStatus(L["train_profession"])
        return
    end

    local handler = professionHandlers[professionContext.professionName]
    if not handler then
        MainFrameCore:Hide()
        return
    end

    dynamicRecommendation = nil
    local scanned = withUnfilteredTradeSkill(function()
        buildRecipeCache()
        cacheAllRecipeReagents()

        if getRecommendationMode() == "dynamic"
            and type(addonTable.computeDynamicProfessionRecommendation) == "function"
        then
            dynamicRecommendation = addonTable.computeDynamicProfessionRecommendation(
                recipeCache,
                professionContext
            )
        end

        if dynamicRecommendation and dynamicRecommendation.available then
            local segment = dynamicRecommendation.currentSegment
            shouldCraft = { segment.recipeID }
            shouldCraftRecipe = {
                segment.recipe and segment.recipe.name
                    or (recipeCache[segment.recipeID] and recipeCache[segment.recipeID].name)
                    or tostring(segment.recipeID)
            }
            targetSkill = segment.skillEnd
        else
            shouldCraft, shouldCraftRecipe, targetSkill = handler(baseSkill)
        end

        cacheRecommendedRecipeDetails()
    end)

    transientSpellIndexMap = {}

    if not scanned then
        showStatus(L["no_guide_step"])
        return
    end

    if not shouldCraft or table.getn(shouldCraft) == 0 or not targetSkill then
        showStatus(L["no_guide_step"])
        return
    end

    local session = addonTable.getCraftSession()
    if session and session.mode == "targeted_enchant" then
        local recommendedID = shouldCraft[1]
        if session.spellID ~= recommendedID then
            addonTable.clearCraftSession()
        end
    end

    displayRecipe()
end

local function printProfessionDebug()
    local rawName, rawRank, rawCap, rawModifier = GetTradeSkillLine()
    local context = addonTable.readProfessionSkillContext()

    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper debug]|r raw: "
        .. tostring(rawName) .. " " .. tostring(rawRank) .. " / " .. tostring(rawCap)
        .. " modifier=" .. tostring(rawModifier))

    if not context then
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper debug]|r no active profession context; open a profession window first")
        return
    end

    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper debug]|r inferred: trained "
        .. context.baseSkill .. " / " .. context.currentCap
        .. " | bonus +" .. context.activeSkillModifier
        .. " | effective " .. context.effectiveSkill .. " / " .. context.effectiveCap)

    local handler = professionHandlers[context.professionName]
    if not handler then
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper debug]|r no guide for " .. tostring(context.professionName))
        return
    end

    local recipes, recipeNames, baseTarget = handler(context.baseSkill)
    if not recipes or not baseTarget then
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper debug]|r no guide step for trained skill " .. context.baseSkill)
        return
    end

    local displayedTarget = addonTable.getEffectiveSkillForBase(baseTarget, context)
    local firstRecipe = recipes[1]
    local firstName = recipeNames and recipeNames[1] or nil
    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper debug]|r route: trained "
        .. context.baseSkill .. " -> " .. baseTarget
        .. " | displayed " .. context.effectiveSkill .. " -> " .. displayedTarget
        .. " | recipe " .. tostring(firstRecipe) .. " " .. tostring(firstName or ""))
end

local function formatCopper(value)
    value = tonumber(value)
    if not value then
        return "n/a"
    end

    value = math.floor(value)
    local gold = math.floor(value / 10000)
    local silver = math.floor((value % 10000) / 100)
    local copper = value % 100
    return string.format("%dg %02ds %02dc", gold, silver, copper)
end

local function printPriceDebug(item)
    if not item or item == "" then
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper price]|r usage: /pcapper price <itemID or item link>")
        return
    end

    local result = addonTable.lookupItemPrice(item)
    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper price]|r provider="
        .. tostring(addonTable.getActivePriceProviderName())
        .. " source=" .. tostring(result.source)
        .. " version=" .. tostring(result.providerVersion or "unknown")
        .. " backend=" .. tostring(result.providerBackend or "unknown"))

    if not result.available then
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper price]|r unavailable: "
            .. tostring(result.unavailableReason or "unknown"))
        return
    end

    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper price]|r item="
        .. tostring(result.itemID or item)
        .. " min=" .. formatCopper(result.minBuyout)
        .. " market=" .. formatCopper(result.marketValue)
        .. " historical=" .. formatCopper(result.historicalValue)
        .. " recent=" .. formatCopper(result.recentValue))

    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper price]|r freshness="
        .. tostring(result.freshness)
        .. " age=" .. tostring(result.ageSeconds or "unknown") .. "s"
        .. " auctions=" .. tostring(result.numAuctions or "unknown")
        .. " suspicious=" .. tostring(result.isSuspicious)
        .. (result.suspiciousReason and (" (" .. result.suspiciousReason .. ")") or ""))
end

local function printCommandHelp()
    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper]|r /pcapper show, hide, attach, detach, lock, unlock, reset, debug, price <itemID>, help")
end

function TogglePcapperFrame(command)
    local rawCommand = command or ""
    local action, argument = string.match(rawCommand, "^%s*(%S*)%s*(.-)%s*$")
    action = string.lower(action or "")
    local db = addonTable.getSettings()

    if action == "" then
        if db.enabled then
            addonTable.setEnabled(false)
            MainFrameCore:Hide()
        else
            addonTable.setEnabled(true)
            addonTable.applyFramePosition(MainFrameCore)
            MainFrameCore:Show()
        end
    elseif action == "show" then
        addonTable.setEnabled(true)
        addonTable.applyFramePosition(MainFrameCore)
        MainFrameCore:Show()
    elseif action == "hide" then
        addonTable.setEnabled(false)
        MainFrameCore:Hide()
    elseif action == "attach" then
        addonTable.setFrameAttached(MainFrameCore, true)
    elseif action == "detach" then
        addonTable.detachFrame(MainFrameCore)
        addonTable.saveFramePosition(MainFrameCore)
    elseif action == "lock" then
        addonTable.setFrameLocked(true)
    elseif action == "unlock" then
        addonTable.setFrameLocked(false)
    elseif action == "reset" then
        addonTable.resetSettings(MainFrameCore)
        addonTable.setEnabled(true)
        MainFrameCore:Show()
    elseif action == "debug" then
        printProfessionDebug()
    elseif action == "price" then
        printPriceDebug(argument)
    elseif action == "help" then
        printCommandHelp()
    else
        printCommandHelp()
    end
end

function ProfessionCapper_OnDragStart()
    local db = addonTable.getSettings()
    if db.locked then
        return
    end

    addonTable.detachFrame(MainFrameCore)
    MainFrameCore:StartMoving()
end

function ProfessionCapper_OnDragStop()
    MainFrameCore:StopMovingOrSizing()
    addonTable.saveFramePosition(MainFrameCore)
end

local function refreshProfessionState(forceRefresh)
    if tradeSkillStateMutation or GetTime() < suppressTradeSkillUpdatesUntil then
        return
    end

    if IsTradeSkillLinked() then
        professionContext = nil
        addonTable.clearProfessionSkillContext()
        MainFrameCore:Hide()
        return
    end

    local nextContext, changed = addonTable.refreshProfessionSkillContext()
    if not nextContext then
        professionContext = nil
        MainFrameCore:Hide()
        return
    end

    if not forceRefresh and not changed then
        return
    end

    professionContext = nextContext
    addonTable.handleCraftRankUpdate(professionContext.baseSkill)

    if not professionHandlers[professionContext.professionName] then
        MainFrameCore:Hide()
        return
    end

    resetValues()
    GetCraftingToDo()
    addonTable.applyFramePosition(MainFrameCore)

    if addonTable.getSettings().enabled then
        MainFrameCore:Show()
    else
        MainFrameCore:Hide()
    end
end

function fnOnLoad()
    addonTable.applyLocale()
    local L = addonTable.L

    txtHeaderLabel:SetText(L["header_label"])
    txtMaterialsLabel:SetText(L["materials_label"])
    if MainFrameCoreCheapestMode then
        MainFrameCoreCheapestMode:SetText(L["mode_cheapest"])
    end
    if MainFrameCoreStaticMode then
        MainFrameCoreStaticMode:SetText(L["mode_static"])
    end
    if MainFrameCoreRoute then
        MainFrameCoreRoute:SetText(L["route_button"])
    end
    installEnchantTargetHooks()
    updateModeControls()
    print("|cff" .. addonTable.chat_frame_default_color .. L["loaded_for"] .. "|r |cff" .. addonTable.chat_frame_player_name_color .. "[" .. UnitLevel("player") .. "]" .. UnitName("player") .. "|r")

    addonTable.getSettings()
    addonTable.applyFramePosition(MainFrameCore)

    this:RegisterEvent("TRADE_SKILL_UPDATE")
    this:RegisterEvent("TRADE_SKILL_CLOSE")
    this:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    this:RegisterEvent("UNIT_AURA")
    this:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    this:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    this:RegisterEvent("UNIT_SPELLCAST_FAILED")
    this:RegisterForDrag("LeftButton")

    SlashCmdList["TOGGLE_PCAPPER_FRAME"] = TogglePcapperFrame
    SLASH_TOGGLE_PCAPPER_FRAME1 = "/pcapper"
end

function fnOnEvent()
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if addonTable.handleCraftSucceeded(arg1, arg2) and MainFrameCore:IsShown() and targetSkill then
            displayRecipe()
        end
        return
    end

    if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        if addonTable.handleCraftInterrupted(arg1, arg2) and MainFrameCore:IsShown() and targetSkill then
            displayRecipe()
        end
        return
    end

    if event == "TRADE_SKILL_CLOSE" then
        addonTable.clearCraftSession()
        addonTable.clearProfessionSkillContext()
        professionContext = nil
        MainFrameCore:Hide()
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        refreshProfessionState(false)
        return
    end

    if event == "UNIT_AURA" then
        if arg1 == "player" then
            refreshProfessionState(false)
        end
        return
    end

    if event == "TRADE_SKILL_UPDATE" then
        refreshProfessionState(true)
    end
end

function displayRecipe()
    local L = addonTable.L
    local usingDynamic = getRecommendationMode() == "dynamic"
        and dynamicRecommendation
        and dynamicRecommendation.available
    local currentKey = recipeKey(shouldCraft)

    if currentKey ~= previousRecipeKey then
        craftRecipeOptionsIndex = 1
    end

    if craftRecipeOptionsIndex < 1 then
        craftRecipeOptionsIndex = 1
    elseif craftRecipeOptionsIndex > table.getn(shouldCraft) then
        craftRecipeOptionsIndex = table.getn(shouldCraft)
    end

    if usingDynamic then
        MainFrameCorePreviousRecipe:Hide()
        MainFrameCoreNextRecipe:Hide()
    else
        if craftRecipeOptionsIndex <= 1 then
            MainFrameCorePreviousRecipe:Disable()
        else
            MainFrameCorePreviousRecipe:Enable()
        end

        if craftRecipeOptionsIndex >= table.getn(shouldCraft) then
            MainFrameCoreNextRecipe:Disable()
        else
            MainFrameCoreNextRecipe:Enable()
        end

        MainFrameCoreNextRecipe:Show()
        MainFrameCorePreviousRecipe:Show()
    end

    local currentID = shouldCraft[craftRecipeOptionsIndex]
    local data = recipeCache[currentID]
    local targetedEnchant = data and isTargetedEnchantRecipe(currentID) or false
    local effectiveTarget = getEffectiveTarget()
    local displayedTarget = getDisplayedTarget(effectiveTarget)
    local skillUpsNeeded = math.max(0, effectiveTarget - professionContext.baseSkill)
    local plannedCrafts = math.max(1, skillUpsNeeded)
    if usingDynamic and dynamicRecommendation.currentSegment then
        plannedCrafts = math.max(
            1,
            math.ceil(tonumber(dynamicRecommendation.currentSegment.expectedCrafts) or plannedCrafts)
        )
    end

    local materialCrafts = plannedCrafts
    if targetedEnchant then
        local repeatMode, repeatCount = getEnchantRepeatSettings()
        if repeatMode == "fixed" then
            materialCrafts = repeatCount
        end
    end

    updateProfessionHeader()
    txtTarget:SetText(string.format(L["target_line"], professionContext.effectiveSkill, displayedTarget))
    if usingDynamic then
        txtRecipePosition:SetText("")
    else
        txtRecipePosition:SetText(string.format(L["recipe_position"], craftRecipeOptionsIndex, table.getn(shouldCraft)))
    end
    txtRecipeStatus:SetText("")
    updateModeControls()
    updateRecommendationSummary()
    updateEnchantRepeatControls(targetedEnchant)

    if data then
        local exactCraftCount = data.skillType == "optimal"
        local statsKey = exactCraftCount and "stats_exact" or "stats_minimum"
        local etaKey = exactCraftCount and "eta_exact" or "eta_minimum"
        local icon = data.icon

        if icon == ENGRAVING_ICON then
            icon = INSCRIPTION_FALLBACK_ICON
        end

        txtShouldCraft:SetText(data.name)
        imgSkillIcon:SetTexture(icon or UNKNOWN_ICON)
        updateRecommendationMeta(data, professionContext.effectiveSkill, displayedTarget)

        if usingDynamic then
            txtCraftStats:SetText("")
            txtRecipeStatus:SetText(L["dynamic_preferred"])
        else
            txtCraftStats:SetText(string.format(L[statsKey], formatSkillUps(skillUpsNeeded), data.numAvailable, plannedCrafts))
            txtRecipeStatus:SetText(L["static_recommendation"])
        end

        if data.numAvailable <= 0 and skillUpsNeeded > 0 then
            local reason = usingDynamic and L["dynamic_preferred"] or L["static_recommendation"]
            txtRecipeStatus:SetText(reason .. " · " .. L["missing_materials"])
        end

        local materialCount, immediatePurchaseCost, purchaseCostComplete = renderMaterials(data.reagents, materialCrafts)
        if usingDynamic then
            if purchaseCostComplete and immediatePurchaseCost > 0 then
                txtCraftStats:SetText(string.format(
                    L["dynamic_availability_purchase"],
                    data.numAvailable,
                    addonTable.formatCopperShort(immediatePurchaseCost)
                ))
            else
                txtCraftStats:SetText(string.format(L["dynamic_availability"], data.numAvailable))
            end
        end

        local craftSeconds = getCraftTimeSeconds(currentID)
        if usingDynamic then
            txtCraftEta:SetText(dynamicPriceLine())
        elseif craftSeconds then
            txtCraftEta:SetText(string.format(L[etaKey], formatDuration(craftSeconds * plannedCrafts)))
        else
            txtCraftEta:SetText(L["eta_unavailable"])
        end

        updateCraftProgress(currentID, effectiveTarget, craftSeconds)

        local session = addonTable.getCraftSession()
        local batchCount = math.min(data.numAvailable, plannedCrafts)
        if session and session.spellID == currentID and session.active then
            MainFrameCoreCraft:Disable()
            MainFrameCoreCraft:SetText(targetedEnchant and L["enchanting_button"] or L["crafting_button"])
        elseif batchCount > 0 and skillUpsNeeded > 0 then
            MainFrameCoreCraft:Enable()
            if targetedEnchant then
                local repeatMode, repeatCount = getEnchantRepeatSettings()
                if session
                    and session.spellID == currentID
                    and session.mode == "targeted_enchant"
                    and session.needsContinue
                then
                    if session.repeatMode == "fixed" then
                        MainFrameCoreCraft:SetText(string.format(
                            L["enchant_again_fixed"],
                            session.completed + 1,
                            session.queued
                        ))
                    else
                        MainFrameCoreCraft:SetText(L["enchant_again"])
                    end
                elseif repeatMode == "fixed" then
                    MainFrameCoreCraft:SetText(string.format(
                        L["enchant_fixed"],
                        math.min(data.numAvailable, repeatCount)
                    ))
                else
                    MainFrameCoreCraft:SetText(L["enchant_until_change"])
                end
            elseif session and session.spellID == currentID and session.needsContinue then
                MainFrameCoreCraft:SetText(string.format(L["continue_to"], displayedTarget))
            elseif usingDynamic and plannedCrafts > skillUpsNeeded then
                MainFrameCoreCraft:SetText(string.format(L["craft_toward"], displayedTarget))
            else
                MainFrameCoreCraft:SetText(string.format(L["craft_to"], displayedTarget))
            end
        else
            MainFrameCoreCraft:Disable()
            MainFrameCoreCraft:SetText(L["craft_button_unavail"])
        end
    else
        imgSkillIcon:SetTexture(GetSpellTexture(currentID) or UNKNOWN_ICON)
        txtShouldCraft:SetText(shouldCraftRecipe[craftRecipeOptionsIndex] or tostring(currentID))
        txtRecipeStatus:SetText(getAcquisitionGuidance(currentID) or L["recipe_not_learned"])
        txtCraftStats:SetText(string.format(L["stats_unlearned"], formatSkillUps(skillUpsNeeded)))
        txtCraftProgress:SetText("")
        txtCraftEta:SetText("")
        clearMaterialRows()
        updateEnchantRepeatControls(false)
        MainFrameCoreCraft:Disable()
        MainFrameCoreCraft:SetText(L["craft_button_unavail"])
    end

    MainFrameCoreCraft:Show()

    local visibleMaterialCount = 0
    if data then
        visibleMaterialCount = table.getn(data.reagents or {})
    end
    updatePanelHeight(visibleMaterialCount, targetedEnchant)

    previousRecipeKey = currentKey
end

function displayNextRecipe()
    craftRecipeOptionsIndex = craftRecipeOptionsIndex + 1
    displayRecipe()
end

function displayPreviousRecipe()
    craftRecipeOptionsIndex = craftRecipeOptionsIndex - 1
    displayRecipe()
end

function craftRecipe()
    local currentID = shouldCraft[craftRecipeOptionsIndex]
    if not currentID or not targetSkill then
        return
    end

    local existingSession = addonTable.getCraftSession()
    if existingSession and existingSession.active then
        return
    end

    local effectiveTarget = getEffectiveTarget()
    local skillUpsNeeded = math.max(0, effectiveTarget - professionContext.baseSkill)
    if skillUpsNeeded <= 0 then
        return
    end

    local targetedEnchant = isTargetedEnchantRecipe(currentID)
    local crafted = false
    local craftedName
    local craftedCount = 0
    local repeatMode
    local craftSeconds = getCraftTimeSeconds(currentID)

    withUnfilteredTradeSkill(function()
        local recipeIndex = findVisibleRecipeIndex(currentID)
        if not recipeIndex then
            return
        end

        local skillName, _, numAvailable = GetTradeSkillInfo(recipeIndex)
        numAvailable = numAvailable or 0
        if numAvailable <= 0 then
            return
        end

        if targetedEnchant then
            local configuredCount
            repeatMode, configuredCount = getEnchantRepeatSettings()
            local plannedApplications = repeatMode == "fixed"
                and math.min(numAvailable, configuredCount)
                or numAvailable

            if plannedApplications <= 0 then
                return
            end

            local canResume = existingSession
                and existingSession.spellID == currentID
                and existingSession.mode == "targeted_enchant"
                and existingSession.needsContinue
                and existingSession.repeatMode == repeatMode
                and existingSession.completed < existingSession.queued
                and (repeatMode ~= "fixed" or existingSession.queued == plannedApplications)

            if canResume then
                addonTable.resumeCraftSession(currentID)
            else
                addonTable.startCraftSession(
                    currentID,
                    skillName,
                    effectiveTarget,
                    plannedApplications,
                    craftSeconds,
                    professionContext.baseSkill,
                    {
                        mode = "targeted_enchant",
                        repeatMode = repeatMode,
                    }
                )
            end

            DoTradeSkill(recipeIndex, 1)
            reuseRememberedEnchantTarget()
            crafted = true
            craftedName = skillName
            craftedCount = 1
            return
        end

        local batchCount = math.min(numAvailable, skillUpsNeeded)
        if batchCount <= 0 then
            return
        end

        addonTable.startCraftSession(
            currentID,
            skillName,
            effectiveTarget,
            batchCount,
            craftSeconds,
            professionContext.baseSkill
        )
        DoTradeSkill(recipeIndex, batchCount)
        crafted = true
        craftedName = skillName
        craftedCount = batchCount
    end)

    if crafted then
        local L = addonTable.L
        if targetedEnchant then
            local session = addonTable.getCraftSession()
            if repeatMode == "fixed" and session then
                print("|cff" .. addonTable.chat_frame_default_color
                    .. string.format(L["enchant_started_fixed"], session.completed + 1, session.queued)
                    .. "|r |cff" .. addonTable.chat_frame_player_name_color
                    .. craftedName .. "|r")
            else
                print("|cff" .. addonTable.chat_frame_default_color
                    .. L["enchant_started_auto"]
                    .. "|r |cff" .. addonTable.chat_frame_player_name_color
                    .. craftedName .. "|r")
            end
        else
            print("|cff" .. addonTable.chat_frame_default_color .. L["crafting"] .. "|r |cff" .. addonTable.chat_frame_player_name_color .. craftedCount .. "x |r|cff" .. addonTable.chat_frame_default_color .. craftedName .. "|r")
        end
        displayRecipe()
    end
end

function resetValues()
    shouldCraft = {}
    shouldCraftRecipe = {}
    targetSkill = nil
    craftRecipeOptionsIndex = 1
    previousRecipeKey = ""
    recipeCache = {}
    transientSpellIndexMap = {}
    dynamicRecommendation = nil

    txtProfessionProgress:SetText("")
    txtShouldCraft:SetText("")
    imgSkillIcon:SetTexture(UNKNOWN_ICON)
    txtTarget:SetText("")
    txtRecipeStatus:SetText("")
    txtCraftStats:SetText("")
    txtCraftProgress:SetText("")
    txtCraftEta:SetText("")
    txtRecipePosition:SetText("")
    if txtCostSummary then
        txtCostSummary:SetText("")
    end
    clearMaterialRows()
    updateEnchantRepeatControls(false)
    updateModeControls()

    local L = addonTable.L
    MainFrameCoreCraft:SetText(L and L["craft_button_unavail"] or "Craft")
end
