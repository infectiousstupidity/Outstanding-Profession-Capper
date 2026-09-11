local addonName, addonTable = ...

local function positiveNumber(value)
    value = tonumber(value)
    if value and value > 0 then
        return value
    end
    return nil
end

local function nonNegativeNumber(value)
    value = tonumber(value)
    if value and value >= 0 then
        return value
    end
    return nil
end

local function copyMap(source)
    local result = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

local function getEffectiveSkill(baseSkill, skillContext)
    if type(addonTable.getEffectiveSkillForBase) == "function" then
        return addonTable.getEffectiveSkillForBase(baseSkill, skillContext)
    end

    local modifier = skillContext and tonumber(skillContext.activeSkillModifier) or 0
    return (tonumber(baseSkill) or 0) + (modifier or 0)
end

local function classifyDifficulty(difficulty, baseSkill)
    if type(difficulty) ~= "table" then
        return nil, nil, "missing_difficulty_metadata"
    end

    local yellow = tonumber(difficulty.yellowSkill or difficulty.yellow)
    local green = tonumber(difficulty.greenSkill or difficulty.green)
    local gray = tonumber(difficulty.graySkill or difficulty.gray)

    if not yellow or not green or not gray or yellow > green or green > gray then
        return nil, nil, "invalid_difficulty_metadata"
    end

    if baseSkill >= gray then
        return "gray", 0, nil
    end

    if baseSkill < yellow then
        return "orange", 1, nil
    end

    local denominator = gray - yellow
    if denominator <= 0 then
        return nil, nil, "invalid_difficulty_metadata"
    end

    local chance = (gray - baseSkill) / denominator
    if chance < 0 then
        chance = 0
    elseif chance > 1 then
        chance = 1
    end

    if baseSkill < green then
        return "yellow", chance, nil
    end

    return "green", chance, nil
end

function addonTable.getRecipeSkillUpChance(recipe, baseSkill, skillContext)
    if type(recipe) ~= "table" then
        return nil, nil, "invalid_recipe"
    end

    local base = tonumber(baseSkill) or 0
    local effectiveSkill = getEffectiveSkill(base, skillContext)

    if type(addonTable.evaluateRecipeDifficulty) == "function" then
        local evaluated = addonTable.evaluateRecipeDifficulty(recipe, base, skillContext)
        if evaluated and evaluated.metadataKnown then
            if evaluated.reason == "required_skill_not_met" then
                return 0, "unavailable", evaluated.reason, effectiveSkill
            end
            return evaluated.skillUpChance, evaluated.color, evaluated.reason == "gray_recipe" and nil or evaluated.reason, effectiveSkill
        end
    end

    local requiredSkill = tonumber(recipe.requiredSkill or recipe.learnSkill)
    if requiredSkill and effectiveSkill < requiredSkill then
        return 0, "unavailable", "required_skill_not_met", effectiveSkill
    end

    -- Skill modifiers can satisfy recipe requirements, but recipe color and
    -- skill-up chance are based on trained/base skill.
    local difficulty, chance, reason = classifyDifficulty(recipe.difficulty, base)
    return chance, difficulty, reason, effectiveSkill
end

local function getPriceLookup(options)
    if options and type(options.priceLookup) == "function" then
        return options.priceLookup
    end
    return addonTable.lookupItemPrice
end

local function getPriceChooser(options)
    if options and type(options.unitPriceChooser) == "function" then
        return options.unitPriceChooser
    end
    return addonTable.chooseUsableUnitPrice
end

local function selectPurchaseChoice(priceResult, chooser)
    if type(priceResult) ~= "table" or not priceResult.available then
        return nil, priceResult and priceResult.unavailableReason or "price_unavailable"
    end

    local auctionChoice = chooser and select(1, chooser(priceResult, "auction")) or nil
    local vendorChoice = chooser and select(1, chooser(priceResult, "vendor")) or nil

    if auctionChoice and vendorChoice then
        if vendorChoice.unitPrice <= auctionChoice.unitPrice then
            return vendorChoice
        end
        return auctionChoice
    end

    if vendorChoice then
        return vendorChoice
    end
    if auctionChoice then
        return auctionChoice
    end

    if chooser then
        return chooser(priceResult, "spend")
    end

    return nil, "no_current_purchase_price"
end

