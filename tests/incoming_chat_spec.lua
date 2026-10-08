-- Run from the repository root: lua tests/incoming_chat_spec.lua (Lua 5.1).
local now = 1000000
local guilds = { [1] = { 101, "Amber Traders" }, [2] = { 202, "Blue Traders" } }
zo_strlower, zo_strupper = string.lower, string.upper
function zo_strformat(_, value) return (value or ""):gsub("%^[%a]+", "") end
function GetDisplayName() return "@Me" end
function GetUnitName() return "My Character^Mx" end
function GetGuildId(slot) return guilds[slot] and guilds[slot][1] or 0 end
function GetGuildName(id)
    for _, guild in pairs(guilds) do if guild[1] == id then return guild[2] end end
    return ""
end
function GetTimeStamp() return now end
function GetUnitZone() return "Stonefalls" end
function GetNumZones() return 2 end
function GetZoneNameByIndex(index) return ({ "Stonefalls", "Deshaan" })[index] or "" end
function GetZoneId() return 41 end
function GetUnitZoneIndex() return 1 end
function GetParentZoneId(id) return id end
function IsActiveWorldBattleground() return false end
function GetCurrentZoneHouseId() return 0 end
function IsPlayerInAvAWorld() return false end
function IsUnitInDungeon() return false end
function zo_random(low, high) assert(low == 30 and high == 90); return 60 end
function d() end
EVENT_ADD_ON_LOADED, EVENT_CHAT_MESSAGE_CHANNEL = 1, 2
CHAT_CHANNEL_ZONE, CHAT_CHANNEL_SAY, CHAT_CHANNEL_YELL = 3, 0, 1
CHAT_CHANNEL_EMOTE, CHAT_CHANNEL_PARTY = 4, 5
CHAT_CHANNEL_WHISPER, CHAT_CHANNEL_WHISPER_SENT = 2, 6
CHAT_CHANNEL_GUILD_1, CHAT_CHANNEL_GUILD_5 = 12, 16
CHAT_CHANNEL_OFFICER_1, CHAT_CHANNEL_OFFICER_5 = 17, 21
SI_UNIT_NAME = 1
EVENT_MANAGER = { events = {}, updates = {} }
function EVENT_MANAGER:RegisterForEvent(name, event, callback) self.events[name .. event] = callback end
function EVENT_MANAGER:UnregisterForEvent(name, event) self.events[name .. event] = nil end
function EVENT_MANAGER:RegisterForUpdate(name, delay, callback) self.updates[name] = { delay = delay, callback = callback } end
function EVENT_MANAGER:UnregisterForUpdate(name) self.updates[name] = nil end

-- Load the actual manifest order, including the incoming watcher module.
for path in io.lines("SmartChatMsg.txt") do
    path = path:match("^%s*(.-)%s*$")
    if path:match("%.lua$") then dofile(path) end
