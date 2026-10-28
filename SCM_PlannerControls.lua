-- Small native controls shared by the custom planner; no web renderer or new library.
SmartChatMsg=SmartChatMsg or {}
local S=SmartChatMsg
local UI={};S.PlannerUI=UI
local gold={0.90,0.76,0.43,1}
function UI.control(parent,key,kind,virtual)
    parent.plannerControls=parent.plannerControls or {}
    local c=parent.plannerControls[key]
    if not c then
        S.plannerControlSerial=(S.plannerControlSerial or 0)+1
        local name='SCM_PlannerControl'..S.plannerControlSerial
        c=virtual and WINDOW_MANAGER:CreateControlFromVirtual(name,parent,virtual) or WINDOW_MANAGER:CreateControl(name,parent,kind)
        parent.plannerControls[key]=c
    end
    c.plannerScroll=parent.plannerScroll
    if c.plannerScroll then c:SetHandler('OnMouseWheel',function(_,delta)ZO_Scroll_OnMouseWheel(c.plannerScroll,delta)end) end
    c:SetHidden(false);return c
end
function UI.place(c,x,y,w,h)
    c:ClearAnchors();c:SetAnchor(TOPLEFT,c:GetParent(),TOPLEFT,x,y);c:SetDimensions(w,h);return c
end
function UI.hide(parent)
    for _,c in pairs(parent.plannerControls or {}) do c:SetHidden(true) end
end
function UI.tooltip(c,text)
    c:SetMouseEnabled(true)
    c:SetHandler('OnMouseEnter',function(control) InitializeTooltip(InformationTooltip,control,TOP,0,8);SetTooltipText(InformationTooltip,text) end)
    c:SetHandler('OnMouseExit',function()ClearTooltip(InformationTooltip)end)
end
function UI.label(parent,key,text,x,y,w,h,heading)
    local c=UI.control(parent,key,CT_LABEL);c:SetFont(heading and 'ZoFontWinH3' or 'ZoFontGame')
    c:SetColor(unpack(heading and gold or {0.86,0.86,0.81,1}));c:SetText(text);return UI.place(c,x,y,w,h or 28)
end
function UI.box(parent,key,x,y,w,h,selected)
    local c=UI.control(parent,key,CT_CONTROL);UI.place(c,x,y,w,h)
    local bg=UI.control(c,'bg',nil,'ZO_DefaultBackdrop');bg:SetAnchorFill(c)
    bg:SetCenterColor(selected and 0.16 or 0.025,selected and 0.13 or 0.025,0.035,0.97)
    bg:SetEdgeColor(selected and 0.95 or 0.40,selected and 0.77 or 0.35,selected and 0.35 or 0.22,1)
    bg:SetMouseEnabled(false);return c
end
function UI.button(parent,key,text,x,y,w,callback,primary,help)
    local c=UI.control(parent,key,CT_BUTTON);UI.place(c,x,y,w,32)
    c:SetMouseEnabled(true)
    if not c.plannerBackdrop then
        c.plannerBackdrop=UI.control(c,'backdrop',nil,'ZO_DefaultBackdrop');c.plannerBackdrop:SetAnchorFill(c);c.plannerBackdrop:SetMouseEnabled(false)
    end
    c.plannerBackdrop:SetCenterColor(primary and 0.28 or 0.07,primary and 0.22 or 0.07,primary and 0.09 or 0.075,1)
    c.plannerBackdrop:SetEdgeColor(0.55,0.46,0.27,1)
    c:SetFont('ZoFontGameBold');c:SetText(text);c:SetNormalFontColor(unpack(gold));c:SetMouseOverFontColor(1,0.93,0.67,1)
    c:SetHandler('OnClicked',callback);if help then UI.tooltip(c,help) end;return c
