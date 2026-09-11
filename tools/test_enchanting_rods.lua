local addonTable = {}
local itemCounts = {}
local includeBankSeen = false

function GetItemCount(itemID, includeBank)
    if includeBank then
        includeBankSeen = true
    end
    return itemCounts[itemID] or 0
end

addonTable.Enchanting = {
    ["7418"] = "Enchant Bracer - Minor Health",
    ["7421"] = "Runed Copper Rod",
    ["7795"] = "Runed Silver Rod",
    ["13628"] = "Runed Golden Rod",
    ["13702"] = "Runed Truesilver Rod",
    ["20051"] = "Runed Arcanite Rod",
    ["32664"] = "Runed Fel Iron Rod",
    ["32665"] = "Runed Adamantite Rod",
    ["32667"] = "Runed Eternium Rod",
    ["60619"] = "Runed Titanium Rod",
    ["34002"] = "Enchant Bracer - Assault",
    ["20020"] = "Enchant Boots - Greater Stamina",
    ["60609"] = "Enchant Cloak - Speed",
    ["27958"] = "Enchant Chest - Exceptional Mana",
    ["60616"] = "Enchant Bracers - Striking",
    ["47898"] = "Enchant Cloak - Greater Speed",
}
addonTable.chat_frame_default_color = "FFFFFF"

assert(loadfile("Guide.lua"))("Profession_Capper", addonTable)
assert(loadfile("Professions/Enchanting.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function contains(values, expected)
    if not values then
        return false
    end

    for i = 1, table.getn(values) do
        if values[i] == expected then
            return true
        end
    end

    return false
end

local function assertContains(values, expected, label)
    if not contains(values, expected) then
        error(string.format("%s: expected recipe %s", label, tostring(expected)))
    end
end

local function assertNotContains(values, expected, label)
    if contains(values, expected) then
        error(string.format("%s: did not expect recipe %s", label, tostring(expected)))
    end
end

local function clearItems()
    itemCounts = {}
end

-- With no rod owned, the normal guide still recommends the rod upgrade.
clearItems()
local recipes = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(299)
assertContains(recipes, 20051, "no rod keeps Runed Arcanite")
assertContains(recipes, 32664, "no rod keeps Runed Fel Iron")

-- Owning Runed Arcanite suppresses Arcanite and every lesser rod, but not the next upgrade.
clearItems()
itemCounts[16207] = 1
recipes = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(299)
assertNotContains(recipes, 20051, "owned Arcanite removed")
assertContains(recipes, 32664, "Fel Iron remains relevant after Arcanite")
assertEqual(addonTable.getHighestOwnedEnchantingRodTier(), 5, "Arcanite tier")

-- Owning Runed Fel Iron suppresses both it and all lesser rods.
clearItems()
itemCounts[22461] = 1
recipes = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(299)
assertNotContains(recipes, 20051, "Fel Iron suppresses Arcanite")
assertNotContains(recipes, 32664, "owned Fel Iron removed")
assertContains(recipes, 34002, "normal enchant remains after rods filtered")
assertEqual(addonTable.getHighestOwnedEnchantingRodTier(), 6, "Fel Iron tier")

-- A top-tier rod serves as every lesser rod, so none of the rod steps should be recommended.
clearItems()
itemCounts[44452] = 1
local rodRecipes = {
    [7421] = true,
    [7795] = true,
    [13628] = true,
    [13702] = true,
    [20051] = true,
    [32664] = true,
    [32665] = true,
    [32667] = true,
    [60619] = true,
}
local representativeRanks = {1, 100, 155, 200, 299, 350, 375, 425}
for i = 1, table.getn(representativeRanks) do
    local rank = representativeRanks[i]
    local currentRecipes = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(rank)
    if not currentRecipes then
        error("Titanium ownership left no recommendation at rank " .. tostring(rank))
    end

    for recipeIndex = 1, table.getn(currentRecipes) do
        local spellID = currentRecipes[recipeIndex]
        if rodRecipes[spellID] then
            error("Titanium ownership still recommended obsolete rod recipe " .. tostring(spellID) .. " at rank " .. tostring(rank))
        end
    end
end
assertEqual(addonTable.getHighestOwnedEnchantingRodTier(), 10, "Titanium tier")
assertEqual(includeBankSeen, true, "rod ownership checks include bank")

-- The level-1 rod-only step falls back to a normal enchant instead of returning no route.
recipes, _, target = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(1)
assertEqual(recipes[1], 7418, "level 1 fallback enchant")
assertEqual(target, 2, "level 1 fallback target")

-- A legacy Runed Cobalt Rod, if present on a server, also suppresses every lower rod.
clearItems()
itemCounts[44451] = 1
recipes = addonTable.getEnchantingCurrentSkillLevelRecipeToCraft(375)
assertNotContains(recipes, 32667, "legacy Cobalt suppresses Eternium")
assertEqual(addonTable.getHighestOwnedEnchantingRodTier(), 9, "legacy Cobalt tier")

print("Enchanting rod ownership tests passed.")
