local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq;f.reset()
f.entry('a','ad','Amber Traders','Normal promotion.','Guild')
local d={mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',timelineVersion=1,reminders={{id='a',start={kind='OFFSET',minutes=-120},finish={kind='OFFSET',minutes=0},intervalMinutes=60,messageIds={'a'}}}}
assert(s:SaveGuildSchedule('ad','Amber Traders',d));local c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-3600
s:TickSchedules();local metadata=s.pendingRestoreState.metadata;s.pendingRestoreState=nil;CHAT_SYSTEM:GetEditControl():SetText('')
s:HandleScheduledPopulateTimeout(metadata);eq(s:GetScheduledDueAt('ad','Amber Traders','a'),now+3600)
s:TickSchedules();eq(s.pendingRestoreState,nil,'timeout must wait its retry interval')
s:ResetAllCooldowns();eq(next(c.timelineUsage),nil,'reset clears timeline usage');eq(s:GetScheduledDueAt('ad','Amber Traders','a'),c.eventAtUtc-7200,'reset re-arms timeline due time')
d.reminders[1].messageIds=12;local ok,result,reason=pcall(s.NormalizeSchedule,s,d);assert(ok);eq(result,nil);assert(reason)
d.reminders[1].messageIds={};d.eventDate='2027-02-01';d.startDate='2026-10-01';d.endDate='2026-10-03';assert(s:NormalizeSchedule(d),'timeline must ignore obsolete legacy start/end dates')
print('timeline retry, reset, invalid pool and obsolete legacy bounds verified')
