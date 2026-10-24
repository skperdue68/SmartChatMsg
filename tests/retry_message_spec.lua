local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset();s.lastTimedOutMessage=nil
local notices={};s.AddLocalChatMessage=function(_,text) notices[#notices+1]=text end
local a=f.entry("first","ad","Amber Traders","First notice for %guild%.","Officer")
f.entry("second","ad","Amber Traders","Different notice.","Officer")
assert(s:PopulateChatBufferForCommand("ad","Amber Traders","Guild",{}))
eq(s.pendingRestoreState.metadata.selectedEntryId,"first")
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
eq(s.pendingRestoreState,nil)
assert(s:RetryTimedOutMessage())
eq(CHAT_SYSTEM.channel,CHAT_CHANNEL_GUILD_1,"retry must preserve explicit channel override")
eq(CHAT_SYSTEM.textEntry.editControl.text,"First notice for Amber Traders.")
eq(s.pendingRestoreState.metadata.selectedEntryId,"first")
eq(a.lastUsedAt,nil,"repopulating is not a confirmed send")
-- A second timeout is recoverable, but typed text is protected.
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
CHAT_SYSTEM.textEntry.editControl.text="My own draft"
assert(not s:RetryTimedOutMessage());eq(CHAT_SYSTEM.textEntry.editControl.text,"My own draft")
CHAT_SYSTEM.textEntry.editControl.text=""
assert(s:RetryTimedOutMessage())
s:HandleRestoreWatcherChatMessage(EVENT_CHAT_MESSAGE_CHANNEL,CHAT_CHANNEL_GUILD_1,"My Character",CHAT_SYSTEM.textEntry.editControl.text,false,"@Me")
eq(s.lastTimedOutMessage,nil,"a confirmed send consumes recovery")
assert(not s:RetryTimedOutMessage())
-- Edited drafts at timeout must not replace the last untouched expired message.
f.reset();s.lastTimedOutMessage=nil;f.entry("edited","ad","Amber Traders","Original notice.","Guild")
assert(s:PopulateChatBufferForCommand("ad","Amber Traders",nil,{}))
CHAT_SYSTEM.textEntry.editControl.text="I changed it"
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
eq(s.lastTimedOutMessage,nil)
eq(CHAT_SYSTEM.textEntry.editControl.text,"I changed it")
print("timed-out message retry preserves selection, channel, typed text and send accounting")

-- Scheduled retry recalculates clocks, keeps identity, and cannot revive a paused phase.
f.reset();s.lastTimedOutMessage=nil
f.entry("event","ad","Amber Traders","Meet %eventwhen% at %eventtime% (%eventcountdown%).","Guild")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-24",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=180,startingSoonEnabled=true,startingSoonMinutes=60,messagePhases={event={DAY=true}}}))
local cfg=s:GetGuildSchedule("ad","Amber Traders")
now=cfg.eventAtUtc-3*3600
assert(s:PopulateChatBufferForCommand("ad","Amber Traders",nil,{}))
assert(CHAT_SYSTEM.textEntry.editControl.text:find("(3h)",1,true))
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
now=now+3600
assert(s:RetryTimedOutMessage())
assert(CHAT_SYSTEM.textEntry.editControl.text:find("(2h)",1,true))
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
now=cfg.eventAtUtc-1800
assert(not s:RetryTimedOutMessage(),"retry cannot restore a message excluded from Starting soon")
eq(s.pendingRestoreState,nil)
now=cfg.eventAtUtc-7200;cfg.paused=true
assert(not s:RetryTimedOutMessage())
cfg.paused=false
-- Fresh peer announcements and cross-schedule pacing remain respected.
now=now+10
f.incoming(CHAT_CHANNEL_GUILD_1,s:ApplyMessageSubstitutions(s.savedVars.messages[1].text,"ad","Amber Traders"))
assert(not s:RetryTimedOutMessage())
-- Deleted original entries never fall back to another random message.
f.reset();s.lastTimedOutMessage=nil
f.entry("deleted","ad","Amber Traders","Delete me.","Guild")
assert(s:PopulateChatBufferForCommand("ad","Amber Traders",nil,{}))
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
s.savedVars.messages={};f.entry("otherentry","ad","Amber Traders","Not the same message.","Guild")
assert(not s:RetryTimedOutMessage());eq(s.pendingRestoreState,nil)
print("retry recalculates countdowns and respects phases, pause, peers and deleted entries")

-- Ordinary automatic Zone sends keep zone usage accounting when recovered.
f.reset();s.lastTimedOutMessage=nil
f.entry("zone","ad","Amber Traders","Zone notice.","Zone")
assert(s:PopulateChatBufferForCommand("ad","Amber Traders",nil,{autoPopulate=true,zoneId=s:GetPlayerZoneId()}))
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
assert(s:RetryTimedOutMessage())
eq(s.pendingRestoreState.metadata.autoPopulate,true)
s:HandleRestoreWatcherChatMessage(EVENT_CHAT_MESSAGE_CHANNEL,CHAT_CHANNEL_ZONE,"My Character",CHAT_SYSTEM.textEntry.editControl.text,false,"@Me")
eq(s:GetGuildAutoPopulateLastSentAt("ad","Amber Traders",s:GetPlayerZoneId()),now)
-- Recovery never reinstates an expired startup queue callback.
f.reset();s.lastTimedOutMessage=nil
f.entry("startup","ad","Amber Traders","Startup notice.","Guild")
assert(s:PopulateChatBufferForCommand("ad","Amber Traders",nil,{startupQueue=true,queueItemId="expired-queue-item"}))
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
assert(s:RetryTimedOutMessage())
eq(s.pendingRestoreState.metadata.startupQueue,nil);eq(s.pendingRestoreState.metadata.queueItemId,nil)
print("retry retains Zone accounting without replaying completed startup actions")

-- ESO can have already cleared the input before our timeout callback runs.
f.reset();s.lastTimedOutMessage=nil
f.entry("emptied","ad","Amber Traders","Remember %guild%.","Guild")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-24",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=180}))
now=s:GetGuildSchedule("ad","Amber Traders").eventAtUtc-3600
s:TickSchedules()
assert(s.pendingRestoreState)
CHAT_SYSTEM.textEntry.editControl.text=""
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
assert(s:RetryTimedOutMessage(),"empty input at scheduled timeout must retain retry recovery")
eq(CHAT_SYSTEM.textEntry.editControl.text,"Remember Amber Traders.")
eq(s:GetGuildLastUsedAt("ad","Amber Traders"),nil)
print("scheduled timeout retains recovery when ESO already emptied chat")

-- A once-only phase is complete after sending, never merely preparing text.
f.reset();s.lastTimedOutMessage=nil
f.entry("once","ad","Amber Traders","One reminder.","Guild")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-24",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=5,phaseOnce={DAY=true}}))
cfg=s:GetGuildSchedule("ad","Amber Traders");now=cfg.eventAtUtc-3600
s:TickSchedules()
EVENT_MANAGER.updates[s.restoreWatcherTimeoutName].callback()
now=now+300;s:TickSchedules()
assert(s.pendingRestoreState,"unsent once-only reminder must retry after its timeout delay")
s:HandleRestoreWatcherChatMessage(EVENT_CHAT_MESSAGE_CHANNEL,CHAT_CHANNEL_GUILD_1,"My Character",CHAT_SYSTEM.textEntry.editControl.text,false,"@Me")
CHAT_SYSTEM.textEntry.editControl.text="";now=now+300;s:TickSchedules()
eq(s.pendingRestoreState,nil,"confirmed once-only reminder must not automatically repeat")
eq(s:GetScheduledDueAt("ad","Amber Traders","DAY"),math.huge)
print("once-only phases retry unsent text and complete only after confirmed send")

f.reset();s.lastTimedOutMessage=nil
f.entry("peeronce","ad","Amber Traders","Only one notice.","Guild")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-24",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=5,phaseOnce={DAY=true}}))
cfg=s:GetGuildSchedule("ad","Amber Traders");now=cfg.eventAtUtc-3600
f.incoming(CHAT_CHANNEL_GUILD_1,"Only one notice.")
now=now+600;s:TickSchedules()
eq(s.pendingRestoreState,nil,"a matching peer send completes a once-only phase too")
print("peer announcements complete once-only phases without preparing local text")
