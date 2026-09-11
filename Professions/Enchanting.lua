local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 2,
        recipes = {7421},
    },
    {
        minSkill = 2,
        targetSkill = 10,
        recipes = {
            7418,
            7421,
        },
    },
    {
        minSkill = 10,
        targetSkill = 15,
        recipes = {7418},
    },
    {
        minSkill = 15,
        targetSkill = 20,
        recipes = {
            7418,
            7420,
        },
    },
    {
        minSkill = 20,
        targetSkill = 50,
        recipes = {
            7418,
            7420,
            7443,
        },
    },
    {
        minSkill = 50,
        targetSkill = 60,
        recipes = {
            7418,
            7420,
            7443,
            7457,
        },
    },
    {
        minSkill = 60,
        targetSkill = 90,
        recipes = {
            7418,
            7420,
            7443,
            7457,
            7766,
        },
    },
    {
        minSkill = 90,
        targetSkill = 100,
        recipes = {
            7443,
            7766,
            7457,
        },
    },
    {
        minSkill = 100,
        targetSkill = 101,
        recipes = {
            7795,
            7766,
            14807,
        },
    },
    {
        minSkill = 101,
        targetSkill = 110,
        recipes = {
            7766,
            14807,
            7795,
        },
    },
    {
        minSkill = 110,
        targetSkill = 135,
        recipes = {
            13419,
            13378,
            7766,
            7782,
            7795,
        },
    },
    {
        minSkill = 135,
        targetSkill = 140,
        recipes = {
            13419,
            13501,
            7863,
            7795,
        },
    },
    {
        minSkill = 140,
        targetSkill = 150,
        recipes = {
            13419,
            13536,
            13501,
            7863,
            7795,
        },
    },
    {
        minSkill = 150,
        targetSkill = 155,
        recipes = {
            13419,
            13536,
            13501,
            7863,
        },
    },
    {
        minSkill = 155,
        targetSkill = 156,
        recipes = {
            13628,
            13536,
            13501,
            7863,
        },
    },
    {
        minSkill = 156,
        targetSkill = 165,
        recipes = {
            13536,
            7863,
            13628,
        },
    },
    {
        minSkill = 165,
        targetSkill = 180,
        recipes = {
            13642,
            13536,
            7863,
            13628,
        },
    },
    {
        minSkill = 180,
        targetSkill = 185,
        recipes = {
            13661,
            13642,
            13536,
            7863,
            13628,
        },
    },
    {
        minSkill = 185,
        targetSkill = 200,
        recipes = {
            13661,
            13642,
            13640,
        },
    },
    {
        minSkill = 200,
        targetSkill = 201,
        recipes = {
            13702,
            13661,
            13536,
        },
    },
    {
        minSkill = 201,
        targetSkill = 205,
        recipes = {
            13661,
            13642,
            13536,
            13702,
        },
    },
    {
        minSkill = 205,
        targetSkill = 220,
        recipes = {
            13794,
            13661,
            13642,
        },
    },
    {
        minSkill = 220,
        targetSkill = 225,
        recipes = {
            13794,
            13746,
            13642,
            13644,
        },
    },
    {
        minSkill = 225,
        targetSkill = 235,
        recipes = {
            13815,
            13794,
            13746,
        },
    },
    {
        minSkill = 235,
        targetSkill = 240,
        recipes = {
            13882,
            13858,
        },
    },
    {
        minSkill = 240,
        targetSkill = 250,
        recipes = {
            13882,
            63746,
            13858,
        },
    },
    {
        minSkill = 250,
        targetSkill = 260,
        recipes = {
            13945,
            13939,
            25127,
        },
    },
    {
        minSkill = 260,
        targetSkill = 265,
        recipes = {
            20008,
            13945,
            13939,
        },
    },
    {
        minSkill = 265,
        targetSkill = 299,
        recipes = {20017},
    },
    {
        minSkill = 299,
        targetSkill = 301,
        recipes = {
            20051,
            32664,
            34002,
            20020,
        },
    },
    {
        minSkill = 301,
        targetSkill = 310,
        recipes = {
            34002,
            20028,
            32664,
            20051,
        },
    },
    {
        minSkill = 310,
        targetSkill = 320,
        recipes = {27899},
    },
    {
        minSkill = 320,
        targetSkill = 330,
        recipes = {
            33996,
            27961,
        },
    },
    {
        minSkill = 330,
        targetSkill = 335,
        recipes = {34009},
    },
    {
        minSkill = 335,
        targetSkill = 340,
        recipes = {
            44383,
            34009,
        },
    },
    {
        minSkill = 340,
        targetSkill = 350,
        recipes = {28019},
    },
    {
        minSkill = 350,
        targetSkill = 351,
        recipes = {
            32665,
            60609,
            27958,
        },
    },
    {
        minSkill = 351,
        targetSkill = 360,
        recipes = {
            60609,
            27958,
            32665,
        },
    },
    {
        minSkill = 360,
        targetSkill = 375,
        recipes = {60616},
    },
    {
        minSkill = 375,
        targetSkill = 376,
        recipes = {
            32667,
            60616,
        },
    },
    {
        minSkill = 376,
        targetSkill = 380,
        recipes = {
            60616,
            32667,
        },
    },
    {
        minSkill = 380,
        targetSkill = 385,
        recipes = {44555},
    },
    {
        minSkill = 385,
        targetSkill = 395,
        recipes = {60623},
    },
    {
        minSkill = 395,
        targetSkill = 410,
        recipes = {
            44500,
            44492,
        },
    },
    {
        minSkill = 410,
        targetSkill = 415,
        recipes = {44484},
    },
    {
        minSkill = 415,
        targetSkill = 420,
        recipes = {
            44508,
            44488,
        },
    },
    {
        minSkill = 420,
        targetSkill = 425,
        recipes = {44509},
    },
    {
        minSkill = 425,
        targetSkill = 426,
        recipes = {
            60619,
            47898,
        },
    },
    {
        minSkill = 426,
        targetSkill = 440,
        recipes = {
            47898,
            60619,
        },
    },
    {
        minSkill = 440,
        targetSkill = 450,
        recipes = {
            60763,
            47672,
        },
    },
}

addonTable.registerProfessionGuide("Enchanting", steps, addonTable.Enchanting)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Enchanting module|r")
