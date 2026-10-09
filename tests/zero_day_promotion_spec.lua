local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
local d={mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-13',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=20,intervalMinutes=30,recurrence='WEEKLY',startingSoonEnabled=true,startingSoonMinutes=120}
local c=assert(s:NormalizeSchedule(d))
eq(c.startsAtUtc,s:ParseEasternDateTime('2026-10-13','12:00 AM'))
eq(c.eventAtUtc,s:ParseEasternDateTime('2026-10-13','08:00 PM'))
local nextWeek=s:GetScheduleOccurrence(c,s:ParseEasternDateTime('2026-10-14','12:00 PM'))
eq(nextWeek.startsAtUtc,s:ParseEasternDateTime('2026-10-20','12:00 AM'))
eq(s:GetSchedulePhase(c,c.startsAtUtc),'DAY')
eq(s:GetSchedulePhase(c,c.eventAtUtc-7200),'SOON')
eq(s:GetSchedulePhase(c,c.eventAtUtc),'LIVE')
d.eventDate='2026-11-01';d.eventTime='08:00 PM'
c=assert(s:NormalizeSchedule(d))
eq(c.startsAtUtc,s:ParseEasternDateTime('2026-11-01','12:00 AM'))
eq(c.eventAtUtc-c.startsAtUtc,21*3600,'fall-back day has 21 real hours to 8 PM')
d.eventDate='2026-03-08'
c=assert(s:NormalizeSchedule(d))
eq(c.startsAtUtc,s:ParseEasternDateTime('2026-03-08','12:00 AM'))
eq(c.eventAtUtc-c.startsAtUtc,19*3600,'spring-forward day has 19 real hours to 8 PM')
d.eventDate='2026-10-13';d.promotionDays=1
c=assert(s:NormalizeSchedule(d));eq(c.startsAtUtc,s:ParseEasternDateTime('2026-10-12','08:00 PM'))
f.entry('day','ad','Amber Traders','Day of promotion','Guild')
d.promotionDays=0
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
c=s:GetGuildSchedule('ad','Amber Traders');now=c.startsAtUtc-1
eq(s:GetGuildScheduleState('ad','Amber Traders',now),'WAITING')
now=c.startsAtUtc;s:TickSchedules();assert(s.pendingRestoreState,'midnight should prepare an eligible event-day message')
print('zero-day midnight promotion checks passed')
