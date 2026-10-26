local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq;f.reset()
f.entry('a','ad','Amber Traders','Already announced','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=10,phaseOnce={LIVE=true},messagePhases={a={LIVE=true}}}))
local old=s:GetGuildSchedule('ad','Amber Traders');now=old.eventAtUtc+60
old.completedOccurrences[tostring(old.eventAtUtc)..':LIVE']=true
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function()return 'Amber Traders' end
assert(s:ConvertScheduleDraftToTimeline());assert(s:SaveGuildSchedule('ad','Amber Traders',s:GetScheduleEditorDraft()))
local config=s:GetGuildSchedule('ad','Amber Traders');local live
for _,row in ipairs(config.reminders) do if row.once then live=row end end
assert(config.timelineUsage[tostring(config.eventAtUtc)..':'..live.id].completed,'phase completion must survive conversion even without last-used guild history')
print('legacy completion identity survives conversion independently of usage timestamps')
