local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset();f.entry("n","ad","Amber Traders","Amber Traders notice")
local notices={};s.ShowStatusMessage=function(_,text) notices[#notices+1]=text end
s.scheduleNoticeStates,s.cooldownNoticeDeadlines={},{}
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="WINDOW",enabled=true,startDate="2026-10-08",startTime="08:00 PM",endDate="2026-10-08",endTime="09:00 PM",delivery="REPEAT",intervalMinutes=5}))
local config=s:GetGuildSchedule("ad","Amber Traders")
now=config.startsAtUtc;s:TickSchedules();s:TickSchedules()
eq(#notices,1);assert(notices[1]:find("schedule started",1,true));assert(notices[1]:find("EDT",1,true))
now=config.endsAtUtc;s:TickSchedules();s:TickSchedules()
eq(#notices,2);assert(notices[2]:find("schedule ended",1,true))
s:NotifyCooldownDelay("ad","Amber Traders",now+60);s:NotifyCooldownDelay("ad","Amber Traders",now+60)
eq(#notices,3);assert(notices[3]:find("delayed by cooldown",1,true))
-- Passive matching before activation, including reload and a further observation.
f.reset();s.ShowStatusMessage=function() end
f.entry("p","ad","Amber Traders","Amber Traders is recruiting!")
s:SetGuildReminderMinutes("ad","Amber Traders",5)
f.incoming(CHAT_CHANNEL_ZONE,"Amber Traders is recruiting!")
assert(not s:IsReminderAutomationActive("ad","Amber Traders"))
ZO_SavedVars={NewAccountWide=function() return s.savedVars end};s:InitializeSavedVars()
s:HandleDynamicSlashCommand("ad","/ad","1")
eq(s.pendingRestoreState,nil)
local key=s:GetReminderStateKey("ad","Amber Traders")
local request=assert(s.chatPopulationQueue[key]);local first=request.metadata.observedDueAt
now=now+10;f.incoming(CHAT_CHANNEL_ZONE,"Amber Traders is recruiting!")
assert(s.chatPopulationQueue[key].metadata.observedDueAt>first)
local deadline=s.chatPopulationQueue[key].metadata.observedDueAt
now=deadline-1;s:ProcessChatPopulationQueue();eq(s.pendingRestoreState,nil)
now=deadline;s:ProcessChatPopulationQueue();assert(s.pendingRestoreState)
print("PASS local transition notices, cooldown deduplication and passive cooldown on later activation")

-- Starting a startup command also waits for a previously observed message.
s:ClearPendingRestoreState("test");CHAT_SYSTEM.textEntry.editControl.text=""
f.reset();f.entry("p","ad","Amber Traders","Amber Traders is recruiting!")
s:SetGuildReminderMinutes("ad","Amber Traders",5)
f.incoming(CHAT_CHANNEL_ZONE,"Amber Traders is recruiting!")
s:SetGuildRunAt("ad","Amber Traders","STARTUP");s.startupQueue={}
assert(s:QueueCommandExecution("ad","/ad","1","startup",{guildName="Amber Traders",guildIndex=1,paramText="1"}))
s:ProcessStartupQueue();eq(s.pendingRestoreState,nil)
local current=s.startupQueueCurrent;assert(current)
s:ProcessChatPopulationQueue();eq(s.startupQueueCurrent,current)
local queued=assert(s.chatPopulationQueue[s:GetReminderStateKey("ad","Amber Traders")])
now=queued.metadata.observedDueAt;s:ProcessChatPopulationQueue()
assert(s.pendingRestoreState);eq(s.pendingRestoreState.metadata.queueItemId,current.id)
print("PASS startup respects previously observed cooldown and preserves ownership")

f.reset()
assert(s:GetChatEditControl()==CHAT_SYSTEM.textEntry.editControl)
assert(not s:IsChatPopulationBusy(),"ESO native empty input is available")
CHAT_SYSTEM.textEntry.editControl:SetText("typed text")
assert(s:IsChatPopulationBusy(),"ESO native typed input stays protected")
CHAT_SYSTEM.textEntry.editControl:SetText(" ")
assert(s:IsChatPopulationBusy(),"whitespace is still a user edit")
CHAT_SYSTEM.textEntry.editControl:SetText("")
assert(not s:IsChatPopulationBusy())
print("PASS native ESO GetEditControl and lowercase editControl preserve input safety")

local scm=SmartChatMsg
local edit=scm:GetChatEditControl()
edit.text="Prepared test"
scm.pendingRestoreState={rawExpectedText="Prepared test",metadata={commandId="ad",guildName="Amber Traders"}}
assert(scm:GetScheduleChatWaitText("ad","Amber Traders")=="Message ready — press Enter")
edit.text="Edited by me"
assert(scm:GetScheduleChatWaitText("ad","Amber Traders"):find("your edits are protected",1,true))
scm.pendingRestoreState=nil
assert(scm:GetScheduleChatWaitText("ad","Amber Traders"):find("your text is protected",1,true))
print("PASS status distinguishes prepared messages from protected user input")
