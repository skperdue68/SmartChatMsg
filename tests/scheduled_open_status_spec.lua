local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('notice','ad','Amber Traders','Status test.','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-10-24',eventTime='08:00 PM',promotionDays=1,endDelayMinutes=10,intervalMinutes=30}))
f.currentSchedules();local config=s:GetGuildSchedule('ad','Amber Traders');now=config.eventAtUtc-3600
assert(s:SetGuildRunAt('ad','Amber Traders','SCHEDULED'));assert(s:SetGuildOpenStatusPanelOnRun('ad','Amber Traders',true))
local opens=0;s.SetStatusPanelVisible=function(_,v)if v then opens=opens+1 end end
s.scheduleNoticeStates={};s:NotifyScheduleTransition('ad','Amber Traders','RUNNING');eq(opens,1)
s:NotifyScheduleTransition('ad','Amber Traders','RUNNING');eq(opens,1,'ticks do not force a manually closed panel open')
assert(s:SetGuildOpenStatusPanelOnRun('ad','Amber Traders',false));s.scheduleNoticeStates={};s:NotifyScheduleTransition('ad','Amber Traders','RUNNING');eq(opens,1)
assert(s:SetGuildRunAt('ad','Amber Traders','ON_DEMAND'));assert(s:SetGuildOpenStatusPanelOnRun('ad','Amber Traders',true));eq(s:ShouldOpenStatusPanelOnRun('ad','Amber Traders'),true)
print('PASS scheduled start opens status once when configured, ordinary setting remains available')
