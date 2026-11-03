local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
f.entry('m','ad','Amber Traders','Raffle %eventwhen%','Guild')
local d={mode='EVENT',timelineVersion=1,eventDate='2026-10-10',eventTime='08:00 PM',recurrence='BIWEEKLY',specialPattern='MONTH_FINAL',regularEventLabel='Bi-weekly raffle',monthFinalEventLabel='Bi-weekly + 50/50',reminders={{id='r',label='Promotion',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},messageIds={'m'}}}}
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
local c=s:GetGuildSchedule('ad','Amber Traders');eq(c.regularEventLabel,d.regularEventLabel);eq(c.monthFinalEventLabel,d.monthFinalEventLabel)
eq(s:GetScheduleVariantLabel('REGULAR','MONTH_FINAL',c),'Bi-weekly raffle');eq(s:GetScheduleVariantLabel('FINAL','MONTH_FINAL',c),'Bi-weekly + 50/50')
ZO_SavedVars={NewAccountWide=function()return s.savedVars end}
assert(s:ImportSettingsFromString(f.currentExport()));c=s:GetGuildSchedule('ad','Amber Traders');eq(c.regularEventLabel,d.regularEventLabel);eq(c.monthFinalEventLabel,d.monthFinalEventLabel)
d.regularEventLabel=42;assert(not s:NormalizeSchedule(d));d.regularEventLabel=string.rep('a',81);assert(not s:NormalizeSchedule(d))
print('PASS optional month-final labels and native export/import')
