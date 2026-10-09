local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
local d={mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-01',eventTime='09:00 PM',promotionDays=2,endDelayMinutes=20,intervalMinutes=30,recurrence='WEEKLY',specialPattern='FACTION_ROTATION',rotationWeeks=4,rotationFactions={'AD','EP','DC'}}
local c=assert(s:NormalizeSchedule(d))
eq(c.specialPattern,'FACTION_ROTATION')
for _,sample in ipairs({{'2026-10-01','AD'},{'2026-10-22','AD'},{'2026-10-29','EP'},{'2026-11-26','DC'},{'2026-12-24','AD'}}) do
    eq(s:GetScheduleEventVariant(c,s:ParseEasternDateTime(sample[1],'09:00 PM')),sample[2])
end
f.entry('all','ad','Amber Traders','PvP %eventfaction% at %eventtime%','Guild')
f.entry('ep','ad','Amber Traders','Pact only','Guild')
d.messageVariants={ep='EP'};assert(s:SaveGuildSchedule('ad','Amber Traders',d))
now=s:ParseEasternDateTime('2026-10-29','12:00 PM')
eq(s:GetScheduledEventTokenValue('eventfaction','ad','Amber Traders'),'Ebonheart Pact')
eq(#s:GetScheduledMessageEntries('ad','Amber Traders'),2)
local message=s:ApplyMessageSubstitutions('PvP %eventfaction% at %eventtime%','ad','Amber Traders')
assert(message:find('Ebonheart Pact',1,true));f.incoming(CHAT_CHANNEL_GUILD_1,message)
eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now)
now=s:ParseEasternDateTime('2026-11-26','12:00 PM');eq(#s:GetScheduledMessageEntries('ad','Amber Traders'),1)
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
assert(s:ImportSettingsFromString(s:BuildExportString()))
c=s:GetGuildSchedule('ad','Amber Traders');eq(c.rotationWeeks,4);eq(c.rotationFactions[2],'EP');eq(c.messageVariants.ep,'EP')
-- Changing order at the same event must invalidate the incoming-token matcher.
now=s:ParseEasternDateTime('2026-10-29','12:00 PM')
local template=s.savedVars.messages[1]
local text=s:NormalizeIncomingChatText(s:ApplyMessageSubstitutions(template.text,'ad','Amber Traders'))
assert(s:MatchesIncomingMessage(template,'Amber Traders',text))
c.rotationFactions={'AD','DC','EP'}
assert(not s:MatchesIncomingMessage(template,'Amber Traders',text))
local changed=s:NormalizeIncomingChatText(s:ApplyMessageSubstitutions(template.text,'ad','Amber Traders'))
assert(s:MatchesIncomingMessage(template,'Amber Traders',changed))

d.specialPattern='MONTH_FINAL';d.recurrence='BIWEEKLY';d.eventDate='2026-10-10';d.eventTime='08:00 PM'
d.messageVariants={ep='FINAL'}
assert(s:SaveGuildSchedule('ad','Amber Traders',d));c=s:GetGuildSchedule('ad','Amber Traders')
eq(s:GetScheduleMessageVariant(c,'all'),'REGULAR','unmarked messages default to regular')
eq(s:GetScheduleEventVariant(c,s:ParseEasternDateTime('2026-10-10','08:00 PM')),'REGULAR')
eq(s:GetScheduleEventVariant(c,s:ParseEasternDateTime('2026-10-24','08:00 PM')),'FINAL')
eq(s:GetScheduleEventVariant(c,s:ParseEasternDateTime('2027-01-02','08:00 PM')),'REGULAR')
eq(s:GetScheduleEventVariant(c,s:ParseEasternDateTime('2027-01-16','08:00 PM')),'REGULAR')
eq(s:GetScheduleEventVariant(c,s:ParseEasternDateTime('2027-01-30','08:00 PM')),'FINAL')
now=s:ParseEasternDateTime('2026-10-22','08:00 PM')
local entries=s:GetScheduledMessageEntries('ad','Amber Traders');eq(#entries,1);eq(entries[1].id,'ep')
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
assert(s:ImportSettingsFromString(s:BuildExportString()))
c=s:GetGuildSchedule('ad','Amber Traders');eq(c.specialPattern,'MONTH_FINAL');eq(c.messageVariants.ep,'FINAL')
assert(s:SetMessageLocked('ep',true));assert(not s:BuildExportString():find('SCHEDULEVARIANT_V1|ad|amber traders|ep',1,true))
assert(s:ImportSettingsFromString(s:BuildExportString()));eq(s:GetGuildSchedule('ad','Amber Traders').messageVariants.ep,'FINAL')
d.specialPattern='FACTION_ROTATION';d.rotationFactions={'AD','AD','DC'}
assert(not s:NormalizeSchedule(d),'duplicate faction stages must be rejected')

-- Exercise the actual settings callbacks and per-message group selectors.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end
s.RefreshSettingsUI=function() end
local controls=s:BuildScheduleOptionControls()
local function find(list,name)
    for _,control in ipairs(list) do
        if (type(control.name)=="function" and control.name() or control.name)==name then return control end
        if control.controls then local match=find(control.controls,name);if match then return match end end
    end
end
local pattern=assert(find(controls,'Special event pattern'))
pattern.setFunc('Faction rotation');eq(find(controls,'Faction rotation').disabled(),false)
find(controls,'Faction frequency (weeks)').setFunc('4')
find(controls,'First faction').setFunc('Daggerfall Covenant')
find(controls,'Second faction').setFunc('Aldmeri Dominion')
find(controls,'Third faction').setFunc('Ebonheart Pact')
local draft=s:GetScheduleEditorDraft();eq(draft.rotationFactions[1],'DC');eq(draft.rotationFactions[3],'EP')
find(controls,'Third faction').setFunc('Not used')
find(controls,'Faction frequency (weeks)').setFunc('2')
local two=assert(s:NormalizeSchedule(draft));eq(#two.rotationFactions,2)
eq(s:GetScheduleEventVariant(two,two.eventAtUtc),'DC')
eq(s:GetScheduleEventVariant(two,two.eventAtUtc+14*86400),'AD')
eq(s:GetScheduleEventVariant(two,two.eventAtUtc+28*86400),'DC')
find(controls,'Second faction').setFunc('Not used')
local one=assert(s:NormalizeSchedule(draft));eq(#one.rotationFactions,1)
eq(s:GetScheduleEventVariant(one,one.eventAtUtc+100*86400),'DC')
local checklist=s:GetScheduleMessageChecklist('DAY');eq(#checklist[1].variantChoices,2)
checklist[1].setVariant('DC');eq(draft.messageVariants.all,'DC')
pattern.setFunc('Last event of month')
checklist=s:GetScheduleMessageChecklist('DAY');eq(#checklist[1].variantChoices,2)
checklist[1].setVariant('FINAL');assert(checklist[1].phaseText)
assert(s:GetScheduleMessagePhaseText('all',draft):find('Month-final events',1,true))
local function control()
    local c={width=520,height=0,children={},handlers={}}
    function c:GetWidth() return self.width end
    function c:SetWidth(v) self.width=v end
    function c:SetHeight(v) self.height=v end
    function c:SetText(v) self.text=v end
    function c:GetTextHeight() return math.ceil(#(self.text or '')/math.max(1,math.floor(self.width/8)))*20 end
    function c:GetNamedChild(k) self.children[k]=self.children[k] or control();return self.children[k] end
    function c:SetHandler(k,v) self.handlers[k]=v end
    return setmetatable(c,{__index=function(_,k) if k:match('^Set') or k=='ClearAnchors' then return function() end end end})
end
WINDOW_MANAGER={CreateControl=function() return control() end,CreateControlFromVirtual=function() return control() end}
ZO_CheckButton_SetCheckState=function(c,v) c.checked=v end
ZO_CheckButton_SetToggleFunction=function(c,v) c.toggle=v end
ZO_Scroll_ResetToTop=function() end;ZO_Scroll_UpdateScrollBar=function() end
ZO_ComboBox_ObjectFromContainer=function(c)
    local combo={items={}}
    function combo:SetSortsItems() end
    function combo:ClearItems() self.items={} end
    function combo:CreateItemEntry(label,callback) return {label=label,callback=callback} end
    function combo:AddItem(item) self.items[#self.items+1]=item end
    function combo:SetSelectedItem(v) self.selected=v end
    return combo
end
local pool=control();s:RefreshScheduleMessagePool(pool,'DAY')
local row=pool.scheduleRows[1]
assert(row.variantButton,'month-final group must have a visible button')
eq(row.variantButton.text,'Group: Month-final events')
row.variantButton.handlers.OnClicked();eq(draft.messageVariants.all,'REGULAR')
s:RefreshScheduleMessagePool(pool,'DAY');eq(row.variantButton.text,'Group: Regular events')
assert(row.height>=row.label.height+36,'message group button must fit below wrapped text')
find(controls,'Schedule type').setFunc('Run during a window');eq(draft.specialPattern,'NONE')
-- Round-trip the flexible two-faction setup, including personal groups and new IDs.
f.reset();f.entry('shared','ad','Amber Traders','PvP for %eventfaction%','Guild')
f.entry('personal','ad','Amber Traders','Personal Pact notice','Guild')
local flexible={mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-10',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=20,
    recurrence='WEEKLY',intervalMinutes=30,specialPattern='FACTION_ROTATION',rotationWeeks=2,rotationFactions={'AD','EP'},
    messageVariants={personal='EP'},messagePhases={personal={DAY=true}}}
assert(s:SaveGuildSchedule('ad','Amber Traders',flexible));assert(s:SetMessageLocked('personal',true))
local export=s:BuildExportString():gsub('|ad|','|imported-id|')
assert(s:ImportSettingsFromString(export))
local restored=s:GetGuildSchedule('imported-id','Amber Traders')
eq(restored.specialPattern,'FACTION_ROTATION');eq(restored.rotationWeeks,2)
eq(#restored.rotationFactions,2);eq(restored.rotationFactions[1],'AD');eq(restored.rotationFactions[2],'EP')
eq(restored.messageVariants.personal,'EP');eq(restored.messagePhases.personal.DAY,true)
eq(restored.startsAtUtc,s:ParseEasternDateTime('2026-10-10','12:00 AM'))
eq(s:GetScheduleEventVariant(restored,s:ParseEasternDateTime('2026-10-24','08:00 PM')),'EP')
eq(s:GetScheduleEventVariant(restored,s:ParseEasternDateTime('2026-11-07','08:00 PM')),'AD')
local kept
for _,entry in ipairs(s.savedVars.messages) do if entry.id=='personal' then kept=entry end end
assert(kept and kept.locked and kept.commandId=='imported-id')
-- A month-final occurrence uses regular messages if no special messages exist.
f.reset();f.entry('regular','ad','Amber Traders','Regular raffle','Guild')
local raffle={mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-10',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=20,
    recurrence='BIWEEKLY',intervalMinutes=30,specialPattern='MONTH_FINAL',messageVariants={deleted='FINAL'}}
assert(s:SaveGuildSchedule('ad','Amber Traders',raffle))
now=s:ParseEasternDateTime('2026-10-22','08:00 PM')
local eligible=s:GetScheduledMessageEntries('ad','Amber Traders');eq(#eligible,1);eq(eligible[1].id,'regular')
f.entry('special','ad','Amber Traders','Special monthly raffle','Guild')
local config=s:GetGuildSchedule('ad','Amber Traders')
config.messageVariants.special='FINAL';config.messagePhases.special={DAY=true}
eq(#s:GetScheduledMessageEntries('ad','Amber Traders'),0,'configured special pool must still respect excluded phases')
now=s:ParseEasternDateTime('2026-10-24','12:00 PM')
eligible=s:GetScheduledMessageEntries('ad','Amber Traders');eq(#eligible,1);eq(eligible[1].id,'special')
assert(s:DeleteMessageEntry('special'))
eligible=s:GetScheduledMessageEntries('ad','Amber Traders');eq(#eligible,1);eq(eligible[1].id,'regular')
print('event rotation and month-final raffle checks passed')
