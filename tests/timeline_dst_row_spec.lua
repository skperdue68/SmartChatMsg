local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('valid','ad','Amber Traders','Valid reminder','Guild');local bad=f.entry('gap','ad','Amber Traders','Gap reminder','Guild')
local draft={mode='EVENT',enabled=true,timeZone='ET',eventDate='2026-03-01',eventTime='12:00 PM',recurrence='WEEKLY',timelineVersion=1,importantTimes={},reminders={
 {id='gap',label='Skipped spring clock',start={kind='DAY',days=0,time='02:30 AM'},finish={kind='DAY',days=0,time='03:30 AM'},intervalMinutes=15,messageIds={'gap'}},
 {id='valid',label='Valid daytime notice',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=15,messageIds={'valid'}}}}
assert(s:SaveGuildSchedule('ad','Amber Traders',draft));local config=s:GetGuildSchedule('ad','Amber Traders')
local event=assert(s:ParseScheduleDateTime('2026-03-08','12:00 PM','FIRST',config))
local occurrence=assert(s:BuildScheduleOccurrence(config,event),'an invalid DAY row must not suppress other reminders')
eq(occurrence.startsAtUtc,event-3600);eq(occurrence.endsAtUtc,event)
now=event-1800;eq(s:GetActiveTimelineReminder(config,now).id,'valid')
eq(s:GetScheduledMessageEntries('ad','Amber Traders')[1].id,'valid')
assert(pcall(function()s:MarkObservedChatUsage(bad,'Amber Traders','Guild')end),'peer matching skips the unresolved row without comparing nil times')
local upcoming=s:GetUpcomingScheduleOccurrences(config,event-3600,2,true)
eq(upcoming[1].eventAtUtc,event);eq(#upcoming,2)
print('PASS a future DST-gap reminder is skipped without dropping valid rows or breaking peer matching')
