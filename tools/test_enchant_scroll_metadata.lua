local addonTable = {}

_G.GetSpellInfo = function()
    error("Task 40 metadata must not use localized spell names")
end
_G.GetItemInfo = function()
    error("Task 40 metadata must not use localized item names")
end

assert(loadfile("RecipeCatalog.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeCatalogData.lua"))("Profession_Capper", addonTable)
assert(loadfile("EnchantScrollData.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local function assertPositiveInteger(value, label)
    assert(type(value) == "number", label .. " must be numeric")
    assert(value > 0 and value == math.floor(value), label .. " must be a positive integer")
end

local provenance = addonTable.enchantScrollMetadataProvenance
assertEqual(provenance.schemaVersion, 1, "schema version")
assertEqual(provenance.recordCount, 301, "record count")
assertEqual(provenance.eligibleCount, 240, "eligible count")
assertEqual(provenance.unknownCount, 1, "unknown count")

local armor = addonTable.enchantVellumCatalog.armor
local weapon = addonTable.enchantVellumCatalog.weapon
assertEqual(armor[1].itemID, 38682, "Armor Vellum")
assertEqual(armor[2].itemID, 37602, "Armor Vellum II")
assertEqual(armor[3].itemID, 43145, "Armor Vellum III")
assertEqual(weapon[1].itemID, 39349, "Weapon Vellum")
assertEqual(weapon[2].itemID, 39350, "Weapon Vellum II")
assertEqual(weapon[3].itemID, 43146, "Weapon Vellum III")
assertEqual(armor[2].maxEnchantLevelRestriction, 35, "tier II level band")
assertEqual(armor[3].maxEnchantLevelRestriction, 60, "tier III level band")

local recipes = addonTable.getRecipeCatalogRecipes("Enchanting")
assertEqual(table.getn(recipes), provenance.recordCount, "catalog coverage")

local metadataCount = 0
for spellID, metadata in pairs(addonTable.enchantScrollMetadata) do
    metadataCount = metadataCount + 1
    assertPositiveInteger(spellID, "spell ID")
    local recipe = addonTable.getRecipeCatalogRecord(spellID)
    assert(recipe ~= nil, "metadata must reference a catalog recipe")

    if metadata.vellumEligible then
        assertPositiveInteger(metadata.scrollItemID, "scroll item ID")
        assert(metadata.targetType == "armor" or metadata.targetType == "weapon", "invalid target type")
        assert(metadata.minVellumTier >= 1 and metadata.minVellumTier <= 3, "invalid vellum tier")
        assertEqual(recipe.outputItemID, metadata.scrollItemID, "eligible scroll/catalog output")
    else
        assert(type(metadata.classification) == "string", "excluded record needs classification")
    end
end
assertEqual(metadataCount, provenance.recordCount, "metadata table size")

for i = 1, table.getn(recipes) do
    assert(
        addonTable.enchantScrollMetadata[recipes[i].spellID] ~= nil,
        "missing metadata for spell " .. tostring(recipes[i].spellID)
    )
end

local gatherer = addonTable.getEnchantScrollMetadata(44506)
assertEqual(gatherer.vellumEligible, true, "Gatherer eligible")
assertEqual(gatherer.scrollItemID, 38960, "Gatherer scroll")
assertEqual(gatherer.targetType, "armor", "Gatherer target")
assertEqual(gatherer.minVellumTier, 3, "Gatherer tier")

local exceptional = addonTable.getEnchantScrollMetadata(44592)
assertEqual(exceptional.vellumEligible, true, "Exceptional Spellpower eligible")
assertEqual(exceptional.scrollItemID, 38979, "Exceptional Spellpower scroll")
assertEqual(exceptional.targetType, "armor", "Exceptional Spellpower target")
assertEqual(exceptional.minVellumTier, 3, "Exceptional Spellpower tier")

local weaponEnchant = addonTable.getEnchantScrollMetadata(59621)
assertEqual(weaponEnchant.vellumEligible, true, "weapon enchant eligible")
assertEqual(weaponEnchant.scrollItemID, 44493, "weapon enchant scroll")
assertEqual(weaponEnchant.targetType, "weapon", "weapon enchant target")
assertEqual(weaponEnchant.minVellumTier, 3, "weapon enchant tier")

local shieldEnchant = addonTable.getEnchantScrollMetadata(34009)
assertEqual(shieldEnchant.vellumEligible, true, "shield enchant eligible")
assertEqual(shieldEnchant.scrollItemID, 38945, "shield enchant scroll")
assertEqual(shieldEnchant.targetType, "armor", "shield uses armor vellum")
assertEqual(shieldEnchant.minVellumTier, 2, "shield enchant tier")

local classicEnchant = addonTable.getEnchantScrollMetadata(7428)
assertEqual(classicEnchant.vellumEligible, true, "classic enchant eligible")
assertEqual(classicEnchant.minVellumTier, 1, "classic enchant tier")

local classicHighLevel = addonTable.getEnchantScrollMetadata(25086)
assertEqual(classicHighLevel.minVellumTier, 2, "classic high-level enchant needs tier II")

local bccHighLevel = addonTable.getEnchantScrollMetadata(27958)
assertEqual(bccHighLevel.minVellumTier, 3, "TBC high-level enchant needs tier III")

local wrathTierTwo = addonTable.getEnchantScrollMetadata(44595)
assertEqual(wrathTierTwo.minVellumTier, 2, "Wrath Scourgebane uses tier II")

local wrathTierOne = addonTable.getEnchantScrollMetadata(71692)
assertEqual(wrathTierOne.minVellumTier, 1, "Wrath Angler uses tier I")

local personal = addonTable.getEnchantScrollMetadata(27920)
assertEqual(personal.vellumEligible, false, "ring enchant excluded")
assertEqual(personal.classification, "personal_enchant", "ring classification")

local rod = addonTable.getEnchantScrollMetadata(32664)
assertEqual(rod.vellumEligible, false, "runed rod excluded")
assertEqual(rod.classification, "non_vellum_craft", "runed rod classification")

local noOutput = addonTable.getEnchantScrollMetadata(7451)
assertEqual(noOutput.vellumEligible, false, "no-output record excluded")
assertEqual(noOutput.classification, "no_output_item", "no-output classification")

local conflict = addonTable.getEnchantScrollMetadata(33996)
assertEqual(conflict.vellumEligible, false, "conflict remains unknown")
assertEqual(conflict.classification, "source_conflict", "conflict classification")
assertEqual(conflict.catalogOutputItemID, 38934, "conflict catalog output")
assertEqual(conflict.crosscheckItemID, 72070, "conflict auxiliary output")

local compatible, minimumTier = addonTable.getCompatibleEnchantVellums(44506)
assertEqual(compatible, armor, "shared compatible vellum table")
assertEqual(minimumTier, 3, "compatible minimum tier")
local none, noneTier = addonTable.getCompatibleEnchantVellums(27920)
assertEqual(none, nil, "excluded enchant compatible set")
assertEqual(noneTier, nil, "excluded enchant minimum tier")

print("Enchant scroll/vellum metadata tests passed.")
