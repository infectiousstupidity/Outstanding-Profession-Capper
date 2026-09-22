-- Profession Capper v3
local addonName, addonTable = ...

local professionContext
local shouldCraft = {}
local shouldCraftRecipe = {}
local targetSkill
local craftRecipeOptionsIndex = 1
local previousRecipeKey = ""
local recipeCache = {}
local recipeReagentCache = {}
local transientSpellIndexMap = {}
local materialRows = {}
local compareRows = {}
local routeRows = {}
local compareVisibleCount = 5
local compareView = "comparison"
local routePageStart = 1
local routePreviousButton
local routeNextButton
local enchantRepeatNotice
local dynamicRecommendation
local dynamicRecommendationJob
local dynamicRecommendationDriver
local dynamicOptimizerDisabled = false

local MATERIAL_ROW_HEIGHT = 54
local MATERIAL_CONVERSION_ROW_HEIGHT = 88
local MATERIAL_ROW_GAP = 6
local MATERIALS_TOP = 360
local FOOTER_SPACE = 72
local REPEAT_FOOTER_SPACE = 144
local MIN_PANEL_HEIGHT = 468
local MATERIAL_ROW_WIDTH = 524
local MATERIAL_NAME_WIDTH = 180

local COMPARE_DEFAULT_VISIBLE = 5
local COMPARE_EXPAND_STEP = 5
local COMPARE_MAX_VISIBLE = 10
local COMPARE_ROW_HEIGHT = 36
local ROUTE_ROW_HEIGHT = 34
local ROUTE_MAX_VISIBLE = 10
local COMPARE_CONTENT_TOP = 132
local COMPARE_FOOTER_SPACE = 58
local COMPARE_MIN_HEIGHT = 356

local DETAILS_PANEL_HEIGHT = 114
local DETAILS_PANEL_GAP = 10

local tradeSkillStateMutation = false
local suppressTradeSkillUpdatesUntil = 0
local professionRefreshCoordinator = addonTable.createRefreshCoordinator()
local professionRefreshDriver
local recommendationTooltipTarget
local acquisitionWhereSummary
local addAcquisitionLocationsToTooltip
local PROFESSION_REFRESH_DEBOUNCE = 0.20

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

local function withUnfilteredTradeSkillInternal(callback)
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

local function withUnfilteredTradeSkill(callback)
    if type(addonTable.measurePerformance) == "function" then
        return addonTable.measurePerformance(
            "with_unfiltered_trade_skill",
            withUnfilteredTradeSkillInternal,
            callback
        )
    end
    return withUnfilteredTradeSkillInternal(callback)
end

local function buildRecipeCacheInternal()
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

local function buildRecipeCache()
    if type(addonTable.measurePerformance) == "function" then
        return addonTable.measurePerformance("build_recipe_cache", buildRecipeCacheInternal)
    end
    return buildRecipeCacheInternal()
end

local function getOwnedItemCount(itemID, fallback)
    if itemID and type(addonTable.getRuntimeInventoryCount) == "function" then
        return addonTable.getRuntimeInventoryCount(itemID, fallback)
    end

    if itemID and type(GetItemCount) == "function" then
        local ok, count = pcall(GetItemCount, itemID, true)
        if not ok then
            ok, count = pcall(GetItemCount, itemID)
        end
        if ok and tonumber(count) then
            return math.max(0, tonumber(count))
        end
    end

    return math.max(0, tonumber(fallback) or 0)
end

local function copyCachedRecipeReagents(cached)
    local result = {}
    for i = 1, table.getn(cached or {}) do
        local reagent = cached[i]
        result[i] = {
            name = reagent.name,
            texture = reagent.texture,
            itemLink = reagent.itemLink,
            itemID = reagent.itemID,
            count = reagent.count,
            owned = getOwnedItemCount(reagent.itemID, reagent.owned),
        }
    end
    return result
end

local function cacheRecipeReagents(spellID)
    local data = recipeCache[spellID]
    local recipeIndex = transientSpellIndexMap[spellID]

    if not data then
        return
    end

    local cached = recipeReagentCache[spellID]
    if cached then
        data.reagents = copyCachedRecipeReagents(cached)
        return
    end

    if not recipeIndex then
        local catalog = type(addonTable.getRecipeCatalogRecord) == "function"
            and addonTable.getRecipeCatalogRecord(spellID)
            or nil
        if not catalog or type(catalog.reagents) ~= "table" then
            return
        end

        data.reagents = {}
        local staticReagents = {}
        for i = 1, table.getn(catalog.reagents) do
            local catalogReagent = catalog.reagents[i]
            local itemID = tonumber(catalogReagent.itemID)
            local reagentName = catalogReagent.name
            local itemLink
            local reagentTexture
            if itemID and type(GetItemInfo) == "function" then
                local itemName, cachedLink, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
                reagentName = reagentName or itemName
                itemLink = cachedLink
                reagentTexture = texture
            end

            reagentName = reagentName or (itemID and ("item " .. tostring(itemID))) or "Unknown"
            itemLink = itemLink or (itemID and ("item:" .. tostring(itemID))) or nil
            local reagent = {
                name = reagentName,
                texture = reagentTexture,
                itemLink = itemLink,
                itemID = itemID,
                count = tonumber(catalogReagent.count) or 0,
                owned = getOwnedItemCount(itemID, 0),
            }
            table.insert(data.reagents, reagent)
            table.insert(staticReagents, {
                name = reagent.name,
                texture = reagent.texture,
                itemLink = reagent.itemLink,
                itemID = reagent.itemID,
                count = reagent.count,
                owned = 0,
            })
        end

        recipeReagentCache[spellID] = staticReagents
        return
    end

    data.reagents = {}
    local staticReagents = {}
    local cacheable = true
    local numReagents = GetTradeSkillNumReagents(recipeIndex)

    for i = 1, numReagents do
        local reagentName, reagentTexture, reagentCount, reagentOwned = GetTradeSkillReagentInfo(recipeIndex, i)
        if reagentName then
            local itemLink
            if GetTradeSkillReagentItemLink then
                itemLink = GetTradeSkillReagentItemLink(recipeIndex, i)
            end

            local itemID = addonTable.getItemIDFromLink and addonTable.getItemIDFromLink(itemLink) or nil
            local reagent = {
                name = reagentName,
                texture = reagentTexture,
                itemLink = itemLink,
                itemID = itemID,
                count = reagentCount or 0,
                owned = reagentOwned or 0,
            }
            table.insert(data.reagents, reagent)

            if itemID then
                table.insert(staticReagents, {
                    name = reagentName,
                    texture = reagentTexture,
                    itemLink = itemLink,
                    itemID = itemID,
                    count = reagentCount or 0,
                    owned = 0,
                })
            else
                cacheable = false
            end
        end
    end

    if cacheable then
        recipeReagentCache[spellID] = staticReagents
    end
end

local function cacheAllRecipeReagents()
    for spellID in pairs(recipeCache) do
        cacheRecipeReagents(spellID)
    end
end

local SKILL_TYPE_BY_COLOR = {
    orange = "optimal",
    yellow = "medium",
    green = "easy",
    gray = "trivial",
}

local function refreshCachedRecipeDifficulty()
    if not professionContext or type(addonTable.evaluateRecipeDifficulty) ~= "function" then
        return
    end

    for spellID, data in pairs(recipeCache) do
        local evaluated = addonTable.evaluateRecipeDifficulty(
            spellID,
            professionContext.baseSkill,
            professionContext
        )
        local skillType = evaluated
            and evaluated.metadataKnown
            and SKILL_TYPE_BY_COLOR[evaluated.color]
            or nil
        if skillType and type(data) == "table" then
            data.skillType = skillType
        end
    end
end

local function refreshRecipeAvailability(spellID)
    local data = recipeCache[spellID]
    if not data then
        return 0
    end

    cacheRecipeReagents(spellID)
    local reagents = data.reagents
    if type(reagents) ~= "table" or table.getn(reagents) == 0 then
        return tonumber(data.numAvailable) or 0
    end

    local craftable
    for i = 1, table.getn(reagents) do
        local reagent = reagents[i]
        local quantity = math.max(0, tonumber(reagent.count) or 0)
        local owned = getOwnedItemCount(reagent.itemID, reagent.owned)
        reagent.owned = owned

        if quantity > 0 then
            local reusable = type(addonTable.isKnownReusableProfessionTool) == "function"
                and addonTable.isKnownReusableProfessionTool(reagent.itemID)
            if reusable then
                if owned < quantity then
                    craftable = 0
                    break
                end
            else
                local reagentCrafts = math.floor(owned / quantity)
                craftable = craftable == nil
                    and reagentCrafts
                    or math.min(craftable, reagentCrafts)
            end
        end
    end

    if craftable ~= nil then
        data.numAvailable = math.max(0, craftable)
    end
    return tonumber(data.numAvailable) or 0
end

local function cacheRecommendedRecipeDetails()
    if not shouldCraft then
        return
    end

    for i = 1, table.getn(shouldCraft) do
        refreshRecipeAvailability(shouldCraft[i])
    end
end

local function getRecipeOutputItem(recipe, recipeID)
    local live = recipeID and recipeCache[recipeID] or nil
    if live and live.outputItemLink then
        local itemID = addonTable.getItemIDFromLink
            and addonTable.getItemIDFromLink(live.outputItemLink)
            or nil
        return live.outputItemLink, itemID
    end

    if type(recipe) == "table" then
        local outputs = recipe.outputs or {}
        local output = outputs[1]
        if output then
            local itemLink = output.itemLink
            local itemID = tonumber(output.itemID or output.item)
            if itemLink or itemID then
                return itemLink, itemID
            end
        end

        local itemID = tonumber(recipe.outputItemID)
        if itemID then
            return nil, itemID
        end
    end

    if recipeID and type(addonTable.getRecipeCatalogRecord) == "function" then
        local catalog = addonTable.getRecipeCatalogRecord(recipeID)
        if catalog and tonumber(catalog.outputItemID) then
            return nil, tonumber(catalog.outputItemID)
        end
    end

    return nil, nil
end

local function showRecipeOutputTooltip(owner, recipe, recipeID, fallbackName)
    local itemLink, itemID = getRecipeOutputItem(recipe, recipeID)
    if not itemLink and itemID and type(GetItemInfo) == "function" then
        local _, cachedLink = GetItemInfo(itemID)
        itemLink = cachedLink
    end

    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if itemLink then
        GameTooltip:SetHyperlink(itemLink)
        return true
    elseif itemID then
        local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. tostring(itemID))
        if ok then
            return true
        end
    end

    GameTooltip:SetText(fallbackName or tostring(recipeID or ""))
    return false
end

local function recommendationTooltipOnEnter(self)
    if not self.recipeID then
        return
    end
    showRecipeOutputTooltip(self, self.recipe, self.recipeID, self.recipeName)
    if self.acquisition and addAcquisitionLocationsToTooltip then
        addAcquisitionLocationsToTooltip(self.acquisition)
    end
    GameTooltip:Show()
end

local function recommendationTooltipOnLeave()
    GameTooltip:Hide()
end

local function updateRecommendationTooltipTarget(recipeID, recipe, recipeName, acquisition)
    if not recommendationTooltipTarget then
        recommendationTooltipTarget = CreateFrame("Button", nil, MainFrameCore)
        recommendationTooltipTarget:SetWidth(500)
        recommendationTooltipTarget:SetHeight(58)
        recommendationTooltipTarget:SetPoint("TOPLEFT", MainFrameCore, "TOPLEFT", 28, -150)
        recommendationTooltipTarget:SetFrameLevel(MainFrameCore:GetFrameLevel() + 4)
        recommendationTooltipTarget:SetScript("OnEnter", recommendationTooltipOnEnter)
        recommendationTooltipTarget:SetScript("OnLeave", recommendationTooltipOnLeave)
    end

    recommendationTooltipTarget.recipeID = recipeID
    recommendationTooltipTarget.recipe = recipe
    recommendationTooltipTarget.recipeName = recipeName
    recommendationTooltipTarget.acquisition = acquisition
    recommendationTooltipTarget:Show()
end

local function getNumAvailableForSpell(spellID)
    return refreshRecipeAvailability(spellID)
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
        local row = materialRows[i]
        row:Hide()
        row.itemLink = nil
        row.reagentName = nil
        row.searchName = nil
        row.purchaseName = nil
        row.priceInfo = nil
        if row.buy then row.buy:SetText("") end
        if row.altBackground then row.altBackground:Hide() end
        if row.altTitle then row.altTitle:SetText("") end
        if row.altSub then row.altSub:SetText("") end
        if row.altSavings then row.altSavings:SetText("") end
    end

    if txtMaterialsLabel then txtMaterialsLabel:Hide() end
    if txtMaterialsHaveHeader then txtMaterialsHaveHeader:Hide() end
    if txtMaterialsNeedHeader then txtMaterialsNeedHeader:Hide() end
    if txtMaterialsMissingHeader then txtMaterialsMissingHeader:Hide() end
    if txtMaterialsCostHeader then txtMaterialsCostHeader:Hide() end
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
    row:SetHeight(MATERIAL_ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnEnter", materialRowOnEnter)
    row:SetScript("OnLeave", materialRowOnLeave)
    row:SetScript("OnClick", materialRowOnClick)

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints(row)
    row.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    row.background:SetVertexColor(0.035, 0.035, 0.035, 0.58)

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints(row)
    row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.highlight:SetBlendMode("ADD")
    row.highlight:SetAlpha(0.16)
    row.highlight:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(34)
    row.icon:SetHeight(34)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -10)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 50, -9)
    row.name:SetWidth(MATERIAL_NAME_WIDTH)
    row.name:SetHeight(18)
    row.name:SetJustifyH("LEFT")

    row.buy = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.buy:SetPoint("TOPLEFT", row, "TOPLEFT", 50, -30)
    row.buy:SetWidth(MATERIAL_NAME_WIDTH)
    row.buy:SetHeight(16)
    row.buy:SetJustifyH("LEFT")

    row.have = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.have:SetPoint("TOPLEFT", row, "TOPLEFT", 236, -16)
    row.have:SetWidth(48)
    row.have:SetHeight(18)
    row.have:SetJustifyH("CENTER")

    row.need = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.need:SetPoint("TOPLEFT", row, "TOPLEFT", 288, -16)
    row.need:SetWidth(48)
    row.need:SetHeight(18)
    row.need:SetJustifyH("CENTER")

    row.missing = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.missing:SetPoint("TOPLEFT", row, "TOPLEFT", 340, -16)
    row.missing:SetWidth(48)
    row.missing:SetHeight(18)
    row.missing:SetJustifyH("CENTER")

    row.price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.price:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -16)
    row.price:SetWidth(120)
    row.price:SetHeight(18)
    row.price:SetJustifyH("RIGHT")

    row.altBackground = row:CreateTexture(nil, "BACKGROUND")
    row.altBackground:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    row.altBackground:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 48, 6)
    row.altBackground:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 6)
    row.altBackground:SetHeight(34)
    row.altBackground:SetVertexColor(0.04, 0.22, 0.04, 0.72)
    row.altBackground:Hide()

    row.altTitle = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.altTitle:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 58, 24)
    row.altTitle:SetWidth(330)
    row.altTitle:SetHeight(15)
    row.altTitle:SetJustifyH("LEFT")
    row.altTitle:SetTextColor(0.55, 1, 0.4)

    row.altSub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.altSub:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 58, 9)
    row.altSub:SetWidth(330)
    row.altSub:SetHeight(14)
    row.altSub:SetJustifyH("LEFT")

    row.altSavings = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.altSavings:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -16, 16)
    row.altSavings:SetWidth(100)
    row.altSavings:SetHeight(16)
    row.altSavings:SetJustifyH("RIGHT")
    row.altSavings:SetTextColor(0.45, 1, 0.35)

    materialRows[index] = row
    return row
