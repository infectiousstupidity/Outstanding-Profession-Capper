local addonName, addonTable = ...

-- Generated from Questie WotLK NPC spawn/map data plus AzerothCore trainer-group mappings.
-- Sources:
--   Questie/Questie @ 215b0c757e2cefdffc11414b2c70456e37573cc2
--   AzerothCore/azerothcore-wotlk @ f1bef3bc0a2f6396175e184c2cac70df77b46d11
-- Only NPCs referenced by bundled recipe acquisition metadata are included.

addonTable.recipeSourceLocationDataRevision = "questie-215b0c7+acore-f1bef3b+map-v1"
local npcLocations = {
    [66] = {
        name = "Tharynn Bouden",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 41.82, y = 67.16 },
        },
    },
    [340] = {
        name = "Kendor Kabonka",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 77.47, y = 52.69 },
        },
    },
    [514] = {
        name = "Smith Argus",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 41.71, y = 65.54 },
        },
    },
    [734] = {
        name = "Corporal Bluth",
        faction = "alliance",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 37.96, y = 2.99 },
        },
    },
    [777] = {
        name = "Amy Davenport",
        faction = "alliance",
        locations = {
            { zone = "Redridge Mountains", areaID = 44, mapID = 36, x = 29.13, y = 47.32 },
        },
    },
    [843] = {
        name = "Gina MacGregor",
        faction = "alliance",
        locations = {
            { zone = "Westfall", areaID = 40, mapID = 39, x = 57.64, y = 54.05 },
        },
    },
    [989] = {
        name = "Banalash",
        faction = "horde",
        locations = {
            { zone = "Swamp of Sorrows", areaID = 8, mapID = 38, x = 44.77, y = 56.63 },
        },
    },
    [1103] = {
        name = "Eldrin",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 79.22, y = 69.03 },
        },
    },
    [1146] = {
        name = "Vharr",
        faction = "horde",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 32.36, y = 27.95 },
        },
    },
    [1148] = {
        name = "Nerrist",
        faction = "horde",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 32.70, y = 29.23 },
        },
    },
    [1149] = {
        name = "Uthok",
        faction = "horde",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 31.55, y = 27.95 },
        },
    },
    [1215] = {
        name = "Alchemist Mallory",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 39.84, y = 48.23 },
        },
    },
    [1241] = {
        name = "Tognus Flintfire",
        faction = "alliance",
        locations = {
            { zone = "Dun Morogh", areaID = 1, mapID = 27, x = 45.34, y = 51.94 },
        },
    },
    [1250] = {
        name = "Drake Lindgren",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 83.31, y = 66.69 },
        },
    },
    [1286] = {
        name = "Edna Mullby",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 64.73, y = 71.26 },
        },
    },
    [1304] = {
        name = "Darian Singh",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 42.44, y = 76.94 },
        },
    },
    [1313] = {
        name = "Maria Lumere",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 55.89, y = 85.63 },
        },
    },
    [1317] = {
        name = "Lucan Cordell",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 52.90, y = 74.46 },
        },
    },
    [1318] = {
        name = "Jessara Cordell",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 52.80, y = 74.26 },
        },
    },
    [1346] = {
        name = "Georgio Bolero",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 53.08, y = 81.35 },
        },
    },
    [1347] = {
        name = "Alexandra Bolero",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 53.14, y = 81.76 },
        },
    },
    [1355] = {
        name = "Cook Ghilm",
        faction = "alliance",
        locations = {
            { zone = "Dun Morogh", areaID = 1, mapID = 27, x = 68.38, y = 54.49 },
        },
    },
    [1382] = {
        name = "Mudduk",
        faction = "horde",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 31.34, y = 27.97 },
        },
    },
    [1385] = {
        name = "Brawn",
        faction = "horde",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 31.74, y = 28.90 },
        },
    },
    [1386] = {
        name = "Rogvar",
        faction = "horde",
        locations = {
            { zone = "Swamp of Sorrows", areaID = 8, mapID = 38, x = 48.53, y = 55.85 },
        },
    },
    [1430] = {
        name = "Tomas",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 44.37, y = 65.99 },
        },
    },
    [1448] = {
        name = "Neal Allen",
        faction = "alliance",
        locations = {
            { zone = "Wetlands", areaID = 11, mapID = 40, x = 10.75, y = 56.75 },
        },
    },
    [1454] = {
        name = "Jennabink Powerseam",
        faction = "alliance",
        locations = {
            { zone = "Wetlands", areaID = 11, mapID = 40, x = 8.12, y = 55.84 },
        },
    },
    [1465] = {
        name = "Drac Roughcut",
        faction = "alliance",
        locations = {
            { zone = "Loch Modan", areaID = 38, mapID = 35, x = 35.57, y = 49.15 },
        },
    },
    [1470] = {
        name = "Ghak Healtouch",
        faction = "alliance",
        locations = {
            { zone = "Loch Modan", areaID = 38, mapID = 35, x = 37.07, y = 49.38 },
        },
    },
    [1471] = {
        name = "Jannos Ironwill",
        faction = "alliance",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 45.98, y = 47.72 },
        },
    },
    [1474] = {
        name = "Rann Flamespinner",
        faction = "alliance",
        locations = {
            { zone = "Loch Modan", areaID = 38, mapID = 35, x = 35.95, y = 45.87 },
        },
    },
    [1632] = {
        name = "Adele Fielder",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 46.38, y = 62.05 },
        },
    },
    [1669] = {
        name = "Defias Profiteer",
        faction = "neutral",
        locations = {
            { zone = "Westfall", areaID = 40, mapID = 39, x = 43.47, y = 66.76 },
        },
    },
    [1676] = {
        name = "Finbus Geargrind",
        faction = "alliance",
        locations = {
            { zone = "Duskwood", areaID = 10, mapID = 34, x = 77.38, y = 48.82 },
        },
    },
    [1684] = {
        name = "Khara Deepwater",
        faction = "alliance",
        locations = {
            { zone = "Loch Modan", areaID = 38, mapID = 35, x = 40.28, y = 39.28 },
        },
    },
    [1685] = {
        name = "Xandar Goodbeard",
        faction = "alliance",
        locations = {
            { zone = "Loch Modan", areaID = 38, mapID = 35, x = 82.47, y = 63.35 },
        },
    },
    [1699] = {
        name = "Gremlock Pilsnor",
        faction = "alliance",
        locations = {
            { zone = "Dun Morogh", areaID = 1, mapID = 27, x = 47.67, y = 52.31 },
        },
    },
    [1702] = {
        name = "Bronk Guzzlegear",
        faction = "alliance",
        locations = {
            { zone = "Dun Morogh", areaID = 1, mapID = 27, x = 50.18, y = 50.38 },
        },
    },
    [2118] = {
        name = "Abigail Shiel",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 61.03, y = 52.37 },
        },
    },
    [2132] = {
        name = "Carolai Anise",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 59.43, y = 52.19 },
        },
    },
    [2326] = {
        name = "Thamner Pol",
        faction = "alliance",
        locations = {
            { zone = "Dun Morogh", areaID = 1, mapID = 27, x = 47.18, y = 52.61 },
        },
    },
    [2327] = {
        name = "Shaina Fuller",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 53.00, y = 44.67 },
        },
    },
    [2329] = {
        name = "Michelle Belle",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 43.39, y = 65.55 },
        },
    },
    [2380] = {
        name = "Nandar Branson",
        faction = "alliance",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 50.93, y = 57.10 },
        },
    },
    [2381] = {
        name = "Micha Yance",
        faction = "alliance",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 48.94, y = 55.03 },
        },
    },
    [2383] = {
        name = "Lindea Rabonne",
        faction = "alliance",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 50.63, y = 60.95 },
        },
    },
    [2391] = {
        name = "Serge Hinott",
        faction = "horde",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 61.63, y = 19.19 },
        },
    },
    [2393] = {
        name = "Christoph Jeffcoat",
        faction = "horde",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 62.29, y = 19.04 },
        },
    },
    [2394] = {
        name = "Mallen Swain",
        faction = "horde",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 61.90, y = 20.98 },
        },
    },
    [2397] = {
        name = "Derak Nightfall",
        faction = "horde",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 63.09, y = 19.41 },
        },
    },
    [2399] = {
        name = "Daryl Stack",
        faction = "horde",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 63.75, y = 20.79 },
        },
    },
    [2480] = {
        name = "Bro'kin",
        faction = "neutral",
        locations = {
            { zone = "Alterac Mountains", areaID = 36, mapID = 15, x = 38.24, y = 38.87 },
        },
    },
    [2481] = {
        name = "Bliztik",
        faction = "neutral",
        locations = {
            { zone = "Duskwood", areaID = 10, mapID = 34, x = 18.04, y = 54.36 },
        },
    },
    [2482] = {
        name = "Zarena Cromwind",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.34, y = 75.46 },
        },
    },
    [2483] = {
        name = "Jaquilina Dramet",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 35.75, y = 10.66 },
        },
    },
    [2627] = {
        name = "Grarnik Goodstitch",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.77, y = 76.84 },
        },
    },
    [2663] = {
        name = "Narkk",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.13, y = 74.42 },
        },
    },
    [2664] = {
        name = "Kelsey Yance",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.23, y = 74.34 },
        },
    },
    [2668] = {
        name = "Danielle Zipstitch",
        faction = "alliance",
        locations = {
            { zone = "Duskwood", areaID = 10, mapID = 34, x = 75.87, y = 45.56 },
        },
    },
    [2669] = {
        name = "Sheri Zipstitch",
        faction = "alliance",
        locations = {
            { zone = "Duskwood", areaID = 10, mapID = 34, x = 75.68, y = 45.57 },
        },
    },
    [2670] = {
        name = "Xizk Goodstitch",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.71, y = 76.89 },
        },
    },
    [2672] = {
        name = "Cowardly Crosby",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 27.00, y = 82.48 },
        },
    },
    [2679] = {
        name = "Wenna Silkbeard",
        faction = "alliance",
        locations = {
            { zone = "Wetlands", areaID = 11, mapID = 40, x = 25.61, y = 25.80 },
        },
    },
    [2682] = {
        name = "Fradd Swiftgear",
        faction = "alliance",
        locations = {
            { zone = "Wetlands", areaID = 11, mapID = 40, x = 26.40, y = 25.76 },
        },
    },
    [2684] = {
        name = "Rizz Loosebolt",
        faction = "neutral",
        locations = {
            { zone = "Alterac Mountains", areaID = 36, mapID = 15, x = 47.30, y = 35.16 },
        },
    },
    [2685] = {
        name = "Mazk Snipeshot",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.50, y = 75.12 },
        },
    },
    [2687] = {
        name = "Gnaz Blunderflame",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 50.98, y = 35.21 },
        },
    },
    [2688] = {
        name = "Ruppo Zipcoil",
        faction = "neutral",
        locations = {
            { zone = "The Hinterlands", areaID = 47, mapID = 26, x = 34.33, y = 37.76 },
        },
    },
    [2697] = {
        name = "Clyde Ranthal",
        faction = "alliance",
        locations = {
            { zone = "Redridge Mountains", areaID = 44, mapID = 36, x = 89.02, y = 70.87 },
        },
    },
    [2698] = {
        name = "George Candarte",
        faction = "horde",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 92.02, y = 38.23 },
        },
    },
    [2699] = {
        name = "Rikqiz",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.49, y = 76.05 },
        },
    },
    [2798] = {
        name = "Pand Stonebinder",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 29.69, y = 21.18 },
        },
    },
    [2803] = {
        name = "Malygen",
        faction = "alliance",
        locations = {
            { zone = "Felwood", areaID = 361, mapID = 182, x = 62.32, y = 25.64 },
        },
    },
    [2806] = {
        name = "Bale",
        faction = "horde",
        locations = {
            { zone = "Felwood", areaID = 361, mapID = 182, x = 34.75, y = 53.23 },
        },
    },
    [2810] = {
        name = "Hammon Karwn",
        faction = "alliance",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 46.49, y = 47.41 },
        },
    },
    [2812] = {
        name = "Drovnar Strongbrew",
        faction = "alliance",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 46.32, y = 47.04 },
        },
    },
    [2814] = {
        name = "Narj Deepslice",
        faction = "alliance",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 45.54, y = 47.61 },
        },
    },
    [2816] = {
        name = "Androd Fadran",
        faction = "alliance",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 45.08, y = 46.83 },
        },
    },
    [2818] = {
        name = "Slagg",
        faction = "horde",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 74.08, y = 33.82 },
        },
    },
    [2819] = {
        name = "Tunkk",
        faction = "horde",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 74.86, y = 34.58 },
        },
    },
    [2821] = {
        name = "Keena",
        faction = "horde",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 74.09, y = 32.73 },
        },
    },
    [2836] = {
        name = "Brikk Keencraft",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.99, y = 75.56 },
        },
    },
    [2837] = {
        name = "Jaxin Chong",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.04, y = 77.99 },
        },
    },
    [2838] = {
        name = "Crazk Sparks",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.36, y = 76.66 },
        },
    },
    [2843] = {
        name = "Jutak",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 27.46, y = 77.55 },
        },
    },
    [2846] = {
        name = "Blixrez Goodstitch",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.25, y = 77.54 },
        },
    },
    [2848] = {
        name = "Glyx Brewright",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.14, y = 78.11 },
        },
    },
    [2998] = {
        name = "Karn Stonehoof",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 39.38, y = 55.09 },
        },
    },
    [3004] = {
        name = "Tepa",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 44.52, y = 45.35 },
        },
    },
    [3005] = {
        name = "Mahu",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 43.80, y = 45.12 },
        },
    },
    [3007] = {
        name = "Una",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 41.50, y = 42.57 },
        },
    },
    [3009] = {
        name = "Bena Winterhoof",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 46.62, y = 33.17 },
        },
    },
    [3011] = {
        name = "Teg Dawnstrider",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 44.91, y = 37.49 },
        },
    },
    [3012] = {
        name = "Nata Dawnstrider",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 44.99, y = 38.75 },
        },
    },
    [3026] = {
        name = "Aska Mistrunner",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 50.72, y = 53.11 },
        },
    },
    [3027] = {
        name = "Naal Mistrunner",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 50.99, y = 52.45 },
        },
    },
    [3029] = {
        name = "Sewa Mistrunner",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 55.79, y = 47.02 },
        },
    },
    [3067] = {
        name = "Pyall Silentstride",
        faction = "horde",
        locations = {
            { zone = "Mulgore", areaID = 215, mapID = 9, x = 45.41, y = 58.11 },
        },
    },
    [3069] = {
        name = "Chaw Stronghide",
        faction = "horde",
        locations = {
            { zone = "Mulgore", areaID = 215, mapID = 9, x = 45.44, y = 57.86 },
        },
    },
    [3081] = {
        name = "Wunna Darkmane",
        faction = "horde",
        locations = {
            { zone = "Mulgore", areaID = 215, mapID = 9, x = 46.18, y = 58.18 },
        },
    },
    [3085] = {
        name = "Gloria Femmel",
        faction = "alliance",
        locations = {
            { zone = "Redridge Mountains", areaID = 44, mapID = 36, x = 26.66, y = 43.51 },
        },
    },
    [3087] = {
        name = "Crystal Boughman",
        faction = "alliance",
        locations = {
            { zone = "Redridge Mountains", areaID = 44, mapID = 36, x = 22.78, y = 43.47 },
        },
    },
    [3134] = {
        name = "Kzixx",
        faction = "neutral",
        locations = {
            { zone = "Duskwood", areaID = 10, mapID = 34, x = 81.82, y = 19.77 },
        },
    },
    [3136] = {
        name = "Clarise Gnarltree",
        faction = "alliance",
        locations = {
            { zone = "Duskwood", areaID = 10, mapID = 34, x = 74.00, y = 48.55 },
        },
    },
    [3174] = {
        name = "Dwukk",
        faction = "horde",
        locations = {
            { zone = "Durotar", areaID = 14, mapID = 4, x = 52.03, y = 40.72 },
        },
    },
    [3178] = {
        name = "Stuart Fleming",
        faction = "alliance",
        locations = {
            { zone = "Wetlands", areaID = 11, mapID = 40, x = 8.01, y = 58.33 },
        },
    },
    [3181] = {
        name = "Fremal Doohickey",
        faction = "alliance",
        locations = {
            { zone = "Wetlands", areaID = 11, mapID = 40, x = 10.83, y = 61.37 },
        },
    },
    [3184] = {
        name = "Miao'zan",
        faction = "horde",
        locations = {
            { zone = "Durotar", areaID = 14, mapID = 4, x = 55.41, y = 73.95 },
        },
    },
    [3290] = {
        name = "Deek Fizzlebizz",
        faction = "alliance",
        locations = {
            { zone = "Loch Modan", areaID = 38, mapID = 35, x = 45.91, y = 13.44 },
        },
    },
    [3333] = {
        name = "Shankys",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 69.99, y = 29.77 },
        },
    },
    [3335] = {
        name = "Hagrus",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 45.99, y = 45.68 },
        },
    },
    [3345] = {
        name = "Godan",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 53.90, y = 38.67 },
        },
    },
    [3346] = {
        name = "Kithas",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 53.88, y = 38.02 },
        },
    },
    [3347] = {
        name = "Yelmak",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 56.84, y = 33.03 },
        },
    },
    [3348] = {
        name = "Kor'geld",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 56.05, y = 34.12 },
        },
    },
    [3355] = {
        name = "Saru Steelfury",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 82.35, y = 22.97 },
        },
    },
    [3356] = {
        name = "Sumi",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 82.60, y = 23.96 },
        },
    },
    [3363] = {
        name = "Magar",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 63.65, y = 49.93 },
        },
    },
    [3364] = {
        name = "Borya",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 63.08, y = 51.45 },
        },
    },
    [3365] = {
        name = "Karolek",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 62.81, y = 44.15 },
        },
    },
    [3366] = {
        name = "Tamar",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 63.05, y = 45.53 },
        },
    },
    [3367] = {
        name = "Felika",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 60.60, y = 48.93 },
        },
    },
    [3373] = {
        name = "Arnok",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 34.18, y = 84.58 },
        },
    },
    [3392] = {
        name = "Prospector Khazgorm",
        faction = "alliance",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 47.44, y = 85.75 },
        },
    },
    [3399] = {
        name = "Zamja",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 57.40, y = 53.96 },
        },
    },
    [3400] = {
        name = "Xen'to",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 57.57, y = 52.90 },
        },
    },
    [3413] = {
        name = "Sovik",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 75.49, y = 25.36 },
        },
    },
    [3443] = {
        name = "Grub",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 55.31, y = 31.79 },
        },
    },
    [3478] = {
        name = "Traugh",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 51.30, y = 28.91 },
        },
    },
    [3482] = {
        name = "Tari'qa",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 51.68, y = 30.04 },
        },
    },
    [3484] = {
        name = "Kil'hala",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 52.20, y = 31.70 },
        },
    },
    [3485] = {
        name = "Wrahk",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 52.25, y = 31.69 },
        },
    },
    [3489] = {
        name = "Zargh",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 52.62, y = 29.84 },
        },
    },
    [3490] = {
        name = "Hula'mahi",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 51.39, y = 30.20 },
        },
    },
    [3494] = {
        name = "Tinkerwiz",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 62.67, y = 36.31 },
        },
    },
    [3495] = {
        name = "Gagsprocket",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 62.64, y = 36.27 },
        },
    },
    [3497] = {
        name = "Kilxx",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 62.77, y = 38.24 },
        },
    },
    [3499] = {
        name = "Ranik",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 61.93, y = 38.70 },
        },
    },
    [3522] = {
        name = "Constance Brisboise",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 52.60, y = 55.77 },
        },
    },
    [3523] = {
        name = "Bowen Brisboise",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 52.59, y = 55.52 },
        },
    },
    [3537] = {
        name = "Zixil",
        faction = "neutral",
        locations = {
            { zone = "Hillsbrad Foothills", areaID = 267, mapID = 24, x = 61.97, y = 20.45 },
        },
    },
    [3549] = {
        name = "Shelene Rhobart",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 65.43, y = 60.12 },
        },
    },
    [3550] = {
        name = "Martine Tramblay",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 65.86, y = 59.64 },
        },
    },
    [3556] = {
        name = "Andrew Hilbert",
        faction = "horde",
        locations = {
            { zone = "Silverpine Forest", areaID = 130, mapID = 21, x = 43.22, y = 40.66 },
        },
    },
    [3557] = {
        name = "Guillaume Sorouy",
        faction = "horde",
        locations = {
            { zone = "Silverpine Forest", areaID = 130, mapID = 21, x = 43.20, y = 41.08 },
        },
    },
    [3603] = {
        name = "Cyndra Kindwhisper",
        faction = "alliance",
        locations = {
            { zone = "Teldrassil", areaID = 141, mapID = 41, x = 57.64, y = 60.80 },
        },
    },
    [3605] = {
        name = "Nadyia Maneweaver",
        faction = "alliance",
        locations = {
            { zone = "Teldrassil", areaID = 141, mapID = 41, x = 41.88, y = 49.44 },
        },
    },
    [3606] = {
        name = "Alanna Raveneye",
        faction = "alliance",
        locations = {
            { zone = "Teldrassil", areaID = 141, mapID = 41, x = 36.71, y = 34.16 },
        },
    },
    [3683] = {
        name = "Kiknikle",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 41.79, y = 38.69 },
        },
    },
    [3703] = {
        name = "Krulmoo Fullmoon",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 44.84, y = 59.46 },
        },
    },
    [3704] = {
        name = "Mahani",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 44.93, y = 59.39 },
        },
    },
    [3881] = {
        name = "Grimtak",
        faction = "horde",
        locations = {
            { zone = "Durotar", areaID = 14, mapID = 4, x = 51.13, y = 42.63 },
        },
    },
    [3954] = {
        name = "Dalria",
        faction = "alliance",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 35.12, y = 52.12 },
        },
    },
    [3956] = {
        name = "Harklan Moongrove",
        faction = "alliance",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 50.84, y = 67.00 },
        },
    },
    [3958] = {
        name = "Lardan",
        faction = "alliance",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 34.79, y = 49.84 },
        },
    },
    [3960] = {
        name = "Ulthaan",
        faction = "alliance",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 50.01, y = 66.64 },
        },
    },
    [3964] = {
        name = "Kylanna",
        faction = "alliance",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 50.85, y = 67.11 },
        },
    },
    [3967] = {
        name = "Aayndia Floralwind",
        faction = "alliance",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 35.98, y = 52.10 },
        },
    },
    [4083] = {
        name = "Jeeda",
        faction = "horde",
        locations = {
            { zone = "Stonetalon Mountains", areaID = 406, mapID = 81, x = 47.61, y = 61.59 },
        },
    },
    [4086] = {
        name = "Veenix",
        faction = "neutral",
        locations = {
            { zone = "Stonetalon Mountains", areaID = 406, mapID = 81, x = 58.22, y = 51.74 },
        },
    },
    [4159] = {
        name = "Me'lynn",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 63.41, y = 22.38 },
        },
    },
    [4160] = {
        name = "Ainethil",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 54.88, y = 24.02 },
        },
    },
    [4168] = {
        name = "Elynna",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 64.58, y = 21.58 },
        },
    },
    [4186] = {
        name = "Mavralyn",
        faction = "alliance",
        locations = {
            { zone = "Darkshore", areaID = 148, mapID = 42, x = 37.00, y = 41.20 },
        },
    },
    [4189] = {
        name = "Valdaron",
        faction = "alliance",
        locations = {
            { zone = "Darkshore", areaID = 148, mapID = 42, x = 38.15, y = 40.60 },
        },
    },
    [4193] = {
        name = "Grondal Moonbreeze",
        faction = "alliance",
        locations = {
            { zone = "Darkshore", areaID = 148, mapID = 42, x = 38.24, y = 40.53 },
        },
    },
    [4200] = {
        name = "Laird",
        faction = "alliance",
        locations = {
            { zone = "Darkshore", areaID = 148, mapID = 42, x = 36.77, y = 44.28 },
        },
    },
    [4210] = {
        name = "Alegorn",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 49.03, y = 21.24 },
        },
    },
    [4211] = {
        name = "Dannelor",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 51.71, y = 12.22 },
        },
    },
    [4212] = {
        name = "Telonis",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 64.43, y = 21.54 },
        },
    },
    [4213] = {
        name = "Taladan",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 58.40, y = 13.12 },
        },
    },
    [4223] = {
        name = "Fyldan",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 48.53, y = 21.60 },
        },
    },
    [4225] = {
        name = "Saenorion",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 63.69, y = 22.28 },
        },
    },
    [4226] = {
        name = "Ulthir",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 55.84, y = 24.47 },
        },
    },
    [4228] = {
        name = "Vaean",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 58.57, y = 14.72 },
        },
    },
    [4229] = {
        name = "Mythrin'dir",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 60.96, y = 17.67 },
        },
    },
    [4258] = {
        name = "Bengus Deepforge",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 52.55, y = 41.46 },
        },
    },
    [4265] = {
        name = "Nyoma",
        faction = "alliance",
        locations = {
            { zone = "Teldrassil", areaID = 141, mapID = 41, x = 57.19, y = 61.26 },
        },
    },
    [4305] = {
        name = "Kriggon Talsone",
        faction = "alliance",
        locations = {
            { zone = "Westfall", areaID = 40, mapID = 39, x = 36.23, y = 90.18 },
        },
    },
    [4307] = {
        name = "Heldan Galesong",
        faction = "alliance",
        locations = {
            { zone = "Darkshore", areaID = 148, mapID = 42, x = 36.97, y = 56.35 },
        },
    },
    [4552] = {
        name = "Eunice Burch",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 62.14, y = 44.91 },
        },
    },
    [4553] = {
        name = "Ronald Burch",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 62.31, y = 43.09 },
        },
    },
    [4561] = {
        name = "Daniel Bartlett",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 64.05, y = 37.37 },
        },
    },
    [4574] = {
        name = "Lizbeth Cromwell",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 81.04, y = 30.75 },
        },
    },
    [4576] = {
        name = "Josef Gregorian",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 70.76, y = 30.69 },
        },
    },
    [4577] = {
        name = "Millie Gregorian",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 70.59, y = 30.14 },
        },
    },
    [4578] = {
        name = "Josephine Lister",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 86.65, y = 22.08 },
        },
    },
    [4588] = {
        name = "Arthur Moore",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 70.18, y = 57.42 },
        },
    },
    [4589] = {
        name = "Joseph Moore",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 70.07, y = 58.44 },
        },
    },
    [4591] = {
        name = "Mary Edras",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 73.16, y = 55.15 },
        },
    },
    [4596] = {
        name = "James Van Brunt",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 61.26, y = 30.63 },
        },
    },
    [4610] = {
        name = "Algernon",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 51.71, y = 74.67 },
        },
    },
    [4611] = {
        name = "Doctor Herbert Halsey",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 47.77, y = 73.34 },
        },
    },
    [4616] = {
        name = "Lavinia Crowe",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 62.47, y = 61.80 },
        },
    },
    [4617] = {
        name = "Thaddeus Webb",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 62.38, y = 60.98 },
        },
    },
    [4775] = {
        name = "Felicia Doan",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 64.13, y = 50.56 },
        },
    },
    [4782] = {
        name = "Truk Wildbeard",
        faction = "alliance",
        locations = {
            { zone = "The Hinterlands", areaID = 47, mapID = 26, x = 14.36, y = 42.31 },
        },
    },
    [4877] = {
        name = "Jandia",
        faction = "horde",
        locations = {
            { zone = "Thousand Needles", areaID = 400, mapID = 61, x = 46.21, y = 51.51 },
        },
    },
    [4878] = {
        name = "Montarr",
        faction = "horde",
        locations = {
            { zone = "Thousand Needles", areaID = 400, mapID = 61, x = 45.15, y = 50.79 },
        },
    },
    [4879] = {
        name = "Ogg'marr",
        faction = "horde",
        locations = {
            { zone = "Dustwallow Marsh", areaID = 15, mapID = 141, x = 36.70, y = 30.97 },
        },
    },
    [4897] = {
        name = "Helenia Olden",
        faction = "alliance",
        locations = {
            { zone = "Dustwallow Marsh", areaID = 15, mapID = 141, x = 66.44, y = 51.46 },
        },
    },
    [4900] = {
        name = "Alchemist Narett",
        faction = "alliance",
        locations = {
            { zone = "Dustwallow Marsh", areaID = 15, mapID = 141, x = 63.94, y = 47.64 },
        },
    },
    [5127] = {
        name = "Fimble Finespindle",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 40.24, y = 33.68 },
        },
    },
    [5128] = {
        name = "Bombus Finespindle",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 39.62, y = 34.49 },
        },
    },
    [5150] = {
        name = "Nissa Firestone",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 55.09, y = 58.26 },
        },
    },
    [5153] = {
        name = "Jormund Stonebrow",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 43.15, y = 29.36 },
        },
    },
    [5157] = {
        name = "Gimble Thistlefuzz",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 59.77, y = 45.45 },
        },
    },
    [5158] = {
        name = "Tilli Thistlefuzz",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 61.03, y = 44.00 },
        },
    },
    [5159] = {
        name = "Daryl Riknussun",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 60.08, y = 36.43 },
        },
    },
    [5160] = {
        name = "Emrul Riknussun",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 59.88, y = 37.37 },
        },
    },
    [5162] = {
        name = "Tansy Puddlefizz",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 48.18, y = 6.51 },
        },
    },
    [5163] = {
        name = "Burbik Gearspanner",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 46.40, y = 26.88 },
        },
    },
    [5164] = {
        name = "Grumnus Steelshaper",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 49.96, y = 42.81 },
        },
    },
    [5174] = {
        name = "Springspindle Fizzlegear",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 68.46, y = 43.54 },
        },
    },
    [5175] = {
        name = "Gearcutter Cogspinner",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 67.84, y = 42.50 },
        },
    },
    [5177] = {
        name = "Tally Berryfizz",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 66.62, y = 55.69 },
        },
    },
    [5178] = {
        name = "Soolie Berryfizz",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 66.23, y = 54.52 },
        },
    },
    [5411] = {
        name = "Krinkle Goodsteel",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 51.46, y = 28.81 },
        },
    },
    [5482] = {
        name = "Stephen Ryback",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 78.17, y = 53.10 },
        },
    },
    [5483] = {
        name = "Erika Tate",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 78.53, y = 52.88 },
        },
    },
    [5494] = {
        name = "Catherine Leland",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 55.09, y = 69.76 },
        },
    },
    [5499] = {
        name = "Lilyssia Nightbreeze",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 55.66, y = 86.09 },
        },
    },
    [5511] = {
        name = "Therum Deepforge",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 63.65, y = 37.01 },
        },
    },
    [5512] = {
        name = "Kaita Deepforge",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 63.26, y = 37.74 },
        },
    },
    [5518] = {
        name = "Lilliam Sparkspindle",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 62.09, y = 30.32 },
        },
    },
    [5564] = {
        name = "Simon Tanner",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 71.68, y = 63.00 },
        },
    },
    [5594] = {
        name = "Alchemist Pestlezugg",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 50.89, y = 26.96 },
        },
    },
    [5695] = {
        name = "Vance Undergloom",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 61.77, y = 51.56 },
        },
    },
    [5748] = {
        name = "Killian Sanatha",
        faction = "horde",
        locations = {
            { zone = "Silverpine Forest", areaID = 130, mapID = 21, x = 33.00, y = 17.85 },
        },
    },
    [5757] = {
        name = "Lilly",
        faction = "horde",
        locations = {
            { zone = "Silverpine Forest", areaID = 130, mapID = 21, x = 43.02, y = 50.82 },
        },
    },
    [5758] = {
        name = "Leo Sarn",
        faction = "horde",
        locations = {
            { zone = "Silverpine Forest", areaID = 130, mapID = 21, x = 53.89, y = 82.21 },
        },
    },
    [5759] = {
        name = "Nurse Neela",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 61.82, y = 52.83 },
        },
    },
    [5783] = {
        name = "Kalldan Felmoon",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 45.89, y = 35.70 },
        },
    },
    [5784] = {
        name = "Waldor",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 45.97, y = 35.85 },
        },
    },
    [5939] = {
        name = "Vira Younghoof",
        faction = "horde",
        locations = {
            { zone = "Mulgore", areaID = 215, mapID = 9, x = 46.80, y = 60.85 },
        },
    },
    [5940] = {
        name = "Harn Longcast",
        faction = "horde",
        locations = {
            { zone = "Mulgore", areaID = 215, mapID = 9, x = 47.51, y = 55.06 },
        },
    },
    [5942] = {
        name = "Zansoa",
        faction = "horde",
        locations = {
            { zone = "Durotar", areaID = 14, mapID = 4, x = 56.06, y = 73.39 },
        },
    },
    [5943] = {
        name = "Rawrk",
        faction = "horde",
        locations = {
            { zone = "Durotar", areaID = 14, mapID = 4, x = 54.17, y = 41.93 },
        },
    },
    [5944] = {
        name = "Yonada",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 45.01, y = 59.33 },
        },
    },
    [6094] = {
        name = "Byancie",
        faction = "alliance",
        locations = {
            { zone = "Teldrassil", areaID = 141, mapID = 41, x = 55.29, y = 56.82 },
        },
    },
    [6286] = {
        name = "Zarrin",
        faction = "alliance",
        locations = {
            { zone = "Teldrassil", areaID = 141, mapID = 41, x = 57.12, y = 61.30 },
        },
    },
    [6299] = {
        name = "Delfrum Flintbeard",
        faction = "alliance",
        locations = {
            { zone = "Darkshore", areaID = 148, mapID = 42, x = 38.19, y = 40.93 },
        },
    },
    [6567] = {
        name = "Ghok'kah",
        faction = "horde",
        locations = {
            { zone = "Dustwallow Marsh", areaID = 15, mapID = 141, x = 35.15, y = 30.83 },
        },
    },
    [6568] = {
        name = "Vizzklick",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 51.01, y = 27.36 },
        },
    },
    [6574] = {
        name = "Jun'ha",
        faction = "horde",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 72.69, y = 36.45 },
        },
    },
    [6576] = {
        name = "Brienna Starglow",
        faction = "alliance",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 88.96, y = 45.95 },
        },
    },
    [6730] = {
        name = "Jinky Twizzlefixxit",
        faction = "neutral",
        locations = {
            { zone = "Thousand Needles", areaID = 400, mapID = 61, x = 77.68, y = 77.90 },
        },
    },
    [6731] = {
        name = "Harlown Darkweave",
        faction = "alliance",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 18.23, y = 60.04 },
        },
    },
    [6777] = {
        name = "Zan Shivsproket",
        faction = "neutral",
        locations = {
            { zone = "Alterac Mountains", areaID = 36, mapID = 15, x = 85.95, y = 79.96 },
        },
    },
    [6779] = {
        name = "Smudge Thunderwood",
        faction = "neutral",
        locations = {
            { zone = "Alterac Mountains", areaID = 36, mapID = 15, x = 86.12, y = 79.58 },
        },
    },
    [7230] = {
        name = "Shayis Steelfury",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 80.24, y = 23.44 },
        },
    },
    [7231] = {
        name = "Kelgruk Bloodaxe",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 81.95, y = 18.02 },
        },
    },
    [7232] = {
        name = "Borgus Steelhand",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 59.40, y = 34.26 },
        },
    },
    [7406] = {
        name = "Oglethorpe Obnoticus",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 28.36, y = 76.35 },
        },
    },
    [7733] = {
        name = "Innkeeper Fizzgrimble",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 52.51, y = 27.91 },
        },
    },
    [7852] = {
        name = "Pratt McGrubben",
        faction = "alliance",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 30.63, y = 42.71 },
        },
    },
    [7854] = {
        name = "Jangdor Swiftstrider",
        faction = "horde",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 74.43, y = 42.91 },
        },
    },
    [7866] = {
        name = "Peter Galen",
        faction = "alliance",
        locations = {
            { zone = "Azshara", areaID = 16, mapID = 181, x = 37.59, y = 65.42 },
        },
    },
    [7867] = {
        name = "Thorkaf Dragoneye",
        faction = "horde",
        locations = {
            { zone = "Badlands", areaID = 3, mapID = 17, x = 62.70, y = 57.40 },
        },
    },
    [7868] = {
        name = "Sarah Tanner",
        faction = "alliance",
        locations = {
            { zone = "Searing Gorge", areaID = 51, mapID = 28, x = 63.56, y = 75.97 },
        },
    },
    [7869] = {
        name = "Brumn Winterhoof",
        faction = "horde",
        locations = {
            { zone = "Arathi Highlands", areaID = 45, mapID = 16, x = 28.27, y = 45.09 },
        },
    },
    [7870] = {
        name = "Caryssia Moonhunter",
        faction = "alliance",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 89.42, y = 46.55 },
        },
    },
    [7871] = {
        name = "Se'Jib",
        faction = "horde",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 36.55, y = 34.09 },
        },
    },
    [7940] = {
        name = "Darnall",
        faction = "neutral",
        locations = {
            { zone = "Moonglade", areaID = 493, mapID = 241, x = 51.47, y = 33.25 },
        },
    },
    [7944] = {
        name = "Tinkmaster Overspark",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 69.55, y = 50.33 },
        },
    },
    [7947] = {
        name = "Vivianna",
        faction = "alliance",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 31.30, y = 43.46 },
        },
    },
    [7948] = {
        name = "Kylanna Windwhisper",
        faction = "alliance",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 32.62, y = 43.78 },
        },
    },
    [7949] = {
        name = "Xylinnia Starshine",
        faction = "alliance",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 31.55, y = 44.25 },
        },
    },
    [8125] = {
        name = "Dirge Quikcleave",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 52.63, y = 28.11 },
        },
    },
    [8126] = {
        name = "Nixx Sprocketspring",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 52.48, y = 27.33 },
        },
    },
    [8131] = {
        name = "Blizrik Buckshot",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 50.74, y = 27.53 },
        },
    },
    [8137] = {
        name = "Gikkix",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 66.64, y = 22.08 },
        },
    },
    [8139] = {
        name = "Jabbey",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 67.01, y = 21.99 },
        },
    },
    [8145] = {
        name = "Sheendra Tallgrass",
        faction = "horde",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 74.49, y = 42.73 },
        },
    },
    [8150] = {
        name = "Janet Hommers",
        faction = "alliance",
        locations = {
            { zone = "Desolace", areaID = 405, mapID = 101, x = 66.19, y = 6.57 },
        },
    },
    [8153] = {
        name = "Narv Hidecrafter",
        faction = "horde",
        locations = {
            { zone = "Desolace", areaID = 405, mapID = 101, x = 55.25, y = 56.34 },
        },
    },
    [8157] = {
        name = "Logannas",
        faction = "alliance",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 32.67, y = 44.03 },
        },
    },
    [8158] = {
        name = "Bronk",
        faction = "horde",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 76.06, y = 43.28 },
        },
    },
    [8160] = {
        name = "Nioma",
        faction = "alliance",
        locations = {
            { zone = "The Hinterlands", areaID = 47, mapID = 26, x = 13.30, y = 43.37 },
        },
    },
    [8161] = {
        name = "Harggan",
        faction = "alliance",
        locations = {
            { zone = "The Hinterlands", areaID = 47, mapID = 26, x = 13.42, y = 44.14 },
        },
    },
    [8176] = {
        name = "Gharash",
        faction = "horde",
        locations = {
            { zone = "Swamp of Sorrows", areaID = 8, mapID = 38, x = 45.46, y = 51.41 },
        },
    },
    [8177] = {
        name = "Rartar",
        faction = "horde",
        locations = {
            { zone = "Swamp of Sorrows", areaID = 8, mapID = 38, x = 45.39, y = 56.87 },
        },
    },
    [8178] = {
        name = "Nina Lightbrew",
        faction = "alliance",
        locations = {
            { zone = "Blasted Lands", areaID = 4, mapID = 19, x = 66.87, y = 18.24 },
        },
    },
    [8306] = {
        name = "Duhng",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 55.29, y = 31.78 },
        },
    },
    [8307] = {
        name = "Tarban Hearthgrain",
        faction = "horde",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 55.15, y = 32.09 },
        },
    },
    [8363] = {
        name = "Shadi Mistrunner",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 40.64, y = 64.00 },
        },
    },
    [8508] = {
        name = "Gretta Ganter",
        faction = "alliance",
        locations = {
            { zone = "Dun Morogh", areaID = 1, mapID = 27, x = 31.53, y = 44.65 },
        },
    },
    [8678] = {
        name = "Jubie Gadgetspring",
        faction = "neutral",
        locations = {
            { zone = "Azshara", areaID = 16, mapID = 181, x = 45.28, y = 90.95 },
        },
    },
    [8679] = {
        name = "Knaz Blunderflame",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 51.05, y = 35.23 },
        },
    },
    [8681] = {
        name = "Outfitter Eric",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 43.37, y = 29.31 },
        },
    },
    [8736] = {
        name = "Buzzek Bracketswing",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 52.34, y = 27.72 },
        },
    },
    [8738] = {
        name = "Vazario Linkgrease",
        faction = "neutral",
        locations = {
            { zone = "The Barrens", areaID = 17, mapID = 11, x = 62.69, y = 36.25 },
        },
    },
    [8878] = {
        name = "Muuran",
        faction = "horde",
        locations = {
            { zone = "Desolace", areaID = 405, mapID = 101, x = 55.59, y = 56.50 },
        },
    },
    [9179] = {
        name = "Jazzrik",
        faction = "neutral",
        locations = {
            { zone = "Badlands", areaID = 3, mapID = 17, x = 42.47, y = 52.50 },
        },
    },
    [9544] = {
        name = "Yuka Screwspigot",
        faction = "neutral",
        locations = {
            { zone = "Burning Steppes", areaID = 46, mapID = 29, x = 66.06, y = 21.95 },
        },
    },
    [9584] = {
        name = "Jalane Ayrole",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 40.35, y = 84.62 },
        },
    },
    [9636] = {
        name = "Kireena",
        faction = "horde",
        locations = {
            { zone = "Desolace", areaID = 405, mapID = 101, x = 50.98, y = 53.55 },
        },
    },
    [10118] = {
        name = "Nessa Shadowsong",
        faction = "alliance",
        locations = {
            { zone = "Teldrassil", areaID = 141, mapID = 41, x = 56.26, y = 92.44 },
        },
    },
    [10856] = {
        name = "Argent Quartermaster Hasana",
        faction = "neutral",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 83.26, y = 68.14 },
        },
    },
    [10857] = {
        name = "Argent Quartermaster Lightspark",
        faction = "neutral",
        locations = {
            { zone = "Western Plaguelands", areaID = 28, mapID = 22, x = 42.84, y = 83.72 },
        },
    },
    [10993] = {
        name = "Twizwick Sprocketgrind",
        faction = "neutral",
        locations = {
            { zone = "Mulgore", areaID = 215, mapID = 9, x = 61.86, y = 31.41 },
        },
    },
    [11017] = {
        name = "Roxxik",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 76.17, y = 25.17 },
        },
    },
    [11025] = {
        name = "Mukdrak",
        faction = "horde",
        locations = {
            { zone = "Durotar", areaID = 14, mapID = 4, x = 52.18, y = 40.80 },
        },
    },
    [11031] = {
        name = "Franklin Lloyd",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 76.12, y = 74.03 },
        },
    },
    [11037] = {
        name = "Jenna Lemkenilli",
        faction = "alliance",
        locations = {
            { zone = "Darkshore", areaID = 148, mapID = 42, x = 38.30, y = 41.12 },
        },
    },
    [11052] = {
        name = "Timothy Worthington",
        faction = "alliance",
        locations = {
            { zone = "Dustwallow Marsh", areaID = 15, mapID = 141, x = 66.18, y = 51.81 },
        },
    },
    [11072] = {
        name = "Kitta Firewind",
        faction = "alliance",
        locations = {
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 64.93, y = 70.71 },
        },
    },
    [11074] = {
        name = "Hgarth",
        faction = "horde",
        locations = {
            { zone = "Stonetalon Mountains", areaID = 406, mapID = 81, x = 49.18, y = 57.18 },
        },
    },
    [11097] = {
        name = "Drakk Stonehand",
        faction = "alliance",
        locations = {
            { zone = "The Hinterlands", areaID = 47, mapID = 26, x = 13.39, y = 43.49 },
        },
    },
    [11098] = {
        name = "Hahrana Ironhide",
        faction = "horde",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 74.36, y = 43.12 },
        },
    },
    [11146] = {
        name = "Ironus Coldsteel",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 50.33, y = 43.56 },
        },
    },
    [11177] = {
        name = "Okothos Ironrager",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 79.80, y = 24.06 },
        },
    },
    [11178] = {
        name = "Borgosh Corebender",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 79.41, y = 23.74 },
        },
    },
    [11185] = {
        name = "Xizzer Fizzbolt",
        faction = "neutral",
        locations = {
            { zone = "Winterspring", areaID = 618, mapID = 281, x = 60.80, y = 38.60 },
        },
    },
    [11187] = {
        name = "Himmik",
        faction = "neutral",
        locations = {
            { zone = "Winterspring", areaID = 618, mapID = 281, x = 61.33, y = 39.16 },
        },
    },
    [11189] = {
        name = "Qia",
        faction = "neutral",
        locations = {
            { zone = "Winterspring", areaID = 618, mapID = 281, x = 61.20, y = 37.21 },
        },
    },
    [11278] = {
        name = "Magnus Frostwake",
        faction = "neutral",
        locations = {
            { zone = "Western Plaguelands", areaID = 28, mapID = 22, x = 68.06, y = 77.52 },
        },
    },
    [11536] = {
        name = "Quartermaster Miranda Breechlock",
        faction = "neutral",
        locations = {
            { zone = "Eastern Plaguelands", areaID = 139, mapID = 23, x = 75.84, y = 54.06 },
        },
    },
    [11557] = {
        name = "Meilosh",
        locations = {
            { zone = "Felwood", areaID = 361, mapID = 182, x = 65.69, y = 2.81 },
        },
    },
    [11874] = {
        name = "Masat T'andr",
        faction = "neutral",
        locations = {
            { zone = "Swamp of Sorrows", areaID = 8, mapID = 38, x = 26.46, y = 31.47 },
        },
    },
    [12022] = {
        name = "Lorelae Wintersong",
        faction = "neutral",
        locations = {
            { zone = "Moonglade", areaID = 493, mapID = 241, x = 48.24, y = 40.14 },
        },
    },
    [12033] = {
        name = "Wulan",
        faction = "horde",
        locations = {
            { zone = "Desolace", areaID = 405, mapID = 101, x = 26.17, y = 69.65 },
        },
    },
    [12043] = {
        name = "Kulwia",
        faction = "horde",
        locations = {
            { zone = "Stonetalon Mountains", areaID = 406, mapID = 81, x = 45.39, y = 59.33 },
        },
    },
    [12941] = {
        name = "Jase Farlane",
        faction = "neutral",
        locations = {
            { zone = "Eastern Plaguelands", areaID = 139, mapID = 23, x = 74.85, y = 51.73 },
        },
    },
    [12942] = {
        name = "Leonard Porter",
        faction = "alliance",
        locations = {
            { zone = "Western Plaguelands", areaID = 28, mapID = 22, x = 43.08, y = 84.31 },
        },
    },
    [12943] = {
        name = "Werg Thickblade",
        faction = "horde",
        locations = {
            { zone = "Tirisfal Glades", areaID = 85, mapID = 20, x = 83.30, y = 69.72 },
        },
    },
    [12956] = {
        name = "Zannok Hidepiercer",
        faction = "neutral",
        locations = {
            { zone = "Silithus", areaID = 1377, mapID = 261, x = 82.00, y = 17.74 },
        },
    },
    [12957] = {
        name = "Blimo Gadgetspring",
        faction = "neutral",
        locations = {
            { zone = "Azshara", areaID = 16, mapID = 181, x = 45.21, y = 90.85 },
        },
    },
    [12958] = {
        name = "Gigget Zipcoil",
        faction = "neutral",
        locations = {
            { zone = "The Hinterlands", areaID = 47, mapID = 26, x = 34.46, y = 38.59 },
        },
    },
    [12959] = {
        name = "Nergal",
        faction = "neutral",
        locations = {
            { zone = "Un'Goro Crater", areaID = 490, mapID = 201, x = 43.27, y = 7.73 },
        },
    },
    [12962] = {
        name = "Wik'Tar",
        faction = "horde",
        locations = {
            { zone = "Ashenvale", areaID = 331, mapID = 43, x = 11.71, y = 34.10 },
        },
    },
    [13420] = {
        name = "Penney Copperpinch",
        faction = "neutral",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 53.21, y = 65.89 },
        },
    },
    [13429] = {
        name = "Nardstrum Copperpinch",
        faction = "neutral",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 68.24, y = 38.86 },
        },
    },
    [13432] = {
        name = "Seersa Copperpinch",
        faction = "neutral",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 39.04, y = 61.07 },
        },
    },
    [13433] = {
        name = "Wulmort Jinglepocket",
        faction = "neutral",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 33.70, y = 67.23 },
        },
    },
    [13435] = {
        name = "Khole Jinglepocket",
        faction = "neutral",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 62.24, y = 70.29 },
        },
    },
    [14637] = {
        name = "Zorbin Fandazzle",
        faction = "neutral",
        locations = {
            { zone = "Feralas", areaID = 357, mapID = 121, x = 44.81, y = 43.42 },
        },
    },
    [14738] = {
        name = "Otho Moji'ko",
        faction = "horde",
        locations = {
            { zone = "The Hinterlands", areaID = 47, mapID = 26, x = 79.38, y = 79.08 },
        },
    },
    [14921] = {
        name = "Rin'wosho the Trader",
        faction = "neutral",
        locations = {
            { zone = "Stranglethorn Vale", areaID = 33, mapID = 37, x = 15.07, y = 16.00 },
        },
    },
    [15165] = {
        name = "Haughty Modiste",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 66.56, y = 22.27 },
        },
    },
    [15176] = {
        name = "Vargus",
        faction = "neutral",
        locations = {
            { zone = "Silithus", areaID = 1377, mapID = 261, x = 51.23, y = 38.86 },
        },
    },
    [15179] = {
        name = "Mishta",
        faction = "neutral",
        locations = {
            { zone = "Silithus", areaID = 1377, mapID = 261, x = 49.88, y = 36.33 },
        },
    },
    [15293] = {
        name = "Aendel Windspear",
        faction = "neutral",
        locations = {
            { zone = "Silithus", areaID = 1377, mapID = 261, x = 62.57, y = 49.79 },
        },
    },
    [15400] = {
        name = "Arathel Sunforge",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 59.52, y = 62.60 },
        },
    },
    [15419] = {
        name = "Kania",
        faction = "neutral",
        locations = {
            { zone = "Silithus", areaID = 1377, mapID = 261, x = 51.97, y = 39.70 },
        },
    },
    [15501] = {
        name = "Aleinia",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 48.51, y = 47.42 },
        },
    },
    [15909] = {
        name = "Fariel Starsong",
        faction = "neutral",
        locations = {
            { zone = "Moonglade", areaID = 493, mapID = 241, x = 53.79, y = 35.32 },
        },
    },
    [16160] = {
        name = "Magistrix Eredania",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 38.16, y = 72.61 },
        },
    },
    [16161] = {
        name = "Arcanist Sheynathren",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 38.16, y = 72.50 },
        },
    },
    [16224] = {
        name = "Rathis Tomber",
        faction = "horde",
        locations = {
            { zone = "Ghostlands", areaID = 3433, mapID = 463, x = 47.14, y = 28.30 },
        },
    },
    [16253] = {
        name = "Master Chef Mouldier",
        faction = "horde",
        locations = {
            { zone = "Ghostlands", areaID = 3433, mapID = 463, x = 48.43, y = 30.93 },
        },
    },
    [16262] = {
        name = "Landraelanis",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 49.01, y = 46.99 },
        },
    },
    [16272] = {
        name = "Kanaria",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 48.58, y = 47.58 },
        },
    },
    [16277] = {
        name = "Quarelestra",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 48.57, y = 47.11 },
        },
    },
    [16278] = {
        name = "Sathein",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 53.67, y = 51.10 },
        },
    },
    [16366] = {
        name = "Sempstress Ambershine",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 37.36, y = 71.92 },
        },
    },
    [16583] = {
        name = "Rohok",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 53.13, y = 38.16 },
        },
    },
    [16585] = {
        name = "Cookie One-Eye",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.61, y = 41.21 },
        },
    },
    [16588] = {
        name = "Apothecary Antonivich",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 52.28, y = 36.46 },
        },
    },
    [16624] = {
        name = "Gelanthis",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 90.92, y = 73.34 },
        },
    },
    [16633] = {
        name = "Sedana",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 69.89, y = 23.70 },
        },
    },
    [16635] = {
        name = "Lyna",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 70.18, y = 24.77 },
        },
    },
    [16638] = {
        name = "Deynna",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 55.58, y = 51.04 },
        },
    },
    [16640] = {
        name = "Keelen Sheets",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 57.38, y = 50.09 },
        },
    },
    [16641] = {
        name = "Melaris",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 67.15, y = 19.50 },
        },
    },
    [16642] = {
        name = "Camberon",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 66.73, y = 16.78 },
        },
    },
    [16657] = {
        name = "Feera",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 53.59, y = 90.84 },
        },
    },
    [16662] = {
        name = "Alestus",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 77.81, y = 71.07 },
        },
    },
    [16667] = {
        name = "Danwe",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 76.97, y = 41.10 },
        },
    },
    [16669] = {
        name = "Bemarrin",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 79.38, y = 38.64 },
        },
    },
    [16670] = {
        name = "Eriden",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 80.35, y = 36.13 },
        },
    },
    [16676] = {
        name = "Sylann",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 69.65, y = 71.57 },
        },
    },
    [16677] = {
        name = "Quelis",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 69.30, y = 70.39 },
        },
    },
    [16688] = {
        name = "Lynalis",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 85.04, y = 80.58 },
        },
    },
    [16689] = {
        name = "Zaralda",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 84.76, y = 78.59 },
        },
    },
    [16705] = {
        name = "Altaa",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 28.14, y = 61.90 },
        },
    },
    [16713] = {
        name = "Arras",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 61.32, y = 89.28 },
        },
    },
    [16718] = {
        name = "Phea",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 54.44, y = 26.26 },
        },
    },
    [16719] = {
        name = "Mumman",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 55.75, y = 26.72 },
        },
    },
    [16722] = {
        name = "Egomis",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 39.85, y = 40.20 },
        },
    },
    [16723] = {
        name = "Lucc",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 27.88, y = 60.65 },
        },
    },
    [16724] = {
        name = "Miall",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 60.59, y = 90.00 },
        },
    },
    [16725] = {
        name = "Nahogg",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 40.72, y = 38.76 },
        },
    },
    [16726] = {
        name = "Ockil",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 54.14, y = 92.84 },
        },
    },
    [16728] = {
        name = "Akham",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 67.50, y = 74.57 },
        },
    },
    [16729] = {
        name = "Refik",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 64.41, y = 68.98 },
        },
    },
    [16731] = {
        name = "Nus",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 39.31, y = 22.19 },
        },
    },
    [16748] = {
        name = "Haferet",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 66.56, y = 73.68 },
        },
    },
    [16767] = {
        name = "Neii",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 64.69, y = 68.46 },
        },
    },
    [16782] = {
        name = "Yatheon",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 75.61, y = 40.72 },
        },
    },
    [16823] = {
        name = "Humphry",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 56.73, y = 63.58 },
        },
    },
    [16826] = {
        name = "Sid Limbardi",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.22, y = 63.60 },
        },
    },
    [17214] = {
        name = "Anchorite Fateema",
        faction = "alliance",
        locations = {
            { zone = "Azuremyst Isle", areaID = 3524, mapID = 464, x = 48.39, y = 51.77 },
        },
    },
    [17215] = {
        name = "Daedal",
        faction = "alliance",
        locations = {
            { zone = "Azuremyst Isle", areaID = 3524, mapID = 464, x = 48.39, y = 51.48 },
        },
    },
    [17222] = {
        name = "Artificer Daelo",
        faction = "alliance",
        locations = {
            { zone = "Azuremyst Isle", areaID = 3524, mapID = 464, x = 48.40, y = 50.24 },
        },
    },
    [17245] = {
        name = "Blacksmith Calypso",
        faction = "alliance",
        locations = {
            { zone = "Azuremyst Isle", areaID = 3524, mapID = 464, x = 46.35, y = 71.19 },
        },
    },
    [17246] = {
        name = "\"Cookie\" McWeaksauce",
        faction = "alliance",
        locations = {
            { zone = "Azuremyst Isle", areaID = 3524, mapID = 464, x = 46.69, y = 70.62 },
        },
    },
    [17424] = {
        name = "Anchorite Paetheus",
        faction = "alliance",
        locations = {
            { zone = "Bloodmyst Isle", areaID = 3525, mapID = 476, x = 54.66, y = 53.94 },
        },
    },
    [17442] = {
        name = "Moordo",
        faction = "alliance",
        locations = {
            { zone = "Azuremyst Isle", areaID = 3524, mapID = 464, x = 44.76, y = 23.91 },
        },
    },
    [17487] = {
        name = "Erin Kelly",
        faction = "alliance",
        locations = {
            { zone = "Azuremyst Isle", areaID = 3524, mapID = 464, x = 46.35, y = 70.65 },
        },
    },
    [17512] = {
        name = "Arred",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 45.51, y = 25.31 },
        },
    },
    [17585] = {
        name = "Quartermaster Urgronn",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.90, y = 37.80 },
        },
    },
    [17634] = {
        name = "K. Lee Smallfry",
        faction = "alliance",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 68.65, y = 50.21 },
        },
    },
    [17637] = {
        name = "Mack Diver",
        faction = "horde",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 34.03, y = 50.93 },
        },
    },
    [17657] = {
        name = "Logistics Officer Ulrike",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 56.70, y = 62.64 },
        },
    },
    [17904] = {
        name = "Fedryen Swiftspear",
        faction = "neutral",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 79.26, y = 63.67 },
        },
    },
    [18005] = {
        name = "Haalrun",
        faction = "alliance",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 67.81, y = 47.91 },
        },
    },
    [18011] = {
        name = "Zurai",
        faction = "horde",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 85.28, y = 54.75 },
        },
    },
    [18015] = {
        name = "Gambarinka",
        faction = "horde",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 31.63, y = 49.19 },
        },
    },
    [18017] = {
        name = "Seer Janidi",
        faction = "horde",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 32.38, y = 51.96 },
        },
    },
    [18255] = {
        name = "Apprentice Darius",
        faction = "neutral",
        locations = {
            { zone = "Deadwind Pass", areaID = 41, mapID = 32, x = 46.94, y = 75.40 },
        },
    },
    [18382] = {
        name = "Mycah",
        faction = "neutral",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 17.86, y = 51.14 },
        },
    },
    [18427] = {
        name = "Fazu",
        faction = "alliance",
        locations = {
            { zone = "Bloodmyst Isle", areaID = 3525, mapID = 476, x = 53.42, y = 56.36 },
        },
    },
    [18484] = {
        name = "Wind Trader Lathrai",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 72.22, y = 30.75 },
        },
    },
    [18749] = {
        name = "Dalinna",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 56.57, y = 37.08 },
        },
    },
    [18751] = {
        name = "Kalaen",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 56.78, y = 37.79 },
        },
    },
    [18752] = {
        name = "Zebig",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.78, y = 38.51 },
        },
    },
    [18753] = {
        name = "Felannia",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 52.34, y = 35.98 },
        },
    },
    [18754] = {
        name = "Barim Spilthoof",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 56.22, y = 38.70 },
        },
    },
    [18771] = {
        name = "Brumman",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.11, y = 63.97 },
        },
    },
    [18772] = {
        name = "Hama",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.63, y = 63.71 },
        },
    },
    [18773] = {
        name = "Johan Barnes",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 53.63, y = 66.14 },
        },
    },
    [18774] = {
        name = "Tatiana",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.63, y = 63.68 },
        },
    },
    [18775] = {
        name = "Lebowski",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 55.72, y = 65.59 },
        },
    },
    [18802] = {
        name = "Alchemist Gribble",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 53.80, y = 65.82 },
        },
    },
    [18911] = {
        name = "Juno Dufrain",
        faction = "neutral",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 78.05, y = 66.09 },
        },
    },
    [18951] = {
        name = "Erilia",
        faction = "horde",
        locations = {
            { zone = "Eversong Woods", areaID = 3430, mapID = 462, x = 56.20, y = 54.56 },
        },
    },
    [18957] = {
        name = "Innkeeper Grilka",
        faction = "horde",
        locations = {
            { zone = "Terokkar Forest", areaID = 3519, mapID = 478, x = 48.76, y = 45.05 },
        },
    },
    [18960] = {
        name = "Rungor",
        faction = "horde",
        locations = {
            { zone = "Terokkar Forest", areaID = 3519, mapID = 478, x = 48.74, y = 46.04 },
        },
    },
    [18987] = {
        name = "Gaston",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 54.03, y = 63.56 },
        },
    },
    [18988] = {
        name = "Baxter",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 56.81, y = 37.38 },
        },
    },
    [18990] = {
        name = "Burko",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 22.33, y = 39.42 },
        },
    },
    [18991] = {
        name = "Aresella",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 26.18, y = 62.05 },
        },
    },
    [18993] = {
        name = "Naka",
        faction = "neutral",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 78.51, y = 63.05 },
        },
    },
    [19004] = {
        name = "Vodesiin",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 24.40, y = 38.77 },
        },
    },
    [19015] = {
        name = "Mathar G'ochar",
        faction = "horde",
        locations = {
            { zone = "Nagrand", areaID = 3518, mapID = 477, x = 56.97, y = 40.29 },
        },
    },
    [19017] = {
        name = "Borto",
        faction = "alliance",
        locations = {
            { zone = "Nagrand", areaID = 3518, mapID = 477, x = 53.26, y = 71.88 },
        },
    },
    [19038] = {
        name = "Supply Officer Mills",
        faction = "alliance",
        locations = {
            { zone = "Terokkar Forest", areaID = 3519, mapID = 478, x = 55.73, y = 53.04 },
        },
    },
    [19042] = {
        name = "Leeli Longhaggle",
        faction = "alliance",
        locations = {
            { zone = "Terokkar Forest", areaID = 3519, mapID = 478, x = 57.74, y = 53.37 },
        },
    },
    [19052] = {
        name = "Lorokeem",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 45.59, y = 21.49 },
        },
    },
    [19063] = {
        name = "Hamanar",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 36.02, y = 20.75 },
        },
    },
    [19074] = {
        name = "Skreah",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 45.77, y = 20.00 },
        },
    },
    [19184] = {
        name = "Mildred Fletcher",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 66.72, y = 13.56 },
        },
    },
    [19185] = {
        name = "Jack Trapper",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 62.67, y = 68.15 },
        },
    },
    [19186] = {
        name = "Kylene",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 74.76, y = 30.83 },
        },
    },
    [19187] = {
        name = "Darmari",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 67.26, y = 67.40 },
        },
    },
    [19195] = {
        name = "Jim Saltit",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 63.53, y = 68.27 },
        },
    },
    [19196] = {
        name = "Cro Threadstrong",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 67.36, y = 67.60 },
        },
    },
    [19213] = {
        name = "Eiin",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 66.24, y = 69.28 },
        },
    },
    [19234] = {
        name = "Yurial Soulwater",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 44.28, y = 97.73 },
        },
    },
    [19251] = {
        name = "Enchantress Volali",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.26, y = 92.28 },
        },
    },
    [19252] = {
        name = "High Enchanter Bardolan",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.45, y = 92.39 },
        },
    },
    [19296] = {
        name = "Innkeeper Biribi",
        faction = "alliance",
        locations = {
            { zone = "Terokkar Forest", areaID = 3519, mapID = 478, x = 56.70, y = 53.27 },
        },
    },
    [19321] = {
        name = "Quartermaster Endarin",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 47.69, y = 25.71 },
        },
    },
    [19331] = {
        name = "Quartermaster Enuril",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 60.50, y = 64.35 },
        },
    },
    [19341] = {
        name = "Grutah",
        faction = "horde",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 29.63, y = 31.53 },
        },
    },
    [19342] = {
        name = "Krek Cragcrush",
        faction = "horde",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 29.29, y = 30.89 },
        },
    },
    [19351] = {
        name = "Daggle Ironshaper",
        faction = "alliance",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 36.80, y = 54.30 },
        },
    },
    [19369] = {
        name = "Celie Steelwing",
        faction = "alliance",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 37.21, y = 58.50 },
        },
    },
    [19373] = {
        name = "Mari Stonehand",
        faction = "alliance",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 36.79, y = 55.05 },
        },
    },
    [19383] = {
        name = "Captured Gnome",
        faction = "horde",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 32.53, y = 48.10 },
        },
    },
    [19478] = {
        name = "Fera Palerunner",
        faction = "horde",
        locations = {
            { zone = "Blade's Edge Mountains", areaID = 3522, mapID = 475, x = 54.01, y = 55.10 },
        },
    },
    [19521] = {
        name = "Arrond",
        faction = "neutral",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 55.93, y = 58.15 },
        },
    },
    [19537] = {
        name = "Dealer Malij",
        faction = "neutral",
        locations = {
            { zone = "Netherstorm", areaID = 3523, mapID = 479, x = 44.12, y = 34.08 },
        },
    },
    [19539] = {
        name = "Jazdalaad",
        faction = "neutral",
        locations = {
            { zone = "Netherstorm", areaID = 3523, mapID = 479, x = 44.52, y = 34.04 },
        },
    },
    [19540] = {
        name = "Asarnan",
        faction = "neutral",
        locations = {
            { zone = "Netherstorm", areaID = 3523, mapID = 479, x = 44.23, y = 33.66 },
        },
    },
    [19576] = {
        name = "Xyrol",
        faction = "neutral",
        locations = {
            { zone = "Netherstorm", areaID = 3523, mapID = 479, x = 32.48, y = 66.79 },
        },
    },
    [19661] = {
        name = "Viggz Shinesparked",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 64.98, y = 69.76 },
        },
    },
    [19662] = {
        name = "Aaron Hollman",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 64.06, y = 72.04 },
        },
    },
    [19663] = {
        name = "Madame Ruby",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 63.28, y = 71.04 },
        },
    },
    [19694] = {
        name = "Loolruna",
        faction = "alliance",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 68.51, y = 50.21 },
        },
    },
    [19722] = {
        name = "Muheru the Weaver",
        faction = "alliance",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 40.52, y = 28.26 },
        },
    },
    [19775] = {
        name = "Kalinda",
        faction = "horde",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 90.34, y = 73.83 },
        },
    },
    [19778] = {
        name = "Farii",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 44.88, y = 24.23 },
        },
    },
    [19836] = {
        name = "Mixie Farshot",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 61.12, y = 81.40 },
        },
    },
    [19837] = {
        name = "Daga Ramba",
        faction = "horde",
        locations = {
            { zone = "Blade's Edge Mountains", areaID = 3522, mapID = 475, x = 51.07, y = 57.82 },
        },
    },
    [20028] = {
        name = "Doba",
        faction = "alliance",
        locations = {
            { zone = "Zangarmarsh", areaID = 3521, mapID = 467, x = 42.33, y = 27.91 },
        },
    },
    [20096] = {
        name = "Uriku",
        faction = "alliance",
        locations = {
            { zone = "Nagrand", areaID = 3518, mapID = 477, x = 56.21, y = 73.33 },
        },
    },
    [20097] = {
        name = "Nula the Butcher",
        faction = "horde",
        locations = {
            { zone = "Nagrand", areaID = 3518, mapID = 477, x = 58.13, y = 35.67 },
        },
    },
    [20124] = {
        name = "Kradu Grimblade",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 69.31, y = 43.24 },
        },
    },
    [20125] = {
        name = "Zula Slagfury",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 69.82, y = 41.98 },
        },
    },
    [20240] = {
        name = "Trader Narasu",
        faction = "alliance",
        locations = {
            { zone = "Nagrand", areaID = 3518, mapID = 477, x = 54.54, y = 75.15 },
        },
    },
    [20242] = {
        name = "Karaaz",
        faction = "neutral",
        locations = {
            { zone = "Netherstorm", areaID = 3523, mapID = 479, x = 43.64, y = 34.30 },
        },
    },
    [20916] = {
        name = "Xerintha Ravenoak",
        faction = "neutral",
        locations = {
            { zone = "Blade's Edge Mountains", areaID = 3522, mapID = 475, x = 62.48, y = 40.34 },
        },
    },
    [21087] = {
        name = "Grikka",
        faction = "horde",
        locations = {
            { zone = "Blade's Edge Mountains", areaID = 3522, mapID = 475, x = 76.87, y = 65.49 },
        },
    },
    [21113] = {
        name = "Sassa Weldwell",
        faction = "alliance",
        locations = {
            { zone = "Blade's Edge Mountains", areaID = 3522, mapID = 475, x = 61.26, y = 68.89 },
        },
    },
    [21209] = {
        name = "Dumphry",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 51.12, y = 60.30 },
        },
    },
    [21432] = {
        name = "Almaador",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 50.97, y = 41.70 },
        },
    },
    [21493] = {
        name = "Kablamm Farflinger",
        faction = "neutral",
        locations = {
            { zone = "Netherstorm", areaID = 3523, mapID = 479, x = 32.96, y = 63.71 },
        },
    },
    [21494] = {
        name = "Smiles O'Byron",
        faction = "neutral",
        locations = {
            { zone = "Blade's Edge Mountains", areaID = 3522, mapID = 475, x = 60.36, y = 65.18 },
        },
    },
    [21643] = {
        name = "Alurmi",
        faction = "neutral",
        locations = {
            { zone = "Tanaris", areaID = 440, mapID = 161, x = 63.59, y = 57.64 },
        },
    },
    [21655] = {
        name = "Nakodu",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 61.99, y = 68.81 },
        },
    },
    [22208] = {
        name = "Nasmara Moonsong",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 66.55, y = 69.33 },
        },
    },
    [22212] = {
        name = "Andrion Darkspinner",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 66.81, y = 68.13 },
        },
    },
    [22213] = {
        name = "Gidge Spellweaver",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 66.82, y = 68.75 },
        },
    },
    [22477] = {
        name = "Anchorite Ensham",
        faction = "neutral",
        locations = {
            { zone = "Terokkar Forest", areaID = 3519, mapID = 478, x = 30.83, y = 76.11 },
        },
    },
    [23007] = {
        name = "Paulsta'ats",
        faction = "neutral",
        locations = {
            { zone = "Nagrand", areaID = 3518, mapID = 477, x = 30.21, y = 57.14 },
        },
    },
    [23064] = {
        name = "Eebee Jinglepocket",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 51.26, y = 29.68 },
        },
    },
    [23734] = {
        name = "Anchorite Yazmina",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 60.01, y = 61.80 },
        },
    },
    [24868] = {
        name = "Niobe Whizzlespark",
        faction = "neutral",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 36.75, y = 54.98 },
        },
    },
    [25032] = {
        name = "Eldara Dawnrunner",
        faction = "neutral",
        locations = {
            { zone = "Isle of Quel'Danas", areaID = 4080, mapID = 499, x = 47.25, y = 30.81 },
        },
    },
    [25099] = {
        name = "Jonathan Garrett",
        faction = "horde",
        locations = {
            { zone = "Shadowmoon Valley", areaID = 3520, mapID = 473, x = 29.18, y = 28.68 },
        },
    },
    [25277] = {
        name = "Chief Engineer Leveny",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 42.67, y = 53.50 },
        },
    },
    [26564] = {
        name = "Borus Ironbender",
        faction = "horde",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 36.61, y = 47.19 },
        },
    },
    [26569] = {
        name = "Alys Vol'tyr",
        faction = "horde",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 36.20, y = 46.51 },
        },
    },
    [26868] = {
        name = "Provisioner Lorkran",
        faction = "horde",
        locations = {
            { zone = "Grizzly Hills", areaID = 394, mapID = 490, x = 22.69, y = 66.17 },
        },
    },
    [26903] = {
        name = "Lanolis Dewdrop",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 58.35, y = 62.22 },
        },
    },
    [26904] = {
        name = "Rosina Rivet",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 59.59, y = 63.79 },
        },
    },
    [26905] = {
        name = "Brom Brewbaster",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 58.21, y = 62.06 },
        },
    },
    [26906] = {
        name = "Elizabeth Jackson",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 58.60, y = 62.73 },
        },
    },
    [26907] = {
        name = "Tisha Longbridge",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 59.69, y = 64.07 },
        },
    },
    [26911] = {
        name = "Bernadette Dexter",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 59.89, y = 63.55 },
        },
    },
    [26914] = {
        name = "Benjamin Clegg",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 58.57, y = 62.71 },
        },
    },
    [26915] = {
        name = "Ounhulo",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 59.93, y = 63.85 },
        },
    },
    [26916] = {
        name = "Mindri Dinkles",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 58.26, y = 62.45 },
        },
    },
    [26951] = {
        name = "Wilhelmina Renel",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 78.75, y = 28.53 },
        },
    },
    [26952] = {
        name = "Kristen Smythe",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 79.29, y = 28.97 },
        },
    },
    [26953] = {
        name = "Thomas Kolichio",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 78.60, y = 29.49 },
        },
    },
    [26954] = {
        name = "Emil Autumn",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 78.69, y = 28.31 },
        },
    },
    [26955] = {
        name = "Jamesina Watterly",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 78.39, y = 30.06 },
        },
    },
    [26956] = {
        name = "Sally Tompkins",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 79.42, y = 29.34 },
        },
    },
    [26959] = {
        name = "Booker Kells",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 79.38, y = 29.29 },
        },
    },
    [26960] = {
        name = "Carter Tiffens",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 79.36, y = 28.80 },
        },
    },
    [26961] = {
        name = "Gunter Hansen",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 78.30, y = 28.14 },
        },
    },
    [26964] = {
        name = "Alexandra McQueen",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 79.40, y = 30.79 },
        },
    },
    [26969] = {
        name = "Raenah",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.63, y = 53.46 },
        },
    },
    [26972] = {
        name = "Orn Tenderhoof",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.98, y = 54.10 },
        },
    },
    [26975] = {
        name = "Arthur Henslowe",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.76, y = 54.23 },
        },
    },
    [26977] = {
        name = "Adelene Sunlance",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.26, y = 53.97 },
        },
    },
    [26980] = {
        name = "Eorain Dawnstrike",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.14, y = 53.94 },
        },
    },
    [26981] = {
        name = "Crog Steelspine",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 40.74, y = 55.31 },
        },
    },
    [26982] = {
        name = "Geba'li",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.63, y = 53.34 },
        },
    },
    [26987] = {
        name = "Falorn Nightwhisper",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.81, y = 71.96 },
        },
    },
    [26988] = {
        name = "Argo Strongstout",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.16, y = 66.60 },
        },
    },
    [26989] = {
        name = "Rollick MacKreel",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.93, y = 71.54 },
        },
    },
    [26990] = {
        name = "Alexis Marlowe",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.59, y = 71.56 },
        },
    },
    [26991] = {
        name = "Sock Brightbolt",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.74, y = 72.22 },
        },
    },
    [26992] = {
        name = "Brynna Wilson",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.82, y = 66.38 },
        },
    },
    [26995] = {
        name = "Tink Brightbolt",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.56, y = 71.70 },
        },
    },
    [26996] = {
        name = "Awan Iceborn",
        faction = "neutral",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 76.21, y = 36.93 },
        },
    },
    [26997] = {
        name = "Alestos",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.44, y = 72.25 },
        },
    },
    [26998] = {
        name = "Rosemary Bovard",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.51, y = 71.94 },
        },
    },
    [27001] = {
        name = "Darin Goodstitch",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.42, y = 72.34 },
        },
    },
    [27023] = {
        name = "Apothecary Bressa",
        faction = "horde",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 36.20, y = 48.83 },
        },
    },
    [27029] = {
        name = "Apothecary Wormwick",
        faction = "horde",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 76.88, y = 62.10 },
        },
    },
    [27030] = {
        name = "Bradley Towns",
        faction = "horde",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 76.95, y = 62.10 },
        },
    },
    [27034] = {
        name = "Josric Fame",
        faction = "horde",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 75.90, y = 63.26 },
        },
    },
    [27054] = {
        name = "Modoru",
        faction = "alliance",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 28.81, y = 55.90 },
        },
    },
    [27147] = {
        name = "Librarian Erickson",
        faction = "neutral",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 46.73, y = 32.47 },
        },
    },
    [27666] = {
        name = "Ontuvo",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 48.60, y = 40.87 },
        },
    },
    [28693] = {
        name = "Enchanter Nalthanis",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 39.05, y = 39.80 },
        },
    },
    [28694] = {
        name = "Alard Schmied",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 45.33, y = 27.70 },
        },
    },
    [28697] = {
        name = "Timofey Oshenko",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 38.44, y = 25.91 },
        },
    },
    [28699] = {
        name = "Charles Worth",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 36.13, y = 33.55 },
        },
    },
    [28700] = {
        name = "Diane Cannings",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 34.71, y = 28.65 },
        },
    },
    [28701] = {
        name = "Timothy Jones",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 40.68, y = 35.35 },
        },
    },
    [28702] = {
        name = "Professor Pallin",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 41.60, y = 37.17 },
        },
    },
    [28703] = {
        name = "Linzy Blackbolt",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 42.65, y = 32.06 },
        },
    },
    [28705] = {
        name = "Katherine Lee",
        faction = "alliance",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 40.28, y = 66.10 },
        },
    },
    [28706] = {
        name = "Olisarra the Kind",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 36.56, y = 37.30 },
        },
    },
    [28714] = {
        name = "Ildine Sorrowspear",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 38.79, y = 41.53 },
        },
    },
    [28721] = {
        name = "Tiffany Cartier",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 40.78, y = 34.51 },
        },
    },
    [28722] = {
        name = "Bryan Landers",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 38.46, y = 24.98 },
        },
    },
    [28723] = {
        name = "Larana Drome",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 41.48, y = 36.49 },
        },
    },
    [29233] = {
        name = "Nurse Applewood",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.66, y = 54.34 },
        },
    },
    [29505] = {
        name = "Imindril Spearsong",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 45.46, y = 28.84 },
        },
    },
    [29506] = {
        name = "Orland Schaeffer",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 44.51, y = 28.16 },
        },
    },
    [29507] = {
        name = "Manfred Staller",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 33.83, y = 29.26 },
        },
    },
    [29508] = {
        name = "Andellion",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 34.29, y = 26.86 },
        },
    },
    [29509] = {
        name = "Namha Moonwater",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 36.07, y = 30.27 },
        },
    },
    [29510] = {
        name = "Linna Bruder",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 34.56, y = 34.83 },
        },
    },
    [29511] = {
        name = "Lalla Brightweave",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 36.61, y = 32.50 },
        },
    },
    [29512] = {
        name = "Ainderu Summerleaf",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 36.47, y = 34.39 },
        },
    },
    [29513] = {
        name = "Didi the Wrench",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 39.65, y = 25.09 },
        },
    },
    [29514] = {
        name = "Findle Whistlesteam",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 39.49, y = 24.77 },
        },
    },
    [29631] = {
        name = "Awilo Lon'gomba",
        faction = "horde",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 69.96, y = 39.01 },
        },
    },
    [29924] = {
        name = "Brandig",
        faction = "alliance",
        locations = {
            { zone = "The Storm Peaks", areaID = 67, mapID = 495, x = 28.85, y = 74.96 },
        },
    },
    [30431] = {
        name = "Veteran Crusader Aliocha Segard",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 87.52, y = 75.58 },
        },
    },
    [30489] = {
        name = "Morgan Day",
        faction = "alliance",
        locations = {
            { zone = "Wintergrasp", areaID = 4197, mapID = 501, x = 48.89, y = 17.48 },
        },
    },
    [30706] = {
        name = "Jo'mah",
        faction = "horde",
        locations = {
            { zone = "Orgrimmar", areaID = 1637, mapID = 321, x = 55.99, y = 46.49 },
        },
    },
    [30709] = {
        name = "Poshken Hardbinder",
        faction = "horde",
        locations = {
            { zone = "Thunder Bluff", areaID = 1638, mapID = 362, x = 29.50, y = 21.41 },
        },
    },
    [30710] = {
        name = "Zantasia",
        faction = "neutral",
        locations = {
            { zone = "Silvermoon City", areaID = 3487, mapID = 480, x = 70.11, y = 24.14 },
        },
    },
    [30711] = {
        name = "Margaux Parchley",
        faction = "horde",
        locations = {
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 61.45, y = 57.83 },
        },
    },
    [30713] = {
        name = "Catarina Stanford",
        faction = "alliance",
        locations = {
            { zone = "Stormwind City", areaID = 1519, mapID = 301, x = 49.83, y = 74.82 },
        },
    },
    [30715] = {
        name = "Feyden Darkin",
        faction = "alliance",
        locations = {
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 59.16, y = 14.07 },
        },
    },
    [30716] = {
        name = "Thoth",
        faction = "alliance",
        locations = {
            { zone = "The Exodar", areaID = 3557, mapID = 471, x = 39.91, y = 38.50 },
        },
    },
    [30717] = {
        name = "Elise Brightletter",
        faction = "alliance",
        locations = {
            { zone = "Ironforge", areaID = 1537, mapID = 341, x = 61.05, y = 45.15 },
        },
    },
    [30721] = {
        name = "Michael Schwan",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 53.99, y = 65.48 },
        },
    },
    [30722] = {
        name = "Neferatti",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 52.25, y = 36.09 },
        },
    },
    [30734] = {
        name = "Jezebel Bican",
        faction = "alliance",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 53.93, y = 65.43 },
        },
    },
    [30735] = {
        name = "Kul Inkspiller",
        faction = "horde",
        locations = {
            { zone = "Hellfire Peninsula", areaID = 3483, mapID = 465, x = 52.49, y = 36.60 },
        },
    },
    [31031] = {
        name = "Misensi",
        faction = "horde",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 69.87, y = 38.40 },
        },
    },
    [31032] = {
        name = "Derek Odds",
        faction = "alliance",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 40.68, y = 65.98 },
        },
    },
    [31910] = {
        name = "Geen",
        faction = "neutral",
        locations = {
            { zone = "Sholazar Basin", areaID = 3711, mapID = 493, x = 54.58, y = 56.12 },
        },
    },
    [31911] = {
        name = "Tanak",
        faction = "neutral",
        locations = {
            { zone = "Sholazar Basin", areaID = 3711, mapID = 493, x = 55.14, y = 69.02 },
        },
    },
    [31916] = {
        name = "Tanaika",
        faction = "neutral",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 25.52, y = 58.71 },
        },
    },
    [32287] = {
        name = "Archmage Alvareaux",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 25.20, y = 47.75 },
        },
    },
    [32294] = {
        name = "Knight Dameron",
        faction = "alliance",
        locations = {
            { zone = "Wintergrasp", areaID = 4197, mapID = 501, x = 51.71, y = 17.25 },
        },
    },
    [32296] = {
        name = "Stone Guard Mukar",
        faction = "horde",
        locations = {
            { zone = "Wintergrasp", areaID = 4197, mapID = 501, x = 51.77, y = 17.30 },
        },
    },
    [32514] = {
        name = "Vanessa Sellers",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 38.41, y = 41.05 },
        },
    },
    [32515] = {
        name = "Braeg Stoutbeard",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 37.35, y = 28.72 },
        },
    },
    [32533] = {
        name = "Cielstrasza",
        faction = "neutral",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 59.95, y = 53.02 },
        },
    },
    [32538] = {
        name = "Duchess Mynx",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 43.39, y = 20.58 },
        },
    },
    [32540] = {
        name = "Lillehoff",
        locations = {
            { zone = "The Storm Peaks", areaID = 67, mapID = 495, x = 66.17, y = 61.43 },
        },
    },
    [32564] = {
        name = "Logistics Officer Silverstone",
        faction = "alliance",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 57.73, y = 66.36 },
        },
    },
    [32565] = {
        name = "Gara Skullcrush",
        faction = "horde",
        locations = {
            { zone = "Borean Tundra", areaID = 3537, mapID = 486, x = 41.42, y = 53.69 },
        },
    },
    [32763] = {
        name = "Sairuk",
        faction = "neutral",
        locations = {
            { zone = "Dragonblight", areaID = 65, mapID = 488, x = 48.47, y = 75.65 },
        },
    },
    [32773] = {
        name = "Logistics Officer Brighton",
        faction = "alliance",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 59.64, y = 63.96 },
        },
    },
    [32774] = {
        name = "Sebastian Crane",
        faction = "horde",
        locations = {
            { zone = "Howling Fjord", areaID = 495, mapID = 491, x = 79.63, y = 30.77 },
        },
    },
    [33580] = {
        name = "Dustin Vail",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 73.04, y = 20.88 },
        },
    },
    [33581] = {
        name = "Kul'de",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 71.79, y = 20.83 },
        },
    },
    [33583] = {
        name = "Fael Morningsong",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 73.04, y = 20.52 },
        },
    },
    [33586] = {
        name = "Binkie Brightgear",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 72.17, y = 20.95 },
        },
    },
    [33587] = {
        name = "Bethany Cromwell",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 72.35, y = 20.98 },
        },
    },
    [33588] = {
        name = "Crystal Brightspark",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 71.61, y = 21.06 },
        },
    },
    [33589] = {
        name = "Joseph Wilson",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 71.38, y = 22.41 },
        },
    },
    [33590] = {
        name = "Oluros",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 71.46, y = 20.90 },
        },
    },
    [33591] = {
        name = "Rekka the Hammer",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 71.87, y = 20.98 },
        },
    },
    [33594] = {
        name = "Fizzix Blastbolt",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 72.21, y = 20.89 },
        },
    },
    [33595] = {
        name = "Mera Mistrunner",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 72.42, y = 20.98 },
        },
    },
    [33602] = {
        name = "Anuur",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 71.36, y = 20.90 },
        },
    },
    [33603] = {
        name = "Arthur Denny",
        faction = "neutral",
        locations = {
            { zone = "Icecrown", areaID = 210, mapID = 492, x = 71.74, y = 20.98 },
        },
    },
    [33608] = {
        name = "Alchemy",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 44.08, y = 90.68 },
        },
    },
    [33609] = {
        name = "Blacksmithing",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.89, y = 90.57 },
        },
    },
    [33610] = {
        name = "Enchanting",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.69, y = 90.45 },
        },
    },
    [33611] = {
        name = "Engineering",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.50, y = 90.34 },
        },
    },
    [33612] = {
        name = "Leatherworking",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.83, y = 90.78 },
        },
    },
    [33613] = {
        name = "Tailoring",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 44.01, y = 90.90 },
        },
    },
    [33614] = {
        name = "Jewelcrafting",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.63, y = 90.66 },
        },
    },
    [33615] = {
        name = "Inscription",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.44, y = 90.53 },
        },
    },
    [33619] = {
        name = "Cooking",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.34, y = 91.13 },
        },
    },
    [33621] = {
        name = "First Aid",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.72, y = 91.40 },
        },
    },
    [33630] = {
        name = "Aelthin",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 38.30, y = 70.97 },
        },
    },
    [33631] = {
        name = "Barien",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.43, y = 65.08 },
        },
    },
    [33633] = {
        name = "Enchantress Andiala",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 55.45, y = 74.76 },
        },
    },
    [33634] = {
        name = "Engineer Sinbei",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 43.89, y = 65.15 },
        },
    },
    [33635] = {
        name = "Daenril",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 41.25, y = 63.11 },
        },
    },
    [33636] = {
        name = "Miralisse",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 41.13, y = 63.48 },
        },
    },
    [33637] = {
        name = "Kirembri Silvermane",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 58.39, y = 75.18 },
        },
    },
    [33638] = {
        name = "Scribe Lanloer",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 55.84, y = 74.36 },
        },
    },
    [33674] = {
        name = "Alchemist Kanhu",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 38.75, y = 30.27 },
        },
    },
    [33675] = {
        name = "Onodo",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 37.64, y = 31.43 },
        },
    },
    [33676] = {
        name = "Zurii",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 36.53, y = 44.17 },
        },
    },
    [33677] = {
        name = "Technician Mihila",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 37.82, y = 31.84 },
        },
    },
    [33679] = {
        name = "Recorder Lidio",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 36.11, y = 43.54 },
        },
    },
    [33680] = {
        name = "Nemiha",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 36.18, y = 48.04 },
        },
    },
    [33681] = {
        name = "Korim",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 37.50, y = 27.66 },
        },
    },
    [33684] = {
        name = "Weaver Aoa",
        faction = "neutral",
        locations = {
            { zone = "Shattrath City", areaID = 3703, mapID = 481, x = 37.71, y = 26.97 },
        },
    },
    [34382] = {
        name = "Chapman",
        faction = "neutral",
        locations = {
            { zone = "Dun Morogh", areaID = 1, mapID = 27, x = 53.93, y = 38.69 },
            { zone = "Elwynn Forest", areaID = 12, mapID = 30, x = 39.06, y = 60.16 },
            { zone = "Durotar", areaID = 14, mapID = 4, x = 47.26, y = 17.83 },
            { zone = "Undercity", areaID = 1497, mapID = 382, x = 68.15, y = 11.16 },
            { zone = "Darnassus", areaID = 1657, mapID = 381, x = 77.40, y = 26.98 },
        },
    },
    [35826] = {
        name = "Kaye Toogie",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 64.66, y = 38.62 },
        },
    },
    [37687] = {
        name = "Alchemist Finklestein",
        faction = "neutral",
        locations = {
            { zone = "Icecrown Citadel", areaID = 4812, mapID = 604, x = 33.75, y = 73.51 },
        },
    },
    [40160] = {
        name = "Frozo the Renowned",
        faction = "neutral",
        locations = {
            { zone = "Dalaran", areaID = 4395, mapID = 504, x = 40.03, y = 28.30 },
        },
    },
}

