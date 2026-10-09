local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
for _,zone in ipairs({'ET','CT','MT','PT'}) do
    local winter=assert(s:ParseZonedDateTime('2026-01-16','08:00 PM',nil,zone))
    local summer=assert(s:ParseZonedDateTime('2026-07-16','08:00 PM',nil,zone))
    local offsets={ET=-5,CT=-6,MT=-7,PT=-8}
    eq(s:GetTimeZoneUtcOffset(winter,zone),offsets[zone])
    eq(s:GetTimeZoneUtcOffset(summer,zone),offsets[zone]+1)
    assert(not s:ParseZonedDateTime('2026-03-08','02:30 AM',nil,zone))
    assert(not s:ParseZonedDateTime('2026-11-01','01:30 AM',nil,zone))
    local first=assert(s:ParseZonedDateTime('2026-11-01','01:30 AM','FIRST',zone))
    local second=assert(s:ParseZonedDateTime('2026-11-01','01:30 AM','SECOND',zone))
    eq(second-first,3600)
end
f.entry('a','ad','Amber Traders','At %eventtime%','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-13',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=20,intervalMinutes=30,recurrence='WEEKLY'}))
local old=s:GetGuildSchedule('ad','Amber Traders').eventAtUtc
assert(s:SetSchedulingTimeZone('PT'))
local c=s:GetGuildSchedule('ad','Amber Traders');eq(c.timeZone,'PT');eq(c.eventAtUtc,old+10800)
eq(c.startsAtUtc,s:ParseZonedDateTime('2026-10-13','12:00 AM',nil,'PT'))
now=s:ParseZonedDateTime('2026-10-13','07:00 PM',nil,'PT')
eq(s:GetScheduledEventTokenValue('eventtime','ad','Amber Traders'),'08:00 PM PDT')
local text=s:ApplyMessageSubstitutions('At %eventtime%','ad','Amber Traders');assert(text:find('(1h)',1,true));f.incoming(CHAT_CHANNEL_GUILD_1,text)
eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now)
local nextEvent=s:GetScheduleOccurrence(c,s:ParseZonedDateTime('2026-10-14','12:00 PM',nil,'PT'))
eq(s:FormatScheduleDateTime(nextEvent.eventAtUtc,c),'2026-10-20 08:00 PM PDT')
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
local exported=s:BuildExportString();assert(s:SetSchedulingTimeZone('ET'))
assert(s:ImportSettingsFromString(exported));eq(s:GetSchedulingTimeZone(),'PT')
eq(s:GetGuildSchedule('ad','Amber Traders').eventAtUtc,old+10800)
eq(s:FormatEasternDateTime(old),'2026-10-13 08:00 PM EDT','explicit Eastern helpers stay Eastern')
-- Imported legacy schedules remain Eastern even when the receiver was Pacific.
local legacy=exported:gsub('GENERALTIMEZONE|PT\n','')
assert(s:ImportSettingsFromString(legacy));eq(s:GetSchedulingTimeZone(),'ET')
eq(s:GetGuildSchedule('ad','Amber Traders').eventAtUtc,old)
-- Clock times stay fixed across the DST change in every supported zone.
for _,zone in ipairs({'ET','CT','MT','PT'}) do
    local schedule=assert(s:NormalizeSchedule({timeZone=zone,mode='EVENT',enabled=true,
        eventDate='2026-10-27',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=20,
        intervalMinutes=30,recurrence='WEEKLY'}))
    local first=s:GetUpcomingScheduleOccurrences(schedule,schedule.startsAtUtc,2,true)
    eq(first[2].eventAtUtc-first[1].eventAtUtc,7*86400+3600)
    assert(s:FormatScheduleDateTime(first[2].eventAtUtc,schedule):find('08:00 PM',1,true))
    eq(s:GetSchedulePhase(schedule,first[2].startsAtUtc),'DAY')
end
-- A zone change cancels only addon-owned text, keeps personal input and cooldowns.
now=old-3600;s:ResetAllCooldowns();s:TickSchedules();assert(s.pendingRestoreState)
CHAT_SYSTEM:GetEditControl():SetText('Keep my typing')
local last=s:GetGuildLastUsedAt('ad','Amber Traders')
assert(s:SetSchedulingTimeZone('PT'))
eq(CHAT_SYSTEM:GetEditControl():GetText(),'Keep my typing');eq(s.pendingRestoreState,nil)
eq(s:GetGuildLastUsedAt('ad','Amber Traders'),last)
-- Invalid spring clock times reject the complete global change transactionally.
local existing=s:GetGuildSchedule('ad','Amber Traders')
existing.eventDate='2026-03-08';existing.eventTime='02:30 AM'
local ok=s:SetSchedulingTimeZone('ET');eq(ok,false)
eq(s:GetSchedulingTimeZone(),'PT');eq(s:GetGuildSchedule('ad','Amber Traders'),existing)
print('four-zone scheduling checks passed')
