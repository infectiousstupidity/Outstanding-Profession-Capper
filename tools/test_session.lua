local addonTable = {}

local now = 100
function GetTime()
    return now
end

local stopped = 0
function StopTradeSkillRepeat()
    stopped = stopped + 1
end

assert(loadfile("Session.lua"))("Profession_Capper", addonTable)

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
    end
end

local targeted = addonTable.startCraftSession(
    100,
    "Enchant Test",
    320,
    5,
    5,
    315,
    {
        mode = "targeted_enchant",
        repeatMode = "fixed",
    }
)

assertEqual(targeted.active, true, "targeted session starts active")
assertEqual(targeted.queued, 5, "targeted queue")
assertEqual(targeted.completed, 0, "targeted completed starts zero")

addonTable.setCraftSessionTarget("bag", 0, 4, 12345)
local target = addonTable.getCraftSessionTarget()
assertEqual(target.kind, "bag", "target kind")
assertEqual(target.bag, 0, "target bag")
assertEqual(target.slot, 4, "target slot")
assertEqual(target.itemID, 12345, "target item")

now = 105
assertEqual(addonTable.handleCraftSucceeded("player", "Enchant Test"), true, "targeted success handled")
targeted = addonTable.getCraftSession()
assertEqual(targeted.completed, 1, "one targeted application completed")
assertEqual(targeted.active, false, "targeted application does not stay stuck active")
assertEqual(targeted.needsContinue, true, "targeted repeat asks for next hardware click")
assertEqual(targeted.finished, false, "targeted repeat not finished early")

assertEqual(addonTable.resumeCraftSession(100), true, "targeted repeat resumes")
assertEqual(addonTable.getCraftSession().active, true, "resumed targeted active")

now = 110
addonTable.handleCraftSucceeded("player", "Enchant Test")
assertEqual(addonTable.getCraftSession().completed, 2, "second targeted application")

local preserved = addonTable.startCraftSession(
    100,
    "Enchant Test",
    320,
    2,
    5,
    315,
    {
        mode = "targeted_enchant",
        repeatMode = "fixed",
    }
)
assertEqual(preserved.target.itemID, 12345, "same enchant preserves remembered target")

addonTable.handleCraftSucceeded("player", "Enchant Test")
addonTable.resumeCraftSession(100)
addonTable.handleCraftSucceeded("player", "Enchant Test")
local finished = addonTable.getCraftSession()
assertEqual(finished.completed, 2, "fixed repeat completes requested count")
assertEqual(finished.active, false, "fixed repeat ends inactive")
assertEqual(finished.needsContinue, false, "fixed repeat no extra continuation")
assertEqual(finished.finished, true, "fixed repeat marked finished")

local auto = addonTable.startCraftSession(
    101,
    "Enchant Auto",
    320,
    20,
    5,
    315,
    {
        mode = "targeted_enchant",
        repeatMode = "until_change",
    }
)
addonTable.handleCraftSucceeded("player", "Enchant Auto")
assertEqual(auto.active, false, "auto targeted pauses after each application")
assertEqual(auto.needsContinue, true, "auto targeted waits for next hardware click")
assertEqual(addonTable.handleCraftRankUpdate(320), "target", "target skill stops repeat")
assertEqual(auto.reachedTarget, true, "auto targeted target reached")
assertEqual(auto.needsContinue, false, "target reached clears continuation")
assertEqual(stopped, 0, "targeted enchant does not call batch stop API")

local batch = addonTable.startCraftSession(200, "Normal Craft", 3, 3, 2, 0)
addonTable.handleCraftSucceeded("player", "Normal Craft")
assertEqual(batch.active, true, "normal batch remains active mid queue")
addonTable.handleCraftSucceeded("player", "Normal Craft")
addonTable.handleCraftSucceeded("player", "Normal Craft")
assertEqual(batch.active, false, "normal batch completes")
assertEqual(batch.needsContinue, true, "normal batch retains existing continuation behavior")

print("Craft session tests passed.")
