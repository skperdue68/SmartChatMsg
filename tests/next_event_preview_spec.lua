local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
local d={mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-06',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=20,intervalMinutes=30,recurrence='WEEKLY'}
now=s:ParseEasternDateTime('2026-10-08','08:00 PM')
eq(s:GetNextScheduleOccurrenceText(d),'Next event: 2026-10-13 08:00 PM EDT')
eq(d.eventDate,'2026-10-06')
now=s:ParseEasternDateTime('2026-10-13','08:05 PM')
eq(s:GetNextScheduleOccurrenceText(d),'Next event: 2026-10-20 08:00 PM EDT')
d.recurrence='NONE';eq(s:GetNextScheduleOccurrenceText(d),'Next event: None scheduled.')
d.recurrence='WEEKLY';d.eventDate='2026-10-27'
now=s:ParseEasternDateTime('2026-11-01','08:00 PM')
eq(s:GetNextScheduleOccurrenceText(d),'Next event: 2026-11-03 08:00 PM EST')
-- The actual settings description reads current drafts instead of stale saved values.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end
local draft=s:GetScheduleEditorDraft();for k,v in pairs(d) do draft[k]=v end
local found
for _,control in ipairs(s:BuildScheduleOptionControls()) do
    if control.reference=='SCM_NextScheduleOccurrence' then found=control end
end
assert(found,'next occurrence must be visible outside collapsed timing sections')
eq(found.text(),'Next event: 2026-11-03 08:00 PM EST')
draft.eventTime='09:00 PM';eq(found.text(),'Next event: 2026-11-03 09:00 PM EST')
-- Zero promotion days starts at the event clock time, not calendar midnight.
d.recurrence='NONE';d.eventDate='2026-10-13';d.promotionDays=0
local zero=assert(s:NormalizeSchedule(d));eq(zero.startsAtUtc,zero.eventAtUtc)
now=s:ParseEasternDateTime('2026-10-13','12:00 AM');assert(now<zero.startsAtUtc)
d.promotionDays=1;local day=assert(s:NormalizeSchedule(d));eq(s:GetSchedulePhase(day,now),'DAY')
print('next event preview checks passed')
