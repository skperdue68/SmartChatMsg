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

s.savedVars.messages={}
editor:RefreshEditor()
assert(holder:GetHeight()>0,"an empty list still reserves the Enter Message box")
assert(holder:GetHeight()<initial,"shrinking a message list must shrink the holder")
assert(schedule:GetTop()>named.SCM_EnterMessageBackdrop:GetBottom())
print("an empty message list still places Scheduling below the entry box")
