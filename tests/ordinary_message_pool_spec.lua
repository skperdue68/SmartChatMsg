local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local function setup()
 f.reset();s.lastTimedOutMessage=nil;f.entry('disabled','ad','Amber Traders','Disabled notice','Guild');f.entry('enabled','ad','Amber Traders','Enabled notice','Guild')
 local settings=s:GetCommandGuildSettings('ad','Amber Traders',true);settings.disabledMessageIds={disabled=true};return settings
end
local settings=setup()
assert(s:PopulateChatBufferForCommand('ad','Amber Traders',nil,{}));eq(s.pendingRestoreState.metadata.selectedEntryId,'enabled','ordinary selection excludes disabled templates');eq(#s:GetMessageEntriesForCommandAndGuild('ad','Amber Traders'),2,'library remains complete')
settings=setup();assert(s:SetOrdinaryMessageEnabled('ad','Amber Traders','enabled',false));local ok,reason=s:PopulateChatBufferForCommand('ad','Amber Traders',nil,{});assert(not ok and reason:find('No enabled messages',1,true));eq(s.pendingRestoreState,nil)
assert(s:SetOrdinaryMessageEnabled('ad','Amber Traders','disabled',true));eq(settings.disabledMessageIds.disabled,nil);assert(s:IsOrdinaryMessageEnabled('ad','Amber Traders','disabled'))
-- All ordinary delivery paths use the same filter, including startup and Zone.
for _,metadata in ipairs({{startupQueue=true},{autoPopulate=true,zoneId=41},{reminderRepeat=true}}) do
 setup();assert(s:PopulateChatBufferForCommand('ad','Amber Traders',nil,metadata));eq(s.pendingRestoreState.metadata.selectedEntryId,'enabled')
end
-- Queued requests reselect against current configuration without exposing drafts.
settings=setup();settings.disabledMessageIds={};CHAT_SYSTEM:GetEditControl():SetText('Player draft');assert(s:PopulateChatBufferForCommand('ad','Amber Traders',nil,{}));assert(s:SetOrdinaryMessageEnabled('ad','Amber Traders','disabled',false));eq(CHAT_SYSTEM:GetEditControl():GetText(),'Player draft');CHAT_SYSTEM:GetEditControl():SetText('');s:ProcessChatPopulationQueue();eq(s.pendingRestoreState.metadata.selectedEntryId,'enabled')
-- Disabling a prepared template withdraws untouched text, preserving edits.
for _,edited in ipairs({false,true}) do
 settings=setup();settings.disabledMessageIds={};assert(s:PopulateChatBufferForCommand('ad','Amber Traders',nil,{}));eq(s.pendingRestoreState.metadata.selectedEntryId,'disabled')
 if edited then CHAT_SYSTEM:GetEditControl():SetText('My edited message') end
 assert(s:SetOrdinaryMessageEnabled('ad','Amber Traders','disabled',false));eq(s.pendingRestoreState,nil);eq(CHAT_SYSTEM:GetEditControl():GetText(),edited and 'My edited message' or '')
end
-- Explicit retry cannot restore a template disabled since its timeout.
settings=setup();settings.disabledMessageIds={};assert(s:PopulateChatBufferForCommand('ad','Amber Traders',nil,{}));EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback();assert(s.lastTimedOutMessage);assert(s:SetOrdinaryMessageEnabled('ad','Amber Traders','disabled',false));assert(not s:RetryTimedOutMessage());eq(s.pendingRestoreState,nil)
-- Scheduled rows ignore ordinary flags; switching back restores those flags.
settings=setup();settings.disabledMessageIds={disabled=true,enabled=true};assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-10-30',eventTime='08:00 PM',promotionDays=1,endDelayMinutes=30,intervalMinutes=30}))
local config=s:GetGuildSchedule('ad','Amber Traders');now=config.eventAtUtc-3600;eq(#s:GetScheduledMessageEntries('ad','Amber Traders'),2);assert(s:PopulateChatBufferForCommand('ad','Amber Traders',nil,{}));eq(s.pendingRestoreState.metadata.selectedEntryId,'disabled');s:ClearPendingRestoreState('test');CHAT_SYSTEM:GetEditControl():SetText('');assert(s:SetGuildRunAt('ad','Amber Traders','ON_DEMAND'));assert(not s:PopulateChatBufferForCommand('ad','Amber Traders',nil,{}))
-- Disabled templates still match other players and advance combination usage.
setup();assert(s:SetGuildReminderMinutes('ad','Amber Traders',5));now=now+10;f.incoming(CHAT_CHANNEL_GUILD_1,'Disabled notice');eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now)
-- SavedVars normalizes only true entries; edits and portable settings preserve it.
settings=setup();settings.disabledMessageIds.enabled=false;settings.disabledMessageIds[3]=true;settings.disabledMessageIds['']=true;ZO_SavedVars={NewAccountWide=function() return s.savedVars end};s:InitializeSavedVars();settings=s:GetCommandGuildSettings('ad','Amber Traders',false);eq(settings.disabledMessageIds.disabled,true);eq(settings.disabledMessageIds.enabled,nil);eq(settings.disabledMessageIds[3],nil);eq(settings.disabledMessageIds[''],nil)
s.savedVars.selectedMessagesCommand='ad';s.savedVars.selectedMessagesGuildIndex=1;s.savedVars.selectedMessagesChannel='Guild'
assert(s:UpdateMessageEntry('disabled','Updated disabled notice'));eq(settings.disabledMessageIds.disabled,true)
local exported=s:BuildExportString();assert(exported:find('MESSAGEPOOL_V1|ad|Amber Traders|disabled',1,true));assert(s:ImportSettingsFromString(exported));eq(s:GetCommandGuildSettings('ad','Amber Traders',false).disabledMessageIds.disabled,true)
-- Portable guild identity follows names when the receiver reorders slots.
local getName=GetGuildName;GetGuildName=function(id) if id==101 then return 'Blue Traders' elseif id==202 then return 'Amber Traders' end;return '' end
assert(s:ImportSettingsFromString(exported));eq(s:GetCommandGuildSettings('ad','Amber Traders',false).disabledMessageIds.disabled,true);GetGuildName=getName
-- UUIDs remain distinct when identical text has different ordinary pool states.
settings=setup();s.savedVars.messages[2].text='Disabled notice';exported=s:BuildExportString();assert(s:ImportSettingsFromString(exported));eq(#s.savedVars.messages,2);eq(#s:GetOrdinaryMessageEntriesForCommandAndGuild('ad','Amber Traders'),1);eq(s:GetOrdinaryMessageEntriesForCommandAndGuild('ad','Amber Traders')[1].id,'enabled')
-- Local locks retain private ordinary pool membership across command-ID remaps.
settings=setup();assert(s:SetMessageLocked('disabled',true));exported=s:BuildExportString();assert(not exported:find('MESSAGEPOOL_V1|ad|Amber Traders|disabled',1,true));assert(s:ImportSettingsFromString(exported:gsub('|ad|','|new-command|')));eq(s:GetCommandGuildSettings('new-command','Amber Traders',false).disabledMessageIds.disabled,true)
-- A source with no per-guild behavior record cannot enable a private local lock.
local minimal=exported:gsub('GUILDSETTING[^\n]*\n','')
assert(s:ImportSettingsFromString(minimal:gsub('|ad|','|new-command|')));eq(s:GetCommandGuildSettings('new-command','Amber Traders',false).disabledMessageIds.disabled,true)
print('Ordinary pool controls filter manual/startup/Zone/repeat/retry, retain scheduled/library/peer behavior, and survive editing, reload and portable UUID transfer')
