local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('a','ad','Amber Traders','Tours %eventwhen% at %eventtime%')
local native
native=function(parent)
    local c={parent=parent,width=1420,height=860,hidden=true,handlers={}}
    function c:GetParent()return self.parent end
    function c:GetWidth()return self.width end;function c:GetHeight()return self.height end
    function c:SetDimensions(w,h)self.width=w;self.height=h end
    function c:SetHorizontalAlignment(v)self.horizontal=v end;function c:SetVerticalAlignment(v)self.vertical=v end
    function c:SetAnchor(point,relative,relativePoint,x,y)self.anchor={point=point,relative=relative,relativePoint=relativePoint,x=x,y=y}end
    function c:SetTexture(v)self.texture=v end
    function c:SetThumbTexture(...)self.thumb={...}end
    function c:SetWidth(w)self.width=w end;function c:SetHeight(h)self.height=h end
    function c:GetLeft()return 22 end;function c:GetTop()return 24 end
    function c:SetHidden(v)self.hidden=v end;function c:IsHidden()return self.hidden end
    function c:SetHandler(k,v)self.handlers[k]=v end
    function c:SetText(v)self.text=v end;function c:GetText()return self.text end
    function c:TakeFocus()self.focused=true end;function c:HasFocus()return self.focused==true end
    function c:SelectAll()assert(self.focused,'Selection must take keyboard focus first');self.selection={0,#(self.text or '')}end
    function c:SetCopyEnabled(v)self.copyEnabled=v end;function c:SetPasteEnabled(v)self.pasteEnabled=v end

    function c:GetTextHeight()return math.ceil(#(self.text or '')/math.max(1,self.width/8))*20 end
    function c:GetNamedChild(k)self.children=self.children or {};self.children[k]=self.children[k] or native(self);return self.children[k]end
    return setmetatable(c,{__index=function(_,key)if key:match('^Set')or key=='ClearAnchors' or key=='LoseFocus' or key=='StartMoving' or key=='StopMovingOrResizing' then return function()end end;if key:match('^[A-Z]') then error('Unsupported control method '..key) end;return nil end})
end
GuiRoot=native();GuiRoot.width=1920;GuiRoot.height=1080
WINDOW_MANAGER={CreateControl=function(_,_,p)return native(p)end,CreateControlFromVirtual=function(_,_,p,template)local c=native(p);c.template=template;return c end}
function ZO_CheckButton_SetCheckState(c,v)c.checked=v end
function ZO_CheckButton_IsChecked(c)return c.checked end
function ZO_CheckButton_SetToggleFunction(c,fn)c.toggle=fn end
function ZO_ComboBox_ObjectFromContainer(c)
    if not c.combo then
        c.combo={entries={}};function c.combo:SetSortsItems()end;function c.combo:ClearItems()self.entries={}end
        function c.combo:CreateItemEntry(label,fn)return {label=label,callback=fn}end
        function c.combo:AddItem(v)table.insert(self.entries,v)end;function c.combo:SetSelectedItem(v)self.selected=v end
    end;return c.combo
end
function ZO_Scroll_UpdateScrollBar()end;function ZO_Scroll_OnMouseWheel()end
SCENE_MANAGER={RegisterTopLevel=function()end,ShowTopLevel=function(_,w)w:SetHidden(false)end,HideTopLevel=function(_,w)w:SetHidden(true)end}
TOPLEFT,TOPRIGHT,CENTER,TOP=1,2,3,4;CT_CONTROL,CT_LABEL,CT_BUTTON,CT_EDITBOX,CT_SLIDER,CT_BACKDROP=1,2,3,4,5,6;DT_HIGH=3;TEXT_ALIGN_RIGHT=2;TEXT_ALIGN_CENTER=3;TEXT_ALIGN_TOP=4;TEXT_ALIGN_LEFT=5;CT_TEXTURE=7;MOUSE_BUTTON_INDEX_LEFT=1
s.plannerWindow=native(GuiRoot)
s.plannerModel=s:CreatePlannerDraft('ad','Amber Traders');s.plannerModel.runAt='SCHEDULED'
local model=s.plannerModel;model.schedule.eventDate='2026-10-27'
for i=1,5 do s:AddPlannerPeriod(model).label='Period '..i end;model.dirty=false
for i,r in ipairs(model.schedule.reminders) do r.start.minutes=-i*60;r.finish.minutes=-(i-1)*60;r.messageIds={'a'}end
assert(s:SaveGuildSchedule('ad','Amber Traders',model.schedule))
assert(s:OpenEventPlanner());model=s.plannerModel;eq(#model.schedule.reminders,6)
local pane=s.plannerPeriods
for _,r in ipairs(model.schedule.reminders)do
    local child=pane.plannerControls.periods:GetNamedChild('Scroll'):GetNamedChild('Child')
    local card=child.plannerControls['period'..r.id];assert(card and not card.hidden)
    card.handlers.OnMouseUp(nil,1,true);eq(s.plannerModel.periodId,r.id)
end
model=s.plannerModel
for _,tab in ipairs({'event','period','library'})do model.tab=tab;s:RefreshEventPlanner()end
local library=s.plannerWindow.plannerControls.detailPane.plannerControls.editor:GetNamedChild('Scroll'):GetNamedChild('Child')
library.plannerControls.add.handlers.OnClicked();eq(#model.messages,2);assert(model.dirty)
local changed=model.messages[2];local card=library.plannerControls['message'..changed.id]
card.plannerControls.text.edit:SetText('New message');card.plannerControls.text.edit.handlers.OnTextChanged(card.plannerControls.text.edit);eq(changed.text,'New message')
card.plannerControls.name.edit:SetText('My message');card.plannerControls.name.edit.handlers.OnTextChanged(card.plannerControls.name.edit);eq(changed.name,'My message')
s.plannerWindow.plannerControls.cancel.handlers.OnClicked();local modal=s.plannerWindow.plannerControls.discard;assert(not modal.hidden)
modal.plannerControls.cancel.handlers.OnClicked();assert(not s.plannerWindow.hidden);assert(model.dirty)
s.plannerWindow.plannerControls.save.handlers.OnClicked();assert(not model.dirty)
s.plannerWindow.plannerControls.cancel.handlers.OnClicked();assert(s.plannerWindow.hidden)
eq(s.savedVars.plannerWindowState.width,1420)
assert(s:HandleScmCommand('schedule'));assert(not s.plannerWindow.hidden)
-- Shared-cap selection must use the live slider value, not a stale empty table.
model=s.plannerModel;model.tab='period';local period=s:GetPlannerPeriod(model);period.availability=nil
s:RefreshEventPlanner()
local editor=s.plannerWindow.plannerControls.detailPane.plannerControls.editor:GetNamedChild('Scroll'):GetNamedChild('Child')
editor.plannerControls.daily.plannerControls.slider.handlers.OnValueChanged(nil,3)
editor.plannerControls.shared.handlers.OnClicked();eq(model.schedule.sharedDailyLimit,3)
period.availability.maxPerDay=8;s:RefreshEventPlanner()
assert(editor.plannerControls.daily.plannerControls.label.text:find('3 per day',1,true))
local before=s.plannerModel.schedule.eventDate
s:ShowPlannerCalendar(before,function(v)s.plannerModel.schedule.eventDate=v end)
s.plannerWindow.plannerControls.calendar.plannerControls.cancel.handlers.OnClicked();eq(s.plannerModel.schedule.eventDate,before)
print('PASS native planner shell, six period cards, tabs, live message drafts, Save/Cancel, calendar cancellation, geometry and /scm schedule')

-- Visual roles remain native controls, with alignment explicit and card lines separate.
local button=s.plannerWindow.plannerControls.save
assert(button.plannerControls.buttonText,'Expected a dedicated centered button label')
eq(button.plannerControls.buttonText.horizontal,TEXT_ALIGN_CENTER);eq(button.plannerControls.buttonText.vertical,TEXT_ALIGN_CENTER)
local row=s:GetPlannerPeriod(model)
local periodContent=s.plannerPeriods.plannerControls.periods:GetNamedChild('Scroll'):GetNamedChild('Child')
local periodCard=periodContent.plannerControls['period'..row.id]
assert(periodCard.plannerControls.starts and periodCard.plannerControls.stops and periodCard.plannerControls.frequency)
local starts,stops,frequency=periodCard.plannerControls.starts,periodCard.plannerControls.stops,periodCard.plannerControls.frequency
eq(starts.anchor.y+starts.height<=stops.anchor.y,true)
assert(frequency.anchor.y>=stops.anchor.y+stops.height+8,'Frequency needs its own row below Stops')
assert(periodCard.height>=frequency.anchor.y+frequency.height+8,'Card must grow to fit frequency')
local check=editor.plannerControls.shared
assert(check.plannerControls.box.template=='ZO_CheckButton');assert(type(check.plannerControls.box.checked)=='boolean')
local value=check.plannerControls.box.checked;check.handlers.OnClicked();eq(check.plannerControls.box.checked,not value)
local raw=editor.plannerControls.daily.plannerControls.slider
assert(raw.thumb[4]>=18 and raw.thumb[5]>=18,'Expected a larger native slider thumb')
assert(raw.plannerControls.track.height<=6,'Slider track should be narrow')
-- Current live activity is independent of which private draft period is selected.
local live=s:GetGuildSchedule('ad','Amber Traders');now=live.eventAtUtc-30*60
model=s.plannerModel;model.periodId=live.reminders[2].id;s:RefreshEventPlanner();s:RefreshPlannerActivityIndicators()
periodContent=s.plannerPeriods.plannerControls.periods:GetNamedChild('Scroll'):GetNamedChild('Child')
local active=s:GetActiveTimelineReminder(live,now);assert(active)
assert(not periodContent.plannerControls['period'..active.id].plannerControls.activeDot.hidden)
assert(periodContent.plannerControls['period'..model.periodId].plannerControls.activeDot.hidden)
assert(EVENT_MANAGER.updates.SCM_PlannerActivity)
local render=s.RefreshEventPlanner;s.RefreshEventPlanner=function()error('Activity refresh must not rebuild the editor')end
now=live.eventAtUtc-90*60;EVENT_MANAGER.updates.SCM_PlannerActivity.callback()
assert(not periodContent.plannerControls['period'..model.periodId].plannerControls.activeDot.hidden)
s.RefreshEventPlanner=render
local disabled=s.PlannerUI.check(s.plannerWindow,'disabledTest','Unavailable',false,0,0,200,function()error('Disabled checkbox changed')end,nil,true)
disabled.handlers.OnClicked();disabled.plannerControls.box.toggle(disabled.plannerControls.box,true);eq(disabled.plannerControls.box.checked,false)
s:HidePlannerWindow();assert(not EVENT_MANAGER.updates.SCM_PlannerActivity)
print('PASS planner theme roles, centered buttons, real checkboxes, slim sliders, distinct period lines and live activity')

local commandParent=s.PlannerUI.control(s.plannerWindow,'condensedSettingsTest',CT_CONTROL)
s:BuildPlannerEventEditor(commandParent,650)
local condensed=assert(commandParent.plannerControls.condensedDateTime)
local saved=s:GetGuildCondensedDateTime(model.commandId,model.guild)
local value=condensed.plannerControls.box.checked
condensed.handlers.OnClicked();eq(model.behavior.condensedDateTime,not value)
eq(s:GetGuildCondensedDateTime(model.commandId,model.guild),saved,'native checkbox edits only the command draft')
print('PASS native command settings exposes condensed format with private draft edits')
