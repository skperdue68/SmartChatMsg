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
CT_SLIDER="SLIDER";CT_TEXTURE="TEXTURE";CT_BACKDROP="BACKDROP";ORIENTATION_HORIZONTAL="HORIZONTAL"
local named={}
local function control(name,parent)
 local c={parent=parent,width=580,height=0,text="",hidden=false,handlers={}}
 if name then named[name]=c end
 function c:SetDimensions(w,h) self.width,self.height=w,h end
 function c:GetWidth() return self.width end
 function c:SetWidth(w) self.width=w end
 function c:GetHeight() return self.height end
 function c:SetHeight(h) self.height=h end
 function c:SetText(t) self.text=t;if self.handlers.OnTextChanged then self.handlers.OnTextChanged(self) end end
 function c:SetMinMax(low,high) self.min,self.max=low,high end
 function c:SetValue(v) self.value=v;if self.handlers.OnValueChanged then self.handlers.OnValueChanged(self,v) end end
 function c:GetValue() return self.value end
 function c:SetMouseEnabled(v) self.mouse=v end
 function c:SetEditEnabled(v) self.editEnabled=v end
 function c:GetText() return self.text end
 function c:SetEdgeTexture(path,w,h)self.edgeTexture=path;self.edgeWidth=w;self.edgeHeight=h end
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

