local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
local function draft()
 return {mode='EVENT',enabled=true,eventDate='2026-10-01',eventTime='08:00 PM',promotionDays=1,endDelayMinutes=30,intervalMinutes=30,recurrence='MONTHLY_WEEKDAY',monthlyWeek='LAST',monthlyWeekday=1}
end
local function dates(config,count)
 local out={};for _,o in ipairs(s:GetNominalScheduleOccurrences(config,config.eventAtUtc,count,true)) do out[#out+1]=s:GetScheduleOccurrenceDate(config,o.eventAtUtc) end;return table.concat(out,',')
end
local d=draft();local c=assert(s:NormalizeSchedule(d))
eq(dates(c,6),'2026-10-25,2026-11-29,2026-12-27,2027-01-31,2027-02-28,2027-03-28','last Sunday handles both four and five Sunday months')
local march=s:GetNominalScheduleOccurrences(c,c.eventAtUtc,6,true)[6];eq(s:GetScheduleParts(march.eventAtUtc,c).hour,20,'DST preserves wall time')
d.recurrenceInterval=2;c=assert(s:NormalizeSchedule(d));eq(dates(c,4),'2026-10-25,2026-12-27,2027-02-28,2027-04-25')
-- An explicit choice before the anchor date starts in the next eligible month.
d=draft();d.eventDate='2026-10-20';d.monthlyWeek=1;c=assert(s:NormalizeSchedule(d));eq(dates(c,2),'2026-11-01,2026-12-06')
-- Old records retain their original nth weekday; fifth never means Last.
d=draft();d.eventDate='2026-08-30';d.monthlyWeek=nil;d.monthlyWeekday=nil;c=assert(s:NormalizeSchedule(d));eq(c.monthlyWeek,5);eq(c.monthlyWeekday,1);eq(dates(c,3),'2026-08-30,2026-11-29,2027-01-31')
d.eventDate='2026-10-16';c=assert(s:NormalizeSchedule(d));eq(c.monthlyWeek,3);eq(c.monthlyWeekday,6);eq(dates(c,2),'2026-10-16,2026-11-20')
-- Explicit monthly fields remain inactive on a same-date recurrence.
d=draft();d.recurrence='MONTHLY_DATE';c=assert(s:NormalizeSchedule(d));eq(dates(c,2),'2026-10-01,2026-11-01');eq(c.monthlyWeek,'LAST')
-- Rotation and cancellations count the chosen actual dates, including a
-- nonmatching anchor and off-cadence exceptions.
d=draft();d.specialPattern='EVENT_ROTATION';d.rotationEvents={{id='a',name='Trial'},{id='b',name='Dungeon'}};d.rotationEvery=1
d.occurrenceExceptions={['2026-10-01']={action='POSTPONE'},['2026-10-25']={action='POSTPONE'}}
c=assert(s:NormalizeSchedule(d));local november=s:ParseScheduleDateTime('2026-11-29',d.eventTime,'FIRST',c);eq(s:GetScheduleEventVariant(c,november),'a')
c.occurrenceExceptions['2026-10-25'].action='KEEP';eq(s:GetScheduleEventVariant(c,november),'b')
-- Changing the monthly controls on the same object invalidates projection and
-- rotation caches without changing the immutable recurrence anchor.
c.occurrenceExceptions={};eq(dates(c,2),'2026-10-25,2026-11-29');c.monthlyWeek=1;eq(dates(c,2),'2026-10-04,2026-11-01')
eq(s:GetScheduleEventVariant(c,november),'a','two first-Sunday occurrences before Nov29')
c.monthlyWeek='LAST';c.monthlyWeekday=2;eq(dates(c,2),'2026-10-26,2026-11-30')
-- Reminder validation uses the first selected monthly occurrence rather than
-- a phantom anchor whose clock happens to be in the spring DST gap.
d=draft();d.eventDate='2026-03-08';d.eventTime='07:00 PM';d.timelineVersion=1;d.importantTimes={}
d.reminders={{id='morning',label='Morning reminder',start={kind='DAY',days=0,time='02:30 AM'},finish={kind='DAY',days=0,time='03:30 AM'},intervalMinutes=15,messageIds={}}}
c=assert(s:NormalizeSchedule(d));eq(s:GetScheduleOccurrenceDate(c,c.eventAtUtc),'2026-03-08','stored anchor remains unchanged')
local actual=s:GetNominalScheduleOccurrences(c,c.eventAtUtc,1,true)[1];eq(s:GetScheduleOccurrenceDate(c,actual.eventAtUtc),'2026-03-29');eq(s:GetScheduleOccurrenceDate(c,c.startsAtUtc),'2026-03-29')
c=assert(s:NormalizeSchedule(c));eq(s:GetScheduleOccurrenceDate(c,c.eventAtUtc),'2026-03-08');eq(dates(c,2),'2026-03-29,2026-04-26')
-- Full backups and SavedVars roundtrip explicit fields alongside timeline data.
f.entry('notice','ad','Amber Traders','Meet %eventactivity%','Guild')
d=draft();d.timelineVersion=1;d.importantTimes={};d.reminders={{id='row',label='Reminder',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=15,messageIds={'notice'}}}
assert(s:SaveGuildSchedule('ad','Amber Traders',d));ZO_SavedVars={NewAccountWide=function() return s.savedVars end};s:InitializeSavedVars()
local exported=s:BuildExportString();assert(exported:find('SCHEDULEMONTHLY_V1|ad|Amber Traders|LAST|1',1,true));assert(s:ImportSettingsFromString(exported))
c=s:GetGuildSchedule('ad','Amber Traders');eq(c.monthlyWeek,'LAST');eq(c.monthlyWeekday,1);eq(c.reminders[1].id,'row');eq(dates(c,2),'2026-10-25,2026-11-29')
local before=c;assert(not s:ImportSettingsFromString(exported:gsub('|LAST|1','|LAST|8')));eq(s:GetGuildSchedule('ad','Amber Traders'),before)
for _,bad in ipairs({0,6,-1,1.5,math.huge,'last','bogus'}) do local invalid=draft();invalid.monthlyWeek=bad;assert(not s:NormalizeSchedule(invalid)) end
for _,bad in ipairs({0,8,1.5,math.huge,'Sunday'}) do local invalid=draft();invalid.monthlyWeekday=bad;assert(not s:NormalizeSchedule(invalid)) end
-- Native controls and automatic relevant-submenu expansion.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end;s.IsMessagesSelectionComplete=function() return true end;s.RefreshSettingsUI=function() end;s.scheduleEditor=nil
local controls=s:BuildScheduleOptionControls()
local function find(list,name) for _,control in ipairs(list) do if control.name==name then return control end;if control.controls then local hit=find(control.controls,name);if hit then return hit end end end end
find(controls,'Repeat schedule').setFunc('Monthly on weekday');eq(find(controls,'Monthly weekday').disabled(),false)
find(controls,'Monthly on').setFunc('Last');find(controls,'Weekday').setFunc('Sunday');local editor=s:GetScheduleEditorDraft();eq(editor.monthlyWeek,'LAST');eq(editor.monthlyWeekday,1)
find(controls,'Monthly on').setFunc('Second');find(controls,'Weekday').setFunc('Wednesday');eq(editor.monthlyWeek,2);eq(editor.monthlyWeekday,4)
local submenu={open=false,disabled=false};submenu.animation={PlayFromStart=function() submenu.plays=(submenu.plays or 0)+1 end};SCM_MonthlyWeekdaySubmenu=submenu
s:RefreshEventTimingExpansion();eq(submenu.open,true);eq(submenu.plays,1);submenu.open=false;s:RefreshEventTimingExpansion();eq(submenu.open,false,'manual collapse remains respected')
find(controls,'Repeat schedule').setFunc('Every week');eq(find(controls,'Monthly weekday').disabled(),true);s:RefreshEventTimingExpansion();find(controls,'Repeat schedule').setFunc('Monthly on weekday');s:RefreshEventTimingExpansion();eq(submenu.open,true)
-- Helper consolidation aligns true monthly occurrences, preserving row/mark
-- offsets and ordinary event tokens despite unrelated technical anchor dates.
local function mergeCase(parentDate,sourceDate,sourceTime,week,weekday,interval)
 f.reset();f.entry('parent','ad','Amber Traders','Parent %eventtime%','Guild');local entry=f.entry('helper','other','Amber Traders','Helper %eventtime% and %eventtime:close%','Guild')
 local parent=draft();parent.eventDate=parentDate;parent.monthlyWeek=week;parent.monthlyWeekday=weekday;parent.recurrenceInterval=interval;parent.timelineVersion=1;parent.importantTimes={};parent.reminders={{id='parent',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},messageIds={'parent'}}}
 local helper=draft();helper.eventDate=sourceDate;helper.eventTime=sourceTime;helper.monthlyWeek=week;helper.monthlyWeekday=weekday;helper.recurrenceInterval=interval;helper.timelineVersion=1;helper.importantTimes={close={label='Close',offsetMinutes=-30}};helper.reminders={{id='helper',start={kind='OFFSET',minutes=-120},finish={kind='MARK',name='close'},messageIds={'helper'}}}
 assert(s:SaveGuildSchedule('ad','Amber Traders',parent));assert(s:SaveGuildSchedule('other','Amber Traders',helper))
 local cfg=s:GetGuildSchedule('ad','Amber Traders');local first=s:GetNominalScheduleOccurrences(cfg,cfg.eventAtUtc,1,true)[1]
 assert(s:MergeTimelineEvents('ad','Amber Traders',{'other'}));return s:GetGuildSchedule('ad','Amber Traders'),entry,first
