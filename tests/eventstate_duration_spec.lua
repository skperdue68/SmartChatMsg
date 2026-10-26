local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('m','ad','Amber Traders','Event notice','Guild')
local function draft(duration)
 return {mode='EVENT',enabled=true,timeZone='ET',eventDate='2026-11-07',eventTime='08:00 PM',timelineVersion=1,eventDurationMinutes=duration,importantTimes={},intervalMinutes=15,reminders={
 {id='repeat',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=180},intervalMinutes=15,messageIds={'m'}},
 {id='end',start={kind='OFFSET',minutes=60},once=true,lateMinutes=5,intervalMinutes=15,messageIds={'m'}}}}
end
local c=assert(s:NormalizeSchedule(draft(60)));eq(c.eventDurationMinutes,60)
local event=c.eventAtUtc;local o=s:BuildScheduleOccurrence(c,event)
eq(o.eventEndsAtUtc,event+3600);eq(o.endsAtUtc,event+3900)
eq(s:GetActiveTimelineReminder(c,event+3599).id,'repeat');eq(s:GetActiveTimelineReminder(c,event+3600).id,'end');eq(s:GetActiveTimelineReminder(c,event+3900),nil)
c.reminders[2].paused=true;eq(s:GetActiveTimelineReminder(c,event+3600),nil)
c.reminders[2].paused=false;c.reminders[2].enabled=false;eq(s:GetActiveTimelineReminder(c,event+3600),nil)
c.reminders[2].enabled=true;eq(s:GetActiveTimelineReminder(c,event+3600).id,'end')
local zero=draft(0);zero.reminders[2].start.minutes=0;c=assert(s:NormalizeSchedule(zero));event=c.eventAtUtc
eq(s:GetActiveTimelineReminder(c,event).id,'end');eq(s:GetActiveTimelineReminder(c,event+300),nil)
local late=draft(0);late.reminders[2].start.minutes=10;c=assert(s:NormalizeSchedule(late));event=c.eventAtUtc;eq(s:GetActiveTimelineReminder(c,event+600),nil)
late.reminders[2].allowAfterEventEnd=true;c=assert(s:NormalizeSchedule(late));eq(s:GetActiveTimelineReminder(c,c.eventAtUtc+600).id,'end')
local legacy=assert(s:NormalizeSchedule(draft(nil)));eq(legacy.eventDurationMinutes,nil);eq(s:GetActiveTimelineReminder(legacy,legacy.eventAtUtc+7200).id,'repeat')
for _,bad in ipairs({-1,1.5,'ten',math.huge}) do local d=draft(bad);eq(s:NormalizeSchedule(d),nil) end
print('PASS event duration caps, boundary once notices, explicit post-event delivery and reminder states')

f.reset();f.entry('m','ad','Amber Traders','Event notice','Guild');assert(s:SaveGuildSchedule('ad','Amber Traders',draft(60)));local cfg=s:GetGuildSchedule('ad','Amber Traders');cfg.reminders[1].enabled=false;cfg.reminders[2].paused=true;cfg.reminders[2].allowAfterEventEnd=true
ZO_SavedVars={NewAccountWide=function()return s.savedVars end};assert(s:ImportSettingsFromString(s:BuildExportString()));cfg=s:GetGuildSchedule('ad','Amber Traders');eq(cfg.eventDurationMinutes,60);eq(cfg.reminders[1].enabled,false);eq(cfg.reminders[2].paused,true);eq(cfg.reminders[2].allowAfterEventEnd,true)
print('PASS duration, period states and explicit after-event exceptions survive transfer')

f.reset();f.entry('m','ad','Amber Traders','Join us','Guild');local d=draft(60);d.reminders[2].enabled=false;assert(s:SaveGuildSchedule('ad','Amber Traders',d));cfg=s:GetGuildSchedule('ad','Amber Traders');now=cfg.eventAtUtc+3540;s:TickSchedules();assert(s.pendingRestoreState,'invitation prepares before end');now=cfg.eventAtUtc+3601;s:TickSchedules();eq(s.pendingRestoreState,nil,'untouched invitation is withdrawn at event end')
print('PASS pending invitations expire at the event duration boundary')
