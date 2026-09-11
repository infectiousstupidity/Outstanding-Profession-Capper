local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getEngineeringCurrentSkillLevelRecipeToCraft = function(rank)
    shouldCraft, shouldCraftRecipe = nil, nil
    local targetSkill = nil
    if rank > 0 and rank < 21 then
        targetSkill = 21
        shouldCraft = {3918}; -- Rough Blasting Powder
    elseif rank >= 21 and rank < 31 then
        targetSkill = 31
        shouldCraft = {
            3919,
            3918,
        };
    elseif rank >= 31 and rank < 50 then
        targetSkill = 50
        shouldCraft = {
            3922,
            3919,
        };
    elseif rank == 50 then
        targetSkill = 51
        shouldCraft = {
            7430,
            3924,
        };
    elseif rank >= 51 and rank < 75 then
        targetSkill = 75
        shouldCraft = {
            3924,
            7430,
        };
    elseif rank >= 75 and rank < 85 then
        targetSkill = 85
        shouldCraft = {
            3929,
            3924,
            7430,
        };
    elseif rank >= 85 and rank < 90 then
        targetSkill = 90
        shouldCraft = {
            3931,
            3929,
            3924,
        };
    elseif rank >= 90 and rank < 110 then
        targetSkill = 110
        shouldCraft = {
            3973,
            3926,
        };
    elseif rank >= 110 and rank < 125 then
        targetSkill = 125
        shouldCraft = {
            3938,
            3937,
            3973,
        };
    elseif rank >= 125 and rank < 135 then
        targetSkill = 135
        shouldCraft = {3945};
    elseif rank >= 135 and rank < 145 then
        targetSkill = 145
        shouldCraft = {
            3942,
            3945,
        };
    elseif rank >= 145 and rank < 150 then
        targetSkill = 150
        shouldCraft = {3942};
    elseif rank >= 150 and rank < 155 then
        targetSkill = 155
        shouldCraft = {3953};
    elseif rank >= 155 and rank < 175 then
        targetSkill = 175
        shouldCraft = {
            3955,
            12584,
            3958,
        };
    elseif rank == 175 then
        targetSkill = 176
        shouldCraft = {
            12590,
            12585,
        };
    elseif rank >= 176 and rank < 185 then
        targetSkill = 185
        shouldCraft = {
            12585,
            12590,
        };
    elseif rank >= 185 and rank < 190 then
        targetSkill = 190
        shouldCraft = {
            3961,
        };
    elseif rank >= 190 and rank < 195 then
        targetSkill = 195
        shouldCraft = {
            3962,
        };
    elseif rank >= 195 and rank < 200 then
        targetSkill = 200
        shouldCraft = {12589};
    elseif rank >= 200 and rank < 210 then
        targetSkill = 210
        shouldCraft = {
            12591,
            12589,
        };
    elseif rank >= 210 and rank < 225 then
        targetSkill = 225
        shouldCraft = {12596};
    elseif rank >= 225 and rank < 235 then
        targetSkill = 235
        shouldCraft = {12599};
    elseif rank >= 235 and rank < 245 then
        targetSkill = 245
        shouldCraft = {
            12619,
            12599,
        };
    elseif rank >= 245 and rank < 250 then
        targetSkill = 250
        shouldCraft = {
            12621,
            12619,
        };
    elseif rank >= 250 and rank < 260 then
        targetSkill = 260
        shouldCraft = {
            19788,
            12621,
        };
    elseif rank >= 260 and rank < 280 then
        targetSkill = 280
        shouldCraft = {19791};
    elseif rank >= 280 and rank < 285 then
        targetSkill = 285
        shouldCraft = {19795};
    elseif rank >= 285 and rank < 300 then
        targetSkill = 300
        shouldCraft = {19800};
    elseif rank >= 300 and rank < 305 then
        targetSkill = 305
        shouldCraft = {
            30305,
            30303,
            19800,
        };
    elseif rank >= 305 and rank < 310 then
        targetSkill = 310
        shouldCraft = {
            30305,
            30303,
        };
    elseif rank >= 310 and rank < 320 then
        targetSkill = 320
        shouldCraft = {
            30304,
            30303,
        };
    elseif rank >= 320 and rank < 325 then
        targetSkill = 325
        shouldCraft = {
            30310,
            30312,
        };
    elseif rank >= 325 and rank < 335 then
        targetSkill = 335
        shouldCraft = {30311};
    elseif rank >= 335 and rank < 340 then
        targetSkill = 340
        shouldCraft = {
            30341,
            30311,
        };
    elseif rank >= 340 and rank < 350 then
        targetSkill = 350
        shouldCraft = {
            30309,
            30341,
        };
    elseif rank >= 350 and rank < 370 then
        targetSkill = 370
        shouldCraft = {56349};
    elseif rank >= 370 and rank < 375 then
        targetSkill = 375
        shouldCraft = {53281};
    elseif rank >= 375 and rank < 385 then
        targetSkill = 385
        shouldCraft = {
            56464,
            56459,
            56461,
        };
    elseif rank >= 385 and rank < 390 then
        targetSkill = 390
        shouldCraft = {56463};
    elseif rank >= 390 and rank < 400 then
        targetSkill = 400
        shouldCraft = {56471};
    elseif rank >= 400 and rank < 405 then
        targetSkill = 405
        shouldCraft = {61471};
    elseif rank >= 405 and rank < 410 then
        targetSkill = 410
        shouldCraft = {56468};
    elseif rank >= 410 and rank < 415 then
        targetSkill = 415
        shouldCraft = {56474};
    elseif rank >= 415 and rank < 420 then
        targetSkill = 420
        shouldCraft = {56475};
    elseif rank >= 420 and rank < 430 then
        targetSkill = 430
        shouldCraft = {56465};
    elseif rank >= 430 and rank < 435 then
        targetSkill = 435
        shouldCraft = {56467};
    elseif rank >= 435 and rank < 450 then
        targetSkill = 450
        shouldCraft = {56462};
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Engineering[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe, targetSkill;
end

print("|cff" .. addonTable.chat_frame_default_color .. '[Profession Capper] loaded Engineering module|r');
