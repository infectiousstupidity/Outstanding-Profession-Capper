local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 45,
        recipes = {2963},
    },
    {
        minSkill = 45,
        targetSkill = 50,
        recipes = {8776},
    },
    {
        minSkill = 50,
        targetSkill = 70,
        recipes = {3840},
    },
    {
        minSkill = 70,
        targetSkill = 75,
        recipes = {2397},
    },
    {
        minSkill = 75,
        targetSkill = 100,
        recipes = {2964},
    },
    {
        minSkill = 100,
        targetSkill = 105,
        recipes = {
            12046,
            3757,
        },
    },
    {
        minSkill = 105,
        targetSkill = 110,
        recipes = {12046},
    },
    {
        minSkill = 110,
        targetSkill = 125,
        recipes = {3848},
    },
    {
        minSkill = 125,
        targetSkill = 145,
        recipes = {3839},
    },
    {
        minSkill = 145,
        targetSkill = 160,
        recipes = {
            8760,
            3848,
        },
    },
    {
        minSkill = 160,
        targetSkill = 170,
        recipes = {8762},
    },
    {
        minSkill = 170,
        targetSkill = 180,
        recipes = {3871},
    },
    {
        minSkill = 180,
        targetSkill = 185,
        recipes = {3865},
    },
    {
        minSkill = 185,
        targetSkill = 205,
        recipes = {8791},
    },
    {
        minSkill = 205,
        targetSkill = 215,
        recipes = {8799},
    },
    {
        minSkill = 215,
        targetSkill = 220,
        recipes = {
            12049,
            8799,
        },
    },
    {
        minSkill = 220,
        targetSkill = 230,
        recipes = {12053},
    },
    {
        minSkill = 230,
        targetSkill = 250,
        recipes = {12072},
    },
    {
        minSkill = 250,
        targetSkill = 260,
        recipes = {18401},
    },
    {
        minSkill = 260,
        targetSkill = 280,
        recipes = {18402},
    },
    {
        minSkill = 280,
        targetSkill = 295,
        recipes = {18417},
    },
    {
        minSkill = 295,
        targetSkill = 300,
        recipes = {18444},
    },
    {
        minSkill = 300,
        targetSkill = 325,
        recipes = {26745},
    },
    {
        minSkill = 325,
        targetSkill = 335,
        recipes = {26747},
    },
    {
        minSkill = 335,
        targetSkill = 345,
        recipes = {26772},
    },
    {
        minSkill = 345,
        targetSkill = 350,
        recipes = {26774},
    },
    {
        minSkill = 350,
        targetSkill = 375,
        recipes = {55899},
    },
    {
        minSkill = 375,
        targetSkill = 380,
        recipes = {55908},
    },
    {
        minSkill = 380,
        targetSkill = 385,
        recipes = {55906},
    },
    {
        minSkill = 385,
        targetSkill = 395,
        recipes = {55907},
    },
    {
        minSkill = 395,
        targetSkill = 400,
        recipes = {55914},
    },
    {
        minSkill = 400,
        targetSkill = 405,
        recipes = {55900},
    },
    {
        minSkill = 405,
        targetSkill = 410,
        recipes = {55920},
    },
    {
        minSkill = 410,
        targetSkill = 415,
        recipes = {55922},
    },
    {
        minSkill = 415,
        targetSkill = 425,
        recipes = {
            55924,
            55923,
        },
    },
    {
        minSkill = 425,
        targetSkill = 450,
        recipes = {56007},
    },
}

addonTable.registerProfessionGuide("Tailoring", steps, addonTable.Tailoring)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Tailoring module|r")