end
function UI.edit(parent,key,text,x,y,w,h,callback,multiline,help)
    local box=UI.box(parent,key,x,y,w,h)
    local edit=UI.control(box,'edit',CT_EDITBOX);UI.place(edit,8,4,w-16,h-8)
    edit:SetFont('ZoFontGame');edit:SetColor(0.96,0.96,0.91,1);edit:SetMaxInputChars(multiline and 2000 or 120)
    edit:SetMultiLine(multiline==true);edit:SetMouseEnabled(true)
    edit:SetEditEnabled(true)
    edit:SetHandler('OnTextChanged',nil);edit:SetText(tostring(text or ''))
    edit:SetHandler('OnTextChanged',function(c)if not S.plannerRefreshing then callback(c:GetText()) end end)
    edit:SetHandler('OnEscape',function(c)c:LoseFocus()end)
    if not multiline then edit:SetHandler('OnEnter',function(c)c:LoseFocus()end) end
    if help then UI.tooltip(box,help) end;box.edit=edit;return box
end
function UI.check(parent,key,text,value,x,y,w,callback,help,disabled)
    local c=UI.control(parent,key,CT_BUTTON);UI.place(c,x,y,w,28);c:SetMouseEnabled(not disabled)
    UI.label(c,'box',value and '[X]' or '[ ]',0,0,30,28)
    local l=UI.label(c,'label',text,32,0,w-32,28);if disabled then l:SetColor(0.45,0.45,0.45,1) end
    c:SetHandler('OnClicked',function()if not disabled then value=not value;c.plannerControls.box:SetText(value and '[X]' or '[ ]');callback(value)end end)
    if help then UI.tooltip(c,help);c:SetMouseEnabled(true) end
    return c
end
function UI.combo(parent,key,labels,values,value,x,y,w,callback,help)
    local c=UI.control(parent,key,nil,'ZO_ComboBox');UI.place(c,x,y,w,32)
    local combo=ZO_ComboBox_ObjectFromContainer(c);combo:SetSortsItems(false);combo:ClearItems()
    local selected='Choose'
    for i,label in ipairs(labels) do
        local v=values and values[i] or label
        local entry=combo:CreateItemEntry(label,function()if not S.plannerRefreshing then callback(v)end end)
        combo:AddItem(entry);if v==value then selected=label end
    end
    combo:SetSelectedItem(selected);if help then UI.tooltip(c,help) end;return c
end
function UI.slider(parent,key,label,value,min,max,x,y,w,callback,format,help)
    local holder=UI.control(parent,key,CT_CONTROL);UI.place(holder,x,y,w,58)
    local labelControl=UI.label(holder,'label',label..' — '..format(value),0,0,w,27)
    local c=UI.control(holder,'slider',CT_SLIDER);UI.place(c,4,32,w-12,16)
    c:SetOrientation(ORIENTATION_HORIZONTAL)
    c:SetMouseEnabled(true)
    c:SetMinMax(min,max);c:SetValueStep(1)
    c:SetThumbTexture('EsoUI/Art/Miscellaneous/scrollbox_elevator.dds','EsoUI/Art/Miscellaneous/scrollbox_elevator_disabled.dds',nil,8,16)
    local bg=UI.control(c,'track',CT_BACKDROP);bg:SetAnchorFill(c);bg:SetCenterColor(0.25,0.24,0.18,1);bg:SetEdgeColor(0.5,0.45,0.3,1);bg:SetMouseEnabled(false)
    c:SetHandler('OnValueChanged',nil);c:SetValue(value)
    c:SetHandler('OnValueChanged',function(_,v)if not S.plannerRefreshing then v=math.floor(v+0.5);callback(v);labelControl:SetText(label..' — '..format(v))end end)
    if help then UI.tooltip(holder,help) end;return holder
end
function UI.scroll(parent,key,x,y,w,h)
    local c=UI.control(parent,key,nil,'ZO_ScrollContainer');UI.place(c,x,y,w,h)
    local child=c:GetNamedChild('Scroll'):GetNamedChild('Child');child:SetResizeToFitDescendents(false);child:SetWidth(w-24)
    child.plannerScroll=c
    child:SetMouseEnabled(true);child:SetHandler('OnMouseWheel',function(_,d)ZO_Scroll_OnMouseWheel(c,d)end)
    return c,child,w-24
