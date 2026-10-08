SmartChatMsg = SmartChatMsg or {}

-- Edits stay in a draft until Save validates the complete window.
function SmartChatMsg:GetScheduleEditorDraft()
    local id=self.savedVars.selectedMessagesCommand
    local guild=self:GetSelectedGuildNameForMessages()
    local key=tostring(id)..":"..tostring(guild)
    local source=self:GetGuildSchedule(id,guild)
    if not self.scheduleEditor or self.scheduleEditor.key~=key or self.scheduleEditor.source~=source then
        local function copy(value)
            if type(value)~="table" then return value end
            local result={}; for k,v in pairs(value) do result[k]=copy(v) end; return result
        end
        local draft=source and copy(source) or {enabled=false,paused=false,delivery="REPEAT",intervalMinutes=15,
            startDate="",startTime="",eventDate="",eventTime="",endDate="",endTime="",messagePhases={},phaseIntervals={}}
        self.scheduleEditor={key=key,source=source,draft=draft}
    end
    return self.scheduleEditor.draft,id,guild
end

function SmartChatMsg:BuildScheduleOptionControls()
    local function draft() return self:GetScheduleEditorDraft() end
    local function refresh() self:RefreshSettingsUI() end
    local function selected() local _,id,guild=draft(); return self:GetCommandById(id) and self:GetGuildSlotByName(guild) end
    local controls={
        {type="description",text="Select a command and guild in Messages Settings first. All dates use Eastern Time (ET), including daylight saving time. Save applies the complete schedule. Messages are placed in chat; you still press Enter to send."},
        {type="description",text=function() local _,id,guild=draft(); return tostring(id or "No command").." / "..tostring(guild or "No guild").."\n"..self:GetScheduleStatusText(id,guild) end},
        {type="checkbox",name="Enable scheduled window",getFunc=function() return draft().enabled end,setFunc=function(v) draft().enabled=v end},
        {type="dropdown",name="Delivery",choices={"REPEAT","ZONE"},getFunc=function() return draft().delivery end,setFunc=function(v) draft().delivery=v end,
            tooltip="REPEAT uses the interval. ZONE fills chat on eligible zone arrivals and uses the interval as its per-zone cooldown."},
        {type="editbox",name="Default interval (minutes)",getFunc=function() return tostring(draft().intervalMinutes) end,setFunc=function(v) draft().intervalMinutes=v end},
    }
    for _,name in ipairs({"start","event","end"}) do
        local field=name
        controls[#controls+1]={type="editbox",name=field.." date (YYYY-MM-DD)",getFunc=function() return draft()[field.."Date"] end,setFunc=function(v) draft()[field.."Date"]=v end}
        controls[#controls+1]={type="editbox",name=field.." time (HH:MM AM/PM ET)",getFunc=function() return draft()[field.."Time"] end,setFunc=function(v) draft()[field.."Time"]=v end}
        controls[#controls+1]={type="dropdown",name=field.." repeated-hour choice",choices={"Automatic","EDT","EST"},
            getFunc=function() return draft()[field.."Fold"] or "Automatic" end,setFunc=function(v) draft()[field.."Fold"]=v~="Automatic" and v or nil end,
            tooltip="On the November clock change, 01:00–01:59 occurs twice. Choose EDT for the first occurrence or EST for the second. Spring missing times are rejected."}
    end
    for _,name in ipairs({"BEFORE","DAY","LIVE"}) do
        local phase=name
        controls[#controls+1]={type="editbox",name=phase.." interval override (blank uses default)",getFunc=function() return tostring(draft().phaseIntervals[phase] or "") end,setFunc=function(v) draft().phaseIntervals[phase]=v end}
    end
    controls[#controls+1]={type="description",text="BEFORE: before the event's Eastern calendar day. DAY: event-day midnight until the event. LIVE: event until window end. Unassigned messages apply to ANY phase. Use %eventdate%, %eventtime%, and %eventwhen% in message text."}
    controls[#controls+1]={type="description",text=function()
        local _,id,guild=draft(); local choices={}
        for index,entry in ipairs(self:GetMessageEntriesForCommandAndGuild(id,guild)) do
            choices[#choices+1]=tostring(index)..": "..entry.text
        end
        return table.concat(choices,"\n")
    end}
    controls[#controls+1]={type="editbox",name="Message number to assign",getFunc=function() draft(); return self.scheduleEditor.messageNumber or "" end,
        setFunc=function(v) local _,id,guild=draft(); self.scheduleEditor.messageNumber=v
            local entry=self:GetMessageEntriesForCommandAndGuild(id,guild)[tonumber(v)]
            self.scheduleEditor.messageId=entry and entry.id; refresh() end}
    for _,name in ipairs({"ANY","BEFORE","DAY","LIVE"}) do
        local phase=name
        controls[#controls+1]={type="checkbox",name="Selected message: "..phase,disabled=function() draft(); return not self.scheduleEditor.messageId end,
            getFunc=function() local d=draft(); local a=d.messagePhases[self.scheduleEditor.messageId]; return a and a[phase] or (not a and phase=="ANY") end,
            setFunc=function(v) local d=draft(); local id=self.scheduleEditor.messageId; if not id then return end
                d.messagePhases[id]=d.messagePhases[id] or {ANY=true}; d.messagePhases[id][phase]=v end}
    end
    controls[#controls+1]={type="button",name="Save schedule",disabled=function() return not selected() end,func=function()
        local d,id,guild=draft(); d.nextDueAt,d.nextDuePhase=nil,nil
        local ok,reason=self:SaveGuildSchedule(id,guild,d)
        self:ShowStatusMessage(ok and "Schedule saved." or reason); if ok then self.scheduleEditor=nil end; refresh()
    end}
    controls[#controls+1]={type="button",name="Pause saved schedule",func=function() local _,id,guild=draft(); local ok,reason=self:PauseGuildSchedule(id,guild); if not ok then self:ShowStatusMessage(reason) end; self.scheduleEditor=nil; refresh() end}
    controls[#controls+1]={type="button",name="Resume saved schedule",func=function() local _,id,guild=draft(); local ok,reason=self:ResumeGuildSchedule(id,guild); if not ok then self:ShowStatusMessage(reason) end; self.scheduleEditor=nil; refresh() end}
    return controls
end
