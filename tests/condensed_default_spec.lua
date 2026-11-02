local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('m','ad','Amber Traders','At %eventtime%','Guild')
local settings=s:GetCommandGuildSettings('ad','Amber Traders',true)
settings.condensedDateTime=nil;eq(s:GetGuildCondensedDateTime('ad','Amber Traders'),true)
local draft=s:CreatePlannerDraft('ad','Amber Traders');eq(draft.behavior.condensedDateTime,true)
s:SetGuildCondensedDateTime('ad','Amber Traders',false);eq(s:GetGuildCondensedDateTime('ad','Amber Traders'),false)
draft=s:CreatePlannerDraft('ad','Amber Traders');eq(draft.behavior.condensedDateTime,false)
ZO_SavedVars={NewAccountWide=function()return s.savedVars end}
assert(s:ImportSettingsFromString(f.currentExport()));eq(s:GetGuildCondensedDateTime('ad','Amber Traders'),false)
s:GetCommandGuildSettings('ad','Amber Traders',true).condensedDateTime=nil
assert(s:ImportSettingsFromString(f.currentExport()));eq(s:GetGuildCondensedDateTime('ad','Amber Traders'),true)
print('PASS condensed defaults and preserved explicit long-format preference')
