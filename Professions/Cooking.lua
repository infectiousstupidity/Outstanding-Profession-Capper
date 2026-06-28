addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getCookingCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 20 then
        shouldCraft = {
            37836,
            8604,
            2538,
            2540,
            7751,
            15935,
            33276,
            7752,
            33277,
        };
    elseif rank >= 20 and rank < 40 then
        shouldCraft = {
            37836,
            6413,
            8604,
            2538,
            2540,
            7751,
            15935,
            33276,
            7752,
            33277,
        };
    elseif rank >= 40 and rank < 45 then
        shouldCraft = {
            6413,
            8604,
            2538,
            2540,
            7751,
            15935,
            33276,
            7752,
            33277,
        };
    elseif rank >= 45 and rank < 50 then
        shouldCraft = {
            8607,
            6413,
            2539,
        };
    elseif rank >= 50 and rank < 70 then
        shouldCraft = {
            8607,
            33278,
            6413,
            2541,
            6499,
            2542,
            7754,
            7753,
            7827,
            6416,
            2539,
        };
    elseif rank >= 70 and rank < 80 then
        shouldCraft = {
            8607,
            6413,
            2541,
            6499,
            2542,
            7754,
            7753,
            7827,
            6416,
        };
    elseif rank >= 80 and rank < 110 then
        shouldCraft = {
            25704,
            2544,
            2541,
            6499,
            2542,
            7754,
            7753,
            7827,
            6416,
        };
    elseif rank >= 110 and rank < 130 then
        shouldCraft = {
            3397,
            3377,
            25704,
            2544,
            2541,
            6499,
            2542,
            7754,
            7753,
            7827,
            6416,
        };
    elseif rank >= 130 and rank < 140 then
        shouldCraft = {
            3376,
            3398,
            15853,
            6500,
            3373,
            3397,
            3377,
            25704,
            2544,
            2541,
            6499,
            2542,
            7754,
            7753,
            7827,
            6416,
        };
    elseif rank >= 140 and rank < 175 then
        shouldCraft = {
            3376,
            3398,
            15853,
            6500,
            3373,
            3397,
            3377,
        };
    elseif rank >= 175 and rank < 225 then
        shouldCraft = {
            15855,
            4094,
            25954,
            7828,
            15863,
            7213,
            20916,
            3400,
            15861,
            15865,
        };
    elseif rank >= 225 and rank < 250 then
        shouldCraft = {
            64054,
            15933,
            22480,
            15915,
            18239,
            18241,
            18238,
        };
    elseif rank >= 250 and rank < 285 then
        shouldCraft = {
            46688,
            46684,
            18244,
        };
    elseif rank >= 285 and rank < 300 then
        shouldCraft = {
            24801,
            18247,
            18246,
            18245,
            22761,
        };
    elseif rank >= 300 and rank < 325 then
        shouldCraft = {
            33284,
            33279,
            33290,
            33291,
            43761,
            43772,
        };
    elseif rank >= 325 and rank < 335 then
        shouldCraft = {
            33289,
            33287,
            33288,
        };
    elseif rank >= 335 and rank < 350 then
        shouldCraft = {
            33289,
            33287,
            33288,
            38867,
            38868,
        };
    elseif rank >= 350 and rank < 375 then
        shouldCraft = {
            45569,
            45549,
            45565,
            45564,
            45566,
            45563,
            45553,
            45551,
            45552,
            45550,
            57421,
            45560,
            45561,
            45562,
            58065,
            33296,
            42302,
            42305,
        };
    elseif rank >= 375 and rank < 400 then
        shouldCraft = {
            53056,
            45569,
            45549,
            45565,
            45564,
            45566,
            45563,
            45553,
            45551,
            45552,
            45550,
            58065,
        };
    elseif rank >= 400 and rank < 425 then
        shouldCraft = {
            57441,
            57442,
            57438,
            45558,
            57439,
            45568,
            57436,
            45570,
            45567,
            57440,
            45571,
            57433,
            57443,
        };
    elseif rank >= 425 and rank < 450 then
        shouldCraft = {
            58527,
            58528,
            57441,
            57442,
            57438,
            45558,
            57439,
            45568,
            57436,
            45570,
            45567,
            57440,
            45571,
            57433,
            57443,
        };
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Alchemy[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe
end

print("|cff" .. addonTable.chat_frame_default_color .. '[Profession Capper] loaded Cooking module|r');
