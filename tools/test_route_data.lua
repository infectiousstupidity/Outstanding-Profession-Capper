local addonTable = {}

assert(loadfile("RecipeDifficulty.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeDifficultyData.lua"))("Profession_Capper", addonTable)
assert(loadfile("GeneratedRouteData.lua"))("Profession_Capper", addonTable)
assert(loadfile("RouteData.lua"))("Profession_Capper", addonTable)

local function expectedCandidates(profession, baseSkill, modifier)
    local expected = {}
    for spellID, metadata in pairs(addonTable.recipeDifficultyMetadata) do
        if metadata.profession == profession
            and baseSkill + modifier >= metadata.requiredSkill
            and baseSkill < metadata.graySkill
        then
            table.insert(expected, spellID)
        end
    end
    table.sort(expected)
    return expected
end

local function assertListEqual(actual, expected, label)
    assert(table.getn(actual) == table.getn(expected), label .. " length")
    for index = 1, table.getn(expected) do
        assert(actual[index] == expected[index], label .. " item " .. tostring(index))
    end
end

for _, skill in ipairs({ 0, 200, 352, 440, 449 }) do
    assertListEqual(
        addonTable.getGeneratedRouteCandidateIDs("Enchanting", skill, 10),
        expectedCandidates("Enchanting", skill, 10),
        "Enchanting generated candidates at " .. tostring(skill)
    )
end

local first = addonTable.getGeneratedRouteCandidateIndex("Enchanting", 10)
local second = addonTable.getGeneratedRouteCandidateIndex("Enchanting", 10)
assert(first == second, "candidate index should be cached for the session")

local relevant = addonTable.getGeneratedRouteCandidateSet("Enchanting", 352, 360, 10)
for spellID in pairs(relevant) do
    local metadata = addonTable.getRecipeDifficultyMetadata(spellID)
    assert(metadata and metadata.profession == "Enchanting", "candidate set must stay profession-scoped")
end

for modifier = 0, 30 do
    addonTable.getGeneratedRouteCandidateIndex("Enchanting", modifier)
end
local cacheStats = addonTable.getGeneratedRouteCandidateCacheStats()
assert(
    cacheStats.entries <= cacheStats.maxEntries,
    "generated candidate-index cache must remain bounded"
)
assert(
    cacheStats.queueEntries <= cacheStats.maxQueueEntries,
    "generated candidate-index eviction queue must remain bounded"
)

addonTable.clearGeneratedRouteCandidateCache()
local clearedStats = addonTable.getGeneratedRouteCandidateCacheStats()
assert(clearedStats.entries == 0, "candidate-index cache clear resets entries")
assert(clearedStats.queueEntries == 0, "candidate-index cache clear resets queue")

print("Generated route topology tests passed.")
