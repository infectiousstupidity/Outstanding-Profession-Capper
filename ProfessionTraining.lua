local addonName, addonTable = ...

-- Profession-rank training facts derived from AzerothCore WotLK trainer_spell.
-- Costs are copper. Only ranks above Apprentice are needed because an open
-- profession window already implies the character knows the profession.
local TRAINING = {
    Alchemy = {
        { spellID = 2280, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 10 },
        { spellID = 3465, atSkill = 125, newCap = 225, goldCost = 5000, requiredLevel = 20 },
        { spellID = 11612, atSkill = 200, newCap = 300, goldCost = 50000, requiredLevel = 35 },
        { spellID = 28597, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 51303, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 65 },
    },
    Blacksmithing = {
        { spellID = 2021, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 10 },
        { spellID = 3539, atSkill = 125, newCap = 225, goldCost = 5000, requiredLevel = 20 },
        { spellID = 9786, atSkill = 200, newCap = 300, goldCost = 50000, requiredLevel = 35 },
        { spellID = 29845, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 51298, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 60 },
    },
    Enchanting = {
        { spellID = 7415, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 10 },
        { spellID = 7416, atSkill = 125, newCap = 225, goldCost = 5000, requiredLevel = 20 },
        { spellID = 13921, atSkill = 200, newCap = 300, goldCost = 50000, requiredLevel = 35 },
        { spellID = 28030, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 51312, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 65 },
    },
    Engineering = {
        { spellID = 4040, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 10 },
        { spellID = 4041, atSkill = 125, newCap = 225, goldCost = 5000, requiredLevel = 20 },
        { spellID = 12657, atSkill = 200, newCap = 300, goldCost = 50000, requiredLevel = 35 },
        { spellID = 30351, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 61464, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 65 },
    },
    Leatherworking = {
        { spellID = 2154, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 10 },
        { spellID = 3812, atSkill = 125, newCap = 225, goldCost = 5000, requiredLevel = 20 },
        { spellID = 10663, atSkill = 200, newCap = 300, goldCost = 50000, requiredLevel = 35 },
        { spellID = 32550, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 51301, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 65 },
    },
    Tailoring = {
        { spellID = 3912, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 10 },
        { spellID = 3913, atSkill = 125, newCap = 225, goldCost = 5000, requiredLevel = 20 },
        { spellID = 12181, atSkill = 200, newCap = 300, goldCost = 50000, requiredLevel = 35 },
        { spellID = 26791, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 51308, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 65 },
    },
    Cooking = {
        { spellID = 3412, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 0 },
        { spellID = 54257, atSkill = 125, newCap = 225, goldCost = 1000, requiredLevel = 0 },
        { spellID = 18261, atSkill = 200, newCap = 300, goldCost = 25000, requiredLevel = 0 },
        { spellID = 54256, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 0 },
        { spellID = 51295, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 0 },
    },
    ["First Aid"] = {
        { spellID = 3280, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 0 },
        { spellID = 54254, atSkill = 125, newCap = 225, goldCost = 1000, requiredLevel = 0 },
        { spellID = 10847, atSkill = 200, newCap = 300, goldCost = 25000, requiredLevel = 35 },
        { spellID = 54255, atSkill = 275, newCap = 375, goldCost = 20000, requiredLevel = 0 },
        { spellID = 50299, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 0 },
    },
    Jewelcrafting = {
        { spellID = 25246, atSkill = 50, newCap = 150, goldCost = 500, requiredLevel = 10 },
        { spellID = 28896, atSkill = 125, newCap = 225, goldCost = 5000, requiredLevel = 20 },
        { spellID = 28899, atSkill = 200, newCap = 300, goldCost = 50000, requiredLevel = 35 },
        { spellID = 28901, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 51310, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 60 },
    },
    Inscription = {
        { spellID = 45376, atSkill = 50, newCap = 150, goldCost = 950, requiredLevel = 10 },
        { spellID = 45377, atSkill = 125, newCap = 225, goldCost = 4750, requiredLevel = 20 },
        { spellID = 45378, atSkill = 200, newCap = 300, goldCost = 47500, requiredLevel = 35 },
        { spellID = 45379, atSkill = 275, newCap = 375, goldCost = 100000, requiredLevel = 50 },
        { spellID = 45380, atSkill = 350, newCap = 450, goldCost = 350000, requiredLevel = 65 },
    },
}

addonTable.professionTrainingDataRevision = "azerothcore-wotlk-f1bef3bc-2026-09-13"

function addonTable.getProfessionTrainingSteps(profession, currentCap, playerLevel)
    local source = TRAINING[profession] or {}
    local cap = tonumber(currentCap) or 75
    local level = tonumber(playerLevel)
    local reachableCap = cap
    local steps = {}

    for index = 1, table.getn(source) do
        local row = source[index]
        if row.newCap > cap then
            local levelReady = row.requiredLevel <= 0 or (level and level >= row.requiredLevel)
            table.insert(steps, {
                key = "profession-rank:" .. tostring(profession) .. ":" .. tostring(row.newCap),
                spellID = row.spellID,
                profession = profession,
                atSkill = row.atSkill,
                newCap = row.newCap,
                status = levelReady and "trainable" or "unavailable",
                goldCost = row.goldCost,
                marketCost = row.goldCost,
                requiredLevel = row.requiredLevel,
                sourceType = "trainer",
                sourceName = profession .. " trainer",
            })
            if reachableCap == row.atSkill or reachableCap >= row.atSkill then
                if levelReady then
                    reachableCap = math.max(reachableCap, row.newCap)
                else
                    break
                end
            end
        end
    end

    return steps, reachableCap
end
