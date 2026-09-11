local addonName, addonTable = ...

function addonTable.confirmReplaceEnchantIfVisible()
    if type(StaticPopup_Visible) ~= "function" or type(ReplaceEnchant) ~= "function" then
        return false
    end

    if not StaticPopup_Visible("REPLACE_ENCHANT") then
        return false
    end

    ReplaceEnchant()
    return true
end
