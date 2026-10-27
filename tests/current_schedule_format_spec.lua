local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('a','ad','Amber Traders','Keep this message','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='WINDOW',enabled=true,delivery='REPEAT',startDate='2026-10-08',startTime='08:00 PM',endDate='2026-10-08',endTime='09:00 PM',intervalMinutes=5}))
local old=s:BuildExportString();local commands=s.savedVars.commands
local ok,reason=s:ImportSettingsFromString(old);eq(ok,false);assert(reason:find('Unsupported schedule format',1,true));eq(s.savedVars.commands,commands)
ZO_SavedVars={NewAccountWide=function()return s.savedVars end};s:InitializeSavedVars();eq(s:GetGuildSchedule('ad','Amber Traders'),nil);eq(s.savedVars.messages[1].text,'Keep this message')
now=1791446400;s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function()return 'Amber Traders'end;s.RefreshSettingsUI=function()end
local d=s:GetScheduleEditorDraft();eq(d.timelineVersion,1);eq(d.mode,'EVENT');assert(#d.reminders==1);eq(d.reminders[1].messageIds[1],'a')
assert(s:SaveGuildSchedule('ad','Amber Traders',d));assert(s:ImportSettingsFromString(s:BuildExportString()));eq(s:GetGuildSchedule('ad','Amber Traders').timelineVersion,1)
print('PASS old schedules rejected without migration; fresh current period schedules roundtrip')

s.scheduleEditor=nil;local d=s:GetScheduleEditorDraft();d.eventDate='2026-11-03';d.eventTime='08:00 PM';d.recurrence='WEEKLY';d.eventDurationMinutes=120
local function find(list,name) for _,c in ipairs(list) do if c.name==name or c.reference==name then return c end;if c.controls then local r=find(c.controls,name);if r then return r end end end end
local controls=s:BuildScheduleOptionControls();local row=s:GetSelectedTimelineReminder()
find(controls,'Period Starts date').setFunc(s:ScheduleDateToPicker('2026-11-02'));eq(row.start.kind,'DAY');eq(row.start.days,-1)
find(controls,'Period Starts hour').setFunc('06');eq(row.start.time,'06:00 PM')
local before=row.start;find(controls,'Period Starts date').setFunc(s:ScheduleDateToPicker('2026-11-04'));eq(row.start,before)
find(controls,'Allow promotion after event starts').setFunc(true)
find(controls,'Period Stops hour').setFunc('10');find(controls,'Period Starts date').setFunc(s:ScheduleDateToPicker('2026-11-03'));find(controls,'Period Starts hour').setFunc('09')
eq(row.start.days,0);eq(row.start.time,'09:00 PM');eq(row.finish.time,'10:00 PM');assert(s:NormalizeSchedule(d))
print('PASS period calendars, server clocks, before-event bounds and underway reminders')

local duration=find(controls,'SCM_PeriodDurationSlider');eq(duration.type,'slider');eq(duration.min,0);eq(duration.max,240);duration.setFunc(0);eq(d.eventDurationMinutes,nil);assert(duration.name():find('Not set',1,true));duration.setFunc(120);eq(d.eventDurationMinutes,120)
local frequency=find(controls,'SCM_PeriodFrequencySlider');eq(frequency.max,1440);frequency.setFunc(125);eq(row.intervalMinutes,125);assert(frequency.name():find('2 hours 5 minutes',1,true))
local recurrence=find(controls,'SCM_PeriodRecurrenceSlider');eq(recurrence.min,1);eq(recurrence.max,10);recurrence.setFunc(2);eq(d.recurrenceInterval,2)
local daily=find(controls,'SCM_PeriodDailyLimitSlider');eq(daily.max,20);daily.setFunc(2);eq(row.availability.maxPerDay,2);daily.setFunc(0);eq(row.availability.maxPerDay,nil);assert(daily.name():find('Unlimited',1,true))
local before=d.recurrenceInterval;recurrence.setFunc(-1);eq(d.recurrenceInterval,before)
print('PASS bounded native sliders, unset/unlimited labels and readable durations')

local afterStart=find(controls,'Allow promotion after event starts');d.eventDurationMinutes=nil;eq(afterStart.disabled(),true);d.eventDurationMinutes=120;eq(afterStart.disabled(),false)
assert(find(controls,'Allow a closing announcement after the event ends'))
s:AddTimelineImportantTime();controls=s:BuildScheduleOptionControls()
local mark=d.importantTimes[s.scheduleEditor.markId];assert(mark)
find(controls,'Important time date').setFunc(s:ScheduleDateToPicker('2026-11-03'))
find(controls,'Important time hour').setFunc('07');find(controls,'Important time minute').setFunc('00');find(controls,'Important time AM/PM').setFunc('PM')
eq(mark.offsetMinutes,-60)
print('PASS important time calendar follows event and after-start duration requirement')
