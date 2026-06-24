addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getAlchemyCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 60 then
        shouldCraft = {2330};
    elseif rank >= 60 and rank < 105 then
        shouldCraft = {2337};
    elseif rank >= 105 and rank < 110 then
        shouldCraft = {3171};
    elseif rank >= 110 and rank < 140 then
        shouldCraft = {3447};
    elseif rank >= 140 and rank < 155 then
        shouldCraft = {3173};
    elseif rank >= 155 and rank < 175 then
        shouldCraft = {7181};
    elseif rank >= 175 and rank < 185 then
        shouldCraft = {3452};
    elseif rank >= 185 and rank < 205 then
        shouldCraft = {
            11449,
            3450,
        };
    elseif rank >= 205 and rank < 215 then
        shouldCraft = {11450};
    elseif rank >= 215 and rank < 230 then
        shouldCraft = {11457};
    elseif rank >= 230 and rank < 231 then
        shouldCraft = {11459};
    elseif rank >= 231 and rank < 250 then
        shouldCraft = {11460};
    elseif rank >= 249 and rank < 265 then
        shouldCraft = {11467};
    elseif rank >= 265 and rank < 285 then
        shouldCraft = {17553};
    elseif rank >= 285 and rank < 300 then
        shouldCraft = {17556};
    elseif rank >= 300 and rank < 310 then
        shouldCraft = {
            33732,
            33740,
        };
    elseif rank >= 310 and rank < 325 then
        shouldCraft = {28545};
    elseif rank >= 325 and rank < 335 then
        shouldCraft = {45061};
    elseif rank >= 335 and rank < 340 then
        shouldCraft = {28551};
    elseif rank >= 340 and rank < 350 then
        shouldCraft = {28555};
    elseif rank >= 350 and rank < 365 then
        shouldCraft = {53839};
    elseif rank >= 365 and rank < 375 then
        shouldCraft = {53842};
    elseif rank >= 375 and rank < 380 then
        shouldCraft = {53812};
    elseif rank >= 380 and rank < 385 then
        shouldCraft = {53900};
    elseif rank >= 385 and rank < 390 then
        shouldCraft = {53840};
    elseif rank >= 400 and rank < 405 then
        shouldCraft = {
            54221,
            53840,
        };
    elseif rank >= 405 and rank < 415 then
        shouldCraft = {
            54221,
            53905,
        };
    elseif rank >= 415 and rank < 425 then
        shouldCraft = {53837};
    elseif rank >= 425 and rank < 430 then
        shouldCraft = {60350};
    elseif rank >= 430 and rank < 435 then
        shouldCraft = {57427};
    elseif rank >= 435 and rank < 440 then
        shouldCraft = {
            57425,
            53903,
            54213,
            53902,
            53901,
        };
    elseif rank >= 440 and rank < 450 then
        shouldCraft = {
            53903,
            54213,
            53902,
            53901,
            57425,
        };
    end
    shouldCraftRecipe = {}
    for i, v in pairs(shouldCraft) do
        shouldCraftRecipe[i] = addonTable.Alchemy[tostring(v)]
    end
    return shouldCraft, shouldCraftRecipe
end

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Alchemy module|r");
