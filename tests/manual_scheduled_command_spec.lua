local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
local function setup(guild,channel)
    f.reset();s.lastTimedOutMessage=nil
    guild=guild or 'Amber Traders'
    f.entry('day','ad',guild,'Meet %eventwhen% at %eventtime% (%eventcountdown%).',channel or 'Guild')
    f.entry('before','ad',guild,'Tomorrow notice.',channel or 'Guild')
    assert(s:SaveGuildSchedule('ad',guild,{mode='EVENT',enabled=true,eventDate='2026-10-24',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=60,intervalMinutes=180,messagePhases={day={DAY=true},before={BEFORE=true}}}))
    local cfg=s:GetGuildSchedule('ad',guild)
    now=cfg.eventAtUtc-3600
    s:MarkCommandUsed('ad',guild,'1',1)
    return cfg
end
local function sent(channel)
    local pending=assert(s.pendingRestoreState)
    CHAT_SYSTEM:GetEditControl():SetText('')
    s:HandleRestoreWatcherChatMessage(2,channel or CHAT_CHANNEL_GUILD_1,'My Character',pending.rawExpectedText,false,'@Me')
end

local cfg=setup()
now=now+60
assert(s:HandleScmCommand('send recruit'))
eq(s.pendingRestoreState.metadata.selectedEntryId,'day')
assert(CHAT_SYSTEM:GetEditControl():GetText():find('today',1,true))
assert(CHAT_SYSTEM:GetEditControl():GetText():find('(~1h)',1,true))
eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now-60,'preparing is not sending')
sent()
eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now)
eq(cfg.nextDueAt,now+10800,'manual send resets its ordinary repeat interval')
eq(s:GetGuildScheduleState('ad','Amber Traders'),'RUNNING')
eq(SLASH_COMMANDS['/recruit'],nil,'scheduled-only command needs no standalone handler')

-- Manual requests override once-only completion too, without enabling repeats.
cfg=setup();cfg.phaseOnce.DAY=true
cfg.completedOccurrences={[tostring(cfg.eventAtUtc)..':DAY']=true}
assert(s:HandleScmCommand('/RECRUIT 1'));sent()
eq(s:GetScheduledDueAt('ad','Amber Traders','DAY'),math.huge)

-- Protect chat drafts, then revalidate the phase and eligibility at execution.
cfg=setup();CHAT_SYSTEM:GetEditControl():SetText('Keep my draft')
assert(s:HandleScmCommand('send recruit 1'))
eq(CHAT_SYSTEM:GetEditControl():GetText(),'Keep my draft')
CHAT_SYSTEM:GetEditControl():SetText('');s:ProcessChatPopulationQueue()
assert(s.pendingRestoreState,'manual request survives own repeat cooldown while queued')

cfg=setup();CHAT_SYSTEM:GetEditControl():SetText('Keep my draft')
assert(s:HandleScmCommand('recruit'))
now=cfg.eventAtUtc+60;CHAT_SYSTEM:GetEditControl():SetText('');s:ProcessChatPopulationQueue()
eq(s.pendingRestoreState,nil,'queued manual message must not cross event phases')

cfg=setup();f.incoming(CHAT_CHANNEL_GUILD_1,'Meet today at 08:00 PM EDT (1h).')
assert(not s:HandleScmCommand('recruit'),'manual request respects a matching peer cooldown')
eq(s.pendingRestoreState,nil)

for _,state in ipairs({'paused','disabled','outside'}) do
    cfg=setup()
    if state=='paused' then cfg.paused=true elseif state=='disabled' then cfg.enabled=false else now=cfg.endsAtUtc+1 end
    assert(not s:HandleScmCommand('send recruit 1'),state)
    eq(s.pendingRestoreState,nil)
end
cfg=setup();s.scheduleStartupEndsAt=now+180
assert(not s:HandleScmCommand('recruit'))
s.scheduleStartupEndsAt=nil;s.scheduledSendPause={senderKey=s:GetReminderStateKey('other','Amber Traders'),endsAt=now+300}
assert(not s:HandleScmCommand('recruit'))

-- Guild selection must be unambiguous and output must remain the saved channel.
cfg=setup('Blue Traders','Officer')
assert(s:HandleScmCommand('recruit'));eq(CHAT_SYSTEM.channel,CHAT_CHANNEL_OFFICER_1+1)
cfg=setup()
f.entry('blue','ad','Blue Traders','Blue reminder.','Officer')
local draft={};for k,v in pairs(cfg) do draft[k]=v end
now=1000000;assert(s:SaveGuildSchedule('ad','Blue Traders',draft));now=cfg.eventAtUtc-3600
assert(not s:HandleScmCommand('send recruit'),'multiple guilds need an explicit slot without a matching default')
assert(s:HandleScmCommand('send recruit 2'));eq(CHAT_SYSTEM.channel,CHAT_CHANNEL_OFFICER_1+1)

for _,input in ipairs({'send unknown','send recruit 6','send recruit 1 extra','send','recruit nope'}) do
    setup();assert(not s:HandleScmCommand(input),'invalid request '..input);eq(s.pendingRestoreState,nil)
end
cfg=setup();s.savedVars.commands[1].name='retry'
assert(s:HandleScmCommand('send retry 1'),'explicit send handles names reserved for built-in actions')

-- The selected default disambiguates matching schedules across multiple guilds.
cfg=setup()
f.entry('blue','ad','Blue Traders','Blue reminder.','Officer')
local blue={};for k,v in pairs(cfg) do blue[k]=v end
now=1000000;assert(s:SaveGuildSchedule('ad','Blue Traders',blue));now=cfg.eventAtUtc-3600
s.savedVars.defaultGuildIndex=2
assert(s:HandleScmCommand('send recruit'));eq(CHAT_SYSTEM.channel,CHAT_CHANNEL_OFFICER_1+1)

-- Zone-arrival schedules retain zone tracking and reset a stale timeout deadline.
cfg=setup(nil,'Zone');cfg.delivery='ZONE'
local zone=s:GetEffectiveAutoPopulateZoneId(s:GetPlayerZoneId())
s:SetGuildAutoPopulateLastSentAt('ad','Amber Traders',zone,now)
cfg.nextDueAt=now+3600;cfg.nextDuePhase='DAY'
cfg.nextDueOccurrence=s:GetScheduleOccurrence(cfg,now).occurrenceKey
assert(s:HandleScmCommand('recruit 1'))
sent(CHAT_CHANNEL_ZONE)
eq(s:GetGuildAutoPopulateLastSentAt('ad','Amber Traders',zone),now)
eq(cfg.nextDueAt,now+10800,'manual Zone send replaces the previous timeout deadline')
print('manual scheduled reminders resolve guilds, respect phases and peers, and update usage only after sending')
