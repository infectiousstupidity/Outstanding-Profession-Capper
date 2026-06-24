local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getTailoringCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 45 then
        shouldCraft = {2963};
    elseif rank >= 45 and rank < 50 then
        shouldCraft = {8776};
    elseif rank >= 50 and rank < 70 then
        shouldCraft = {3840};
    elseif rank >= 70 and rank < 75 then
        shouldCraft = {2397};
    elseif rank >= 75 and rank < 100 then
        shouldCraft = {2964};
    elseif rank >= 100 and rank < 105 then
        shouldCraft = {
            12046,
            3757,
        };
    elseif rank >= 105 and rank < 110 then
        shouldCraft = {12046};
    elseif rank >= 110 and rank < 125 then
        shouldCraft = {3848};
    elseif rank >= 125 and rank < 145 then
        shouldCraft = {3839};
    elseif rank >= 145 and rank < 160 then
        shouldCraft = {
            8760,
            3848,
        };
    elseif rank >= 160 and rank < 170 then
        shouldCraft = {8762};
    elseif rank >= 170 and rank < 180 then
        shouldCraft = {3871};
    elseif rank >= 180 and rank < 185 then
        shouldCraft = {3865};
    elseif rank >= 185 and rank < 205 then
        shouldCraft = {8791};
    elseif rank >= 205 and rank < 215 then
        shouldCraft = {8799};
    elseif rank >= 215 and rank < 220 then
        shouldCraft = {
            12049,
            8799,
        };
    elseif rank >= 220 and rank < 230 then
        shouldCraft = {12053};
    elseif rank >= 230 and rank < 250 then
        shouldCraft = {12072};
    elseif rank >= 250 and rank < 260 then
        shouldCraft = {18401};
    elseif rank >= 260 and rank < 280 then
        shouldCraft = {18402};
    elseif rank >= 280 and rank < 295 then
        shouldCraft = {18417};
    elseif rank >= 295 and rank < 300 then
        shouldCraft = {18444};
    elseif rank >= 300 and rank < 325 then
        shouldCraft = {26745};
    elseif rank >= 325 and rank < 335 then
        shouldCraft = {26747};
    elseif rank >= 335 and rank < 345 then
        shouldCraft = {26772};
    elseif rank >= 345 and rank < 350 then
        shouldCraft = {26774};
    elseif rank >= 350 and rank < 375 then
        shouldCraft = {55899};
    elseif rank >= 375 and rank < 380 then
        shouldCraft = {55908};
    elseif rank >= 380 and rank < 385 then
        shouldCraft = {55906};
    elseif rank >= 385 and rank < 395 then
        shouldCraft = {55907};
    elseif rank >= 395 and rank < 400 then
        shouldCraft = {55914};
    elseif rank >= 400 and rank < 405 then
        shouldCraft = {55900};
    elseif rank >= 405 and rank < 410 then
        shouldCraft = {55920};
    elseif rank >= 410 and rank < 415 then
        shouldCraft = {55922};
    elseif rank >= 415 and rank < 425 then
        shouldCraft = {
            55924,
            55923,
        };
    elseif rank >= 425 and rank < 450 then
        shouldCraft = {56007};
    end
    shouldCraftRecipe = {}
    for i, v in pairs(shouldCraft) do
        shouldCraftRecipe[i] = addonTable.Tailoring[tostring(v)]
    end
    return shouldCraft, shouldCraftRecipe;
end