end
local merged,entry=mergeCase('2026-01-15','2026-01-01','08:00 PM','LAST',1,1)
eq(merged.reminders[2].start.minutes,-120);eq(merged.importantTimes.source_other_close.offsetMinutes,-30);eq(entry.text,'Helper %eventtime% and %eventtime:source_other_close%')
merged,entry=mergeCase('2026-01-15','2026-01-01','07:00 PM','LAST',1,1)
eq(merged.reminders[2].start.minutes,-180);eq(merged.importantTimes.source_other_close.offsetMinutes,-90);eq(entry.text,'Helper %eventtime-60m% and %eventtime:source_other_close%')
local sparseFirst;merged,entry,sparseFirst=mergeCase('2026-02-15','2026-02-01','08:00 PM',5,1,12)
assert(sparseFirst.eventAtUtc-merged.eventAtUtc>400*86400);eq(merged.reminders[2].start.minutes,-120);eq(merged.importantTimes.source_other_close.offsetMinutes,-30)
-- Matching weekday controls still require the same interval-month phase.
f.reset();f.entry('p','ad','Amber Traders','Parent','Guild');f.entry('h','other','Amber Traders','Helper','Guild')
local parent=draft();parent.recurrenceInterval=2;parent.timelineVersion=1;parent.reminders={{id='p',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},messageIds={'p'}}}
local helper=draft();helper.eventDate='2026-11-01';helper.recurrenceInterval=2
assert(s:SaveGuildSchedule('ad','Amber Traders',parent));assert(s:SaveGuildSchedule('other','Amber Traders',helper));local ok,reason=s:MergeTimelineEvents('ad','Amber Traders',{'other'});assert(not ok and reason:find('starting-month phase',1,true))
print('Explicit monthly ordinals and Last weekday handle DST, recurrence intervals, legacy fifth skips, rotation cancellation caches, transfers and native controls')
