local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 20,
        recipes = {
            2881,
            2152,
        },
    },
    {
        minSkill = 20,
        targetSkill = 30,
        recipes = {2152},
    },
    {
        minSkill = 30,
        targetSkill = 50,
        recipes = {9058},
    },
    {
        minSkill = 50,
        targetSkill = 55,
        recipes = {9062},
    },
    {
        minSkill = 55,
        targetSkill = 85,
        recipes = {3756},
    },
    {
        minSkill = 85,
        targetSkill = 100,
        recipes = {3763},
    },
    {
        minSkill = 100,
        targetSkill = 115,
        recipes = {3817},
    },
    {
        minSkill = 115,
        targetSkill = 130,
        recipes = {2167},
    },
    {
        minSkill = 130,
        targetSkill = 145,
        recipes = {
            3766,
            2168,
        },
    },
    {
        minSkill = 145,
        targetSkill = 150,
        recipes = {3764},
    },
    {
        minSkill = 150,
        targetSkill = 155,
        recipes = {23190},
    },
    {
        minSkill = 155,
        targetSkill = 165,
        recipes = {3818},
    },
    {
        minSkill = 165,
        targetSkill = 180,
        recipes = {3780},
    },
    {
        minSkill = 180,
        targetSkill = 200,
        recipes = {10482},
    },
    {
        minSkill = 200,
        targetSkill = 205,
        recipes = {10487},
    },
    {
        minSkill = 205,
        targetSkill = 235,
        recipes = {10507},
    },
    {
        minSkill = 235,
        targetSkill = 250,
        recipes = {10548},
    },
    {
        minSkill = 250,
        targetSkill = 265,
        recipes = {19058},
    },
    {
        minSkill = 265,
        targetSkill = 290,
        recipes = {19052},
    },
    {
        minSkill = 290,
        targetSkill = 300,
        recipes = {19071},
    },
    {
        minSkill = 300,
        targetSkill = 310,
        recipes = {32454},
    },
    {
        minSkill = 310,
        targetSkill = 325,
        recipes = {32456},
    },
    {
        minSkill = 325,
        targetSkill = 335,
        recipes = {32455},
    },
    {
        minSkill = 335,
        targetSkill = 340,
        recipes = {32473},
    },
    {
        minSkill = 340,
        targetSkill = 350,
        recipes = {
            32469,
            32473,
        },
    },
    {
        minSkill = 350,
        targetSkill = 380,
        recipes = {50962},
    },
    {
        minSkill = 380,
        targetSkill = 390,
        recipes = {50948},
    },
    {
        minSkill = 390,
        targetSkill = 405,
        recipes = {50936},
    },
    {
        minSkill = 405,
        targetSkill = 420,
        recipes = {
            60601,
            60611,
        },
    },
    {
        minSkill = 420,
        targetSkill = 425,
        recipes = {60720},
    },
    {
        minSkill = 425,
        targetSkill = 435,
        recipes = {60721},
    },
    {
        minSkill = 435,
        targetSkill = 440,
        recipes = {
            50965,
            50967,
        },
    },
    {
        minSkill = 440,
        targetSkill = 450,
        recipes = {
            60757,
            60756,
            60640,
            60637,
            60761,
            60755,
            60759,
            62176,
            60758,
            60760,
            60754,
            62177,
        },
    },
}

addonTable.registerProfessionGuide("Leatherworking", steps, addonTable.Leatherworking)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Leatherworking module|r")
