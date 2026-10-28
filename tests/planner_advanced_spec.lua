dofile('tests/planner_window_spec.lua')
dofile('SCM_PlannerAdvanced.lua')
local s=SmartChatMsg
local model={schedule={mode='EVENT',timelineVersion=1,eventDate='2026-10-27',eventTime='08:00 PM',timeZone='ET',recurrence='WEEKLY',specialPattern='EVENT_ROTATION',rotationEvents={},messageVariants={},importantTimes={},reminders={}},dirty=false}
local id=assert(s:AddPlannerActivity(model,'First'));assert(model.schedule.rotationEvents[1].id==id)
assert(s:RenamePlannerActivity(model,id,'Renamed'));assert(model.schedule.rotationEvents[1].id==id)
local other=assert(s:AddPlannerActivity(model,'Second'));assert(s:MovePlannerActivity(model,other,-1));assert(model.schedule.rotationEvents[1].id==other)
model.schedule.messageVariants.message=id;assert(not s:RemovePlannerActivity(model,id));assert(#model.schedule.rotationEvents==2)
model.schedule.messageVariants.message=nil;assert(s:RemovePlannerActivity(model,id));assert(model.schedule.messageVariants.message==nil)
assert(not s:AddPlannerActivity(model,''));assert(not s:RenamePlannerActivity(model,other,string.rep('x',81)))
local key=assert(s:AddPlannerImportantTime(model,'gather_time','Gather'));assert(key=='gather_time')
assert(not s:AddPlannerImportantTime(model,'gather_time','Duplicate'));assert(not s:AddPlannerImportantTime(model,'Invalid','Bad'))
model.schedule.reminders={{start={kind='MARK',name=key},finish={kind='OFFSET',minutes=0}}}
assert(not s:RemovePlannerImportantTime(model,key));model.schedule.reminders={};assert(s:RemovePlannerImportantTime(model,key))
assert(s:SetPlannerCancellation(model,'2026-10-27','POSTPONE'));assert(model.schedule.occurrenceExceptions['2026-10-27'].action=='POSTPONE')
assert(s:SetPlannerCancellation(model,'2026-10-27',nil));assert(not model.schedule.occurrenceExceptions['2026-10-27'])
assert(not s:SetPlannerCancellation(model,'invalid','KEEP'));assert(not s:SetPlannerCancellation(model,'2026-10-27','INVALID'))
-- An empty rotation temporarily fails normalization but must keep the editor usable.
model.schedule.rotationEvents={};model.schedule.reminders={{id='p',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},messageIds={}}}
s.plannerModel=model;assert(s:GetPlannerMarkBase(model));key=assert(s:AddPlannerImportantTime(model,'gather','Gather'))
assert(s:SetPlannerImportantTimeDateTime(model,key,'2026-10-27','07:00 PM'));assert(model.schedule.importantTimes[key].offsetMinutes==-60)
local parent=s.PlannerUI.control(s.plannerWindow,'advancedTest',CT_CONTROL)
assert(s:BuildPlannerAdvancedEditor(parent,650)>400)
assert(parent.plannerControls.activityAdd and parent.plannerControls.markDate and parent.plannerControls.cancellation)
model.schedule.specialPattern='FACTION_ROTATION';s:BuildPlannerAdvancedEditor(parent,650);assert(parent.plannerControls.faction3)
model.schedule.recurrence='MONTHLY_WEEKDAY';model.schedule.specialPattern='NONE';s:BuildPlannerAdvancedEditor(parent,650);assert(parent.plannerControls.monthlyWeek)
print('PASS planner advanced stable activities, reference guards, cancellations, mark tokens and incomplete draft rendering')
