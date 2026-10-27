local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('notice','ad','Amber Traders','Retry notice','Guild')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',10));assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',60));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40))
eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),10,'Retry cannot exceed Repeat even when Cooldown is larger');eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),10)
assert(s:SetGuildRunAt('ad','Amber Traders','STARTUP'));eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),10)
assert(s:SetGuildReminderMinutes('ad','Amber Traders',60));assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',10));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),10,'Retry cannot exceed Cooldown when Repeat is larger')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',120));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',90));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),10,'raising Repeat does not bypass smaller Cooldown')
assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',60));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),40)
assert(s:SetGuildReminderMinutes('ad','Amber Traders',25));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),25,'lowering Repeat clamps stored Retry')
assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',15));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),15,'lowering Cooldown clamps stored Retry')
assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',100));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',90));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),25,'raising Cooldown does not bypass smaller Repeat')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',''));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),0);eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),0);assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),0,'no repeat means no automatic retry')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',10));assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',60));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40))
-- Real timeout scheduling observes the lower limit, never the requested 40.
local settings=s:GetCommandGuildSettings('ad','Amber Traders',false);settings.lastUsedAt=now-1
s:SetReminderAutomationActive('ad','Amber Traders',true);s:HandleReminderPopulateTimeout({commandId='ad',guildName='Amber Traders',lastUsedAt=now-1})
local timer=assert(EVENT_MANAGER.updates[s:GetReminderTimerName('ad','Amber Traders')]);eq(timer.delay,10*60*1000)
local schedule=s.ScheduleCommandReminder;local fallback=0;s.ScheduleCommandReminder=function() fallback=fallback+1 end
assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',0));s:HandleReminderPopulateTimeout({commandId='ad',guildName='Amber Traders',lastUsedAt=now-1});eq(fallback,1);s.ScheduleCommandReminder=schedule
-- Legacy/raw larger values are safely effective-capped across reload/import.
settings.reminderRetryMinutes=40;ZO_SavedVars={NewAccountWide=function() return s.savedVars end};s:InitializeSavedVars();eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),10)
assert(s:ImportSettingsFromString(s:BuildExportString()));eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),10)
-- Scheduled combinations keep their existing active schedule interval cap.
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-10-30',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=60,intervalMinutes=30}))
local cfg=s:GetGuildSchedule('ad','Amber Traders');now=cfg.eventAtUtc-3600
assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40));eq(s:GetGuildAutoPopulateCooldownMinutes('ad','Amber Traders'),30);eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),30)
-- Native save applies new mode, Repeat and Cooldown before the requested Retry.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end;s.IsMessagesSelectionComplete=function() return true end
s.settings.pendingGuildRunAt='ON_DEMAND';s.settings.pendingGuildReminderMinutes='60';s.settings.pendingGuildReminderRetryMinutes='40';s.settings.pendingGuildAutoPopulateCooldownMinutes='50';s.settings.pendingGuildAutoPopulateOnZone=false
assert(s.settings:SaveBehaviorSettings());eq(s:GetGuildRunAt('ad','Amber Traders'),'ON_DEMAND');eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),40)
s.settings.pendingGuildReminderMinutes='10';assert(s.settings:SaveBehaviorSettings());eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),10)
s.settings.pendingGuildReminderMinutes='60';s.settings.pendingGuildAutoPopulateCooldownMinutes='5';assert(s.settings:SaveBehaviorSettings());eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),5)
print('Retry caps to min(Repeat, Cooldown), both setters clamp saved Retry, and timeout/reload/import/native saves preserve the final rule')
