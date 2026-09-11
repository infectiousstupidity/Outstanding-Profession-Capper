local addonName, addonTable = ...

local function numberOrZero(value)
    return tonumber(value) or 0
end

local function positiveNumber(value)
    value = tonumber(value)
    if value and value > 0 then
        return value
    end
    return nil
end

local function itemKey(itemID, item)
    if itemID then
        return "id:" .. tostring(itemID)
    end
    if item ~= nil then
        return "item:" .. tostring(item)
    end
    return nil
end

local function reusableKey(reagent)
    if reagent.reusableKey then
        return tostring(reagent.reusableKey)
    end
    return itemKey(reagent.itemID, reagent.item or reagent.itemLink)
end

local function getInventoryCount(inventory, entry)
    if type(inventory) ~= "table" then
        return 0
    end

    local value
    if entry.itemID then
        value = inventory[entry.itemID]
        if value == nil then
            value = inventory[tostring(entry.itemID)]
        end
    end
    if value == nil and entry.item ~= nil then
        value = inventory[entry.item]
    end
    return math.max(0, tonumber(value) or 0)
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

local function choosePurchase(priceResult, chooser)
    if type(priceResult) ~= "table" or not priceResult.available then
        return nil, priceResult and priceResult.unavailableReason or "price_unavailable"
    end

    local auction = select(1, chooser(priceResult, "auction"))
    local vendor = select(1, chooser(priceResult, "vendor"))

    if auction and vendor then
        if vendor.unitPrice <= auction.unitPrice then
            return vendor
        end
        return auction
    end
    if vendor then
        return vendor
    end
    if auction then
        return auction
    end

    return chooser(priceResult, "spend")
end

local function chooseMaterialPrice(item, quantity, purpose, options, priceLookup, priceChooser)
    if type(addonTable.chooseCheapestEquivalentPurchase) == "function" then
        return addonTable.chooseCheapestEquivalentPurchase(item, quantity, purpose, {
            priceLookup = priceLookup,
            unitPriceChooser = priceChooser,
            now = options and options.now,
        })
    end

    local result = priceLookup(item, options and options.now)
    local choice
    local reason
    if purpose == "purchase" then
        choice, reason = choosePurchase(result, priceChooser)
    else
        choice, reason = priceChooser(result, purpose)
    end

    if not choice then
        return nil, reason
    end

    local requested = math.max(0, tonumber(quantity) or 0)
    local sourceQuantity = math.ceil(requested - 0.0000001)
    local copy = {}
    for key, value in pairs(choice) do
        copy[key] = value
    end
    copy.requestedQuantity = requested
    copy.sourceQuantity = sourceQuantity
    copy.sourceItemID = item
    copy.sourceUnitPrice = choice.unitPrice
    copy.totalCost = sourceQuantity * choice.unitPrice
    copy.effectiveUnitPrice = requested > 0 and (copy.totalCost / requested) or 0
    copy.unitPrice = copy.effectiveUnitPrice
    copy.producedQuantity = requested
    copy.excessQuantity = 0
    copy.converted = false
    return copy
end

local function ensureMaterial(materials, reagent)
    local item = reagent.item or reagent.itemLink or reagent.itemID
    local key = itemKey(reagent.itemID, item)
    if not key then
        return nil
    end

    local entry = materials[key]
    if not entry then
        entry = {
            key = key,
            item = item,
            itemID = reagent.itemID,
            totalExpectedQuantity = 0,
            routeProducedQuantity = 0,
            externallyRequiredQuantity = 0,
            quantityCurrentlyOwned = 0,
            ownedAppliedQuantity = 0,
            quantityStillNeeded = 0,
            chosenUnitPrice = nil,
            chosenPriceType = nil,
            chosenPriceSource = nil,
            sourceItemID = nil,
            sourceQuantity = nil,
            sourceUnitPrice = nil,
            producedQuantity = nil,
            excessQuantity = nil,
            directTotalCost = nil,
            alternateTotalCost = nil,
            savings = nil,
            converted = false,
            conversionRatio = nil,
            conversionDirection = nil,
            freshness = nil,
            ageSeconds = nil,
            estimatedPurchaseCost = nil,
            estimatedFullPurchaseCost = nil,
            marketUnitValue = nil,
            estimatedMarketValue = nil,
            missingPrice = false,
            missingPriceReason = nil,
        }
        materials[key] = entry
    end

    return entry
