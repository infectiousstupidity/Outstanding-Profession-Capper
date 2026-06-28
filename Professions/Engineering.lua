addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getEngineeringCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 21 then
        shouldCraft = {3918}; -- Rough Blasting Powder
    elseif rank >= 21 and rank < 31 then
        shouldCraft = {
            3919,
            3918,
        };
    elseif rank >= 31 and rank < 50 then
        shouldCraft = {
            3922,
            3919,
        };
    elseif rank == 50 then
        shouldCraft = {
            7430,
            3924,
        };
    elseif rank >= 51 and rank < 75 then
        shouldCraft = {
            3924,
            7430,
        };
    elseif rank >= 75 and rank < 85 then
        shouldCraft = {
            3929,
            3924,
            7430,
        };
    elseif rank >= 85 and rank < 90 then
        shouldCraft = {
            3931,
            3929,
            3924,
        };
    elseif rank >= 90 and rank < 110 then
        shouldCraft = {
            3973,
            3926,
        };
    elseif rank >= 110 and rank < 125 then
        shouldCraft = {
            3938,
            3937,
            3973,
        };
    elseif rank >= 125 and rank < 135 then
        shouldCraft = {3945};
    elseif rank >= 135 and rank < 145 then
        shouldCraft = {
            3942,
            3945,
        };
    elseif rank >= 145 and rank < 150 then
        shouldCraft = {3942};
    elseif rank >= 150 and rank < 155 then
        shouldCraft = {3953};
    elseif rank >= 155 and rank < 175 then
        shouldCraft = {
            3955,
            12584,
            3958,
        };
    elseif rank == 175 then
        shouldCraft = {
            12590,
            12585,
        };
    elseif rank >= 176 and rank < 185 then
        shouldCraft = {
            12585,
            12590,
        };
    elseif rank >= 185 and rank < 190 then
        shouldCraft = {
            3961,
        };
    elseif rank >= 190 and rank < 195 then
        shouldCraft = {
            3962,
        };
    elseif rank >= 195 and rank < 200 then
        shouldCraft = {12589};
    elseif rank >= 200 and rank < 210 then
        shouldCraft = {
            12591,
            12589,
        };
    elseif rank >= 210 and rank < 225 then
        shouldCraft = {12596};
    elseif rank >= 225 and rank < 235 then
        shouldCraft = {12599};
    elseif rank >= 235 and rank < 245 then
        shouldCraft = {
            12619,
            12599,
        };
    elseif rank >= 245 and rank < 250 then
        shouldCraft = {
            12621,
            12619,
        };
    elseif rank >= 250 and rank < 260 then
        shouldCraft = {
            19788,
            12621,
        };
    elseif rank >= 260 and rank < 280 then
        shouldCraft = {19791};
    elseif rank >= 280 and rank < 285 then
        shouldCraft = {19795};
    elseif rank >= 285 and rank < 300 then
        shouldCraft = {19800};
    elseif rank >= 300 and rank < 305 then
        shouldCraft = {
            30305,
            30303,
            19800,
        };
    elseif rank >= 305 and rank < 310 then
        shouldCraft = {
            30305,
            30303,
        };
    elseif rank >= 310 and rank < 320 then
        shouldCraft = {
            30304,
            30303,
        };
    elseif rank >= 320 and rank < 325 then
        shouldCraft = {
            30310,
            30312,
        };
    elseif rank >= 325 and rank < 335 then
        shouldCraft = {30311};
    elseif rank >= 335 and rank < 340 then
        shouldCraft = {
            30341,
            30311,
        };
    elseif rank >= 340 and rank < 350 then
        shouldCraft = {
            30309,
            30341,
        };
    elseif rank >= 350 and rank < 370 then
        shouldCraft = {56349};
    elseif rank >= 370 and rank < 375 then
        shouldCraft = {53281};
    elseif rank >= 375 and rank < 385 then
        shouldCraft = {
            56464,
            56459,
            56461,
        };
    elseif rank >= 385 and rank < 390 then
        shouldCraft = {56463};
    elseif rank >= 390 and rank < 400 then
        shouldCraft = {56471};
    elseif rank >= 400 and rank < 405 then
        shouldCraft = {61471};
    elseif rank >= 405 and rank < 410 then
        shouldCraft = {56468};
    elseif rank >= 410 and rank < 415 then
        shouldCraft = {56474};
    elseif rank >= 415 and rank < 420 then
        shouldCraft = {56475};
    elseif rank >= 420 and rank < 430 then
        shouldCraft = {56465};
    elseif rank >= 430 and rank < 435 then
        shouldCraft = {56467};
    elseif rank >= 435 and rank < 450 then
        shouldCraft = {56462};
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Engineering[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe
end

print("|cff" .. addonTable.chat_frame_default_color .. '[Profession Capper] loaded Engineering module|r');
