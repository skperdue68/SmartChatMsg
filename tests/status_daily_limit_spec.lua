local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();for _,id in ipairs({'a','b','c','d'}) do f.entry(id,'ad','Amber Traders','Message '..id,'Guild') end
local d={mode='EVENT',enabled=true,eventDate='2026-10-30',eventTime='08:00 PM',timelineVersion=1,importantTimes={},reminders={
 {id='early',label='Early promotion',start={kind='OFFSET',minutes=-360},finish={kind='OFFSET',minutes=-180},intervalMinutes=30,messageIds={'a','b','c','d'},availability={enabled=false,maxPerDay=5}},
 {id='late',label='Late promotion',start={kind='OFFSET',minutes=-180},finish={kind='OFFSET',minutes=0},intervalMinutes=30,messageIds={'a','b','c','d'},availability={enabled=false,maxPerDay=2}}
}}
assert(s:SaveGuildSchedule('ad','Amber Traders',d));local c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-300*60
local date=s:GetScheduleOccurrenceDate(c,now);c.availabilityUsage={['early:'..date]={count=5,lastAt=now},['_command:'..date]={count=5,lastAt=now}}
local notice=s:GetScheduledDailyLimitNotice('ad','Amber Traders');assert(notice:find('Period daily limit reached (5/5)',1,true));assert(notice:find('Early promotion',1,true))
local status,nextText,nextAt=s:GetScheduledCardDetails('ad','Amber Traders','ON');assert(status:find(notice,1,true));assert(not status:find('Complete',1,true));eq(nextText,'Waiting for an eligible period');eq(nextAt,nil)
assert(s:GetScheduleStatusText('ad','Amber Traders'):find('Period daily limit reached',1,true));eq(s:GetScheduledCardDetails('ad','Amber Traders','OFF'),'Inactive')
c.dailyLimitShared=true;c.sharedDailyLimit=5;notice=s:GetScheduledDailyLimitNotice('ad','Amber Traders');assert(notice:find('Command daily limit reached (5/5)',1,true))
c.sharedDailyLimit=nil;eq(s:GetScheduledDailyLimitNotice('ad','Amber Traders'),nil)
c.dailyLimitShared=false;now=c.eventAtUtc-120*60;eq(s:GetScheduledDailyLimitNotice('ad','Amber Traders'),nil,'early cap does not block another period')
c.availabilityUsage['late:'..date]={count=2,lastAt=now};notice=s:GetScheduledDailyLimitNotice('ad','Amber Traders');assert(notice:find('Period daily limit reached (2/2)',1,true))
-- Already-completed one-time notices are complete, rather than quota waits.
local occurrence=s:GetScheduleOccurrence(c,now);c.reminders[2].once=true;c.timelineUsage={[occurrence.occurrenceKey..':late']={completed=true}}
eq(s:GetScheduledDailyLimitNotice('ad','Amber Traders'),nil)
c.reminders[2].once=false;c.paused=true;eq(s:GetScheduledDailyLimitNotice('ad','Amber Traders'),nil)
c.paused=false;c.enabled=false;eq(s:GetScheduledDailyLimitNotice('ad','Amber Traders'),nil)
print('PASS status distinguishes period/shared caps and does not invent next-send timestamps')

-- Named active periods are explicitly identified on their status card.
c.enabled=true;c.paused=false;c.availabilityUsage={};c.timelineUsage={}
local rows=s:GetRepeatStatusPanelRows()
local named=false
for _,r in ipairs(rows) do if r.commandId=='ad' then named=r.statusText:find('Period: ',1,true)~=nil end end
assert(named,'Status card must identify the named active period')
