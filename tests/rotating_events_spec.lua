local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local function clone(t) if type(t)~='table' then return t end;local r={};for k,v in pairs(t) do r[k]=clone(v) end;return r end
local function draft()
 return {mode='EVENT',enabled=true,eventDate='2026-10-01',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=30,intervalMinutes=30,recurrence='WEEKLY',specialPattern='EVENT_ROTATION',rotationEvery=2,rotationEvents={{id='stable-a',name='Trial night'},{id='stable-b',name='Dungeon night'}},messageVariants={b='stable-b'}}
end
local function event(c,date) return assert(s:ParseScheduleDateTime(date,c.eventTime,'FIRST',c)) end
f.reset()
local d=draft();local c=assert(s:NormalizeSchedule(d))
for _,row in ipairs({{'2026-10-01','stable-a'},{'2026-10-08','stable-a'},{'2026-10-15','stable-b'},{'2026-10-22','stable-b'},{'2026-10-29','stable-a'}}) do eq(s:GetScheduleEventVariant(c,event(c,row[1])),row[2]) end
-- Both cancellation actions skip delivery. Only POSTPONE holds a nominal slot.
d.occurrenceExceptions={['2026-10-01']={action='POSTPONE'},['2026-10-08']={action='KEEP'},['2026-10-02']={action='POSTPONE'}}
c=assert(s:NormalizeSchedule(d))
eq(s:GetScheduleEventVariant(c,event(c,'2026-10-15')),'stable-a')
eq(s:GetScheduleEventVariant(c,event(c,'2026-10-22')),'stable-b')
local nominal=s:GetNominalScheduleOccurrences(c,c.eventAtUtc,3,true)
eq(nominal[1].cancelled,true);eq(nominal[1].exceptionAction,'POSTPONE')
eq(s:GetUpcomingScheduleOccurrences(c,c.startsAtUtc,1)[1].eventAtUtc,event(c,'2026-10-15'),'cancelled anchor normalization and long lead projection')
-- Removing and restoring an exception repeatedly must invalidate projection caches.
for i=1,3 do
 c.occurrenceExceptions['2026-10-01']=nil
 eq(s:GetUpcomingScheduleOccurrences(c,c.startsAtUtc,1)[1].eventAtUtc,c.eventAtUtc)
 c.occurrenceExceptions['2026-10-01']={action='POSTPONE'}
 eq(s:GetUpcomingScheduleOccurrences(c,c.startsAtUtc,1)[1].eventAtUtc,event(c,'2026-10-15'))
