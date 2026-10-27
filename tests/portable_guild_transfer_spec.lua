local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset()
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
s.savedVars.defaultGuildIndex=1
f.entry("a","ad","Amber Traders","Talk in /g1 or /o2. Keep /g10 and https://example.com/g1 intact.","Guild")
s.savedVars.messages[1].guildIndex=1
local settings=s:GetCommandGuildSettings("ad","Amber Traders",true)
settings.lastUsedGuildIndex=1;settings.lastUsedParamText="1";settings.runAt="STARTUP"
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=false,eventDate="2026-10-24",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=15}))
local exported=f.currentExport()
assert(exported:find("SCM_EXPORT_V2",1,true)==1,"exports must identify the name-based format")
assert(not exported:find("Talk in /g1 or /o2",1,true),"literal slot references must be named in the export")
assert(exported:find("DEFAULT|Amber Traders",1,true))
-- Simulate the recipient's guild order: Amber is now slot 2, Blue slot 1.
local originalName=GetGuildName
GetGuildName=function(id) if id==101 then return "Blue Traders" elseif id==202 then return "Amber Traders" end;return "" end
local notices={};s.AddLocalChatMessage=function(_,text) notices[#notices+1]=text end
assert(s:ImportSettingsFromString(exported))
eq(s.savedVars.defaultGuildIndex,2)
eq(s.savedVars.messages[1].guildIndex,2)
eq(s.savedVars.messages[1].guildName,"Amber Traders")
eq(s.savedVars.messages[1].text,"Talk in /g2 or /o1. Keep /g10 and https://example.com/g1 intact.")
settings=s:GetCommandGuildSettings("ad","Amber Traders",false)
eq(settings.lastUsedGuildIndex,2);eq(settings.lastUsedParamText,"2")
assert(settings.schedule)
eq(s:GetSavedChatChannel("ad","Amber Traders"),"Guild")
-- A missing referenced guild skips the message rather than pointing at another slot.
GetGuildName=function(id) if id==101 then return "Different Guild" elseif id==202 then return "Amber Traders" end;return "" end
assert(s:ImportSettingsFromString(exported))
eq(#s.savedVars.messages,1,"skipped incoming records do not delete local content")
local log=table.concat(notices,"\n")
assert(log:find("Blue Traders",1,true) and log:find("MESSAGE",1,true),log)
-- Missing primary guilds must skip settings and schedules as well as messages.
GetGuildName=function() return "Different Guild" end
notices={};assert(s:ImportSettingsFromString(exported))
eq(s.savedVars.defaultGuildIndex,2,"skipped default-guild record keeps recipient choice")
eq(#s.savedVars.messages,1,"skipped incoming records do not delete local content")
assert(next(s.savedVars.commandGuildSettings),"absent guild settings remain local")
assert(table.concat(notices,"\n"):find("Amber Traders",1,true))
GetGuildName=originalName
print("portable guild names, command parameters, channel references and missing-guild notices passed")

-- Legacy exports with a name/slot pair can be mapped, never assumed local.
local legacy="SCM_EXPORT_V1\nDEFAULT|1\nCOMMAND|legacy|events||\nMESSAGE|old|legacy|1|Amber Traders|Use /g1.||\nEND"
GetGuildName=function(id) if id==101 then return "Blue Traders" elseif id==202 then return "Amber Traders" end;return "" end
assert(s:ImportSettingsFromString(legacy))
eq(s.savedVars.defaultGuildIndex,2);eq(s.savedVars.messages[1].guildIndex,2)
local importedLegacy;for _,message in ipairs(s.savedVars.messages) do if message.id=="old" then importedLegacy=message end end;assert(importedLegacy);eq(importedLegacy.text,"Use /g2.")
local stable=f.currentExport()
local before=s.savedVars.messages[1].text
assert(not s:ImportSettingsFromString("not an export"))
eq(s.savedVars.messages[1].text,before)
-- Unsupported legacy source slots are skipped rather than bound to a local guild.
notices={}
assert(s:ImportSettingsFromString("SCM_EXPORT_V1\nDEFAULT|1\nCOMMAND|legacy|events||\nEND"))
eq(s.savedVars.defaultGuildIndex,2,"skipped default-guild record keeps recipient choice")
assert(table.concat(notices,"\n"):find("unknown source guild slot 1",1,true))
-- Preserve local locks when the same command arrives under another ID.
f.reset();local private=f.entry("private","ad","Amber Traders","My private content","Guild");private.locked=true
assert(s:ImportSettingsFromString("SCM_EXPORT_V2\nCOMMAND|replacement|recruit||\nMESSAGE|remote|replacement|Amber Traders|Amber Traders|Public /g2||\nEND"))
local kept
for _,e in ipairs(s.savedVars.messages) do if e.locked then kept=e end end
assert(kept and kept.commandId=="ad" and kept.text=="My private content")
GetGuildName=originalName
print("legacy mapping, transactional failures and locked message preservation passed")

-- Startup/reminder parameters also support channel-prefixed guild slots.
for _,parameter in ipairs({"g1","o1"}) do
 GetGuildName=originalName
 f.reset();f.entry("prefixed","ad","Amber Traders","A public notice.","Guild")
 local cfg=s:GetCommandGuildSettings("ad","Amber Traders",true)
 cfg.lastUsedGuildIndex=1;cfg.lastUsedParamText=parameter;cfg.runAt="STARTUP"
 local encoded=f.currentExport()
 GetGuildName=function(id) if id==101 then return "Blue Traders" elseif id==202 then return "Amber Traders" end;return "" end
 assert(s:ImportSettingsFromString(encoded))
 eq(s:GetCommandGuildSettings("ad","Amber Traders",false).lastUsedParamText,parameter:sub(1,1).."2")
end
GetGuildName=originalName
print("guild and officer command parameters preserve their channel and remap their slot")

-- Quoted slash references are normal prose, not literal sender slot numbers.
f.reset();f.entry("quoted","ad","Amber Traders",[[Use "/g1" and '/o2' to chat.]],"Guild")
local quoted=f.currentExport()
GetGuildName=function(id) if id==101 then return "Blue Traders" elseif id==202 then return "Amber Traders" end;return "" end
assert(s:ImportSettingsFromString(quoted))
eq(s.savedVars.messages[1].text,[[Use "/g2" and '/o1' to chat.]])
GetGuildName=originalName
print("quoted guild and officer references remap correctly")
