local addonTable = {}

local visible = false
local confirmations = 0

function StaticPopup_Visible(which)
    if which == "REPLACE_ENCHANT" and visible then
        return {}
    end
    return nil
end

function ReplaceEnchant()
    confirmations = confirmations + 1
end

assert(loadfile("EnchantConfirmation.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

assertEqual(addonTable.confirmReplaceEnchantIfVisible(), false, "no popup means no confirm")
assertEqual(confirmations, 0, "must not call ReplaceEnchant early")

visible = true
assertEqual(addonTable.confirmReplaceEnchantIfVisible(), true, "visible replace popup confirmed")
assertEqual(confirmations, 1, "ReplaceEnchant called exactly once")

visible = false
assertEqual(addonTable.confirmReplaceEnchantIfVisible(), false, "hidden popup remains untouched")
assertEqual(confirmations, 1, "no extra confirmation")

print("Enchant replacement confirmation tests passed.")
