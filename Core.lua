-- Profession Capper v3 foundation
local addonName, addonTable = ...

local tradeSkillName, rank, maxLevel
local shouldCraft = {}
local shouldCraftRecipe = {}
local targetSkill
local craftRecipeOptionsIndex = 1
local previousRecipeKey = ""
local spellIndexMap = {}

local UNKNOWN_ICON = "Interface\\InventoryItems\\WoWUnknownItem01"
local ENGRAVING_ICON = "Interface\\Icons\\Trade_Engraving"
local INSCRIPTION_FALLBACK_ICON = "Interface\\Icons\\Spell_Holy_GreaterHeal"

local function buildSpellIndexMap()
    spellIndexMap = {}
    for i = 1, GetNumTradeSkills() do
        local link = GetTradeSkillRecipeLink(i)
        if link then
            local id = link:match("spell:(%d+)") or link:match("enchant:(%d+)")
            if id then
                spellIndexMap[tonumber(id)] = i
            end
        end
    end
end

local function getNumAvailableForSpell(spellId)
    local idx = spellIndexMap[spellId]
    if not idx then
        return 0
    end

    local _, _, numAvailable = GetTradeSkillInfo(idx)
    return numAvailable or 0
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

local function getRecipeIngredients(recipeIndex, plannedCrafts)
    local numReagents = GetTradeSkillNumReagents(recipeIndex)
    local parts = {}

    for j = 1, numReagents do
        local reagentName, _, reagentCount, reagentOwned = GetTradeSkillReagentInfo(recipeIndex, j)
        if reagentName then
            local totalRequired = (reagentCount or 0) * math.max(1, plannedCrafts or 1)
            if reagentOwned ~= nil then
                table.insert(parts, reagentName .. ": " .. reagentOwned .. "/" .. totalRequired)
            else
                table.insert(parts, totalRequired .. "x " .. reagentName)
            end
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

    shouldCraft, shouldCraftRecipe, targetSkill = handler(rank)

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
    buildSpellIndexMap()
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
    local idx = spellIndexMap[currentID]
    local effectiveTarget = targetSkill

    if maxLevel and maxLevel > 0 and effectiveTarget > maxLevel then
        effectiveTarget = maxLevel
    end

    local skillUpsNeeded = math.max(0, effectiveTarget - rank)
    local plannedCrafts = math.max(1, skillUpsNeeded)

    if idx then
        local skillName, skillType, numAvailable = GetTradeSkillInfo(idx)
        numAvailable = numAvailable or 0

        local exactCraftCount = skillType == "optimal"
        local statsKey = exactCraftCount and "stats_exact" or "stats_minimum"
        local etaKey = exactCraftCount and "eta_exact" or "eta_minimum"
        local icon = GetTradeSkillIcon(idx)

        if icon == ENGRAVING_ICON then
            icon = INSCRIPTION_FALLBACK_ICON
        end

        txtShouldCraft:SetText(skillName)
        imgSkillIcon:SetTexture(icon or UNKNOWN_ICON)
        txtCraftStats:SetText(string.format(L[statsKey], effectiveTarget, skillUpsNeeded, numAvailable, plannedCrafts))
        txtShouldCraftRecipe:SetText(L["recipe_prefix"] .. getRecipeIngredients(idx, plannedCrafts))

        local craftSeconds = getCraftTimeSeconds(currentID)
        if craftSeconds then
            txtCraftEta:SetText(string.format(L[etaKey], formatDuration(craftSeconds * plannedCrafts)))
        else
            txtCraftEta:SetText(L["eta_unavailable"])
        end

        local batchCount = math.min(numAvailable, plannedCrafts)
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
    local idx = currentID and spellIndexMap[currentID]

    if not idx or not targetSkill then
        return
    end

    local skillName, _, numAvailable = GetTradeSkillInfo(idx)
    numAvailable = numAvailable or 0

    local effectiveTarget = targetSkill
    if maxLevel and maxLevel > 0 and effectiveTarget > maxLevel then
        effectiveTarget = maxLevel
    end

    local skillUpsNeeded = math.max(0, effectiveTarget - rank)
    local batchCount = math.min(numAvailable, skillUpsNeeded)

    if batchCount <= 0 then
        return
    end

    local L = addonTable.L
    print("|cff" .. addonTable.chat_frame_default_color .. L["crafting"] .. "|r |cff" .. addonTable.chat_frame_player_name_color .. batchCount .. "x |r|cff" .. addonTable.chat_frame_default_color .. skillName .. "|r")
    DoTradeSkill(idx, batchCount)
end

function resetValues()
    shouldCraft = {}
    shouldCraftRecipe = {}
    targetSkill = nil
    craftRecipeOptionsIndex = 1
    previousRecipeKey = ""

    txtShouldCraft:SetText("")
    imgSkillIcon:SetTexture(UNKNOWN_ICON)
    txtCraftStats:SetText("")
    txtCraftEta:SetText("")
    txtShouldCraftRecipe:SetText("")

    local L = addonTable.L
    MainFrameCoreCraft:SetText(L and L["craft_button_unavail"] or "Craft")
end
