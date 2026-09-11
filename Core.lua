-- Profession Capper v3
local addonName, addonTable = ...

local tradeSkillName, rank, maxLevel
local shouldCraft = {}
local shouldCraftRecipe = {}
local targetSkill
local craftRecipeOptionsIndex = 1
local previousRecipeKey = ""
local recipeCache = {}
local transientSpellIndexMap = {}

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
            recipeCache[spellID] = {
                name = skillName,
                skillType = skillType,
                numAvailable = numAvailable or 0,
                icon = GetTradeSkillIcon(i),
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
        local reagentName, _, reagentCount, reagentOwned = GetTradeSkillReagentInfo(recipeIndex, i)
        if reagentName then
            table.insert(data.reagents, {
                name = reagentName,
                count = reagentCount or 0,
                owned = reagentOwned,
            })
        end
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

local function getRecipeIngredients(reagents, plannedCrafts)
    local parts = {}

    for i = 1, table.getn(reagents or {}) do
        local reagent = reagents[i]
        local totalRequired = reagent.count * math.max(1, plannedCrafts or 1)

        if reagent.owned ~= nil then
            table.insert(parts, reagent.name .. ": " .. reagent.owned .. "/" .. totalRequired)
        else
            table.insert(parts, totalRequired .. "x " .. reagent.name)
        end
    end

    return table.concat(parts, ", ")
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
end

local function showStatus(message)
    txtShouldCraft:SetText(message)
    imgSkillIcon:SetTexture(GetSpellTexture(tradeSkillName) or UNKNOWN_ICON)
    txtCraftStats:SetText("")
    txtCraftEta:SetText("")
    txtShouldCraftRecipe:SetText("")
    hideCraftControls()
    MainFrameCore:SetHeight(190)
end

function GetCraftingToDo()
    local L = addonTable.L

    if rank >= 450 then
        showStatus(L["profession_cap"])
        return
    end

    if maxLevel and maxLevel > 0 and rank >= maxLevel and maxLevel < 450 then
        showStatus(L["train_profession"])
        return
    end

    local handler = professionHandlers[tradeSkillName]
    if not handler then
        MainFrameCore:Hide()
        return
    end

    local scanned = withUnfilteredTradeSkill(function()
        buildRecipeCache()
        shouldCraft, shouldCraftRecipe, targetSkill = handler(rank)
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

    displayRecipe()
end

function TogglePcapperFrame(toggle)
    toggle = string.lower(toggle or "")

    if toggle == "show" then
        MainFrameCore:Show()
    elseif toggle == "hide" then
        MainFrameCore:Hide()
    elseif MainFrameCore:IsShown() then
        MainFrameCore:Hide()
    else
        MainFrameCore:Show()
    end
end

function fnOnLoad()
    addonTable.applyLocale()
    local L = addonTable.L

    txtHeaderLabel:SetText(L["header_label"])
    print("|cff" .. addonTable.chat_frame_default_color .. L["loaded_for"] .. "|r |cff" .. addonTable.chat_frame_player_name_color .. "[" .. UnitLevel("player") .. "]" .. UnitName("player") .. "|r")

    this:RegisterEvent("TRADE_SKILL_UPDATE")
    this:RegisterEvent("TRADE_SKILL_CLOSE")
    this:RegisterForDrag("LeftButton")

    SlashCmdList["TOGGLE_PCAPPER_FRAME"] = TogglePcapperFrame
    SLASH_TOGGLE_PCAPPER_FRAME1 = "/pcapper"
end

function fnOnEvent()
    if event == "TRADE_SKILL_CLOSE" then
        MainFrameCore:Hide()
        return
    end

    if event ~= "TRADE_SKILL_UPDATE" then
        return
    end

    if tradeSkillStateMutation or GetTime() < suppressTradeSkillUpdatesUntil then
        return
    end

    local isLinked = IsTradeSkillLinked()
    if isLinked then
        MainFrameCore:Hide()
        return
    end

    tradeSkillName, rank, maxLevel = GetTradeSkillLine()
    if not professionHandlers[tradeSkillName] then
        MainFrameCore:Hide()
        return
    end

    resetValues()
    GetCraftingToDo()
    MainFrameCore:Show()
end

function displayRecipe()
    local L = addonTable.L
    local currentKey = recipeKey(shouldCraft)

    if currentKey ~= previousRecipeKey then
        craftRecipeOptionsIndex = 1
    end

    if craftRecipeOptionsIndex < 1 then
        craftRecipeOptionsIndex = 1
    elseif craftRecipeOptionsIndex > table.getn(shouldCraft) then
        craftRecipeOptionsIndex = table.getn(shouldCraft)
    end

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

    local currentID = shouldCraft[craftRecipeOptionsIndex]
    local data = recipeCache[currentID]
    local effectiveTarget = targetSkill

    if maxLevel and maxLevel > 0 and effectiveTarget > maxLevel then
        effectiveTarget = maxLevel
    end

    local skillUpsNeeded = math.max(0, effectiveTarget - rank)
    local plannedCrafts = math.max(1, skillUpsNeeded)

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
        txtCraftStats:SetText(string.format(L[statsKey], effectiveTarget, skillUpsNeeded, data.numAvailable, plannedCrafts))
        txtShouldCraftRecipe:SetText(L["recipe_prefix"] .. getRecipeIngredients(data.reagents, plannedCrafts))

        local craftSeconds = getCraftTimeSeconds(currentID)
        if craftSeconds then
            txtCraftEta:SetText(string.format(L[etaKey], formatDuration(craftSeconds * plannedCrafts)))
        else
            txtCraftEta:SetText(L["eta_unavailable"])
        end

        local batchCount = math.min(data.numAvailable, plannedCrafts)
        if batchCount > 0 and skillUpsNeeded > 0 then
            MainFrameCoreCraft:Enable()
            MainFrameCoreCraft:SetText(string.format(L["craft_batch"], batchCount))
        else
            MainFrameCoreCraft:Disable()
            MainFrameCoreCraft:SetText(L["craft_button_unavail"])
        end
    else
        imgSkillIcon:SetTexture(UNKNOWN_ICON)
        txtShouldCraft:SetText(L["not_learned"])
        txtCraftStats:SetText(string.format("Target: %d | Need: %d skill-ups", effectiveTarget, skillUpsNeeded))
        txtCraftEta:SetText(L["eta_unavailable"])
        txtShouldCraftRecipe:SetText(L["unknown_recipe_prefix"] .. (shouldCraftRecipe[craftRecipeOptionsIndex] or tostring(currentID)))
        MainFrameCoreCraft:Disable()
        MainFrameCoreCraft:SetText(L["craft_button_unavail"])
    end

    MainFrameCoreCraft:Show()
    MainFrameCore:SetHeight(300)
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

    local effectiveTarget = targetSkill
    if maxLevel and maxLevel > 0 and effectiveTarget > maxLevel then
        effectiveTarget = maxLevel
    end

    local skillUpsNeeded = math.max(0, effectiveTarget - rank)
    if skillUpsNeeded <= 0 then
        return
    end

    local crafted = false
    local craftedName
    local craftedCount = 0

    withUnfilteredTradeSkill(function()
        local recipeIndex = findVisibleRecipeIndex(currentID)
        if not recipeIndex then
            return
        end

        local skillName, _, numAvailable = GetTradeSkillInfo(recipeIndex)
        numAvailable = numAvailable or 0

        local batchCount = math.min(numAvailable, skillUpsNeeded)
        if batchCount <= 0 then
            return
        end

        DoTradeSkill(recipeIndex, batchCount)
        crafted = true
        craftedName = skillName
        craftedCount = batchCount
    end)

    if crafted then
        local L = addonTable.L
        print("|cff" .. addonTable.chat_frame_default_color .. L["crafting"] .. "|r |cff" .. addonTable.chat_frame_player_name_color .. craftedCount .. "x |r|cff" .. addonTable.chat_frame_default_color .. craftedName .. "|r")
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

    txtShouldCraft:SetText("")
    imgSkillIcon:SetTexture(UNKNOWN_ICON)
    txtCraftStats:SetText("")
    txtCraftEta:SetText("")
    txtShouldCraftRecipe:SetText("")

    local L = addonTable.L
    MainFrameCoreCraft:SetText(L and L["craft_button_unavail"] or "Craft")
end