local function resolveAcquisition(recipe, state, skillContext, options)
    if type(addonTable.resolveRecipeAcquisition) == "function" then
        local modeled = addonTable.resolveRecipeAcquisition(recipe, state, skillContext, options)
        if modeled and modeled.handled then
            return {
                available = modeled.available == true,
                alreadyAcquired = modeled.alreadyAcquired == true,
                marketCost = modeled.marketCost,
                goldCost = modeled.goldCost,
                key = modeled.key,
                source = modeled.sourceType or modeled.source,
                reason = modeled.reason,
                model = modeled,
            }
        end
    end

    local spellID = recipe.spellID or recipe.recipeID
    local learnedRecipes = state and state.learnedRecipes
    if spellID and type(learnedRecipes) == "table" and learnedRecipes[spellID] then
        return {
            available = true,
            alreadyAcquired = true,
            marketCost = 0,
            goldCost = 0,
            key = "recipe:" .. tostring(spellID),
            source = "learned",
        }
    end

    local acquisition = recipe.acquisition
    if type(acquisition) ~= "table" then
        return {
            available = false,
            reason = "missing_acquisition_metadata",
        }
    end

    local status = acquisition.status or acquisition.state
    if status == "learned" or acquisition.alreadyLearned then
        return {
            available = true,
            alreadyAcquired = true,
            marketCost = 0,
            goldCost = 0,
            key = acquisition.key or (spellID and ("recipe:" .. tostring(spellID)) or nil),
            source = status or "learned",
        }
    end

    if acquisition.available == false
        or status == "unavailable"
        or status == "unknown"
        or status == "reputation"
        or status == "drop"
        or status == "quest"
    then
        return {
            available = false,
            reason = acquisition.reason or "recipe_not_immediately_acquirable",
            source = status,
        }
    end

    local goldCost = nonNegativeNumber(acquisition.goldCost or acquisition.purchasePrice)
    local marketCost = nonNegativeNumber(acquisition.marketCost)
    if marketCost == nil then
        marketCost = goldCost
    end

    if acquisition.available == true or status == "trainable" or status == "vendor" or status == "purchasable" then
        if goldCost == nil then
            return {
                available = false,
                reason = "missing_acquisition_cost",
                source = status,
            }
        end

        return {
            available = true,
            alreadyAcquired = false,
            marketCost = marketCost,
            goldCost = goldCost,
            key = acquisition.key or (spellID and ("recipe:" .. tostring(spellID)) or nil),
            source = status,
        }
    end

    return {
        available = false,
        reason = "unsupported_acquisition_state",
        source = status,
    }
end

local function getInventoryCount(inventory, reagent)
    if type(inventory) ~= "table" then
        return 0
    end

    local key = reagent.itemID or reagent.item or reagent.itemLink
    local value = inventory[key]
    if value == nil and reagent.itemID then
        value = inventory[tostring(reagent.itemID)]
    end
    return math.max(0, tonumber(value) or 0)
end

local function getReagentKey(reagent)
    if reagent.reusableKey then
        return tostring(reagent.reusableKey)
    end
    if reagent.itemID then
        return "item:" .. tostring(reagent.itemID)
    end
    if reagent.item then
        return "item:" .. tostring(reagent.item)
    end
    return nil
end

local function addMissingFlag(flags, item, reason)
    table.insert(flags, {
        item = item,
        reason = reason,
    })
end

