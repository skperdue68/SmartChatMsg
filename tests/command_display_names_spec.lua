local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();assert(s:AddCommand('fftg',nil,nil,'Sunday Fishing'))
local command;for _,c in ipairs(s:GetCommands())do if c.name=='fftg'then command=c end end
assert(command);eq(command.displayName,'Sunday Fishing');eq(s:GetCommandDisplayName(command),'Sunday Fishing')
assert(s:RenameCommand(command.id,' /ff-tg! ',nil,nil,'Sunday Fishing 🐟'));eq(command.name,'fftg');eq(command.displayName,'Sunday Fishing 🐟')
local draft=s:CreatePlannerDraft(command.id,'Amber Traders');eq(draft.displayName,'Sunday Fishing 🐟');draft.name=' /fftg!! ';assert(s:SavePlannerDraft(draft));eq(draft.name,'fftg')
ZO_SavedVars={NewAccountWide=function()return s.savedVars end};assert(s:ImportSettingsFromString(f.currentExport()));eq(s:GetCommandById(command.id).displayName,'Sunday Fishing 🐟')
assert(not s:RenameCommand(command.id,'o f f'));eq(s:GetCommandDisplayName({name='legacy'}),'legacy')
print('PASS display/slash names, planner and import roundtrip')

f.reset();s.savedVars.commands={{id='legacy',name='Sunday Fishing'}};s:InitializeSavedVars();eq(s.savedVars.commands[1].name,'SundayFishing');eq(s.savedVars.commands[1].displayName,'Sunday Fishing')
