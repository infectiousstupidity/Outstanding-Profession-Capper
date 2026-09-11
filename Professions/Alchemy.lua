local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getAlchemyCurrentSkillLevelRecipeToCraft = function(rank)
    shouldCraft, shouldCraftRecipe = nil, nil
    local targetSkill = nil
    if rank > 0 and rank < 60 then
        targetSkill = 60
        shouldCraft = {2330};
    elseif rank >= 60 and rank < 105 then
        targetSkill = 105
        shouldCraft = {2337};
    elseif rank >= 105 and rank < 110 then
        targetSkill = 110
        shouldCraft = {3171};
    elseif rank >= 110 and rank < 140 then
        targetSkill = 140
        shouldCraft = {3447};
    elseif rank >= 140 and rank < 155 then
        targetSkill = 155
        shouldCraft = {3173};
    elseif rank >= 155 and rank < 175 then
        targetSkill = 175
        shouldCraft = {7181};
    elseif rank >= 175 and rank < 185 then
        targetSkill = 185
        shouldCraft = {3452};
    elseif rank >= 185 and rank < 205 then
        targetSkill = 205
        shouldCraft = {
            11449,
            3450,
        };
    elseif rank >= 205 and rank < 215 then
        targetSkill = 215
        shouldCraft = {11450};
    elseif rank >= 215 and rank < 230 then
        targetSkill = 230
        shouldCraft = {11457};
    elseif rank >= 230 and rank < 231 then
        targetSkill = 231
        shouldCraft = {11459};
    elseif rank >= 231 and rank < 250 then
        targetSkill = 250
        shouldCraft = {11460};
    elseif rank >= 250 and rank < 265 then
        targetSkill = 265
        shouldCraft = {11467};
    elseif rank >= 265 and rank < 285 then
        targetSkill = 285
        shouldCraft = {17553};
    elseif rank >= 285 and rank < 300 then
        targetSkill = 300
        shouldCraft = {17556};
    elseif rank >= 300 and rank < 310 then
        targetSkill = 310
        shouldCraft = {
            33732,
            33740,
        };
    elseif rank >= 310 and rank < 325 then
        targetSkill = 325
        shouldCraft = {28545};
    elseif rank >= 325 and rank < 335 then
        targetSkill = 335
        shouldCraft = {45061};
    elseif rank >= 335 and rank < 340 then
        targetSkill = 340
        shouldCraft = {28551};
    elseif rank >= 340 and rank < 350 then
        targetSkill = 350
        shouldCraft = {28555};
    elseif rank >= 350 and rank < 365 then
        targetSkill = 365
        shouldCraft = {53839};
    elseif rank >= 365 and rank < 375 then
        targetSkill = 375
        shouldCraft = {53842};
    elseif rank >= 375 and rank < 380 then
        targetSkill = 380
        shouldCraft = {53812};
    elseif rank >= 380 and rank < 385 then
        targetSkill = 385
        shouldCraft = {53900};
    elseif rank >= 385 and rank < 395 then
        targetSkill = 395
        shouldCraft = {54218};
    elseif rank >= 395 and rank < 400 then
        targetSkill = 400
        shouldCraft = {53840};
    elseif rank >= 400 and rank < 405 then
        targetSkill = 405
        shouldCraft = {
            54221,
            53840,
        };
    elseif rank >= 405 and rank < 415 then
        targetSkill = 415
        shouldCraft = {
            54221,
            53905,
        };
    elseif rank >= 415 and rank < 425 then
        targetSkill = 425
        shouldCraft = {53837};
    elseif rank >= 425 and rank < 430 then
        targetSkill = 430
        shouldCraft = {60350};
    elseif rank >= 430 and rank < 435 then
        targetSkill = 435
        shouldCraft = {57427};
    elseif rank >= 435 and rank < 440 then
        targetSkill = 440
        shouldCraft = {
            57425,
            53903,
            54213,
            53902,
            53901,
        };
    elseif rank >= 440 and rank < 450 then
        targetSkill = 450
        shouldCraft = {
            53903,
            54213,
            53902,
            53901,
            57425,
        };
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Alchemy[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe, targetSkill;
end

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Alchemy module|r");
