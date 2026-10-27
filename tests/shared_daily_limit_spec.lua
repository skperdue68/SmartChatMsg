local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local function copy(v) if type(v)~='table' then return v end;local r={};for k,x in pairs(v) do r[k]=copy(x) end;return r end
local function draft()
 local d={mode='EVENT',enabled=true,eventDate='2026-11-02',eventTime='08:00 PM',timelineVersion=1,importantTimes={},reminders={}}
 for i=1,2 do d.reminders[i]={id='p'..i,label='Period '..i,start={kind='OFFSET',minutes=-10080},finish={kind='OFFSET',minutes=4320},intervalMinutes=30,messageIds={'m'..(i*2-1),'m'..(i*2)},availability={enabled=false,maxPerDay=2}} end
 return d
end
f.reset();for i=1,4 do f.entry('m'..i,'ad','Amber Traders','Shared text','Guild') end
local d=draft();d.dailyLimitShared=true;d.sharedDailyLimit=2;assert(s:SaveGuildSchedule('ad','Amber Traders',d))
local c=s:GetGuildSchedule('ad','Amber Traders');local function at(date,time,fold) return assert(s:ParseScheduleDateTime(date,time or '12:00 PM',fold or 'FIRST',c)) end
now=at('2026-10-29');local o=s:GetScheduleOccurrence(c,now)
eq(s:GetReminderDailyLimit(c,c.reminders[1],now).count,0)
f.incoming(CHAT_CHANNEL_GUILD_1,'Shared text');eq(s:GetScheduleDailyLimitCount(c,now),1)
for _,r in ipairs(c.reminders) do eq(s:GetReminderAvailabilityCount(c,r,now),1) end
c.paused=true;c.reminders[1].paused=true;f.incoming(CHAT_CHANNEL_GUILD_1,'Shared text');eq(s:GetScheduleDailyLimitCount(c,now),2)
for _,r in ipairs(c.reminders) do local q=s:GetReminderDailyLimit(c,r,now);assert(q.shared and q.reached);eq(q.limit,2);assert(not s:GetReminderAvailabilityStatus(c,r,o,now)) end
c.dailyLimitShared=false;c.reminders[1].availability.maxPerDay=3;assert(not s:GetReminderDailyLimit(c,c.reminders[1],now).reached);assert(s:GetReminderDailyLimit(c,c.reminders[2],now).reached)
c.sharedDailyLimit=nil;c.dailyLimitShared=true;assert(not s:GetReminderDailyLimit(c,c.reminders[1],now).reached)
s:HandleScheduledSendConfirmed({scheduledDelivery=true,commandId='ad',guildName='Amber Traders',scheduledPhase='p1',scheduledOccurrence=o.occurrenceKey})
eq(s:GetScheduleDailyLimitCount(c,now),3);eq(s:GetReminderAvailabilityCount(c,c.reminders[1],now),3)
ZO_SavedVars={NewAccountWide=function() return s.savedVars end};local export=f.currentExport();assert(export:find('SCHEDULEDAILYLIMIT_V1|ad|Amber Traders|1|',1,true));assert(not export:find('_command:',1,true))
assert(s:ImportSettingsFromString(export));c=s:GetGuildSchedule('ad','Amber Traders');eq(s:GetScheduleDailyLimitCount(c,now),3)
ZO_SavedVars={NewAccountWide=function() return s.savedVars end};s:InitializeSavedVars();c=s:GetGuildSchedule('ad','Amber Traders');eq(s:GetScheduleDailyLimitCount(c,now),3)
local edited=copy(c);edited.dailyLimitShared=false;assert(s:SaveGuildSchedule('ad','Amber Traders',edited));c=s:GetGuildSchedule('ad','Amber Traders');eq(s:GetScheduleDailyLimitCount(c,now),3)
now=at('2026-10-30','12:00 AM');eq(s:GetScheduleDailyLimitCount(c,now),0)
local first=at('2026-11-01','01:30 AM','FIRST');local second=at('2026-11-01','01:30 AM','SECOND');s:RecordScheduleDailyLimitUsage(c,first);eq(s:GetScheduleDailyLimitCount(c,second),1);eq(s:GetScheduleDailyLimitCount(c,at('2026-11-02','12:00 AM')),0)
c.availabilityUsage={['p1:2026-10-29']={count=2,lastAt=at('2026-10-29')},['p2:2026-10-29']={count=1,lastAt=at('2026-10-29')}};eq(s:GetScheduleDailyLimitCount(c,at('2026-10-29')),3)
for _,bad in ipairs({0,-1,1.5,1001,'2',math.huge}) do local x=draft();x.sharedDailyLimit=bad;assert(not s:NormalizeSchedule(x)) end
local x=draft();x.dailyLimitShared='yes';assert(not s:NormalizeSchedule(x))
local recipientTime=now;f.reset();now=recipientTime;assert(s:ImportSettingsFromString(export));c=s:GetGuildSchedule('ad','Amber Traders');eq(s:GetScheduleDailyLimitCount(c,now),0)
print('PASS shared quota scopes, peer deduplication, hours disabled, mode switches, import/reload, civil midnight and DST')

