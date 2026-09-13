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

local ESSENCE_EQUIVALENTS = {
    [10938] = { alternateItemID = 10939, multiplier = 1 / 3, ratio = 3, direction = "greater_to_lesser" },
    [10939] = { alternateItemID = 10938, multiplier = 3, ratio = 3, direction = "lesser_to_greater" },
    [10998] = { alternateItemID = 11082, multiplier = 1 / 3, ratio = 3, direction = "greater_to_lesser" },
    [11082] = { alternateItemID = 10998, multiplier = 3, ratio = 3, direction = "lesser_to_greater" },
    [11134] = { alternateItemID = 11135, multiplier = 1 / 3, ratio = 3, direction = "greater_to_lesser" },
    [11135] = { alternateItemID = 11134, multiplier = 3, ratio = 3, direction = "lesser_to_greater" },
    [11174] = { alternateItemID = 11175, multiplier = 1 / 3, ratio = 3, direction = "greater_to_lesser" },
    [11175] = { alternateItemID = 11174, multiplier = 3, ratio = 3, direction = "lesser_to_greater" },
    [16202] = { alternateItemID = 16203, multiplier = 1 / 3, ratio = 3, direction = "greater_to_lesser" },
    [16203] = { alternateItemID = 16202, multiplier = 3, ratio = 3, direction = "lesser_to_greater" },
    [22447] = { alternateItemID = 22446, multiplier = 1 / 3, ratio = 3, direction = "greater_to_lesser" },
    [22446] = { alternateItemID = 22447, multiplier = 3, ratio = 3, direction = "lesser_to_greater" },
    [34056] = { alternateItemID = 34055, multiplier = 1 / 3, ratio = 3, direction = "greater_to_lesser" },
    [34055] = { alternateItemID = 34056, multiplier = 3, ratio = 3, direction = "lesser_to_greater" },
}

local function parseItemID(item)
    if type(item) == "number" then
        return item
    end
    if type(item) ~= "string" then
        return nil
    end

    local numeric = tonumber(item)
    if numeric then
        return numeric
    end

    local itemID = string.match(item, "[Ii][Tt][Ee][Mm]:(%d+)")
    return itemID and tonumber(itemID) or nil
end

local function copyChoice(choice)
    local result = {}
    if type(choice) == "table" then
        for key, value in pairs(choice) do
            result[key] = value
        end
    end
    return result
end

local function chooseItemPrice(item, purpose, lookup, chooser, now)
    local priceResult = lookup(item, now)
    local choice
    local reason

    if purpose == "purchase" then
        choice, reason = selectPurchaseChoice(priceResult, chooser)
    else
        choice, reason = chooser(priceResult, purpose)
    end

    if not choice then
        return nil, reason or (priceResult and priceResult.unavailableReason) or "price_unavailable"
    end

    local result = copyChoice(choice)
    result.requestedItemID = parseItemID(item)
    result.sourceItemID = parseItemID(item)
    result.converted = false
    result.isSuspicious = priceResult and priceResult.isSuspicious or false
    return result
end

function addonTable.getEquivalentReagent(item)
    local itemID = parseItemID(item)
    if not itemID then
        return nil
    end
    return ESSENCE_EQUIVALENTS[itemID]
end

function addonTable.chooseCheapestEquivalentUnitPrice(item, purpose, options)
    options = options or {}
    local lookup = getPriceLookup(options)
    local chooser = getPriceChooser(options)
    if type(lookup) ~= "function" or type(chooser) ~= "function" then
        return nil, "price_provider_unavailable"
    end

    local direct, directReason = chooseItemPrice(item, purpose, lookup, chooser, options.now)
    local itemID = parseItemID(item)
    local equivalent = itemID and ESSENCE_EQUIVALENTS[itemID] or nil
    if not equivalent then
        return direct, directReason
    end

    local alternate, alternateReason = chooseItemPrice(
        equivalent.alternateItemID,
        purpose,
        lookup,
        chooser,
        options.now
    )

    if alternate then
        alternate.unitPrice = alternate.unitPrice * equivalent.multiplier
        alternate.requestedItemID = itemID
        alternate.sourceItemID = equivalent.alternateItemID
        alternate.converted = true
        alternate.conversionRatio = equivalent.ratio
        alternate.conversionDirection = equivalent.direction
    end

    if direct and alternate then
        if alternate.unitPrice < direct.unitPrice then
            return alternate
        end
        return direct
    end
    if alternate then
        return alternate
    end
    if direct then
        return direct
    end

    return nil, directReason or alternateReason or "price_unavailable"