local trainerGroups = {
    [58] = { 16583, 16823, 19341, 33609, 33631, 33675 },
    [59] = { 26564, 26904, 26952, 26981, 26988, 27034, 28694, 29924, 33591 },
    [60] = { 514, 1241, 2836, 2998, 3136, 3174, 3355, 3478, 3557, 4258, 4596, 5511, 6299, 15400, 16669, 16724, 17245, 21209 },
    [61] = { 1385, 1632, 3007, 3069, 3365, 3549, 3605, 3703, 3967, 4212, 4588, 5127, 5564, 5784, 8153, 11097, 11098, 16278, 16688, 16728, 17442 },
    [62] = { 18754, 18771, 19187, 21087, 33612, 33635, 33681 },
    [63] = { 26996 },
    [64] = { 26911, 26961, 26998, 28700, 33581 },
    [66] = { 16588, 18802, 19052, 27023, 27029, 33608, 33630, 33674 },
    [67] = { 1215, 1386, 1470, 2132, 2391, 2837, 3009, 3184, 3347, 3603, 3964, 4160, 4611, 4900, 5177, 5499, 7948, 16161, 16642, 16723 },
    [68] = { 17215 },
    [72] = { 26914, 26964, 26969, 27001, 28699, 33580 },
    [73] = { 18749, 18772, 33613, 33636, 33684 },
    [74] = { 1103, 1346, 2399, 2627, 3004, 3363, 3484, 3523, 3704, 4159, 4193, 4576, 5153, 11052, 11557, 16366, 16640, 16729, 17487 },
    [75] = { 26905, 26953, 26972, 26989, 28705, 29631, 33587 },
    [76] = { 18987, 18988, 18993 },
    [77] = { 1355, 1382, 1430, 1699, 3026, 3067, 3087, 3399, 4210, 4552, 5159, 5482, 6286, 8306, 16253, 16277, 16676, 16719, 17246, 19185, 19369, 33619, 34708, 34710, 34711, 34712, 34713, 34714, 34785, 34786 },
    [81] = { 23734, 26956, 26992, 28706, 29233, 33589 },
    [82] = { 18990, 18991 },
    [83] = { 2326, 2327, 2329, 2798, 3181, 3373, 4211, 4591, 5150, 5759, 5939, 5943, 6094, 16272, 16662, 16731, 17214, 17424, 19184, 19478, 22477, 33621 },
    [84] = { 17634 },
    [85] = { 18752 },
    [86] = { 18775 },
    [87] = { 19576 },
    [88] = { 17637 },
    [89] = { 25277, 26907, 26955, 26991, 28697, 33586 },
    [90] = { 33677 },
    [91] = { 33611, 33634 },
    [92] = { 1676, 1702, 3290, 3494, 5174, 5518, 8736, 10993, 11017, 11025, 11031, 11037, 16667, 16726, 17222 },
    [93] = { 2818 },
    [95] = { 18753, 18773, 19251, 19252, 19540, 33610, 33633, 33676 },
    [96] = { 1317, 3011, 3345, 3606, 4213, 4616, 5157, 5695, 7949, 11072, 11073, 11074, 16160, 16633, 16725 },
    [103] = { 8126, 8738, 29513 },
    [104] = { 29506 },
    [105] = { 7866, 7867, 29508 },
    [106] = { 7870, 7871, 29509 },
    [107] = { 7868, 7869, 29507 },
    [108] = { 4578, 9584 },
    [109] = { 7406, 7944, 29514 },
    [111] = { 26915, 26960, 26982, 26997, 28701, 33590 },
    [112] = { 18751, 18774, 19063, 19539, 33614, 33637, 33680 },
    [113] = { 15501, 19775, 19778 },
    [114] = { 26906, 26954, 26980, 26990, 28693, 33583 },
    [115] = { 21493 },
    [116] = { 21494 },
    [117] = { 19186 },
    [118] = { 24868, 25099 },
    [119] = { 26916, 26959, 26977, 26995, 28702, 33603 },
    [120] = { 30721, 30722, 33615, 33638, 33679 },
    [121] = { 30706, 30709, 30710, 30711, 30713, 30715, 30716, 30717 },
    [122] = { 26903, 26951, 26975, 26987, 28703, 33588 },
    [123] = { 7231, 7232, 11146, 11178, 20124, 29505 },
    [124] = { 5164, 7230, 11177, 20125 },
    [126] = { 2880 },
}

