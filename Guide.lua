local addonName, addonTable = ...

addonTable.guides = addonTable.guides or {}

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
    addonTable.guides[name] = steps
    options = options or {}

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