end
-- Biweekly factions hold the entire span to their next nominal occurrence.
d=draft();d.specialPattern='FACTION_ROTATION';d.recurrence='BIWEEKLY';d.rotationWeeks=2;d.rotationFactions={'AD','EP'}
d.occurrenceExceptions={['2026-10-01']={action='POSTPONE'},['2026-10-02']={action='POSTPONE'}}
c=assert(s:NormalizeSchedule(d));eq(s:GetScheduleEventVariant(c,event(c,'2026-10-15')),'AD');eq(s:GetScheduleEventVariant(c,event(c,'2026-10-29')),'EP')
d.occurrenceExceptions['2026-10-01'].action='KEEP';c=assert(s:NormalizeSchedule(d));eq(s:GetScheduleEventVariant(c,event(c,'2026-10-15')),'EP')
-- DST does not shorten a held calendar week.
d.eventDate='2026-10-29';d.recurrence='WEEKLY';d.rotationWeeks=1;d.occurrenceExceptions={['2026-10-29']={action='POSTPONE'}}
c=assert(s:NormalizeSchedule(d));eq(s:GetScheduleEventVariant(c,event(c,'2026-11-05')),'AD');eq(s:GetScheduleEventVariant(c,event(c,'2026-11-12')),'EP')
-- Faction holds also use a real calendar month and very sparse next dates.
d=draft();d.specialPattern='FACTION_ROTATION';d.recurrence='MONTHLY_DATE';d.rotationWeeks=4;d.rotationFactions={'AD','EP'};d.occurrenceExceptions={['2026-10-01']={action='POSTPONE'}}
c=assert(s:NormalizeSchedule(d));eq(s:GetScheduleEventVariant(c,event(c,'2026-11-01')),'AD');eq(s:GetScheduleEventVariant(c,event(c,'2026-12-01')),'EP')
d.recurrence='WEEKLY';d.recurrenceInterval=101;d.rotationWeeks=1;c=assert(s:NormalizeSchedule(d))
local sparse=s:GetNominalScheduleOccurrences(c,c.eventAtUtc,2,true);assert(sparse[2].eventAtUtc-c.eventAtUtc>400*86400);eq(s:GetScheduleEventVariant(c,sparse[2].eventAtUtc),'AD')
-- Monthly schedules and selected weekdays count actual occurrences.
d=draft();d.recurrence='MONTHLY_DATE';d.rotationEvery=1;d.occurrenceExceptions={['2026-10-01']={action='POSTPONE'}}
c=assert(s:NormalizeSchedule(d));eq(s:GetScheduleEventVariant(c,event(c,'2026-11-01')),'stable-a');eq(s:GetScheduleEventVariant(c,event(c,'2026-12-01')),'stable-b')
d=draft();d.weekdays={[3]=true,[5]=true};d.rotationEvery=1;c=assert(s:NormalizeSchedule(d))
eq(s:GetScheduleEventVariant(c,event(c,'2026-10-06')),'stable-b');eq(s:GetScheduleEventVariant(c,event(c,'2026-10-08')),'stable-a')
-- New activity token participates in exact current-activity peer matching.
f.reset();local entry=f.entry('a','ad','Amber Traders','Join %eventactivity% on %eventdate% at %eventtime% (%eventcountdown%)','Guild')
f.entry('b','ad','Amber Traders','Specific activity','Guild')
d=draft();assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-3600
local text=s:ApplyMessageSubstitutions(entry.text,'ad','Amber Traders');assert(text:find('Trial night',1,true));eq(#s:GetScheduledMessageEntries('ad','Amber Traders'),1)
assert(s:MatchesIncomingMessage(entry,'Amber Traders',s:NormalizeIncomingChatText(text)))
c.rotationEvents[1].name='Renamed trial';assert(not s:MatchesIncomingMessage(entry,'Amber Traders',s:NormalizeIncomingChatText(text)))
local changed=s:ApplyMessageSubstitutions(entry.text,'ad','Amber Traders');assert(s:MatchesIncomingMessage(entry,'Amber Traders',s:NormalizeIncomingChatText(changed)))
-- Save/load/full import preserves stable IDs, order, exceptions and locked groups.
c.occurrenceExceptions={['2026-10-01']={action='POSTPONE'},['2026-10-08']={action='KEEP'}}
assert(s:SetMessageLocked('b',true));ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
s:InitializeSavedVars();c=s:GetGuildSchedule('ad','Amber Traders');eq(c.rotationEvents[1].id,'stable-a');eq(c.occurrenceExceptions['2026-10-01'].action,'POSTPONE')
local exported=s:BuildExportString();assert(exported:find('SCHEDULEACTIVITY_V1',1,true));assert(s:ImportSettingsFromString(exported));c=s:GetGuildSchedule('ad','Amber Traders')
eq(c.rotationEvents[1].name,'Renamed trial');eq(c.rotationEvery,2);eq(c.messageVariants.b,'stable-b');eq(c.occurrenceExceptions['2026-10-08'].action,'KEEP')
-- Independently created activity IDs reconcile by unique exact name for locks.
local foreign=exported:gsub('stable%-b','foreign-b')
assert(s:ImportSettingsFromString(foreign));eq(s:GetGuildSchedule('ad','Amber Traders').rotationEvents[2].id,'stable-b');eq(s:GetGuildSchedule('ad','Amber Traders').messageVariants.b,'stable-b')
local absent=foreign:gsub('Dungeon night','Different activity')
local original=s:GetGuildSchedule('ad','Amber Traders');local ok,reason=s:ImportSettingsFromString(absent);assert(not ok and reason:find('locked activity',1,true));eq(s:GetGuildSchedule('ad','Amber Traders'),original)
-- Queued manual and automatic requests cannot deliver a newly cancelled date.
for _,manual in ipairs({false,true}) do
 f.reset();f.entry('a','ad','Amber Traders','Join %eventactivity%','Guild');d=draft();d.promotionDays=1;assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-3600
 CHAT_SYSTEM:GetEditControl():SetText('My draft');assert(s:RequestScheduledDelivery('ad','Amber Traders',manual))
 c.occurrenceExceptions['2026-10-01']={action='KEEP'};CHAT_SYSTEM:GetEditControl():SetText('');s:ProcessChatPopulationQueue();eq(s.pendingRestoreState,nil);assert(not s:RequestScheduledDelivery('ad','Amber Traders',manual))
end
-- Saving a cancellation withdraws an already prepared untouched message.
f.reset();f.entry('a','ad','Amber Traders','Join %eventactivity%','Guild');d=draft();assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-3600
assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:ProcessChatPopulationQueue();assert(s.pendingRestoreState)
d.occurrenceExceptions={['2026-10-01']={action='POSTPONE'}};assert(s:SaveGuildSchedule('ad','Amber Traders',d));eq(s.pendingRestoreState,nil);eq(CHAT_SYSTEM:GetEditControl():GetText(),'')
-- Long-lead timelines skip an already active cancelled anchor, even when the
-- following occurrence's reminder window is active too.
d=draft();d.timelineVersion=1;d.importantTimes={};d.reminders={{id='lead',label='Long promotion',start={kind='OFFSET',minutes=-43200},finish={kind='OFFSET',minutes=0},intervalMinutes=60,messageIds={'a'}}}
d.occurrenceExceptions={['2026-10-01']={action='POSTPONE'}}
c=assert(s:NormalizeSchedule(d));now=c.eventAtUtc-3600
local active,_,_,following=s:GetActiveTimelineReminder(c,now);eq(active.id,'lead');eq(following.eventAtUtc,event(c,'2026-10-08'));eq(s:GetScheduleEventVariant(c,following.eventAtUtc),'stable-a')
-- A DST-gap reminder cannot erase its actual event from nominal rotation.
d=draft();d.eventDate='2026-03-01';d.eventTime='07:00 PM';d.rotationEvery=1;d.timelineVersion=1;d.importantTimes={}
d.reminders={{id='gap',label='Sunday morning',start={kind='DAY',days=0,time='02:30 AM'},finish={kind='DAY',days=0,time='03:30 AM'},intervalMinutes=30,messageIds={'a'}}}
c=assert(s:NormalizeSchedule(d));local spring=s:GetNominalScheduleOccurrences(c,c.eventAtUtc,3,true)
eq(s:GetScheduleOccurrenceDate(c,spring[2].eventAtUtc),'2026-03-08');eq(s:GetScheduleOccurrenceDate(c,spring[3].eventAtUtc),'2026-03-15')
eq(s:GetScheduleEventVariant(c,event(c,'2026-03-15')),'stable-a','March 8 event consumes ordinal 1 despite invalid reminder')
now=event(c,'2026-03-08')-12*3600;eq(s:GetActiveTimelineReminder(c,now),nil)
c.occurrenceExceptions={['2026-03-08']={action='POSTPONE'}};eq(s:GetScheduleEventVariant(c,event(c,'2026-03-15')),'stable-b')
-- Legacy explicit promotion bounds can also hit a gap while the event exists.
d=draft();d.eventDate='2026-03-01';d.eventTime='07:00 PM';d.promotionDays=nil;d.startDate='2026-03-01';d.startTime='02:30 AM';d.endDate='2026-03-01';d.endTime='08:00 PM';d.rotationEvery=1
c=assert(s:NormalizeSchedule(d));local legacy=s:GetNominalScheduleOccurrences(c,c.eventAtUtc,3,true)
eq(s:GetScheduleOccurrenceDate(c,legacy[2].eventAtUtc),'2026-03-08');eq(s:GetScheduleEventVariant(c,event(c,'2026-03-15')),'stable-a')
local delivery=s:GetUpcomingScheduleOccurrences(c,event(c,'2026-03-08')-12*3600,1,true);eq(s:GetScheduleOccurrenceDate(c,delivery[1].eventAtUtc),'2026-03-15')
-- Invalid structures reject transactionally, including nonfinite counts and dates.
for _,mutate in ipairs({function(x) x.rotationEvery=math.huge end,function(x) x.rotationEvery=0/0 end,function(x) x.rotationEvery=1.5 end,function(x) x.rotationEvents={} end,function(x) x.rotationEvents[2].id='stable-a' end,function(x) x.rotationEvents[1].name=string.rep('x',81) end,function(x) x.rotationEvents[4]={id='hole',name='Hole'} end,function(x) x.occurrenceExceptions={['2026-02-30']={action='KEEP'}} end,function(x) x.occurrenceExceptions={['2026-10-01']={action='skip'}} end}) do local invalid=draft();mutate(invalid);assert(not s:NormalizeSchedule(invalid)) end
-- Native editor callbacks keep IDs on rename/reorder and expose cancellations.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end;s.RefreshSettingsUI=function() end;s.scheduleEditor=nil
local controls=s:BuildScheduleOptionControls()
local function find(list,name) for _,control in ipairs(list) do if control.name==name then return control end;if control.controls then local result=find(control.controls,name);if result then return result end end end end
local editor=s:GetScheduleEditorDraft();find(controls,'Activity name').setFunc('Edited trial');eq(editor.rotationEvents[1].id,'stable-a')
find(controls,'Move activity down').func();eq(editor.rotationEvents[2].id,'stable-a');find(controls,'Move activity up').func();eq(editor.rotationEvents[1].id,'stable-a')
find(controls,'Occurrences per activity').setFunc('3');eq(editor.rotationEvery,'3')
local date=event(c,'2026-10-08');now=date-3600
find(controls,'Occurrence to cancel or undo').setFunc('2026-10-08');find(controls,'Cancellation rotation').setFunc('Postpone rotation');find(controls,'Cancel selected occurrence').func();eq(editor.occurrenceExceptions['2026-10-08'].action,'POSTPONE')
find(controls,'Undo selected cancellation').func();eq(editor.occurrenceExceptions['2026-10-08'],nil)
-- New activities use UUIDs, avoid collisions, and never recycle deleted IDs.
local originalUuid=s.GenerateUuid;s.GenerateUuid=function() return '00000000-0000-4000-8000-000000000001' end
find(controls,'New activity name').setFunc('Added one');find(controls,'Add activity').func();local firstAdded=editor.rotationEvents[#editor.rotationEvents].id
find(controls,'New activity name').setFunc('Added two');find(controls,'Add activity').func();local secondAdded=editor.rotationEvents[#editor.rotationEvents].id
assert(firstAdded~=secondAdded);eq(firstAdded,'00000000-0000-4000-8000-000000000001')
find(controls,'Selected activity').setFunc(tostring(#editor.rotationEvents)..'. Added two');find(controls,'Remove activity').func()
find(controls,'New activity name').setFunc('Added three');find(controls,'Add activity').func();local thirdAdded=editor.rotationEvents[#editor.rotationEvents].id
assert(thirdAdded~=firstAdded and thirdAdded~=secondAdded);s.GenerateUuid=originalUuid
-- The occurrence selector includes the current live promotion after event start.
editor.occurrenceExceptions={};now=assert(s:NormalizeSchedule(editor)).eventAtUtc+60
local labels=s.rotationEditorChoiceProviders.SCM_SelectedCancellationOccurrence();assert(labels[1]:find('2026-10-01',1,true))
find(controls,'Occurrence to cancel or undo').setFunc(labels[1]);find(controls,'Cancel selected occurrence').func();eq(editor.occurrenceExceptions['2026-10-01'].action,'POSTPONE')
-- Retaining cancellations across pattern/cadence changes never resumes the date.
editor.specialPattern='NONE';editor.recurrence='NONE';editor.occurrenceExceptions={['2026-10-01']={action='KEEP'}}
local retained=assert(s:NormalizeSchedule(editor));eq(#s:GetUpcomingScheduleOccurrences(retained,retained.startsAtUtc,1),0)
eq(find(controls,'Occurrence cancellations').disabled(),false)
-- Unicode names use character counts, and bad active groups are rejected.
local unicode=draft();unicode.rotationEvents[1].name=string.rep(string.char(0xC3,0xA9),80);assert(s:NormalizeSchedule(unicode))
unicode.rotationEvents[1].name=unicode.rotationEvents[1].name..'x';assert(not s:NormalizeSchedule(unicode))
local missing=draft();missing.messageVariants.b='missing';assert(not s:NormalizeSchedule(missing))
print('Rotating activities, nominal cancellation progression, DST, runtime delivery, transfer and native editor callbacks passed')
