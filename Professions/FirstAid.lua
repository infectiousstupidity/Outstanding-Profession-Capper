local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getFirstAidCurrentSkillLevelRecipeToCraft = function(rank)
    shouldCraft, shouldCraftRecipe = nil, nil
    local targetSkill = nil
    if rank > 0 and rank < 40 then
        targetSkill = 40
        shouldCraft = {3275};
    elseif rank >= 40 and rank < 80 then
        targetSkill = 80
        shouldCraft = {3276};
    elseif rank >= 80 and rank < 100 then
        targetSkill = 100
        shouldCraft = {
            3277,
            3276,
            7934,
        };
    elseif rank >= 100 and rank < 115 then
        targetSkill = 115
        shouldCraft = {
            3277,
            7934,
        };
    elseif rank >= 115 and rank < 130 then
        targetSkill = 130
        shouldCraft = {3278};
    elseif rank >= 130 and rank < 150 then
        targetSkill = 150
        shouldCraft = {
            3278,
            7935,
        };
    elseif rank >= 150 and rank < 180 then
        targetSkill = 180
        shouldCraft = {
            7928,
            3278,
            7935,
        };
    elseif rank >= 180 and rank < 210 then
        targetSkill = 210
        shouldCraft = {7929};
    elseif rank >= 210 and rank < 240 then
        targetSkill = 240
        shouldCraft = {
            10840,
            7929,
        };
    elseif rank >= 240 and rank < 260 then
        targetSkill = 260
        shouldCraft = {10841};
    elseif rank >= 260 and rank < 290 then
        targetSkill = 290
        shouldCraft = {
            18629,
            10841,
        };
    elseif rank >= 290 and rank < 300 then
        targetSkill = 300
        shouldCraft = {
            18630,
            10841,
        };
    elseif rank >= 300 and rank < 330 then
        targetSkill = 330
        shouldCraft = {
            27032,
            18630,
            23787,
        };
    elseif rank >= 330 and rank < 350 then
        targetSkill = 350
        shouldCraft = {
            27033,
            18630,
            23787,
        };
    elseif rank >= 350 and rank < 375 then
        targetSkill = 375
        shouldCraft = {
            45545,
            27033,
        };
    elseif rank >= 375 and rank < 400 then
        targetSkill = 400
        shouldCraft = {45545};
    elseif rank >= 400 and rank < 450 then
        targetSkill = 450
        shouldCraft = {45546};
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.FirstAid[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe, targetSkill;
end


