local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 21,
        recipes = {3918},
    },
    {
        minSkill = 21,
        targetSkill = 31,
        recipes = {
            3919,
            3918,
        },
    },
    {
        minSkill = 31,
        targetSkill = 50,
        recipes = {
            3922,
            3919,
        },
    },
    {
        minSkill = 50,
        targetSkill = 51,
        recipes = {
            7430,
            3924,
        },
    },
    {
        minSkill = 51,
        targetSkill = 75,
        recipes = {
            3924,
            7430,
        },
    },
    {
        minSkill = 75,
        targetSkill = 85,
        recipes = {
            3929,
            3924,
            7430,
        },
    },
    {
        minSkill = 85,
        targetSkill = 90,
        recipes = {
            3931,
            3929,
            3924,
        },
    },
    {
        minSkill = 90,
        targetSkill = 110,
        recipes = {
            3973,
            3926,
        },
    },
    {
        minSkill = 110,
        targetSkill = 125,
        recipes = {
            3938,
            3937,
            3973,
        },
    },
    {
        minSkill = 125,
        targetSkill = 135,
        recipes = {3945},
    },
    {
        minSkill = 135,
        targetSkill = 145,
        recipes = {
            3942,
            3945,
        },
    },
    {
        minSkill = 145,
        targetSkill = 150,
        recipes = {3942},
    },
    {
        minSkill = 150,
        targetSkill = 155,
        recipes = {3953},
    },
    {
        minSkill = 155,
        targetSkill = 175,
        recipes = {
            3955,
            12584,
            3958,
        },
    },
    {
        minSkill = 175,
        targetSkill = 176,
        recipes = {
            12590,
            12585,
        },
    },
    {
        minSkill = 176,
        targetSkill = 185,
        recipes = {
            12585,
            12590,
        },
    },
    {
        minSkill = 185,
        targetSkill = 190,
        recipes = {3961},
    },
    {
        minSkill = 190,
        targetSkill = 195,
        recipes = {3962},
    },
    {
        minSkill = 195,
        targetSkill = 200,
        recipes = {12589},
    },
    {
        minSkill = 200,
        targetSkill = 210,
        recipes = {
            12591,
            12589,
        },
    },
    {
        minSkill = 210,
        targetSkill = 225,
        recipes = {12596},
    },
    {
        minSkill = 225,
        targetSkill = 235,
        recipes = {12599},
    },
    {
        minSkill = 235,
        targetSkill = 245,
        recipes = {
            12619,
            12599,
        },
    },
    {
        minSkill = 245,
        targetSkill = 250,
        recipes = {
            12621,
            12619,
        },
    },
    {
        minSkill = 250,
        targetSkill = 260,
        recipes = {
            19788,
            12621,
        },
    },
    {
        minSkill = 260,
        targetSkill = 280,
        recipes = {19791},
    },
    {
        minSkill = 280,
        targetSkill = 285,
        recipes = {19795},
    },
    {
        minSkill = 285,
        targetSkill = 300,
        recipes = {19800},
    },
    {
        minSkill = 300,
        targetSkill = 305,
        recipes = {
            30305,
            30303,
            19800,
        },
    },
    {
        minSkill = 305,
        targetSkill = 310,
        recipes = {
            30305,
            30303,
        },
    },
    {
        minSkill = 310,
        targetSkill = 320,
        recipes = {
            30304,
            30303,
        },
    },
    {
        minSkill = 320,
        targetSkill = 325,
        recipes = {
            30310,
            30312,
        },
    },
    {
        minSkill = 325,
        targetSkill = 335,
        recipes = {30311},
    },
    {
        minSkill = 335,
        targetSkill = 340,
        recipes = {
            30341,
            30311,
        },
    },
    {
        minSkill = 340,
        targetSkill = 350,
        recipes = {
            30309,
            30341,
        },
    },
    {
        minSkill = 350,
        targetSkill = 370,
        recipes = {56349},
    },
    {
        minSkill = 370,
        targetSkill = 375,
        recipes = {53281},
    },
    {
        minSkill = 375,
        targetSkill = 385,
        recipes = {
            56464,
            56459,
            56461,
        },
    },
    {
        minSkill = 385,
        targetSkill = 390,
        recipes = {56463},
    },
    {
        minSkill = 390,
        targetSkill = 400,
        recipes = {56471},
    },
    {
        minSkill = 400,
        targetSkill = 405,
        recipes = {61471},
    },
    {
        minSkill = 405,
        targetSkill = 410,
        recipes = {56468},
    },
    {
        minSkill = 410,
        targetSkill = 415,
        recipes = {56474},
    },
    {
        minSkill = 415,
        targetSkill = 420,
        recipes = {56475},
    },
    {
        minSkill = 420,
        targetSkill = 430,
        recipes = {56465},
    },
    {
        minSkill = 430,
        targetSkill = 435,
        recipes = {56467},
    },
    {
        minSkill = 435,
        targetSkill = 450,
        recipes = {56462},
    },
}

addonTable.registerProfessionGuide("Engineering", steps, addonTable.Engineering)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Engineering module|r")
