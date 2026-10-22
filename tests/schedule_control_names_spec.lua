local f=dofile("tests/eso_fixture.lua")
local s,eq=f.scm,f.eq
f.reset();s.savedVars.selectedMessagesCommand="ad"
s.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
for i=1,3 do f.entry("m"..i,"ad","Amber Traders","Message "..i,"Guild") end
local names,count={},0
local function register(name)
 if name then assert(not names[name],"Duplicate global control: "..name);names[name]=true end
 count=count+1
end
local function control(name,parent)
 local c={width=520,height=0,text="",children={},handlers={}}
 function c:GetWidth() return self.width end
 function c:SetWidth(v) self.width=v end
 function c:SetHeight(v) self.height=v end
 function c:SetText(v) self.text=v end
 function c:GetTextHeight() return 30 end
 function c:SetHandler(k,fn) self.handlers[k]=fn end
 function c:GetNamedChild(k) if not self.children[k] then self.children[k]=control(nil,self) end;return self.children[k] end
 return setmetatable(c,{__index=function(_,k) if k:match("^Set") or k=="ClearAnchors" then return function() end end end})
end
WINDOW_MANAGER={CreateControl=function(_,name,parent) register(name);return control(name,parent) end,
 CreateControlFromVirtual=function(_,name,parent,template)
  register(name)
  if template=="ZO_DefaultBackdrop" then register((name or "").."MungeOverlay") end
  return control(name,parent)
 end}
ZO_CheckButton_SetCheckState=function() end;ZO_CheckButton_SetToggleFunction=function() end
ZO_Scroll_ResetToTop=function() end;ZO_Scroll_UpdateScrollBar=function() end
ZO_ComboBox_ObjectFromContainer=function() return setmetatable({CreateItemEntry=function(_,label,fn)return {label,fn}end},{__index=function()return function()end end}) end
local d=s:GetScheduleEditorDraft();d.mode="EVENT";d.specialPattern="MONTH_FINAL";d.startingSoonEnabled=true
local pools={}
for _,phase in ipairs({"BEFORE","DAY","SOON","LIVE"}) do
 local p=control();p.phase=phase;pools[#pools+1]=p;s:RefreshScheduleMessagePool(p,phase)
end
local created=count
for _,p in ipairs(pools) do s:RefreshScheduleMessagePool(p,p.phase) end
eq(count,created,"unchanged refreshes must reuse controls")
-- Allocate faction dropdowns on older pools after later pools exist.
d.specialPattern="FACTION_ROTATION"
for _,p in ipairs(pools) do s:RefreshScheduleMessagePool(p,p.phase) end
created=count
for _,p in ipairs(pools) do s:RefreshScheduleMessagePool(p,p.phase) end
eq(count,created)
print("schedule rows and all template children have stable unique names across pools and refreshes")