end
function UI.scrollEnd(scroll,child,height)
    child:SetHeight(math.max(1,height));ZO_Scroll_UpdateScrollBar(scroll)
end
function UI.clock(parent,key,value,x,y,w,callback,zone)
    local hour,minute,ampm=tostring(value or ''):match('^(%d%d?):(%d%d) ([AP]M)$')
    hour,minute,ampm=hour or '08',minute or '00',ampm or 'PM'
    local hours,minutes={},{};for h=1,12 do hours[#hours+1]=string.format('%02d',h)end;for m=0,59 do minutes[#minutes+1]=string.format('%02d',m)end
    local part=math.floor((w-38)/3)
    UI.combo(parent,key..'h',hours,nil,hour,x,y,part,function(v)callback(v..':'..minute..' '..ampm)end)
    UI.combo(parent,key..'m',minutes,nil,minute,x+part+3,y,part,function(v)callback(hour..':'..v..' '..ampm)end)
    UI.combo(parent,key..'a',{'AM','PM'},nil,ampm,x+part*2+6,y,part,function(v)callback(hour..':'..minute..' '..v)end)
    UI.label(parent,key..'z',zone or '',x+part*3+9,y+3,36,28)
end
-- A native, timezone-neutral calendar. Dates are civil dates, never OS-local timestamps.
function S:ShowPlannerCalendar(date,callback)
    local win=self.plannerWindow;local UI=self.PlannerUI
    local popup=UI.box(win,'calendar',0,0,330,330,true);popup:ClearAnchors();popup:SetAnchor(CENTER,win,CENTER,0,0);popup:SetDrawTier(DT_HIGH);popup:SetMouseEnabled(true)
    local year,month=tostring(date):match('^(%d%d%d%d)%-(%d%d)');year,month=tonumber(year) or 2026,tonumber(month) or 1
    year=math.max(2007,math.min(2099,year));month=math.max(1,math.min(12,month))
    local function render()
        UI.hide(popup);UI.box(popup,'background',0,0,330,330,true)
        UI.label(popup,'month',os.date('!%B %Y',self:ParseScheduleDateTime(string.format('%04d-%02d-01',year,month),'12:00 PM','FIRST',{timeZone='ET'})),45,12,240,28,true)
        UI.button(popup,'prev','<',10,10,30,function()if year==2007 and month==1 then return end;month=month-1;if month<1 then month=12;year=year-1 end;render()end)
        UI.button(popup,'next','>',288,10,30,function()if year==2099 and month==12 then return end;month=month+1;if month>12 then month=1;year=year+1 end;render()end)
        for i,label in ipairs({'Su','Mo','Tu','We','Th','Fr','Sa'}) do UI.label(popup,'day'..i,label,14+(i-1)*44,51,40,25)end
        local first=self:ParseScheduleDateTime(string.format('%04d-%02d-01',year,month),'12:00 PM','FIRST',{timeZone='ET'})
        local weekday=os.date('!*t',first).wday
        local days=({31,year%4==0 and (year%100~=0 or year%400==0) and 29 or 28,31,30,31,30,31,31,30,31,30,31})[month]
        for d=1,days do local day=d;local slot=weekday+d-2
            UI.button(popup,'date'..d,tostring(d),12+slot%7*44,78+math.floor(slot/7)*35,40,function()popup:SetHidden(true);callback(string.format('%04d-%02d-%02d',year,month,day))end,date==string.format('%04d-%02d-%02d',year,month,day))
        end
        UI.button(popup,'cancel','Cancel',110,291,110,function()popup:SetHidden(true)end)
    end
    render()
end
function UI.date(parent,key,date,x,y,w,callback)
    return UI.button(parent,key,date or 'Choose date',x,y,w,function()S:ShowPlannerCalendar(date,callback)end,false,'Choose a calendar date in the guild scheduling timezone.')
end