end

local function renderMaterials(reagents, plannedCrafts)
    clearMaterialRows()

    local count = table.getn(reagents or {})
    if count == 0 then
        if MainFrameCoreMaterials then MainFrameCoreMaterials:SetHeight(1) end
        return 0, 0, true
    end

    txtMaterialsLabel:Show()
    txtMaterialsHaveHeader:Show()
    txtMaterialsNeedHeader:Show()
    txtMaterialsMissingHeader:Show()
    txtMaterialsCostHeader:Show()

    local purchaseTotal = 0
    local purchaseComplete = true
    local usedHeight = 0
    local priceOptions
    if dynamicRecommendation and type(dynamicRecommendation.priceLookup) == "function" then
        priceOptions = {
            priceLookup = dynamicRecommendation.priceLookup,
            unitPriceChooser = addonTable.chooseUsableUnitPrice,
        }
    end

    for i = 1, count do
        local reagent = reagents[i]
        local totalRequired = reagent.count * math.max(1, plannedCrafts or 1)
        local owned = reagent.owned or 0
        local needed = math.max(0, totalRequired - owned)
        local priceItem = reagent.itemID or reagent.itemLink or reagent.name
        local priceInfo = addonTable.getMaterialPriceInfo
            and addonTable.getMaterialPriceInfo(priceItem, needed, nil, priceOptions)
            or nil
        local converted = needed > 0
            and priceInfo
            and priceInfo.available
            and priceInfo.converted
            and priceInfo.sourceItemID

        local row = getMaterialRow(i)
        local rowHeight = converted and MATERIAL_CONVERSION_ROW_HEIGHT or MATERIAL_ROW_HEIGHT
        row:SetHeight(rowHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", MainFrameCoreMaterials, "TOPLEFT", 0, -usedHeight)

        row.itemLink = reagent.itemLink
        row.reagentName = reagent.name
        row.searchName = reagent.name
        row.purchaseName = nil
        row.priceInfo = priceInfo
        row.icon:SetTexture(reagent.texture or UNKNOWN_ICON)
        row.name:SetText(reagent.name)
        row.buy:SetText("")
        row.have:SetText(tostring(owned))
        row.need:SetText(tostring(totalRequired))
        row.missing:SetText(tostring(needed))
        row.altBackground:Hide()
        row.altTitle:SetText("")
        row.altSub:SetText("")
        row.altSavings:SetText("")

        if owned > 0 then
            row.have:SetTextColor(0.35, 1, 0.35)
        else
            row.have:SetTextColor(0.72, 0.72, 0.72)
        end
        row.need:SetTextColor(0.92, 0.92, 0.92)
        if needed > 0 then
            row.missing:SetTextColor(1, 0.35, 0.35)
        else
            row.missing:SetTextColor(0.35, 1, 0.35)
        end

        if needed <= 0 then
            row.price:SetText("")
        elseif priceInfo and priceInfo.available then
            local remainingCost = tonumber(priceInfo.estimatedRemainingCost) or 0
            purchaseTotal = purchaseTotal + remainingCost
            row.price:SetText("~" .. addonTable.formatCopperShort(remainingCost))
            if priceInfo.isStale then
                row.price:SetTextColor(1, 0.72, 0.22)
            else
                row.price:SetTextColor(0.95, 0.82, 0.42)
            end

            if converted then
                local sourceName = GetItemInfo(priceInfo.sourceItemID)
                    or ("item " .. tostring(priceInfo.sourceItemID))
                local sourceQuantity = math.max(1, math.ceil(tonumber(priceInfo.sourceQuantity) or 1))
                local savings = tonumber(priceInfo.savings) or 0

                row.purchaseName = sourceName
                row.searchName = sourceName
                row.altBackground:Show()
                row.altTitle:SetText(string.format(
                    addonTable.L["material_best_buy"],
                    sourceQuantity,
                    sourceName
                ))
                if savings > 0 then
                    row.altSub:SetText(string.format(
                        addonTable.L["material_best_buy_savings"],
                        addonTable.formatCopperShort(savings),
                        reagent.name
                    ))
                    row.altSavings:SetText(string.format(
                        addonTable.L["material_save"],
                        addonTable.formatCopperShort(savings)
                    ))
                else
                    row.altSub:SetText(addonTable.L["material_best_buy_equivalent"])
                end
            else
                row.buy:SetText(string.format(addonTable.L["material_buy_quantity"], needed))
            end
        else
            purchaseComplete = false
            row.price:SetText(addonTable.L["material_no_price"])
            row.price:SetTextColor(1, 0.35, 0.35)
            if needed > 0 then
                row.buy:SetText(string.format(addonTable.L["material_buy_quantity"], needed))
            end
        end

        local _, _, quality = GetItemInfo(reagent.itemLink or reagent.name)
        if quality then
            local r, g, b = GetItemQualityColor(quality)
            row.name:SetTextColor(r, g, b)
        else
            row.name:SetTextColor(1, 1, 1)
        end

        row:Show()
        usedHeight = usedHeight + rowHeight
        if i < count then usedHeight = usedHeight + MATERIAL_ROW_GAP end
    end

    MainFrameCoreMaterials:SetHeight(math.max(1, usedHeight))
    return usedHeight, purchaseTotal, purchaseComplete
end

local function updatePanelHeight(materialHeight, showRepeatControls, showDetails)
    local footerSpace = showRepeatControls and REPEAT_FOOTER_SPACE or FOOTER_SPACE
    local detailsHeight = showDetails and (DETAILS_PANEL_HEIGHT + DETAILS_PANEL_GAP) or 0
    local requiredHeight = MATERIALS_TOP
        + math.max(0, materialHeight or 0)
        + detailsHeight
        + footerSpace

    if MainFrameCoreDetails then
        MainFrameCoreDetails:ClearAllPoints()
        MainFrameCoreDetails:SetPoint(
            "BOTTOMLEFT",
            MainFrameCore,
            "BOTTOMLEFT",
            18,
            footerSpace
        )
    end

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
    if not MainFrameCoreRepeatMode
        or not MainFrameCoreRepeatCount
        or not txtRepeatLabel
        or not txtRepeatTargetLabel
    then
        return
    end

    if not visible then
        if texRepeatBackground then texRepeatBackground:Hide() end
        txtRepeatLabel:Hide()
        txtRepeatProgress:Hide()
        txtRepeatTargetLabel:Hide()
        txtRepeatTargetValue:Hide()
        MainFrameCoreRepeatMode:Hide()
        MainFrameCoreRepeatCount:Hide()
        return
    end

    local mode, count = getEnchantRepeatSettings()
    if texRepeatBackground then texRepeatBackground:Show() end
    txtRepeatLabel:SetText(addonTable.L["repeat_label"])
    txtRepeatLabel:Show()
    txtRepeatProgress:Show()
    txtRepeatTargetLabel:SetText(addonTable.L["repeat_target_label"])
    txtRepeatTargetLabel:Show()
    txtRepeatTargetValue:Show()

    MainFrameCoreRepeatMode:SetText(
        mode == "fixed"
            and addonTable.L["repeat_fixed_short"]
            or addonTable.L["repeat_until_change"]
    )
    MainFrameCoreRepeatMode:Show()

    if mode == "fixed" then
        if not MainFrameCoreRepeatCount:HasFocus() then
            MainFrameCoreRepeatCount:SetText(tostring(count))
        end
        MainFrameCoreRepeatCount:Enable()
        MainFrameCoreRepeatCount:SetTextColor(1, 1, 1)
        MainFrameCoreRepeatCount:Show()
    else
        MainFrameCoreRepeatCount:Hide()
    end
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
    enchantRepeatNotice = nil

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

local function getEnchantTargetLink(target)
    if not target then
        return nil
    end

    if target.kind == "bag" and GetContainerItemLink then
        return GetContainerItemLink(target.bag, target.slot)
    elseif target.kind == "inventory" and GetInventoryItemLink then
        return GetInventoryItemLink("player", target.slot)
    end

    return nil
end

local function targetStillMatches(target)
    local itemLink = getEnchantTargetLink(target)
    if not itemLink then
        return false
    end

    if target.itemID and addonTable.getItemIDFromLink then
        return addonTable.getItemIDFromLink(itemLink) == target.itemID
    end

    return true
end

local function getEnchantTargetName(target)
    if not target or not targetStillMatches(target) then
        return nil
    end

    local itemLink = getEnchantTargetLink(target)
    if not itemLink then
        return nil
    end

    local itemName = GetItemInfo and GetItemInfo(itemLink) or nil
    return itemName or itemLink
end

local function updateEnchantRepeatPresentation(currentID)
    local L = addonTable.L
    local session = addonTable.getCraftSession()
    local target
    local targetName

    if session
        and session.spellID == currentID
        and session.mode == "targeted_enchant"
    then
        target = addonTable.getCraftSessionTarget()
        if target and (not target.itemID or not targetStillMatches(target)) then
            addonTable.clearCraftSessionTarget()
            target = nil
            enchantRepeatNotice = "target_moved"
        end
        targetName = getEnchantTargetName(target)
    end

    txtRepeatTargetValue:SetText(targetName or L["repeat_target_select"])
    if targetName then
        txtRepeatTargetValue:SetTextColor(0.55, 1, 0.45)
    else
        txtRepeatTargetValue:SetTextColor(1, 0.72, 0.22)
    end

    if enchantRepeatNotice == "recommendation_changed" then
        txtRepeatProgress:SetText(L["repeat_stopped_recommendation"])
        txtRepeatProgress:SetTextColor(1, 0.72, 0.22)
        return
    elseif enchantRepeatNotice == "target_moved" then
        txtRepeatProgress:SetText(L["repeat_target_moved"])
        txtRepeatProgress:SetTextColor(1, 0.72, 0.22)
        return
    end

    if not session
        or session.spellID ~= currentID
        or session.mode ~= "targeted_enchant"
    then
        txtRepeatProgress:SetText(L["repeat_ready"])
        txtRepeatProgress:SetTextColor(0.72, 0.72, 0.72)
        return
    end

    if session.reachedTarget then
        txtRepeatProgress:SetText(L["target_reached"])
        txtRepeatProgress:SetTextColor(0.45, 1, 0.35)
    elseif session.active then
        if targetName then
            txtRepeatProgress:SetText(L["repeat_applying"])
            txtRepeatProgress:SetTextColor(0.82, 0.82, 0.82)
        else
            txtRepeatProgress:SetText(L["repeat_select_target"])
            txtRepeatProgress:SetTextColor(1, 0.72, 0.22)
        end
    elseif session.repeatMode == "fixed" then
        if session.finished then
            txtRepeatProgress:SetText(string.format(
                L["repeat_fixed_complete"],
                session.completed,
                session.queued
            ))
            txtRepeatProgress:SetTextColor(0.45, 1, 0.35)
        else
            txtRepeatProgress:SetText(string.format(
                L["repeat_fixed_progress"],
                session.completed,
                session.queued
            ))
            txtRepeatProgress:SetTextColor(0.82, 0.82, 0.82)
        end
    elseif session.needsContinue then
        txtRepeatProgress:SetText(string.format(
            L["repeat_until_progress"],
            session.completed
        ))
        txtRepeatProgress:SetTextColor(0.82, 0.82, 0.82)
    else
        txtRepeatProgress:SetText(L["repeat_ready"])
        txtRepeatProgress:SetTextColor(0.72, 0.72, 0.72)
    end
end

local function reuseRememberedEnchantTarget()
    local target = addonTable.getCraftSessionTarget()
    if not target then
        return false
    end
    if not targetStillMatches(target) then
        addonTable.clearCraftSessionTarget()
        enchantRepeatNotice = "target_moved"
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

        if imgProfessionIcon then
            imgProfessionIcon:SetTexture(GetSpellTexture(professionContext.professionName) or UNKNOWN_ICON)
        end
        if MainFrameCoreProfessionBar then
            local cap = math.max(1, tonumber(professionContext.effectiveCap) or 450)
            local skill = math.max(0, math.min(cap, tonumber(professionContext.effectiveSkill) or 0))
            MainFrameCoreProfessionBar:SetMinMaxValues(0, cap)
            MainFrameCoreProfessionBar:SetValue(skill)
        end
    else
        txtProfessionProgress:SetText("")
        if imgProfessionIcon then imgProfessionIcon:SetTexture(UNKNOWN_ICON) end
        if MainFrameCoreProfessionBar then
            MainFrameCoreProfessionBar:SetMinMaxValues(0, 1)
            MainFrameCoreProfessionBar:SetValue(0)
        end
    end
end

local function getRecommendationState()
    local db = addonTable.getSettings()
    if type(addonTable.getRecommendationPresentationState) == "function" then
        return addonTable.getRecommendationPresentationState(db)
    end

    local objective = db.recommendationObjective == "smartest"
        and "smartest"
        or "cheapest"
    local static = db.recommendationMode == "static"
    return {
        mode = static and "static" or objective,
        objective = objective,
        static = static,
        cheapest = not static and objective == "cheapest",
        smartest = not static and objective == "smartest",
        availableOnly = db.recommendationAvailableOnly == true,
        availableEnabled = not static,
    }
end

local function getRecommendationMode()
    return getRecommendationState().mode
end

local function isOptimizedMode(mode)
    return mode == "cheapest" or mode == "smartest"
end

local function isAvailableOnly()
    return getRecommendationState().availableOnly == true
end

local function getDetailMode()
    local db = addonTable.getSettings()
    return db.detailMode == "expanded" and "expanded" or "compact"
end

local DIFFICULTY_PRESENTATION = {
    optimal = { key = "difficulty_orange", color = "ffff7f00" },
    medium = { key = "difficulty_yellow", color = "ffffff00" },
    easy = { key = "difficulty_green", color = "ff40c040" },
    trivial = { key = "difficulty_gray", color = "ff909090" },
}

local function updateRecommendationMeta(data, skillStart, skillEnd)
    txtTarget:SetText(string.format(addonTable.L["target_line"], skillStart, skillEnd))

    local difficulty = data and DIFFICULTY_PRESENTATION[data.skillType] or nil
    if not difficulty then
        if txtDifficulty then txtDifficulty:SetText("") end
        if texDifficultyBackground then texDifficultyBackground:Hide() end
        return
    end

    if txtDifficulty then
        txtDifficulty:SetText(addonTable.L[difficulty.key])
        if data.skillType == "optimal" then
            txtDifficulty:SetTextColor(1, 0.55, 0.05)
        elseif data.skillType == "medium" then
            txtDifficulty:SetTextColor(1, 0.9, 0.1)
        elseif data.skillType == "easy" then
            txtDifficulty:SetTextColor(0.35, 1, 0.35)
        else
            txtDifficulty:SetTextColor(0.65, 0.65, 0.65)
        end
    end

    if texDifficultyBackground then
        if data.skillType == "optimal" then
            texDifficultyBackground:SetVertexColor(0.42, 0.20, 0.02, 0.80)
        elseif data.skillType == "medium" then
            texDifficultyBackground:SetVertexColor(0.34, 0.28, 0.02, 0.80)
        elseif data.skillType == "easy" then
            texDifficultyBackground:SetVertexColor(0.03, 0.24, 0.05, 0.80)
        else
            texDifficultyBackground:SetVertexColor(0.15, 0.15, 0.15, 0.80)
        end
        texDifficultyBackground:Show()
    end
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
        no_available_recipe = L["dynamic_reason_no_available_recipe"],
        materials_not_available_now = L["dynamic_reason_no_available_recipe"],
        optimizer_error = L["dynamic_reason_optimizer_error"],
        calculating = L["dynamic_reason_calculating"],
        runtime_inputs_changed = L["dynamic_reason_inputs_changed"],
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

    local fontString = button.GetFontString and button:GetFontString() or nil
    if fontString then
        if selected then
            fontString:SetTextColor(1, 0.82, 0.12)
        else
            fontString:SetTextColor(0.78, 0.78, 0.78)
        end
    end
end

local function updateModeControls()
    local state = getRecommendationState()
    local mode = state.mode

    setModeButtonState(MainFrameCoreCheapestMode, mode == "cheapest")
    setModeButtonState(MainFrameCoreSmartestMode, mode == "smartest")
    setModeButtonState(MainFrameCoreStaticMode, mode == "static")

    if MainFrameCoreAvailableOnly then
        MainFrameCoreAvailableOnly:SetChecked(state.availableOnly)
        if state.availableEnabled then
            MainFrameCoreAvailableOnly:Enable()
            MainFrameCoreAvailableOnly:SetAlpha(1)
            if txtAvailableOnlyLabel then
                txtAvailableOnlyLabel:SetTextColor(0.78, 0.78, 0.78)
            end
        else
            MainFrameCoreAvailableOnly:Disable()
            MainFrameCoreAvailableOnly:SetAlpha(0.45)
            if txtAvailableOnlyLabel then
                txtAvailableOnlyLabel:SetTextColor(0.45, 0.45, 0.45)
            end
        end
    end

    if MainFrameCoreRoute then
        local staticRouteAvailable = mode == "static"
            and professionContext
            and type(addonTable.buildStaticProfessionRoute) == "function"
            and type(addonTable.getProfessionGuide) == "function"
            and addonTable.getProfessionGuide(professionContext.professionName) ~= nil
        local dynamicRouteAvailable = isOptimizedMode(mode)
            and dynamicRecommendation
            and dynamicRecommendation.available

        if staticRouteAvailable or dynamicRouteAvailable then
            MainFrameCoreRoute:SetText(
                staticRouteAvailable
                    and addonTable.L["route_button_static"]
                    or addonTable.L["route_button"]
            )
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

local function economicItemName(itemID)
    itemID = tonumber(itemID)
    if itemID and type(GetItemInfo) == "function" then
        local name = GetItemInfo(itemID)
        if name and name ~= "" then
            return name
        end
    end
    return itemID and ("Item " .. tostring(itemID)) or addonTable.L["metric_unknown"]
end

local function formatEconomicCopper(value)
    if value == nil then
        return addonTable.L["metric_unknown"]
    end
    return addonTable.formatCopperShort(value)
end

local function formatSkillUpChance(chance)
    chance = tonumber(chance)
    if not chance then
        return addonTable.L["metric_unknown"]
    end

    local percent = math.max(0, math.min(100, chance * 100))
    local rounded = math.floor(percent + 0.5)
    if math.abs(percent - rounded) < 0.05 then
        return tostring(rounded) .. "%"
    end
    return string.format("%.1f%%", percent)
end

local function formatExpectedCrafts(crafts)
    crafts = tonumber(crafts)
    if not crafts then
        return addonTable.L["metric_unknown"]
    end

    crafts = math.max(0, crafts)
    local rounded = math.floor(crafts + 0.5)
    if math.abs(crafts - rounded) < 0.05 then
        return tostring(rounded)
    end
    return string.format("%.1f", crafts)
end

local function smartestEconomics(cost)
    if type(addonTable.getSmartestEconomicsPresentation) ~= "function" then
        return nil
    end
    return addonTable.getSmartestEconomicsPresentation(cost)
end

local function smartestResaleWarning(economics)
    if not economics or economics.method ~= "scroll" then
        return ""
    end

    local warning
    if economics.resaleEvidenceState == "unavailable" then
        warning = addonTable.L["smartest_resale_unavailable"]
    elseif economics.resaleEvidenceState == "rejected" then
        warning = addonTable.L["smartest_resale_rejected"]
    elseif economics.resaleEvidenceState == "weak" then
        warning = addonTable.L["smartest_resale_weak"]
    end

    if warning then
        return warning .. " · " .. addonTable.L["smartest_market_disclaimer"]
    end
    return addonTable.L["smartest_market_disclaimer"]
end

local function addSmartestEconomicsToTooltip(cost)
    local economics = smartestEconomics(cost)
    if not economics then
        return
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(addonTable.L["smartest_tooltip_title"], 1, 0.82, 0.12, true)
    GameTooltip:AddLine(string.format(
        addonTable.L["smartest_tooltip_skill"],
        formatSkillUpChance(economics.skillUpChance),
        formatExpectedCrafts(economics.expectedCrafts)
    ), 0.82, 0.82, 0.82, true)
    GameTooltip:AddLine(string.format(
        addonTable.L["smartest_tooltip_materials"],
        formatEconomicCopper(economics.materialCostPerCraft)
    ), 0.82, 0.82, 0.82, true)

    if economics.method == "scroll" then
        GameTooltip:AddLine(string.format(
            addonTable.L["smartest_tooltip_vellum"],
            economicItemName(economics.vellumItemID),
            formatEconomicCopper(economics.vellumCost)
        ), 0.82, 0.82, 0.82, true)
    end

    GameTooltip:AddLine(string.format(
        addonTable.L["smartest_tooltip_gross"],
        formatEconomicCopper(economics.grossCostPerCraft)
    ), 0.82, 0.82, 0.82, true)

    if economics.method == "scroll" then
        GameTooltip:AddLine(string.format(
            addonTable.L["smartest_tooltip_resale"],
            formatEconomicCopper(economics.estimatedResalePerCraft)
        ), 0.82, 0.82, 0.82, true)
    end

    GameTooltip:AddLine(string.format(
        addonTable.L["smartest_tooltip_effective"],
        formatEconomicCopper(economics.effectiveCostPerSkillUp)
    ), 0.55, 1, 0.45, true)

    if economics.hasPositiveSurplus then
        GameTooltip:AddLine(string.format(
            addonTable.L["smartest_tooltip_surplus"],
            formatEconomicCopper(economics.estimatedSurplusPerCraft)
        ), 0.72, 0.82, 1, true)
    end

    local warning = smartestResaleWarning(economics)
    if warning ~= "" then
        GameTooltip:AddLine(warning, 1, 0.72, 0.22, true)
    end
end

local function updateDetailModeControl()
    if not MainFrameCoreDetailsToggle then
        return
    end

    if not isOptimizedMode(getRecommendationMode()) then
        MainFrameCoreDetailsToggle:Hide()
        return
    end

    MainFrameCoreDetailsToggle:Show()
    if getDetailMode() == "expanded" then
        MainFrameCoreDetailsToggle:SetText(addonTable.L["details_collapse"])
    else
        MainFrameCoreDetailsToggle:SetText(addonTable.L["details_expand"])
    end
end

local function comparableCandidateCount()
    local count = 0
    local candidates = dynamicRecommendation and dynamicRecommendation.candidates or {}

    for i = 1, table.getn(candidates) do
        local candidate = candidates[i]
        if candidate
            and (candidate.difficulty == "orange" or candidate.difficulty == "yellow")
            and candidate.costPerCraft ~= nil
            and candidate.expectedCostPerSkillUp ~= nil
        then
            count = count + 1
        end
    end

    return count
end

local function updateDetailPanel()
    updateDetailModeControl()

    if type(addonTable.updateAcquisitionLocationControls) == "function" then
        addonTable.updateAcquisitionLocationControls(nil)
    end

    if not MainFrameCoreDetails then
        return false
    end

    local mode = getRecommendationMode()
    if not isOptimizedMode(mode) then
        MainFrameCoreDetails:Hide()
        return false
    end

    if getDetailMode() ~= "expanded" then
        MainFrameCoreDetails:Hide()
        return false
    end

    MainFrameCoreDetails:Show()
    txtDetailsLabel:SetText(
        mode == "smartest"
            and addonTable.L["details_smartest_label"]
            or addonTable.L["details_label"]
    )

    if not dynamicRecommendation or not dynamicRecommendation.available then
        local reason = dynamicRecommendation and dynamicRecommendation.reason or "unknown"
        txtDetailsRoute:SetText(string.format(
            addonTable.L["details_unavailable"],
            humanizeDynamicReason(reason)
        ))
        txtDetailsRoute:SetTextColor(1, 0.72, 0.22)
        txtDetailsSource:SetText("")
        txtDetailsCoverage:SetText("")
        txtDetailsCandidates:SetText("")
        txtDetailsWarning:SetText("")
        return true
    end

    if dynamicRecommendation.requiresAcquisition
        and type(addonTable.updateAcquisitionLocationControls) == "function"
    then
        addonTable.updateAcquisitionLocationControls(dynamicRecommendation.acquisition)
    end

    if mode == "smartest" then
        local economics = smartestEconomics(dynamicRecommendation.currentCost)
        if not economics then
            txtDetailsSource:SetText("")
            txtDetailsRoute:SetText(addonTable.L["details_route_incomplete"])
            txtDetailsRoute:SetTextColor(1, 0.72, 0.22)
            txtDetailsCoverage:SetText("")
            txtDetailsCandidates:SetText("")
            txtDetailsWarning:SetText("")
            return true
        end

        local vellumContext = ""
        if economics.method == "scroll" then
            local vellumName = economicItemName(economics.vellumItemID)
            local scrollName = economicItemName(economics.scrollOutputItemID)
            txtDetailsSource:SetText(string.format(
                addonTable.L["smartest_execution_scroll"],
                vellumName,
                scrollName
            ))
            vellumContext = string.format(
                addonTable.L["smartest_vellum_context"],
                vellumName,
                formatEconomicCopper(economics.vellumCost)
            )
        else
            txtDetailsSource:SetText(addonTable.L["smartest_execution_direct"])
        end

        txtDetailsRoute:SetText(string.format(
            addonTable.L["smartest_skill_context"],
            formatSkillUpChance(economics.skillUpChance),
            formatExpectedCrafts(economics.expectedCrafts),
            formatEconomicCopper(economics.materialCostPerCraft),
            vellumContext
        ))
        txtDetailsRoute:SetTextColor(0.92, 0.92, 0.92)

        txtDetailsCoverage:SetText(string.format(
            addonTable.L["smartest_economics_line"],
            formatEconomicCopper(economics.grossCostPerCraft),
            formatEconomicCopper(economics.estimatedResalePerCraft),
            formatEconomicCopper(economics.effectiveCostPerSkillUp)
        ))

        if economics.hasPositiveSurplus then
            txtDetailsCandidates:SetText(string.format(
                addonTable.L["smartest_surplus_line"],
                formatEconomicCopper(economics.estimatedSurplusPerCraft)
            ))
        else
            txtDetailsCandidates:SetText(addonTable.L["smartest_no_surplus_line"])
        end

        txtDetailsWarning:SetText(smartestResaleWarning(economics))
        if economics.resaleEvidenceState == "unavailable"
            or economics.resaleEvidenceState == "rejected"
            or economics.resaleEvidenceState == "weak"
        then
            txtDetailsWarning:SetTextColor(1, 0.72, 0.22)
        else
            txtDetailsWarning:SetTextColor(0.62, 0.62, 0.62)
        end
        return true
    end

    local sourceSummary = dynamicRecommendation.requiresAcquisition
        and acquisitionWhereSummary(dynamicRecommendation.acquisition)
        or nil
    txtDetailsSource:SetText(
        sourceSummary
            and string.format(addonTable.L["details_source"], sourceSummary)
            or ""
    )

    local plan = dynamicRecommendation.plan
    local target = tonumber(dynamicRecommendation.targetSkill)
        or (professionContext and professionContext.currentCap)
        or 450

    if plan and plan.complete then
        txtDetailsRoute:SetText(string.format(
            addonTable.L["details_route_summary"],
            target,
            addonTable.formatCopperShort(
                plan.estimatedCurrentPurchaseCost or plan.estimatedMarketValueCost
            ),
            addonTable.formatCopperShort(plan.estimatedGoldNeededNow),
            math.max(0, math.ceil(tonumber(plan.totalExpectedCrafts) or 0))
        ))
        txtDetailsRoute:SetTextColor(0.92, 0.92, 0.92)

        local staleCount = tonumber(plan.stalePriceCount) or 0
        local missingCount = tonumber(plan.missingPriceCount) or 0
        txtDetailsCoverage:SetText(string.format(
            addonTable.L["details_coverage"],
            addonTable.formatPriceAge(plan.oldestPriceAgeSeconds),
            staleCount,
            missingCount
        ))
    else
        txtDetailsRoute:SetText(addonTable.L["details_route_incomplete"])
        txtDetailsRoute:SetTextColor(1, 0.72, 0.22)
        txtDetailsCoverage:SetText("")
    end

    txtDetailsCandidates:SetText(string.format(
        addonTable.L["details_candidates"],
        comparableCandidateCount()
    ))
    txtDetailsWarning:SetText("")

    return true
end

function toggleDetailMode()
    local nextMode = getDetailMode() == "expanded" and "compact" or "expanded"
    if not addonTable.setDetailMode(nextMode) then
        return
    end

    if targetSkill and MainFrameCore:IsShown() then
        displayRecipe()
    else
        updateDetailPanel()
    end
end

local function resetRecommendationMetrics()
    txtMetricApplicationValue:SetText(addonTable.L["metric_unknown"])
    txtMetricApplicationValue:SetTextColor(0.92, 0.92, 0.92)
    txtMetricSkillValue:SetText(addonTable.L["metric_unknown"])
    txtMetricSkillValue:SetTextColor(0.92, 0.92, 0.92)
    txtMetricCanMakeValue:SetText(addonTable.L["metric_unknown"])
    txtMetricCanMakeValue:SetTextColor(0.92, 0.92, 0.92)
    txtMetricBuyValue:SetText(addonTable.L["metric_unknown"])
    txtMetricBuyValue:SetTextColor(0.92, 0.92, 0.92)
    txtPriceMeta:SetText("")
end

local function updateRecommendationSummary()
    resetRecommendationMetrics()

    local mode = getRecommendationMode()
    if mode == "smartest" then
        txtMetricApplicationLabel:SetText(addonTable.L["metric_gross_craft"])
        txtMetricSkillLabel:SetText(addonTable.L["metric_effective_skill"])
    else
        txtMetricApplicationLabel:SetText(addonTable.L["metric_application"])
        txtMetricSkillLabel:SetText(addonTable.L["metric_skill_up"])
    end

    if isOptimizedMode(mode) and dynamicRecommendation and dynamicRecommendation.available then
        local cost = dynamicRecommendation.currentCost or {}
        if mode == "smartest" then
            local economics = smartestEconomics(cost)
            if economics then
                txtMetricApplicationValue:SetText("~" .. formatEconomicCopper(
                    economics.grossCostPerCraft
                ))
                txtMetricSkillValue:SetText("~" .. formatEconomicCopper(
                    economics.effectiveCostPerSkillUp
                ))
                if economics.method == "scroll" then
                    txtPriceMeta:SetText(string.format(
                        addonTable.L["smartest_execution_scroll"],
                        economicItemName(economics.vellumItemID),
                        economicItemName(economics.scrollOutputItemID)
                    ))
                else
                    txtPriceMeta:SetText(addonTable.L["smartest_execution_direct"])
                end
                return
            end
        end

        local perCraft = addonTable.formatCopperShort(
            cost.currentPurchaseCostPerCraft or cost.materialMarketValuePerCraft
        )
        local perSkill = addonTable.formatCopperShort(
            cost.expectedCurrentPurchaseCostPerSkillUp or cost.expectedMarketCostPerSkillUp
        )

        txtMetricApplicationValue:SetText("~" .. perCraft)
        txtMetricSkillValue:SetText("~" .. perSkill)
        txtPriceMeta:SetText(dynamicPriceLine())
        return
    end

    if isOptimizedMode(mode) then
        if dynamicRecommendation and dynamicRecommendation.calculating then
            txtPriceMeta:SetText(addonTable.L["dynamic_calculating"])
            return
        end

        local reason = dynamicRecommendation and dynamicRecommendation.reason or "unknown"
        local fallbackKey
        if isAvailableOnly() then
            fallbackKey = "available_filter_fallback"
        elseif mode == "smartest" then
            fallbackKey = "smartest_fallback"
        else
            fallbackKey = "dynamic_fallback"
        end
        txtPriceMeta:SetText(string.format(
            addonTable.L[fallbackKey],
            humanizeDynamicReason(reason)
        ))
        return
    end

    txtPriceMeta:SetText(addonTable.L["static_summary"])
end

local function updateAvailabilityMetrics(canMake, purchaseTotal, purchaseComplete)
    canMake = math.max(0, tonumber(canMake) or 0)
    txtMetricCanMakeValue:SetText(tostring(canMake))
    if canMake > 0 then
        txtMetricCanMakeValue:SetTextColor(0.92, 0.92, 0.92)
    else
        txtMetricCanMakeValue:SetTextColor(1, 0.35, 0.35)
    end

    if purchaseComplete then
        purchaseTotal = math.max(0, tonumber(purchaseTotal) or 0)
        if purchaseTotal > 0 then
            txtMetricBuyValue:SetText("~" .. addonTable.formatCopperShort(purchaseTotal))
            txtMetricBuyValue:SetTextColor(0.95, 0.82, 0.42)
        else
            txtMetricBuyValue:SetText(addonTable.L["metric_none"])
            txtMetricBuyValue:SetTextColor(0.35, 1, 0.35)
        end
    else
        txtMetricBuyValue:SetText(addonTable.L["metric_unknown"])
        txtMetricBuyValue:SetTextColor(0.72, 0.72, 0.72)
    end
end

local function collectAcquisitionLocations(acquisition)
    if type(addonTable.collectAcquisitionLocations) == "function" then
        return addonTable.collectAcquisitionLocations(acquisition)
    end
    return {}
end

local function acquisitionDisplayInfo(acquisition)
    if type(acquisition) ~= "table" then
        return nil
    end

    local model = type(acquisition.model) == "table" and acquisition.model or acquisition
    local locations = collectAcquisitionLocations(acquisition)
    local primary = locations[1]
    return {
        sourceType = model.sourceType
            or acquisition.sourceType
            or acquisition.source
            or model.source,
        sourceName = primary and primary.name
            or model.sourceName
            or acquisition.sourceName,
        zone = primary and primary.zone
            or model.zone
            or acquisition.zone,
        coordinates = primary and primary.coordinates
            or model.coordinates
            or acquisition.coordinates,
        locations = locations,
        goldCost = acquisition.goldCost
            or model.goldCost
            or model.purchasePrice
            or acquisition.purchasePrice,
        limitedStock = model.limitedStock == true or acquisition.limitedStock == true,
        reputation = model.reputation or acquisition.reputation,
        alreadyAcquired = acquisition.alreadyAcquired == true or model.alreadyAcquired == true,
    }
end

local function acquisitionSourceLabel(sourceType)
    if sourceType == "learned"
        or sourceType == "simulated_learned"
        or sourceType == "owned_recipe_item"
    then
        return addonTable.L["acquisition_known"]
    end

    local labels = {
        trainer = addonTable.L["acquisition_trainer"],
        vendor = addonTable.L["acquisition_vendor"],
        limited_vendor = addonTable.L["acquisition_limited_vendor"],
        auction = addonTable.L["acquisition_auction"],
        reputation = addonTable.L["acquisition_reputation"],
        quest = addonTable.L["acquisition_quest"],
        drop = addonTable.L["acquisition_drop"],
        world_drop = addonTable.L["acquisition_drop"],
        manual = addonTable.L["acquisition_manual"],
    }
    return labels[sourceType] or tostring(sourceType or addonTable.L["acquisition_unknown"])
end

local function formatAcquisitionLocation(location, includeName)
    if type(location) ~= "table" then return nil end
    local zone = location.zone
    local coordinates = location.coordinates
    local x = type(coordinates) == "table" and tonumber(coordinates.x or coordinates[1]) or nil
    local y = type(coordinates) == "table" and tonumber(coordinates.y or coordinates[2]) or nil
    local locationText = zone and tostring(zone) or nil
    if locationText and x and y then
        locationText = locationText .. string.format(" (%.1f, %.1f)", x, y)
    end

    if includeName and location.name and location.name ~= "" then
        if locationText then
            return tostring(location.name) .. " — " .. locationText
        end
        return tostring(location.name)
    end
    return locationText
end

local function shortAcquisitionLabel(acquisition)
    local info = acquisitionDisplayInfo(acquisition)
    if not info then
        return nil
    end
    if info.alreadyAcquired then
        return addonTable.L["acquisition_known"]
    end

    local parts = { acquisitionSourceLabel(info.sourceType) }
    local primary = info.locations and info.locations[1]
    if primary and primary.zone then
        table.insert(parts, primary.zone)
    elseif info.zone and info.zone ~= "" then
        table.insert(parts, info.zone)
    end
    if info.goldCost ~= nil then
        table.insert(parts, addonTable.formatCopperShort(info.goldCost))
    end
    return table.concat(parts, " · ")
end

local function formatAcquisitionGuidanceInfo(info)
    if not info then
        return addonTable.L["acquisition_unknown"]
    end
    if info.alreadyAcquired then
        return addonTable.L["acquisition_known"]
    end

    local parts = {
        addonTable.L["acquisition_prefix"] .. acquisitionSourceLabel(info.sourceType),
    }
    local primary = info.locations and info.locations[1]

    if primary then
        if primary.name and primary.name ~= "" then
            table.insert(parts, primary.name)
        end
        local location = formatAcquisitionLocation(primary, false)
        if location then table.insert(parts, location) end
    else
        if info.sourceName and info.sourceName ~= "" then
            table.insert(parts, info.sourceName)
        end
        if info.zone and info.zone ~= "" then
            local location = info.zone
            if type(info.coordinates) == "table" then
                local x = tonumber(info.coordinates.x or info.coordinates[1])
                local y = tonumber(info.coordinates.y or info.coordinates[2])
                if x and y then
                    location = location .. string.format(" (%.1f, %.1f)", x, y)
                end
            end
            table.insert(parts, location)
        end
    end

    if info.goldCost ~= nil then
        table.insert(parts, addonTable.formatCopperShort(info.goldCost))
    end
    if info.limitedStock then
        table.insert(parts, addonTable.L["acquisition_limited_stock"])
    end
    if type(info.reputation) == "table" and info.reputation.faction and info.reputation.standing then
        table.insert(parts, tostring(info.reputation.faction) .. " " .. tostring(info.reputation.standing))
    end

    return table.concat(parts, " · ")
end

acquisitionWhereSummary = function(acquisition)
    local info = acquisitionDisplayInfo(acquisition)
    if not info or info.alreadyAcquired then return nil end
    local locations = info.locations or {}
    if table.getn(locations) == 0 then return nil end
    return formatAcquisitionLocation(locations[1], true)
end

addAcquisitionLocationsToTooltip = function(acquisition)
    local info = acquisitionDisplayInfo(acquisition)
    if not info or info.alreadyAcquired then return end
    local locations = info.locations or {}
    if table.getn(locations) == 0 then return end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(addonTable.L["acquisition_locations_title"], 1, 0.82, 0.12, true)
    for index = 1, table.getn(locations) do
        GameTooltip:AddLine(
            formatAcquisitionLocation(locations[index], true) or "",
            0.82, 0.82, 0.82, true
        )
    end
end

local function getAcquisitionGuidance(spellID, acquisition, compact)
    if type(acquisition) == "table" then
        if compact then
            local short = shortAcquisitionLabel(acquisition)
            return short
                and (addonTable.L["acquisition_prefix"] .. short)
                or addonTable.L["acquisition_unknown"]
        end
        return formatAcquisitionGuidanceInfo(acquisitionDisplayInfo(acquisition))
    end

    if type(addonTable.explainRecipeAcquisition) ~= "function" then
        return addonTable.L["acquisition_unknown"]
    end

    local state = { learnedRecipes = {} }
    if type(UnitFactionGroup) == "function" then
        state.faction = UnitFactionGroup("player")
    end
    if type(UnitLevel) == "function" then
        state.playerLevel = UnitLevel("player")
    end

    local info = addonTable.explainRecipeAcquisition(spellID, state, professionContext, {})
    if not info or info.sourceType == "unknown" then
        return addonTable.L["acquisition_unknown"]
    end

    if compact then
        local short = shortAcquisitionLabel(info)
        return short
            and (addonTable.L["acquisition_prefix"] .. short)
            or addonTable.L["acquisition_unknown"]
    end

    return formatAcquisitionGuidanceInfo(info)
end

local function refreshAfterRecommendationSettingChange()
    if professionContext then
        resetValues()
        if type(addonTable.performanceRecordRefreshRequest) == "function" then
            addonTable.performanceRecordRefreshRequest("MODE_CHANGE")
        end
        GetCraftingToDo("MODE_CHANGE")
    else
        updateModeControls()
    end
end

function setRecommendationMode(mode)
    if mode == "cheapest" or mode == "smartest" then
        if not addonTable.setRecommendationMode("optimized") then
            return
        end
        if not addonTable.setRecommendationObjective(mode) then
            return
        end
    elseif not addonTable.setRecommendationMode(mode) then
        return
    end

    refreshAfterRecommendationSettingChange()
end

function setRecommendationAvailableOnly(availableOnly)
    if getRecommendationMode() == "static" then
        updateModeControls()
        return
    end
    if not addonTable.setRecommendationAvailableOnly(availableOnly) then
        return
    end
    refreshAfterRecommendationSettingChange()
end

local COMPARE_DIFFICULTY_COLORS = {
    orange = { 1, 0.5, 0.05 },
    yellow = { 1, 0.9, 0.1 },
}

local function compareDifficultyLabel(difficulty)
    local key = "difficulty_" .. tostring(difficulty or "")
    local label = addonTable.L[key]
    if label then
        return label
    end
    return string.upper(tostring(difficulty or "?"))
end

local function setCompareTabState(button, selected)
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

    local fontString = button.GetFontString and button:GetFontString() or nil
    if fontString then
        if selected then
            fontString:SetTextColor(1, 0.82, 0.12)
        else
            fontString:SetTextColor(0.78, 0.78, 0.78)
        end
    end
end

local function hideCompareRows()
    for i = 1, table.getn(compareRows) do
        local row = compareRows[i]
        row.candidate = nil
        if row.highlight then row.highlight:Hide() end
        row:Hide()
    end
end

local function hideRouteRows()
    for i = 1, table.getn(routeRows) do
        routeRows[i].segment = nil
        routeRows[i].rowType = nil
        routeRows[i]:Hide()
    end
end

local function getCompareReagentName(reagent)
    if not reagent then
        return addonTable.L["compare_material_unknown"]
    end

    local itemID = reagent.itemID or reagent.item
    if itemID and GetItemInfo then
        local itemName = GetItemInfo(itemID)
        if itemName and itemName ~= "" then
            return itemName
        end
    end

    return reagent.name
        or (itemID and ("Item " .. tostring(itemID)))
        or addonTable.L["compare_material_unknown"]
end

local function compareRowOnEnter(self)
    if self.highlight then
        self.highlight:Show()
    end

    local candidate = self.candidate
    if not candidate then
        return
    end

    local recipe = candidate.recipe or {}
    local recipeName = recipe.name or tostring(candidate.recipeID or "?")
    local difficulty = compareDifficultyLabel(candidate.difficulty)

    local hasNativeItem = showRecipeOutputTooltip(
        self,
        recipe,
        candidate.recipeID,
        recipeName
    )
    if hasNativeItem then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            string.format(addonTable.L["recipe_tooltip_source"], recipeName),
            1, 0.82, 0.12, true
        )
    end
    if getRecommendationMode() == "smartest" then
        GameTooltip:AddLine(difficulty, 0.82, 0.82, 0.82, true)
        addSmartestEconomicsToTooltip(candidate.cost)
    else
        GameTooltip:AddLine(string.format(
            addonTable.L["compare_material_costs"],
            difficulty,
            addonTable.formatCopperShort(candidate.costPerCraft),
            addonTable.formatCopperShort(candidate.expectedCostPerSkillUp)
        ), 0.82, 0.82, 0.82, true)
    end

    if candidate.cost and candidate.cost.quality == "stale" then
        GameTooltip:AddLine(addonTable.L["compare_stale"], 1, 0.72, 0.22, true)
    end

    local acquisitionInfo = candidate.cost
        and acquisitionDisplayInfo(candidate.cost.acquisition)
        or nil
    if acquisitionInfo and not acquisitionInfo.alreadyAcquired then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(addonTable.L["acquisition_required"], 1, 0.82, 0.12, true)
        GameTooltip:AddLine(
            getAcquisitionGuidance(candidate.recipeID, candidate.cost.acquisition),
            0.82, 0.82, 0.82, true
        )
        addAcquisitionLocationsToTooltip(candidate.cost.acquisition)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(addonTable.L["compare_materials_title"], 1, 0.82, 0.12)

    local reagents = recipe.reagents or {}
    local inventory = dynamicRecommendation
        and dynamicRecommendation.state
        and dynamicRecommendation.state.inventory
        or {}

    if table.getn(reagents) == 0 then
        GameTooltip:AddLine(addonTable.L["compare_material_none"], 0.7, 0.7, 0.7, true)
    else
        for i = 1, table.getn(reagents) do
            local reagent = reagents[i]
            local quantity = tonumber(reagent.quantity or reagent.count) or 0
            local itemID = reagent.itemID or reagent.item
            local owned = itemID and tonumber(inventory[itemID]) or nil
            local rightText = owned ~= nil
                and string.format(addonTable.L["compare_material_have"], owned)
                or ""

            GameTooltip:AddDoubleLine(
                string.format("%dx %s", quantity, getCompareReagentName(reagent)),
                rightText,
                0.92, 0.92, 0.92,
                0.65, 0.65, 0.65
            )
        end
    end

    GameTooltip:Show()
