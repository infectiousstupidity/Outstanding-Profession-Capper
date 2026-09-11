local addonName, addonTable = ...

-- Conservative built-in acquisition seed from the public AzerothCore WotLK
-- world trainer table. These rows are intentionally small and verifiable;
-- Task 06 can enrich acquisition sources at runtime without bundling another
-- addon's restricted database.

addonTable.registerRecipeAcquisition({
    spellID = 7420,
    profession = "Enchanting",
    sourceType = "trainer",
    sourceName = "Enchanting trainer",
    trainerID = 201009,
    purchasePrice = 50,
    requiredSkill = 15,
    source = "AzerothCore WotLK npc_trainer",
})

addonTable.registerRecipeAcquisition({
    spellID = 7426,
    profession = "Enchanting",
    sourceType = "trainer",
    sourceName = "Enchanting trainer",
    trainerID = 201009,
    purchasePrice = 100,
    requiredSkill = 40,
    source = "AzerothCore WotLK npc_trainer",
})

addonTable.registerRecipeAcquisition({
    key = "profession-rank:Enchanting:125",
    spellID = 7416,
    entryKind = "profession_rank",
    profession = "Enchanting",
    sourceType = "trainer",
    sourceName = "Enchanting trainer",
    trainerID = 201009,
    purchasePrice = 5000,
    requiredSkill = 125,
    requiredLevel = 20,
    notes = "Profession-rank training; requires the preceding Enchanting rank.",
    source = "AzerothCore WotLK npc_trainer",
})

addonTable.recipeAcquisitionDataRevision = "wotlk-3.3.5-2026-09-11"
