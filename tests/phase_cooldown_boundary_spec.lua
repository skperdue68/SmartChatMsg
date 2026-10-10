local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset();f.entry("a","ad","Amber Traders","Meet %eventwhen% at %eventtime%.","Guild")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-10",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=180,startingSoonEnabled=true,startingSoonMinutes=60}))
local config=s:GetGuildSchedule("ad","Amber Traders")
local settings=s:GetCommandGuildSettings("ad","Amber Traders",true)
now=s:ParseEasternDateTime("2026-10-09","11:50 PM")
f.incoming(CHAT_CHANNEL_GUILD_1,s:ApplyMessageSubstitutions(s.savedVars.messages[1].text,"ad","Amber Traders"))
local last=settings.lastUsedAt
now=s:ParseEasternDateTime("2026-10-10","12:00 AM")
assert(s:GetScheduledDueAt("ad","Amber Traders","DAY")<=now,"old BEFORE repeat/peer cooldown must not delay DAY")
eq(settings.lastUsedAt,last,"last-send history remains accurate")
-- Fresh peer activity in the new phase still starts its cooldown.
f.incoming(CHAT_CHANNEL_GUILD_1,s:ApplyMessageSubstitutions(s.savedVars.messages[1].text,"ad","Amber Traders"))
assert(s:GetScheduledDueAt("ad","Amber Traders","DAY")>now)
now=config.eventAtUtc-3600
assert(s:GetScheduledDueAt("ad","Amber Traders","SOON")<=now)
settings.lastUsedAt=now-60;settings.observedChatCooldowns={['*']={at=now-60,delaySeconds=60}}
now=config.eventAtUtc
assert(s:GetScheduledDueAt("ad","Amber Traders","LIVE")<=now)
-- Scheduled zone cooldowns also belong to the phase; ordinary zone cooldowns do not.
config.delivery="ZONE"
settings.lastAutoPopulateSentAtByZone={[tostring(s:GetPlayerZoneId())]=now-60}
assert(not s:GetAutoPopulateCooldownEndsAt("ad","Amber Traders",s:GetPlayerZoneId()) or s:GetAutoPopulateCooldownEndsAt("ad","Amber Traders",s:GetPlayerZoneId())<=now)
s:SetGuildRunAt("ad","Amber Traders","ON_DEMAND")
assert(s:GetAutoPopulateCooldownEndsAt("ad","Amber Traders",s:GetPlayerZoneId())>now)
print("new phases reset delays while preserving history and new-phase observations")

s:SetGuildRunAt("ad","Amber Traders","SCHEDULED")
config.nextDueAt=now+7200;config.nextDuePhase="DAY";config.nextDueOccurrence=tostring(config.eventAtUtc)
s.scheduleStartupEndsAt=now+180
s:TickSchedules()
eq(config.nextDueAt,nil,"a previous-phase zone deadline cannot hold the new phase")
assert(s:GetSchedulePacingDelay("ad","Amber Traders"),"phase reset must retain startup pacing")
print("phase transitions discard stale zone deadlines while retaining startup pacing")