end

local function compareRowOnLeave(self)
    if self.highlight then
        self.highlight:Hide()
    end
    GameTooltip:Hide()
end

local function compareRowOnClick(self)
    compareRowOnEnter(self)
end

local function getCompareRow(index)
    if compareRows[index] then
        return compareRows[index]
    end

    local row = CreateFrame("Button", nil, MainFrameCoreCompareContent)
    row:SetWidth(608)
    row:SetHeight(COMPARE_ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnEnter", compareRowOnEnter)
    row:SetScript("OnLeave", compareRowOnLeave)
    row:SetScript("OnClick", compareRowOnClick)

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints(row)
    row.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    row.background:SetVertexColor(0.03, 0.03, 0.03, 0.58)

    row.highlight = row:CreateTexture(nil, "OVERLAY")
    row.highlight:SetAllPoints(row)
    row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.highlight:SetBlendMode("ADD")
    row.highlight:SetAlpha(0.16)
    row.highlight:Hide()

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.rank:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.rank:SetWidth(28)
    row.rank:SetJustifyH("CENTER")

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -4)
    row.name:SetWidth(205)
    row.name:SetHeight(16)
    row.name:SetJustifyH("LEFT")

    row.meta = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.meta:SetPoint("TOPLEFT", row, "TOPLEFT", 34, -20)
    row.meta:SetWidth(205)
    row.meta:SetHeight(13)
    row.meta:SetJustifyH("LEFT")

    row.difficulty = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.difficulty:SetPoint("LEFT", row, "LEFT", 244, 0)
    row.difficulty:SetWidth(70)
    row.difficulty:SetJustifyH("CENTER")

    row.perApp = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.perApp:SetPoint("LEFT", row, "LEFT", 318, 0)
    row.perApp:SetWidth(82)
    row.perApp:SetJustifyH("RIGHT")

    row.perSkill = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.perSkill:SetPoint("LEFT", row, "LEFT", 406, 0)
    row.perSkill:SetWidth(92)
    row.perSkill:SetJustifyH("RIGHT")

    row.delta = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.delta:SetPoint("LEFT", row, "LEFT", 504, 0)
    row.delta:SetWidth(98)
    row.delta:SetJustifyH("RIGHT")

    compareRows[index] = row
    return row