addonTable.recipeSourceNpcLocations = npcLocations
addonTable.recipeSourceTrainerGroups = trainerGroups

local function appendNpcLocations(result, npcID)
    local npc = npcLocations[tonumber(npcID)]
    if not npc then return end
    for index = 1, table.getn(npc.locations or {}) do
        local source = npc.locations[index]
        table.insert(result, {
            npcID = tonumber(npcID),
            name = npc.name,
            faction = npc.faction,
            zone = source.zone,
            areaID = source.areaID,
            mapID = source.mapID,
            coordinates = { x = source.x, y = source.y },
        })
    end
end

function addonTable.getRecipeSourceLocations(entry)
    if type(entry) ~= "table" then return {} end
    local sourceType = entry.sourceType or entry.source
    local result = {}

    if sourceType == "trainer" then
        local trainerID = tonumber(entry.trainerID or entry.sourceID)
        local npcIDs = trainerID and trainerGroups[trainerID] or nil
        if type(npcIDs) == "table" then
            for index = 1, table.getn(npcIDs) do
                appendNpcLocations(result, npcIDs[index])
            end
        elseif trainerID then
            appendNpcLocations(result, trainerID)
        end
    elseif sourceType == "vendor"
        or sourceType == "limited_vendor"
        or sourceType == "reputation"
    then
        appendNpcLocations(result, entry.vendorID or entry.sourceID)
    end

    return result
end
