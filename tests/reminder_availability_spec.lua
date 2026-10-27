local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local function copy(v) if type(v)~='table' then return v end;local r={};for k,x in pairs(v) do r[k]=copy(x) end;return r end
local function draft(a)
 return {mode='EVENT',enabled=true,eventDate='2026-10-30',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=1,intervalMinutes=30,timelineVersion=1,importantTimes={},reminders={{id='row',label='Notice',start={kind='OFFSET',minutes=-14400},finish={kind='OFFSET',minutes=4320},intervalMinutes=30,messageIds={'msg'},availability=a}}}
end
local function at(config,date,time) return assert(s:ParseScheduleDateTime(date,time or '12:00 PM','FIRST',config)) end
local function normalize(a) local c=assert(s:NormalizeSchedule(draft(a)));return c,c.reminders[1],assert(s:BuildScheduleOccurrence(c,c.eventAtUtc)) end
f.reset()
local c,row,o=normalize({enabled=true,startMinute=420,endMinute=1320,maxPerDay=1})
assert(not s:GetReminderAvailabilityStatus(c,row,o,at(c,'2026-10-27','06:59 AM')));assert(s:GetReminderAvailabilityStatus(c,row,o,at(c,'2026-10-27','07:00 AM')));assert(not s:GetReminderAvailabilityStatus(c,row,o,at(c,'2026-10-27','10:00 PM')))
local windows=s:GetEffectiveReminderWindows(c,row,o,at(c,'2026-10-27','12:00 PM'),at(c,'2026-10-27','01:00 PM'));eq(#windows,1);eq(windows[1].start,at(c,'2026-10-27','07:00 AM'),'query does not clip effective slices')
row.availability.weekdays={};assert(not s:GetReminderAvailabilityStatus(c,row,o,at(c,'2026-10-27','08:00 AM')))
row.availability={enabled=true,startMinute=1320,endMinute=360,weekdays={[3]=true},weekdayOverrides={[3]={startMinute=1260,endMinute=300}},dateOverrides={['2026-10-27']={startMinute=1380,endMinute=240}}}
local ok,_,_,source,origin=s:GetReminderAvailabilityStatus(c,row,o,at(c,'2026-10-28','02:00 AM'));assert(ok);eq(source,'DATE');eq(origin,'2026-10-27')
assert(not s:GetReminderAvailabilityStatus(c,row,o,at(c,'2026-10-28','04:00 AM')))
row.availability.dateOverrides={};local _,_,_,inherited=s:GetReminderAvailabilityStatus(c,row,o,at(c,'2026-10-27','09:30 PM'));eq(inherited,'WEEKDAY')
-- Calendar days are 23/25 hours and ambiguous boundaries use FIRST/SECOND.
local dst=draft({enabled=true});dst.eventDate='2026-03-15';dst.reminders[1].start.minutes=-43200;dst.reminders[1].finish.minutes=43200
c=assert(s:NormalizeSchedule(dst));row=c.reminders[1];o=s:BuildScheduleOccurrence(c,c.eventAtUtc)
windows=s:GetEffectiveReminderWindows(c,row,o,at(c,'2026-03-08','12:00 AM'),at(c,'2026-03-09','12:00 AM'));eq(#windows,1);eq(windows[1].finish-windows[1].start,23*3600)
row.availability.startMinute=150;row.availability.endMinute=210;eq(#s:GetEffectiveReminderWindows(c,row,o,at(c,'2026-03-08','12:00 AM'),at(c,'2026-03-09','12:00 AM')),0)
dst.eventDate='2026-11-02';c=assert(s:NormalizeSchedule(dst));row=c.reminders[1];o=s:BuildScheduleOccurrence(c,c.eventAtUtc)
windows=s:GetEffectiveReminderWindows(c,row,o,at(c,'2026-11-01','12:00 AM'),at(c,'2026-11-02','12:00 AM'));eq(windows[1].finish-windows[1].start,25*3600)
row.availability.startMinute=90;row.availability.endMinute=105;windows=s:GetEffectiveReminderWindows(c,row,o,at(c,'2026-11-01','12:00 AM'),at(c,'2026-11-02','12:00 AM'));eq(windows[1].finish-windows[1].start,75*60)
-- Confirmation counts; preparing and retry timeout do not. Manual and
-- time-sensitive delivery cannot bypass a cap, including while queued.
f.reset();local entry=f.entry('msg','ad','Amber Traders','Availability announcement','Guild')
local d=draft({enabled=true,startMinute=420,endMinute=1320,maxPerDay=1});d.reminders[1].timeSensitive=true;assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');row=c.reminders[1];now=at(c,'2026-10-27','08:00 AM')
assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:ProcessChatPopulationQueue();local pending=assert(s.pendingRestoreState);eq(s:GetReminderAvailabilityCount(c,row,now),0)
s:HandleScheduledPopulateTimeout(pending.metadata);eq(s:GetReminderAvailabilityCount(c,row,now),0)
CHAT_SYSTEM:GetEditControl():SetText('');s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_GUILD_1,'My Character',pending.rawExpectedText,false,'@Me');eq(s:GetReminderAvailabilityCount(c,row,now),1);assert(not s:RequestScheduledDelivery('ad','Amber Traders',true))
now=at(c,'2026-10-28','08:00 AM');eq(s:GetReminderAvailabilityCount(c,row,now),0)
CHAT_SYSTEM:GetEditControl():SetText('Draft');assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:RecordReminderAvailabilityUsage(c,row,now);CHAT_SYSTEM:GetEditControl():SetText('');s:ProcessChatPopulationQueue();eq(s.pendingRestoreState,nil,'queued manual cap rechecked')
-- Relevant peers count even while the schedule/row is paused or outside hours;
-- overnight caps use the send date, not the opening date.
now=at(c,'2026-10-29','02:00 AM');c.paused=true;row.paused=true;f.incoming(CHAT_CHANNEL_GUILD_1,entry.text);eq(s:GetReminderAvailabilityCount(c,row,now),1);eq(c.availabilityUsage['row:2026-10-28'].count,1)
local before=s:GetReminderAvailabilityCount(c,row,now);local unrelated=f.entry('other','ad','Amber Traders','Different announcement','Guild');s:MarkObservedChatUsage(unrelated,'Amber Traders','Guild');eq(s:GetReminderAvailabilityCount(c,row,now),before)
-- Today's old timeline history bootstraps one without counting preparation.
c.availabilityUsage={};c.timelineUsage={['old:row']={lastSentAt=now-10,peerAt=now-5}};eq(s:GetReminderAvailabilityCount(c,row,now),1)
-- Hour changes and portable imports preserve recipient daily counters.
c.paused=false;row.paused=false;local edit=copy(c);edit.availabilityUsage={};edit.reminders[1].availability.startMinute=480;assert(s:SaveGuildSchedule('ad','Amber Traders',edit));c=s:GetGuildSchedule('ad','Amber Traders');eq(c.availabilityUsage['row:2026-10-29'].count,1)
ZO_SavedVars={NewAccountWide=function() return s.savedVars end};s:InitializeSavedVars();c=s:GetGuildSchedule('ad','Amber Traders');eq(c.availabilityUsage['row:2026-10-29'].count,1)
c.reminders[1].availability.dateOverrides={['2026-10-30']={startMinute=540,endMinute=1200}};c.reminders[1].availability.weekdayOverrides={[3]={startMinute=600,endMinute=1260}}
local exported=s:BuildExportString();assert(exported:find('SCHEDULEAVAILABILITY_V1',1,true));assert(not exported:find('availabilityUsage',1,true));assert(s:ImportSettingsFromString(exported));c=s:GetGuildSchedule('ad','Amber Traders');eq(c.availabilityUsage['row:2026-10-29'].count,1);eq(c.reminders[1].availability.dateOverrides['2026-10-30'].startMinute,540);eq(c.reminders[1].availability.weekdayOverrides[3].endMinute,1260)
s:ResetAllCooldowns();eq(next(c.availabilityUsage),nil)
for _,bad in ipairs({{enabled=true,startMinute=420,endMinute=420},{enabled=false,startMinute=-1},{enabled=true,endMinute=0},{enabled=true,maxPerDay=0},{enabled=true,maxPerDay=math.huge},{enabled=true,weekdays={[8]=true}},{enabled=true,dateOverrides={['2026-02-30']={startMinute=0,endMinute=1440}}},{enabled=true,weekdayOverrides={[3]={startMinute=0,endMinute=0}}}}) do assert(not s:NormalizeSchedule(draft(bad))) end
-- Native controls edit/reset overrides without touching the cap or counters.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end;s.RefreshSettingsUI=function() end;s.scheduleEditor=nil
local controls=s:BuildScheduleOptionControls();local function find(list,name) for _,control in ipairs(list) do if control.name==name then return control end;if control.controls then local hit=find(control.controls,name);if hit then return hit end end end end
find(controls,'Limit reminder availability').setFunc(true);find(controls,'Allowed from (HH:MM)').setFunc('07:00');find(controls,'Maximum announcements per server day (optional)').setFunc('2');find(controls,'Available on Sunday').setFunc(false)
find(controls,'Override weekday').setFunc('Tuesday');find(controls,'Weekday override from (HH:MM)').setFunc('08:00');local editor=s:GetScheduleEditorDraft();eq(editor.reminders[1].availability.weekdayOverrides[3].startMinute,480)
find(controls,'Reset selected weekday hours').func();eq(editor.reminders[1].availability.weekdayOverrides[3],nil)
find(controls,'Override opening date').setFunc(s:ScheduleDateToPicker('2026-10-30'));find(controls,'Date override from (HH:MM)').setFunc('09:00');eq(editor.reminders[1].availability.dateOverrides['2026-10-30'].startMinute,540)
find(controls,'Reset selected date hours').func();eq(editor.reminders[1].availability.dateOverrides['2026-10-30'],nil);eq(editor.reminders[1].availability.maxPerDay,2)
-- Date edits inherit weekday override hours, including the untouched edge;
-- resetting a date returns to weekday hours without resetting counts/caps.
find(controls,'Override weekday').setFunc('Friday');find(controls,'Weekday override from (HH:MM)').setFunc('08:00');find(controls,'Weekday override until (HH:MM)').setFunc('20:00')
eq(find(controls,'Date override from (HH:MM)').getFunc(),'08:00');eq(find(controls,'Date override until (HH:MM)').getFunc(),'20:00')
find(controls,'Date override until (HH:MM)').setFunc('21:00');eq(editor.reminders[1].availability.dateOverrides['2026-10-30'].startMinute,480);eq(editor.reminders[1].availability.dateOverrides['2026-10-30'].endMinute,1260)
find(controls,'Reset selected date hours').func();eq(find(controls,'Date override until (HH:MM)').getFunc(),'20:00');eq(editor.reminders[1].availability.maxPerDay,2)
-- Month-final fallback uses actual templates in this reminder's selected pool.
f.reset();local regular=f.entry('msg','ad','Amber Traders','Regular pool notice','Guild');local final=f.entry('final','ad','Amber Traders','Final pool notice','Guild')
d=draft({enabled=true,startMinute=420,endMinute=1320,maxPerDay=10});d.recurrence='WEEKLY';d.specialPattern='MONTH_FINAL';d.messageVariants={msg='REGULAR',final='FINAL'}
assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');row=c.reminders[1];now=at(c,'2026-10-29','02:00 AM');c.paused=true
eq(s:GetScheduleEventVariant(c,c.eventAtUtc),'FINAL');f.incoming(CHAT_CHANNEL_GUILD_1,regular.text);eq(s:GetReminderAvailabilityCount(c,row,now),1,'final template outside this row pool must not disable regular fallback')
row.messageIds={'msg','final'};f.incoming(CHAT_CHANNEL_GUILD_1,regular.text);eq(s:GetReminderAvailabilityCount(c,row,now),1,'regular peer cannot count when this row has a final pool')
f.incoming(CHAT_CHANNEL_GUILD_1,final.text);eq(s:GetReminderAvailabilityCount(c,row,now),2)
-- An irrelevant group cannot bootstrap a false count through legacy peerAt.
c.availabilityUsage={};c.timelineUsage={};c.paused=false;now=at(c,'2026-10-29','08:00 AM');f.incoming(CHAT_CHANNEL_GUILD_1,regular.text);eq(s:GetReminderAvailabilityCount(c,row,now),0)
row.messageIds={'msg'};f.incoming(CHAT_CHANNEL_GUILD_1,regular.text);eq(s:GetReminderAvailabilityCount(c,row,now),1)
-- A physical peer announcement can match duplicate-text templates in multiple
-- rows. Count every relevant row once, even if the first template is expired.
f.reset();f.entry('expired','ad','Amber Traders','Shared peer text','Guild');f.entry('active','ad','Amber Traders','Shared peer text','Guild');f.entry('duplicate','ad','Amber Traders','Shared peer text','Guild')
d=draft({enabled=true,maxPerDay=1});d.reminders[1].messageIds={'active','duplicate'};local expired=copy(d.reminders[1]);expired.id='expired-row';expired.messageIds={'expired'};expired.start.minutes=-28800;expired.finish.minutes=-20000;table.insert(d.reminders,1,expired)
assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');now=at(c,'2026-10-29','08:00 AM');f.incoming(CHAT_CHANNEL_GUILD_1,'Shared peer text')
eq(s:GetReminderAvailabilityCount(c,c.reminders[1],now),0);eq(s:GetReminderAvailabilityCount(c,c.reminders[2],now),1);assert(not s:RequestScheduledDelivery('ad','Amber Traders',true))
f.incoming(CHAT_CHANNEL_GUILD_1,'Shared peer text');eq(s:GetReminderAvailabilityCount(c,c.reminders[2],now),2,'one increment per physical message, not per duplicate template')
-- Source legacy timelineUsage must not bootstrap a fresh recipient's daily cap.
f.reset();f.entry('msg','ad','Amber Traders','Portable capped notice','Guild');d=draft({enabled=true,maxPerDay=1});assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');now=at(c,'2026-10-29','08:00 AM')
c.timelineUsage={[tostring(c.eventAtUtc)..':row']={lastSentAt=now,peerAt=now,nextDueAt=now+1800}};local source=s:BuildExportString();local recipientClock=now
f.reset();now=recipientClock;assert(s:ImportSettingsFromString(source));c=s:GetGuildSchedule('ad','Amber Traders');eq(s:GetReminderAvailabilityCount(c,c.reminders[1],now),0,'source history is not recipient daily usage')
-- Existing recipient history still bootstraps when its explicit counter is absent.
c.availabilityUsage={};c.timelineUsage={[tostring(c.eventAtUtc)..':row']={lastSentAt=now-10}};assert(s:ImportSettingsFromString(source));c=s:GetGuildSchedule('ad','Amber Traders');eq(s:GetReminderAvailabilityCount(c,c.reminders[1],now),1)
print('Reminder availability normalization, effective civil/DST slices, caps, confirmation/peer counters, queue/manual gating, transfer and native controls passed')
