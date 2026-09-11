local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getLeatherworkingCurrentSkillLevelRecipeToCraft = function(rank)
    shouldCraft, shouldCraftRecipe = nil, nil
    local targetSkill = nil
    if rank > 0 and rank < 20 then
        targetSkill = 20
        shouldCraft = {
            2881,
            2152,
        };
    elseif rank >= 20 and rank < 30 then
        targetSkill = 30
        shouldCraft = {2152};
    elseif rank >= 30 and rank < 50 then
        targetSkill = 50
        shouldCraft = {9058};
    elseif rank >= 50 and rank < 55 then
        targetSkill = 55
        shouldCraft = {9062};
    elseif rank >= 55 and rank < 85 then
        targetSkill = 85
        shouldCraft = {3756};
    elseif rank >= 85 and rank < 100 then
        targetSkill = 100
        shouldCraft = {3763};
    elseif rank >= 100 and rank < 115 then
        targetSkill = 115
        shouldCraft = {3817};
    elseif rank >= 115 and rank < 130 then
        targetSkill = 130
        shouldCraft = {2167};
    elseif rank >= 130 and rank < 145 then
        targetSkill = 145
        shouldCraft = {
            3766,
            2168,
        };
    elseif rank >= 145 and rank < 150 then
        targetSkill = 150
        shouldCraft = {3764};
    elseif rank >= 150 and rank < 155 then
        targetSkill = 155
        shouldCraft = {23190};
    elseif rank >= 155 and rank < 165 then
        targetSkill = 165
        shouldCraft = {3818};
    elseif rank >= 165 and rank < 180 then
        targetSkill = 180
        shouldCraft = {3780};
    elseif rank >= 180 and rank < 200 then
        targetSkill = 200
        shouldCraft = {10482};
    elseif rank >= 200 and rank < 205 then
        targetSkill = 205
        shouldCraft = {10487};
    elseif rank >= 205 and rank < 235 then
        targetSkill = 235
        shouldCraft = {10507};
    elseif rank >= 235 and rank < 250 then
        targetSkill = 250
        shouldCraft = {10548};
    elseif rank >= 250 and rank < 265 then
        targetSkill = 265
        shouldCraft = {19058};
    elseif rank >= 265 and rank < 290 then
        targetSkill = 290
        shouldCraft = {19052};
    elseif rank >= 290 and rank < 300 then
        targetSkill = 300
        shouldCraft = {19071};
    elseif rank >= 300 and rank < 310 then
        targetSkill = 310
        shouldCraft = {32454};
    elseif rank >= 310 and rank < 325 then
        targetSkill = 325
        shouldCraft = {32456};
    elseif rank >= 325 and rank < 335 then
        targetSkill = 335
        shouldCraft = {32455};
    elseif rank >= 335 and rank < 340 then
        targetSkill = 340
        shouldCraft = {32473};
    elseif rank >= 340 and rank < 350 then
        targetSkill = 350
        shouldCraft = {
            32469,
            32473,
        };
    elseif rank >= 350 and rank < 380 then
        targetSkill = 380
        shouldCraft = {50962};
    elseif rank >= 380 and rank < 390 then
        targetSkill = 390
        shouldCraft = {50948};
    elseif rank >= 390 and rank < 405 then
        targetSkill = 405
        shouldCraft = {50936};
    elseif rank >= 405 and rank < 420 then
        targetSkill = 420
        shouldCraft = {
            60601,
            60611,
        };
    elseif rank >= 420 and rank < 425 then
        targetSkill = 425
        shouldCraft = {60720};
    elseif rank >= 425 and rank < 435 then
        targetSkill = 435
        shouldCraft = {60721};
    elseif rank >= 435 and rank < 440 then
        targetSkill = 440
        shouldCraft = {
            50965,
            50967,
        };
    elseif rank >= 440 and rank < 450 then
        targetSkill = 450
        shouldCraft = {
            60757,
            60756,
            60640,
            60637,
            60761,
            60755,
            60759,
            62176,
            60758,
            60760,
            60754,
            62177,
        };
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Leatherworking[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe, targetSkill;
end
