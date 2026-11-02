local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local guild='Amber Traders'
for _,output in ipairs({'Guild','Officer'}) do
 for _,enabled in ipairs({false,true}) do
  f.reset();local a=f.entry('a','ad',guild,'%guild% trial starts soon!',output)
  f.entry('b','other',guild,'%guild% trial starts soon!',output)
  s:SetGuildShareGuildOfficerCooldowns('ad',guild,enabled)
  eq(s:GetGuildShareGuildOfficerCooldowns('other',guild),false)
  local cross=output=='Guild' and CHAT_CHANNEL_OFFICER_1 or CHAT_CHANNEL_GUILD_1
  f.incoming(cross+1,'Amber Traders trial starts soon!');eq(a.useCount,nil)
  f.incoming(cross,'Amber Traders trial starts soon!','Alt','@ME');eq(a.useCount,nil)
  f.incoming(CHAT_CHANNEL_ZONE,'Amber Traders trial starts soon!');eq(a.useCount,nil)
  f.incoming(CHAT_CHANNEL_PARTY,'Amber Traders trial starts soon!');eq(a.useCount,nil)
  f.incoming(cross,'Amber Traders trial starts soon!')
  eq(a.useCount,enabled and 1 or nil)
  eq(s:GetGuildLastUsedAt('ad',guild),enabled and now or nil)
  eq(s:GetGuildLastUsedAt('other',guild),nil)
  eq(s:GetSavedChatChannel('ad',guild),output)
  if enabled then eq(s:GetAutoPopulateCooldownEndsAt('ad',guild,41),now+3660) end
  s:SetGuildShareGuildOfficerCooldowns('other',guild,true)
  f.incoming(cross,'Amber Traders trial starts soon!');eq(s:GetGuildLastUsedAt('other',guild),now)
 end
end
for _,output in ipairs({'Zone','Group'}) do
 f.reset();local a=f.entry('a','ad',guild,'Same text',output);s:SetGuildShareGuildOfficerCooldowns('ad',guild,true)
 f.incoming(CHAT_CHANNEL_GUILD_1,'Same text');f.incoming(CHAT_CHANNEL_OFFICER_1,'Same text');eq(a.useCount,nil)
end
f.reset();f.entry('a','ad',guild,'Scheduled text','Guild');s:SetGuildShareGuildOfficerCooldowns('ad',guild,true)
assert(s:SaveGuildSchedule('ad',guild,{mode='EVENT',timelineVersion=1,eventDate='2026-11-02',eventTime='08:00 PM',dailyLimitShared=true,sharedDailyLimit=5,importantTimes={},reminders={{id='p',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=30,messageIds={'a'},availability={enabled=false,maxPerDay=5}}}}))
local c=s:GetGuildSchedule('ad',guild);now=c.eventAtUtc-1800
f.incoming(CHAT_CHANNEL_OFFICER_1,'Scheduled text')
eq(s:GetGuildLastUsedAt('ad',guild),now);eq(s:GetScheduleDailyLimitCount(c,now),1);eq(s:GetReminderAvailabilityCount(c,c.reminders[1],now),1)
eq(s:GetObservedCommandCooldownEndsAt('ad',guild,'Guild'),now+1860)
ZO_SavedVars={NewAccountWide=function()return s.savedVars end}
for _,mode in ipairs({'ON_DEMAND','STARTUP','SCHEDULED'}) do
 s:GetCommandGuildSettings('ad',guild,true).runAt=mode
 local export=f.currentExport();assert(s:ImportSettingsFromString(export));eq(s:GetGuildShareGuildOfficerCooldowns('ad',guild),true)
 local old=export:gsub('(GUILDSETTING[^\n]*)',function(line)return line:gsub('|[^|]*$','')end)
 assert(s:ImportSettingsFromString(old));eq(s:GetGuildShareGuildOfficerCooldowns('ad',guild),false)
 s:SetGuildShareGuildOfficerCooldowns('ad',guild,true)
end
local draft=s:CreatePlannerDraft('ad',guild);eq(draft.behavior.shareGuildOfficerCooldowns,true)
draft.behavior.shareGuildOfficerCooldowns=false;assert(s:IsPlannerDraftDirty(draft));assert(s:SavePlannerDraft(draft));eq(s:GetGuildShareGuildOfficerCooldowns('ad',guild),false)
print('PASS opt-in cross-channel scope, self/guild isolation, templates, actual cooldown, scheduled usage, transfer and drafts')
