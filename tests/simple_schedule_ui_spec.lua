local f=dofile("tests/eso_fixture.lua")
local scm,eq=f.scm,f.eq
f.reset()
f.entry("a","ad","Amber Traders","First actual message preview")
f.entry("b","ad","Amber Traders","Second actual message preview")
scm.savedVars.selectedMessagesCommand="ad"
scm.GetSelectedGuildNameForMessages=function() return "Amber Traders" end
scm.RefreshSettingsUI=function() end
local function find(list,name)
    for _,c in ipairs(list) do
        if c.name==name then return c end
        if c.controls then local found=find(c.controls,name); if found then return found end end
    end
end
local controls=scm:BuildScheduleOptionControls()
local kind=assert(find(controls,"Schedule type"),"simple schedule type missing")
kind.setFunc("Run during a window")
eq(scm:GetScheduleEditorDraft().mode,"WINDOW")
eq(find(controls,"Event and promotion timing").disabled(),true)
eq(find(controls,"Window dates and times").disabled(),false)
local date=assert(find(controls,"Start date (ET)"))
eq(date.type,"datepicker")
local carrier=scm:ScheduleDateToPicker("2026-10-16")
eq(scm:ScheduleDateFromPicker(carrier),"2026-10-16")
date.setFunc(carrier)
eq(scm:GetScheduleEditorDraft().startDate,"2026-10-16")
find(controls,"Start hour").setFunc("08")
find(controls,"Start minute").setFunc("35")
find(controls,"Start AM / PM").setFunc("PM")
eq(scm:GetScheduleEditorDraft().startTime,"08:35 PM")
kind.setFunc("Promote an event")
find(controls,"Repeat schedule").setFunc("Every other week")
eq(scm:GetScheduleEditorDraft().recurrence,"BIWEEKLY")
find(controls,"Sunday").setFunc(true)
eq(scm:GetScheduleEditorDraft().weekdays[1],true)
find(controls,"Prepare only once when event starts").setFunc(true)
eq(scm:GetScheduleEditorDraft().phaseOnce.LIVE,true)
local pool=assert(find(controls,"Before event day").controls[1])
local rows=scm:GetScheduleMessageChecklist("BEFORE")
eq(#rows,2); eq(rows[1].name,"First actual message preview")
rows[1].setFunc(true); rows[2].setFunc(true)
eq(rows[1].getFunc(),true); eq(rows[2].getFunc(),true)
eq(scm:GetScheduleEditorDraft().messagePhases.a.BEFORE,true)
eq(scm:GetScheduleEditorDraft().messagePhases.b.BEFORE,true)
assert(not find(controls,"Message number to assign"))
local originalDate=os.date
-- DatePicker reads/writes local calendar midnight. Simulate a UTC-7 client.
os.date=function(fmt,t)
    if fmt=="*t" then return originalDate("!*t",t-7*3600) end
    return originalDate(fmt,t)
end
local originalTime=os.time
os.time=function(p)
    local midnight=scm:ParseEasternDateTime(string.format("%04d-%02d-%02d",p.year,p.month,p.day),"12:00 AM")
    return midnight+ (7+scm:GetEasternUtcOffset(midnight))*3600
end
eq(scm:ScheduleDateFromPicker(scm:ScheduleDateToPicker("2026-10-16")),"2026-10-16")
os.date,os.time=originalDate,originalTime
find(controls,"Custom repeat interval (optional)").setFunc("")
eq(scm:GetScheduleEditorDraft().recurrenceInterval,nil)
-- Exercise the native custom control, including real checkbox toggle callbacks.
local function nativeControl()
    local c={width=600,hidden=false}
    function c:GetWidth() return self.width end
    function c:SetWidth(v) self.width=v end
    function c:SetHeight(v) self.height=v end
    function c:SetHidden(v) self.hidden=v end
    function c:SetText(v) self.text=v end
    function c:GetTextHeight() return 20 end
    function c:SetHandler(name,fn) self[name]=fn end
    function c:SetAnchor() end
    function c:ClearAnchors() end
    function c:SetFont() end
    function c:SetMouseEnabled() end
    return c
end
WINDOW_MANAGER={CreateControl=function() return nativeControl() end,CreateControlFromVirtual=function() return nativeControl() end}
function ZO_CheckButton_SetCheckState(c,v) c.checked=v end
function ZO_CheckButton_IsChecked(c) return c.checked end
function ZO_CheckButton_SetToggleFunction(c,fn) c.toggle=fn end
local holder=nativeControl()
pool.createFunc(holder)
eq(#holder.scheduleRows,2)
eq(holder.scheduleRows[1].label.text,"First actual message preview")
holder.scheduleRows[1].check.checked=false
holder.scheduleRows[1].check.toggle(holder.scheduleRows[1].check)
eq(scm:GetScheduleEditorDraft().messagePhases.a.BEFORE,false)
holder.scheduleRows[2].label.OnMouseUp()
eq(scm:GetScheduleEditorDraft().messagePhases.b.BEFORE,false)
f.entry("c","ad","Amber Traders","Added after settings opened")
pool.refreshFunc(holder)
eq(#holder.scheduleRows,3)
eq(holder.scheduleRows[3].label.text,"Added after settings opened")
-- Save through the UI validates all current fields and persists checklists.
now=1792080000
find(controls,"Sunday").setFunc(false)
find(controls,"Event date (ET)").setFunc(scm:ScheduleDateToPicker("2026-10-16"))
find(controls,"Event hour").setFunc("08")
find(controls,"Event minute").setFunc("00")
find(controls,"Event AM / PM").setFunc("PM")
rows=scm:GetScheduleMessageChecklist("BEFORE")
rows[1].setFunc(true); rows[2].setFunc(true)
local preview
for _,c in ipairs(controls) do
    if c.type=="description" and type(c.text)=="function" then
        local text=c.text(); if text:find("Upcoming occurrences",1,true) then preview=text end
    end
end
assert(preview and preview:find("2026%-10%-16") and preview:find("EDT"))
find(controls,"Save and activate").func()
local saved=assert(scm:GetGuildSchedule("ad","Amber Traders"))
eq(saved.messagePhases.a.BEFORE,true); eq(saved.messagePhases.b.BEFORE,true)
eq(saved.phaseOnce.LIVE,true)
scm:GetScheduleEditorDraft().eventTime="invalid"
find(controls,"Save and activate").func()
eq(scm:GetGuildSchedule("ad","Amber Traders"),saved)
-- Editing the loaded draft never changes the saved schedule before Save.
local loaded=scm:GetScheduleEditorDraft()
loaded.eventTime="09:00 PM"
eq(saved.eventTime,"08:00 PM")
-- Legacy exact windows keep their start/end when no offset is edited.
local legacy={enabled=false,delivery="REPEAT",intervalMinutes=5,startDate="2026-10-15",startTime="12:00 PM",eventDate="2026-10-16",eventTime="08:00 PM",endDate="2026-10-16",endTime="09:00 PM"}
assert(scm:SaveGuildSchedule("ad","Amber Traders",legacy))
scm.scheduleEditor=nil
local legacyDraft=scm:GetScheduleEditorDraft()
eq(legacyDraft.mode,"EVENT")
eq(legacyDraft.promotionDays,nil)
find(controls,"Save and activate").func()
eq(scm:GetGuildSchedule("ad","Amber Traders").startTime,"12:00 PM")
print("PASS simple schedule UI callbacks, native checklists, preview, transactional save and date carrier roundtrip")

-- Activation and disabled saves are distinct and validation remains transactional.
find(controls,"Save disabled").func()
eq(scm:GetGuildSchedule("ad","Amber Traders").enabled,false)
find(controls,"Save and activate").func()
eq(scm:GetGuildSchedule("ad","Amber Traders").enabled,true)
assert(not find(controls,"Enable schedule"))
assert(find(controls,"From event start until promotion ends"))
assert(find(controls,"More repeat options"))
print("PASS explicit activation and disabled save actions")

-- Capture actual panel registration to verify placement and its Run At gate.
local options
LibAddonMenu2={RegisterAddonPanel=function() return {} end,RegisterOptionControls=function(_,_,list) options=list end}
ZO_Dialogs_RegisterCustomDialog=function() end
dofile("SCM_Settings.lua")
scm.settings.InitializeState=function() end
scm:CreateSettingsPanel()
local messages=assert(find(options,"Create / Edit / Delete Messages"))
local nested=assert(find(messages.controls,"Scheduling (Eastern Time)"))
eq(messages.controls[#messages.controls],nested)
eq(messages.controls[#messages.controls-1].reference,"SCM_MessagesEditorHolder")
for _,section in ipairs(options) do assert(section.name~="Scheduling (Eastern Time)" and section.name~="Event Scheduling (Eastern Time)") end
scm.IsMessagesSelectionComplete=function() return true end
scm:SetGuildRunAt("ad","Amber Traders","ON_DEMAND");eq(nested.disabled(),true)
scm:SetGuildRunAt("ad","Amber Traders","STARTUP");eq(nested.disabled(),true)
scm:SetGuildRunAt("ad","Amber Traders","SCHEDULED");eq(nested.disabled(),false)
scm.IsMessagesSelectionComplete=function() return false end;eq(nested.disabled(),true)
print("PASS scheduling is nested under messages and enabled only for Scheduled selections")