end

local function ceilPositive(value)
    value = math.max(0, tonumber(value) or 0)
    if value <= 0 then
        return 0
    end
    return math.ceil(value - 0.0000001)
end

local function buildQuantityChoice(
    choice,
    requestedItemID,
    requestedQuantity,
    sourceItemID,
    sourceQuantity,
    converted,
    equivalent
)
    if not choice then
        return nil
    end

    local result = copyChoice(choice)
    result.requestedItemID = requestedItemID
    result.requestedQuantity = requestedQuantity
    result.sourceItemID = sourceItemID
    result.sourceQuantity = sourceQuantity
    result.sourceUnitPrice = choice.unitPrice
    result.totalCost = sourceQuantity * choice.unitPrice
    result.effectiveUnitPrice = requestedQuantity > 0
        and (result.totalCost / requestedQuantity)
        or 0
    result.unitPrice = result.effectiveUnitPrice
    result.converted = converted and true or false

    if converted and equivalent then
        result.conversionRatio = equivalent.ratio
        result.conversionDirection = equivalent.direction
        if equivalent.direction == "greater_to_lesser" then
            result.producedQuantity = sourceQuantity * equivalent.ratio
        else
            result.producedQuantity = sourceQuantity / equivalent.ratio
        end
        result.excessQuantity = math.max(0, result.producedQuantity - requestedQuantity)
    else
        result.producedQuantity = requestedQuantity
        result.excessQuantity = 0
    end

    return result
end

function addonTable.chooseCheapestEquivalentPurchase(item, quantity, purpose, options)
    options = options or {}
    quantity = math.max(0, tonumber(quantity) or 0)
    if quantity <= 0 then
        return {
            requestedItemID = parseItemID(item),
            requestedQuantity = 0,
            sourceItemID = parseItemID(item),
            sourceQuantity = 0,
            sourceUnitPrice = 0,
            totalCost = 0,
            effectiveUnitPrice = 0,
            unitPrice = 0,
            producedQuantity = 0,
            excessQuantity = 0,
            converted = false,
        }
    end

    local lookup = getPriceLookup(options)
    local chooser = getPriceChooser(options)
    if type(lookup) ~= "function" or type(chooser) ~= "function" then
        return nil, "price_provider_unavailable"
    end

    local itemID = parseItemID(item)
    local directChoice, directReason = chooseItemPrice(item, purpose, lookup, chooser, options.now)
    local direct = buildQuantityChoice(
        directChoice,
        itemID,
        quantity,
        itemID,
        ceilPositive(quantity),
        false,
        nil
    )

    local equivalent = itemID and ESSENCE_EQUIVALENTS[itemID] or nil
    if not equivalent then
        return direct, directReason
    end

    local alternateChoice, alternateReason = chooseItemPrice(
        equivalent.alternateItemID,
        purpose,
        lookup,
        chooser,
        options.now
    )

    local alternateSourceQuantity
    if equivalent.direction == "greater_to_lesser" then
        alternateSourceQuantity = ceilPositive(quantity / equivalent.ratio)
    else
        alternateSourceQuantity = ceilPositive(quantity * equivalent.ratio)
    end

    local alternate = buildQuantityChoice(
        alternateChoice,
        itemID,
        quantity,
        equivalent.alternateItemID,
        alternateSourceQuantity,
        true,
        equivalent
    )

    local chosen
    if direct and alternate then
        if alternate.totalCost < direct.totalCost then
            chosen = alternate
        else
            chosen = direct
        end
    else
        chosen = alternate or direct
    end

    if not chosen then
        return nil, directReason or alternateReason or "price_unavailable"
    end

    chosen.directTotalCost = direct and direct.totalCost or nil
    chosen.alternateTotalCost = alternate and alternate.totalCost or nil
    chosen.alternateItemID = equivalent.alternateItemID

    if direct and alternate then
        local otherCost = chosen.converted and direct.totalCost or alternate.totalCost
        chosen.savings = math.max(0, otherCost - chosen.totalCost)
    else
        chosen.savings = 0
    end

    return chosen
