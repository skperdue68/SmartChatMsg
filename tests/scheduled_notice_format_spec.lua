local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset();f.entry("n","ad","Amber Traders","Scheduled message")
eq(s:GetScheduledNoticeLabel("ad","Alphabet Mafia"),"Alphabet Mafia (recruit)")
eq(s:GetSlashCommandDisplayName("ad"),"/recruit")
local notices={};s.ShowStatusMessage=function(_,text) notices[#notices+1]=text end
local function last(prefix)
    local text=notices[#notices]
    assert(text and text:sub(1,#prefix)==prefix,tostring(text).." expected prefix "..prefix)
end
s.scheduleNoticeStates,s.cooldownNoticeDeadlines={},{}
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-08",eventTime="08:00 PM",promotionDays=1,endDelayMinutes=60,delivery="REPEAT",intervalMinutes=5}))
local config=s:GetGuildSchedule("ad","Amber Traders")
now=config.startsAtUtc
s:NotifyScheduleTransition("ad","Amber Traders","RUNNING")
last("Amber Traders (recruit): Schedule started;")
now=config.eventAtUtc
s:NotifyScheduleTransition("ad","Amber Traders","RUNNING")
last("Amber Traders (recruit): Schedule changed to ")
s:NotifyScheduleTransition("ad","Amber Traders","PAUSED")
last("Amber Traders (recruit): Schedule paused.")
s:NotifyScheduleTransition("ad","Amber Traders","RUNNING")
last("Amber Traders (recruit): Schedule resumed;")
assert(s:RequestScheduledDelivery("ad","Amber Traders",true));s:ProcessChatPopulationQueue()
last("Amber Traders (recruit): Scheduled message ready in chat.")
local metadata=s.pendingRestoreState.metadata
s:HandleScheduledPopulateTimeout(metadata)
last("Amber Traders (recruit): Scheduled message was not sent before the chat timeout.")
s:HandleScheduledSendConfirmed(metadata)
eq(notices[#notices],"Amber Traders (recruit): Scheduled message sent. Other schedules pause for 5 minutes, until "..s:FormatScheduleDateTime(now+300,config)..".")
s:NotifyCooldownDelay("ad","Amber Traders",now+60)
last("Amber Traders (recruit): Message delayed by cooldown until ")
now=config.endsAtUtc;s:NotifyScheduleTransition("ad","Amber Traders","FINISHED")
last("Amber Traders (recruit): Schedule ended at ")
s:SetGuildRunAt("ad","Amber Traders","ON_DEMAND")
s:NotifyCooldownDelay("ad","Amber Traders",now+120)
last("/recruit / Amber Traders: message delayed by cooldown until ")
print("PASS scheduled notice labels and lifecycle preserve ordinary notices and slash commands")
