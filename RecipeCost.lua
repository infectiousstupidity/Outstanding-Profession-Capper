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

local function getInventoryCount(inventory, reagent, state)
    local key = reagent.itemID or reagent.item or reagent.itemLink
    local value
    if type(inventory) == "table" then
        value = inventory[key]
        if value == nil and reagent.itemID then
            value = inventory[tostring(reagent.itemID)]
        end
    end
    if value == nil and state and type(state.getInventoryCount) == "function" then
        local ok, count = pcall(state.getInventoryCount, reagent.itemID or key, 0)
        if ok and tonumber(count) then value = count end
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

    local maxAge = 15 * 60
    if addonTable.priceFreshnessSettings
        and tonumber(addonTable.priceFreshnessSettings.availableNowMaxAgeSeconds)
    then
        maxAge = tonumber(addonTable.priceFreshnessSettings.availableNowMaxAgeSeconds)
    end

    local ageSeconds = tonumber(choice.ageSeconds)
    if not ageSeconds then
        return false, "auction_scan_age_unknown"
    end
    if ageSeconds > maxAge then
        return false, "auction_scan_too_old_for_available"
    end

    local needed = math.max(0, tonumber(requiredQuantity) or 0)
    local availableQuantity = tonumber(choice.availableQuantity)
    local minimumQuantity = availableQuantity or tonumber(choice.numAuctions)
    if not minimumQuantity then
        return false, "auction_quantity_unknown"
    end
    if minimumQuantity < needed then
        return false, "insufficient_auction_quantity"
    end

    if availableQuantity then
        return true, "confirmed_quantity"
    end
    return true, "confirmed_minimum_quantity"
end

