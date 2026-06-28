local addonName, addonTable = ...;

local shouldCraft, shouldCraftRecipe;

addonTable.getInscriptionCurrentSkillLevelRecipeToCraft = function(rank)
    if rank > 0 and rank < 19 then
        shouldCraft = {52738};
    elseif rank >= 19 and rank < 35 then
        shouldCraft = {45382};
    elseif rank >= 35 and rank < 53 then
        shouldCraft = {52843};
    elseif rank >= 53 and rank < 75 then
        shouldCraft = {52739};
    elseif rank >= 75 and rank < 80 then
        shouldCraft = {53462};
    elseif rank >= 80 and rank < 85 then
        shouldCraft = {
            57114,
            56976,
            57004,
            57194,
            56955,
            57022,
        };
    elseif rank >= 85 and rank < 90 then
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
        shouldCraft = {
            57027,
            56978,
            56961,
            57009,
        };
    elseif rank >= 100 and rank < 105 then
        shouldCraft = {57704};
    elseif rank >= 105 and rank < 110 then
        shouldCraft = {
            57120,
            57184,
            57029,
        };
    elseif rank >= 110 and rank < 115 then
        shouldCraft = {
            57238,
            57163,
        };
    elseif rank >= 115 and rank < 120 then
        shouldCraft = {
            56971,
            56945,
            56997,
        };
    elseif rank >= 120 and rank < 125 then
        shouldCraft = {
            57121,
            57186,
            57030,
        };
    elseif rank >= 125 and rank < 130 then
        shouldCraft = {
            57262,
            57240,
            57157,
        };
    elseif rank >= 130 and rank < 135 then
        shouldCraft = {
            56973,
            57005,
            56951,
        };
    elseif rank >= 135 and rank < 140 then
        shouldCraft = {
            57031,
            57123,
            57188,
        };
    elseif rank >= 140 and rank < 150 then
        shouldCraft = {
            57245,
            57167,
        };
    elseif rank >= 150 and rank < 155 then
        shouldCraft = {57707};
    elseif rank >= 155 and rank < 160 then
        shouldCraft = {
            56974,
            57032,
        };
    elseif rank >= 160 and rank < 165 then
        shouldCraft = {
            57125,
            57197,
        };
    elseif rank >= 165 and rank < 170 then
        shouldCraft = {
            57249,
        };
    elseif rank >= 170 and rank < 175 then
        shouldCraft = {
            57161,
            56953,
        };
    elseif rank >= 175 and rank < 180 then
        shouldCraft = {
            56994,
            56981,
        };
    elseif rank >= 180 and rank < 185 then
        shouldCraft = {
            57020,
            57200,
        };
    elseif rank >= 185 and rank < 190 then
        shouldCraft = {
            57241,
            57129,
        };
    elseif rank >= 190 and rank < 200 then
        shouldCraft = {
            57165,
        };
    elseif rank >= 200 and rank < 205 then
        shouldCraft = {57709};
    elseif rank >= 205 and rank < 210 then
        shouldCraft = {59499};
    elseif rank >= 210 and rank < 215 then
        shouldCraft = {
            57131,
            57201,
        };
    elseif rank >= 215 and rank < 220 then
        shouldCraft = {
            57242,
        };
    elseif rank >= 220 and rank < 225 then
        shouldCraft = {
            57151,
            56959,
        };
    elseif rank >= 225 and rank < 230 then
        shouldCraft = {
            57001,
            56979,
        };
    elseif rank >= 230 and rank < 235 then
        shouldCraft = {
            57024,
            57183,
        };
    elseif rank >= 235 and rank < 240 then
        shouldCraft = {
            57244,
            57132,
        };
    elseif rank >= 240 and rank < 250 then
        shouldCraft = {
            57154,
        };
    elseif rank >= 250 and rank < 255 then
        shouldCraft = {57711};
    elseif rank >= 255 and rank < 260 then
        shouldCraft = {50608};
    elseif rank >= 260 and rank < 265 then
        shouldCraft = {
            57002,
            56957,
        };
    elseif rank >= 265 and rank < 270 then
        shouldCraft = {
            57210,
            57025,
        };
    elseif rank >= 270 and rank < 275 then
        shouldCraft = {
            57185,
            57216,
        };
    elseif rank >= 275 and rank < 280 then
        shouldCraft = {
            57251,
        };
    elseif rank >= 280 and rank < 285 then
        shouldCraft = {
            57219,
            56985,
        };
    elseif rank >= 285 and rank < 290 then
        shouldCraft = {
            57213,
            57156,
            57133,
        };
    elseif rank >= 290 and rank < 305 then
        shouldCraft = {57713};
    elseif rank >= 305 and rank < 310 then
        shouldCraft = {
            57122,
            57226,
        };
    elseif rank >= 310 and rank < 315 then
        shouldCraft = {
            56952,
        };
    elseif rank >= 315 and rank < 320 then
        shouldCraft = {
            56991,
            57187,
            57008,
        };
    elseif rank >= 320 and rank < 325 then
        shouldCraft = {
            57168,
        };
    elseif rank >= 325 and rank < 330 then
        shouldCraft = {
            56984,
        };
    elseif rank >= 330 and rank < 335 then
        shouldCraft = {
            57224,
            57252,
        };
    elseif rank >= 335 and rank < 340 then
        shouldCraft = {
            56972,
            57033,
        };
    elseif rank >= 340 and rank < 345 then
        shouldCraft = {
            57113,
        };
    elseif rank >= 345 and rank < 350 then
        shouldCraft = {
            57227,
            57172,
        };
    elseif rank >= 350 and rank < 355 then
        shouldCraft = {57715};
    elseif rank >= 355 and rank < 380 then
        shouldCraft = {50610};
    elseif rank >= 380 and rank < 385 then
        shouldCraft = {62162};
    elseif rank == 385 then
        shouldCraft = {
            61177,
            56987,
        };
    elseif rank >= 386 and rank < 400 then
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
        shouldCraft = {50620};
    elseif rank >= 405 and rank < 410 then
        shouldCraft = {50611};
    elseif rank >= 410 and rank < 415 then
        shouldCraft = {50604};
    elseif rank >= 415 and rank < 420 then
        shouldCraft = {58491};
    elseif rank >= 420 and rank < 425 then
        shouldCraft = {58483};
    elseif rank >= 425 and rank < 440 then
        shouldCraft = {
            61177,
            56980,
            57257,
            57221,
        };
    elseif rank >= 440 and rank < 450 then
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
    return shouldCraft, shouldCraftRecipe;
end
