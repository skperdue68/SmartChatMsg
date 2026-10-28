local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset()
local template="Raffle %eventwhen% at %eventtime% (%eventcountdown%). Sales close at %eventtime-1h% (%eventcountdown-1h%)."
local entry=f.entry("raffle","ad","Amber Traders",template,"Guild")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-10",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=15,recurrence="BIWEEKLY",startingSoonEnabled=true,startingSoonMinutes=60}))
local schedule=s:GetGuildSchedule("ad","Amber Traders")
now=schedule.eventAtUtc-3*3600
local output=s:ApplyMessageSubstitutions(template,"ad","Amber Traders")
eq(output,"Raffle today at 08:00 PM EDT (3h). Sales close at 07:00 PM EDT (2h).")
eq(s:GetScheduledEventTokenValue("eventtime+30m","ad","Amber Traders"),"08:30 PM EDT")
eq(s:GetScheduledEventTokenValue("eventcountdown-1h","ad","Amber Traders"),"2h")
eq(s:ResolveScheduledEventTokens("%EVENTTIME-1H% / %EVENTCOUNTDOWN%","ad","Amber Traders"),"07:00 PM EDT / 3h")
-- Both explicit durations can change without losing the incoming match.
now=now+15*60
assert(s:MatchesIncomingMessage(entry,"Amber Traders",s:NormalizeIncomingChatText(output)),"both earlier countdowns must match")
assert(not s:MatchesIncomingMessage(entry,"Amber Traders",s:NormalizeIncomingChatText(output:gsub("07:00 PM","06:00 PM"))),"deadline identity must remain required")
f.incoming(CHAT_CHANNEL_GUILD_1,output)
assert(s:GetCommandGuildSettings("ad","Amber Traders",false).lastUsedAt==now,"peer resets usage")
-- A recurring event and guild timezone determine both deadlines.
now=s:ParseEasternDateTime("2026-10-23","05:00 PM")
output=s:ApplyMessageSubstitutions(template,"ad","Amber Traders")
assert(output:find("tomorrow",1,true),output)
assert(output:find("07:00 PM EDT",1,true),output)
-- The preview's simulated clock must be shared by both countdowns.
s.savedVars.selectedMessagesCommand="ad";s.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
s.AddLocalChatMessage=function() end
output,context=s:TestMessagePreview("raffle","SOON")
assert(output:find("(30m)",1,true),output)
assert(output:find("(passed)",1,true),output)
eq(context.now,context.occurrence.eventAtUtc-30*60)
-- Existing templates retain the original automatic countdown.
now=schedule.eventAtUtc-3*3600
eq(s:ApplyMessageSubstitutions("Raffle at %eventtime%.","ad","Amber Traders"),"Raffle at 08:00 PM EDT (3h).")
eq(s:ApplyMessageSubstitutions("Close at %eventtime-1h%.","ad","Amber Traders"),"Close at 07:00 PM EDT (2h).")
eq(s:GetScheduledEventTokenValue("eventcountdown-1h","ad","Amber Traders",{schedule=schedule,occurrence=s:BuildScheduleOccurrence(schedule,schedule.eventAtUtc),now=schedule.eventAtUtc-3600}),"now")
print("event time offsets and independent countdowns passed")

-- Unknown syntax stays literal and does not disable the legacy formatter.
eq(s:ResolveScheduledEventTokens("%eventtime-nope% %eventcountdown-1x%","ad","Amber Traders"),"%eventtime-nope% %eventcountdown-1x%")
assert(not s:HasExplicitEventCountdown("%eventcountdown-1x%"))
assert(not s:MatchesIncomingMessage(entry,"Amber Traders",s:NormalizeIncomingChatText("Raffle today at 08:00 PM EDT (banana). Sales close at 07:00 PM EDT (2h).")))
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
local exported=f.currentExport();assert(s:ImportSettingsFromString(exported))
eq(s.savedVars.messages[1].text,template,"full settings transfer preserves deadline tokens")
-- Offsets crossing a DST boundary retain elapsed-hour meaning and each timezone label.
local dst=assert(s:NormalizeSchedule({mode="EVENT",eventDate="2026-11-01",eventTime="02:30 AM",promotionDays=1,endDelayMinutes=60,intervalMinutes=15,timeZone="ET"}))
local c={schedule=dst,occurrence=s:BuildScheduleOccurrence(dst,dst.eventAtUtc),now=dst.eventAtUtc-7200}
eq(s:ResolveScheduledEventTokens("%eventtime% / %eventtime-2h% / %eventcountdown-2h%","ad","Amber Traders",c),"02:30 AM EST / 01:30 AM EDT / now")
dst.timeZone="PT";c.occurrence.timeZone="PT"
assert(s:GetScheduledEventTokenValue("eventtime","ad","Amber Traders",c):find("PDT",1,true))
print("malformed tokens, incoming validation, transfer and DST offsets passed")

local kind,offset=s:ParseScheduledEventToken("eventcountdown-1d")
eq(kind,"eventcountdown");eq(offset,-86400)
kind,offset=s:ParseScheduledEventToken("EVENTTIME-3H")
eq(kind,"eventtime");eq(offset,-10800)
kind,offset=s:ParseScheduledEventToken("eventtime-30m")
eq(offset,-1800)

-- Explicit deadlines must not round away the offset on long countdowns.
local longContext={schedule=schedule,occurrence=s:BuildScheduleOccurrence(schedule,schedule.eventAtUtc),now=schedule.eventAtUtc-(10*86400+6*3600+17*60)}
eq(s:ResolveScheduledEventTokens('%eventcountdown% / %eventcountdown-60m% / %eventcountdown-1h% / %eventcountdown-4h%', 'ad','Amber Traders',longContext), '10d 6h 17m / 10d 5h 17m / 10d 5h 17m / 10d 2h 17m')
eq(s:FormatEventCountdown(31*60),'31m')
eq(s:FormatEventCountdown(1),'1m')
eq(s:FormatEventCountdown(0),'now')
eq(s:FormatEventCountdown(-1),'passed')

for _,value in ipairs({'1m','4m','17m','31m','59m','10d 5h 17m','~10d 6h'}) do
 assert(s:IsValidIncomingMatchCapture({kind='eventcountdown'},value),'peer countdown must remain valid: '..value)
end
assert(not s:IsValidIncomingMatchCapture({kind='eventcountdown'},'60m'))
local peer=f.entry('precise-peer','ad','Amber Traders','Raffle countdown: %eventcountdown%.','Guild')
assert(s:MatchesIncomingMessage(peer,'Amber Traders',s:NormalizeIncomingChatText('Raffle countdown: 10d 5h 17m.')))
assert(s:MatchesIncomingMessage(peer,'Amber Traders',s:NormalizeIncomingChatText('Raffle countdown: 1m.')))