local function chooseConfirmedAvailableEquivalentPurchase(item, quantity, options)
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
            availabilityReason = "owned",
        }
    end

    local lookup = getPriceLookup(options)
    local chooser = getPriceChooser(options)
    if type(lookup) ~= "function" or type(chooser) ~= "function" then
        return nil, "price_provider_unavailable"
    end

    local itemID = parseItemID(item)
    local directChoice, directReason = chooseItemPrice(item, "purchase", lookup, chooser, options.now)
    local direct = buildQuantityChoice(
        directChoice,
        itemID,
        quantity,
        itemID,
        ceilPositive(quantity),
        false,
        nil
    )
    local directAvailabilityReason
    if direct then
        local confirmed
        confirmed, directAvailabilityReason = classifyPurchaseAvailability(
            direct,
            direct.sourceQuantity
        )
        if confirmed then
            direct.availabilityReason = directAvailabilityReason
        else
            direct = nil
        end
    end

    local equivalent = itemID and ESSENCE_EQUIVALENTS[itemID] or nil
    local alternate
    local alternateReason
    local alternateAvailabilityReason
    if equivalent then
        local alternateChoice
        alternateChoice, alternateReason = chooseItemPrice(
            equivalent.alternateItemID,
            "purchase",
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

        alternate = buildQuantityChoice(
            alternateChoice,
            itemID,
            quantity,
            equivalent.alternateItemID,
            alternateSourceQuantity,
            true,
            equivalent
        )
        if alternate then
            local confirmed
            confirmed, alternateAvailabilityReason = classifyPurchaseAvailability(
                alternate,
                alternate.sourceQuantity
            )
            if confirmed then
                alternate.availabilityReason = alternateAvailabilityReason
            else
                alternate = nil
            end
        end
    end

    if direct and alternate then
        return alternate.totalCost < direct.totalCost and alternate or direct
    end
    if direct then
        return direct
    end
    if alternate then
        return alternate
    end

    return nil,
        directAvailabilityReason
        or alternateAvailabilityReason
        or directReason
        or alternateReason
        or "no_confirmed_purchase_source"
end

local function materialCostCacheKey(recipe, state, options)
    local acquired = state and (state.acquiredOneTime or state.acquiredReusable) or {}
    local parts = {}
    for key, value in pairs(acquired or {}) do
        if value and string.sub(tostring(key), 1, 7) ~= "recipe:" then
            table.insert(parts, tostring(key))
        end
    end
    table.sort(parts)

    return table.concat({
        tostring(recipe and (recipe.spellID or recipe.recipeID or recipe.id) or recipe),
        options and options.requireAvailableNow and "available" or "priced",
        table.concat(parts, "\031"),
    }, "|")
end

local function buildDirectExecutionEconomics(variableMarket, fixedMarket)
    local directGrossCost = nonNegativeNumber(variableMarket) or 0
    return {
        selectedExecutionMethod = "direct",
        directGrossCost = directGrossCost,
        scrollPathAvailable = false,
        scrollGrossCost = nil,
        scrollEffectiveCostPerCraft = nil,
        vellumItemID = nil,
        vellumTier = nil,
        vellumCost = nil,
        vellumPriceType = nil,
        vellumSource = nil,
        scrollOutputItemID = nil,
        resaleEstimate = nil,
        resaleOptimizationValue = 0,
        resaleCredit = 0,
        estimatedSurplus = 0,
        effectiveCostPerCraft = directGrossCost,
        fixedOneTimeMaterialCost = nonNegativeNumber(fixedMarket) or 0,
        resaleConfidence = "none",
        resaleReason = "not_vellum_eligible",
        scrollUnavailableReason = "not_vellum_eligible",
    }
end

local function chooseCheapestCompatibleVellum(spellID, priceLookup, priceChooser, now)
    if type(addonTable.getCompatibleEnchantVellums) ~= "function" then
        return nil, "vellum_metadata_unavailable"
    end

    local vellums, minimumTier = addonTable.getCompatibleEnchantVellums(spellID)
    if type(vellums) ~= "table" or not tonumber(minimumTier) then
        return nil, "no_compatible_vellum"
    end

    local best
    local firstReason
    for index = 1, table.getn(vellums) do
        local vellum = vellums[index]
        local tier = tonumber(vellum and vellum.tier)
        local itemID = vellum and tonumber(vellum.itemID)
        if tier and itemID and tier >= tonumber(minimumTier) then
            local choice, reason = chooseItemPrice(
                itemID,
                "market",
                priceLookup,
                priceChooser,
                now
            )
            local cost = choice and nonNegativeNumber(choice.unitPrice) or nil
            if cost ~= nil then
                if not best
                    or cost < best.cost
                    or (cost == best.cost and tier < best.tier)
                then
                    best = {
                        itemID = itemID,
                        tier = tier,
                        cost = cost,
                        choice = choice,
                    }
                end
            elseif not firstReason then
                firstReason = reason
            end
        end
    end

    return best, firstReason or "compatible_vellum_price_unavailable"
end

local function buildExecutionEconomics(
    recipe,
    variableMarket,
    fixedMarket,
    priceLookup,
    priceChooser,
    options
)
    local economics = buildDirectExecutionEconomics(variableMarket, fixedMarket)
    local spellID = recipe and (recipe.spellID or recipe.recipeID)
    if type(addonTable.getEnchantScrollMetadata) ~= "function" then
        economics.scrollUnavailableReason = "enchant_metadata_unavailable"
        economics.resaleReason = "enchant_metadata_unavailable"
        return economics
    end

    local metadata = addonTable.getEnchantScrollMetadata(spellID)
    if not metadata or not metadata.vellumEligible or not tonumber(metadata.scrollItemID) then
        economics.scrollUnavailableReason = metadata and metadata.classification
            or "not_vellum_eligible"
        economics.resaleReason = economics.scrollUnavailableReason
        return economics
    end

    economics.scrollOutputItemID = tonumber(metadata.scrollItemID)

    local vellum, vellumReason = chooseCheapestCompatibleVellum(
        spellID,
        priceLookup,
        priceChooser,
        options and options.now
    )
    if not vellum then
        economics.scrollUnavailableReason = vellumReason or "compatible_vellum_price_unavailable"
        economics.resaleReason = economics.scrollUnavailableReason
        return economics
    end

    economics.scrollPathAvailable = true
    economics.scrollUnavailableReason = nil
    economics.vellumItemID = vellum.itemID
    economics.vellumTier = vellum.tier
    economics.vellumCost = vellum.cost
    economics.vellumPriceType = vellum.choice and vellum.choice.priceType or nil
    economics.vellumSource = vellum.choice and vellum.choice.source or nil
    economics.scrollGrossCost = economics.directGrossCost + vellum.cost

    local resale
    if type(addonTable.evaluateResaleValue) == "function" then
        local rawResale = priceLookup(economics.scrollOutputItemID, options and options.now)
        resale = addonTable.evaluateResaleValue(rawResale)
    end

    local resaleEstimate = resale and nonNegativeNumber(resale.estimatedResaleValue) or nil
    local optimizationValue = resale and nonNegativeNumber(resale.optimizationCredit) or 0
    optimizationValue = optimizationValue or 0

    economics.resaleEstimate = resaleEstimate
    economics.resaleOptimizationValue = optimizationValue
    economics.resaleConfidence = resale and resale.confidence or "none"
    economics.resaleReason = resale and resale.reason or "resale_evaluator_unavailable"
    economics.resaleCredit = math.min(economics.scrollGrossCost, optimizationValue)
    economics.scrollEffectiveCostPerCraft = math.max(
        0,
        economics.scrollGrossCost - economics.resaleCredit
    )
    economics.estimatedSurplus = math.max(
        0,
        (resaleEstimate or 0) - economics.scrollGrossCost
    )

    if economics.scrollEffectiveCostPerCraft < economics.directGrossCost then
        economics.selectedExecutionMethod = "scroll"
        economics.effectiveCostPerCraft = economics.scrollEffectiveCostPerCraft
    end

    return economics
end

local function applyExecutionEconomics(result, economics, expectedCrafts)
    if type(result) ~= "table" or type(economics) ~= "table" then
        return
    end

    result.selectedExecutionMethod = economics.selectedExecutionMethod
    result.directGrossCost = economics.directGrossCost
    result.scrollPathAvailable = economics.scrollPathAvailable
    result.scrollGrossCost = economics.scrollGrossCost
    result.scrollEffectiveCostPerCraft = economics.scrollEffectiveCostPerCraft
    result.vellumItemID = economics.vellumItemID
    result.vellumTier = economics.vellumTier
    result.vellumCost = economics.vellumCost
    result.vellumPriceType = economics.vellumPriceType
    result.vellumSource = economics.vellumSource
    result.scrollOutputItemID = economics.scrollOutputItemID
    result.resaleEstimate = economics.resaleEstimate
    result.resaleOptimizationValue = economics.resaleOptimizationValue
    result.resaleCredit = economics.resaleCredit
    result.estimatedSurplus = economics.estimatedSurplus
    result.effectiveCostPerCraft = economics.effectiveCostPerCraft
    result.effectiveLevelingCost = economics.effectiveCostPerCraft
    result.fixedOneTimeMaterialCost = economics.fixedOneTimeMaterialCost
    result.resaleConfidence = economics.resaleConfidence
    result.resaleReason = economics.resaleReason
    result.scrollUnavailableReason = economics.scrollUnavailableReason

    local crafts = positiveNumber(expectedCrafts) or 1
    result.expectedEffectiveCostPerSkillUp =
        (nonNegativeNumber(economics.effectiveCostPerCraft) or 0) * crafts
        + (nonNegativeNumber(economics.fixedOneTimeMaterialCost) or 0)
    result.expectedEstimatedSurplusPerSkillUp =
        (nonNegativeNumber(economics.estimatedSurplus) or 0) * crafts

    result.executionEconomics = copyMap(economics)
    result.executionEconomics.expectedEffectiveCostPerSkillUp =
        result.expectedEffectiveCostPerSkillUp
    result.executionEconomics.expectedEstimatedSurplusPerSkillUp =
        result.expectedEstimatedSurplusPerSkillUp
end

function addonTable.calculateRecipeCost(recipe, baseSkill, skillContext, state, options)
    if type(addonTable.performanceIncrement) == "function" then
        addonTable.performanceIncrement("recipe_cost_evaluations", 1)
    end

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
        selectedExecutionMethod = nil,
        directGrossCost = nil,
        scrollPathAvailable = false,
        scrollGrossCost = nil,
        scrollEffectiveCostPerCraft = nil,
        vellumItemID = nil,
        vellumTier = nil,
        vellumCost = nil,
        scrollOutputItemID = nil,
        resaleEstimate = nil,
        resaleOptimizationValue = 0,
        resaleCredit = 0,
        estimatedSurplus = 0,
        effectiveCostPerCraft = nil,
        effectiveLevelingCost = nil,
        fixedOneTimeMaterialCost = nil,
        expectedEffectiveCostPerSkillUp = nil,
        expectedEstimatedSurplusPerSkillUp = nil,
        resaleConfidence = "none",
        resaleReason = nil,
        scrollUnavailableReason = nil,
        executionEconomics = nil,
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
    local materialCache = type(options.materialCostCache) == "table"
        and options.materialCostCache
        or nil
    local materialKey = materialCache and materialCostCacheKey(recipe, state, options) or nil
    local cachedMaterial = materialKey and materialCache[materialKey] or nil
    if materialCache and type(addonTable.performanceCache) == "function" then
        addonTable.performanceCache("material_cost", cachedMaterial ~= nil)
    end

    if cachedMaterial then
        result.reagentCosts = cachedMaterial.reagentCosts
        result.missingPrices = cachedMaterial.missingPrices
        result.stalePrices = cachedMaterial.stalePrices
        result.availabilityIssues = cachedMaterial.availabilityIssues
        for oneTimeIndex = 1, table.getn(cachedMaterial.oneTimeCosts or {}) do
            table.insert(result.oneTimeCosts, cachedMaterial.oneTimeCosts[oneTimeIndex])
        end

        if cachedMaterial.incomplete then
            result.incomplete = true
            result.quality = "incomplete"
            result.unavailableReason = cachedMaterial.unavailableReason or "incomplete_price_data"
            return result
        end

        result.expectedCraftsPerSkillUp = expectedCrafts
        result.materialMarketValuePerCraft = cachedMaterial.marketPerCraft
        result.goldNeededNowPerCraft = cachedMaterial.goldPerCraft
        result.currentPurchaseCostPerCraft = cachedMaterial.currentPurchasePerCraft
        result.expectedMarketCostPerSkillUp =
            cachedMaterial.variableMarket * expectedCrafts + cachedMaterial.fixedMarket
        result.expectedGoldNeededNowPerSkillUp =
            cachedMaterial.variableGold * expectedCrafts + cachedMaterial.fixedGold
        result.expectedCurrentPurchaseCostPerSkillUp =
            cachedMaterial.variableCurrent * expectedCrafts + cachedMaterial.fixedCurrent
        applyExecutionEconomics(
            result,
            cachedMaterial.executionEconomics,
            expectedCrafts
        )
        result.availableNow = cachedMaterial.allPurchasesAvailableNow
        result.availabilityConfidence = result.availableNow and "confirmed" or "unavailable"
        result.available = true
        result.useful = true
        result.quality = cachedMaterial.hasStale and "stale" or "complete"
        return result
    end
    local marketPerCraft = 0
    local goldPerCraft = 0
    local expectedMarket = 0
    local expectedGold = 0
    local currentPurchasePerCraft = 0
    local expectedCurrentPurchase = 0
    local variableMarket = 0
    local variableGold = 0
    local variableCurrent = 0
    local fixedMarket = 0
    local fixedGold = 0
    local fixedCurrent = 0
    local materialOneTimeCosts = {}
    local hasStale = false
    local allPurchasesAvailableNow = true
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
            local owned = getInventoryCount(inventoryRemaining, reagent, state)
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
            local availabilityChoice
            local availabilityIssueReason
            if purchaseQuantity > 0 then
                neededPurchaseChoice, neededPurchaseReason = addonTable.chooseCheapestEquivalentPurchase(
                    item,
                    purchaseQuantity,
                    "purchase",
                    equivalentOptions
                )
                availabilityChoice, availabilityIssueReason = chooseConfirmedAvailableEquivalentPurchase(
                    item,
                    purchaseQuantity,
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
                    availabilityConfirmed = availabilityChoice ~= nil
                    availabilityReason = availabilityChoice
                        and availabilityChoice.availabilityReason
                        or availabilityIssueReason
                        or "no_confirmed_purchase_source"
                    if not availabilityConfirmed then
                        allPurchasesAvailableNow = false
                        table.insert(result.availabilityIssues, {
                            item = item,
                            reason = availabilityReason,
                        })
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
                local currentGoldChoice = options.requireAvailableNow
                    and availabilityChoice
                    or neededPurchaseChoice
                local craftGold = currentGoldChoice and currentGoldChoice.totalCost or 0
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

                if reusable then
                    fixedMarket = fixedMarket + craftMarket
                    fixedGold = fixedGold + craftGold
                    fixedCurrent = fixedCurrent + craftCurrentPurchase
                else
                    variableMarket = variableMarket + craftMarket
                    variableGold = variableGold + craftGold
                    variableCurrent = variableCurrent + craftCurrentPurchase
                end

                if reusable and not alreadyAcquired and reusableKey then
                    local oneTime = {
                        key = reusableKey,
                        kind = "reusable_reagent",
                        item = item,
                        marketCost = craftMarket,
                        goldCost = craftGold,
                    }
                    table.insert(result.oneTimeCosts, oneTime)
                    table.insert(materialOneTimeCosts, oneTime)
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
                    availabilityPriceType = availabilityChoice and availabilityChoice.priceType or nil,
                    availabilityAgeSeconds = availabilityChoice and availabilityChoice.ageSeconds or nil,
                    availabilitySourceItemID = availabilityChoice and availabilityChoice.sourceItemID or nil,
                    availabilitySourceQuantity = availabilityChoice and availabilityChoice.sourceQuantity or 0,
                    availabilityQuantity = availabilityChoice and (
                        availabilityChoice.availableQuantity or availabilityChoice.numAuctions
                    ) or nil,
                })
            end
        end
    end

    local executionEconomics
    if not result.incomplete then
        executionEconomics = buildExecutionEconomics(
            recipe,
            variableMarket,
            fixedMarket,
            priceLookup,
            priceChooser,
            options
        )
    end

    if materialCache and materialKey then
        materialCache[materialKey] = {
            incomplete = result.incomplete,
            unavailableReason = result.incomplete and "incomplete_price_data" or nil,
            reagentCosts = result.reagentCosts,
            missingPrices = result.missingPrices,
            stalePrices = result.stalePrices,
            availabilityIssues = result.availabilityIssues,
            oneTimeCosts = materialOneTimeCosts,
            marketPerCraft = marketPerCraft,
            goldPerCraft = goldPerCraft,
            currentPurchasePerCraft = currentPurchasePerCraft,
            variableMarket = variableMarket,
            variableGold = variableGold,
            variableCurrent = variableCurrent,
            fixedMarket = fixedMarket,
            fixedGold = fixedGold,
            fixedCurrent = fixedCurrent,
            hasStale = hasStale,
            allPurchasesAvailableNow = allPurchasesAvailableNow,
            executionEconomics = executionEconomics,
        }
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
    applyExecutionEconomics(result, executionEconomics, expectedCrafts)
    result.availableNow = allPurchasesAvailableNow
    result.availabilityConfidence = allPurchasesAvailableNow and "confirmed" or "unavailable"
    result.available = true
    result.useful = true
    result.quality = hasStale and "stale" or "complete"

    return result
end
