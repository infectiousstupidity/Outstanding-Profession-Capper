local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 40,
        recipes = {3275},
    },
    {
        minSkill = 40,
        targetSkill = 80,
        recipes = {3276},
    },
    {
        minSkill = 80,
        targetSkill = 100,
        recipes = {
            3277,
            3276,
            7934,
        },
    },
    {
        minSkill = 100,
        targetSkill = 115,
        recipes = {
            3277,
            7934,
        },
    },
    {
        minSkill = 115,
        targetSkill = 130,
        recipes = {3278},
    },
    {
        minSkill = 130,
        targetSkill = 150,
        recipes = {
            3278,
            7935,
        },
    },
    {
        minSkill = 150,
        targetSkill = 180,
        recipes = {
            7928,
            3278,
            7935,
        },
    },
    {
        minSkill = 180,
        targetSkill = 210,
        recipes = {7929},
    },
    {
        minSkill = 210,
        targetSkill = 240,
        recipes = {
            10840,
            7929,
        },
    },
    {
        minSkill = 240,
        targetSkill = 260,
        recipes = {10841},
    },
    {
        minSkill = 260,
        targetSkill = 290,
        recipes = {
            18629,
            10841,
        },
    },
    {
        minSkill = 290,
        targetSkill = 300,
        recipes = {
            18630,
            10841,
        },
    },
    {
        minSkill = 300,
        targetSkill = 330,
        recipes = {
            27032,
            18630,
            23787,
        },
    },
    {
        minSkill = 330,
        targetSkill = 350,
        recipes = {
            27033,
            18630,
            23787,
        },
    },
    {
        minSkill = 350,
        targetSkill = 375,
        recipes = {
            45545,
            27033,
        },
    },
    {
        minSkill = 375,
        targetSkill = 400,
        recipes = {45545},
    },
    {
        minSkill = 400,
        targetSkill = 450,
        recipes = {45546},
    },
}

addonTable.registerProfessionGuide("FirstAid", steps, addonTable.FirstAid)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded FirstAid module|r")
