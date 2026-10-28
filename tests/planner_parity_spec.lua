local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('one','ad','Amber Traders','One');f.entry('two','ad','Blue Traders','Two')
local m=s:CreatePlannerDraft('ad','Amber Traders');local id=m.commandId
m.name='renamed';assert(s:SavePlannerDraft(m));eq(s:GetCommandById(id).name,'renamed');eq(#s.savedVars.messages,2)
m.name='off';assert(not s:SavePlannerDraft(m));eq(s:GetCommandById(id).name,'renamed')
local r=s:GetPlannerPeriod(m);r.availability={enabled=true,startMinute=420,endMinute=1320,weekdayOverrides={},dateOverrides={}}
assert(s:SetPlannerAvailabilityOverride(m,'weekdayOverrides',3,'startMinute','05:00 PM'));eq(r.availability.weekdayOverrides[3].startMinute,1020);eq(r.availability.weekdayOverrides[3].endMinute,1320)
assert(s:SetPlannerAvailabilityOverride(m,'dateOverrides','2026-10-27','endMinute','11:00 PM'));eq(r.availability.dateOverrides['2026-10-27'].startMinute,1020)
assert(s:SetPlannerAvailabilityOverride(m,'dateOverrides','2026-10-27','endMinute','12:00 AM'));eq(r.availability.dateOverrides['2026-10-27'].endMinute,1440)
assert(not s:SetPlannerAvailabilityOverride(m,'dateOverrides','not a date','startMinute','01:00 AM'))
assert(s:ResetPlannerAvailabilityOverride(m,'weekdayOverrides',3));assert(not r.availability.weekdayOverrides[3]);assert(r.availability.dateOverrides['2026-10-27'])
m.schedule.specialPattern='MONTH_FINAL';local labels,values=s:GetPlannerMessageGroups(m);eq(#values,3);eq(values[3],'ALL')
m.schedule.specialPattern='FACTION_ROTATION';m.schedule.rotationFactions={'EP','AD','NONE'};labels,values=s:GetPlannerMessageGroups(m);eq(#values,3);eq(values[1],'ALL');eq(values[2],'EP')
m.schedule.specialPattern='EVENT_ROTATION';m.schedule.rotationEvents={{id='stable',name='Trial'}};labels,values=s:GetPlannerMessageGroups(m);eq(values[2],'stable')
m=s:CreatePlannerDraft(id,'Amber Traders');m.messages[1].text='Changed';assert(s:ApplyPlannerMessage(m,m.messages[1].id));eq(s.savedVars.messages[1].text,'Changed');assert(not m.dirty)
m.messages[1].text='Unsaved';assert(s:RevertPlannerMessage(m,m.messages[1].id));eq(m.messages[1].text,'Changed');assert(not m.dirty)
print('PASS planner rename, other guild retention, inherited availability overrides/resets and message groups')

-- The custom window exposes all audited settings directly, without opening LAM.
dofile('tests/planner_window_spec.lua')
s=SmartChatMsg;assert(s:OpenEventPlanner())
assert(s.plannerEvents.plannerControls.globals and s.plannerEvents.plannerControls.transfer)
assert(s.plannerWindow.plannerControls.guildSettings)
m=s.plannerModel;m.schedule.recurrence='MONTHLY_WEEKDAY';m.schedule.specialPattern='NONE';m.tab='advanced';s:RefreshEventPlanner()
local editor=s.plannerWindow.plannerControls.detailPane.plannerControls.editor:GetNamedChild('Scroll'):GetNamedChild('Child')
assert(editor.plannerControls.monthlyWeek and editor.plannerControls.monthlyDay and editor.plannerControls.markAdd)
m.tab='period';local row=s:GetPlannerPeriod(m);row.availability={enabled=true,startMinute=420,endMinute=1320};s:RefreshEventPlanner()
assert(editor.plannerControls.overrideWeekday and editor.plannerControls.overrideDate and editor.plannerControls.weekdayOverridesReset and editor.plannerControls.dateOverridesReset)
assert(editor.plannerControls.paused and editor.plannerControls.afterStart)
m.schedule.specialPattern='MONTH_FINAL';m.tab='library';s:RefreshEventPlanner()
local card=editor.plannerControls['message'..m.messages[1].id];assert(card.plannerControls.apply and card.plannerControls.revert and card.plannerControls.libraryGroup)
m.tab='event';s:RefreshEventPlanner();assert(editor.plannerControls.deleteCommand and editor.plannerControls.soundPreview)
local old=s:GetCommandById(m.commandId);s:DeletePlannerCommand();s.plannerWindow.plannerControls.confirmation.plannerControls.cancel.handlers.OnClicked();assert(s:GetCommandById(m.commandId)==old)
m.runAt='ON_DEMAND';m.tab='advanced';s:RefreshEventPlanner();assert(m.tab=='event')
-- Exact numeric controls preserve the supported ordinary range and reject negatives.
local exact=editor.plannerControls['repeat'].plannerControls.exact.edit
exact:SetText('5000');exact.handlers.OnTextChanged(exact);assert(m.behavior.reminderMinutes==5000)
exact:SetText('-1');exact.handlers.OnTextChanged(exact);assert(m.behavior.reminderMinutes==5000)
local cool=editor.plannerControls.cooldown.plannerControls.exact.edit;cool:SetText('600');cool.handlers.OnTextChanged(cool);assert(m.behavior.autoPopulateCooldownMinutes==600)
-- The actual native transfer path exports/imports with merge semantics.
m.dirty=false;local transfer=s:OpenPlannerTransfer();transfer.plannerControls.export.handlers.OnClicked()
local exported=transfer.plannerControls.text.edit:GetText();assert(exported:find('SCM_EXPORT_V2',1,true))
ZO_SavedVars={NewAccountWide=function()return s.savedVars end}
local messages=#s.savedVars.messages;transfer.plannerControls.import.handlers.OnClicked();s.plannerWindow.plannerControls.confirmation.plannerControls.accept.handlers.OnClicked();assert(#s.savedVars.messages==messages)
print('PASS integrated globals, guild timezone, advanced/period/library settings, exact numbers and real merge transfer')

-- Repeat changes update Retry availability immediately, without rebuilding controls.
m=s.plannerModel;m.runAt='ON_DEMAND';m.tab='event';m.behavior.autoPopulateOnZone=false;m.behavior.reminderMinutes=nil;s:RefreshEventPlanner()
editor=s.plannerWindow.plannerControls.detailPane.plannerControls.editor:GetNamedChild('Scroll'):GetNamedChild('Child')
assert(editor.plannerControls.retry.plannerDisabled)
editor.plannerControls['repeat'].plannerControls.slider.handlers.OnValueChanged(nil,60);assert(not editor.plannerControls.retry.plannerDisabled)
editor.plannerControls['repeat'].plannerControls.slider.handlers.OnValueChanged(nil,0);assert(editor.plannerControls.retry.plannerDisabled)
-- Real global and guild-zone operations refresh the saved-source draft.
s.plannerModel=s:CreatePlannerDraft(m.commandId,m.guild);s:RefreshEventPlanner();s:OpenPlannerGlobalSettings()
local globals=s.plannerWindow.plannerControls.globalSettings;globals.draft.zone='CT';globals.draft.seconds=90;globals.draft.guild=2;globals.plannerControls.save.handlers.OnClicked()
assert(s:GetSchedulingTimeZone()=='CT' and s:GetRevertChatSeconds()==90 and s:GetDefaultGuildIndex()==2)
assert(s.plannerModel.source==s:GetGuildSchedule(s.plannerModel.commandId,s.plannerModel.guild))
s:OpenPlannerGuildSettings();local guildDialog=s.plannerWindow.plannerControls.guildSettings
guildDialog.plannerControls.zone.combo.entries[5].callback();guildDialog.plannerControls.save.handlers.OnClicked()
assert(s:GetGuildSchedulingTimeZoneOverride(s.plannerModel.guild)=='PT');assert(s.plannerModel.schedule.timeZone=='PT')

-- Global settings and command management remain available without guild membership.
local originalGuildId=GetGuildId;GetGuildId=function()return 0 end;s.plannerModel=nil
assert(s:OpenEventPlanner());assert(s.plannerModel.guild=='')
s:OpenPlannerGlobalSettings();assert(s.plannerWindow.plannerControls.globalSettings);s.plannerWindow.plannerControls.globalSettings.plannerControls.cancel.handlers.OnClicked()
local noGuild=s:CreatePlannerDraft(nil,'');noGuild.name='noguildcommand';local commands=#s:GetCommands();assert(s:SavePlannerDraft(noGuild));assert(#s:GetCommands()==commands+1)
assert(not s.savedVars.commandGuildSettings[noGuild.commandId]);GetGuildId=originalGuildId
