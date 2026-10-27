-- Run from the repository root: lua tests/incoming_chat_spec.lua (Lua 5.1).
now = 1000000
local guilds = { [1] = { 101, "Amber Traders" }, [2] = { 202, "Blue Traders" } }
zo_strlower, zo_strupper = string.lower, string.upper
zo_strlen = string.len
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
function zo_random(low, high) if low==30 and high==90 then return 60 end; return low end
function d() end
SOUNDS = { NONE="none", DEFAULT_CLICK="click", NEGATIVE_CLICK="negative", DUEL_START="duel" }
function PlaySound() end
function ZO_Alert() end
function StartChatInput(text,channel) CHAT_SYSTEM.textEntry.editControl.text=text; CHAT_SYSTEM.channel=channel end
EVENT_ADD_ON_LOADED, EVENT_CHAT_MESSAGE_CHANNEL = 1, 2
CHAT_CHANNEL_ZONE, CHAT_CHANNEL_SAY, CHAT_CHANNEL_YELL = 3, 0, 1
CHAT_CHANNEL_EMOTE, CHAT_CHANNEL_PARTY = 4, 5
CHAT_CHANNEL_WHISPER, CHAT_CHANNEL_WHISPER_SENT = 2, 6
CHAT_CHANNEL_GUILD_1, CHAT_CHANNEL_GUILD_5 = 12, 16
CHAT_CHANNEL_OFFICER_1, CHAT_CHANNEL_OFFICER_5 = 17, 21
SI_UNIT_NAME = 1
SLASH_COMMANDS = {}
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
    scm.schedulerTicking = false
    scm.scheduleStartupEndsAt = nil
    scm.scheduledSendPause = nil
    scm.scheduleNoticeStates = {}
    scm.repeatPanelPaused = {}
    scm.statusSectionStates = {}
    scm.scheduleRuntime, scm.chatPopulationQueue = {}, {}
    scm.statusPanelVisible = false
    scm.startupQueueCurrent = nil
    EVENT_MANAGER.updates = {}
    local edit = { text = "" }
    function edit:GetText() return self.text end
    function edit:SetText(value) self.text = value end
    function edit:LoseFocus() end
    CHAT_SYSTEM = { textEntry = { editControl = edit }, channel = CHAT_CHANNEL_SAY }
    function CHAT_SYSTEM.textEntry:GetEditControl() return self.editControl end
    function CHAT_SYSTEM:GetEditControl() return self.textEntry:GetEditControl() end
    function CHAT_SYSTEM:SetChannel(channel) self.channel = channel end
    function CHAT_SYSTEM:GetCurrentChannelData() return {id=self.channel} end
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
-- Old unit fixtures still exercise date/phase arithmetic internally. Public
-- roundtrip fixtures must explicitly emit the current period format.
local function currentSchedules()
 for id,guilds in pairs(scm.savedVars.commandGuildSettings or {}) do for guild,settings in pairs(guilds) do
  local c=settings.schedule
  if c and c.timelineVersion~=1 then
   local rows,variants=scm:BuildLegacyTimelineRows(c,id,guild,c.eventAtUtc)
   assert(rows,variants)
   local p=scm:GetScheduleParts(c.eventAtUtc,c);local d={};for key,value in pairs(c) do d[key]=value end
   d.mode='EVENT';d.timelineVersion=1;d.eventDate=string.format('%04d-%02d-%02d',p.year,p.month,p.day);d.eventTime=string.format('%02d:%02d %s',p.hour%12==0 and 12 or p.hour%12,p.min,p.hour>=12 and 'PM' or 'AM');d.importantTimes={};d.reminders=rows;d.messageVariants=variants or c.messageVariants or {};d.timelineUsage={}
   if #rows==0 then d.reminders={{id='fixture-period',label='Period',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=15,lateMinutes=5,messageIds={}}} end
   settings.schedule=assert(scm:NormalizeSchedule(d))
  end
 end end
end
local function currentExport()
 local originals={};for _,guilds in pairs(scm.savedVars.commandGuildSettings or {}) do for _,settings in pairs(guilds) do originals[settings]=settings.schedule end end
 currentSchedules();local value=scm:BuildExportString();for settings,original in pairs(originals) do settings.schedule=original end;return value
end
return {scm=scm, reset=reset, entry=entry, incoming=incoming, eq=eq,currentExport=currentExport,currentSchedules=currentSchedules}
