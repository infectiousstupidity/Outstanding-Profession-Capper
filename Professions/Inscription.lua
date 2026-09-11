local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getInscriptionCurrentSkillLevelRecipeToCraft = function(rank)
    shouldCraft, shouldCraftRecipe = nil, nil
    local targetSkill = nil
    if rank > 0 and rank < 19 then
        targetSkill = 19
        shouldCraft = {52738};
    elseif rank >= 19 and rank < 35 then
        targetSkill = 35
        shouldCraft = {45382};
    elseif rank >= 35 and rank < 53 then
        targetSkill = 53
        shouldCraft = {52843};
    elseif rank >= 53 and rank < 75 then
        targetSkill = 75
        shouldCraft = {52739};
    elseif rank >= 75 and rank < 80 then
        targetSkill = 80
        shouldCraft = {53462};
    elseif rank >= 80 and rank < 85 then
        targetSkill = 85
        shouldCraft = {
            57114,
            56976,
            57004,
            57194,
            56955,
            57022,
        };
    elseif rank >= 85 and rank < 90 then
        targetSkill = 90
        shouldCraft = {
            57114,
            56976,
            57004,
            57194,
            56955,
            57022,
            57259,
            57239,
            57162,
            56963,
        };
    elseif rank >= 90 and rank < 95 then
        targetSkill = 95
        shouldCraft = {
            57259,
            57239,
            57162,
            56963,
            57027,
            56978,
            56961,
            57009,
        };
    elseif rank >= 95 and rank < 100 then
        targetSkill = 100
        shouldCraft = {
            57027,
            56978,
            56961,
            57009,
        };
    elseif rank >= 100 and rank < 105 then
        targetSkill = 105
        shouldCraft = {57704};
    elseif rank >= 105 and rank < 110 then
        targetSkill = 110
        shouldCraft = {
            57120,
            57184,
            57029,
        };
    elseif rank >= 110 and rank < 115 then
        targetSkill = 115
        shouldCraft = {
            57238,
            57163,
        };
    elseif rank >= 115 and rank < 120 then
        targetSkill = 120
        shouldCraft = {
            56971,
            56945,
            56997,
        };
    elseif rank >= 120 and rank < 125 then
        targetSkill = 125
        shouldCraft = {
            57121,
            57186,
            57030,
        };
    elseif rank >= 125 and rank < 130 then
        targetSkill = 130
        shouldCraft = {
            57262,
            57240,
            57157,
        };
    elseif rank >= 130 and rank < 135 then
        targetSkill = 135
        shouldCraft = {
            56973,
            57005,
            56951,
        };
    elseif rank >= 135 and rank < 140 then
        targetSkill = 140
        shouldCraft = {
            57031,
            57123,
            57188,
        };
    elseif rank >= 140 and rank < 150 then
        targetSkill = 150
        shouldCraft = {
            57245,
            57167,
        };
    elseif rank >= 150 and rank < 155 then
        targetSkill = 155
        shouldCraft = {57707};
    elseif rank >= 155 and rank < 160 then
        targetSkill = 160
        shouldCraft = {
            56974,
            57032,
        };
    elseif rank >= 160 and rank < 165 then
        targetSkill = 165
        shouldCraft = {
            57125,
            57197,
        };
    elseif rank >= 165 and rank < 170 then
        targetSkill = 170
        shouldCraft = {
            57249,
        };
    elseif rank >= 170 and rank < 175 then
        targetSkill = 175
        shouldCraft = {
            57161,
            56953,
        };
    elseif rank >= 175 and rank < 180 then
        targetSkill = 180
        shouldCraft = {
            56994,
            56981,
        };
    elseif rank >= 180 and rank < 185 then
        targetSkill = 185
        shouldCraft = {
            57020,
            57200,
        };
    elseif rank >= 185 and rank < 190 then
        targetSkill = 190
        shouldCraft = {
            57241,
            57129,
        };
    elseif rank >= 190 and rank < 200 then
        targetSkill = 200
        shouldCraft = {
            57165,
        };
    elseif rank >= 200 and rank < 205 then
        targetSkill = 205
        shouldCraft = {57709};
    elseif rank >= 205 and rank < 210 then
        targetSkill = 210
        shouldCraft = {59499};
    elseif rank >= 210 and rank < 215 then
        targetSkill = 215
        shouldCraft = {
            57131,
            57201,
        };
    elseif rank >= 215 and rank < 220 then
        targetSkill = 220
        shouldCraft = {
            57242,
        };
    elseif rank >= 220 and rank < 225 then
        targetSkill = 225
        shouldCraft = {
            57151,
            56959,
        };
    elseif rank >= 225 and rank < 230 then
        targetSkill = 230
        shouldCraft = {
            57001,
            56979,
        };
    elseif rank >= 230 and rank < 235 then
        targetSkill = 235
        shouldCraft = {
            57024,
            57183,
        };
    elseif rank >= 235 and rank < 240 then
        targetSkill = 240
        shouldCraft = {
            57244,
            57132,
        };
    elseif rank >= 240 and rank < 250 then
        targetSkill = 250
        shouldCraft = {
            57154,
        };
    elseif rank >= 250 and rank < 255 then
        targetSkill = 255
        shouldCraft = {57711};
    elseif rank >= 255 and rank < 260 then
        targetSkill = 260
        shouldCraft = {50608};
    elseif rank >= 260 and rank < 265 then
        targetSkill = 265
        shouldCraft = {
            57002,
            56957,
        };
    elseif rank >= 265 and rank < 270 then
        targetSkill = 270
        shouldCraft = {
            57210,
            57025,
        };
    elseif rank >= 270 and rank < 275 then
        targetSkill = 275
        shouldCraft = {
            57185,
            57216,
        };
    elseif rank >= 275 and rank < 280 then
        targetSkill = 280
        shouldCraft = {
            57251,
        };
    elseif rank >= 280 and rank < 285 then
        targetSkill = 285
        shouldCraft = {
            57219,
            56985,
        };
    elseif rank >= 285 and rank < 290 then
        targetSkill = 290
        shouldCraft = {
            57213,
            57156,
            57133,
        };
    elseif rank >= 290 and rank < 305 then
        targetSkill = 305
        shouldCraft = {57713};
    elseif rank >= 305 and rank < 310 then
        targetSkill = 310
        shouldCraft = {
            57122,
            57226,
        };
    elseif rank >= 310 and rank < 315 then
        targetSkill = 315
        shouldCraft = {
            56952,
        };
    elseif rank >= 315 and rank < 320 then
        targetSkill = 320
        shouldCraft = {
            56991,
            57187,
            57008,
        };
    elseif rank >= 320 and rank < 325 then
        targetSkill = 325
        shouldCraft = {
            57168,
        };
    elseif rank >= 325 and rank < 330 then
        targetSkill = 330
        shouldCraft = {
            56984,
        };
    elseif rank >= 330 and rank < 335 then
        targetSkill = 335
        shouldCraft = {
            57224,
            57252,
        };
    elseif rank >= 335 and rank < 340 then
        targetSkill = 340
        shouldCraft = {
            56972,
            57033,
        };
    elseif rank >= 340 and rank < 345 then
        targetSkill = 345
        shouldCraft = {
            57113,
        };
    elseif rank >= 345 and rank < 350 then
        targetSkill = 350
        shouldCraft = {
            57227,
            57172,
        };
    elseif rank >= 350 and rank < 355 then
        targetSkill = 355
        shouldCraft = {57715};
    elseif rank >= 355 and rank < 380 then
        targetSkill = 380
        shouldCraft = {50610};
    elseif rank >= 380 and rank < 385 then
        targetSkill = 385
        shouldCraft = {62162};
    elseif rank == 385 then
        targetSkill = 386
        shouldCraft = {
            61177,
            56987,
        };
    elseif rank >= 386 and rank < 400 then
        targetSkill = 400
        shouldCraft = {
            61177,
            56943,
            57192,
            57003,
            57006,
            57036,
            57198,
            57248,
            57225,
            57222,
        };
    elseif rank >= 400 and rank < 405 then
        targetSkill = 405
        shouldCraft = {50620};
    elseif rank >= 405 and rank < 410 then
        targetSkill = 410
        shouldCraft = {50611};
    elseif rank >= 410 and rank < 415 then
        targetSkill = 415
        shouldCraft = {50604};
    elseif rank >= 415 and rank < 420 then
        targetSkill = 420
        shouldCraft = {58491};
    elseif rank >= 420 and rank < 425 then
        targetSkill = 425
        shouldCraft = {58483};
    elseif rank >= 425 and rank < 440 then
        targetSkill = 440
        shouldCraft = {
            61177,
            56980,
            57257,
            57221,
        };
    elseif rank >= 440 and rank < 450 then
        targetSkill = 450
        shouldCraft = {
            69385,
            61177,
        };
    end
    if shouldCraft and #shouldCraft > 0 then
        shouldCraftRecipe = {}
        addonTable.sortRecipesByNumAvailable(shouldCraft)
        for i, v in pairs(shouldCraft) do
            shouldCraftRecipe[i] = addonTable.Inscription[tostring(v)]
        end
    end
    return shouldCraft, shouldCraftRecipe, targetSkill;
end
