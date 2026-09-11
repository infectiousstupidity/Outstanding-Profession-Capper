local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 30,
        recipes = {25255},
    },
    {
        minSkill = 30,
        targetSkill = 50,
        recipes = {
            32179,
            32178,
        },
    },
    {
        minSkill = 50,
        targetSkill = 80,
        recipes = {
            25278,
            32179,
            32178,
        },
    },
    {
        minSkill = 80,
        targetSkill = 100,
        recipes = {
            25317,
            25287,
            25284,
        },
    },
    {
        minSkill = 100,
        targetSkill = 110,
        recipes = {
            25318,
            25317,
            25287,
            25284,
        },
    },
    {
        minSkill = 110,
        targetSkill = 120,
        recipes = {
            32807,
            25318,
            25317,
        },
    },
    {
        minSkill = 120,
        targetSkill = 150,
        recipes = {
            25610,
            32807,
            25318,
        },
    },
    {
        minSkill = 150,
        targetSkill = 180,
        recipes = {25615},
    },
    {
        minSkill = 180,
        targetSkill = 200,
        recipes = {25620},
    },
    {
        minSkill = 200,
        targetSkill = 220,
        recipes = {25621},
    },
    {
        minSkill = 220,
        targetSkill = 225,
        recipes = {
            26876,
            25621,
        },
    },
    {
        minSkill = 225,
        targetSkill = 245,
        recipes = {26880},
    },
    {
        minSkill = 245,
        targetSkill = 260,
        recipes = {26883},
    },
    {
        minSkill = 260,
        targetSkill = 280,
        recipes = {26902},
    },
    {
        minSkill = 280,
        targetSkill = 290,
        recipes = {
            34960,
            26908,
            26907,
        },
    },
    {
        minSkill = 290,
        targetSkill = 300,
        recipes = {
            34961,
            34960,
            26908,
            26907,
        },
    },
    {
        minSkill = 300,
        targetSkill = 320,
        recipes = {
            28903,
            28938,
            28950,
            28916,
            28910,
            28925,
        },
    },
    {
        minSkill = 320,
        targetSkill = 325,
        recipes = {
            28905,
            28917,
            28953,
        },
    },
    {
        minSkill = 325,
        targetSkill = 340,
        recipes = {
            38068,
            28948,
            28936,
            28924,
        },
    },
    {
        minSkill = 340,
        targetSkill = 350,
        recipes = {
            31052,
            28948,
            28936,
            28924,
        },
    },
    {
        minSkill = 350,
        targetSkill = 395,
        recipes = {
            53831,
            53835,
            53832,
            53934,
            53926,
            53892,
            53866,
            53852,
        },
    },
    {
        minSkill = 395,
        targetSkill = 400,
        recipes = {
            56193,
            58142,
            58141,
            56194,
        },
    },
    {
        minSkill = 400,
        targetSkill = 420,
        recipes = {
            58145,
            58146,
        },
    },
    {
        minSkill = 420,
        targetSkill = 425,
        recipes = {
            54007,
            53969,
            53947,
            53956,
            53989,
            53953,
            56531,
        },
    },
    {
        minSkill = 425,
        targetSkill = 450,
        recipes = {
            55394,
            55386,
            55389,
            55390,
            55384,
            55392,
            55393,
            55387,
            55388,
            55407,
            55395,
            55402,
            55399,
            55401,
            55405,
            55397,
            55398,
            55396,
            55404,
            55400,
            55403,
        },
    },
}

addonTable.registerProfessionGuide("Jewelcrafting", steps, addonTable.Jewelcrafting)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Jewelcrafting module|r")
