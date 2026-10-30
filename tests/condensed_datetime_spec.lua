local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq;f.reset()
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
local guild='Amber Traders'
local entry=f.entry('a','ad',guild,'Raffle %eventwhen% at %eventtime% (%eventcountdown%). Date %eventdate%. Close %eventwhen:tickets% at %eventtime:tickets% / %eventtime-30m% / %eventtime+30m%.','Guild')
assert(s:SaveGuildSchedule('ad',guild,{mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',promotionDays=3,endDelayMinutes=60,intervalMinutes=60,importantTimes={tickets={label='Tickets',offsetMinutes=-75}}}))
s:GetGuildSchedule('ad',guild).importantTimes={tickets={label='Tickets',offsetMinutes=-75}}
now=s:ParseScheduleDateTime('2026-11-05','05:00 PM',nil,{timeZone='ET'})
eq(s:GetGuildCondensedDateTime('ad',guild),false)
local standard=s:ApplyMessageSubstitutions(entry.text,'ad',guild)
eq(s:GetScheduledEventTokenValue('eventdate','ad',guild),'11/07/2026')
assert(s:SetGuildCondensedDateTime('ad',guild,true))
eq(s:GetScheduledEventTokenValue('eventdate','ad',guild),'11/07')
eq(s:GetScheduledEventTokenValue('eventtime','ad',guild),'8PM ET')
eq(s:GetScheduledEventTokenValue('eventtime:tickets','ad',guild),'645PM ET')
eq(s:GetScheduledEventTokenValue('eventwhen','ad',guild),'Sat 11/07')
local condensed=s:ApplyMessageSubstitutions(entry.text,'ad',guild)
for _,enabled in ipairs({false,true}) do
 s:SetGuildCondensedDateTime('ad',guild,enabled)
 for _,text in ipairs({standard,condensed}) do
  assert(s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText(text)),text)
  assert(not s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText(text:gsub('8PM','9PM'):gsub('08:00','09:00'))),'wrong event clock')
  assert(not s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText(text:gsub('645PM','630PM'):gsub('06:45','06:30'))),'wrong mark clock')
  assert(not s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText(text:gsub('11/07','11/08'))),'wrong date')
 end
end
-- Relative day labels retain the same midnight grace in both formats.
s:SetGuildCondensedDateTime('ad',guild,true)
now=s:ParseScheduleDateTime('2026-11-06','11:58 PM',nil,{timeZone='ET'})
eq(s:GetScheduledEventTokenValue('eventwhen','ad',guild),'tomorrow')
local beforeMidnight=s:ApplyMessageSubstitutions(entry.text,'ad',guild)
now=s:ParseScheduleDateTime('2026-11-07','12:02 AM',nil,{timeZone='ET'})
eq(s:GetScheduledEventTokenValue('eventwhen','ad',guild),'today')
assert(s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText(beforeMidnight)))
now=s:ParseScheduleDateTime('2026-11-07','02:00 AM',nil,{timeZone='ET'})
assert(not s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText(beforeMidnight)))
-- Offsets crossing the fallback boundary keep the chosen civil zone label.
local dst=assert(s:NormalizeSchedule({mode='EVENT',eventDate='2026-11-01',eventTime='02:30 AM',timeZone='ET',promotionDays=1,endDelayMinutes=60,intervalMinutes=60}))
eq(s:GetScheduledEventTokenValue('eventtime-2h','ad',guild,{schedule=dst,condensedDateTime=true}),'130AM ET')
eq(s:GetScheduledEventTokenValue('eventtime-2h','ad',guild,{schedule=dst,condensedDateTime=false}),'01:30 AM EDT')
now=s:ParseScheduleDateTime('2026-11-05','05:00 PM',nil,{timeZone='ET'})
-- An implicit countdown stays optional for either peer representation.
entry.text='Raffle at %eventtime%.'
for _,enabled in ipairs({false,true}) do
 s:SetGuildCondensedDateTime('ad',guild,enabled)
 assert(s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText('Raffle at 8PM ET (2d).')))
 assert(s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText('Raffle at 08:00 PM EST (2d).')))
 assert(not s:MatchesIncomingMessage(entry,guild,s:NormalizeIncomingChatText('Raffle at 9PM ET (2d).')))
end
-- Guild isolation and compact midnight/noon, minutes and timezone season rules.
eq(s:GetGuildCondensedDateTime('ad','Blue Traders'),false)
local c=s:GetGuildSchedule('ad',guild)
for _,zone in ipairs({'ET','CT','MT','PT'}) do
 local config=assert(s:NormalizeSchedule({mode='EVENT',eventDate='2026-10-31',eventTime='12:00 AM',timeZone=zone,promotionDays=3,endDelayMinutes=60,intervalMinutes=60}))
 eq(s:GetScheduledEventTokenValue('eventtime','ad',guild,{schedule=config,condensedDateTime=true}),'12AM '..zone)
 eq(s:GetScheduledEventTokenValue('eventtime+12h','ad',guild,{schedule=config,condensedDateTime=true}),'12PM '..zone)
end
s:SetGuildCondensedDateTime('ad',guild,true)
for _,mode in ipairs({'ON_DEMAND','STARTUP','SCHEDULED'}) do
 s:GetCommandGuildSettings('ad',guild,true).runAt=mode
 local export=f.currentExport()
 assert(s:ImportSettingsFromString(export))
 eq(s:GetGuildCondensedDateTime('ad',guild),true)
 eq(s:GetGuildRunAt('ad',guild),mode)
 local old=export:gsub('(GUILDSETTING[^\n]*)',function(line)return line:gsub('|1$','')end)
 assert(s:ImportSettingsFromString(old))
 eq(s:GetGuildCondensedDateTime('ad',guild),false)
 s:SetGuildCondensedDateTime('ad',guild,true)
end
print('PASS condensed dates, clocks, signed/named tokens, exact peer matching, guild isolation and all-mode transfer')