end

local function routeRowOnEnter(self)
    local segment = self.segment
    if not segment or self.rowType == "training" then
        return
    end

    local recipe = segment.recipe or {}
    local recipeName = recipe.name or tostring(segment.recipeID or "?")
    local hasNativeItem = showRecipeOutputTooltip(
        self,
        recipe,
        segment.recipeID,
        recipeName
    )

    if hasNativeItem then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(
            string.format(addonTable.L["recipe_tooltip_source"], recipeName),
            1, 0.82, 0.12, true
        )
    end

    if self.rowType == "acquisition" and segment.acquisition then
        GameTooltip:AddLine(
            getAcquisitionGuidance(segment.recipeID, segment.acquisition),
            0.95, 0.82, 0.42, true
        )
        addAcquisitionLocationsToTooltip(segment.acquisition)
    else
        GameTooltip:AddLine(string.format(
            addonTable.L["recipe_tooltip_route_range"],
            tonumber(segment.skillStart) or 0,
            tonumber(segment.skillEnd) or 0
        ), 0.82, 0.82, 0.82, true)

        if getRecommendationMode() == "smartest"
            and self.rowType == "craft"
            and segment.firstCost
        then
            addSmartestEconomicsToTooltip(segment.firstCost)
        end

        if self.rowType == "static"
            and type(segment.recipeNames) == "table"
            and table.getn(segment.recipeNames) > 1
        then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(addonTable.L["static_route_alternatives_title"], 1, 0.82, 0.12, true)
            for i = 2, table.getn(segment.recipeNames) do
                GameTooltip:AddLine(segment.recipeNames[i], 0.82, 0.82, 0.82, true)
            end
        end
    end
    GameTooltip:Show()
