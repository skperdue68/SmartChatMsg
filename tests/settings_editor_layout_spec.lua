local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset()
for i=1,12 do f.entry("m"..i,"ad","Amber Traders","A raffle announcement %eventwhen% at %eventtime%.","Guild") end
s.savedVars.selectedMessagesCommand="ad"
s.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
local selected=true
s.IsMessagesSelectionComplete=function() return selected end
s.GetSelectedMessagesChannel=function() return "Guild" end
s.GetMessageEntriesForSelection=function() return s.savedVars.messages end
s.settings.InitializeState=function() end
TOPLEFT="TOPLEFT";BOTTOMLEFT="BOTTOMLEFT";TOPRIGHT="TOPRIGHT";RIGHT="RIGHT";LEFT="LEFT"
local named={}
local function control(name,parent)
 local c={parent=parent,width=580,height=0,text="",hidden=false,handlers={}}
 if name then named[name]=c end
 function c:SetDimensions(w,h) self.width,self.height=w,h end
 function c:GetWidth() return self.width end
 function c:SetWidth(w) self.width=w end
 function c:GetHeight() return self.height end
 function c:SetHeight(h) self.height=h end
 function c:SetText(t) self.text=t end
 function c:GetText() return self.text end
 function c:SetHidden(v) self.hidden=v end
 function c:IsHidden() return self.hidden end
 function c:SetHandler(k,fn) self.handlers[k]=fn end
 function c:SetAnchor(_,relative,point,_,y) self.anchor={relative=relative,point=point,y=y or 0} end
 function c:ClearAnchors() self.anchor=nil end
 function c:GetTop()
  if not self.anchor then return self.parent and self.parent:GetTop() or 0 end
  return self.anchor.relative:GetTop()+(self.anchor.point==BOTTOMLEFT and self.anchor.relative:GetHeight() or 0)+self.anchor.y
 end
 function c:GetBottom() return self:GetTop()+self.height end
 return setmetatable(c,{__index=function(_,k) if k:match("^Set") then return function() end end end})
end
WINDOW_MANAGER={CreateControl=function(_,n,p) return control(n,p) end,CreateControlFromVirtual=function(_,n,p) return control(n,p) end}
ZO_Dialogs_RegisterCustomDialog=function() end
ZO_CheckButton_SetLabelText=function(c,text) c.label=text end
ZO_CheckButton_SetCheckState=function(c,value) c.checked=value end
ZO_CheckButton_SetToggleFunction=function(c,callback) c.toggle=callback end
local options
LibAddonMenu2={RegisterAddonPanel=function() return {} end,RegisterOptionControls=function(_,_,list) options=list end}
dofile("SCM_Settings.lua")
s:CreateSettingsPanel()
local editorOption
local function find(list)
 for _,item in ipairs(list) do
  if item.reference=="SCM_MessagesEditorHolder" then editorOption=item end
  if item.controls then find(item.controls) end
 end
end
find(options);assert(editorOption)
local holder=control("Holder")
editorOption.createFunc(holder)
local editor=assert(named.SCM_MessagesEditorContainer)
local schedule=control("Scheduling")
schedule:SetAnchor(TOPLEFT,holder,BOTTOMLEFT,0,0)
-- Native custom controls do not invoke refreshFunc on creation.
assert(holder:GetHeight()>=editor:GetHeight()+60,"initial custom holder must reserve the full editor and padding before LAM refresh")
assert(schedule:GetTop()>named.SCM_EnterMessageBackdrop:GetBottom(),"Scheduling must follow the Enter Message box")
for _,row in ipairs(s.settings.controls.savedMessageRows) do assert(row:GetBottom()<schedule:GetTop(),"Scheduling cannot overlap a saved message") end
local enabled
for name,c in pairs(named) do if name:match('^SCM_SavedMessageEnabled') and c.toggle then enabled=c;break end end
assert(enabled and enabled.checked and enabled.label=='Enabled','ordinary template has a checked Enabled control')
s.RefreshSettingsUI=function() editor:RefreshEditor() end
enabled.toggle(enabled,false);assert(next(s:GetCommandGuildSettings('ad','Amber Traders',false).disabledMessageIds));eq(#s:GetMessageEntriesForSelection(),12,'disabled templates remain in the editor')
enabled.toggle(enabled,true);eq(next(s:GetCommandGuildSettings('ad','Amber Traders',false).disabledMessageIds),nil)
local initial=holder:GetHeight()
f.entry("extra","ad","Amber Traders","Added while settings are open.","Guild")
editor:RefreshEditor()
assert(holder:GetHeight()>initial,"direct editor refresh must grow its LAM holder")
assert(schedule:GetTop()>named.SCM_EnterMessageBackdrop:GetBottom())
selected=false;editor:RefreshEditor();eq(holder:GetHeight(),0)
selected=true;editor:RefreshEditor();assert(holder:GetHeight()>initial)
editorOption.refreshFunc(holder)
eq(holder:GetHeight(),editor:GetHeight()+60,"LAM refresh and direct refresh must agree")
print("initial and refreshed settings reserve all message rows and the entry box before Scheduling")

local nameEdit=assert(named.SCM_SavedMessageNameEdit1,'saved message name field required')
local update=assert(named.SCM_SavedMessageUpdateButton1);local revert=assert(named.SCM_SavedMessageRevertButton1)
local entry=s.savedVars.messages[1];local text=entry.text;local used=entry.useCount
nameEdit:SetText('Early promotion');nameEdit.handlers.OnTextChanged(nameEdit);eq(s.settings:IsMessageEntryDirty(entry),true)
update.handlers.OnClicked();eq(entry.name,'Early promotion');eq(entry.text,text);eq(entry.useCount,used);eq(s.settings:IsMessageEntryDirty(entry),false)
nameEdit:SetText('Draft rename');nameEdit.handlers.OnTextChanged(nameEdit);revert.handlers.OnClicked();eq(entry.name,'Early promotion');eq(nameEdit:GetText(),'Early promotion')
nameEdit:SetText('');nameEdit.handlers.OnTextChanged(nameEdit);update.handlers.OnClicked();eq(entry.name,nil)
local newName=assert(named.SCM_NewMessageNameEdit);local newText=named.SCM_EnterMessageEditBox
newName:SetText('New named notice');newName.handlers.OnTextChanged(newName);newText:SetText('Actual outgoing message.');newText.handlers.OnTextChanged(newText)
named.SCM_MessagesEditorAddButton.handlers.OnClicked();local added=s.savedVars.messages[#s.savedVars.messages];eq(added.name,'New named notice');eq(added.text,'Actual outgoing message.');eq(newName:GetText(),'')
assert(schedule:GetTop()>named.SCM_EnterMessageBackdrop:GetBottom(),'name fields must remain inside the editor height')
print('PASS saved/new optional names, Update/Revert, name clearing and editor layout')

s.savedVars.messages={}
editor:RefreshEditor()
assert(holder:GetHeight()>0,"an empty list still reserves the Enter Message box")
assert(holder:GetHeight()<initial,"shrinking a message list must shrink the holder")
assert(schedule:GetTop()>named.SCM_EnterMessageBackdrop:GetBottom())
print("an empty message list still places Scheduling below the entry box")


newText:SetText('Hi 🌈');newText.handlers.OnTextChanged(newText);eq(named.SCM_NewMessageCharacterCount:GetText(),'4/350')
newText:SetText(string.rep('a',351));newText.handlers.OnTextChanged(newText);eq(named.SCM_NewMessageCharacterCount:GetText(),'351/350')
print('PASS live Unicode character counts for native new message editor')
