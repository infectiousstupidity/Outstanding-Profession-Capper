local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 19,
        recipes = {52738},
    },
    {
        minSkill = 19,
        targetSkill = 35,
        recipes = {45382},
    },
    {
        minSkill = 35,
        targetSkill = 53,
        recipes = {52843},
    },
    {
        minSkill = 53,
        targetSkill = 75,
        recipes = {52739},
    },
    {
        minSkill = 75,
        targetSkill = 80,
        recipes = {53462},
    },
    {
        minSkill = 80,
        targetSkill = 85,
        recipes = {
            57114,
            56976,
            57004,
            57194,
            56955,
            57022,
        },
    },
    {
        minSkill = 85,
        targetSkill = 90,
        recipes = {
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
        },
    },
    {
        minSkill = 90,
        targetSkill = 95,
        recipes = {
            57259,
            57239,
            57162,
            56963,
            57027,
            56978,
            56961,
            57009,
        },
    },
    {
        minSkill = 95,
        targetSkill = 100,
        recipes = {
            57027,
            56978,
            56961,
            57009,
        },
    },
    {
        minSkill = 100,
        targetSkill = 105,
        recipes = {57704},
    },
    {
        minSkill = 105,
        targetSkill = 110,
        recipes = {
            57120,
            57184,
            57029,
        },
    },
    {
        minSkill = 110,
        targetSkill = 115,
        recipes = {
            57238,
            57163,
        },
    },
    {
        minSkill = 115,
        targetSkill = 120,
        recipes = {
            56971,
            56945,
            56997,
        },
    },
    {
        minSkill = 120,
        targetSkill = 125,
        recipes = {
            57121,
            57186,
            57030,
        },
    },
    {
        minSkill = 125,
        targetSkill = 130,
        recipes = {
            57262,
            57240,
            57157,
        },
    },
    {
        minSkill = 130,
        targetSkill = 135,
        recipes = {
            56973,
            57005,
            56951,
        },
    },
    {
        minSkill = 135,
        targetSkill = 140,
        recipes = {
            57031,
            57123,
            57188,
        },
    },
    {
        minSkill = 140,
        targetSkill = 150,
        recipes = {
            57245,
            57167,
        },
    },
    {
        minSkill = 150,
        targetSkill = 155,
        recipes = {57707},
    },
    {
        minSkill = 155,
        targetSkill = 160,
        recipes = {
            56974,
            57032,
        },
    },
    {
        minSkill = 160,
        targetSkill = 165,
        recipes = {
            57125,
            57197,
        },
    },
    {
        minSkill = 165,
        targetSkill = 170,
        recipes = {57249},
    },
    {
        minSkill = 170,
        targetSkill = 175,
        recipes = {
            57161,
            56953,
        },
    },
    {
        minSkill = 175,
        targetSkill = 180,
        recipes = {
            56994,
            56981,
        },
    },
    {
        minSkill = 180,
        targetSkill = 185,
        recipes = {
            57020,
            57200,
        },
    },
    {
        minSkill = 185,
        targetSkill = 190,
        recipes = {
            57241,
            57129,
        },
    },
    {
        minSkill = 190,
        targetSkill = 200,
        recipes = {57165},
    },
    {
        minSkill = 200,
        targetSkill = 205,
        recipes = {57709},
    },
    {
        minSkill = 205,
        targetSkill = 210,
        recipes = {59499},
    },
    {
        minSkill = 210,
        targetSkill = 215,
        recipes = {
            57131,
            57201,
        },
    },
    {
        minSkill = 215,
        targetSkill = 220,
        recipes = {57242},
    },
    {
        minSkill = 220,
        targetSkill = 225,
        recipes = {
            57151,
            56959,
        },
    },
    {
        minSkill = 225,
        targetSkill = 230,
        recipes = {
            57001,
            56979,
        },
    },
    {
        minSkill = 230,
        targetSkill = 235,
        recipes = {
            57024,
            57183,
        },
    },
    {
        minSkill = 235,
        targetSkill = 240,
        recipes = {
            57244,
            57132,
        },
    },
    {
        minSkill = 240,
        targetSkill = 250,
        recipes = {57154},
    },
    {
        minSkill = 250,
        targetSkill = 255,
        recipes = {57711},
    },
    {
        minSkill = 255,
        targetSkill = 260,
        recipes = {50608},
    },
    {
        minSkill = 260,
        targetSkill = 265,
        recipes = {
            57002,
            56957,
        },
    },
    {
        minSkill = 265,
        targetSkill = 270,
        recipes = {
            57210,
            57025,
        },
    },
    {
        minSkill = 270,
        targetSkill = 275,
        recipes = {
            57185,
            57216,
        },
    },
    {
        minSkill = 275,
        targetSkill = 280,
        recipes = {57251},
    },
    {
        minSkill = 280,
        targetSkill = 285,
        recipes = {
            57219,
            56985,
        },
    },
    {
        minSkill = 285,
        targetSkill = 290,
        recipes = {
            57213,
            57156,
            57133,
        },
    },
    {
        minSkill = 290,
        targetSkill = 305,
        recipes = {57713},
    },
    {
        minSkill = 305,
        targetSkill = 310,
        recipes = {
            57122,
            57226,
        },
    },
    {
        minSkill = 310,
        targetSkill = 315,
        recipes = {56952},
    },
    {
        minSkill = 315,
        targetSkill = 320,
        recipes = {
            56991,
            57187,
            57008,
        },
    },
    {
        minSkill = 320,
        targetSkill = 325,
        recipes = {57168},
    },
    {
        minSkill = 325,
        targetSkill = 330,
        recipes = {56984},
    },
    {
        minSkill = 330,
        targetSkill = 335,
        recipes = {
            57224,
            57252,
        },
    },
    {
        minSkill = 335,
        targetSkill = 340,
        recipes = {
            56972,
            57033,
        },
    },
    {
        minSkill = 340,
        targetSkill = 345,
        recipes = {57113},
    },
    {
        minSkill = 345,
        targetSkill = 350,
        recipes = {
            57227,
            57172,
        },
    },
    {
        minSkill = 350,
        targetSkill = 355,
        recipes = {57715},
    },
    {
        minSkill = 355,
        targetSkill = 380,
        recipes = {50610},
    },
    {
        minSkill = 380,
        targetSkill = 385,
        recipes = {62162},
    },
    {
        minSkill = 385,
        targetSkill = 386,
        recipes = {
            61177,
            56987,
        },
    },
    {
        minSkill = 386,
        targetSkill = 400,
        recipes = {
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
        },
    },
    {
        minSkill = 400,
        targetSkill = 405,
        recipes = {50620},
    },
    {
        minSkill = 405,
        targetSkill = 410,
        recipes = {50611},
    },
    {
        minSkill = 410,
        targetSkill = 415,
        recipes = {50604},
    },
    {
        minSkill = 415,
        targetSkill = 420,
        recipes = {58491},
    },
    {
        minSkill = 420,
        targetSkill = 425,
        recipes = {58483},
    },
    {
        minSkill = 425,
        targetSkill = 440,
        recipes = {
            61177,
            56980,
            57257,
            57221,
        },
    },
    {
        minSkill = 440,
        targetSkill = 450,
        recipes = {
            69385,
            61177,
        },
    },
}

addonTable.registerProfessionGuide("Inscription", steps, addonTable.Inscription)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Inscription module|r")
