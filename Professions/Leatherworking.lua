local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getLeatherworkingCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 20 then
        shouldCraft = {
            2881,
            2152,
        };
    elseif rank >= 20 and rank < 30 then
        shouldCraft = {2152};
    elseif rank >= 30 and rank < 50 then
        shouldCraft = {9058};
    elseif rank >= 50 and rank < 55 then
        shouldCraft = {9062};
    elseif rank >= 55 and rank < 85 then
        shouldCraft = {3756};
    elseif rank >= 85 and rank < 100 then
        shouldCraft = {3763};
    elseif rank >= 100 and rank < 115 then
        shouldCraft = {3817};
    elseif rank >= 115 and rank < 130 then
        shouldCraft = {2167};
    elseif rank >= 130 and rank < 145 then
        shouldCraft = {
            3766,
            2168,
        };
    elseif rank >= 145 and rank < 150 then
        shouldCraft = {3764};
    elseif rank >= 150 and rank < 155 then
        shouldCraft = {23190};
    elseif rank >= 155 and rank < 165 then
        shouldCraft = {3818};
    elseif rank >= 165 and rank < 180 then
        shouldCraft = {3780};
    elseif rank >= 180 and rank < 200 then
        shouldCraft = {10482};
    elseif rank >= 200 and rank < 205 then
        shouldCraft = {10487};
    elseif rank >= 205 and rank < 235 then
        shouldCraft = {10507};
    elseif rank >= 235 and rank < 250 then
        shouldCraft = {10548};
    elseif rank >= 250 and rank < 265 then
        shouldCraft = {19058};
    elseif rank >= 265 and rank < 290 then
        shouldCraft = {19052};
    elseif rank >= 290 and rank < 300 then
        shouldCraft = {19071};
    elseif rank >= 300 and rank < 310 then
        shouldCraft = {32454};
    elseif rank >= 310 and rank < 325 then
        shouldCraft = {32456};
    elseif rank >= 325 and rank < 335 then
        shouldCraft = {32455};
    elseif rank >= 335 and rank < 340 then
        shouldCraft = {32473};
    elseif rank >= 340 and rank < 350 then
        shouldCraft = {
            32469,
            32473,
        };
    elseif rank >= 350 and rank < 380 then
        shouldCraft = {50962};
    elseif rank >= 380 and rank < 390 then
        shouldCraft = {50948};
    elseif rank >= 390 and rank < 405 then
        shouldCraft = {50936};
    elseif rank >= 405 and rank < 420 then
        shouldCraft = {
            60601,
            60611,
        };
    elseif rank >= 420 and rank < 425 then
        shouldCraft = {60720};
    elseif rank >= 425 and rank < 435 then
        shouldCraft = {60721};
    elseif rank >= 435 and rank < 440 then
        shouldCraft = {
            50965,
            50967,
        };
    elseif rank >= 440 and rank < 450 then
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
    return shouldCraft, shouldCraftRecipe;
end
