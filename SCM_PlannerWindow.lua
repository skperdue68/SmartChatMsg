SmartChatMsg=SmartChatMsg or {}
local S=SmartChatMsg
local UI=S.PlannerUI
local function has(list,id)for _,v in ipairs(list or {})do if v==id then return true end end return false end
local function clockMinute(v)return string.format('%02d:%02d %s',math.floor(v/60)%12==0 and 12 or math.floor(v/60)%12,v%60,v>=720 and 'PM' or 'AM')end
local function minuteClock(v)local h,m,a=v:match('^(%d%d?):(%d%d) ([AP]M)$');return (tonumber(h)%12+(a=='PM' and 12 or 0))*60+tonumber(m)end
function S:PlannerChanged()
    if not self.plannerModel then return end
    self.plannerModel.dirty=true
    self.plannerPreviewText=nil
    if self.plannerPreview then self.plannerPreview:SetText('Settings changed. Click Test to update this preview.') end
    if self.plannerFooter then self.plannerFooter:SetText('Unsaved changes — Save changes applies this event; Cancel discards edits.') end
    if self.plannerSave then self.plannerSave.plannerBackdrop:SetEdgeColor(1,0.75,0.25,1) end
end
function S:PlannerError(message)
    if self.plannerFooter then self.plannerFooter:SetText('|cFFAA77'..tostring(message or '')..'|r') end
end
function S:RequestPlannerAction(action)
    if not self.plannerModel or not self.plannerModel.dirty then action();return end
    local win=self.plannerWindow
    local modal=UI.box(win,'discard',0,0,550,180,true);modal:ClearAnchors();modal:SetAnchor(CENTER,win,CENTER,0,0);modal:SetDrawTier(DT_HIGH);modal:SetMouseEnabled(true)
    UI.label(modal,'title','Discard unsaved changes?',20,14,510,30,true)
    UI.label(modal,'body','Your saved event will stay unchanged. Discard this draft to continue, or Cancel to keep editing.',20,52,510,62)
    UI.button(modal,'discard','Discard edits',24,126,220,function()modal:SetHidden(true);action()end)
    UI.button(modal,'cancel','Cancel',270,126,250,function()modal:SetHidden(true)end,true)
end
function S:SavePlannerWindowGeometry()
    local w=self.plannerWindow
    if not w or not self.savedVars then return end
    self.savedVars.plannerWindowState={width=w:GetWidth(),height=w:GetHeight(),x=w:GetLeft(),y=w:GetTop()}
end
function S:HidePlannerWindow()
    self:SavePlannerWindowGeometry();self.plannerWindow:SetHidden(true)
    if SCENE_MANAGER and self.plannerRegistered then SCENE_MANAGER:HideTopLevel(self.plannerWindow) end
end
function S:OpenPlannerExistingSettings()
    self:RequestPlannerAction(function()
        local m=self.plannerModel
        if m and m.commandId then
            self.savedVars.selectedMessagesCommand=m.commandId
            self.savedVars.selectedMessagesGuildIndex=self:GetGuildSlotByName(m.guild)
            self:SetSelectedMessagesChannel(self:GetSavedChatChannel(m.commandId,m.guild) or m.channel)
            self.scheduleEditor=nil
        end
        self:HidePlannerWindow();self:OpenSettings()
    end)
end
function S:OpenEventPlanner()
    local win=self.plannerWindow or _G.SCM_EventPlanner
    if not win then self:AddLocalChatMessage('[SmartChatMsg] Planner window is unavailable. Reinstall all addon files, including SCM_PlannerWindow.xml.');return false end
    self.plannerWindow=win
    if not self.plannerInitialized then
        win:SetDimensionConstraints(1080,660);win:SetResizeHandleSize(16)
        win:SetHandler('OnResizeStop',function()self:SavePlannerWindowGeometry();self:RefreshEventPlanner()end)
        win:SetHandler('OnMoveStop',function()self:SavePlannerWindowGeometry()end)
        win:SetHandler('OnRectWidthChanged',function()if not self.plannerRefreshing then self:RefreshEventPlanner()end end)
        win:SetHandler('OnEffectivelyHidden',function()self:SavePlannerWindowGeometry()end)
        if SCENE_MANAGER then SCENE_MANAGER:RegisterTopLevel(win,true);self.plannerRegistered=true end
        local state=self.savedVars.plannerWindowState or {}
        win:SetDimensions(math.min(GuiRoot:GetWidth()-32,math.max(1080,state.width or 1420)),math.min(GuiRoot:GetHeight()-32,math.max(660,state.height or 860)))
        if state.x and state.y then win:ClearAnchors();win:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,state.x,state.y) end
        self.plannerInitialized=true
    end
    local guild=self.plannerModel and self.plannerModel.guild or self:GetSelectedGuildNameForMessages() or self:GetGuildNameByIndex(1)
    if not guild then self:AddLocalChatMessage('[SmartChatMsg] Join a guild before using the event planner.');return false end
    if not self.plannerModel or not self.plannerModel.dirty then
        local id=self.plannerModel and self.plannerModel.commandId or self.savedVars.selectedMessagesCommand
        if not id then local commands=self:GetCommands();id=commands[1] and commands[1].id end
        self.plannerModel=self:CreatePlannerDraft(id,guild)
    end
    if SCENE_MANAGER and self.plannerRegistered then SCENE_MANAGER:ShowTopLevel(win) else win:SetHidden(false);SetGameCameraUIMode(true) end
    self:RefreshEventPlanner();return true