end

local function routeRowOnLeave()
    GameTooltip:Hide()
end

local function getRouteRow(index)
    if routeRows[index] then
        return routeRows[index]
    end

    local row = CreateFrame("Button", nil, MainFrameCoreCompareContent)
    row:SetWidth(608)
    row:SetHeight(ROUTE_ROW_HEIGHT)
    row:SetScript("OnEnter", routeRowOnEnter)
    row:SetScript("OnLeave", routeRowOnLeave)

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints(row)
    row.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    row.background:SetVertexColor(0.03, 0.03, 0.03, 0.50)

    row.range = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.range:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.range:SetWidth(80)
    row.range:SetJustifyH("LEFT")

    row.step = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.step:SetPoint("LEFT", row, "LEFT", 90, 0)
    row.step:SetWidth(300)
    row.step:SetJustifyH("LEFT")

    row.crafts = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.crafts:SetPoint("LEFT", row, "LEFT", 396, 0)
    row.crafts:SetWidth(78)
    row.crafts:SetJustifyH("RIGHT")

    row.cost = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.cost:SetPoint("LEFT", row, "LEFT", 480, 0)
    row.cost:SetWidth(122)
    row.cost:SetJustifyH("RIGHT")

    routeRows[index] = row
    return row
end

local function setComparisonHeadersVisible(visible)
    local headers = {
        txtCompareRankHeader,
        txtCompareRecipeHeader,
        txtCompareDifficultyHeader,
        txtCompareAppHeader,
        txtCompareSkillHeader,
        txtCompareDeltaHeader,
    }
    for i = 1, table.getn(headers) do
        if visible then headers[i]:Show() else headers[i]:Hide() end
    end
end

local function setRouteHeadersVisible(visible)
    local headers = {
        txtCompareRouteRangeHeader,
        txtCompareRouteStepHeader,
        txtCompareRouteCraftsHeader,
        txtCompareRouteCostHeader,
    }
    for i = 1, table.getn(headers) do
        if visible then headers[i]:Show() else headers[i]:Hide() end
    end
end

local function filteredComparisonCandidates()
    local result = {}
    local candidates = dynamicRecommendation and dynamicRecommendation.candidates or {}
    local requireAvailable = isAvailableOnly()
    for i = 1, table.getn(candidates) do
        local candidate = candidates[i]
        local difficulty = candidate and candidate.difficulty
        if candidate
            and (not requireAvailable or candidate.availableNow)
            and (difficulty == "orange" or difficulty == "yellow")
            and candidate.costPerCraft ~= nil
            and candidate.expectedCostPerSkillUp ~= nil
        then
            table.insert(result, candidate)
        end
    end
    return result
end

local function updateComparePanelHeight(rowCount, rowHeight)
    local rowsHeight = math.max(1, rowCount) * rowHeight
    MainFrameCoreCompare:SetHeight(math.max(
        COMPARE_MIN_HEIGHT,
        COMPARE_CONTENT_TOP + rowsHeight + COMPARE_FOOTER_SPACE
    ))
end

local function ensureRoutePagingButtons()
    if routePreviousButton and routeNextButton then
        return
    end

    routePreviousButton = CreateFrame("Button", nil, MainFrameCoreCompare, "UIPanelButtonTemplate")
    routePreviousButton:SetWidth(72)
    routePreviousButton:SetHeight(22)
    routePreviousButton:SetPoint("BOTTOMLEFT", MainFrameCoreCompare, "BOTTOMLEFT", 16, 14)
    routePreviousButton:SetText(addonTable.L["route_previous"])
    routePreviousButton:SetScript("OnClick", function()
        routePageStart = math.max(1, routePageStart - ROUTE_MAX_VISIBLE)
        refreshComparisonPanel()
    end)
    routePreviousButton:Hide()

    routeNextButton = CreateFrame("Button", nil, MainFrameCoreCompare, "UIPanelButtonTemplate")
    routeNextButton:SetWidth(72)
    routeNextButton:SetHeight(22)
    routeNextButton:SetPoint("BOTTOMLEFT", MainFrameCoreCompare, "BOTTOMLEFT", 92, 14)
    routeNextButton:SetText(addonTable.L["route_next"])
    routeNextButton:SetScript("OnClick", function()
        routePageStart = routePageStart + ROUTE_MAX_VISIBLE
        refreshComparisonPanel()
    end)
    routeNextButton:Hide()
end

local function hideRoutePagingButtons()
    if routePreviousButton then routePreviousButton:Hide() end
    if routeNextButton then routeNextButton:Hide() end
end

local function getRoutePage(total)
    ensureRoutePagingButtons()
    total = math.max(0, tonumber(total) or 0)

    local maxStart = math.floor((math.max(total, 1) - 1) / ROUTE_MAX_VISIBLE)
        * ROUTE_MAX_VISIBLE + 1
    if routePageStart > maxStart then
        routePageStart = maxStart
    elseif routePageStart < 1 then
        routePageStart = 1
    end

    local pageEnd = math.min(total, routePageStart + ROUTE_MAX_VISIBLE - 1)
    if total > ROUTE_MAX_VISIBLE then
        routePreviousButton:Show()
        routeNextButton:Show()
        if routePageStart <= 1 then routePreviousButton:Disable() else routePreviousButton:Enable() end
        if pageEnd >= total then routeNextButton:Disable() else routeNextButton:Enable() end
    else
        hideRoutePagingButtons()
    end

    return routePageStart, pageEnd
end

