local f=dofile('tests/eso_fixture.lua')
local s=SmartChatMsg
local function normalize(d) local v,e=s:NormalizeSchedule(d); assert(v,e); return v end
local d={mode='REMINDER',enabled=true,startDate='2026-03-07',startTime='02:30 AM',delivery='REPEAT',intervalMinutes=5,recurrence='DAILY'}
local n=normalize(d)
local upcoming=s:GetUpcomingScheduleOccurrences(n,n.startsAtUtc,3)
assert(#upcoming==3)
assert(s:GetEasternParts(upcoming[2].startsAtUtc).day==9,'spring gap skipped')
assert(s:GetEasternParts(upcoming[2].startsAtUtc).hour==2,'wallclock retained')
assert(n.startDate=='2026-03-07','anchor unchanged')
d.startDate='2026-01-31';d.startTime='08:00 PM';d.recurrence='MONTHLY_DATE'
n=normalize(d); upcoming=s:GetUpcomingScheduleOccurrences(n,n.startsAtUtc,3)
assert(s:GetEasternParts(upcoming[2].startsAtUtc).month==3,'missing monthday skipped')
d.startDate='2026-10-16';d.recurrence='MONTHLY_WEEKDAY'
n=normalize(d);upcoming=s:GetUpcomingScheduleOccurrences(n,n.startsAtUtc,3)
assert(s:GetEasternParts(upcoming[2].startsAtUtc).day==20,'third Friday')
d.startDate='2026-10-05';d.recurrence='BIWEEKLY';d.weekdays={[2]=true,[6]=true}
n=normalize(d);upcoming=s:GetUpcomingScheduleOccurrences(n,n.startsAtUtc,3)
assert(s:GetEasternParts(upcoming[2].startsAtUtc).day==9)
assert(s:GetEasternParts(upcoming[3].startsAtUtc).day==19)
d.mode='WINDOW';d.recurrence='NONE';d.endDate='2026-10-05';d.endTime='09:00 PM'
n=normalize(d);assert(n.eventAtUtc==n.startsAtUtc)
print('PASS recurring civil dates, DST, modes and immutable anchors')
-- Scheduler integration: a reminder prepares once, reload retains the marker,
-- and a missed occurrence cannot create a backlog.
f.reset(); f.entry('r','ad','Amber Traders','Reminder')
now=s:ParseEasternDateTime('2026-10-08','08:00 PM')
local reminder={mode='REMINDER',enabled=true,startDate='2026-10-08',startTime='08:00 PM',recurrence='DAILY',intervalMinutes=5,delivery='REPEAT'}
assert(s:SaveGuildSchedule('ad','Amber Traders',reminder))
local saved=s:GetGuildSchedule('ad','Amber Traders')
assert(s.pendingRestoreState,'online occurrence prepared')
assert(s:GetScheduledDueAt('ad','Amber Traders','ANY')==math.huge,'once per occurrence')
local reloaded=normalize(saved)
assert(reloaded.completedOccurrences[next(saved.completedOccurrences)],'once marker survives reload')
s:StopScheduledDelivery('ad','Amber Traders')
now=now+180
assert(s:GetGuildScheduleState('ad','Amber Traders')=='WAITING','expired reminder skipped')
now=now+86400-180
s:TickSchedules()
assert(s.pendingRestoreState,'next occurrence prepared')
local o=s:GetScheduleOccurrence(saved,now)
assert(o.startsAtUtc==now)
local records=s:ExportScheduleRecords()
local rows={}
for _,line in ipairs(records) do local row={};for part in (line..'|'):gmatch('(.-)|') do row[#row+1]=part end; rows[#rows+1]=row end
local imported={commands={{id='ad'}},commandGuildSettings={}}
assert(s:ImportScheduleRecords(rows,imported))
local copy=imported.commandGuildSettings.ad['amber traders'].schedule
assert(copy.mode=='REMINDER' and copy.recurrence=='DAILY')
print('PASS reminder once, reload, skipped backlog, next occurrence and exports')
assert(s:GetScheduleStatusText('ad','Amber Traders'):find('Engaged',1,true))
now=now+180
local status=s:GetScheduleStatusText('ad','Amber Traders')
assert(status:find('Waiting',1,true))
assert(status:find('2026-10-10',1,true),'status projects next occurrence')
print('PASS current and future occurrence status')
local zoneReminder=normalize({mode='REMINDER',delivery='ZONE',startDate='2026-10-08',startTime='08:00 PM',recurrence='DAILY'})
assert(zoneReminder.delivery=='REPEAT','reminders always fire by time')
local at=zoneReminder.startsAtUtc
local cached=s:GetUpcomingScheduleOccurrences(zoneReminder,at,3)
assert(s:GetUpcomingScheduleOccurrences(zoneReminder,at+1,3)==cached,'projection cached across ticks')
assert(s:GetUpcomingScheduleOccurrences(zoneReminder,at+120,3)~=cached,'expiry advances cache')
assert(s:GetUpcomingScheduleOccurrences(zoneReminder,at-1,3)[1].startsAtUtc==at,'backward clock invalidates cache')
print('PASS reminder delivery and projection cache boundaries')
local longWindow=normalize({mode='WINDOW',startDate='2026-10-01',startTime='08:00 PM',endDate='2026-10-06',endTime='09:00 PM',recurrence='WEEKLY'})
local inside=s:ParseEasternDateTime('2026-10-05','08:00 PM')
local current=s:GetScheduleOccurrence(longWindow,inside)
assert(current.startsAtUtc==longWindow.startsAtUtc,'long windows remain current near their end')
f.reset();f.entry('r','ad','Amber Traders','Reminder')
local queued=false
local original=s.PopulateChatBufferForCommand
s.PopulateChatBufferForCommand=function() queued=true;return true end
assert(s:QueueChatPopulation('ad','Amber Traders',nil,{observedDueAt=now+60},1))
s:ProcessChatPopulationQueue()
assert(not queued,'observed cooldown defers manual request')
assert(next(s.chatPopulationQueue),'future request retained')
now=now+60;s:ProcessChatPopulationQueue()
assert(queued,'future request executes at deadline')
s.PopulateChatBufferForCommand=original
print('PASS long active windows and deferred observed cooldown queue')
