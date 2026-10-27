local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset();s.savedVars.selectedMessagesCommand="ad"
s.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
s.IsMessagesSelectionComplete=function() return true end
local scheduled=true
s.GetGuildRunAt=function() return scheduled and "SCHEDULED" or "ON_DEMAND" end
local key="ad:Amber Traders"
local draft={mode="EVENT",recurrence="NONE",specialPattern="NONE",startingSoonEnabled=false}
s.GetScheduleEditorDraft=function() s.scheduleEditor={key=key};return draft end
local controls={}
local function widget(name)
 local c={open=false,disabled=false,plays=0}
 c.animation={PlayFromStart=function() c.plays=c.plays+1 end}
 _G[name]=c;controls[name]=c;return c
end
local outer=widget("SCM_SchedulingSubmenu")
local event=widget("SCM_EventTimingSubmenu")
local rotation=widget("SCM_FactionRotationSubmenu")
local repeatOptions=widget("SCM_RepeatOptionsSubmenu")
local weekdays=widget("SCM_RepeatWeekdaysSubmenu")
local soon=widget("SCM_PhaseSOONSubmenu")
s:RefreshEventTimingExpansion()
eq(event.open,true)
rotation.open=false;draft.recurrence="WEEKLY";draft.specialPattern="FACTION_ROTATION"
s:RefreshEventTimingExpansion()
eq(rotation.open,true,"choosing faction rotation must reveal its settings")
eq(repeatOptions.open,true);eq(weekdays.open,true)
rotation.open=false;outer.open=false
s:RefreshEventTimingExpansion()
eq(rotation.open,false,"ordinary refresh preserves manual collapse")
eq(outer.open,false)
draft.specialPattern="NONE";s:RefreshEventTimingExpansion()
draft.specialPattern="FACTION_ROTATION";s:RefreshEventTimingExpansion()
eq(rotation.open,true);eq(outer.open,true,"new child relevance reveals its ancestor")
draft.startingSoonEnabled=true;s:RefreshEventTimingExpansion();eq(soon.open,true)
soon.open=false;s:RefreshEventTimingExpansion();eq(soon.open,false)
-- A disabled native control must be opened after its deferred enable/update.
draft.startingSoonEnabled=false;s:RefreshEventTimingExpansion()
soon.disabled=true;draft.startingSoonEnabled=true;s:RefreshEventTimingExpansion();eq(soon.open,false)
soon.disabled=false;s:RefreshEventTimingExpansion();eq(soon.open,true)
-- Switching to an existing command/guild reveals relevant settings afresh.
rotation.open=false;key="other:Amber Traders";s:RefreshEventTimingExpansion();eq(rotation.open,true)
scheduled=false;s:RefreshEventTimingExpansion()
scheduled=true;outer.open=false;rotation.open=false;s:RefreshEventTimingExpansion()
eq(outer.open,true);eq(rotation.open,true)
print("newly relevant settings open while manual collapse survives ordinary refresh")

local window=widget("SCM_WindowTimingSubmenu")
local reminder=widget("SCM_ReminderTimingSubmenu")
local any=widget("SCM_PhaseANYSubmenu")
draft.mode="WINDOW";s:RefreshEventTimingExpansion();eq(window.open,true);eq(any.open,true)
any.open=false;s:RefreshEventTimingExpansion();eq(any.open,false)
draft.mode="REMINDER";s:RefreshEventTimingExpansion();eq(reminder.open,true)
-- Newly available weekday controls must reopen their manually collapsed parent.
draft.recurrence="MONTHLY_DATE";s:RefreshEventTimingExpansion()
repeatOptions.open=false;weekdays.open=false
draft.recurrence="DAILY";s:RefreshEventTimingExpansion()
eq(repeatOptions.open,true);eq(weekdays.open,true)
-- Group controls added inside existing phase lists must be revealed as well.
local day=widget("SCM_PhaseDAYSubmenu")
draft.mode="EVENT";draft.specialPattern="NONE";s:RefreshEventTimingExpansion()
day.open=false;draft.specialPattern="MONTH_FINAL";s:RefreshEventTimingExpansion();eq(day.open,true)
print("mode timing, weekday ancestors and newly relevant phase group controls expand")

local editable=true
local generic=widget('SCM_TestEditableSection');local readonly=widget('SCM_TestReadonlySection');readonly.open=true
s.settings=s.settings or {};s.settings.optionDefinitions={{type='submenu',reference='SCM_TestEditableSection',disabled=function()return not editable end,controls={{type='editbox'}}},{type='submenu',reference='SCM_TestReadonlySection',controls={{type='description'}}}}
s:RefreshEventTimingExpansion();eq(generic.open,true);eq(readonly.open,false)
generic.open=false;s:RefreshEventTimingExpansion();eq(generic.open,false,'manual collapse stays respected')
editable=false;generic.open=true;s:RefreshEventTimingExpansion();eq(generic.open,false,'unavailable submenu closes')
editable=true;s:RefreshEventTimingExpansion();eq(generic.open,true,'newly relevant submenu opens')
print('PASS generic editable-only submenu expansion and unavailable-section collapse')