local function renderComparisonView()
    hideRoutePagingButtons()
    hideRouteRows()
    setRouteHeadersVisible(false)
    setComparisonHeadersVisible(true)

    local mode = getRecommendationMode()
    local availableOnly = isAvailableOnly()
    local subtitleKey
    if mode == "smartest" then
        subtitleKey = availableOnly
            and "compare_smartest_available_subtitle"
            or "compare_smartest_subtitle"
        txtCompareAppHeader:SetText(addonTable.L["compare_effective_per_app"])
        txtCompareSkillHeader:SetText(addonTable.L["compare_effective_per_skill"])
        txtCompareDeltaHeader:SetText(addonTable.L["compare_vs_chosen"])
    else
        subtitleKey = availableOnly
            and "compare_available_subtitle"
            or "compare_subtitle"
        txtCompareAppHeader:SetText(addonTable.L["compare_per_app"])
        txtCompareSkillHeader:SetText(addonTable.L["compare_per_skill"])
        txtCompareDeltaHeader:SetText(addonTable.L["compare_vs_best"])
    end
    txtCompareSubtitle:SetText(string.format(
        addonTable.L[subtitleKey],
        professionContext and professionContext.effectiveSkill or 0
    ))

    local candidates = filteredComparisonCandidates()
    local total = table.getn(candidates)
    local visible = math.min(total, compareVisibleCount, COMPARE_MAX_VISIBLE)
    local winnerCost = total > 0 and tonumber(candidates[1].expectedCostPerSkillUp) or nil

    hideCompareRows()

    for i = 1, visible do
        local candidate = candidates[i]
        local row = getCompareRow(i)
        row.candidate = candidate
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", MainFrameCoreCompareContent, "TOPLEFT", 0, -((i - 1) * COMPARE_ROW_HEIGHT))

        local name = candidate.recipe and candidate.recipe.name or tostring(candidate.recipeID or "?")
        local stale = candidate.cost and candidate.cost.quality == "stale"
        local color = COMPARE_DIFFICULTY_COLORS[candidate.difficulty] or { 0.82, 0.82, 0.82 }

        row.rank:SetText(tostring(i))
        row.name:SetText(name)
        row.difficulty:SetText(compareDifficultyLabel(candidate.difficulty))
        row.difficulty:SetTextColor(color[1], color[2], color[3])
        row.perApp:SetText("~" .. addonTable.formatCopperShort(candidate.costPerCraft))
        row.perSkill:SetText("~" .. addonTable.formatCopperShort(candidate.expectedCostPerSkillUp))

        local metaParts = {}
        if mode == "smartest" then
            local smartMeta = string.format(
                addonTable.L["compare_smartest_meta"],
                formatSkillUpChance(candidate.skillUpChance),
                formatExpectedCrafts(candidate.expectedCraftsPerSkillUp)
            )
            local surplus = tonumber(candidate.estimatedSurplusPerSkillUp) or 0
            if surplus > 0 then
                smartMeta = smartMeta .. string.format(
                    addonTable.L["compare_smartest_surplus"],
                    addonTable.formatCopperShort(surplus)
                )
            end
            table.insert(metaParts, smartMeta)
        end

        local acquisitionInfo = candidate.cost
            and acquisitionDisplayInfo(candidate.cost.acquisition)
            or nil
        if acquisitionInfo and not acquisitionInfo.alreadyAcquired then
            local acquisitionMeta = shortAcquisitionLabel(candidate.cost.acquisition)
            if acquisitionMeta then
                table.insert(metaParts, acquisitionMeta)
            end
        end

        if stale then
            table.insert(metaParts, addonTable.L["compare_stale"])
        elseif not candidate.availableNow then
            table.insert(metaParts, addonTable.L["compare_not_available_now"])
        end
        row.meta:SetText(table.concat(metaParts, " · "))

        if stale or not candidate.availableNow then
            row.meta:SetTextColor(1, 0.72, 0.22)
        elseif acquisitionInfo and not acquisitionInfo.alreadyAcquired then
            row.meta:SetTextColor(0.95, 0.82, 0.42)
        else
            row.meta:SetTextColor(0.65, 0.65, 0.65)
        end

        if stale then
            row.perApp:SetTextColor(1, 0.72, 0.22)
            row.perSkill:SetTextColor(1, 0.72, 0.22)
        else
            row.perApp:SetTextColor(0.92, 0.92, 0.92)
            row.perSkill:SetTextColor(0.92, 0.92, 0.92)
        end

        if i == 1 then
            row.background:SetVertexColor(0.04, 0.19, 0.06, 0.82)
            row.rank:SetTextColor(0.45, 1, 0.35)
            row.name:SetTextColor(0.55, 1, 0.45)
            row.delta:SetText(addonTable.L["compare_best"])
            row.delta:SetTextColor(0.45, 1, 0.35)
        else
            row.background:SetVertexColor(0.03, 0.03, 0.03, 0.58)
            row.rank:SetTextColor(0.65, 0.65, 0.65)
            row.name:SetTextColor(0.92, 0.92, 0.92)
            local delta = winnerCost and (tonumber(candidate.expectedCostPerSkillUp) - winnerCost) or nil
            if delta and delta > 0 then
                row.delta:SetText("+" .. addonTable.formatCopperShort(delta))
            else
                row.delta:SetText(addonTable.L["compare_same"])
            end
            row.delta:SetTextColor(0.72, 0.72, 0.72)
        end

        row:Show()
    end

    if total == 0 then
        txtCompareEmpty:SetText(addonTable.L["compare_no_candidates"])
        txtCompareEmpty:Show()
    else
        txtCompareEmpty:Hide()
    end

    local canShowMore = visible < total and visible < COMPARE_MAX_VISIBLE
    if canShowMore then
        local nextCount = math.min(COMPARE_EXPAND_STEP, total - visible, COMPARE_MAX_VISIBLE - visible)
        MainFrameCoreCompareShowMore:SetText(string.format(
            addonTable.L["compare_show_more"],
            nextCount
        ))
        MainFrameCoreCompareShowMore:Show()
    else
        MainFrameCoreCompareShowMore:Hide()
    end

    local rankingNote
    if mode == "smartest" then
        rankingNote = availableOnly
            and addonTable.L["compare_smartest_available_note"]
            or addonTable.L["compare_smartest_ranking_note"]
    else
        rankingNote = availableOnly
            and addonTable.L["compare_available_note"]
            or addonTable.L["compare_ranking_note"]
    end

    if total > visible and visible >= COMPARE_MAX_VISIBLE then
        txtCompareFooter:SetText(
            string.format(addonTable.L["compare_top_only"], visible, total)
                .. "\n" .. rankingNote
        )
    else
        txtCompareFooter:SetText(rankingNote)
    end

    updateComparePanelHeight(math.max(visible, 1), COMPARE_ROW_HEIGHT)
end

local function renderRouteView()
    hideCompareRows()
    hideRouteRows()
    setComparisonHeadersVisible(false)
    setRouteHeadersVisible(true)
    MainFrameCoreCompareShowMore:Hide()

    local mode = getRecommendationMode()
    local smartest = mode == "smartest"
    txtCompareSubtitle:SetText(
        addonTable.L[smartest and "compare_route_smartest_subtitle" or "compare_route_subtitle"]
    )
    txtCompareRouteCostHeader:SetText(
        addonTable.L[smartest and "compare_route_effective_header" or "compare_route_cost_header"]
    )

    local plan = dynamicRecommendation and dynamicRecommendation.plan
    if not plan or not plan.complete then
        hideRoutePagingButtons()
        txtCompareEmpty:SetText(addonTable.L["route_tooltip_incomplete"])
        txtCompareEmpty:Show()
        txtCompareFooter:SetText("")
        updateComparePanelHeight(3, ROUTE_ROW_HEIGHT)
        return
    end

    txtCompareEmpty:Hide()
    local displayRows = {}
    local segments = plan.segments or {}

    for i = 1, table.getn(segments) do
        local segment = segments[i]
        if segment.type == "craft" and segment.requiresAcquisition then
            table.insert(displayRows, {
                type = "acquisition",
                segment = segment,
            })
        end
        table.insert(displayRows, {
            type = segment.type,
            segment = segment,
        })
    end

    local count = table.getn(displayRows)
    local pageStart, pageEnd = getRoutePage(count)
    local visibleIndex = 0
    for sourceIndex = pageStart, pageEnd do
        visibleIndex = visibleIndex + 1
        local display = displayRows[sourceIndex]
        local segment = display.segment
        local row = getRouteRow(visibleIndex)
        row.segment = segment
        row.rowType = display.type
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", MainFrameCoreCompareContent, "TOPLEFT", 0, -((visibleIndex - 1) * ROUTE_ROW_HEIGHT))

        if display.type == "acquisition" then
            local name = segment.recipe and segment.recipe.name or tostring(segment.recipeID or "?")
            row.range:SetText(tostring(tonumber(segment.skillStart) or 0))
            row.step:SetText(string.format(
                addonTable.L["compare_route_acquire"],
                name,
                shortAcquisitionLabel(segment.acquisition) or addonTable.L["acquisition_unknown"]
            ))
            row.step:SetTextColor(0.95, 0.82, 0.42)
            row.crafts:SetText(addonTable.L["metric_unknown"])
            if segment.acquisitionCost ~= nil then
                row.cost:SetText("~" .. addonTable.formatCopperShort(segment.acquisitionCost))
            else
                row.cost:SetText(addonTable.L["metric_unknown"])
            end
        elseif display.type == "training" then
            row.range:SetText(tostring(tonumber(segment.skillStart) or 0))
            row.step:SetText(string.format(
                addonTable.L["compare_route_training"],
                tonumber(segment.oldCap) or 0,
                tonumber(segment.newCap) or 0
            ))
            row.step:SetTextColor(0.9, 0.82, 0.45)
            row.crafts:SetText(addonTable.L["metric_unknown"])
            row.cost:SetText("~" .. addonTable.formatCopperShort(
                smartest
                    and (segment.effectiveLevelingCost or segment.marketCost)
                    or segment.marketCost
            ))
        else
            row.range:SetText(string.format(
                addonTable.L["compare_route_range"],
                tonumber(segment.skillStart) or 0,
                tonumber(segment.skillEnd) or 0
            ))
            local name = segment.recipe and segment.recipe.name or tostring(segment.recipeID or "?")
            row.step:SetText(name)
            row.step:SetTextColor(0.92, 0.92, 0.92)
            row.crafts:SetText("~" .. tostring(math.max(0, math.ceil(tonumber(segment.expectedCrafts) or 0))))
            local craftCost
            if smartest then
                craftCost = math.max(
                    0,
                    (tonumber(segment.effectiveLevelingCost) or 0)
                        - (tonumber(segment.acquisitionCost) or 0)
                )
            else
                craftCost = math.max(
                    0,
                    (tonumber(segment.marketCost) or 0) - (tonumber(segment.acquisitionCost) or 0)
                )
            end
            row.cost:SetText("~" .. addonTable.formatCopperShort(craftCost))
        end

        row:Show()
    end

    local pageText = string.format(addonTable.L["compare_route_page"], pageStart, pageEnd, count)
    if smartest and type(addonTable.getSmartestRoutePresentation) == "function" then
        local economics = addonTable.getSmartestRoutePresentation(plan)
        if economics then
            txtCompareFooter:SetText(string.format(
                addonTable.L["compare_route_smartest_total"],
                formatEconomicCopper(economics.grossLevelingCost),
                formatEconomicCopper(economics.estimatedResaleCredit),
                formatEconomicCopper(economics.effectiveLevelingCost),
                formatEconomicCopper(economics.estimatedSurplus),
                pageText
            ))
        else
            txtCompareFooter:SetText(pageText)
        end
    else
        local totalCost = plan.estimatedCurrentPurchaseCost or plan.estimatedMarketValueCost
        if totalCost then
            txtCompareFooter:SetText(
                string.format(addonTable.L["compare_route_total"], addonTable.formatCopperShort(totalCost))
                    .. " · " .. pageText
            )
        else
            txtCompareFooter:SetText(pageText)
        end
    end

    updateComparePanelHeight(math.max(visibleIndex, 1), ROUTE_ROW_HEIGHT)
end

local function renderStaticRouteView()
    hideCompareRows()
    hideRouteRows()
    setComparisonHeadersVisible(false)
    setRouteHeadersVisible(true)
    MainFrameCoreCompareShowMore:Hide()
    txtCompareSubtitle:SetText(addonTable.L["static_route_subtitle"])

    local playerLevel
    if type(UnitLevel) == "function" then
        local ok, level = pcall(UnitLevel, "player")
        if ok then playerLevel = tonumber(level) end
    end

    local plan = type(addonTable.buildStaticProfessionRoute) == "function"
        and addonTable.buildStaticProfessionRoute(
            professionContext and professionContext.professionName,
            professionContext and professionContext.baseSkill or 0,
            450,
            professionContext,
            playerLevel
        )
        or nil

    if not plan or table.getn(plan.segments or {}) == 0 then
        hideRoutePagingButtons()
        txtCompareEmpty:SetText(addonTable.L["static_route_unavailable"])
        txtCompareEmpty:Show()
        txtCompareFooter:SetText("")
        updateComparePanelHeight(3, ROUTE_ROW_HEIGHT)
        return
    end

    txtCompareEmpty:Hide()
    local segments = plan.segments or {}
    local count = table.getn(segments)
    local pageStart, pageEnd = getRoutePage(count)
    local visibleIndex = 0

    for sourceIndex = pageStart, pageEnd do
        visibleIndex = visibleIndex + 1
        local segment = segments[sourceIndex]
        local row = getRouteRow(visibleIndex)
        row.segment = segment
        row.rowType = segment.type == "training" and "training" or "static"
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", MainFrameCoreCompareContent, "TOPLEFT", 0, -((visibleIndex - 1) * ROUTE_ROW_HEIGHT))

        if segment.type == "training" then
            row.range:SetText(tostring(tonumber(segment.skillStart) or 0))
            local trainingText = string.format(
                addonTable.L["compare_route_training"],
                tonumber(segment.oldCap) or 0,
                tonumber(segment.newCap) or 0
            )
            if segment.available == false and tonumber(segment.requiredLevel) then
                trainingText = trainingText .. " · " .. string.format(
                    addonTable.L["static_route_requires_level"],
                    tonumber(segment.requiredLevel)
                )
            end
            row.step:SetText(trainingText)
            row.step:SetTextColor(0.9, 0.82, 0.45)
        else
            row.range:SetText(string.format(
                addonTable.L["compare_route_range"],
                tonumber(segment.skillStart) or 0,
                tonumber(segment.skillEnd) or 0
            ))
            local name = segment.recipe and segment.recipe.name or tostring(segment.recipeID or "?")
            local alternatives = tonumber(segment.alternatives) or 0
            if alternatives > 0 then
                name = string.format(addonTable.L["static_route_alternatives"], name, alternatives)
            end
            row.step:SetText(name)
            row.step:SetTextColor(0.92, 0.92, 0.92)
        end

        row.crafts:SetText(addonTable.L["metric_unknown"])
        row.cost:SetText(addonTable.L["metric_unknown"])
        row:Show()
    end

    txtCompareFooter:SetText(string.format(
        addonTable.L["static_route_footer"],
        pageStart,
        pageEnd,
        count
    ))
    updateComparePanelHeight(math.max(visibleIndex, 1), ROUTE_ROW_HEIGHT)
