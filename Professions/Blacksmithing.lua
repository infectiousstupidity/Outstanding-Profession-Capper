addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getBlacksmithingCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 30 then
        shouldCraft = {2660};
    elseif rank >= 30 and rank < 65 then
        shouldCraft = {3320};
    elseif rank >= 65 and rank < 75 then
        shouldCraft = {2661};
    elseif rank >= 75 and rank < 87 then
        shouldCraft = {3326};
    elseif rank >= 87 and rank < 100 then
        shouldCraft = {2666};
    elseif rank >= 100 and rank < 105 then
        shouldCraft = {7818};
    elseif rank >= 105 and rank < 125 then
        shouldCraft = {2668};
    elseif rank >= 125 and rank < 150 then
        shouldCraft = {3337};
    elseif rank >= 150 and rank < 155 then
        shouldCraft = {14379};
    elseif rank >= 155 and rank < 165 then
        shouldCraft = {3506};
    elseif rank >= 165 and rank < 190 then
        shouldCraft = {3501};
    elseif rank >= 190 and rank < 200 then
        shouldCraft = {7223};
    elseif rank >= 200 and rank < 205 then
        shouldCraft = {14380};
    elseif rank >= 205 and rank < 210 then
        shouldCraft = {9920};
    elseif rank >= 210 and rank < 225 then
        shouldCraft = {9928};
    elseif rank >= 225 and rank < 235 then
        shouldCraft = {9937};
    elseif rank >= 235 and rank < 250 then
        shouldCraft = {
            9964,
            9961,
        };
    elseif rank >= 250 and rank < 260 then
        shouldCraft = {16641};
    elseif rank >= 260 and rank < 275 then
        shouldCraft = {16644};
    elseif rank >= 275 and rank < 280 then
        shouldCraft = {20201};
    elseif rank >= 280 and rank < 290 then
        shouldCraft = {16649};
    elseif rank >= 290 and rank < 300 then
        shouldCraft = {
            16652,
            16653,
        };
    elseif rank >= 300 and rank < 305 then
        shouldCraft = {34607};
    elseif rank >= 305 and rank < 315 then
        shouldCraft = {29547};
    elseif rank >= 315 and rank < 320 then
        shouldCraft = {29552};
    elseif rank >= 320 and rank < 325 then
        shouldCraft = {
            29548,
            29553,
        };
    elseif rank >= 325 and rank < 330 then
        shouldCraft = {32284};
    elseif rank >= 330 and rank < 335 then
        shouldCraft = {29550};
    elseif rank >= 335 and rank < 340 then
        shouldCraft = {29568};
    elseif rank >= 340 and rank < 350 then
        shouldCraft = {29728};
    elseif rank >= 350 and rank < 360 then
        shouldCraft = {
            52569,
            52568,
        };
    elseif rank >= 360 and rank < 370 then
        shouldCraft = {
            54550,
            55834,
        };
    elseif rank >= 370 and rank < 375 then
        shouldCraft = {
            52567,
            52571,
        };
    elseif rank >= 375 and rank < 380 then
        shouldCraft = {55835};
    elseif rank >= 380 and rank < 385 then
        shouldCraft = {54918};
    elseif rank >= 385 and rank < 390 then
        shouldCraft = {55202};
    elseif rank >= 390 and rank < 395 then
        shouldCraft = {55204};
    elseif rank >= 395 and rank < 400 then
        shouldCraft = {59436};
    elseif rank >= 400 and rank < 405 then
        shouldCraft = {54949};
    elseif rank >= 405 and rank < 415 then
        shouldCraft = {55206};
    elseif rank >= 415 and rank < 425 then
        shouldCraft = {55656};
    elseif rank >= 425 and rank < 430 then
        shouldCraft = {55839};
    elseif rank >= 430 and rank < 435 then
        shouldCraft = {55311};
    elseif rank >= 435 and rank < 440 then
        shouldCraft = {55303};
    elseif rank >= 440 and rank < 450 then
        shouldCraft = {55303};
    end
    shouldCraftRecipe = {}
    for i, v in pairs(shouldCraft) do
        shouldCraftRecipe[i] = addonTable.BS[tostring(v)]
    end
    return shouldCraft, shouldCraftRecipe
end

print("|cff" .. addonTable.chat_frame_default_color .. '[Profession Capper] loaded Blacksmithing module|r');