end
local scm = SmartChatMsg
local function eq(actual, expected, message)
    assert(actual == expected, (message or "unexpected result") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function reset()
    now = 1000000
    scm.savedVars = { commands = { { id = "ad", name = "recruit" }, { id = "other", name = "other" } }, messages = {}, chatChannels = {}, commandGuildSettings = {}, revertChatSeconds = 60 }
    scm.activeReminderStates = {}
    scm.incomingMessageMatchCache = nil
    scm.incomingZoneNames = nil
    scm.pendingRestoreState = nil
    scm.statusPanelVisible = false
    scm.startupQueueCurrent = nil
    EVENT_MANAGER.updates = {}
    local edit = { text = "" }
    function edit:GetText() return self.text end
    function edit:SetText(value) self.text = value end
    function edit:LoseFocus() end
    CHAT_SYSTEM = { textEntry = { EditControl = edit }, channel = CHAT_CHANNEL_SAY }
    function CHAT_SYSTEM:SetChannel(channel) self.channel = channel end
end
local function entry(id, command, guild, text, channel)
    local value = { id = id, commandId = command, guildName = guild, text = text }
    table.insert(scm.savedVars.messages, value)
    scm:SetSavedChatChannel(command, guild, channel or "Zone")
    return value
end
local function incoming(channel, text, sender, display)
    assert(type(scm.HandleIncomingChatMessage) == "function", "incoming-message listener is missing")
    scm:HandleIncomingChatMessage(EVENT_CHAT_MESSAGE_CHANNEL, channel, sender or "Other Character", text, false, display or "@Other")
end
local tests = {}
local function test(name, fn) tests[#tests + 1] = {name, fn} end

test("other player's ad resets the whole combination with real usage time", function()
    local a = entry("a", "ad", "Amber Traders", "%guild% is recruiting!")
    entry("b", "ad", "Amber Traders", "Join %guild% for trials!")
    entry("c", "other", "Amber Traders", "Other notice")
    incoming(CHAT_CHANNEL_ZONE, "Amber Traders is recruiting!")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
    eq(a.useCount, 1)
    eq(scm:GetGuildLastUsedAt("other", "Amber Traders"), nil)
    eq(scm:GetAutoPopulateCooldownEndsAt("ad", "Amber Traders", 41), now + 3660)
    eq(scm.savedVars.activeAutoPopulate, nil)
    eq(scm:IsReminderAutomationActive("ad", "Amber Traders"), false)
end)
test("own account is ignored despite a different sender character", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    incoming(CHAT_CHANNEL_ZONE, "Amber Traders is recruiting!", "Alt Character", "@ME")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
end)
test("own character fallback is ignored without display name", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:HandleIncomingChatMessage(2, 3, "My Character", "Amber Traders is recruiting!", false, "")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
end)
test("anonymous and customer-service messages are ignored", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:HandleIncomingChatMessage(2, 3, "", "Amber Traders is recruiting!", false, "")
    scm:HandleIncomingChatMessage(2, 3, "Other", "Amber Traders is recruiting!", true, "@Other")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
end)
test("guild channel selects the receiver's guild identity", function()
    entry("a", "ad", "Amber Traders", "Trial starts soon!", "Guild")
    entry("b", "ad", "Blue Traders", "Trial starts soon!", "Guild")
    incoming(CHAT_CHANNEL_GUILD_1 + 1, "Trial starts soon!")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    eq(scm:GetGuildLastUsedAt("ad", "Blue Traders"), now)
end)
test("officer chat cannot reset a guild or zone output", function()
    entry("a", "ad", "Amber Traders", "Trial starts soon!", "Guild")
    entry("b", "other", "Amber Traders", "Trial starts soon!", "Officer")
    incoming(CHAT_CHANNEL_OFFICER_1, "Trial starts soon!")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    eq(scm:GetGuildLastUsedAt("other", "Amber Traders"), now)
    eq(scm:GetAutoPopulateCooldownEndsAt("other", "Amber Traders", 99), now + 3660)
end)
test("zone chat ignores guild outputs and resets every matching zone combination once", function()
    local a = entry("a", "ad", "Amber Traders", "Shared trial announcement")
    local b = entry("b", "ad", "Amber Traders", "Shared trial announcement")
    entry("c", "other", "Blue Traders", "Shared trial announcement")
    entry("d", "other", "Amber Traders", "Shared trial announcement", "Guild")
    incoming(CHAT_CHANNEL_ZONE, "Shared trial announcement")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
    eq(scm:GetGuildLastUsedAt("other", "Blue Traders"), now)
    eq(scm:GetGuildLastUsedAt("other", "Amber Traders"), nil)
    eq((a.useCount or 0) + (b.useCount or 0), 1)
end)
test("greeting and zone substitutions can differ but guild cannot", function()
    entry("a", "ad", "Amber Traders", "Good %greeting%! %guild% is recruiting in %zone%.")
    entry("b", "ad", "Blue Traders", "Good %greeting%! %guild% is recruiting in %zone%.")
    incoming(3, "Good evening! Amber Traders is recruiting in Deshaan.")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
    eq(scm:GetGuildLastUsedAt("ad", "Blue Traders"), nil)
end)
test("only valid greetings match", function()
    entry("a", "ad", "Amber Traders", "Good %time%! %guild% is recruiting.")
    incoming(3, "Good whatever! Amber Traders is recruiting.")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
end)
test("countdown varies at the actual insertion position", function()
    entry("a", "ad", "Amber Traders", "%guild% trial Friday at 8 PM EDT. Bring potions (required).")
    incoming(3, "Amber Traders trial Friday at 8 PM EDT (about 1h 55m). Bring potions (required).")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("starting and ending soon are recognized countdowns", function()
    entry("a", "ad", "Amber Traders", "%guild% trial at 8 PM EDT.")
    incoming(3, "Amber Traders trial at 8 PM EDT (starting soon).")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("generated meridiem and timezone are allowed beside a bare time", function()
    entry("a", "ad", "Amber Traders", "%guild% trial tomorrow at 8:30.")
    incoming(3, "Amber Traders trial tomorrow at 8:30 PM PDT (about 1d 2h).")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("event date, time, timezone and unrelated parentheses remain required", function()
    entry("a", "ad", "Amber Traders", "%guild% trial 10/10/2026 at 8 PM EDT (required).")
    for _, text in ipairs({
        "Amber Traders trial 10/11/2026 at 8 PM EDT (about 2h) (required).",
        "Amber Traders trial 10/10/2026 at 9 PM EDT (about 2h) (required).",
        "Amber Traders trial 10/10/2026 at 8 PM PDT (about 2h) (required).",
        "Amber Traders trial 10/10/2026 at 8 PM EDT (about 2h) (optional).",
        "Amber Traders trial 10/10/2026 at 8 PM EDT (buy gold) (required).",
    }) do incoming(3, text); eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil, text) end
end)
test("formatting and link style differ without losing guild-link identity", function()
    entry("a", "ad", "Amber Traders", "Join |H1:guild:101|hAmber Traders|h today!")
    incoming(3, "|cFFFFFFJOIN |H0:guild:202|hBlue Traders|h today!|r")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    incoming(3, "|cFFFFFFJOIN   |H0:guild:101|hAmber Traders|h today!|r")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("substring and similar advertisements do not match", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting for veteran trials.")
    for _, text in ipairs({"Amber Traders", "Blue Traders is recruiting for veteran trials.", "Amber Traders is recruiting for normal trials."}) do
        incoming(3, text)
        eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    end
end)
test("active repeat resets with one random delay and preserves parameters", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:SetGuildReminderMinutes("ad", "Amber Traders", 5)
    scm:SetGuildLastUsedState("ad", "Amber Traders", now - 100, "g1", 1)
    scm:ScheduleCommandReminder("ad", "Amber Traders")
    incoming(3, "Amber Traders is recruiting!")
    local timer = EVENT_MANAGER.updates[scm:GetReminderTimerName("ad", "Amber Traders")]
    eq(timer.delay, 360000)
    eq(scm:GetGuildLastUsedParamText("ad", "Amber Traders"), "g1")
end)
test("zone cooldown includes random delay at both boundaries and display deadline", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    incoming(3, "Amber Traders is recruiting!")
    eq(scm:GetGuildAutoPopulateLastSentAt("ad", "Amber Traders", 41), 1000000)
    now = 1003659
    eq(scm:ShouldSkipAutoPopulateForZone("ad", "Amber Traders", 41), true)
    now = 1003660
    eq(scm:ShouldSkipAutoPopulateForZone("ad", "Amber Traders", 41), false)
    eq(scm:ShouldSkipAutoPopulateForZone("ad", "Amber Traders", 99), false)
end)
test("outgoing restore watcher does not mistake another sender for your send", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:ArmPendingRestoreState({id = CHAT_CHANNEL_SAY}, "Amber Traders is recruiting!", {commandId = "ad", guildName = "Amber Traders", selectedEntryId = "a"})
    scm:HandleRestoreWatcherChatMessage(2, 3, "Other Character", "Amber Traders is recruiting!", false, "@Other")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    assert(scm.pendingRestoreState ~= nil)
end)
test("unchanged pending duplicate is withdrawn but edited chat is preserved", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:ArmPendingRestoreState({id = CHAT_CHANNEL_SAY}, "Amber Traders is recruiting!", {commandId = "ad", guildName = "Amber Traders"})
    CHAT_SYSTEM.textEntry.EditControl.text = "Amber Traders is recruiting!"
    incoming(3, "Amber Traders is recruiting!")
    eq(CHAT_SYSTEM.textEntry.EditControl.text, "")
    eq(scm.pendingRestoreState, nil)
    scm:ArmPendingRestoreState({id = CHAT_CHANNEL_SAY}, "Amber Traders is recruiting!", {commandId = "ad", guildName = "Amber Traders"})
    CHAT_SYSTEM.textEntry.EditControl.text = "My edited notice"
    incoming(3, "Amber Traders is recruiting!")
    eq(CHAT_SYSTEM.textEntry.EditControl.text, "My edited notice")
    eq(scm.pendingRestoreState, nil)
end)
test("edited saved templates invalidate the matching cache", function()
    local a = entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    incoming(3, "Amber Traders is recruiting!")
    a.text = "Amber Traders has a trader!"
    now = now + 10
    incoming(3, "Amber Traders is recruiting!")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), 1000000)
    incoming(3, "Amber Traders has a trader!")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)

test("random delay accepts both inclusive endpoints without changing configured cooldown", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    local originalRandom = zo_random
    for _, delay in ipairs({30, 90}) do
        zo_random = function(low, high) eq(low, 30); eq(high, 90); return delay end
        incoming(3, "Amber Traders is recruiting!")
        eq(scm:GetAutoPopulateCooldownEndsAt("ad", "Amber Traders", 41), now + 3600 + delay)
        eq(scm:GetGuildAutoPopulateCooldownMinutes("ad", "Amber Traders"), 60)
    end
    zo_random = originalRandom
end)
test("peer cooldown survives saved-variable initialization and retains each zone", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    incoming(3, "Amber Traders is recruiting!")
    local originalZone = scm.GetPlayerZoneId
    scm.GetPlayerZoneId = function() return 99 end
    now = now + 10
    incoming(3, "Amber Traders is recruiting!")
    scm.GetPlayerZoneId = originalZone
    ZO_SavedVars = { NewAccountWide = function() return scm.savedVars end }
    scm:InitializeSavedVars()
    eq(scm:GetAutoPopulateCooldownEndsAt("ad", "Amber Traders", 41), 1003660)
    eq(scm:GetAutoPopulateCooldownEndsAt("ad", "Amber Traders", 99), 1003670)
end)
test("normal own sends still confirm and use the unchanged repeat interval", function()
    local a = entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:SetGuildReminderMinutes("ad", "Amber Traders", 5)
    scm:ArmPendingRestoreState({id = CHAT_CHANNEL_SAY}, a.text, {commandId = "ad", guildName = "Amber Traders", selectedEntryId = "a"})
    scm:HandleRestoreWatcherChatMessage(2, 3, "My Character", a.text, false, "@Me")
    eq(a.useCount, 1)
    eq(scm.pendingRestoreState, nil)
    eq(EVENT_MANAGER.updates[scm:GetReminderTimerName("ad", "Amber Traders")].delay, 300000)
end)
test("watcher registration survives clearing the outgoing watcher", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:RegisterIncomingChatWatcher()
    scm:ClearPendingRestoreState()
    local listener = EVENT_MANAGER.events[scm.name .. "_IncomingChat" .. EVENT_CHAT_MESSAGE_CHANNEL]
    assert(listener, "incoming watcher must remain active between sends")
    listener(2, 3, "Other", "Amber Traders is recruiting!", false, "@Other")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("repeat configuration alone does not start repeat on an observed match", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:SetGuildReminderMinutes("ad", "Amber Traders", 5)
    incoming(3, "Amber Traders is recruiting!")
    eq(scm:IsReminderAutomationActive("ad", "Amber Traders"), false)
    eq(EVENT_MANAGER.updates[scm:GetReminderTimerName("ad", "Amber Traders")], nil)
end)
test("guild slot order and legacy message entries resolve using current guilds", function()
    local a = entry("a", "ad", "Blue Traders", "Shared trial announcement", "Guild")
    a.guildName, a.guildIndex = nil, 2
    incoming(CHAT_CHANNEL_GUILD_1 + 1, "Shared trial announcement")
    eq(scm:GetGuildLastUsedAt("ad", "Blue Traders"), now)
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
end)
test("unrelated chat channels and variable-only templates do not reset usage", function()
    entry("a", "ad", "Amber Traders", "%zone%")
    incoming(3, "Stonefalls")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    entry("b", "ad", "Amber Traders", "Amber Traders is recruiting!")
    incoming(CHAT_CHANNEL_SAY, "Amber Traders is recruiting!")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
end)
test("original unannotated time and ending-soon countdown are supported", function()
    entry("a", "ad", "Amber Traders", "%guild% event until 8 PM EDT.")
    incoming(3, "Amber Traders event until 8 PM EDT (ending soon).")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
    now = now + 10
    incoming(3, "Amber Traders event until 8 PM EDT.")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("startup duplicate releases the queue without activating stopped automation", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm.startupQueue = {}
    scm.startupQueueCurrent = { commandId = "ad", guildName = "Amber Traders" }
    scm:ArmPendingRestoreState({id = CHAT_CHANNEL_SAY}, "Amber Traders is recruiting!", {commandId = "ad", guildName = "Amber Traders", startupQueue = true})
    incoming(3, "Amber Traders is recruiting!")
    eq(scm.startupQueueCurrent, nil)
    eq(scm:IsReminderAutomationActive("ad", "Amber Traders"), false)
end)
test("even whitespace-only user edits to a pending message are preserved", function()
    entry("a", "ad", "Amber Traders", "Amber Traders is recruiting!")
    scm:ArmPendingRestoreState({id = CHAT_CHANNEL_SAY}, "Amber Traders is recruiting!", {commandId = "ad", guildName = "Amber Traders"})
    CHAT_SYSTEM.textEntry.EditControl.text = "Amber  Traders is recruiting!"
    incoming(3, "Amber Traders is recruiting!")
    eq(CHAT_SYSTEM.textEntry.EditControl.text, "Amber  Traders is recruiting!")
    eq(scm.pendingRestoreState, nil)
end)
test("short templates with fixed words still match supported substitutions", function()
    entry("a", "ad", "Amber Traders", "Hi %greeting%!")
    incoming(3, "Hi evening!")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("zone substitutions must be known zone names rather than arbitrary text", function()
    entry("a", "ad", "Amber Traders", "%guild% is recruiting in %zone%.")
    incoming(3, "Amber Traders is recruiting in BUY GOLD NOW.")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    incoming(3, "Amber Traders is recruiting in Deshaan.")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)
test("repeated substitutions must agree within a message", function()
    entry("a", "ad", "Amber Traders", "Good %time%! %guild% sends %greeting% greetings from %zone% to %zone%.")
    incoming(3, "Good morning! Amber Traders sends evening greetings from Stonefalls to Deshaan.")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), nil)
    incoming(3, "Good morning! Amber Traders sends morning greetings from Stonefalls to Stonefalls.")
    eq(scm:GetGuildLastUsedAt("ad", "Amber Traders"), now)
end)

local failures = 0
for _, case in ipairs(tests) do
    reset()
    local ok, reason = pcall(case[2])
    if ok then print("PASS " .. case[1]) else failures = failures + 1; print("FAIL " .. case[1] .. ": " .. tostring(reason)) end
end
print(string.format("%d tests, %d failures", #tests, failures))
assert(failures == 0, "incoming chat regression suite failed")