end
function S:RefreshPlannerEvents(parent,w,h)
    UI.hide(parent);UI.label(parent,'title','EVENTS',14,12,w-24,30,true)
    UI.edit(parent,'search',self.plannerSearch or '',12,48,w-24,32,function(text)self.plannerSearch=text;self:RefreshPlannerEventList()end,false,'Filter by command/event name.')
    UI.button(parent,'new','+ Event',12,88,w-24,function()self:RequestPlannerAction(function()self.plannerModel=self:CreatePlannerDraft(nil,self.plannerModel.guild);self.plannerModel.tab='event';self:RefreshEventPlanner()end)end)
    local scroll,child,cw=UI.scroll(parent,'events',8,128,w-16,h-232);UI.hide(child)
    local y=0;local m=self.plannerModel
    for _,command in ipairs(self:GetCommands()) do if (command.name or ''):lower():find((self.plannerSearch or ''):lower(),1,true) then
        local id=command.id
        local button=UI.button(child,'event'..id,command.name,4,y,cw-8,function()self:RequestPlannerAction(function()self.plannerModel=self:CreatePlannerDraft(id,m.guild);self:RefreshEventPlanner()end)end,id==m.commandId)
        button:SetHeight(45);y=y+51
    end end
    UI.scrollEnd(scroll,child,y)
    UI.button(parent,'existing','Existing settings',12,h-94,w-24,function()self:OpenPlannerExistingSettings()end,false,'Open the original settings, including import/export and advanced configuration. Save this draft first to keep its changes.')
    UI.label(parent,'hint','Import / export and advanced options remain in Existing settings.',14,h-56,w-28,50)
end
function S:RefreshPlannerEventList()
    if self.plannerEvents then self:RefreshPlannerEvents(self.plannerEvents,self.plannerEvents:GetWidth(),self.plannerEvents:GetHeight()) end
