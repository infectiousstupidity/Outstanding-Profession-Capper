local addonTable = {}
assert(loadfile("ProfessionBook.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format(
            "%s: expected %s, got %s",
            label,
            tostring(expected),
            tostring(actual)
        ))
    end
end

local scanCount = 0
local liveRefreshCount = 0

local function apply(profession, context)
    local decision = addonTable.prepareProfessionBook(profession, context)
    if decision.action == "scan" then
        scanCount = scanCount + 1
        addonTable.storeProfessionBookSnapshot(profession, {
            [scanCount] = {
                name = profession .. " recipe",
                skillType = "optimal",
                numAvailable = 1,
            },
        }, context)
    elseif decision.action == "refresh_live" then
        liveRefreshCount = liveRefreshCount + 1
        addonTable.markProfessionBookLiveCurrent(profession, context)
    end
    return decision
end

local enchanting = {
    professionName = "Enchanting",
    baseSkill = 352,
    activeSkillModifier = 10,
}

local first = apply("Enchanting", enchanting)
assertEqual(first.action, "scan", "initial open scans")
assertEqual(scanCount, 1, "initial scan count")

local unchanged = apply("Enchanting", enchanting)
assertEqual(unchanged.action, "reuse", "unchanged TRADE_SKILL_UPDATE reuses snapshot")
assertEqual(scanCount, 1, "unchanged update does not rescan")

assertEqual(
    addonTable.noteProfessionBookEvent("BAG_UPDATE", "Enchanting"),
    "preserve",
    "bag update preservation policy"
)
local bag = apply("Enchanting", enchanting)
assertEqual(bag.action, "reuse", "bag update keeps profession book")
assertEqual(scanCount, 1, "bag update does not rescan")

assertEqual(
    addonTable.noteProfessionBookEvent("PRICE_PROVIDER_REVISION", "Enchanting"),
    "preserve",
    "price revision preservation policy"
)
assertEqual(apply("Enchanting", enchanting).action, "reuse", "price change does not rescan")
assertEqual(scanCount, 1, "price change scan count")

local modifierChanged = {
    professionName = "Enchanting",
    baseSkill = 352,
    activeSkillModifier = 15,
}
assertEqual(
    addonTable.noteProfessionBookEvent("PLAYER_EQUIPMENT_CHANGED", "Enchanting"),
    "preserve",
    "modifier equipment event policy"
)
local modifier = apply("Enchanting", modifierChanged)
assertEqual(modifier.action, "reuse", "+profession modifier does not rediscover recipe identity")
assertEqual(scanCount, 1, "modifier change scan count")

local skillChanged = {
    professionName = "Enchanting",
    baseSkill = 353,
    activeSkillModifier = 15,
}
local skill = apply("Enchanting", skillChanged)
assertEqual(skill.action, "refresh_live", "base skill change refreshes live fields only")
assertEqual(scanCount, 1, "base skill change does not full scan")
assertEqual(liveRefreshCount, 1, "base skill live refresh count")

addonTable.noteProfessionBookEvent("LEARNED_SPELL_IN_TAB", "Enchanting")
local learnedState = addonTable.getProfessionBookLifecycleState("Enchanting")
assertEqual(learnedState.identityInvalid, true, "learned recipe invalidates identity")
local learned = apply("Enchanting", skillChanged)
assertEqual(learned.action, "scan", "learned recipe causes rescan")
assertEqual(scanCount, 2, "learned recipe scan count")

local jewelcrafting = {
    professionName = "Jewelcrafting",
    baseSkill = 112,
    activeSkillModifier = 0,
}
local switched = apply("Jewelcrafting", jewelcrafting)
assertEqual(switched.action, "scan", "switching profession scans")
assertEqual(scanCount, 3, "profession switch scan count")

local switchBack = apply("Enchanting", skillChanged)
assertEqual(switchBack.action, "scan", "switching back cannot reuse wrong active snapshot")
assertEqual(scanCount, 4, "switch-back scan count")

local sameProfessionReopen = apply("Enchanting", skillChanged)
assertEqual(sameProfessionReopen.action, "reuse", "same profession reopen reuses session snapshot")
assertEqual(scanCount, 4, "same profession reopen scan count")

local shared = addonTable.getProfessionBookSnapshot("Enchanting")
assert(type(shared) == "table", "snapshot must remain available to all recommendation modes")
for _, mode in ipairs({ "static", "cheapest", "available" }) do
    local modeSnapshot = addonTable.getProfessionBookSnapshot("Enchanting")
    assert(modeSnapshot == shared, mode .. " must consume the same live profession snapshot")
end

addonTable.resetProfessionBookLifecycle()
assertEqual(addonTable.getProfessionBookSnapshot("Enchanting"), nil, "reset clears snapshots")

print("Profession book lifecycle tests passed")
