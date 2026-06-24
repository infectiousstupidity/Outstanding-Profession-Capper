local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getJewelcraftingCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 30 then
        shouldCraft = {25255};
    elseif rank >= 30 and rank < 50 then
        shouldCraft = {
            32179,
            32178,
        };
    elseif rank >= 50 and rank < 80 then
        shouldCraft = {
            25278,
            32179,
            32178,
        };
    elseif rank >= 80 and rank < 100 then
        shouldCraft = {
            25317,
            25287,
            25284,
        };
    elseif rank >= 100 and rank < 110 then
        shouldCraft = {
            25318,
            25317,
            25287,
            25284,
        };
    elseif rank >= 110 and rank < 120 then
        shouldCraft = {
            32807,
            25318,
            25317,
        };
    elseif rank >= 120 and rank < 150 then
        shouldCraft = {
            25610,
            32807,
            25318,
        };
    elseif rank >= 150 and rank < 180 then
        shouldCraft = {25615};
    elseif rank >= 180 and rank < 200 then
        shouldCraft = {25620};
    elseif rank >= 200 and rank < 220 then
        shouldCraft = {25621};
    elseif rank >= 220 and rank < 225 then
        shouldCraft = {
            26876,
            25621,
        };
    elseif rank >= 225 and rank < 245 then
        shouldCraft = {26880};
    elseif rank >= 245 and rank < 260 then
        shouldCraft = {26883};
    elseif rank >= 260 and rank < 280 then
        shouldCraft = {26902};
    elseif rank >= 280 and rank < 290 then
        shouldCraft = {
            34960,
            26908,
            26907,
        };
    elseif rank >= 290 and rank < 300 then
        shouldCraft = {
            34961,
            34960,
            26908,
            26907,
        };
    elseif rank >= 300 and rank < 320 then
        shouldCraft = {
            28903,
            28938,
            28950,
            28916,
            28910,
            28925,
        };
    elseif rank >= 320 and rank < 325 then
        shouldCraft = {
            28905,
            28917,
            28953,
        };
    elseif rank >= 325 and rank < 340 then
        shouldCraft = {
            38068,
            28948,
            28936,
            28924,
        };
    elseif rank >= 340 and rank < 350 then
        shouldCraft = {
            31052,
            28948,
            28936,
            28924,
        };
    elseif rank >= 350 and rank < 395 then
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
        shouldCraft = {
            56193,
            58142,
            58141,
            56194,
        };
    elseif rank >= 400 and rank < 420 then
        shouldCraft = {
            58145,
            58146,
        };
    elseif rank >= 420 and rank < 425 then
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
    shouldCraftRecipe = {}
    for i, v in pairs(shouldCraft) do
        shouldCraftRecipe[i] = addonTable.Jewelcrafting[tostring(v)]
    end
    return shouldCraft, shouldCraftRecipe;
end
