local f=dofile('tests/eso_fixture.lua');f.reset();local s,eq=f.scm,f.eq
f.entry('eligible','ad','Amber Traders','Reminder')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,timelineVersion=1,eventDate='2026-10-27',eventTime='08:00 PM',timeZone='ET',recurrence='NONE',importantTimes={},reminders={{id='period',label='Promotion',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=10,messageIds={'eligible'}}}}))
local c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-1800
s.plannerModel=s:CreatePlannerDraft('ad','Amber Traders')
local occurrence=s:GetScheduleOccurrence(c,now);local key=occurrence.occurrenceKey..':period'
c.timelineUsage[key]={nextDueAt=now+600}
local text,at=s:GetPlannerPeriodEligibilityText('period');eq(at,now+600);eq(text,'Next eligible: '..s:FormatStatusDuration(600))
now=now+1;local nextText=s:GetPlannerPeriodEligibilityText('period');eq(nextText,'Next eligible: '..s:FormatStatusDuration(599))
s.scheduleStartupEndsAt=now+900;text,at=s:GetPlannerPeriodEligibilityText('period');eq(at,now+900)
s.scheduleStartupEndsAt=nil;s.scheduledSendPause={senderKey='another-command',endsAt=now+1200};text,at=s:GetPlannerPeriodEligibilityText('period');eq(at,now+1200)
s.scheduledSendPause=nil;c.timelineUsage[key].nextDueAt=now-1;text=s:GetPlannerPeriodEligibilityText('period');assert(text:find('Ready now',1,true))
s.savedVars.scheduledSendingEnabled=false;eq(s:GetPlannerPeriodEligibilityText('period'),'Scheduled sending off');s.savedVars.scheduledSendingEnabled=true
c.timelineUsage[key].nextDueAt=c.eventAtUtc+60;text=s:GetPlannerPeriodEligibilityText('period');assert(text:find('No further',1,true))
c.reminders[1].availability={maxPerDay=1};c.availabilityUsage={['period:'..s:GetScheduleOccurrenceDate(c,now)]={count=1,lastAt=now}}
text=s:GetPlannerPeriodEligibilityText('period');assert(text:find('Period daily limit reached',1,true))
eq(s:GetPlannerPeriodEligibilityText('different-period'),nil)
-- Identical period IDs under another guild use that guild's own usage.
local blue=assert(s:NormalizeSchedule(s.CopyPlannerValue(c)));blue.reminders[1].availability=nil;blue.availabilityUsage={};blue.timelineUsage={[key]={nextDueAt=now+120}}
local settings=s:GetCommandGuildSettings('ad','Blue Traders',true);settings.runAt='SCHEDULED';settings.schedule=blue
f.entry('blue','ad','Blue Traders','Blue reminder');s.plannerModel=s:CreatePlannerDraft('ad','Blue Traders')
text,at=s:GetPlannerPeriodEligibilityText('period');eq(at,now+120)
print('PASS planner live countdown includes current period cooldown, startup/pacing, readiness, sending switch, period end and quota')
