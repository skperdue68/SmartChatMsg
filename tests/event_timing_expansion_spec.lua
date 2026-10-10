local f=dofile("tests/eso_fixture.lua")
local scm,eq=f.scm,f.eq
f.reset()
local key="ad:Amber Traders"
local mode="EVENT"
scm.GetScheduleEditorDraft=function() scm.scheduleEditor={key=key}; return {mode=mode} end
scm.IsMessagesSelectionComplete=function() return true end
scm.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
scm.GetGuildRunAt=function() return "SCHEDULED" end
local plays=0
SCM_EventTimingSubmenu={open=false,disabled=false,animation={PlayFromStart=function() plays=plays+1 end}}
scm:RefreshEventTimingExpansion()
eq(SCM_EventTimingSubmenu.open,true)
eq(plays,1)
SCM_EventTimingSubmenu.open=false
scm:RefreshEventTimingExpansion()
eq(SCM_EventTimingSubmenu.open,false,"manual collapse survives refresh")
mode="WINDOW"; scm:RefreshEventTimingExpansion()
mode="EVENT"; scm:RefreshEventTimingExpansion()
eq(plays,2,"returning to event opens timing")
key="other:Amber Traders"; SCM_EventTimingSubmenu.open=false
scm:RefreshEventTimingExpansion(); eq(plays,3)
SCM_EventTimingSubmenu=nil; key="new:Amber Traders"
scm:RefreshEventTimingExpansion()
SCM_EventTimingSubmenu={open=false,disabled=false,animation={PlayFromStart=function() plays=plays+1 end}}
scm:RefreshEventTimingExpansion(); eq(plays,4,"deferred widgets open when created")
print("Event timing expansion tests passed")
