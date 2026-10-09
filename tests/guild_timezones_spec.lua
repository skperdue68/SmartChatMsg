local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
f.entry('a','ad','Amber Traders','At %eventtime%','Guild')
f.entry('b','ad','Blue Traders','At %eventtime%','Guild')
local function draft() return {mode='EVENT',enabled=true,eventDate='2026-10-13',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=20,intervalMinutes=30,recurrence='WEEKLY'} end
assert(s:SetGuildSchedulingTimeZone('Blue Traders','PT'))
assert(s:SaveGuildSchedule('ad','Amber Traders',draft()))
assert(s:SaveGuildSchedule('ad','Blue Traders',draft()))
local amber=s:GetGuildSchedule('ad','Amber Traders');local blue=s:GetGuildSchedule('ad','Blue Traders')
eq(blue.eventAtUtc-amber.eventAtUtc,10800);eq(blue.timeZone,'PT')
now=amber.eventAtUtc-3600
eq(s:GetScheduledEventTokenValue('eventtime','ad','Amber Traders'),'08:00 PM EDT')
eq(s:GetScheduledEventTokenValue('eventtime','ad','Blue Traders'),'08:00 PM PDT')
eq(s:GetSchedulePhase(blue,blue.startsAtUtc),'DAY')
assert(s:SetSchedulingTimeZone('CT'))
eq(s:GetGuildSchedule('ad','Blue Traders').eventAtUtc,blue.eventAtUtc)
eq(s:GetGuildSchedule('ad','Amber Traders').eventAtUtc,amber.eventAtUtc+3600)
assert(s:SetGuildSchedulingTimeZone('Amber Traders','MT'))
eq(s:GetGuildSchedule('ad','Amber Traders').eventAtUtc,amber.eventAtUtc+7200)
eq(s:GetGuildSchedule('ad','Blue Traders').eventAtUtc,blue.eventAtUtc)
assert(s:SetGuildSchedulingTimeZone('Blue Traders','GLOBAL'))
eq(s:GetGuildSchedulingTimeZone('Blue Traders'),'CT')
eq(s:GetGuildSchedule('ad','Blue Traders').eventAtUtc,amber.eventAtUtc+3600)
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
local export=s:BuildExportString()
assert(s:SetSchedulingTimeZone('PT'));assert(s:ImportSettingsFromString(export))
eq(s:GetSchedulingTimeZone(),'CT');eq(s:GetGuildSchedulingTimeZone('Amber Traders'),'MT')
eq(s:GetGuildSchedulingTimeZone('Blue Traders'),'CT')
eq(s:GetGuildSchedule('ad','Amber Traders').timeZone,'MT')
eq(s:GetGuildSchedule('ad','Blue Traders').timeZone,'CT')
assert(not s:SetGuildSchedulingTimeZone('Blue Traders','BAD'))
-- Settings use the selected guild and retain draft changes across preference edits.
s.savedVars.selectedMessagesCommand='ad';s.savedVars.selectedMessagesGuildIndex=2
local controls=s:BuildScheduleOptionControls()
local picker
for _,control in ipairs(controls) do if control.name=='Guild timezone' then picker=control end end
assert(picker);eq(picker.getFunc(),'Use global default')
local editor=s:GetScheduleEditorDraft();editor.eventTime='09:30 PM';s.scheduleEditor.dirty=true
picker.setFunc('Pacific (PT)')
eq(s:GetScheduleEditorDraft().eventTime,'09:30 PM');eq(s:GetScheduleEditorDraft().timeZone,'PT')
eq(s.scheduleEditor.dirty,true);eq(picker.getFunc(),'Pacific (PT)')
assert(s:GetNextScheduleOccurrenceText(s:GetScheduleEditorDraft()):find('09:30 PM PDT',1,true))
local blue=s:GetGuildSchedule('ad','Blue Traders')
now=blue.eventAtUtc-3600
local message=s:ApplyMessageSubstitutions('At %eventtime%','ad','Blue Traders')
assert(message:find('(1h)',1,true));f.incoming(CHAT_CHANNEL_GUILD_1+1,message)
eq(s:GetGuildLastUsedAt('ad','Blue Traders'),now)
local rows=s:GetRepeatStatusPanelRows();local card
for _,row in ipairs(rows) do if row.guildName=='Blue Traders' then card=row end end
assert(card);assert(card.promotionText:find('PDT',1,true))
print('guild timezone defaults and isolation checks passed')