end

local function resolveAcquisition(recipe, state, skillContext, options, simulatedBaseSkill)
    if type(addonTable.resolveRecipeAcquisition) == "function" then
        local acquisitionOptions = {}
        for key, value in pairs(options or {}) do acquisitionOptions[key] = value end
        acquisitionOptions.baseSkill = simulatedBaseSkill
        local modeled = addonTable.resolveRecipeAcquisition(recipe, state, skillContext, acquisitionOptions)
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

local function classifyPurchaseAvailability(choice, requiredQuantity)
    if not choice then
        return false, "no_purchase_source"
    end

    if choice.priceType == "vendor" then
        return true, "vendor"
    end

    if choice.priceType ~= "auction" then
        return false, "not_current_purchase_source"
    end

    if not choice.isFresh then
        return false, "auction_scan_stale"
    end

    local availableQuantity = tonumber(choice.availableQuantity)
    local needed = math.max(0, tonumber(requiredQuantity) or 0)
    if availableQuantity and availableQuantity < needed then
        return false, "insufficient_auction_quantity"
    end

    if availableQuantity then
        return true, "confirmed_quantity"
    end

    -- The current WotLK TSM AuctionDB backport confirms that a listing existed
    -- at scan time but does not persist total stack quantity. Treat a fresh
    -- listing as available, but expose the weaker confidence explicitly.
    return true, "fresh_listing"
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
        currentPurchaseCostPerCraft = nil,
        expectedMarketCostPerSkillUp = nil,
        expectedGoldNeededNowPerSkillUp = nil,
        expectedCurrentPurchaseCostPerSkillUp = nil,
        acquisitionCost = nil,
        acquisitionMarketCost = nil,
        reagentCosts = {},
        missingPrices = {},
        stalePrices = {},
        oneTimeCosts = {},
        availabilityIssues = {},
        availableNow = false,
        availabilityConfidence = "unavailable",
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

    local acquisition = resolveAcquisition(recipe, state, skillContext, options, baseSkill)
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
    local currentPurchasePerCraft = 0
    local expectedCurrentPurchase = 0
    local hasStale = false
    local allPurchasesAvailableNow = true
    local listingOnlyAvailability = false
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
            local owned = getInventoryCount(inventoryRemaining, reagent)
            local ownedUsed = math.min(quantity, owned)
            local purchaseQuantity = math.max(0, quantity - ownedUsed)
            local equivalentOptions = {
                priceLookup = priceLookup,
                unitPriceChooser = priceChooser,
                now = options.now,
            }
            local marketChoice, marketReason = addonTable.chooseCheapestEquivalentPurchase(
                item,
                quantity,
                "market",
                equivalentOptions
            )
            local purchaseChoice, purchaseReason = addonTable.chooseCheapestEquivalentPurchase(
                item,
                quantity,
                "purchase",
                equivalentOptions
            )
            local neededPurchaseChoice
            local neededPurchaseReason
            if purchaseQuantity > 0 then
                neededPurchaseChoice, neededPurchaseReason = addonTable.chooseCheapestEquivalentPurchase(
                    item,
                    purchaseQuantity,
                    "purchase",
                    equivalentOptions
                )
            end

            if not marketChoice or not purchaseChoice or (purchaseQuantity > 0 and not neededPurchaseChoice) then
                result.incomplete = true
                addMissingFlag(
                    result.missingPrices,
                    item,
                    marketReason or purchaseReason or neededPurchaseReason or "price_unavailable"
                )
            else
                local availabilityConfirmed = true
                local availabilityReason = alreadyAcquired and "owned_reusable" or "owned"
                if purchaseQuantity > 0 and not alreadyAcquired then
                    availabilityConfirmed, availabilityReason = classifyPurchaseAvailability(
                        neededPurchaseChoice,
                        neededPurchaseChoice and neededPurchaseChoice.sourceQuantity or purchaseQuantity
                    )
                    if not availabilityConfirmed then
                        allPurchasesAvailableNow = false
                        table.insert(result.availabilityIssues, {
                            item = item,
                            reason = availabilityReason,
                        })
                    elseif availabilityReason == "fresh_listing" then
                        listingOnlyAvailability = true
                    end
                end

                local itemKey = reagent.itemID or reagent.item or reagent.itemLink
                if itemKey ~= nil then
                    inventoryRemaining[itemKey] = math.max(0, owned - ownedUsed)
                    if reagent.itemID then
                        inventoryRemaining[tostring(reagent.itemID)] = nil
                    end
                end

                local craftMarket = marketChoice.totalCost
                local craftGold = neededPurchaseChoice and neededPurchaseChoice.totalCost or 0
                local craftCurrentPurchase = purchaseChoice.totalCost
                local multiplier = reusable and 1 or expectedCrafts

                if alreadyAcquired then
                    craftMarket = 0
                    craftGold = 0
                    craftCurrentPurchase = 0
                    multiplier = 0
                end

                marketPerCraft = marketPerCraft + craftMarket
                goldPerCraft = goldPerCraft + craftGold
                currentPurchasePerCraft = currentPurchasePerCraft + craftCurrentPurchase
                expectedMarket = expectedMarket + (craftMarket * multiplier)
                expectedGold = expectedGold + (craftGold * multiplier)
                expectedCurrentPurchase = expectedCurrentPurchase + (craftCurrentPurchase * multiplier)

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
                    or marketChoice.isSuspicious or purchaseChoice.isSuspicious
                then
                    hasStale = true
                    table.insert(result.stalePrices, {
                        item = item,
                        source = purchaseChoice.source or marketChoice.source,
                        freshness = purchaseChoice.freshness or marketChoice.freshness,
                        ageSeconds = purchaseChoice.ageSeconds or marketChoice.ageSeconds,
                        suspicious = marketChoice.isSuspicious or purchaseChoice.isSuspicious or false,
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
                    marketUnitPrice = marketChoice.effectiveUnitPrice,
                    marketPriceType = marketChoice.priceType,
                    purchaseUnitPrice = purchaseChoice.effectiveUnitPrice,
                    purchaseSourceUnitPrice = purchaseChoice.sourceUnitPrice,
                    purchasePriceType = purchaseChoice.priceType,
                    purchaseTotalCost = purchaseChoice.totalCost,
                    source = purchaseChoice.source or marketChoice.source,
                    freshness = purchaseChoice.freshness or marketChoice.freshness,
                    ageSeconds = purchaseChoice.ageSeconds or marketChoice.ageSeconds,
                    sourceItemID = purchaseChoice.sourceItemID,
                    sourceQuantity = purchaseChoice.sourceQuantity,
                    producedQuantity = purchaseChoice.producedQuantity,
                    excessQuantity = purchaseChoice.excessQuantity,
                    directTotalCost = purchaseChoice.directTotalCost,
                    alternateTotalCost = purchaseChoice.alternateTotalCost,
                    savings = purchaseChoice.savings,
                    converted = purchaseChoice.converted and true or false,
                    conversionRatio = purchaseChoice.conversionRatio,
                    conversionDirection = purchaseChoice.conversionDirection,
                    availableNow = availabilityConfirmed,
                    availabilityReason = availabilityReason,
                    availabilityPriceType = neededPurchaseChoice and neededPurchaseChoice.priceType or nil,
                    availabilityAgeSeconds = neededPurchaseChoice and neededPurchaseChoice.ageSeconds or nil,
                    availabilitySourceItemID = neededPurchaseChoice and neededPurchaseChoice.sourceItemID or nil,
                    availabilitySourceQuantity = neededPurchaseChoice and neededPurchaseChoice.sourceQuantity or 0,
                    availabilityQuantity = neededPurchaseChoice and neededPurchaseChoice.availableQuantity or nil,
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
    result.currentPurchaseCostPerCraft = currentPurchasePerCraft
    result.expectedMarketCostPerSkillUp = expectedMarket
    result.expectedGoldNeededNowPerSkillUp = expectedGold
    result.expectedCurrentPurchaseCostPerSkillUp = expectedCurrentPurchase
    result.availableNow = allPurchasesAvailableNow
    result.availabilityConfidence = allPurchasesAvailableNow
        and (listingOnlyAvailability and "fresh_listing" or "confirmed")
        or "unavailable"
    result.available = true
    result.useful = true
    result.quality = hasStale and "stale" or "complete"

    return result
end
