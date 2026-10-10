local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset()
f.entry("a","ad","Amber Traders","%guild%: %eventwhen% at %eventtime%", "Guild")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=true,eventDate="2026-10-16",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=15,startingSoonEnabled=true,startingSoonMinutes=120}))
s.savedVars.selectedMessagesCommand="ad"
s.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
local schedule=s:GetGuildSchedule("ad","Amber Traders")
now=schedule.eventAtUtc-3600
local clock=now
local localMessages={}
s.AddLocalChatMessage=function(_,text) localMessages[#localMessages+1]=text end
local due=schedule.nextDueAt
local output,context=s:TestMessagePreview("a","BEFORE")
assert(output:find("tomorrow",1,true),output)
assert(output:find("(1d)",1,true),output)
eq(context.phase,"BEFORE")
eq(now,clock,"preview cannot change real clock")
eq(schedule.nextDueAt,due,"preview cannot change cooldown")
output,context=s:TestMessagePreview("a","DAY")
assert(output:find("today",1,true),output)
assert(s:GetSchedulePhase(context.schedule,context.now)=="DAY")
output,context=s:TestMessagePreview("a","SOON")
assert(output:find("(1h)",1,true),output)
eq(context.now,context.occurrence.eventAtUtc-3600)
output,context=s:TestMessagePreview("a","LIVE")
assert(context.now>context.occurrence.eventAtUtc)
eq(output,s:ApplyMessageSubstitutions(s.savedVars.messages[1].text,"ad","Amber Traders",context),"live preview uses real parser")
-- An unsaved event edit is the source for all phase previews.
local draft=s:GetScheduleEditorDraft();draft.eventTime="09:00 PM"
output=s:TestMessagePreview("a","SOON")
assert(output:find("09:00 PM",1,true),output)
local effective=s.settings.GetEffectiveMessageText
s.settings.GetEffectiveMessageText=function() return "Edited %guild% at %eventtime%" end
output=s:TestMessagePreview("a")
assert(output:find("Edited Amber Traders",1,true),output)
assert(localMessages[#localMessages]==output,"output must go to local chat")
assert(s.pendingRestoreState==nil,"preview must not populate chat")
s.settings.GetEffectiveMessageText=effective
f.reset();f.entry("plain","ad","Amber Traders","Hello %guild%, %zone%!")
output=s:TestMessagePreview("plain")
assert(output:find("Amber Traders",1,true) and output:find("Stonefalls",1,true),output)
print("message previews passed")

-- Explicit now reaches the literal time parser as well as event tokens.
local real=now
local at=s:ParseEasternDateTime("2026-10-15","12:00 PM")
local literal=s:ApplyMessageSubstitutions("Tomorrow at 12PM ET","ad","Amber Traders",{now=at})
assert(literal:find("(1d)",1,true),literal)
eq(now,real)
-- Recurrences use the next occurrence, not an obsolete anchor.
f.reset();f.entry("r","ad","Amber Traders","%eventdate% at %eventtime% %eventwhen%")
assert(s:SaveGuildSchedule("ad","Amber Traders",{mode="EVENT",enabled=false,paused=true,eventDate="2026-10-06",eventTime="08:00 PM",promotionDays=2,endDelayMinutes=60,intervalMinutes=15,recurrence="WEEKLY",startingSoonEnabled=true,startingSoonMinutes=120}))
s.savedVars.selectedMessagesCommand="ad"
now=s:ParseEasternDateTime("2026-10-12","10:00 AM")
output,context=s:TestMessagePreview("r","BEFORE")
assert(output:find("10/13/2026",1,true),output)
assert(output:find("tomorrow",1,true),output)
eq(s:GetGuildSchedule("ad","Amber Traders").enabled,false,"testing disabled schedule must not enable it")
-- Phases that have no time in the configured window give a clear local notice.
s:GetScheduleEditorDraft().promotionDays=0
output=s:TestMessagePreview("r","BEFORE")
eq(output,nil)
assert(localMessages[#localMessages]:find("no time",1,true))
-- Before-event preview uses a civil day, not a fixed 24-hour DST assumption.
local d=s:GetScheduleEditorDraft();d.eventDate="2026-03-08";d.eventTime="08:00 PM";d.promotionDays=2;d.recurrence="NONE"
now=s:ParseEasternDateTime("2026-03-06","08:00 PM")
output,context=s:TestMessagePreview("r","BEFORE")
eq(s:GetScheduleParts(context.now,context.schedule).day,7)
eq(s:GetScheduleParts(context.now,context.schedule).hour,20)
assert(output:find("tomorrow",1,true),output)
eq(context.occurrence.eventAtUtc-context.now,23*3600)
print("literal clocks, recurring events, empty phases and DST previews passed")
