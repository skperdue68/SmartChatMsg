-- Reuse the ESO mocks and run the incoming coordination regressions first.
dofile("tests/incoming_chat_spec.lua")
local scm=SmartChatMsg
local function reset()
    scm.savedVars={commands={{id="local",name="events"}},messages={},chatChannels={},commandGuildSettings={}}
    scm:SetSavedChatChannel("local","Amber Traders","Zone")
end
local serial=0
scm.GenerateUuid=function() serial=serial+1; return "shared-"..serial end
local function add(text,id)
    scm.savedVars.messages[#scm.savedVars.messages+1]={id=id or "old",commandId="local",guildName="Amber Traders",guildIndex=1,text=text,lastUsedAt=99}
end
local tests={}
local function test(name,fn) tests[#tests+1]={name,fn} end
test("selected export includes only its guild/channel templates and preserves escaped text",function()
    add("%guild% says | hello\n100% ready!")
    scm.savedVars.messages[#scm.savedVars.messages+1]={id="other",commandId="local",guildName="Blue Traders",text="Other guild"}
    local export,reason=scm:BuildMessageShareString("local","Amber Traders"); assert(export,reason)
    assert(export:match("^SCM_MESSAGES_V1")); assert(not export:find("Other guild",1,true))
    reset(); local ok,result=scm:ImportSharedMessages(export,"local","Amber Traders"); assert(ok,result)
    assert(scm.savedVars.messages[1].text=="%guild% says | hello\n100% ready!")
end)
test("merge preserves existing messages usage settings and skips exact duplicates",function()
    add("Shared template")
    local export=assert(scm:BuildMessageShareString("local","Amber Traders"))
    reset(); add("Personal template"); local own=scm.savedVars.messages[1]
    scm.savedVars.commandGuildSettings["local"]={sentinel={value="preserve"}}
    local settings=scm.savedVars.commandGuildSettings
    local ok= scm:ImportSharedMessages(export,"local","Amber Traders"); assert(ok)
    assert(#scm.savedVars.messages==2 and scm.savedVars.messages[1]==own and own.lastUsedAt==99)
    assert(scm.savedVars.commandGuildSettings==settings)
    assert(scm:ImportSharedMessages(export,"local","Amber Traders")); assert(#scm.savedVars.messages==2)
    assert(scm.savedVars.messages[2].lastUsedAt==nil)
end)
test("wrong guild channel and malformed input fail before any messages are added",function()
    add("Valid template"); local export=assert(scm:BuildMessageShareString("local","Amber Traders")); reset()
    assert(not scm:ImportSharedMessages(export:gsub("Amber Traders","Blue Traders"),"local","Amber Traders"))
    assert(not scm:ImportSharedMessages(export:gsub("|Zone","|Guild"),"local","Amber Traders"))
    assert(not scm:ImportSharedMessages(export:gsub("\nEND","\nUNKNOWN|oops\nEND"),"local","Amber Traders"))
    assert(not scm:ImportSharedMessages(export:gsub("\nEND",""),"local","Amber Traders"))
    assert(#scm.savedVars.messages==0)
end)
test("normal full-settings import rejects a message share instead of replacing settings",function()
    add("Valid template"); local export=assert(scm:BuildMessageShareString("local","Amber Traders"))
    local previous=scm.savedVars
    assert(not scm:ImportSettingsFromString(export)); assert(scm.savedVars==previous and #scm.savedVars.messages==1)
end)
test("shared templates participate in incoming peer coordination",function()
    add("%guild% is recruiting!"); local export=assert(scm:BuildMessageShareString("local","Amber Traders")); reset()
    assert(scm:ImportSharedMessages(export,"local","Amber Traders"))
    scm:HandleIncomingChatMessage(2,CHAT_CHANNEL_ZONE,"Other Character","Amber Traders is recruiting!",false,"@Other")
    assert(scm:GetGuildLastUsedAt("local","Amber Traders")==GetTimeStamp())
end)
test("settings export and merge callbacks retain selected destination and report results",function()
    add("%guild% shared message")
    scm.savedVars.selectedMessagesCommand="local"
    local oldGuild,oldRefresh=scm.GetSelectedGuildNameForMessages,scm.RefreshSettingsUI
    scm.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
    scm.RefreshSettingsUI=function() end
    local controls=scm:BuildMessageSharingOptionControls(); local byName={}
    for _,control in ipairs(controls) do if control.name then byName[control.name]=control end end
    byName["Export Messages"].func(); assert(scm.pendingMessageShareText:match("^SCM_MESSAGES_V1"))
    scm.savedVars.messages={}
    byName["Import Messages (merge)"].func()
    assert(#scm.savedVars.messages==1 and scm.pendingMessageShareText=="")
    scm.GetSelectedGuildNameForMessages,scm.RefreshSettingsUI=oldGuild,oldRefresh
end)
test("duplicate templates in one paste produce one addition and oversized records are rejected",function()
    local prefix="SCM_MESSAGES_V1\nSET|Amber Traders|Zone\n"
    assert(scm:ImportSharedMessages(prefix.."TEXT|Same\nTEXT|Same\nEND","local","Amber Traders"))
    assert(#scm.savedVars.messages==1)
    assert(not scm:ImportSharedMessages(prefix.."TEXT|Valid\nTEXT|"..string.rep("x",361).."\nEND","local","Amber Traders"))
    assert(#scm.savedVars.messages==1)
end)
local failures=0
for _,case in ipairs(tests) do
    reset(); local ok,reason=pcall(case[2]); if ok then print("PASS "..case[1]) else failures=failures+1; print("FAIL "..case[1]..": "..tostring(reason)) end
end
assert(failures==0,"message sharing failures: "..failures)
print(#tests.." message sharing tests, 0 failures")
