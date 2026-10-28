local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset();f.entry('a','ad','Amber Traders','Tours %eventwhen% at %eventtime% (%eventcountdown%)')
local d={mode='EVENT',enabled=true,timeZone='ET',eventDate='2026-10-27',eventTime='08:00 PM',recurrence='WEEKLY',timelineVersion=1,importantTimes={},reminders={}}
local names={'Monday evening','Tuesday afternoon','Tuesday evening','Starting soon','Tours starting now','Tours underway'}
for i,label in ipairs(names) do d.reminders[i]={id='tour'..i,label=label,start={kind='OFFSET',minutes=-360+i*30},finish={kind='OFFSET',minutes=-330+i*30},intervalMinutes=15,messageIds={'a'}} end
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
local c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-300*60
local m=s:CreatePlannerDraft('ad','Amber Traders');eq(#m.schedule.reminders,6)
for i=1,6 do assert(s:SelectPlannerPeriod(m,'tour'..i));eq(s:GetPlannerPeriod(m).label,names[i]) end
assert(not m.dirty);m.schedule.reminders[1].label='Private edit';eq(c.reminders[1].label,names[1])
m.dirty=true;local cancelled=s:CreatePlannerDraft('ad','Amber Traders');eq(cancelled.schedule.reminders[1].label,names[1])
-- Current usage may advance while the window is open. Save preserves it.
local key=s:GetScheduleOccurrence(c,now).occurrenceKey..':tour1'
c.timelineUsage[key]={lastSentAt=now,nextDueAt=now+600};c.availabilityUsage={['_command:2026-10-27']={count=3,lastAt=now}}
s.savedVars.messages[1].useCount=8;s.savedVars.messages[1].lastUsedAt=now
m.messages[1].name='Tours opener';m.channel='Officer'
assert(s:SavePlannerDraft(m));local saved=s:GetGuildSchedule('ad','Amber Traders')
eq(saved.reminders[1].label,'Private edit');eq(saved.timelineUsage[key].lastSentAt,now);eq(saved.availabilityUsage['_command:2026-10-27'].count,3)
eq(s.savedVars.messages[1].useCount,8);eq(s.savedVars.messages[1].name,'Tours opener');eq(s:GetSavedChatChannel('ad','Amber Traders'),'Officer')
assert(not m.dirty)
local preview,ctx=s:PreviewPlannerMessage(m,'a');assert(preview,ctx);assert(not preview:find('%%event'));eq(GetTimeStamp(),now)
local first,last=s:GetTimelineReminderWindow(ctx.schedule,ctx.occurrence,s:GetPlannerPeriod(m));assert(ctx.now>=first and ctx.now<last)
-- Invalid input and stale external edits never partially save messages.
m.messages[1].text='Do not commit';m.schedule.eventTime='invalid';assert(not s:SavePlannerDraft(m));assert(s.savedVars.messages[1].text~='Do not commit')
m=s:CreatePlannerDraft('ad','Amber Traders');assert(s:SaveGuildSchedule('ad','Amber Traders',m.schedule));assert(not s:SavePlannerDraft(m))
-- Calendar edits use guild civil days, so recurring periods retain their clocks.
m=s:CreatePlannerDraft('ad','Amber Traders');s:SelectPlannerPeriod(m,'tour1')
local date,time=s:GetPlannerBoundary(m,'start');assert(date and time)
assert(s:SetPlannerBoundary(m,'start',date,'01:00 AM'));eq(s:GetPlannerPeriod(m).start.kind,'DAY');eq(s:GetPlannerPeriod(m).start.time,'01:00 AM')
-- New commands and messages remain drafts until Save; new periods keep IDs.
local count=#s:GetCommands();local n=s:CreatePlannerDraft(nil,'Amber Traders');n.name='newtours';n.runAt='ON_DEMAND'
local msg=s:AddPlannerMessage(n);msg.text='Hello %guild%';eq(#s:GetCommands(),count)
assert(s:SavePlannerDraft(n));eq(#s:GetCommands(),count+1);assert(s:GetCommandById(n.commandId))
n=s:CreatePlannerDraft(nil,'Amber Traders');n.name='off';s:AddPlannerMessage(n).text='No';assert(not s:SavePlannerDraft(n));eq(#s:GetCommands(),count+1)
print('PASS planner private drafts, all six periods, validated saves, live usage preservation, previews, calendar boundaries and new commands')

-- Ordinary pool enablement uses the same settings as the existing editor.
local ordinary=s:CreatePlannerDraft('ad','Amber Traders');ordinary.runAt='ON_DEMAND'
ordinary.behavior.disabledMessageIds={a=true};ordinary.behavior.reminderMinutes=60;ordinary.behavior.autoPopulateCooldownMinutes=30;ordinary.behavior.reminderRetryMinutes=50
assert(s:SavePlannerDraft(ordinary));assert(not s:IsOrdinaryMessageEnabled('ad','Amber Traders','a'));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),30);eq(ordinary.behavior.reminderRetryMinutes,30)
local retained=s:GetGuildSchedule('ad','Amber Traders');assert(retained and retained.timelineVersion==1)
ordinary=s:CreatePlannerDraft('ad','Amber Traders');ordinary.behavior.disabledMessageIds.a=nil;assert(s:SavePlannerDraft(ordinary));assert(s:IsOrdinaryMessageEnabled('ad','Amber Traders','a'))
ordinary.schedule.timelineVersion=nil;ordinary.runAt='SCHEDULED';local ok,error=s:SavePlannerDraft(ordinary);assert(not ok and error:find('current Period Timeline',1,true))
