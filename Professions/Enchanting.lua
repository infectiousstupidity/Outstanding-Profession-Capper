local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getEnchantingCurrentSkillLevelRecipeToCraft = function(rank)
    if rank == 1 then
        shouldCraft = {7421};
    elseif rank >= 2 and rank < 10 then
        shouldCraft = {
            7418,
            7421,
        };
    elseif rank >= 10 and rank < 15 then
        shouldCraft = {7418};
    elseif rank >= 15 and rank < 20 then
        shouldCraft = {
            7418,
            7420,
        };
    elseif rank >= 20 and rank < 50 then
        shouldCraft = {
            7418,
            7420,
            7443,
        };
    elseif rank >= 50 and rank < 60 then
        shouldCraft = {
            7418,
            7420,
            7443,
            7457,
        };
    elseif rank >= 60 and rank < 90 then
        shouldCraft = {
            7418,
            7420,
            7443,
            7457,
            7766,
        };
    elseif rank >= 90 and rank < 100 then
        shouldCraft = {
            7443,
            7766,
            7457,
        };
    elseif rank == 100 then
        shouldCraft = {
            7795,
            7766,
            14807,
        };
    elseif rank >= 101 and rank < 110 then
        shouldCraft = {
            7766,
            14807,
            7795,
        };
    elseif rank >= 110 and rank < 135 then
        shouldCraft = {
            13419,
            13378,
            7766,
            7782,
            7795,
        };
    elseif rank >= 135 and rank < 140 then
        shouldCraft = {
            13419,
            13501,
            7863,
            7795,
        };
    elseif rank >= 140 and rank < 150 then
        shouldCraft = {
            13419,
            13536,
            13501,
            7863,
            7795,
        };
    elseif rank >= 150 and rank < 155 then
        shouldCraft = {
            13419,
            13536,
            13501,
            7863,
        };
    elseif rank == 155 then
        shouldCraft = {
            13628,
            13536,
            13501,
            7863,
        };
    elseif rank >= 156 and rank < 165 then
        shouldCraft = {
            13536,
            7863,
            13628,
        };
    elseif rank >= 165 and rank < 180 then
        shouldCraft = {
            13642,
            13536,
            7863,
            13628,
        };
    elseif rank >= 180 and rank < 184 then
        shouldCraft = {
            13661,
            13642,
            13536,
            7863,
            13628,
        };
    elseif rank >= 185 and rank < 200 then
        shouldCraft = {
            13661,
            13642,
            13640,
        };
    elseif rank == 200 then
        shouldCraft = {
            13702,
            13661,
            13536,
        };
    elseif rank >= 201 and rank < 205 then
        shouldCraft = {
            13661,
            13642,
            13536,
            13702,
        };
    elseif rank >= 205 and rank < 220 then
        shouldCraft = {
            13794,
            13661,
            13642,
        };
    elseif rank >= 220 and rank < 225 then
        shouldCraft = {
            13794,
            13746,
            13642,
            13644,
        };
    elseif rank >= 225 and rank < 235 then
        shouldCraft = {
            13815,
            13794,
            13746,
        };
    elseif rank >= 235 and rank < 240 then
        shouldCraft = {
            13882,
            13858,
        };
    elseif rank >= 240 and rank < 250 then
        shouldCraft = {
            13882,
            63746,
            13858,
        };
    elseif rank >= 250 and rank < 260 then
        shouldCraft = {
            13945,
            13939,
            25127,
        };
    elseif rank >= 260 and rank < 265 then
        shouldCraft = {
            20008,
            13945,
            13939,
        };
    elseif rank >= 265 and rank < 299 then
        shouldCraft = {20017};
    elseif rank >= 299 and rank < 301 then
        shouldCraft = {
            20051,
            32664,
            34002,
            20020,
        };
    elseif rank >= 301 and rank < 310 then
        shouldCraft = {
            34002,
            20028,
            32664,
            20051,
        };
    elseif rank >= 310 and rank < 320 then
        shouldCraft = {27899};
    elseif rank >= 320 and rank < 330 then
        shouldCraft = {
            33996,
            27961,
        };
    elseif rank >= 330 and rank < 335 then
        shouldCraft = {34009};
    elseif rank >= 335 and rank < 340 then
        shouldCraft = {
            44383,
            34009,
        };
    elseif rank >= 340 and rank < 350 then
        shouldCraft = {28019};
    elseif rank == 350 then
        shouldCraft = {
            32665,
            60609,
            27958,
        };
    elseif rank >= 351 and rank < 360 then
        shouldCraft = {
            60609,
            27958,
            32665,
        };
    elseif rank >= 360 and rank < 375 then
        shouldCraft = {60616};
    elseif rank == 375 then
        shouldCraft = {
            32667,
            60616,
        };
    elseif rank >= 376 and rank < 380 then
        shouldCraft = {
            60616,
            32667,
        };
    elseif rank >= 380 and rank < 385 then
        shouldCraft = {44555};
    elseif rank >= 385 and rank < 395 then
        shouldCraft = {60623};
    elseif rank >= 395 and rank < 410 then
        shouldCraft = {
            44500,
            44492,
        };
    elseif rank >= 410 and rank < 415 then
        shouldCraft = {44484};
    elseif rank >= 415 and rank < 420 then
        shouldCraft = {
            44508,
            44488,
        };
    elseif rank >= 420 and rank < 425 then
        shouldCraft = {44509};
    elseif rank == 425 then
        shouldCraft = {
            60619,
            47898,
        };
    elseif rank >= 426 and rank < 440 then
        shouldCraft = {
            47898,
            60619,
        };
    elseif rank >= 440 and rank < 450 then
        shouldCraft = {
            60763,
            47672,
        };
    end
    shouldCraftRecipe = {}
    for i, v in pairs(shouldCraft) do
        shouldCraftRecipe[i] = addonTable.Enchanting[tostring(v)]
    end
    return shouldCraft, shouldCraftRecipe;
end

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Enchanting module|r");