function addonTable.calculateRecipeCost(recipe, baseSkill, skillContext, state, options)
    state = state or {}
    options = options or {}

    local chance, difficulty, difficultyReason, effectiveSkill = addonTable.getRecipeSkillUpChance(
        recipe,
        baseSkill,
        skillContext
    )

    local result = {
        recipe = recipe,
        spellID = recipe and (recipe.spellID or recipe.recipeID) or nil,
        baseSkill = tonumber(baseSkill) or 0,
        effectiveSkill = effectiveSkill,
        difficulty = difficulty,
        skillUpChance = chance,
        expectedCraftsPerSkillUp = nil,
        materialMarketValuePerCraft = nil,
        goldNeededNowPerCraft = nil,
        expectedMarketCostPerSkillUp = nil,
        expectedGoldNeededNowPerSkillUp = nil,
        acquisitionCost = nil,
        acquisitionMarketCost = nil,
        reagentCosts = {},
        missingPrices = {},
        stalePrices = {},
        oneTimeCosts = {},
        available = false,
        useful = false,
        incomplete = false,
        quality = "unavailable",
        unavailableReason = nil,
    }

    if not recipe or type(recipe) ~= "table" then
        result.unavailableReason = "invalid_recipe"
        return result
    end

    if difficultyReason then
        result.incomplete = true
        result.quality = "incomplete"
        result.unavailableReason = difficultyReason
        return result
    end

    if not chance or chance <= 0 then
        result.unavailableReason = difficulty == "gray" and "gray_recipe" or "no_skill_up_chance"
        return result
    end

    local acquisition = resolveAcquisition(recipe, state, skillContext, options)
    result.acquisition = acquisition
    if not acquisition.available then
        result.incomplete = acquisition.reason == "missing_acquisition_metadata" or acquisition.reason == "missing_acquisition_cost"
        result.quality = result.incomplete and "incomplete" or "unavailable"
        result.unavailableReason = acquisition.reason
        return result
    end

    result.acquisitionCost = acquisition.goldCost or 0
    result.acquisitionMarketCost = acquisition.marketCost or acquisition.goldCost or 0
    if not acquisition.alreadyAcquired and acquisition.key then
        table.insert(result.oneTimeCosts, {
            key = acquisition.key,
            kind = "recipe_acquisition",
            marketCost = result.acquisitionMarketCost,
            goldCost = result.acquisitionCost,
        })
    end

    local priceLookup = getPriceLookup(options)
    local priceChooser = getPriceChooser(options)
    if type(priceLookup) ~= "function" or type(priceChooser) ~= "function" then
        result.incomplete = true
        result.quality = "incomplete"
        result.unavailableReason = "price_provider_unavailable"
        return result
    end

    local expectedCrafts = 1 / chance
    local marketPerCraft = 0
    local goldPerCraft = 0
    local expectedMarket = 0
    local expectedGold = 0
    local hasStale = false
    local inventoryRemaining = copyMap(state.inventory)
    local acquiredOneTime = state.acquiredOneTime or state.acquiredReusable or {}

    local reagents = recipe.reagents or {}
    for index = 1, table.getn(reagents) do
        local reagent = reagents[index]
        local quantity = positiveNumber(reagent.quantity or reagent.count)
        local item = reagent.itemID or reagent.item or reagent.itemLink

        if not quantity or not item then
            result.incomplete = true
            addMissingFlag(result.missingPrices, item, "invalid_reagent")
        else
            local reusable = reagent.reusable and true or false
            local reusableKey = reusable and getReagentKey(reagent) or nil
            local alreadyAcquired = reusableKey and acquiredOneTime[reusableKey]
            local priceResult = priceLookup(item, options.now)
            local marketChoice, marketReason = priceChooser(priceResult, "market")
            local purchaseChoice, purchaseReason = selectPurchaseChoice(priceResult, priceChooser)

            if not marketChoice or not purchaseChoice then
                result.incomplete = true
                addMissingFlag(
                    result.missingPrices,
                    item,
                    marketReason or purchaseReason or "price_unavailable"
                )
            else
                local owned = getInventoryCount(inventoryRemaining, reagent)
                local ownedUsed = math.min(quantity, owned)
                local purchaseQuantity = math.max(0, quantity - ownedUsed)
                local itemKey = reagent.itemID or reagent.item or reagent.itemLink
                if itemKey ~= nil then
                    inventoryRemaining[itemKey] = math.max(0, owned - ownedUsed)
                    if reagent.itemID then
                        inventoryRemaining[tostring(reagent.itemID)] = nil
                    end
                end

                local craftMarket = quantity * marketChoice.unitPrice
                local craftGold = purchaseQuantity * purchaseChoice.unitPrice
                local multiplier = reusable and 1 or expectedCrafts

                if alreadyAcquired then
                    craftMarket = 0
                    craftGold = 0
                    multiplier = 0
                end

                marketPerCraft = marketPerCraft + craftMarket
                goldPerCraft = goldPerCraft + craftGold
                expectedMarket = expectedMarket + (craftMarket * multiplier)
                expectedGold = expectedGold + (craftGold * multiplier)

                if reusable and not alreadyAcquired and reusableKey then
                    table.insert(result.oneTimeCosts, {
                        key = reusableKey,
                        kind = "reusable_reagent",
                        item = item,
                        marketCost = craftMarket,
                        goldCost = craftGold,
                    })
                end

                if marketChoice.isStale or purchaseChoice.isStale
                    or marketChoice.isTooOld or purchaseChoice.isTooOld
                    or (priceResult and priceResult.isSuspicious)
                then
                    hasStale = true
                    table.insert(result.stalePrices, {
                        item = item,
                        source = purchaseChoice.source or marketChoice.source,
                        freshness = purchaseChoice.freshness or marketChoice.freshness,
                        ageSeconds = purchaseChoice.ageSeconds or marketChoice.ageSeconds,
                        suspicious = priceResult and priceResult.isSuspicious or false,
                    })
                end

                table.insert(result.reagentCosts, {
                    item = item,
                    itemID = reagent.itemID,
                    quantity = quantity,
                    owned = ownedUsed,
                    purchaseQuantity = purchaseQuantity,
                    reusable = reusable,
                    reusableKey = reusableKey,
                    marketUnitPrice = marketChoice.unitPrice,
                    marketPriceType = marketChoice.priceType,
                    purchaseUnitPrice = purchaseChoice.unitPrice,
                    purchasePriceType = purchaseChoice.priceType,
                    source = purchaseChoice.source or marketChoice.source,
                    freshness = purchaseChoice.freshness or marketChoice.freshness,
                })
            end
        end
    end

    if result.incomplete then
        result.quality = "incomplete"
        result.unavailableReason = "incomplete_price_data"
        return result
    end

    result.expectedCraftsPerSkillUp = expectedCrafts
    result.materialMarketValuePerCraft = marketPerCraft
    result.goldNeededNowPerCraft = goldPerCraft
    result.expectedMarketCostPerSkillUp = expectedMarket
    result.expectedGoldNeededNowPerSkillUp = expectedGold
    result.available = true
    result.useful = true
    result.quality = hasStale and "stale" or "complete"

    return result
end
