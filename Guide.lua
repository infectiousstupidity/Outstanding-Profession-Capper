local addonName, addonTable = ...

addonTable.guides = addonTable.guides or {}

local function copyRecipes(recipes)
    local copy = {}
    for i = 1, table.getn(recipes) do
        copy[i] = recipes[i]
    end
    return copy
end

function addonTable.registerProfessionGuide(name, steps, recipeNames)
    addonTable.guides[name] = steps

    addonTable["get" .. name .. "CurrentSkillLevelRecipeToCraft"] = function(rank)
        for i = 1, table.getn(steps) do
            local step = steps[i]
            if rank >= step.minSkill and rank < step.targetSkill then
                local recipes = copyRecipes(step.recipes)
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