end

function refreshComparisonPanel()
    if not MainFrameCoreCompare or not MainFrameCoreCompare:IsShown() then
        return
    end

    local mode = getRecommendationMode()
    if mode == "static" then
        if not professionContext
            or type(addonTable.buildStaticProfessionRoute) ~= "function"
        then
            MainFrameCoreCompare:Hide()
            return
        end

        MainFrameCoreCompareCurrentTab:Hide()
        MainFrameCoreCompareRouteTab:Show()
        compareView = "route"
        setCompareTabState(MainFrameCoreCompareRouteTab, true)
        renderStaticRouteView()
        return
    end

    MainFrameCoreCompareCurrentTab:Show()
    MainFrameCoreCompareRouteTab:Show()

    if not isOptimizedMode(mode)
        or not dynamicRecommendation
        or not dynamicRecommendation.available
    then
        MainFrameCoreCompare:Hide()
        return
    end

    setCompareTabState(MainFrameCoreCompareCurrentTab, compareView == "comparison")
    setCompareTabState(MainFrameCoreCompareRouteTab, compareView == "route")

    if compareView == "route" then
        renderRouteView()
    else
        renderComparisonView()
    end
end

function setComparisonView(view)
    if getRecommendationMode() == "static" then
        view = "route"
    elseif view ~= "route" then
        view = "comparison"
    end

    if compareView ~= view then
        routePageStart = 1
    end
    compareView = view
    refreshComparisonPanel()
end

function showMoreComparisonRows()
    compareVisibleCount = math.min(
        COMPARE_MAX_VISIBLE,
        compareVisibleCount + COMPARE_EXPAND_STEP
    )
    refreshComparisonPanel()
end

function toggleComparisonPanel(forceState)
    if not MainFrameCoreCompare then
        return
    end

    local shouldShow = forceState
    if shouldShow == nil then
        shouldShow = not MainFrameCoreCompare:IsShown()
    end

    if not shouldShow then
        MainFrameCoreCompare:Hide()
        return
    end

    local mode = getRecommendationMode()
    if mode == "static" then
        if not professionContext
            or type(addonTable.buildStaticProfessionRoute) ~= "function"
        then
            MainFrameCoreCompare:Hide()
            return
        end
        compareView = "route"
    elseif not isOptimizedMode(mode)
        or not dynamicRecommendation
        or not dynamicRecommendation.available
    then
        MainFrameCoreCompare:Hide()
        return
    else
        compareView = "comparison"
    end

    compareVisibleCount = COMPARE_DEFAULT_VISIBLE
    routePageStart = 1
    MainFrameCoreCompare:Show()
    refreshComparisonPanel()
end

function CompareFrame_OnLoad()
    local L = addonTable.L
    txtCompareTitle:SetText(L["compare_title"])
    txtCompareRankHeader:SetText(L["compare_rank"])
    txtCompareRecipeHeader:SetText(L["compare_recipe"])
    txtCompareDifficultyHeader:SetText(L["compare_difficulty"])
    txtCompareAppHeader:SetText(L["compare_per_app"])
    txtCompareSkillHeader:SetText(L["compare_per_skill"])
    txtCompareDeltaHeader:SetText(L["compare_vs_best"])
    txtCompareRouteRangeHeader:SetText(L["compare_route_range_header"])
    txtCompareRouteStepHeader:SetText(L["compare_route_step_header"])
    txtCompareRouteCraftsHeader:SetText(L["compare_route_crafts_header"])
    txtCompareRouteCostHeader:SetText(L["compare_route_cost_header"])
    MainFrameCoreCompareCurrentTab:SetText(L["compare_current_tab"])
    MainFrameCoreCompareRouteTab:SetText(L["compare_route_tab"])
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
    txtRecipePosition:SetText("")
    txtCraftStats:SetText("")
    txtCraftProgress:SetText("")
    txtCraftEta:SetText("")
    if txtDifficulty then txtDifficulty:SetText("") end
    if texDifficultyBackground then texDifficultyBackground:Hide() end
    resetRecommendationMetrics()
    clearMaterialRows()
    if MainFrameCoreDetails then
        MainFrameCoreDetails:Hide()
    end
    updateDetailModeControl()
    if MainFrameCoreCompare then
        MainFrameCoreCompare:Hide()
    end
    hideCraftControls()
    updateModeControls()
    MainFrameCore:SetHeight(MIN_PANEL_HEIGHT)
end

local function cancelDynamicRecommendationWork(reason)
    local pending = dynamicRecommendationJob
    dynamicRecommendationJob = nil

    if pending
        and type(addonTable.cancelDynamicProfessionRecommendation) == "function"
    then
        addonTable.cancelDynamicProfessionRecommendation(
            pending,
            reason or "superseded"
        )
    end

    if dynamicRecommendationDriver then
        dynamicRecommendationDriver:Hide()
    end
end

local function applyCurrentRecommendationSelection()
    if not professionContext then
        return false
    end

    local handler = professionHandlers[professionContext.professionName]
    if not handler then
        MainFrameCore:Hide()
        return false
    end

    local baseSkill = professionContext.baseSkill
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

    if not shouldCraft or table.getn(shouldCraft) == 0 or not targetSkill then
        showStatus(addonTable.L["no_guide_step"])
        return false
    end

    local session = addonTable.getCraftSession()
    if session and session.mode == "targeted_enchant" then
        local recommendedID = shouldCraft[1]
        if session.spellID ~= recommendedID then
            enchantRepeatNotice = "recommendation_changed"
            addonTable.clearCraftSession()
        end
    end

    displayRecipe()
    return true
end

local function ensureDynamicRecommendationDriver()
    if dynamicRecommendationDriver then
        return dynamicRecommendationDriver
    end

    dynamicRecommendationDriver = CreateFrame("Frame")
    dynamicRecommendationDriver:Hide()
    dynamicRecommendationDriver:SetScript("OnUpdate", function(self)
        local pending = dynamicRecommendationJob
        if not pending then
            self:Hide()
            return
        end

        local ok, status, recommendationOrError = pcall(
            addonTable.stepDynamicProfessionRecommendation,
            pending
        )

        if dynamicRecommendationJob ~= pending then
            return
        end

        if not ok then
            cancelDynamicRecommendationWork("optimizer_error")
            dynamicOptimizerDisabled = true
            dynamicRecommendation = {
                available = false,
                fallbackToStaticGuide = true,
                reason = "optimizer_error",
                routeReason = "optimizer_error",
            }
            if professionContext and MainFrameCore:IsShown() then
                applyCurrentRecommendationSelection()
            end
            if type(geterrorhandler) == "function" then
                geterrorhandler()(status)
            end
            return
        end

        if status == "running" then
            return
        end

        dynamicRecommendationJob = nil
        self:Hide()

        if status == "completed" then
            dynamicRecommendation = recommendationOrError
            if professionContext
                and MainFrameCore:IsShown()
                and isOptimizedMode(getRecommendationMode())
            then
                applyCurrentRecommendationSelection()
            end
            return
        end

        if status == "cancelled" then
            dynamicRecommendation = recommendationOrError
            if professionContext
                and MainFrameCore:IsShown()
                and isOptimizedMode(getRecommendationMode())
            then
                if professionRefreshCoordinator:isPending() then
                    applyCurrentRecommendationSelection()
                else
                    GetCraftingToDo("ROUTE_JOB_STALE")
                end
            end
            return
        end

        dynamicOptimizerDisabled = true
        dynamicRecommendation = {
            available = false,
            fallbackToStaticGuide = true,
            reason = "optimizer_error",
            routeReason = "optimizer_error",
        }
        if professionContext and MainFrameCore:IsShown() then
            applyCurrentRecommendationSelection()
        end
    end)

    return dynamicRecommendationDriver
end

local function getCraftingToDoInternal()
    local L = addonTable.L

    cancelDynamicRecommendationWork("superseded")

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

    local professionName = professionContext.professionName
    local handler = professionHandlers[professionName]
    if not handler then
        MainFrameCore:Hide()
        return
    end

    local decision = type(addonTable.prepareProfessionBook) == "function"
        and addonTable.prepareProfessionBook(professionName, professionContext)
        or { action = "scan", reason = "lifecycle_unavailable" }
    local bookReady = true

    if decision.action == "scan" then
        if type(addonTable.performanceCache) == "function" then
            addonTable.performanceCache("profession_book", false)
        end
        if type(addonTable.performanceIncrement) == "function" then
            addonTable.performanceIncrement("profession_book_full_scans", 1)
        end

        bookReady = withUnfilteredTradeSkill(function()
            buildRecipeCache()
        end)
        transientSpellIndexMap = {}

        if bookReady and type(addonTable.storeProfessionBookSnapshot) == "function" then
            addonTable.storeProfessionBookSnapshot(
                professionName,
                recipeCache,
                professionContext
            )
        end
    else
        if type(addonTable.performanceCache) == "function" then
            addonTable.performanceCache("profession_book", true)
        end
        recipeCache = decision.snapshot or {}
        transientSpellIndexMap = {}

        if decision.action == "refresh_live" then
            refreshCachedRecipeDifficulty()
            if type(addonTable.markProfessionBookLiveCurrent) == "function" then
                addonTable.markProfessionBookLiveCurrent(professionName, professionContext)
            end
            if type(addonTable.performanceIncrement) == "function" then
                addonTable.performanceIncrement("profession_book_live_refreshes", 1)
            end
        end
    end

    if type(addonTable.performanceSet) == "function" then
        addonTable.performanceSet("profession_book_action", decision.action)
    end

    if not bookReady then
        showStatus(L["no_guide_step"])
        return
    end

    dynamicRecommendation = nil
    local recommendationMode = getRecommendationMode()
    if isOptimizedMode(recommendationMode)
        and type(addonTable.computeDynamicProfessionRecommendation) == "function"
    then
        if dynamicOptimizerDisabled then
            dynamicRecommendation = {
                available = false,
                fallbackToStaticGuide = true,
                reason = "optimizer_error",
                routeReason = "optimizer_error",
            }
        else
            local settings = addonTable.getSettings()
            local optimizerOK, recommendationOrError = pcall(
                addonTable.computeDynamicProfessionRecommendation,
                recipeCache,
                professionContext,
                {
                    objective = settings.recommendationObjective == "smartest"
                        and "smartest"
                        or "cheapest",
                    availableOnly = settings.recommendationAvailableOnly == true,
                    incrementalRoute = true,
                }
            )

            if optimizerOK then
                dynamicRecommendation = recommendationOrError
                if dynamicRecommendation
                    and dynamicRecommendation.calculating
                    and type(addonTable.stepDynamicProfessionRecommendation) == "function"
                then
                    dynamicRecommendationJob = dynamicRecommendation
                    ensureDynamicRecommendationDriver():Show()
                end
            else
                -- Dynamic optimization must never take the deterministic guide
                -- down with it. Disable it for this UI session after a hard
                -- failure so reopening the profession cannot repeat an OOM loop.
                dynamicOptimizerDisabled = true
                dynamicRecommendation = {
                    available = false,
                    fallbackToStaticGuide = true,
                    reason = "optimizer_error",
                    routeReason = "optimizer_error",
                }
                if type(collectgarbage) == "function" then
                    pcall(collectgarbage, "collect")
                end
                if type(geterrorhandler) == "function" then
                    geterrorhandler()(recommendationOrError)
                end
            end
        end
    end

    applyCurrentRecommendationSelection()
end

function GetCraftingToDo(reason)
    local metadata = {
        profession = professionContext and professionContext.professionName or nil,
        baseSkill = professionContext and professionContext.baseSkill or nil,
        effectiveSkill = professionContext and professionContext.effectiveSkill or nil,
        currentCap = professionContext and professionContext.currentCap or nil,
        mode = getRecommendationMode(),
        providerName = type(addonTable.getActivePriceProviderName) == "function"
            and addonTable.getActivePriceProviderName()
            or nil,
        providerRevision = type(addonTable.getActivePriceProviderRevision) == "function"
            and addonTable.getActivePriceProviderRevision()
            or nil,
    }

    if type(addonTable.measurePerformanceRefresh) == "function" then
        return addonTable.measurePerformanceRefresh(
            reason or "DIRECT",
            metadata,
            getCraftingToDoInternal
        )
    end
    return getCraftingToDoInternal()
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

local function printPerformanceDebug(argument)
    local subcommand = string.lower(tostring(argument or ""))
    subcommand = string.match(subcommand, "^%s*(.-)%s*$") or ""

    if subcommand == "off" then
        addonTable.setPerformanceEnabled(false)
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper perf]|r disabled")
        return
    end

    if subcommand == "reset" then
        addonTable.setPerformanceEnabled(true)
        addonTable.resetPerformance()
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper perf]|r reset; instrumentation enabled")
        return
    end

    if subcommand == "on" then
        addonTable.setPerformanceEnabled(true)
    elseif not addonTable.isPerformanceEnabled() then
        addonTable.setPerformanceEnabled(true)
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper perf]|r enabled; perform an action, then run /pcapper perf again")
    end

    local lines = addonTable.getPerformanceSummaryLines()
    for i = 1, table.getn(lines or {}) do
        print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper perf]|r " .. lines[i])
    end
end

local function printCommandHelp()
    print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper]|r /pcapper show, hide, attach, detach, lock, unlock, reset, debug, price <itemID>, perf [on|off|reset], help")
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
    elseif action == "perf" then
        printPerformanceDebug(argument)
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

