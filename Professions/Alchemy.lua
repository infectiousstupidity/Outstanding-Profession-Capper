local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 60,
        recipes = {2330},
    },
    {
        minSkill = 60,
        targetSkill = 105,
        recipes = {2337},
    },
    {
        minSkill = 105,
        targetSkill = 110,
        recipes = {3171},
    },
    {
        minSkill = 110,
        targetSkill = 140,
        recipes = {3447},
    },
    {
        minSkill = 140,
        targetSkill = 155,
        recipes = {3173},
    },
    {
        minSkill = 155,
        targetSkill = 175,
        recipes = {7181},
    },
    {
        minSkill = 175,
        targetSkill = 185,
        recipes = {3452},
    },
    {
        minSkill = 185,
        targetSkill = 205,
        recipes = {
            11449,
            3450,
        },
    },
    {
        minSkill = 205,
        targetSkill = 215,
        recipes = {11450},
    },
    {
        minSkill = 215,
        targetSkill = 230,
        recipes = {11457},
    },
    {
        minSkill = 230,
        targetSkill = 231,
        recipes = {11459},
    },
    {
        minSkill = 231,
        targetSkill = 250,
        recipes = {11460},
    },
    {
        minSkill = 250,
        targetSkill = 265,
        recipes = {11467},
    },
    {
        minSkill = 265,
        targetSkill = 285,
        recipes = {17553},
    },
    {
        minSkill = 285,
        targetSkill = 300,
        recipes = {17556},
    },
    {
        minSkill = 300,
        targetSkill = 310,
        recipes = {
            33732,
            33740,
        },
    },
    {
        minSkill = 310,
        targetSkill = 325,
        recipes = {28545},
    },
    {
        minSkill = 325,
        targetSkill = 335,
        recipes = {45061},
    },
    {
        minSkill = 335,
        targetSkill = 340,
        recipes = {28551},
    },
    {
        minSkill = 340,
        targetSkill = 350,
        recipes = {28555},
    },
    {
        minSkill = 350,
        targetSkill = 365,
        recipes = {53839},
    },
    {
        minSkill = 365,
        targetSkill = 375,
        recipes = {53842},
    },
    {
        minSkill = 375,
        targetSkill = 380,
        recipes = {53812},
    },
    {
        minSkill = 380,
        targetSkill = 385,
        recipes = {53900},
    },
    {
        minSkill = 385,
        targetSkill = 395,
        recipes = {54218},
    },
    {
        minSkill = 395,
        targetSkill = 400,
        recipes = {53840},
    },
    {
        minSkill = 400,
        targetSkill = 405,
        recipes = {
            54221,
            53840,
        },
    },
    {
        minSkill = 405,
        targetSkill = 415,
        recipes = {
            54221,
            53905,
        },
    },
    {
        minSkill = 415,
        targetSkill = 425,
        recipes = {53837},
    },
    {
        minSkill = 425,
        targetSkill = 430,
        recipes = {60350},
    },
    {
        minSkill = 430,
        targetSkill = 435,
        recipes = {57427},
    },
    {
        minSkill = 435,
        targetSkill = 440,
        recipes = {
            57425,
            53903,
            54213,
            53902,
            53901,
        },
    },
    {
        minSkill = 440,
        targetSkill = 450,
        recipes = {
            53903,
            54213,
            53902,
            53901,
            57425,
        },
    },
}

addonTable.registerProfessionGuide("Alchemy", steps, addonTable.Alchemy)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Alchemy module|r")
