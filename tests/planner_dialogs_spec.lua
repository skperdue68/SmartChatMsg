dofile('tests/planner_window_spec.lua')
dofile('SCM_PlannerDialogs.lua')
local s=SmartChatMsg
local function click(c,key)c.plannerControls[key].handlers.OnClicked()end
local original=s.plannerModel
original.dirty=false
local guild=s.savedVars.defaultGuildIndex
local seconds=s:GetRevertChatSeconds()
s:OpenPlannerGlobalSettings()
local c=s.plannerWindow.plannerControls.globalSettings
assert(c and not c.hidden)
assert(#c.plannerControls.guild.combo.entries==#s:GetDefaultGuildOptions())
c.draft.seconds=99;c.draft.guild=0;click(c,'cancel')
assert(s.savedVars.defaultGuildIndex==guild and s:GetRevertChatSeconds()==seconds)
s:OpenPlannerGlobalSettings();c.draft.zone='INVALID';c.draft.seconds=99;click(c,'save')
assert(not c.hidden and s:GetRevertChatSeconds()==seconds and s.savedVars.defaultGuildIndex==guild)
c.draft.zone='ET';click(c,'save');assert(c.hidden and s:GetRevertChatSeconds()==99 and s.savedVars.defaultGuildIndex==nil)
assert(s.plannerModel~=original and not s.plannerModel.dirty)
local transfer=s:OpenPlannerTransfer()
local export=s.BuildExportString;local importer=s.ImportSettingsFromString
local exports=0;s.BuildExportString=function()exports=exports+1;return 'export text'end
s.plannerModel.dirty=true;click(transfer,'export');assert(exports==0 and s.plannerModel.dirty)
s.plannerModel.dirty=false;click(transfer,'export');assert(exports==1 and transfer.plannerControls.text.edit:GetText()=='export text')
click(transfer,'clear');assert(transfer.plannerControls.text.edit:GetText()=='')
transfer.plannerControls.text.edit:SetText('bad import')
local imports=0;s.ImportSettingsFromString=function(_,text)imports=imports+1;assert(text=='bad import');return false,'Bad import'end
click(transfer,'import');assert(imports==0)
local confirm=s.plannerWindow.plannerControls.confirmation;click(confirm,'cancel');assert(imports==0)
click(transfer,'import');click(confirm,'accept');assert(imports==1 and transfer.plannerControls.text.edit:GetText()=='bad import' and not transfer.hidden)
s.ImportSettingsFromString=function()imports=imports+1;return true end
local old=s.plannerModel;click(transfer,'import');click(confirm,'accept');assert(imports==2 and s.plannerModel~=old)
s.BuildExportString=export;s.ImportSettingsFromString=importer
print('PASS native global settings transactions and transfer confirmation, dirty guards, failure text retention and refresh')
