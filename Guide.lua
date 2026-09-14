local addonName, addonTable = ...

addonTable.guides = addonTable.guides or {}
addonTable.guideDefinitions = addonTable.guideDefinitions or {}

local function copyRelevantRecipes(recipes, recipeIsRelevant, rank, step)
    local copy = {}
    for i = 1, table.getn(recipes) do
        local spellID = recipes[i]
        local include = true

        if recipeIsRelevant then
            local ok, relevant = pcall(recipeIsRelevant, spellID, rank, step)
            if ok and relevant == false then
                include = false
            end
        end

        if include then
            table.insert(copy, spellID)
        end
    end
    return copy
end

function addonTable.registerProfessionGuide(name, steps, recipeNames, options)
    options = options or {}
    addonTable.guides[name] = steps
    addonTable.guideDefinitions[name] = {
        steps = steps,
        recipeNames = recipeNames,
        options = options,
    }

    addonTable["get" .. name .. "CurrentSkillLevelRecipeToCraft"] = function(rank)
        for i = 1, table.getn(steps) do
            local step = steps[i]
            if rank >= step.minSkill and rank < step.targetSkill then
                local recipes = copyRelevantRecipes(step.recipes, options.recipeIsRelevant, rank, step)

                if table.getn(recipes) == 0 and step.fallbackRecipes then
                    recipes = copyRelevantRecipes(step.fallbackRecipes, options.recipeIsRelevant, rank, step)
                end

                if table.getn(recipes) == 0 then
                    return nil, nil, nil
                end

                if addonTable.sortRecipesByNumAvailable then
                    addonTable.sortRecipesByNumAvailable(recipes)
                end

                local names = {}
                for recipeIndex = 1, table.getn(recipes) do
                    local spellID = recipes[recipeIndex]
                    names[recipeIndex] = recipeNames and recipeNames[tostring(spellID)] or nil
                end

                return recipes, names, step.targetSkill
            end
        end

        return nil, nil, nil
    end
end

function addonTable.getProfessionGuide(name)
    return addonTable.guides[name]
end

local function staticRecipeName(recipeNames, spellID)
    local name = recipeNames and recipeNames[tostring(spellID)] or nil
    if name and name ~= "" then
        return name
    end

    if type(GetSpellInfo) == "function" then
        local ok, spellName = pcall(GetSpellInfo, spellID)
        if ok and spellName and spellName ~= "" then
            return spellName
        end
    end

    if type(addonTable.getRecipeCatalogRecord) == "function" then
        local record = addonTable.getRecipeCatalogRecord(spellID)
        if record and record.name and record.name ~= "" then
            return record.name
        end
    end

    return "Spell " .. tostring(spellID)
end

local function staticRecipeRecord(spellID, name)
    if type(addonTable.getRecipeCatalogRecord) == "function" then
        local record = addonTable.getRecipeCatalogRecord(spellID)
        if record then
            return record
        end
    end
    return {
        spellID = spellID,
        name = name,
    }
end

local function copyStaticSegment(segment, skillStart, skillEnd)
    return {
        type = "craft",
        skillStart = skillStart,
        skillEnd = skillEnd,
        recipeID = segment.recipeID,
        recipe = segment.recipe,
        recipeIDs = segment.recipeIDs,
        recipeNames = segment.recipeNames,
        alternatives = segment.alternatives,
    }
end

