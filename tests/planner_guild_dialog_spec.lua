dofile('tests/planner_window_spec.lua')
local s=SmartChatMsg
s.plannerModel=s:CreatePlannerDraft(s.plannerModel.commandId,s.plannerModel.guild)
assert(s:OpenEventPlanner())
local button=s.plannerWindow.plannerControls.guildSettings
local width,height=button:GetWidth(),button:GetHeight()
button.handlers.OnClicked()
local dialog=s.plannerWindow.plannerControls.guildSettingsDialog
assert(dialog and dialog~=button,'Guild dialog must have its own container')
assert(button:GetWidth()==width and button:GetHeight()==height,'Opening the dialog must not resize the launcher')
assert(dialog.anchor.point==CENTER and dialog.anchor.relative==s.plannerWindow)
assert(not button.plannerControls.title,'Dialog content must never become children of the launcher')
dialog.plannerControls.zone.combo.entries[3].callback();dialog.plannerControls.save.handlers.OnClicked()
assert(dialog.hidden and not button.hidden);assert(button:GetWidth()==width and button:GetHeight()==height)
button.handlers.OnClicked();assert(not dialog.hidden);assert(dialog.anchor.point==CENTER)
dialog.plannerControls.cancel.handlers.OnClicked();assert(dialog.hidden)
local active,live=s:GetPlannerLivePeriod();assert(active)
local child=s.plannerPeriods.plannerControls.periods:GetNamedChild('Scroll'):GetNamedChild('Child')
local card=child.plannerControls['period'..active.id]
local countdown=card.plannerControls.eligibility
assert(countdown and not countdown.hidden)
assert(countdown.anchor.y>=card.plannerControls.stops.anchor.y+card.plannerControls.stops.height)
assert(card.plannerControls.frequency.anchor.y>=countdown.anchor.y+countdown.height)
local occurrence=s:GetScheduleOccurrence(live,now)
live.timelineUsage[occurrence.occurrenceKey..':'..active.id]={nextDueAt=now+100}
EVENT_MANAGER.updates.SCM_PlannerActivity.callback()
assert(countdown.text=='Next eligible: '..s:FormatStatusDuration(100))
now=now+1;EVENT_MANAGER.updates.SCM_PlannerActivity.callback()
assert(countdown.text=='Next eligible: '..s:FormatStatusDuration(99))
-- Pooled keys cannot silently turn a button into a dialog container again.
local ok=pcall(function()s.PlannerUI.box(s.plannerWindow,'guildSettings',0,0,680,330,true)end)
assert(not ok,'Pooled controls must reject incompatible control types')
print('PASS separate centered guild dialog, Save/reopen/Cancel and pooled control type safety')
