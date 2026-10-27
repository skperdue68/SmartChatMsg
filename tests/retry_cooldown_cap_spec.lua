local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('notice','ad','Amber Traders','Retry notice','Guild')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',10));assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',60));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40))
eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),40,'retry longer than Repeat must be retained when Cooldown permits')
eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),40)
assert(s:SetGuildRunAt('ad','Amber Traders','STARTUP'));eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),40)
assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',30));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),30,'lowering Cooldown clamps the saved Retry')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',5));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),30);eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),30,'lowering Repeat cannot cap Retry')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',''));eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),0,'no repeat means no automatic retry')
assert(s:SetGuildReminderMinutes('ad','Amber Traders',10));assert(s:SetGuildAutoPopulateCooldownMinutes('ad','Amber Traders',60));assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40))
-- The actual ordinary timeout timer uses Retry, even when it exceeds Repeat.
local settings=s:GetCommandGuildSettings('ad','Amber Traders',false);settings.lastUsedAt=now-1
s:SetReminderAutomationActive('ad','Amber Traders',true);s:HandleReminderPopulateTimeout({commandId='ad',guildName='Amber Traders',lastUsedAt=now-1})
local timer=assert(EVENT_MANAGER.updates[s:GetReminderTimerName('ad','Amber Traders')]);eq(timer.delay,40*60*1000)
local schedule=s.ScheduleCommandReminder;local fallback=0;s.ScheduleCommandReminder=function() fallback=fallback+1 end
assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',0));s:HandleReminderPopulateTimeout({commandId='ad',guildName='Amber Traders',lastUsedAt=now-1});eq(fallback,1);s.ScheduleCommandReminder=schedule
-- Loaded larger values are capped by Cooldown, not Repeat, and roundtrip.
settings.reminderRetryMinutes=40;ZO_SavedVars={NewAccountWide=function() return s.savedVars end};s:InitializeSavedVars();eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),40)
assert(s:ImportSettingsFromString(s:BuildExportString()));eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),40);eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),40)
-- Scheduled combinations retain the existing schedule interval cooldown cap.
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-10-30',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=60,intervalMinutes=30}))
local cfg=s:GetGuildSchedule('ad','Amber Traders');now=cfg.eventAtUtc-3600
assert(s:SetGuildReminderRetryMinutes('ad','Amber Traders',40));eq(s:GetGuildAutoPopulateCooldownMinutes('ad','Amber Traders'),30);eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),30)
-- Native behavior saving must apply the new mode and cooldown before Retry:
-- otherwise an old scheduled interval/cooldown silently destroys a valid value.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end;s.IsMessagesSelectionComplete=function() return true end
s.settings.pendingGuildRunAt='ON_DEMAND';s.settings.pendingGuildReminderMinutes='10';s.settings.pendingGuildReminderRetryMinutes='40';s.settings.pendingGuildAutoPopulateCooldownMinutes='60';s.settings.pendingGuildAutoPopulateOnZone=false
assert(s.settings:SaveBehaviorSettings());eq(s:GetGuildRunAt('ad','Amber Traders'),'ON_DEMAND');eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),40);eq(s:GetGuildEffectiveReminderRetryMinutes('ad','Amber Traders'),40)
s.settings.pendingGuildAutoPopulateCooldownMinutes='25';assert(s.settings:SaveBehaviorSettings());eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),25)
print('Retry caps to Cooldown independently of Repeat, preserves no-repeat/scheduled behavior, and saves/times out/roundtrips correctly')
