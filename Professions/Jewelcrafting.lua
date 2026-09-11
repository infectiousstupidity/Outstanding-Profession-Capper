local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getJewelcraftingCurrentSkillLevelRecipeToCraft = function(rank)
    shouldCraft, shouldCraftRecipe = nil, nil
    local targetSkill = nil
    if rank > 0 and rank < 30 then
        targetSkill = 30
        shouldCraft = {25255};
    elseif rank >= 30 and rank < 50 then
        targetSkill = 50
        shouldCraft = {
            32179,
            32178,
        };
    elseif rank >= 50 and rank < 80 then
        targetSkill = 80
        shouldCraft = {
            25278,
            32179,
            32178,
        };
    elseif rank >= 80 and rank < 100 then
        targetSkill = 100
        shouldCraft = {
            25317,
            25287,
            25284,
        };
    elseif rank >= 100 and rank < 110 then
        targetSkill = 110
        shouldCraft = {
            25318,
            25317,
            25287,
            25284,
        };
    elseif rank >= 110 and rank < 120 then
        targetSkill = 120
        shouldCraft = {
            32807,
            25318,
            25317,
        };
    elseif rank >= 120 and rank < 150 then
        targetSkill = 150
        shouldCraft = {
            25610,
            32807,
            25318,
        };
    elseif rank >= 150 and rank < 180 then
        targetSkill = 180
        shouldCraft = {25615};
    elseif rank >= 180 and rank < 200 then
        targetSkill = 200
        shouldCraft = {25620};
    elseif rank >= 200 and rank < 220 then
        targetSkill = 220
        shouldCraft = {25621};
    elseif rank >= 220 and rank < 225 then
        targetSkill = 225
        shouldCraft = {
            26876,
            25621,
        };
    elseif rank >= 225 and rank < 245 then
        targetSkill = 245
        shouldCraft = {26880};
    elseif rank >= 245 and rank < 260 then
        targetSkill = 260
        shouldCraft = {26883};
    elseif rank >= 260 and rank < 280 then
        targetSkill = 280
        shouldCraft = {26902};
    elseif rank >= 280 and rank < 290 then
        targetSkill = 290
        shouldCraft = {
            34960,
            26908,
            26907,
        };
    elseif rank >= 290 and rank < 300 then
        targetSkill = 300
        shouldCraft = {
            34961,
            34960,
            26908,
            26907,
        };
    elseif rank >= 300 and rank < 320 then
        targetSkill = 320
        shouldCraft = {
            28903,
            28938,
            28950,
            28916,
            28910,
            28925,
        };
    elseif rank >= 320 and rank < 325 then
        targetSkill = 325
        shouldCraft = {
            28905,
            28917,
            28953,
        };
    elseif rank >= 325 and rank < 340 then
        targetSkill = 340
        shouldCraft = {
            38068,
            28948,
            28936,
            28924,
        };
    elseif rank >= 340 and rank < 350 then
        targetSkill = 350
        shouldCraft = {
            31052,
            28948,
            28936,
            28924,
        };
    elseif rank >= 350 and rank < 395 then
        targetSkill = 395
        shouldCraft = {
            53831,
            53835,
            53832,
            53934,
            53926,
            53892,
            53866,
            53852,
        };
    elseif rank >= 395 and rank < 400 then
        targetSkill = 400
        shouldCraft = {
            56193,
            58142,
            58141,
            56194,
        };
    elseif rank >= 400 and rank < 420 then
        targetSkill = 420
        shouldCraft = {
            58145,
            58146,
        };
    elseif rank >= 420 and rank < 425 then
        targetSkill = 425
        shouldCraft = {
            54007,
            53969,
            53947,
            53956,
            53989,
            53953,
            56531,
        };
    elseif rank >= 425 and rank < 450 then
        targetSkill = 450
        shouldCraft = {
            55394, 
            55386,
            55389,
            55390,
            55384,
            55392,
            55393,
            55387,
            55388,
            55407,
            55395,
            55402,
            55399,
            55401,
            55405,
            55397,
            55398,
            55396,
            55404,
            55400,
            55403,
        };
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Jewelcrafting[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe, targetSkill;
end
