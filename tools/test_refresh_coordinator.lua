local addonTable = {}
assert(loadfile("RefreshCoordinator.lua"))("Profession_Capper", addonTable)

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

local coordinator = addonTable.createRefreshCoordinator()
assertEqual(coordinator:isPending(), false, "new coordinator starts idle")

coordinator:schedule(100, 0.20, "BAG_UPDATE")
coordinator:schedule(100.05, 0.20, "BAG_UPDATE")
assertEqual(coordinator:isPending(), true, "duplicate bag events share one pending refresh")
assertEqual(coordinator:getReason(), "BAG_UPDATE", "duplicate reason remains specific")
assertEqual(coordinator:getDeadline(), 100.25, "debounce extends from latest equivalent event")
assertEqual(coordinator:takeIfDue(100.24), nil, "pending refresh cannot dispatch before deadline")
assertEqual(coordinator:takeIfDue(100.25), "BAG_UPDATE", "equivalent event burst dispatches once")
assertEqual(coordinator:isPending(), false, "dispatch clears pending refresh")

local duplicateStats = coordinator:getStats()
assertEqual(duplicateStats.scheduleCount, 2, "duplicate requests are counted")
assertEqual(duplicateStats.coalescedCount, 1, "duplicate request is coalesced")
assertEqual(duplicateStats.dispatchCount, 1, "duplicate event burst creates one expensive refresh")

coordinator:schedule(200, 0.05, "LEARNED_SPELL_IN_TAB")
coordinator:schedule(200.01, 0.05, "BAG_UPDATE")
assertEqual(coordinator:getReason(), "MULTIPLE_EVENTS", "different pending reasons are merged")
coordinator:deferUntil(201)
assertEqual(coordinator:takeIfDue(200.5), nil, "trade-skill mutation can defer pending work")
assertEqual(coordinator:takeIfDue(201), "MULTIPLE_EVENTS", "deferred mixed events dispatch once")

coordinator:schedule(300, 1, "PLAYER_LEVEL_UP")
assertEqual(coordinator:cancel(), true, "cancel reports pending work")
assertEqual(coordinator:isPending(), false, "cancel clears work")
assertEqual(coordinator:cancel(), false, "cancelling idle coordinator is a no-op")

print("Refresh coordinator tests passed")
