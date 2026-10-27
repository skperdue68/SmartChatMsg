local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();local notices={};s.AddLocalChatMessage=function(_,v)notices[#notices+1]=v end
f.entry('scheduled','ad','Amber Traders','Scheduled family notice.','Guild');f.entry('ordinary','other','Blue Traders','Ordinary notice.','Zone')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',recurrence='WEEKLY',timelineVersion=1,importantTimes={},reminders={{id='period',label='Promotion',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=15,lateMinutes=5,messageIds={'scheduled'}}}}))
assert(s:SetGuildRunAt('ad','Amber Traders','SCHEDULED'));local schedule=s:GetGuildSchedule('ad','Amber Traders');now=schedule.eventAtUtc-1800
s:TickSchedules();assert(s.pendingRestoreState);eq(s.pendingRestoreState.metadata.commandId,'ad')
assert(s:HandleScmCommand('OFF'));eq(s.savedVars.scheduledSendingEnabled,false);eq(s.pendingRestoreState,nil);eq(CHAT_SYSTEM.textEntry.editControl.text,'');assert(schedule.enabled)
assert(not s:RequestScheduledDelivery('ad','Amber Traders',true));assert(not s:PopulateChatBufferForCommand('ad','Amber Traders','Guild',{}));s:TickSchedules();eq(s.pendingRestoreState,nil)
local occurrence=s:GetScheduleOccurrence(schedule,now);local phase=s:GetSchedulePhase(schedule,now)
s:QueueChatPopulation('ad','Amber Traders','Guild',{scheduledDelivery=true,scheduledPhase=phase,scheduledOccurrence=occurrence.occurrenceKey},3)
s:ProcessChatPopulationQueue();eq(s.pendingRestoreState,nil,'queued scheduled work is revalidated against OFF')

assert(s:GetStatusPanelHeaderText():find('Scheduled sending: OFF',1,true))
-- Passive peer detection stays alive and still updates the recipient cooldown.
f.incoming(CHAT_CHANNEL_GUILD_1,'Scheduled family notice.');assert(s:GetGuildLastUsedAt('ad','Amber Traders'))
-- Ordinary manual, Startup and zone-driven messages remain permitted.
for _,mode in ipairs({'ON_DEMAND','STARTUP'})do
 assert(s:SetGuildRunAt('other','Blue Traders',mode));assert(s:PopulateChatBufferForCommand('other','Blue Traders','Zone',{}));s:ClearPendingChatBuffer();s:ClearPendingRestoreState()
end
assert(s:SetGuildRunAt('other','Blue Traders','ON_DEMAND'));assert(s:PopulateChatBufferForCommand('other','Blue Traders','Zone',{autoPopulate=true,zoneId=s:GetPlayerZoneId()}));s:ClearPendingChatBuffer();s:ClearPendingRestoreState()
ZO_SavedVars={NewAccountWide=function()return s.savedVars end};s:InitializeSavedVars();eq(s:IsScheduledSendingEnabled(),false)
s:InitializeScheduler();assert(table.concat(notices,'\n'):find('Use /scm on',1,true));eq(s.pendingRestoreState,nil)
assert(s:HandleScmCommand('on'));eq(s:IsScheduledSendingEnabled(),true)
-- Resuming does not bypass the startup wait or observed cooldown.
eq(s.pendingRestoreState,nil);s.scheduleStartupEndsAt=nil;s:ResetAllCooldowns();assert(s.pendingRestoreState)
s.scheduledSendPause={senderKey='other',endsAt=now+300};assert(s:GetStatusPanelHeaderText():find('Other schedules wait',1,true));now=now+301;assert(not s:GetStatusPanelHeaderText():find('Other schedules wait',1,true))
-- Every built-in action is reserved, including case/leading punctuation variants.
for _,name in ipairs({'on','OFF','schedule','status','retry','resetcooldowns','send','scm','scmdebug','/On'})do
 local ok,reason=s:AddCommand(name);eq(ok,false);assert(reason:find('reserved',1,true));eq(s:RenameCommand('other',name),false)
end
local before=s.savedVars;assert(not s:ImportSettingsFromString('SCM_EXPORT_V2\nCOMMAND|bad|off||\nEND'));eq(s.savedVars,before)
print('PASS saved scheduled switch, queue/pending protection, passive monitoring, ordinary delivery, header and reserved names')