function addonTable.buildStaticProfessionRoute(name, startSkill, targetSkill, skillContext, playerLevel)
    local definition = addonTable.guideDefinitions[name]
    local start = math.max(0, tonumber(startSkill) or 0)
    local target = math.min(450, math.max(start, tonumber(targetSkill) or 450))
    local result = {
        complete = false,
        professionName = name,
        startSkill = start,
        targetSkill = target,
        segments = {},
        reason = nil,
    }

    if not definition or type(definition.steps) ~= "table" then
        result.reason = "guide_unavailable"
        return result
    end

    if target <= start then
        result.complete = true
        return result
    end

    local craftSegments = {}
    local coveredTo = start
    local steps = definition.steps
    local options = definition.options or {}
    local recipeNames = definition.recipeNames

    for i = 1, table.getn(steps) do
        local step = steps[i]
        local segmentStart = math.max(start, tonumber(step.minSkill) or 0)
        local segmentEnd = math.min(target, tonumber(step.targetSkill) or 0)

        if segmentEnd > segmentStart then
            local recipes = copyRelevantRecipes(
                step.recipes or {},
                options.recipeIsRelevant,
                segmentStart,
                step
            )
            if table.getn(recipes) == 0 and step.fallbackRecipes then
                recipes = copyRelevantRecipes(
                    step.fallbackRecipes,
                    options.recipeIsRelevant,
                    segmentStart,
                    step
                )
            end

            if table.getn(recipes) == 0 then
                result.reason = "guide_step_has_no_recipe"
                return result
            end

            local names = {}
            for recipeIndex = 1, table.getn(recipes) do
                names[recipeIndex] = staticRecipeName(recipeNames, recipes[recipeIndex])
            end

            local primaryID = recipes[1]
            table.insert(craftSegments, {
                skillStart = segmentStart,
                skillEnd = segmentEnd,
                recipeID = primaryID,
                recipe = staticRecipeRecord(primaryID, names[1]),
                recipeIDs = recipes,
                recipeNames = names,
                alternatives = math.max(0, table.getn(recipes) - 1),
            })
            if segmentStart <= coveredTo and segmentEnd > coveredTo then
                coveredTo = segmentEnd
            end
        end
    end

    local training = {}
    if type(addonTable.getProfessionTrainingSteps) == "function" then
        local currentCap = skillContext and skillContext.currentCap or 75
        local stepsForRanks = addonTable.getProfessionTrainingSteps(
            name,
            currentCap,
            playerLevel
        )
        local previousCap = tonumber(currentCap) or 75
        for i = 1, table.getn(stepsForRanks or {}) do
            local action = stepsForRanks[i]
            local atSkill = tonumber(action.atSkill) or 0
            if atSkill < target then
                local copy = {}
                for key, value in pairs(action) do
                    copy[key] = value
                end
                copy.oldCap = previousCap
                copy.routeSkill = math.max(start, atSkill)
                table.insert(training, copy)
            end
            if tonumber(action.newCap) then
                previousCap = tonumber(action.newCap)
            end
        end
        table.sort(training, function(left, right)
            if left.routeSkill ~= right.routeSkill then
                return left.routeSkill < right.routeSkill
            end
            return (tonumber(left.newCap) or 0) < (tonumber(right.newCap) or 0)
        end)
    end

    local insertedTraining = {}
    for segmentIndex = 1, table.getn(craftSegments) do
        local segment = craftSegments[segmentIndex]
        local cursor = segment.skillStart

        for trainingIndex = 1, table.getn(training) do
            local action = training[trainingIndex]
            local point = action.routeSkill
            if not insertedTraining[trainingIndex]
                and point >= cursor
                and point < segment.skillEnd
            then
                if point > cursor then
                    table.insert(result.segments, copyStaticSegment(segment, cursor, point))
                end

                table.insert(result.segments, {
                    type = "training",
                    training = action,
                    skillStart = point,
                    skillEnd = point,
                    oldCap = action.oldCap or action.currentCap,
                    newCap = action.newCap or action.targetCap,
                    requiredLevel = action.requiredLevel,
                    available = action.status ~= "unavailable" and action.available ~= false,
                })
                insertedTraining[trainingIndex] = true
                cursor = point
            end
        end

        if cursor < segment.skillEnd then
            table.insert(result.segments, copyStaticSegment(segment, cursor, segment.skillEnd))
        end
    end

    result.complete = coveredTo >= target
    if not result.complete then
        result.reason = "guide_incomplete"
    end
    return result
end