end
function S:RefreshPlannerPeriods(parent,w,h)
    UI.hide(parent);local m=self.plannerModel
    UI.label(parent,'title',m.runAt=='SCHEDULED' and 'PERIODS' or 'MESSAGE POOL',14,12,w-24,30,true)
    UI.label(parent,'event',m.name~='' and m.name or 'New event',14,48,w-28,30,true)
    if m.runAt~='SCHEDULED' then
        UI.label(parent,'ordinary','All enabled messages share this command’s random pool. Choose Message library to edit them.',14,92,w-28,120)
        UI.button(parent,'library','Message library',14,220,w-28,function()m.tab='library';self:RefreshEventPlanner()end)
        UI.label(parent,'run',m.runAt=='STARTUP' and 'Engages on login.' or 'Engages when you run its slash command.',14,264,w-28,80);return
    end
    local occurrence,c,reason=self:GetPlannerOccurrence(m)
    UI.label(parent,'summary',occurrence and self:FormatScheduleDateTime(occurrence.eventAtUtc,c)..'\n'..tostring(m.schedule.recurrence or 'NONE'):gsub('_',' ') or tostring(reason),14,83,w-28,64)
    local scroll,child,cw=UI.scroll(parent,'periods',8,154,w-16,h-208);UI.hide(child)
    local y=0
    for _,r in ipairs(m.schedule.reminders or {}) do
        local id=r.id;local card=UI.box(child,'period'..id,2,y,cw-4,100,m.periodId==id);card:SetMouseEnabled(true)
        local function select()self:SelectPlannerPeriod(m,id);m.tab='period';self.plannerDetailScroll=0;self:RefreshEventPlanner()end
        card:SetHandler('OnMouseUp',function(_,button,inside)if button==MOUSE_BUTTON_INDEX_LEFT and inside then select()end end)
        local label=UI.label(card,'name',(r.enabled==false or r.paused) and '|c888888'..r.label..' (disabled)|r' or r.label,10,6,cw-24,26,true)
        label:SetMouseEnabled(true);label:SetHandler('OnMouseUp',function(_,button,inside)if button==MOUSE_BUTTON_INDEX_LEFT and inside then select()end end)
        local first=occurrence and self:ResolveTimelineAnchor(c,occurrence,r.start)
        local last=occurrence and not (r.once and not r.onceUntilFinish) and self:ResolveTimelineAnchor(c,occurrence,r.finish)
        local text=first and self:FormatScheduleDateTime(first,c) or 'Choose dates'
        if last then text=text..'\n'..self:FormatScheduleDateTime(last,c) end
        text=text..'\n'..(r.once and 'Send once' or 'Every '..self:FormatSchedulingMinutes(r.intervalMinutes or 30))
        local detail=UI.label(card,'detail',text,10,33,cw-24,66);detail:SetMouseEnabled(true);detail:SetHandler('OnMouseUp',function(_,button,inside)if button==MOUSE_BUTTON_INDEX_LEFT and inside then select()end end)
        for _,control in ipairs({card,label,detail})do control:SetHandler('OnMouseWheel',function(_,delta)ZO_Scroll_OnMouseWheel(scroll,delta)end)end
        y=y+108
    end
    UI.scrollEnd(scroll,child,y)
    UI.button(parent,'add','+ Period',12,h-44,w-24,function()local r,error=self:AddPlannerPeriod(m);if not r then self:PlannerError(error);return end;m.tab='period';self:RefreshEventPlanner()end)
end
function S:PlannerNumber(parent,key,label,value,min,max,x,y,w,set,zero)
    UI.slider(parent,key,label,tonumber(value) or min,min,math.max(max,tonumber(value) or min),x,y,w,function(n)set(n);self:PlannerChanged()end,function(n)return n==0 and (zero or 'Off') or self:FormatSchedulingMinutes(n)end)
