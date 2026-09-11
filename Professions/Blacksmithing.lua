local addonName, addonTable = ...

local steps = {
    {
        minSkill = 1,
        targetSkill = 30,
        recipes = {2660},
    },
    {
        minSkill = 30,
        targetSkill = 65,
        recipes = {3320},
    },
    {
        minSkill = 65,
        targetSkill = 75,
        recipes = {2661},
    },
    {
        minSkill = 75,
        targetSkill = 87,
        recipes = {3326},
    },
    {
        minSkill = 87,
        targetSkill = 100,
        recipes = {2666},
    },
    {
        minSkill = 100,
        targetSkill = 105,
        recipes = {7818},
    },
    {
        minSkill = 105,
        targetSkill = 125,
        recipes = {2668},
    },
    {
        minSkill = 125,
        targetSkill = 150,
        recipes = {3337},
    },
    {
        minSkill = 150,
        targetSkill = 155,
        recipes = {14379},
    },
    {
        minSkill = 155,
        targetSkill = 165,
        recipes = {3506},
    },
    {
        minSkill = 165,
        targetSkill = 190,
        recipes = {3501},
    },
    {
        minSkill = 190,
        targetSkill = 200,
        recipes = {7223},
    },
    {
        minSkill = 200,
        targetSkill = 205,
        recipes = {14380},
    },
    {
        minSkill = 205,
        targetSkill = 210,
        recipes = {9920},
    },
    {
        minSkill = 210,
        targetSkill = 225,
        recipes = {9928},
    },
    {
        minSkill = 225,
        targetSkill = 235,
        recipes = {9937},
    },
    {
        minSkill = 235,
        targetSkill = 250,
        recipes = {
            9964,
            9961,
        },
    },
    {
        minSkill = 250,
        targetSkill = 260,
        recipes = {16641},
    },
    {
        minSkill = 260,
        targetSkill = 275,
        recipes = {16644},
    },
    {
        minSkill = 275,
        targetSkill = 280,
        recipes = {20201},
    },
    {
        minSkill = 280,
        targetSkill = 290,
        recipes = {16649},
    },
    {
        minSkill = 290,
        targetSkill = 300,
        recipes = {
            16652,
            16653,
        },
    },
    {
        minSkill = 300,
        targetSkill = 305,
        recipes = {34607},
    },
    {
        minSkill = 305,
        targetSkill = 315,
        recipes = {29547},
    },
    {
        minSkill = 315,
        targetSkill = 320,
        recipes = {29552},
    },
    {
        minSkill = 320,
        targetSkill = 325,
        recipes = {
            29548,
            29553,
        },
    },
    {
        minSkill = 325,
        targetSkill = 330,
        recipes = {32284},
    },
    {
        minSkill = 330,
        targetSkill = 335,
        recipes = {29550},
    },
    {
        minSkill = 335,
        targetSkill = 340,
        recipes = {29568},
    },
    {
        minSkill = 340,
        targetSkill = 350,
        recipes = {29728},
    },
    {
        minSkill = 350,
        targetSkill = 360,
        recipes = {
            52569,
            52568,
        },
    },
    {
        minSkill = 360,
        targetSkill = 370,
        recipes = {
            54550,
            55834,
        },
    },
    {
        minSkill = 370,
        targetSkill = 375,
        recipes = {
            52567,
            52571,
        },
    },
    {
        minSkill = 375,
        targetSkill = 380,
        recipes = {55835},
    },
    {
        minSkill = 380,
        targetSkill = 385,
        recipes = {54918},
    },
    {
        minSkill = 385,
        targetSkill = 390,
        recipes = {55202},
    },
    {
        minSkill = 390,
        targetSkill = 395,
        recipes = {55204},
    },
    {
        minSkill = 395,
        targetSkill = 400,
        recipes = {59436},
    },
    {
        minSkill = 400,
        targetSkill = 405,
        recipes = {54949},
    },
    {
        minSkill = 405,
        targetSkill = 415,
        recipes = {55206},
    },
    {
        minSkill = 415,
        targetSkill = 425,
        recipes = {55656},
    },
    {
        minSkill = 425,
        targetSkill = 430,
        recipes = {55839},
    },
    {
        minSkill = 430,
        targetSkill = 435,
        recipes = {55311},
    },
    {
        minSkill = 435,
        targetSkill = 440,
        recipes = {55303},
    },
    {
        minSkill = 440,
        targetSkill = 450,
        recipes = {55303},
    },
}

addonTable.registerProfessionGuide("Blacksmithing", steps, addonTable.Blacksmithing)

print("|cff" .. addonTable.chat_frame_default_color .. "[Profession Capper] loaded Blacksmithing module|r")
