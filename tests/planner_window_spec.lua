local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('a','ad','Amber Traders','Tours %eventwhen% at %eventtime%')
local native
native=function(parent)
    local c={parent=parent,width=1420,height=860,hidden=true,handlers={}}
    function c:GetParent()return self.parent end
    function c:GetWidth()return self.width end;function c:GetHeight()return self.height end
    function c:SetDimensions(w,h)self.width=w;self.height=h end
    function c:SetWidth(w)self.width=w end;function c:SetHeight(h)self.height=h end
    function c:GetLeft()return 22 end;function c:GetTop()return 24 end
    function c:SetHidden(v)self.hidden=v end;function c:IsHidden()return self.hidden end
    function c:SetHandler(k,v)self.handlers[k]=v end
    function c:SetText(v)self.text=v end;function c:GetText()return self.text end
    function c:GetTextHeight()return math.ceil(#(self.text or '')/math.max(1,self.width/8))*20 end
    function c:GetNamedChild(k)self.children=self.children or {};self.children[k]=self.children[k] or native(self);return self.children[k]end
    return setmetatable(c,{__index=function(_,key)if key:match('^Set')or key=='ClearAnchors' or key=='LoseFocus' or key=='StartMoving' or key=='StopMovingOrResizing' then return function()end end;if key:match('^[A-Z]') then error('Unsupported control method '..key) end;return nil end})
end
GuiRoot=native();GuiRoot.width=1920;GuiRoot.height=1080
WINDOW_MANAGER={CreateControl=function(_,_,p)return native(p)end,CreateControlFromVirtual=function(_,_,p)return native(p)end}
function ZO_ComboBox_ObjectFromContainer(c)
    if not c.combo then
        c.combo={entries={}};function c.combo:SetSortsItems()end;function c.combo:ClearItems()self.entries={}end
        function c.combo:CreateItemEntry(label,fn)return {label=label,callback=fn}end
        function c.combo:AddItem(v)table.insert(self.entries,v)end;function c.combo:SetSelectedItem(v)self.selected=v end
    end;return c.combo
end
function ZO_Scroll_UpdateScrollBar()end;function ZO_Scroll_OnMouseWheel()end
SCENE_MANAGER={RegisterTopLevel=function()end,ShowTopLevel=function(_,w)w:SetHidden(false)end,HideTopLevel=function(_,w)w:SetHidden(true)end}
TOPLEFT,TOPRIGHT,CENTER,TOP=1,2,3,4;CT_CONTROL,CT_LABEL,CT_BUTTON,CT_EDITBOX,CT_SLIDER,CT_BACKDROP=1,2,3,4,5,6;DT_HIGH=3;TEXT_ALIGN_RIGHT=2;MOUSE_BUTTON_INDEX_LEFT=1
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