end
function S:BuildPlannerEventEditor(parent,w)
    local m=self.plannerModel;local d=m.schedule;local y=12
    UI.label(parent,'nameLabel','Event / command name',8,y,w-16,26)
    if m.commandId then UI.label(UI.box(parent,'name',8,y+28,w-16,34),'text',m.name,8,3,w-32,28)
    else UI.edit(parent,'name',m.name,8,y+28,w-16,34,function(v)m.name=v;self:PlannerChanged()end,false,'1–25 letters/numbers; existing command names are renamed in Existing settings.') end;y=y+80
    UI.label(parent,'runLabel','Run at',8,y,w-16,25)
    UI.combo(parent,'run',{'On Demand','Startup','Scheduled'},{'ON_DEMAND','STARTUP','SCHEDULED'},m.runAt,8,y+28,w-16,function(v)m.runAt=v;if v=='SCHEDULED' and #(d.reminders or {})==0 then self:AddPlannerPeriod(m)end;self:PlannerChanged();self:RefreshEventPlanner()end);y=y+76
    if m.runAt=='SCHEDULED' then
        local half=math.floor((w-32)/2)
        UI.label(parent,'dateLabel','Event Date',8,y,half,26);UI.label(parent,'timeLabel','Event Start Time',half+24,y,half,26)
        UI.date(parent,'eventDate',d.eventDate,8,y+28,half,function(v)d.eventDate=v;d.eventAtUtc=nil;self:PlannerChanged();self:RefreshEventPlanner()end)
        UI.clock(parent,'eventTime',d.eventTime,half+24,y+28,half,function(v)d.eventTime=v;d.eventAtUtc=nil;self:PlannerChanged();self:RefreshEventPlanner()end,d.timeZone);y=y+76
        UI.label(parent,'repeatLabel','Recurrence',8,y,w-16,25)
        UI.combo(parent,'recurrence',{'Does not repeat','Every day','Every week','Every other week','Monthly date','Monthly weekday'},{'NONE','DAILY','WEEKLY','BIWEEKLY','MONTHLY_DATE','MONTHLY_WEEKDAY'},d.recurrence or 'NONE',8,y+28,w-16,function(v)d.recurrence=v;self:PlannerChanged();self:RefreshEventPlanner()end);y=y+76
        if d.recurrence~='NONE' then
            UI.slider(parent,'interval','Recurrence interval',d.recurrenceInterval or 1,1,10,8,y,w-16,function(v)d.recurrenceInterval=v;self:PlannerChanged();self:RefreshPlannerPeriodSummary()end,tostring,'Multiplier for the recurrence above. Every week with interval 2 means every two weeks.');y=y+66
        end
        self:PlannerNumber(parent,'duration','Event duration',d.eventDurationMinutes or 0,0,240,8,y,w-16,function(v)d.eventDurationMinutes=v>0 and v or nil end,'Not set');y=y+70
        UI.check(parent,'eventEnabled','Enabled',d.enabled~=false and not d.paused,8,y,180,function(v)d.enabled=v;d.paused=false;self:PlannerChanged();self:RefreshEventPlanner()end,'Enable scheduled preparation. Monitoring incoming matching chat remains active.');y=y+38
        local occurrence,c,reason=self:GetPlannerOccurrence(m)
        UI.label(parent,'next',occurrence and 'Next event: '..self:FormatScheduleDateTime(occurrence.eventAtUtc,c) or tostring(reason),8,y,w-16,60);y=y+66
        if c then
            local items=self:GetUpcomingScheduleOccurrences(c,GetTimeStamp(),4,true);local lines={'Upcoming events'}
            for _,o in ipairs(items)do lines[#lines+1]=self:FormatScheduleDateTime(o.eventAtUtc,c)..(c.specialPattern~='NONE' and ' — '..self:GetScheduleVariantLabel(self:GetScheduleEventVariant(c,o.eventAtUtc),c.specialPattern,c) or '')end
            UI.label(parent,'upcoming',table.concat(lines,'\n'),8,y,w-16,140);y=y+148
        end
        UI.button(parent,'advanced','Patterns, important times & advanced settings',8,y,w-16,function()self:OpenPlannerExistingSettings()end,false,'Save changes first, then use Existing settings for faction/rotating event lists, occurrence cancellations, monthly patterns and named important times. They are preserved when saving here.');y=y+44
    else
        local b=m.behavior
        local function minutes(v)return v==0 and 'Off' or self:FormatSchedulingMinutes(v)end
        local repeatValue=b.reminderMinutes or 0
        local function updateRetry()
            local cap=math.min(b.reminderMinutes and b.reminderMinutes>0 and b.reminderMinutes or math.huge,b.autoPopulateCooldownMinutes or 60)
            b.reminderRetryMinutes=math.min(b.reminderRetryMinutes or 0,cap)
            local holder=parent.plannerControls.retry
            if holder then
                holder.plannerControls.slider:SetMinMax(0,cap);holder.plannerControls.slider:SetValue(b.reminderRetryMinutes)
                holder.plannerControls.label:SetText('Retry Delay — '..minutes(b.reminderRetryMinutes))
            end
        end
        UI.slider(parent,'repeat','Repeat Frequency',repeatValue,0,math.max(1440,repeatValue),8,y,w-16,function(v)if b.autoPopulateOnZone then return end;b.reminderMinutes=v>0 and v or nil;updateRetry();self:PlannerChanged()end,minutes,'Off disables timed repetition. Auto Populate Chat on Zone is an alternative to repetition.')
        if b.autoPopulateOnZone then parent.plannerControls['repeat']:SetMouseEnabled(false);parent.plannerControls['repeat']:SetAlpha(0.4);parent.plannerControls['repeat'].plannerControls.slider:SetMouseEnabled(false)else parent.plannerControls['repeat']:SetAlpha(1);parent.plannerControls['repeat'].plannerControls.slider:SetMouseEnabled(true)end;y=y+70
        local cap=math.min(repeatValue>0 and repeatValue or math.huge,b.autoPopulateCooldownMinutes or 60)
        self:PlannerNumber(parent,'retry','Retry Delay',math.min(b.reminderRetryMinutes or 0,cap),0,cap,8,y,w-16,function(v)b.reminderRetryMinutes=v end);y=y+70
        self:PlannerNumber(parent,'cooldown','Cooldown',b.autoPopulateCooldownMinutes or 60,15,480,8,y,w-16,function(v)b.autoPopulateCooldownMinutes=v;updateRetry()end);y=y+70
        UI.check(parent,'zone','Auto Populate Chat on Zone',b.autoPopulateOnZone==true,8,y,w-16,function(v)b.autoPopulateOnZone=v;self:PlannerChanged();self:RefreshEventPlanner()end);y=y+38
    end
    UI.check(parent,'status','Open Status Panel on Run',m.behavior.openStatusPanelOnRun==true,8,y,w-16,function(v)m.behavior.openStatusPanelOnRun=v;self:PlannerChanged()end);y=y+38
    local sounds=self:GetUsefulSoundOptions();UI.label(parent,'soundLabel','Notify Sound',8,y,w-16,25)
    UI.combo(parent,'sound',sounds,nil,m.behavior.populateSound or 'DUEL_START',8,y+28,w-16,function(v)m.behavior.populateSound=v;self:PlannerChanged()end);return y+80
end
function S:RefreshPlannerPeriodSummary()
    if self.plannerPeriods then self:RefreshPlannerPeriods(self.plannerPeriods,self.plannerPeriods:GetWidth(),self.plannerPeriods:GetHeight()) end
end
function S:PlannerTestMessage(id)
    local output,ctx=self:PreviewPlannerMessage(self.plannerModel,id)
    if not output then self:PlannerError(ctx);return end
    local period=self:GetPlannerPeriod(self.plannerModel)
    self:AddLocalChatMessage('[SmartChatMsg] Message test — '..(self.plannerModel.runAt=='SCHEDULED' and (period and period.label or 'Period') or 'Current time')..(ctx and ' — '..self:FormatScheduleDateTime(ctx.now,ctx.schedule) or ''))
    self:AddLocalChatMessage(output);self.plannerPreviewText=output
    if self.plannerPreview then self.plannerPreview:SetText(output) end
end
function S:BuildPlannerMessagePool(parent,w,y)
    local m=self.plannerModel;local r=self:GetPlannerPeriod(m)
    local count=0;for _,entry in ipairs(m.messages)do if m.runAt=='SCHEDULED' and r and has(r.messageIds,entry.id) or m.runAt~='SCHEDULED' and not (m.behavior.disabledMessageIds or {})[entry.id]then count=count+1 end end
    UI.label(parent,'poolTitle',m.runAt=='SCHEDULED' and 'Messages for this period' or 'Messages in the random pool',8,y,w-16,28,true);y=y+30
    UI.label(parent,'poolCount',count..' selected — one is chosen at random',8,y,w-16,26);y=y+30
    if #m.messages==0 then UI.label(parent,'emptyPool','Create at least one message in Message library, then select it here.',8,y,w-16,60);return y+68 end
    for _,entry in ipairs(m.messages)do
        local id=entry.id;local selected=m.runAt=='SCHEDULED' and r and has(r.messageIds,id) or m.runAt~='SCHEDULED' and not (m.behavior.disabledMessageIds or {})[id]
        local card=UI.box(parent,'pool'..id,8,y,w-16,126,false)
        UI.check(card,'selected',entry.name or 'Unnamed message',selected,8,6,w-132,function(v)
            if m.runAt=='SCHEDULED' then self:SetPlannerMessageSelected(m,id,v)else m.behavior.disabledMessageIds=m.behavior.disabledMessageIds or {};m.behavior.disabledMessageIds[id]=not v or nil end
            self:PlannerChanged();self:RefreshEventPlanner()
        end,'Only checked messages are eligible for random selection in this pool.')
        UI.button(card,'test','Test',w-110,8,76,function()self:PlannerTestMessage(id)end)
        local text=UI.label(card,'text',entry.text,14,40,w-54,10000)
        local textHeight=math.max(40,text:GetTextHeight());text:SetHeight(textHeight);card:SetHeight(textHeight+52)
        UI.tooltip(text,entry.text..'\n\nClick Test to render substitutions in the selected period.')
        y=y+textHeight+62
    end
    return y
end
function S:BuildPlannerPeriodEditor(parent,w)
    local m=self.plannerModel;local r=self:GetPlannerPeriod(m)
    if not r then UI.label(parent,'empty','Choose a period from the middle column.',8,12,w-16,60);return 90 end
    local y=12;UI.label(parent,'periodLabel','Period Label',8,y,w-16,25)
    UI.edit(parent,'label',r.label,8,y+28,w-16,34,function(v)r.label=v;self:PlannerChanged();self:RefreshPlannerPeriodSummary()end);y=y+76
    UI.check(parent,'enabled','Enabled',r.enabled~=false and not r.paused,8,y,160,function(v)r.enabled=v;r.paused=false;self:PlannerChanged();self:RefreshEventPlanner()end)
    UI.button(parent,'remove','Remove period',w-174,y,166,function()local ok,error=self:RemovePlannerPeriod(m);if ok then self:RefreshEventPlanner()else self:PlannerError(error)end end);y=y+44
    local half=math.floor((w-28)/2)
    for i,key in ipairs({'start','finish'})do
        if key=='start' or not r.once or r.onceUntilFinish then
            local x=8+(i-1)*(half+12);local date,time=self:GetPlannerBoundary(m,key)
            UI.label(parent,key..'label',key=='start' and 'Period Starts' or 'Period Stops',x,y,half,25)
            local function set(dateValue,timeValue)local ok,error=self:SetPlannerBoundary(m,key,dateValue,timeValue);if ok then self:PlannerChanged();self:SortPlannerPeriods(m);self:RefreshEventPlanner()else self:PlannerError(error)end end
            UI.date(parent,key..'Date',date,x,y+28,half,function(v)set(v,time)end)
            UI.clock(parent,key..'Time',time,x,y+70,half,function(v)set(date,v)end,m.schedule.timeZone)
        end
    end;y=y+118
    UI.check(parent,'once','Send once',r.once==true,8,y,170,function(v)r.once=v;self:PlannerChanged();self:RefreshEventPlanner()end,'One confirmed announcement per event occurrence. Preparing or timing out does not complete it.')
    UI.check(parent,'sensitive','Time-sensitive',r.timeSensitive==true,190,y,210,function(v)r.timeSensitive=v;self:PlannerChanged();self:RefreshEventPlanner()end,'May bypass ordinary spacing between scheduled commands. Startup delay and your chat text remain protected.');y=y+38
    if r.once then
        UI.check(parent,'onceWindow','Send once anytime in this period',r.onceUntilFinish==true,8,y,w-16,function(v)r.onceUntilFinish=v;self:PlannerChanged();self:RefreshEventPlanner()end);y=y+38
        self:PlannerNumber(parent,'late','Late allowance',r.lateMinutes or 5,1,60,8,y,w-16,function(v)r.lateMinutes=v end);y=y+66
    else self:PlannerNumber(parent,'frequency','Repeat Frequency',r.intervalMinutes or 30,1,1440,8,y,w-16,function(v)r.intervalMinutes=v;self:RefreshPlannerPeriodSummary()end);y=y+66 end
    local duration=tonumber(m.schedule.eventDurationMinutes) or 0
    UI.label(parent,'endCap',duration>0 and ('Underway promotion stops at the event end ('..self:FormatSchedulingMinutes(duration)..' after start), unless the closing exception below is enabled.') or 'Set Event duration in Event settings to allow underway invitations after the event starts.',8,y,w-16,56);y=y+62
    UI.check(parent,'closing','Allow a closing announcement after the event ends',r.allowAfterEventEnd==true,8,y,w-16,function(v)r.allowAfterEventEnd=v;self:PlannerChanged();self:RefreshEventPlanner()end,'Use only for a brief closing notice. Keep its finish/grace short; ordinary underway invitations should stop at the event end.');y=y+38
    local a=r.availability or {}
    local dailyValue=m.schedule.dailyLimitShared and (m.schedule.sharedDailyLimit or 0) or (a.maxPerDay or 0)
    UI.slider(parent,'daily','Daily announcement limit',dailyValue,0,math.max(20,dailyValue),8,y,w-16,function(v)
        if m.schedule.dailyLimitShared then m.schedule.sharedDailyLimit=v>0 and v or nil
        else r.availability=r.availability or {enabled=false,startMinute=0,endMinute=1440};r.availability.maxPerDay=v>0 and v or nil end
        self:PlannerChanged()
    end,function(v)return v==0 and 'Unlimited' or v..' per day'end,'Confirmed sends and matching announcements from other players count. Preparing does not. By default the limit is for this period only.');y=y+66
    UI.check(parent,'shared','Share Limit to ALL periods',m.schedule.dailyLimitShared==true,8,y,w-16,function(v)m.schedule.dailyLimitShared=v;if v then m.schedule.sharedDailyLimit=(r.availability or {}).maxPerDay end;self:PlannerChanged();self:RefreshEventPlanner()end,'Unchecked: this period has its own daily limit. Checked: all periods for this command and guild share one limit.');y=y+38
    UI.check(parent,'availability','Limit eligible days and hours',a.enabled==true,8,y,w-16,function(v)r.availability=r.availability or {startMinute=0,endMinute=1440};r.availability.enabled=v;self:PlannerChanged();self:RefreshEventPlanner()end);y=y+38
    if a.enabled then
        for day,label in ipairs({'Sun','Mon','Tue','Wed','Thu','Fri','Sat'})do local index=day
            UI.check(parent,'weekday'..day,label,a.weekdays==nil or a.weekdays[day]==true,8+(day-1)*(w-16)/7,y,(w-16)/7,function(v)
                if not a.weekdays then a.weekdays={};for d=1,7 do a.weekdays[d]=true end end;a.weekdays[index]=v or nil;self:PlannerChanged();self:RefreshEventPlanner()
            end)
        end;y=y+38
        UI.label(parent,'fromLabel','From',8,y,half,25);UI.label(parent,'untilLabel','Until',half+20,y,half,25)
        UI.clock(parent,'fromClock',clockMinute(a.startMinute or 0),8,y+28,half,function(v)a.startMinute=minuteClock(v);self:PlannerChanged();self:RefreshEventPlanner()end,m.schedule.timeZone)
        UI.clock(parent,'untilClock',clockMinute((a.endMinute or 1440)%1440),half+20,y+28,half,function(v)local n=minuteClock(v);a.endMinute=n==0 and 1440 or n;self:PlannerChanged();self:RefreshEventPlanner()end,m.schedule.timeZone);y=y+72
        UI.label(parent,'overrideHint','Existing date and weekday overrides are retained. Edit those in Existing settings.',8,y,w-16,48);y=y+52
    end
    y=self:BuildPlannerMessagePool(parent,w,y+8)
    UI.button(parent,'library','Edit message library',8,y,w-16,function()m.tab='library';self:RefreshEventPlanner()end);return y+46
end
function S:BuildPlannerLibrary(parent,w)
    local m=self.plannerModel;UI.button(parent,'add','+ Message',8,12,w-16,function()self:AddPlannerMessage(m);self:PlannerChanged();self:RefreshEventPlanner()end)
    local y=58
    for index,entry in ipairs(m.messages)do
        local id=entry.id;local card=UI.box(parent,'message'..id,8,y,w-16,290,m.messageId==id)
        local disabled=m.runAt~='SCHEDULED' and (m.behavior.disabledMessageIds or {})[id]
        UI.label(card,'title',(entry.name or 'Message '..index)..(disabled and ' (disabled)' or ''),12,8,w-48,28,true)
        UI.edit(card,'name',entry.name or '',12,42,w-48,32,function(v)entry.name=v;self:PlannerChanged()end,false,'Optional name, up to 60 characters. It is never sent to chat.')
        UI.edit(card,'text',entry.text,12,84,w-48,122,function(v)
            entry.text=v;self:PlannerChanged();card.plannerControls.count:SetText(tostring(self:CountMessageCharacters(v))..'/350')
        end,true)
        local counter=UI.label(card,'count',tostring(self:CountMessageCharacters(entry.text or ''))..'/350',12,209,w-48,25);counter:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
        UI.button(card,'test','Test',12,245,100,function()self:PlannerTestMessage(id)end)
        UI.button(card,'delete','Remove',122,245,100,function()self:RemovePlannerMessage(m,id);self:PlannerChanged();self:RefreshEventPlanner()end)
        if m.runAt~='SCHEDULED' then UI.check(card,'pool','Enabled in pool',not disabled,234,247,w-280,function(v)m.behavior.disabledMessageIds=m.behavior.disabledMessageIds or {};m.behavior.disabledMessageIds[id]=not v or nil;self:PlannerChanged();self:RefreshEventPlanner()end)end
        y=y+302
    end
    if m.runAt~='SCHEDULED' then y=self:BuildPlannerMessagePool(parent,w,y) end
    return y
end
function S:RefreshEventPlanner()
    local win,m=self.plannerWindow,self.plannerModel
    if not win or not m or self.plannerRefreshing then return end
    self.plannerRefreshing=true
    local previewKey=tostring(m.commandId)..':'..m.guild..':'..tostring(m.periodId)..':'..m.runAt
    if self.plannerPreviewKey~=previewKey then self.plannerPreviewText=nil;self.plannerPreviewKey=previewKey end
    local width,height=win:GetWidth(),win:GetHeight();UI.hide(win)
    UI.box(win,'background',0,0,width,height,false)
    local title=UI.label(win,'title','SMARTCHATMSG — Event planner',18,12,width-380,38,true)
    title:SetMouseEnabled(true)
    title:SetHandler('OnMouseDown',function(_,button)if button==MOUSE_BUTTON_INDEX_LEFT then win:StartMoving()end end)
    title:SetHandler('OnMouseUp',function()win:StopMovingOrResizing();self:SavePlannerWindowGeometry()end)
    UI.label(win,'sending','Scheduled sending: '..(self:IsScheduledSendingEnabled() and 'ON' or 'OFF'),width-340,16,290,30)
    UI.button(win,'close','X',width-48,10,30,function()self:RequestPlannerAction(function()self.plannerModel=nil;self:HidePlannerWindow()end)end)
    UI.label(win,'guildLabel','Guild',18,58,50,28)
    local guilds={};for i=1,5 do local g=self:GetGuildNameByIndex(i);if g then guilds[#guilds+1]=g end end
    UI.combo(win,'guild',guilds,nil,m.guild,72,56,250,function(v)self:RequestPlannerAction(function()self.plannerModel=self:CreatePlannerDraft(m.commandId,v);self:RefreshEventPlanner()end)end)
    UI.label(win,'channelLabel','Output',346,58,70,28)
    UI.combo(win,'channel',{'Guild','Officer','Zone','Group'},nil,m.channel,414,56,180,function(v)m.channel=v;self:PlannerChanged()end)
    UI.label(win,'zone','Server clock: '..self:GetSchedulingTimeZoneName(m.schedule.timeZone)..' ('..m.schedule.timeZone..')',620,58,width-650,28)
    local left=math.max(210,math.floor(width*0.20));local middle=math.max(260,math.floor(width*0.23));local top=102;local bodyHeight=height-172
    local events=UI.box(win,'eventsPane',12,top,left,bodyHeight,false);self.plannerEvents=events;self:RefreshPlannerEvents(events,left,bodyHeight)
    local periods=UI.box(win,'periodPane',24+left,top,middle,bodyHeight,false);self.plannerPeriods=periods;self:RefreshPlannerPeriods(periods,middle,bodyHeight)
    local rightX=36+left+middle;local rightW=width-rightX-12
    local detail=UI.box(win,'detailPane',rightX,top,rightW,bodyHeight,false);UI.hide(detail);detail.plannerControls.bg:SetHidden(false)
    local tabs=m.runAt=='SCHEDULED' and {{'Event settings','event'},{'Period settings','period'},{'Message library','library'}} or {{'Command settings','event'},{'Message library','library'}}
    if m.runAt~='SCHEDULED' and m.tab=='period' then m.tab='event' end
    local tabWidth=math.floor((rightW-24)/#tabs)
    for i,t in ipairs(tabs)do local tab=t[2];UI.button(detail,'tab'..tab,t[1],12+(i-1)*tabWidth,12,tabWidth-4,function()m.tab=tab;self:RefreshEventPlanner()end,m.tab==tab)end
    local scroll,child,cw=UI.scroll(detail,'editor',6,54,rightW-12,bodyHeight-226);UI.hide(child)
    local endY
    if m.tab=='event' then endY=self:BuildPlannerEventEditor(child,cw)elseif m.tab=='library' then endY=self:BuildPlannerLibrary(child,cw)else endY=self:BuildPlannerPeriodEditor(child,cw)end
    UI.scrollEnd(scroll,child,endY+12)
    local preview=UI.box(detail,'preview',12,bodyHeight-160,rightW-24,148,false)
    UI.label(preview,'title','Preview — '..(m.runAt=='SCHEDULED' and 'during selected period' or 'current time'),10,5,rightW-50,25,true)
    self.plannerPreview=UI.label(preview,'output',self.plannerPreviewText or 'Click Test beside a message to preview substitutions here and in your chat.',10,34,rightW-50,108)
    self.plannerPreview:SetFont('ZoFontGameSmall')
    self.plannerFooter=UI.label(win,'footer',m.dirty and 'Unsaved changes — Save changes applies this event; Cancel discards edits.' or 'Same saved data as the existing addon settings.',18,height-53,width-350,44)
    UI.button(win,'cancel','Cancel',width-314,height-52,130,function()self:RequestPlannerAction(function()self.plannerModel=nil;self:HidePlannerWindow()end)end)
    self.plannerSave=UI.button(win,'save','Save changes',width-170,height-52,150,function()
        local ok,error=self:SavePlannerDraft(self.plannerModel)
        if not ok then self:PlannerError(error);return end
        self:RefreshEventPlanner();self.plannerFooter:SetText('Saved. The addon is using these settings.');self:AddLocalChatMessage('[SmartChatMsg] '..self.plannerModel.guild..' ('..self.plannerModel.name..'): settings saved.')
    end,true)
    self.plannerRefreshing=false
end
