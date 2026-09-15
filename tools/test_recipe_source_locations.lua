local addonTable = {}

assert(loadfile("RecipeSourceLocations.lua"))("Profession_Capper", addonTable)
assert(loadfile("MapLocations.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeAcquisition.lua"))("Profession_Capper", addonTable)

local trainerLocations = addonTable.getRecipeSourceLocations({
    sourceType = "trainer",
    trainerID = 114,
})
assert(table.getn(trainerLocations) >= 5, "Grand Master Enchanting trainer group should expose physical trainers")

local foundDalaran = false
for index = 1, table.getn(trainerLocations) do
    local location = trainerLocations[index]
    if location.npcID == 28693 then
        assert(location.name == "Enchanter Nalthanis", "Dalaran trainer name")
        assert(location.zone == "Dalaran", "Dalaran trainer zone")
        assert(location.areaID == 4395, "Dalaran trainer AreaTableID")
        assert(location.mapID == 504, "Dalaran trainer WorldMapAreaID")
        assert(math.abs(location.coordinates.x - 39.05) < 0.01, "Dalaran trainer x coordinate")
        assert(math.abs(location.coordinates.y - 39.80) < 0.01, "Dalaran trainer y coordinate")
        foundDalaran = true
    end
end
assert(foundDalaran, "Dalaran Enchanting trainer should be bundled")

local vendorLocations = addonTable.getRecipeSourceLocations({
    sourceType = "vendor",
    vendorID = 340,
})
assert(table.getn(vendorLocations) >= 1, "known recipe vendor should expose a physical location")
assert(vendorLocations[1].name == "Kendor Kabonka", "vendor name should replace generic numeric source")
assert(vendorLocations[1].zone == "Stormwind City", "vendor zone should be bundled")

local elwynnSource = addonTable.recipeSourceNpcLocations[66]
assert(elwynnSource and elwynnSource.locations[1], "Elwynn source should be bundled")
assert(elwynnSource.locations[1].zone == "Elwynn Forest", "zone parser must not confuse AreaTableID 12 with Questie Events category")
assert(elwynnSource.locations[1].areaID == 12, "Elwynn AreaTableID should be preserved")
assert(elwynnSource.locations[1].mapID == 30, "Elwynn WorldMapAreaID should be bundled")

addonTable.registerRecipeAcquisition({
    spellID = 900001,
    profession = "Enchanting",
    sourceType = "trainer",
    sourceName = "Enchanting trainer",
    trainerID = 114,
    purchasePrice = 50000,
    requiredSkill = 350,
})

local result = addonTable.resolveRecipeAcquisition(
    900001,
    {
        baseSkill = 350,
        currentCap = 450,
        playerLevel = 80,
        faction = "Alliance",
        learnedRecipes = {},
        learnedSpells = {},
        reputation = {},
        inventory = {},
    },
    {
        professionName = "Enchanting",
        baseSkill = 350,
        currentCap = 450,
    },
    {}
)
assert(result.available == true, "located trainer source remains resolvable")
assert(type(result.locations) == "table" and table.getn(result.locations) >= 5, "resolved source carries locations")

local explained = addonTable.explainRecipeAcquisition(
    900001,
    {
        baseSkill = 350,
        currentCap = 450,
        playerLevel = 80,
        faction = "Alliance",
        learnedRecipes = {},
        learnedSpells = {},
        reputation = {},
        inventory = {},
    },
    {
        professionName = "Enchanting",
        baseSkill = 350,
        currentCap = 450,
    },
    {}
)
assert(type(explained.locations) == "table" and table.getn(explained.locations) >= 5, "explained source carries locations")

UnitFactionGroup = function() return "Alliance" end
GetRealZoneText = function() return "Dalaran" end
local usableLocations = addonTable.collectAcquisitionLocations(result)
assert(table.getn(usableLocations) >= 4, "location chooser should expose all faction-compatible trainer alternatives")
assert(usableLocations[1].name == "Enchanter Nalthanis", "current-zone trainer should sort first")
assert(usableLocations[1].mapID == 504, "location chooser must preserve map ID for Show on map")
for index = 1, table.getn(usableLocations) do
    assert(usableLocations[index].faction ~= "horde", "Alliance chooser should filter Horde-only trainers")
end

print("Recipe source location tests passed.")
