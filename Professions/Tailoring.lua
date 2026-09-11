local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getTailoringCurrentSkillLevelRecipeToCraft = function(rank)
    shouldCraft, shouldCraftRecipe = nil, nil
    local targetSkill = nil
    if rank > 0 and rank < 45 then
        targetSkill = 45
        shouldCraft = {2963};
    elseif rank >= 45 and rank < 50 then
        targetSkill = 50
        shouldCraft = {8776};
    elseif rank >= 50 and rank < 70 then
        targetSkill = 70
        shouldCraft = {3840};
    elseif rank >= 70 and rank < 75 then
        targetSkill = 75
        shouldCraft = {2397};
    elseif rank >= 75 and rank < 100 then
        targetSkill = 100
        shouldCraft = {2964};
    elseif rank >= 100 and rank < 105 then
        targetSkill = 105
        shouldCraft = {
            12046,
            3757,
        };
    elseif rank >= 105 and rank < 110 then
        targetSkill = 110
        shouldCraft = {12046};
    elseif rank >= 110 and rank < 125 then
        targetSkill = 125
        shouldCraft = {3848};
    elseif rank >= 125 and rank < 145 then
        targetSkill = 145
        shouldCraft = {3839};
    elseif rank >= 145 and rank < 160 then
        targetSkill = 160
        shouldCraft = {
            8760,
            3848,
        };
    elseif rank >= 160 and rank < 170 then
        targetSkill = 170
        shouldCraft = {8762};
    elseif rank >= 170 and rank < 180 then
        targetSkill = 180
        shouldCraft = {3871};
    elseif rank >= 180 and rank < 185 then
        targetSkill = 185
        shouldCraft = {3865};
    elseif rank >= 185 and rank < 205 then
        targetSkill = 205
        shouldCraft = {8791};
    elseif rank >= 205 and rank < 215 then
        targetSkill = 215
        shouldCraft = {8799};
    elseif rank >= 215 and rank < 220 then
        targetSkill = 220
        shouldCraft = {
            12049,
            8799,
        };
    elseif rank >= 220 and rank < 230 then
        targetSkill = 230
        shouldCraft = {12053};
    elseif rank >= 230 and rank < 250 then
        targetSkill = 250
        shouldCraft = {12072};
    elseif rank >= 250 and rank < 260 then
        targetSkill = 260
        shouldCraft = {18401};
    elseif rank >= 260 and rank < 280 then
        targetSkill = 280
        shouldCraft = {18402};
    elseif rank >= 280 and rank < 295 then
        targetSkill = 295
        shouldCraft = {18417};
    elseif rank >= 295 and rank < 300 then
        targetSkill = 300
        shouldCraft = {18444};
    elseif rank >= 300 and rank < 325 then
        targetSkill = 325
        shouldCraft = {26745};
    elseif rank >= 325 and rank < 335 then
        targetSkill = 335
        shouldCraft = {26747};
    elseif rank >= 335 and rank < 345 then
        targetSkill = 345
        shouldCraft = {26772};
    elseif rank >= 345 and rank < 350 then
        targetSkill = 350
        shouldCraft = {26774};
    elseif rank >= 350 and rank < 375 then
        targetSkill = 375
        shouldCraft = {55899};
    elseif rank >= 375 and rank < 380 then
        targetSkill = 380
        shouldCraft = {55908};
    elseif rank >= 380 and rank < 385 then
        targetSkill = 385
        shouldCraft = {55906};
    elseif rank >= 385 and rank < 395 then
        targetSkill = 395
        shouldCraft = {55907};
    elseif rank >= 395 and rank < 400 then
        targetSkill = 400
        shouldCraft = {55914};
    elseif rank >= 400 and rank < 405 then
        targetSkill = 405
        shouldCraft = {55900};
    elseif rank >= 405 and rank < 410 then
        targetSkill = 410
        shouldCraft = {55920};
    elseif rank >= 410 and rank < 415 then
        targetSkill = 415
        shouldCraft = {55922};
    elseif rank >= 415 and rank < 425 then
        targetSkill = 425
        shouldCraft = {
            55924,
            55923,
        };
    elseif rank >= 425 and rank < 450 then
        targetSkill = 450
        shouldCraft = {56007};
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Tailoring[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe, targetSkill;
end
