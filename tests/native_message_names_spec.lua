local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();s.savedVars.selectedMessagesCommand='ad';s.savedVars.selectedMessagesGuildIndex=1;s.GetSelectedMessagesChannel=function()return 'Guild'end
assert(s:AddMessageEntryForSelection('Message body','  Opening reminder  '));local entry=s.savedVars.messages[1];eq(entry.name,'Opening reminder');entry.useCount=7;entry.lastUsedAt=123;local id=entry.id
assert(s:UpdateMessageEntry(id,'Updated body','Renamed reminder'));eq(entry.name,'Renamed reminder');eq(entry.id,id);eq(entry.useCount,7);eq(entry.lastUsedAt,123)
assert(s:UpdateMessageEntry(id,'Body-only edit'));eq(entry.name,'Renamed reminder','legacy callers retain name')
local ok=s:UpdateMessageEntry(id,'Do not save',string.rep('x',61));eq(ok,false);eq(entry.text,'Body-only edit');eq(entry.name,'Renamed reminder')
assert(s:UpdateMessageEntry(id,'Body-only edit',string.rep('猫',60)));eq(entry.name,string.rep('猫',60))
assert(s:UpdateMessageEntry(id,'Body-only edit',''));eq(entry.name,nil)
assert(s:AddMessageEntryForSelection('Other message'));eq(s.savedVars.messages[2].name,nil)
print('PASS native optional message-name API matches web character limit and preserves identity/history')