end

local function addRecipeRequirements(materials, recipe, expectedCrafts, seenReusable, acquiredReusable)
    local reagents = recipe.reagents or {}
    for i = 1, table.getn(reagents) do
        local reagent = reagents[i]
        local quantity = positiveNumber(reagent.quantity or reagent.count)
        if quantity then
            local entry = ensureMaterial(materials, reagent)
            if entry then
                local multiplier = expectedCrafts
                if reagent.reusable then
                    local key = reusableKey(reagent)
                    if key and (acquiredReusable[key] or seenReusable[key]) then
                        multiplier = 0
                    else
                        multiplier = 1
                        if key then
                            seenReusable[key] = true
                        end
                    end
                end
                entry.totalExpectedQuantity = entry.totalExpectedQuantity + (quantity * multiplier)
            end
        end
    end
end

local function addRecipeOutputs(materials, recipe, expectedCrafts)
    local outputs = recipe.outputs or {}
    for i = 1, table.getn(outputs) do
        local output = outputs[i]
        local quantity = positiveNumber(output.quantity or output.count)
        if quantity then
            local entry = ensureMaterial(materials, output)
            if entry then
                local multiplier = output.reusable and 1 or expectedCrafts
                entry.routeProducedQuantity = entry.routeProducedQuantity + (quantity * multiplier)
            end
        end
    end
end

local function sortedMaterialList(materials)
    local result = {}
    for _, entry in pairs(materials) do
        table.insert(result, entry)
    end
    table.sort(result, function(left, right)
        if left.itemID and right.itemID and left.itemID ~= right.itemID then
            return left.itemID < right.itemID
        end
        return tostring(left.item or left.key) < tostring(right.item or right.key)
    end)
    return result
end

local function buildCostSegments(actions)
    local segments = {}

    for i = 1, table.getn(actions or {}) do
        local action = actions[i]
        if action.type == "craft" then
            local recipeID = action.recipeID or (action.recipe and (action.recipe.spellID or action.recipe.recipeID or action.recipe.id))
            local last = segments[table.getn(segments)]
            if last and last.type == "craft" and last.recipeID == recipeID and last.skillEnd == action.skillFrom then
                last.skillEnd = action.skillTo
                last.expectedCrafts = last.expectedCrafts + numberOrZero(action.expectedCrafts)
                last.marketCost = last.marketCost + numberOrZero(action.marketCost)
                last.routeGoldEstimate = last.routeGoldEstimate + numberOrZero(action.goldCost)
                last.acquisitionCost = last.acquisitionCost + numberOrZero(action.acquisitionGoldCost)
            else
                table.insert(segments, {
                    type = "craft",
                    recipe = action.recipe,
                    recipeID = recipeID,
                    skillStart = action.skillFrom,
                    skillEnd = action.skillTo,
                    expectedCrafts = numberOrZero(action.expectedCrafts),
                    marketCost = numberOrZero(action.marketCost),
                    routeGoldEstimate = numberOrZero(action.goldCost),
                    acquisitionCost = numberOrZero(action.acquisitionGoldCost),
                })
            end
        elseif action.type == "training" then
            table.insert(segments, {
                type = "training",
                training = action.training,
                skillStart = action.skillFrom,
                skillEnd = action.skillTo,
                oldCap = action.oldCap,
                newCap = action.newCap,
                expectedCrafts = 0,
                marketCost = numberOrZero(action.marketCost),
                routeGoldEstimate = numberOrZero(action.goldCost),
                acquisitionCost = numberOrZero(action.goldCost),
            })
        end
    end

    return segments
end

local function addSource(sourceSet, source)
    if source and source ~= "" then
        sourceSet[source] = true
    end
end

local function setToSortedList(set)
    local result = {}
    for key, value in pairs(set or {}) do
        if value then
            table.insert(result, tostring(key))
        end
    end
    table.sort(result)
    return result
end

local function encodeMap(map)
    local parts = {}
    if type(map) == "table" then
        for key, value in pairs(map) do
            if value ~= nil and value ~= false then
                table.insert(parts, tostring(key) .. "=" .. tostring(value))
            end
        end
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

local function encodeSet(set)
    return table.concat(setToSortedList(set), ",")
end