local function refreshProfessionState(forceRefresh, reason, requestRecorded)
    reason = reason or "DIRECT"
    if not requestRecorded and type(addonTable.performanceRecordRefreshRequest) == "function" then
        addonTable.performanceRecordRefreshRequest(reason)
    end

    if tradeSkillStateMutation or GetTime() < suppressTradeSkillUpdatesUntil then
        return false
    end

    if IsTradeSkillLinked() then
        professionContext = nil
        addonTable.clearProfessionSkillContext()
        MainFrameCore:Hide()
        return false
    end

    local nextContext, changed = addonTable.refreshProfessionSkillContext()
    if not nextContext then
        professionContext = nil
        MainFrameCore:Hide()
        return false
    end

    if type(addonTable.syncRuntimeSkillContext) == "function" then
        addonTable.syncRuntimeSkillContext(nextContext)
    end

    if not forceRefresh and not changed then
        return false
    end

    professionContext = nextContext
    addonTable.handleCraftRankUpdate(professionContext.baseSkill)

    if not professionHandlers[professionContext.professionName] then
        MainFrameCore:Hide()
        return false
    end

    resetValues()
    GetCraftingToDo(reason)
    addonTable.applyFramePosition(MainFrameCore)

    if addonTable.getSettings().enabled then
        MainFrameCore:Show()
    else
        MainFrameCore:Hide()
    end

    return true
end

local function cancelScheduledProfessionRefresh()
    professionRefreshCoordinator:cancel()
    if professionRefreshDriver then
        professionRefreshDriver:Hide()
    end
end

local function scheduleProfessionRefresh(delay, reason)
    reason = reason or "SCHEDULED"

    if not MainFrameCore or not MainFrameCore:IsShown() then
        return
    end

    if type(addonTable.performanceRecordRefreshRequest) == "function" then
        addonTable.performanceRecordRefreshRequest(reason)
    end

    if not professionRefreshDriver then
        professionRefreshDriver = CreateFrame("Frame")
        professionRefreshDriver:Hide()
        professionRefreshDriver:SetScript("OnUpdate", function(self)
            if not professionRefreshCoordinator:isPending() then
                self:Hide()
                return
            end

            local now = GetTime()
            if tradeSkillStateMutation or now < suppressTradeSkillUpdatesUntil then
                professionRefreshCoordinator:deferUntil(
                    suppressTradeSkillUpdatesUntil + 0.02
                )
                return
            end

            local refreshReason = professionRefreshCoordinator:takeIfDue(now)
            if not refreshReason then
                return
            end

            self:Hide()
            refreshProfessionState(true, refreshReason, true)
        end)
    end

    professionRefreshCoordinator:schedule(
        GetTime(),
        math.max(0, tonumber(delay) or PROFESSION_REFRESH_DEBOUNCE),
        reason
    )
    professionRefreshDriver:Show()
end

function fnOnLoad()
    addonTable.applyLocale()
    local L = addonTable.L

    txtHeaderLabel:SetText(L["header_label"])
    txtRecommendationLabel:SetText(L["recommendation_label"])
    txtMaterialsLabel:SetText(L["materials_label"])
    txtMetricApplicationLabel:SetText(L["metric_application"])
    txtMetricSkillLabel:SetText(L["metric_skill_up"])
    txtMetricCanMakeLabel:SetText(L["metric_can_make"])
    txtMetricBuyLabel:SetText(L["metric_buy_missing"])
    txtMaterialsHaveHeader:SetText(L["materials_have"])
    txtMaterialsNeedHeader:SetText(L["materials_need"])
    txtMaterialsMissingHeader:SetText(L["materials_missing"])
    txtMaterialsCostHeader:SetText(L["materials_cost"])
    if MainFrameCoreCheapestMode then
        MainFrameCoreCheapestMode:SetText(L["mode_cheapest"])
    end
    if MainFrameCoreStaticMode then
        MainFrameCoreStaticMode:SetText(L["mode_static"])
    end
    if MainFrameCoreRoute then
        MainFrameCoreRoute:SetText(L["route_button"])
    end
    updateDetailModeControl()
    installEnchantTargetHooks()
    updateModeControls()
    print("|cff" .. addonTable.chat_frame_default_color .. L["loaded_for"] .. "|r |cff" .. addonTable.chat_frame_player_name_color .. "[" .. UnitLevel("player") .. "]" .. UnitName("player") .. "|r")

    addonTable.getSettings()
    addonTable.applyFramePosition(MainFrameCore)

    this:RegisterEvent("TRADE_SKILL_UPDATE")
    this:RegisterEvent("TRADE_SKILL_CLOSE")
    this:RegisterEvent("BAG_UPDATE")
    this:RegisterEvent("LEARNED_SPELL_IN_TAB")
    this:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    this:RegisterEvent("PLAYER_LEVEL_UP")
    this:RegisterEvent("UPDATE_FACTION")
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
        cancelScheduledProfessionRefresh()
        cancelDynamicRecommendationWork("profession_closed")
        if type(addonTable.performanceMarkProfessionClosed) == "function" then
            addonTable.performanceMarkProfessionClosed()
        end
        addonTable.clearCraftSession()
        addonTable.clearProfessionSkillContext()
        professionContext = nil
        MainFrameCore:Hide()
        return
    end

    if event == "BAG_UPDATE" then
        if type(addonTable.noteRuntimeInventoryChanged) == "function" then
            addonTable.noteRuntimeInventoryChanged()
        end
        local session = addonTable.getCraftSession()
        if not session or not session.active then
            scheduleProfessionRefresh(PROFESSION_REFRESH_DEBOUNCE, "BAG_UPDATE")
        end
        return
    end

    if event == "LEARNED_SPELL_IN_TAB" then
        if type(addonTable.noteProfessionBookEvent) == "function" then
            addonTable.noteProfessionBookEvent(
                "LEARNED_SPELL_IN_TAB",
                professionContext and professionContext.professionName or nil
            )
        end
        if type(addonTable.noteRuntimeEligibilityChanged) == "function" then
            addonTable.noteRuntimeEligibilityChanged()
        end
        scheduleProfessionRefresh(0.05, "LEARNED_SPELL_IN_TAB")
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        refreshProfessionState(false, "PLAYER_EQUIPMENT_CHANGED")
        return
    end

    if event == "PLAYER_LEVEL_UP" or event == "UPDATE_FACTION" then
        if type(addonTable.noteRuntimeEligibilityChanged) == "function" then
            addonTable.noteRuntimeEligibilityChanged()
        end
        scheduleProfessionRefresh(0.05, event)
        return
    end

    if event == "UNIT_AURA" then
        if arg1 == "player" then
            refreshProfessionState(false, "UNIT_AURA")
        end
        return
    end

    if event == "TRADE_SKILL_UPDATE" then
        local pendingReason = professionRefreshCoordinator:getReason()
        local refreshReason = pendingReason or "TRADE_SKILL_UPDATE"
        local requestRecorded = pendingReason ~= nil
        if requestRecorded and type(addonTable.performanceRecordRefreshRequest) == "function" then
            addonTable.performanceRecordRefreshRequest("TRADE_SKILL_UPDATE")
        end
        if refreshProfessionState(false, refreshReason, requestRecorded) then
            cancelScheduledProfessionRefresh()
        end
    end
end

local function displayRecipeInternal()
    local L = addonTable.L
    local usingDynamic = isOptimizedMode(getRecommendationMode())
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
    local recipeOptionCount = table.getn(shouldCraft)
    if usingDynamic or recipeOptionCount <= 1 then
        txtRecipePosition:SetText("")
    else
        txtRecipePosition:SetText(string.format(L["recipe_position"], craftRecipeOptionsIndex, recipeOptionCount))
    end
    txtRecipeStatus:SetText("")
    updateModeControls()
    updateRecommendationSummary()
    local detailsVisible = updateDetailPanel()
    updateEnchantRepeatControls(targetedEnchant)
    if targetedEnchant then
        updateEnchantRepeatPresentation(currentID)
    end

    local renderedMaterialHeight = 0

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

        local recommendationMode = getRecommendationMode()
        local requestedDynamic = isOptimizedMode(recommendationMode)
        if usingDynamic then
            txtCraftStats:SetText("")
            txtRecipeStatus:SetText(
                recommendationMode == "available"
                    and L["available_preferred"]
                    or L["dynamic_preferred"]
            )
            txtRecipeStatus:SetTextColor(0.45, 1, 0.35)
        elseif requestedDynamic then
            txtCraftStats:SetText(string.format(L[statsKey], formatSkillUps(skillUpsNeeded), data.numAvailable, plannedCrafts))
            if dynamicRecommendation and dynamicRecommendation.calculating then
                txtRecipeStatus:SetText(L["dynamic_calculating_short"])
            else
                txtRecipeStatus:SetText(
                    recommendationMode == "available"
                        and L["available_fallback_short"]
                        or L["dynamic_fallback_short"]
                )
            end
            txtRecipeStatus:SetTextColor(1, 0.72, 0.22)
        else
            txtCraftStats:SetText(string.format(L[statsKey], formatSkillUps(skillUpsNeeded), data.numAvailable, plannedCrafts))
            txtRecipeStatus:SetText(L["static_recommendation"])
            txtRecipeStatus:SetTextColor(0.78, 0.78, 0.78)
        end

        local immediatePurchaseCost
        local purchaseCostComplete
        renderedMaterialHeight, immediatePurchaseCost, purchaseCostComplete = renderMaterials(
            data.reagents,
            materialCrafts
        )
        updateAvailabilityMetrics(data.numAvailable, immediatePurchaseCost, purchaseCostComplete)

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
                if session
                    and session.spellID == currentID
                    and session.mode == "targeted_enchant"
                    and session.needsContinue
                then
                    if session.repeatMode == "fixed" then
                        MainFrameCoreCraft:SetText(string.format(
                            L["enchant_progress_button"],
                            session.completed + 1,
                            session.queued
                        ))
                    else
                        MainFrameCoreCraft:SetText(L["enchant_again"])
                    end
                else
                    MainFrameCoreCraft:SetText(L["enchant_button"])
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
        local selectedRecipe = usingDynamic
            and dynamicRecommendation.currentSegment
            and dynamicRecommendation.currentSegment.recipe
            or nil
        local outputItemID = selectedRecipe and selectedRecipe.outputItemID or nil
        local outputTexture
        if outputItemID and GetItemInfo then
            local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(outputItemID)
            outputTexture = texture
        end

        imgSkillIcon:SetTexture(outputTexture or GetSpellTexture(currentID) or UNKNOWN_ICON)
        txtShouldCraft:SetText(shouldCraftRecipe[craftRecipeOptionsIndex] or tostring(currentID))
        txtCraftProgress:SetText("")
        clearMaterialRows()
        updateEnchantRepeatControls(false)
        MainFrameCoreCraft:Disable()

        if usingDynamic and dynamicRecommendation.requiresAcquisition then
            local difficulty = dynamicRecommendation.currentCost
                and dynamicRecommendation.currentCost.difficulty
                or nil
            local skillType = difficulty == "orange" and "optimal"
                or difficulty == "yellow" and "medium"
                or difficulty == "green" and "easy"
                or difficulty == "gray" and "trivial"
                or nil
            updateRecommendationMeta({ skillType = skillType }, professionContext.effectiveSkill, displayedTarget)

            txtRecipeStatus:SetText(
                getAcquisitionGuidance(currentID, dynamicRecommendation.acquisition, true)
            )
            txtRecipeStatus:SetTextColor(0.95, 0.82, 0.42)
            txtCraftStats:SetText(string.format(
                L["acquisition_then_craft"],
                plannedCrafts,
                displayedTarget
            ))
            txtCraftEta:SetText(dynamicPriceLine())
            updateAvailabilityMetrics(0, 0, false)
            MainFrameCoreCraft:SetText(L["acquisition_button"])
        else
            txtRecipeStatus:SetText(getAcquisitionGuidance(currentID, nil, true) or L["recipe_not_learned"])
            txtRecipeStatus:SetTextColor(1, 0.72, 0.22)
            txtCraftStats:SetText(string.format(L["stats_unlearned"], formatSkillUps(skillUpsNeeded)))
            txtCraftEta:SetText("")
            updateAvailabilityMetrics(0, 0, false)
            MainFrameCoreCraft:SetText(L["craft_button_unavail"])
        end
    end

    MainFrameCoreCraft:Show()

    local tooltipRecipe = usingDynamic
        and dynamicRecommendation.currentSegment
        and dynamicRecommendation.currentSegment.recipe
        or (type(addonTable.getRecipeCatalogRecord) == "function"
            and addonTable.getRecipeCatalogRecord(currentID)
            or nil)
    updateRecommendationTooltipTarget(
        currentID,
        tooltipRecipe,
        shouldCraftRecipe[craftRecipeOptionsIndex]
            or (data and data.name)
            or tostring(currentID),
        usingDynamic and dynamicRecommendation.acquisition or nil
    )

    updatePanelHeight(renderedMaterialHeight, targetedEnchant, detailsVisible)

    if MainFrameCoreCompare and MainFrameCoreCompare:IsShown() then
        refreshComparisonPanel()
    end

    previousRecipeKey = currentKey
end

function displayRecipe()
    if type(addonTable.measurePerformance) == "function" then
        return addonTable.measurePerformance("ui_render_update", displayRecipeInternal)
    end
    return displayRecipeInternal()
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
                enchantRepeatNotice = nil
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
    transientSpellIndexMap = {}
    dynamicRecommendation = nil
    enchantRepeatNotice = nil

    txtProfessionProgress:SetText("")
    if imgProfessionIcon then imgProfessionIcon:SetTexture(UNKNOWN_ICON) end
    if MainFrameCoreProfessionBar then
        MainFrameCoreProfessionBar:SetMinMaxValues(0, 1)
        MainFrameCoreProfessionBar:SetValue(0)
    end
    txtShouldCraft:SetText("")
    imgSkillIcon:SetTexture(UNKNOWN_ICON)
    txtTarget:SetText("")
    txtRecipeStatus:SetText("")
    txtCraftStats:SetText("")
    txtCraftProgress:SetText("")
    txtCraftEta:SetText("")
    txtRecipePosition:SetText("")
    if txtDifficulty then txtDifficulty:SetText("") end
    if texDifficultyBackground then texDifficultyBackground:Hide() end
    resetRecommendationMetrics()
    clearMaterialRows()
    if MainFrameCoreDetails then
        MainFrameCoreDetails:Hide()
    end
    updateDetailModeControl()
    updateEnchantRepeatControls(false)
    updateModeControls()

    local L = addonTable.L
    MainFrameCoreCraft:SetText(L and L["craft_button_unavail"] or "Craft")
end
