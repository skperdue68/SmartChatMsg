local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset()
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
local label=string.rep('猫',60)
local entry=f.entry('named','ad','Amber Traders','Outgoing body','Guild')
entry.name='  '..label..'  ';entry.displayOrder=17;entry.lastUsedAt=123;entry.useCount=7
local private=f.entry('private','ad','Amber Traders','Private body','Guild')
private.name='Private label';private.displayOrder=3;private.locked=true
local invalid=f.entry('invalid','ad','Amber Traders','Invalid metadata','Guild')
invalid.name=string.rep('猫',81);invalid.displayOrder=1.5
s:InitializeSavedVars()
eq(entry.name,label,'startup trims and retains Unicode label')
eq(entry.displayOrder,17);eq(entry.text,'Outgoing body')
eq(invalid.name,nil,'overlong label is omitted rather than byte-truncated')
eq(invalid.displayOrder,nil,'fractional order is omitted')
for _,value in ipairs({0,-1,1000001,math.huge}) do
 entry.displayOrder=value;s:InitializeSavedVars();eq(entry.displayOrder,nil)
end
entry.displayOrder=17
local exported=s:BuildExportString()
assert(not exported:find('Private label',1,true),'locked metadata is private')
assert(not exported:find('Private body',1,true),'locked body is private')
local collision=exported:gsub('\nEND$','\nMESSAGE|private|ad|1|Amber Traders|Changed body|0|0|Changed label|99\nEND')
assert(s:ImportSettingsFromString(collision))
local function find(id) for _,message in ipairs(s.savedVars.messages) do if message.id==id then return message end end end
eq(find('named').name,label);eq(find('named').displayOrder,17)
eq(find('named').lastUsedAt,123);eq(find('named').useCount,7)
eq(find('named').text,'Outgoing body','metadata does not alter outgoing text')
eq(find('private').name,'Private label');eq(find('private').displayOrder,3)
eq(find('private').text,'Private body','a colliding import cannot replace locked content')
local escaped=s:EscapeImportExportField(label)
local legacy=exported:gsub('|'..escaped..'|17','')
assert(s:ImportSettingsFromString(legacy))
eq(find('named').name,nil,'old MESSAGE rows need no metadata columns')
eq(find('named').displayOrder,nil)
eq(find('private').name,'Private label','local locked metadata survives older imports')
eq(find('private').displayOrder,3)
print('Optional message metadata survives startup and transfer without exposing locked metadata')
