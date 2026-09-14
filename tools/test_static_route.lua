local addonTable = {}

addonTable.getRecipeCatalogRecord = function(spellID)
    local records = {
        [1] = { spellID = 1, name = "Recipe One", outputItemID = 101 },
        [2] = { spellID = 2, name = "Recipe Two", outputItemID = 102 },
        [3] = { spellID = 3, name = "Recipe Three", outputItemID = 103 },
        [4] = { spellID = 4, name = "Recipe Four", outputItemID = 104 },
    }
    return records[spellID]
end

addonTable.getProfessionTrainingSteps = function(profession, currentCap, playerLevel)
    assert(profession == "Test Profession", "profession passed to training lookup")
    assert(currentCap == 75, "current cap passed to training lookup")
    assert(playerLevel == 80, "player level passed to training lookup")
    return {
        {
            atSkill = 50,
            newCap = 150,
            status = "trainable",
            requiredLevel = 10,
        },
    }, 150
end

assert(loadfile("Guide.lua"))("Profession_Capper", addonTable)

addonTable.registerProfessionGuide("Test Profession", {
    {
        minSkill = 1,
        targetSkill = 60,
        recipes = { 1, 2 },
    },
    {
        minSkill = 60,
        targetSkill = 100,
        recipes = { 3, 4 },
    },
}, {
    ["1"] = "Recipe One",
    ["2"] = "Recipe Two",
    ["3"] = "Recipe Three",
    ["4"] = "Recipe Four",
}, {
    recipeIsRelevant = function(spellID, rank)
        if rank < 60 and spellID == 2 then
            return false
        end
        return true
    end,
})

local route = addonTable.buildStaticProfessionRoute(
    "Test Profession",
    40,
    100,
    { currentCap = 75 },
    80
)

assert(route.complete == true, "static route should cover requested range")
assert(route.targetSkill == 100, "static route target")
assert(table.getn(route.segments) == 4, "training boundary should split the guide segment")

local first = route.segments[1]
assert(first.type == "craft", "first segment craft")
assert(first.skillStart == 40 and first.skillEnd == 50, "first craft segment stops at training point")
assert(first.recipeID == 1, "relevance filter preserved")
assert(first.recipe.outputItemID == 101, "catalog output record retained for item tooltip")
assert(first.alternatives == 0, "filtered alternative excluded")

local training = route.segments[2]
assert(training.type == "training", "training row inserted")
assert(training.skillStart == 50, "training shown at correct skill")
assert(training.oldCap == 75 and training.newCap == 150, "training cap transition retained")

local second = route.segments[3]
assert(second.type == "craft", "craft resumes after training")
assert(second.skillStart == 50 and second.skillEnd == 60, "split segment resumes after training")
assert(second.recipeID == 1, "same guide recipe resumes")

local third = route.segments[4]
assert(third.skillStart == 60 and third.skillEnd == 100, "later guide step retained")
assert(third.recipeID == 3, "primary recipe retained")
assert(third.alternatives == 1, "static alternatives retained")
assert(third.recipeNames[2] == "Recipe Four", "alternative name retained")

local overdue = addonTable.buildStaticProfessionRoute(
    "Test Profession",
    55,
    60,
    { currentCap = 75 },
    80
)
assert(overdue.segments[1].type == "training", "overdue rank training should be the first route action")
assert(overdue.segments[1].skillStart == 55, "overdue training is shown as train now")
assert(overdue.segments[2].type == "craft", "craft follows overdue training")
assert(overdue.segments[2].skillStart == 55 and overdue.segments[2].skillEnd == 60, "remaining static step preserved")

print("Static profession route tests passed.")