ZO_ComboBox_ObjectFromContainer=function(control)
 local combo={items={}};function combo:SetSortsItems()end;function combo:ClearItems()self.items={}end;function combo:CreateItemEntry(label,fn)return {label=label,callback=fn}end;function combo:AddItem(item)self.items[#self.items+1]=item end;function combo:SetSelectedItem(label)self.selected=label end;control.combo=combo;return combo
end
s:CreateSettingsPanel()
local function find(list,reference)for _,v in ipairs(list)do if v.reference==reference then return v end;if v.controls then local hit=find(v.controls,reference);if hit then return hit end end end end
local holder=control('Holder');local option=find(options,'SCM_MessagesBehaviorSettingsHolder');assert(option)
s.settings.pendingGuildReminderMinutes='30';s.settings.pendingGuildReminderRetryMinutes='10';s.settings.pendingGuildAutoPopulateCooldownMinutes='60';s.settings.pendingGuildAutoPopulateOnZone=false
s.RefreshSettingsUI=function()end
option.createFunc(holder)
local repeatSlider=assert(named.SCM_MessagesReminderSlider,'Repeat slider required')
local retry=assert(named.SCM_MessagesReminderRetrySlider);local cooldown=assert(named.SCM_MessagesAutoPopulateCooldownSlider)
local container=named.SCM_MessagesBehaviorSettingsContainer
s.RefreshSettingsUI=function()container:RefreshEditor()end
local function move(c,value)c.handlers.OnValueChanged(c,value);c.handlers.OnSliderReleased(c,value)end
move(repeatSlider,20);eq(s:GetGuildReminderMinutes('ad','Amber Traders'),20);eq(retry.max,20)
move(retry,15);eq(s:GetGuildReminderRetryMinutes('ad','Amber Traders'),15)
move(cooldown,15);eq(s:GetGuildAutoPopulateCooldownMinutes('ad','Amber Traders'),15);eq(retry.max,15)
move(repeatSlider,0);assert(named.SCM_MessagesReminderLabel.text:find('Off',1,true));eq(retry.mouse,false)
move(repeatSlider,45);eq(retry.mouse,true);move(retry,0);assert(named.SCM_MessagesReminderRetryLabel.text:find('Off',1,true))
named.SCM_MessagesAutoPopulateCheckbox.toggle(nil,true);eq(repeatSlider.mouse,false);eq(retry.mouse,false)
-- Refresh clamps only thumb positions, never valid legacy settings.
s.settings.pendingGuildAutoPopulateOnZone=false;s.settings.pendingGuildReminderMinutes='2000';s.settings.pendingGuildAutoPopulateCooldownMinutes='5';s.settings.pendingGuildReminderRetryMinutes='90'
local saves=0;local save=s.settings.SaveBehaviorSettings;s.settings.SaveBehaviorSettings=function(...)saves=saves+1;return save(...)end
s.settings.pendingGuildAutoPopulateOnZone=true;container:RefreshEditor();eq(s.settings.pendingGuildAutoPopulateOnZone,true);eq(repeatSlider.mouse,false);eq(saves,0);s.settings.pendingGuildAutoPopulateOnZone=false
container:RefreshEditor();eq(saves,0);eq(s.settings.pendingGuildReminderMinutes,'2000');eq(s.settings.pendingGuildAutoPopulateCooldownMinutes,'5');eq(s.settings.pendingGuildReminderRetryMinutes,'90');eq(repeatSlider.value,1440);eq(cooldown.value,15);eq(retry.value,5)
assert(named.SCM_MessagesReminderLabel.text:find('2000',1,true));assert(named.SCM_MessagesAutoPopulateCooldownLabel.text:find('5',1,true))
move(cooldown,30);eq(s:GetGuildAutoPopulateCooldownMinutes('ad','Amber Traders'),30)
assert(named.SCM_MessagesPopulateSoundDropdown.combo.items[1]);named.SCM_MessagesPopulateSoundDropdown.combo.items[1].callback();assert(named.SCM_MessagesPopulateSoundPreviewButton.handlers.OnClicked)
assert(holder.height>=container.height);assert(container.height>235);eq(option.maxHeight,container.height)
local ordered={named.SCM_MessagesReminderLabel,repeatSlider,named.SCM_MessagesReminderRetryLabel,retry,named.SCM_MessagesAutoPopulateCooldownLabel,cooldown,named.SCM_MessagesAutoPopulateCheckbox,named.SCM_MessagesOpenStatusPanelOnRunCheckbox,named.SCM_MessagesRunAtLabel,named.SCM_MessagesPopulateSoundLabel}
for i,v in ipairs(ordered) do
 assert(v:GetTop()>=container:GetTop() and v:GetBottom()<=container:GetBottom(),'control remains inside reserved container')
 if i>1 then assert(v:GetTop()>=ordered[i-1]:GetBottom(),'stacked rows must not overlap') end
end
option.refreshFunc(holder);eq(holder.height,container.height)
print('PASS ordinary native sliders bounds, Off labels, disabled modes, retry caps, legacy refresh preservation and sound controls')

local timeout=find(options,'SCM_GeneralRevertSettingsHolder');eq(timeout.type,'slider');eq(timeout.min,30);eq(timeout.max,300);eq(timeout.step,1)
local previous=s:GetRevertChatSeconds();timeout.setFunc(120);eq(s:GetRevertChatSeconds(),120);eq(timeout.getFunc(),120)
timeout.setFunc(29);eq(s:GetRevertChatSeconds(),120);timeout.setFunc(301);eq(s:GetRevertChatSeconds(),120)
timeout.setFunc(30);eq(s:GetRevertChatSeconds(),30);timeout.setFunc(300);eq(s:GetRevertChatSeconds(),300)
print('PASS global timeout uses native LAM slider, persists bounds and rejects invalid changes')

for _,name in ipairs({'SCM_MessagesReminderSlider','SCM_MessagesReminderRetrySlider','SCM_MessagesAutoPopulateCooldownSlider'}) do
 local track=assert(named[name..'Track']);eq(track.edgeTexture,'EsoUI/Art/Tooltips/UI-SliderBackdrop.dds');eq(track.edgeWidth,32);eq(track.edgeHeight,4)
end
assert(named.SCM_MessagesReminderLabel.text:find('Repeat Frequency: ',1,true))
print('PASS ordinary sliders use LAM backdrop track and ASCII labels')

local originalRunAt=s.GetGuildRunAt;s.GetGuildRunAt=function()return 'SCHEDULED'end
s.settings.pendingGuildOpenStatusPanelOnRun=true
container:RefreshEditor();option.refreshFunc(holder)
eq(container.height,140);eq(holder.height,140)
for _,name in ipairs({'SCM_MessagesReminderSlider','SCM_MessagesReminderRetrySlider','SCM_MessagesAutoPopulateCooldownSlider','SCM_MessagesAutoPopulateCheckbox'})do eq(named[name].hidden,true)end
eq(repeatSlider.mouse,false);eq(retry.mouse,false);eq(cooldown.mouse,false)
eq(named.SCM_MessagesOpenStatusPanelOnRunCheckbox.mouse,true);eq(s.settings.pendingGuildOpenStatusPanelOnRun,true)
s.GetGuildRunAt=function()return 'ON_DEMAND'end;container:RefreshEditor();option.refreshFunc(holder)
eq(container.height,370);eq(holder.height,370);eq(repeatSlider.hidden,false);eq(cooldown.hidden,false)
s.GetGuildRunAt=originalRunAt
print('PASS scheduled delivery hides ordinary sliders, reclaims height and retains status-panel preference')