function addonTable.getRouteRefreshKey(skillContext, state, options)
    skillContext = skillContext or {}
    state = state or {}
    options = options or {}

    local provider = options.priceProviderName
    if provider == nil and type(addonTable.getActivePriceProviderName) == "function" then
        provider = addonTable.getActivePriceProviderName()
    end

    local parts = {
        "profession=" .. tostring(skillContext.professionName or state.professionName or ""),
        "base=" .. tostring(skillContext.baseSkill or state.baseSkill or 0),
        "effective=" .. tostring(skillContext.effectiveSkill or skillContext.currentSkill or 0),
        "modifier=" .. tostring(skillContext.activeSkillModifier or 0),
        "cap=" .. tostring(skillContext.currentCap or state.currentCap or 0),
        "inventory=" .. encodeMap(state.inventory),
        "learned=" .. encodeSet(state.learnedRecipes),
        "reusable=" .. encodeSet(state.acquiredOneTime or state.acquiredReusable),
        "provider=" .. tostring(provider or ""),
        "priceRevision=" .. tostring(options.priceRevision or options.scanUpdatedAt or ""),
        "recipeRevision=" .. tostring(options.recipeRevision or state.recipeRevision or ""),
        "acquisitionRevision=" .. tostring(options.acquisitionRevision or state.acquisitionRevision or ""),
    }

    return table.concat(parts, "|")
end

function addonTable.routeRefreshNeeded(previousKey, skillContext, state, options)
    return previousKey ~= addonTable.getRouteRefreshKey(skillContext, state, options)
end