-- The slider lives beside frequency, while Availability contains only hours/day controls.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function()return 'Amber Traders'end;s.RefreshSettingsUI=function()end;s.scheduleEditor=nil
local controls=s:BuildScheduleOptionControls()
local function find(list,name) for _,v in ipairs(list) do if v.reference==name or v.name==name then return v end;if v.controls then local hit=find(v.controls,name);if hit then return hit end end end end
local pane=find(controls,'SCM_TimelineSubmenu').controls;local slider=find(pane,'SCM_PeriodDailyLimitSlider');local checkbox=find(pane,'Share daily limit across this command and guild')
assert(slider and checkbox and slider.tooltip:find('midnight',1,true));assert(not find(find(pane,'Reminder availability').controls,'SCM_PeriodDailyLimitSlider'))
local frequencyIndex;for i,v in ipairs(pane) do if v.reference=='SCM_PeriodFrequencySlider' then frequencyIndex=i end end;eq(pane[frequencyIndex+1],slider);eq(pane[frequencyIndex+2],checkbox)
checkbox.setFunc(false);slider.setFunc(3);local editor=s:GetScheduleEditorDraft();eq(editor.reminders[1].availability.maxPerDay,3)
checkbox.setFunc(true);slider.setFunc(1);eq(editor.sharedDailyLimit,1);eq(editor.reminders[1].availability.maxPerDay,3);slider.setFunc(0);eq(editor.sharedDailyLimit,nil);eq(slider.getFunc(),0)
for _,record in ipairs({'SCHEDULEDAILYLIMIT_V1|ad|Amber Traders|2|1','SCHEDULEDAILYLIMIT_V1|ad|Amber Traders|1|0','SCHEDULEDAILYLIMIT_V1|ad|Amber Traders|1|abc','SCHEDULEDAILYLIMIT_V1|ad|Amber Traders|1|1001'}) do
 local bad=export:gsub('SCHEDULEDAILYLIMIT_V1[^\n]*',function()return record end);assert(not s:ImportSettingsFromString(bad),record)
end
assert(not s:ImportSettingsFromString((export:gsub('(SCHEDULEDAILYLIMIT_V1[^\n]*)',function(line)return line..'\nSCHEDULEDAILYLIMIT_V1|ad|Amber Traders|1|1' end))))
-- Once and time-sensitive delivery obey caps even with hours disabled; no prep or timeout counts.
f.reset();f.entry('m1','ad','Amber Traders','Prepared quota test','Guild');d=draft();d.reminders={d.reminders[1]};d.reminders[1].once=true;d.reminders[1].timeSensitive=true;d.dailyLimitShared=true;d.sharedDailyLimit=1
assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');now=s:ResolveTimelineAnchor(c,{eventAtUtc=c.eventAtUtc},c.reminders[1].start)
assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:ProcessChatPopulationQueue();local pending=assert(s.pendingRestoreState)
eq(s:GetScheduleDailyLimitCount(c,now),0);s:HandleScheduledPopulateTimeout(pending.metadata);eq(s:GetScheduleDailyLimitCount(c,now),0)
CHAT_SYSTEM:GetEditControl():SetText('');s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_GUILD_1,'My Character',pending.rawExpectedText,false,'@Me');eq(s:GetScheduleDailyLimitCount(c,now),1);assert(not s:RequestScheduledDelivery('ad','Amber Traders',true))
-- Recipient command IDs can differ when merging portable settings.
local portable=f.currentExport();s.savedVars.commands[1].id='recipient';s.savedVars.commandGuildSettings.recipient=s.savedVars.commandGuildSettings.ad;s.savedVars.commandGuildSettings.ad=nil
for _,entry in ipairs(s.savedVars.messages) do entry.commandId='recipient' end
assert(s:ImportSettingsFromString(portable));c=s:GetGuildSchedule('ad','Amber Traders');eq(s:GetScheduleDailyLimitCount(c,now),1)
print('PASS native quota placement/scope editing, malformed records, once/time-sensitive preparation, and command remap')

-- Irrelevant variant observations must not reappear through legacy timeline bootstrap when hours are off.
f.reset();f.entry('m1','ad','Amber Traders','Regular variant','Guild');f.entry('m2','ad','Amber Traders','Final variant','Guild');d=draft();d.reminders={d.reminders[1]};d.specialPattern='MONTH_FINAL';d.recurrence='WEEKLY';d.eventDate='2026-10-30';d.messageVariants={m1='REGULAR',m2='FINAL'}
assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders');now=at('2026-10-29');f.incoming(CHAT_CHANNEL_GUILD_1,'Regular variant');eq(s:GetReminderAvailabilityCount(c,c.reminders[1],now),0);eq(s:GetScheduleDailyLimitCount(c,now),0)
