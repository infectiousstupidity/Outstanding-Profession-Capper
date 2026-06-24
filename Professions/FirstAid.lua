addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getFirstAidCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 40 then
        shouldCraft = {3275};
    elseif rank >= 40 and rank < 80 then
        shouldCraft = {3276};
    elseif rank >= 80 and rank < 100 then
        shouldCraft = {
            3277,
            3276,
            7934,
        };
    elseif rank >= 100 and rank < 115 then
        shouldCraft = {
            3277,
            7934,
        };
    elseif rank >= 115 and rank < 130 then
        shouldCraft = {3278};
    elseif rank >= 130 and rank < 150 then
        shouldCraft = {
            3278,
            7935,
        };
    elseif rank >= 150 and rank < 180 then
        shouldCraft = {
            7928,
            3278,
            7935,
        };
    elseif rank >= 180 and rank < 210 then
        shouldCraft = {7929};
    elseif rank >= 210 and rank < 240 then
        shouldCraft = {
            10840,
            7929,
        };
    elseif rank >= 240 and rank < 260 then
        shouldCraft = {10841};
    elseif rank >= 260 and rank < 290 then
        shouldCraft = {
            18629,
            10841,
        };
    elseif rank >= 290 and rank < 300 then
        shouldCraft = {
            18630,
            10841,
        };
    elseif rank >= 300 and rank < 330 then
        shouldCraft = {
            27032,
            18630,
            23787,
        };
    elseif rank >= 330 and rank < 350 then
        shouldCraft = {
            27033,
            18630,
            23787,
        };
    elseif rank >= 350 and rank < 375 then
        shouldCraft = {
            45545,
            27033,
        };
    elseif rank >= 375 and rank < 400 then
        shouldCraft = {45545};
    elseif rank >= 400 and rank < 450 then
        shouldCraft = {45546};
    end
    addonTable.sortRecipesByNumAvailable(shouldCraft)
    shouldCraftRecipe = {}
    for i, v in pairs(shouldCraft) do
        shouldCraftRecipe[i] = addonTable.FirstAid[tostring(v)]
    end
    return shouldCraft, shouldCraftRecipe
end