function addonTable.buildProfessionShoppingPlan(route, state, options)
    state = state or {}
    options = options or {}

    local result = {
        complete = false,
        routeComplete = route and route.complete or false,
        estimatedMarketValueCost = nil,
        estimatedCurrentPurchaseCost = nil,
        estimatedGoldNeededNow = nil,
        acquisitionCost = 0,
        acquisitionMarketCost = 0,
        totalExpectedCrafts = 0,
        segments = {},
        routeSegments = route and route.segments or {},
        materials = {},
        missingPriceCount = 0,
        missingPriceQuantity = 0,
        missingPriceKnownMarketValue = 0,
        stalePriceCount = 0,
        oldestPriceAgeSeconds = nil,
        priceSources = {},
        priceDepthKnown = false,
        auctionCostIsEstimate = true,
        quality = "incomplete",
        reason = nil,
    }

    if type(route) ~= "table" or not route.complete then
        result.reason = route and route.reason or "route_unavailable"
        return result
    end

    local actions = route.actions or {}
    result.segments = buildCostSegments(actions)
    local materials = {}
    local seenReusable = {}
    local acquiredReusable = state.acquiredOneTime or state.acquiredReusable or {}
    local totalMarket = 0
    local acquisitionGold = 0
    local acquisitionMarket = 0

    for i = 1, table.getn(actions) do
        local action = actions[i]
        totalMarket = totalMarket + numberOrZero(action.marketCost)

        if action.type == "craft" then
            local expectedCrafts = numberOrZero(action.expectedCrafts)
            result.totalExpectedCrafts = result.totalExpectedCrafts + expectedCrafts
            addRecipeRequirements(materials, action.recipe or {}, expectedCrafts, seenReusable, acquiredReusable)
            addRecipeOutputs(materials, action.recipe or {}, expectedCrafts)

            local acquisition = numberOrZero(action.acquisitionGoldCost)
            acquisitionGold = acquisitionGold + acquisition
            acquisitionMarket = acquisitionMarket + acquisition
        elseif action.type == "training" then
            acquisitionGold = acquisitionGold + numberOrZero(action.goldCost)
            acquisitionMarket = acquisitionMarket + numberOrZero(action.marketCost)
        end
    end

    local priceLookup = getPriceLookup(options)
    local priceChooser = getPriceChooser(options)
    if type(priceLookup) ~= "function" or type(priceChooser) ~= "function" then
        result.reason = "price_provider_unavailable"
        return result
    end

    local purchaseTotal = 0
    local fullPurchaseTotal = 0
    local sourceSet = {}
    local materialList = sortedMaterialList(materials)

    for i = 1, table.getn(materialList) do
        local entry = materialList[i]
        entry.externallyRequiredQuantity = math.max(0, entry.totalExpectedQuantity - entry.routeProducedQuantity)
        entry.quantityCurrentlyOwned = getInventoryCount(state.inventory, entry)
        entry.ownedAppliedQuantity = math.min(entry.quantityCurrentlyOwned, entry.externallyRequiredQuantity)
        entry.quantityStillNeeded = math.max(0, entry.externallyRequiredQuantity - entry.ownedAppliedQuantity)

        if entry.quantityStillNeeded > 0 then
            local lookupItem = entry.itemID or entry.item
            local marketChoice, marketReason = chooseMaterialPrice(
                lookupItem,
                entry.externallyRequiredQuantity,
                "market",
                options,
                priceLookup,
                priceChooser
            )
            local purchaseChoice, purchaseReason = chooseMaterialPrice(
                lookupItem,
                entry.quantityStillNeeded,
                "purchase",
                options,
                priceLookup,
                priceChooser
            )
            local fullPurchaseChoice = chooseMaterialPrice(
                lookupItem,
                entry.externallyRequiredQuantity,
                "purchase",
                options,
                priceLookup,
                priceChooser
            )

            if marketChoice then
                entry.marketUnitValue = marketChoice.effectiveUnitPrice or marketChoice.unitPrice
                entry.estimatedMarketValue = marketChoice.totalCost
            end

            if not purchaseChoice then
                entry.missingPrice = true
                entry.missingPriceReason = purchaseReason or marketReason or "price_unavailable"
                result.missingPriceCount = result.missingPriceCount + 1
                result.missingPriceQuantity = result.missingPriceQuantity + entry.quantityStillNeeded
                if marketChoice then
                    result.missingPriceKnownMarketValue = result.missingPriceKnownMarketValue
                        + (entry.quantityStillNeeded * marketChoice.unitPrice)
                end
            else
                entry.chosenUnitPrice = purchaseChoice.effectiveUnitPrice or purchaseChoice.unitPrice
                entry.sourceUnitPrice = purchaseChoice.sourceUnitPrice
                entry.chosenPriceType = purchaseChoice.priceType
                entry.chosenPriceSource = purchaseChoice.source
                entry.sourceItemID = purchaseChoice.sourceItemID
                entry.sourceQuantity = purchaseChoice.sourceQuantity
                entry.producedQuantity = purchaseChoice.producedQuantity
                entry.excessQuantity = purchaseChoice.excessQuantity
                entry.directTotalCost = purchaseChoice.directTotalCost
                entry.alternateTotalCost = purchaseChoice.alternateTotalCost
                entry.savings = purchaseChoice.savings
                entry.converted = purchaseChoice.converted and true or false
                entry.conversionRatio = purchaseChoice.conversionRatio
                entry.conversionDirection = purchaseChoice.conversionDirection
                entry.freshness = purchaseChoice.freshness
                entry.ageSeconds = purchaseChoice.ageSeconds
                entry.estimatedPurchaseCost = purchaseChoice.totalCost
                entry.estimatedFullPurchaseCost = fullPurchaseChoice
                    and fullPurchaseChoice.totalCost
                    or purchaseChoice.totalCost
                purchaseTotal = purchaseTotal + entry.estimatedPurchaseCost
                fullPurchaseTotal = fullPurchaseTotal + entry.estimatedFullPurchaseCost
                addSource(sourceSet, purchaseChoice.source)

                if purchaseChoice.isStale or purchaseChoice.isTooOld
                    or purchaseChoice.isSuspicious
                    or (marketChoice and marketChoice.isSuspicious)
                then
                    result.stalePriceCount = result.stalePriceCount + 1
                end

                if purchaseChoice.ageSeconds
                    and (not result.oldestPriceAgeSeconds or purchaseChoice.ageSeconds > result.oldestPriceAgeSeconds)
                then
                    result.oldestPriceAgeSeconds = purchaseChoice.ageSeconds
                end
            end
        else
            entry.estimatedPurchaseCost = 0
            entry.estimatedFullPurchaseCost = 0
        end
    end

    result.materials = materialList
    result.priceSources = setToSortedList(sourceSet)
    result.estimatedMarketValueCost = totalMarket
    result.acquisitionCost = acquisitionGold
    result.acquisitionMarketCost = acquisitionMarket

    if result.missingPriceCount > 0 then
        result.reason = "incomplete_price_data"
        result.quality = "incomplete"
        return result
    end

    result.estimatedCurrentPurchaseCost = fullPurchaseTotal + acquisitionGold
    result.estimatedGoldNeededNow = purchaseTotal + acquisitionGold
    result.complete = true
    result.quality = result.stalePriceCount > 0 and "stale" or "complete"
    return result
end
