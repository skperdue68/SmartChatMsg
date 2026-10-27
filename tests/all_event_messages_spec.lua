local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset()
f.entry('regular','ad','Amber Traders','Regular tickets.','Guild')
f.entry('final','ad','Amber Traders','Monthly tickets.','Guild')
f.entry('shared','ad','Amber Traders','Sales are closed.','Guild')
local d={mode='EVENT',enabled=true,eventDate='2026-10-10',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=20,
    recurrence='BIWEEKLY',intervalMinutes=30,specialPattern='MONTH_FINAL',startingSoonEnabled=true,startingSoonMinutes=60,
    messageVariants={final='FINAL',shared='ALL'},messagePhases={regular={DAY=true},final={DAY=true},shared={DAY=true,SOON=true}}}
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
local cfg=s:GetGuildSchedule('ad','Amber Traders')
eq(cfg.messageVariants.shared,'ALL','normalization preserves explicit All events')
eq(s:GetScheduleMessageVariant(cfg,'regular'),'REGULAR','unmarked messages keep the regular default')
local function ids()
    local result={}
    for _,entry in ipairs(s:GetScheduledMessageEntries('ad','Amber Traders')) do result[entry.id]=true end
    return result
end
now=s:ParseEasternDateTime('2026-10-10','12:00 PM')
local selected=ids();assert(selected.regular and selected.shared and not selected.final)
now=s:ParseEasternDateTime('2026-10-24','12:00 PM')
selected=ids();assert(selected.final and selected.shared and not selected.regular)
for _,date in ipairs({'2026-10-10','2026-10-24'}) do
    now=s:ParseEasternDateTime(date,'07:30 PM')
    local entries=s:GetScheduledMessageEntries('ad','Amber Traders')
    eq(#entries,1);eq(entries[1].id,'shared','one shared Starting soon message works for either drawing')
end
now=s:ParseEasternDateTime('2026-10-23','12:00 PM')
eq(#s:GetScheduledMessageEntries('ad','Amber Traders'),0,'All events still respects phase exclusions')
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
assert(s:ImportSettingsFromString(f.currentExport()))
cfg=s:GetGuildSchedule('ad','Amber Traders')
eq(cfg.messageVariants.shared,'ALL','full settings transfer preserves All events')
eq(cfg.messagePhases.shared.SOON,true)
assert(s:SetMessageLocked('shared',true))
assert(s:ImportSettingsFromString(f.currentExport()))
eq(s:GetGuildSchedule('ad','Amber Traders').messageVariants.shared,'ALL','personal locked groups survive import')
assert(s:DeleteMessageEntry('final'))
now=s:ParseEasternDateTime('2026-10-24','12:00 PM')
selected=ids();assert(selected.regular and selected.shared,'no month-final pool retains regular fallback plus shared messages')
eq(s:GetScheduleVariantLabel('ALL','MONTH_FINAL'),'All events')
eq(s:GetScheduleVariantLabel('ALL','FACTION_ROTATION'),'All selected factions')
print('All events shares one message across regular and final occurrences, respects phases and survives transfer')
