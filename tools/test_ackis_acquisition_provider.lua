local addonTable = {}
local prices = {}

addonTable.getEffectiveSkillForBase = function(baseSkill, context)
    return (tonumber(baseSkill) or 0) + ((context and tonumber(context.activeSkillModifier)) or 0)
end
addonTable.lookupItemPrice = function(itemID)
    return prices[itemID] or { available = false, unavailableReason = "missing" }
end
addonTable.chooseUsableUnitPrice = function(result, purpose)
    if not result.available then return nil, result.unavailableReason end
    if purpose == "auction" and result.minBuyout then
        return { unitPrice = result.minBuyout, source = "fixture", freshness = "fresh" }
    end
    return nil, "missing"
end

_G.AckisRecipeList = nil

assert(loadfile("RecipeAcquisition.lua"))("Profession_Capper", addonTable)
assert(loadfile("RecipeAcquisitionData.lua"))("Profession_Capper", addonTable)
assert(loadfile("AckisAcquisitionProvider.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local status = addonTable.getRecipeAcquisitionProviderStatus()
assertEqual(status[1].name, "Ackis Recipe List", "provider registered")
assertEqual(status[1].available, false, "provider absent safely")

local baseline = addonTable.resolveRecipeAcquisition(
    7420, {}, { baseSkill = 15, activeSkillModifier = 0 }, {}
)
assertEqual(baseline.available, true, "built-in fallback without ARL")
assertEqual(baseline.goldCost, 50, "built-in price without ARL")
assertEqual(baseline.sourceName, "Enchanting trainer", "built-in source without ARL")

local mode = "normal"
_G.AckisRecipeList = {
    GetRecipeData = function(self, spellID, member)
        if mode == "error" then
            error("simulated ARL failure")
        end
        if spellID == 7420 then
            return { [1] = { [3345] = true, [4616] = true } }
        elseif spellID == 90001 then
            return { [2] = { [777] = true } }
        elseif spellID == 90002 then
            return { [3] = { [888] = true } }
        elseif spellID == 90003 then
            return { acquire_data = { [4] = { [999] = true } } }
        end
        return nil
    end,
}

status = addonTable.getRecipeAcquisitionProviderStatus()
assertEqual(status[1].available, true, "provider detected")

local enriched = addonTable.resolveRecipeAcquisition(
    7420, {}, { baseSkill = 15, activeSkillModifier = 0 }, {}
)
assertEqual(enriched.available, true, "live trainer keeps built-in viability")
assertEqual(enriched.goldCost, 50, "live provider does not erase verified price")
assertEqual(enriched.sourceName, "Enchanting trainer", "richer built-in name retained")
assertEqual(enriched.provider, "Ackis Recipe List", "provider provenance")
assertEqual(enriched.providerSourceIDs[1], 3345, "provider source ID exposed")

local vendor = addonTable.resolveRecipeAcquisition(
    90001, {}, { baseSkill = 1, activeSkillModifier = 0 }, {}
)
assertEqual(vendor.sourceType, "vendor", "ARL vendor normalized")
assertEqual(vendor.available, false, "ARL vendor without known price is not free")
assertEqual(vendor.reason, "missing_acquisition_cost", "ARL vendor safe reason")
assertEqual(vendor.providerSourceIDs[1], 777, "vendor source ID")

local drop = addonTable.resolveRecipeAcquisition(
    90002, {}, { baseSkill = 1, activeSkillModifier = 0 }, {}
)
assertEqual(drop.sourceType, "drop", "ARL mob drop normalized")
assertEqual(drop.available, false, "ARL drop not instant")
assertEqual(drop.reason, "drop_not_guaranteed", "ARL drop safe reason")

local quest = addonTable.resolveRecipeAcquisition(
    90003, {}, { baseSkill = 1, activeSkillModifier = 0 }, {}
)
assertEqual(quest.sourceType, "quest", "whole-record ARL compatibility")
assertEqual(quest.reason, "quest_requirement", "quest normalization")

mode = "error"
local isolated = addonTable.resolveRecipeAcquisition(
    7420, {}, { baseSkill = 15, activeSkillModifier = 0 }, {}
)
assertEqual(isolated.available, true, "provider error falls back")
assertEqual(isolated.goldCost, 50, "provider error preserves built-in")
status = addonTable.getRecipeAcquisitionProviderStatus()
if status[1].lastError == nil then
    error("provider failure should be recorded without escaping")
end

print("Ackis Recipe List acquisition provider tests passed.")
