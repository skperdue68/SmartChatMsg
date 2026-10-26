SmartChatMsg = SmartChatMsg or {}
local S=SmartChatMsg
local function copy(v) if type(v)~='table' then return v end local r={} for k,x in pairs(v) do r[k]=copy(x) end return r end
local function includes(t,id) for _,v in ipairs(t or {}) do if v==id then return true end end return false end
local function dirty(self) self.scheduleEditor.dirty=true;self:RefreshSettingsUI() end
function S:GetSelectedTimelineReminder()
 local d=self:GetScheduleEditorDraft()
 for _,r in ipairs(d.reminders or {}) do if r.id==self.scheduleEditor.reminderId then return r end end
 local r=(d.reminders or {})[1];self.scheduleEditor.reminderId=r and r.id;return r
end
function S:AddTimelineReminder()
 local d=self:GetScheduleEditorDraft();d.reminders=d.reminders or {}
 if #d.reminders>=100 then return nil end
 local ids={} for _,r in ipairs(d.reminders) do ids[r.id]=true end
 local base=self:GenerateUuid();local id=base;local suffix=1
 while ids[id] do suffix=suffix+1;id=base..'-'..suffix end
 local r={id=id,label='New reminder',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=15,lateMinutes=5,once=false,timeSensitive=false,messageIds={}}
 d.reminders[#d.reminders+1]=r;self.scheduleEditor.reminderId=id;dirty(self);return r
end
function S:RemoveTimelineReminder(id)
 local d=self:GetScheduleEditorDraft();if #(d.reminders or {})<=1 then return false end
 for i,r in ipairs(d.reminders) do if r.id==id then table.remove(d.reminders,i);self.scheduleEditor.reminderId=nil;dirty(self);return true end end
 return false
end
function S:AddTimelineImportantTime(label,minutes)
 local d=self:GetScheduleEditorDraft();d.importantTimes=d.importantTimes or {}
 local i=1;while d.importantTimes['time'..i] do i=i+1 end
 local id='time'..i;d.importantTimes[id]={label=label or 'Important time',offsetMinutes=minutes or -60};self.scheduleEditor.markId=id;dirty(self);return id
end
function S:RemoveTimelineImportantTime(id)
 local d=self:GetScheduleEditorDraft()
 for _,r in ipairs(d.reminders or {}) do for _,a in ipairs({r.start,r.finish}) do if a and a.kind=='MARK' and a.name==id then return false end end end
 if not (d.importantTimes or {})[id] then return false end
 d.importantTimes[id]=nil;self.scheduleEditor.markId=nil;dirty(self);return true
end
-- Shared by explicit single-event conversion and helper-command consolidation.
-- eventAtUtc is the chosen parent's true event; sourceEventAtUtc identifies the
-- aligned source occurrence (which may have used a technical helper time).
function S:BuildLegacyTimelineRows(config,command,guild,eventAtUtc,sourceEventAtUtc)
 local c,reason=self:NormalizeSchedule(config);if not c then return nil,reason end
 local sourceEvent=sourceEventAtUtc or c.eventAtUtc;local occurrence=self:BuildScheduleOccurrence(c,sourceEvent)
 if not occurrence then return nil,'The source occurrence cannot be resolved.' end
 local event=eventAtUtc or sourceEvent;local p=self:GetScheduleParts(sourceEvent,c)
 local midnight=self:ParseScheduleDateTime(string.format('%04d-%02d-%02d',p.year,p.month,p.day),'12:00 AM',nil,c)
 local soon=c.startingSoonEnabled and sourceEvent-c.startingSoonMinutes*60 or sourceEvent
 local ranges={}
 if c.mode=='EVENT' then
  ranges={{'BEFORE','Before event day',occurrence.startsAtUtc,math.min(midnight,soon)},{'DAY','On event day',math.max(occurrence.startsAtUtc,midnight),math.min(soon,sourceEvent)}}
  if c.startingSoonEnabled then ranges[#ranges+1]={'SOON','Starting soon',math.max(occurrence.startsAtUtc,soon),sourceEvent} end
  ranges[#ranges+1]={'LIVE','After event starts',sourceEvent,occurrence.endsAtUtc}
 else ranges={{'ANY',c.mode=='REMINDER' and 'One-time reminder' or 'While active',occurrence.startsAtUtc,occurrence.endsAtUtc}} end
 local parentDay=math.floor((event+self:GetTimeZoneUtcOffset(event,c.timeZone)*3600)/86400)
 local function civil(utc)
  local part=self:GetScheduleParts(utc,c)
  return {kind='DAY',days=math.floor((utc+self:GetTimeZoneUtcOffset(utc,c.timeZone)*3600)/86400)-parentDay,time=string.format('%02d:%02d %s',part.hour%12==0 and 12 or part.hour%12,part.min,part.hour>=12 and 'PM' or 'AM')}
 end
 local function anchor(utc,phase)
  if phase=='SOON' or phase=='LIVE' or c.mode=='EVENT' and (utc==sourceEvent or c.startingSoonEnabled and utc==soon) then return {kind='OFFSET',minutes=math.floor((utc-event)/60)} end
  return civil(utc)
 end
 local rows,ids={},{}
 for _,range in ipairs(ranges) do if range[4]>range[3] then
  local base=self:GenerateUuid();local id=base;local suffix=1;while ids[id] do suffix=suffix+1;id=base..'-'..suffix end;ids[id]=true
  local r={id=id,label=range[2],start=anchor(range[3],range[1]),finish=anchor(range[4],range[1]),messageIds={},timeSensitive=false,legacyPhase=range[1]}
  r.intervalMinutes=(c.phaseIntervals or {})[range[1]] or c.intervalMinutes or 15;r.once=(c.phaseOnce or {})[range[1]]==true
  if c.mode=='REMINDER' then r.once=true;r.lateMinutes=math.max(1,math.ceil((range[4]-range[3])/60)) else r.lateMinutes=math.min(1440,math.max(1,math.ceil((range[4]-range[3])/60)));r.onceUntilFinish=r.once end
  for _,m in ipairs(self:GetMessageEntriesForCommandAndGuild(command,guild)) do local a=(c.messagePhases or {})[m.id];if not a or a.ANY or a[range[1]] then r.messageIds[#r.messageIds+1]=m.id end end
  rows[#rows+1]=r
 end end
 return rows,copy(c.messageVariants or {})
end
-- Conversion is opt-in and retains the complete original configuration.
function S:ConvertScheduleDraftToTimeline()
 local d,command,guild=self:GetScheduleEditorDraft();if d.timelineVersion then return false,'This event already uses reminders.' end
 if d.mode~='EVENT' then return false,'Choose Promote an event first.' end
 local rows,variants=self:BuildLegacyTimelineRows(d,command,guild)
 if not rows then return false,variants end
 d.legacyTimelineBackup=copy(d);d.timelineVersion=1;d.importantTimes={};d.reminders=rows
 if #d.reminders==0 then self:AddTimelineReminder() end
 self.scheduleEditor.reminderId=d.reminders[1].id;dirty(self);return true
end
function S:GetTimelinePreviewContext(id)
 local c,reason=self:NormalizeSchedule(self:GetScheduleEditorDraft());if not c then return nil,reason end
 local occurrence=self:GetUpcomingScheduleOccurrences(c,GetTimeStamp(),1,true)[1] or self:BuildScheduleOccurrence(c,c.eventAtUtc)
 if not occurrence then return nil,'No event occurrence is available.' end
 for _,r in ipairs(c.reminders) do if r.id==id then
  local first,last=self:GetTimelineReminderWindow(c,occurrence,r)
  if not first or not last or last<=first then return nil,'This reminder is outside the event duration. Adjust its window or enable its explicit after-event exception.' end
  return {schedule=c,occurrence=occurrence,now=first+math.floor((last-first)/2),phase=r.id,reminderId=r.id}
 end end
 return nil,'Choose a reminder to test.'
end
local checklist=S.GetScheduleMessageChecklist
function S:GetScheduleMessageChecklist(phase)
 if phase~='TIMELINE' then return checklist(self,phase) end
 local r=self:GetSelectedTimelineReminder();if not r then return {} end
 local choices=checklist(self,'ANY')
 for _,choice in ipairs(choices) do
  local id=choice.messageId;local rowId=r.id
  choice.phaseText='Reminder: '..r.label
  choice.getFunc=function() for _,row in ipairs(self:GetScheduleEditorDraft().reminders or {}) do if row.id==rowId then return includes(row.messageIds,id) end end return false end
  choice.setFunc=function(value)
   for _,row in ipairs(self:GetScheduleEditorDraft().reminders or {}) do if row.id==rowId then
    local result={} for _,v in ipairs(row.messageIds or {}) do if v~=id then result[#result+1]=v end end
    if value then result[#result+1]=id end row.messageIds=result;dirty(self);return
   end end
  end
 end
 return choices
end
local context=S.GetMessagePreviewContext
function S:GetMessagePreviewContext(entry,phase)
 if phase=='TIMELINE' then local r=self:GetSelectedTimelineReminder();return self:GetTimelinePreviewContext(r and r.id) end
 return context(self,entry,phase)
end
local testMessage=S.TestMessagePreview
function S:TestMessagePreview(id,phase)
 if phase~='TIMELINE' then return testMessage(self,id,phase) end
 local r=self:GetSelectedTimelineReminder();local ctx,reason=self:GetTimelinePreviewContext(r and r.id)
 if not ctx then self:AddLocalChatMessage('[SmartChatMsg] Test unavailable: '..tostring(reason));return nil end
 for _,entry in ipairs(self.savedVars.messages or {}) do if entry.id==id then
  local text=self.settings and self.settings.GetEffectiveMessageText and self.settings:GetEffectiveMessageText(entry) or entry.text
  local output=self:ApplyMessageSubstitutions(text,entry.commandId,entry.guildName,ctx)
  self:AddLocalChatMessage('[SmartChatMsg] Message test — '..r.label..' — '..self:FormatScheduleDateTime(ctx.now,ctx.schedule));self:AddLocalChatMessage(output);return output,ctx
 end end
end
function S:DescribeTimelineAnchor(a,d)
 if not a then return 'Choose a time' end
 if a.kind=='MARK' then local m=(d.importantTimes or {})[a.name];return m and m.label or 'Choose an important time' end
 if a.kind=='DAY' then return tostring(a.days)..' calendar days from event at '..tostring(a.time) end
 local minutes=tonumber(a.minutes) or 0
 if minutes==0 then return 'Event starts' end
 local magnitude=math.abs(minutes);local amount=magnitude%1440==0 and tostring(magnitude/1440)..' days' or magnitude%60==0 and tostring(magnitude/60)..' hours' or tostring(magnitude)..' minutes'
 return amount..(minutes<0 and ' before event' or ' after event')
end
-- Native cards are bounded and scrollable; selecting a card edits one stable row.
function S:RefreshTimelineCards(control,marks)
 local d=self:GetScheduleEditorDraft();local width=math.max(240,control:GetWidth() or 520)
 if not control.timelineScroll then
  self.timelineControlSerial=(self.timelineControlSerial or 0)+1;control.timelineControlName='SCM_TimelineCards'..self.timelineControlSerial
  local scroll=WINDOW_MANAGER:CreateControlFromVirtual(control.timelineControlName,control,'ZO_ScrollContainer');scroll:SetAnchor(TOPLEFT,control,TOPLEFT,0,0);scroll:SetHeight(180)
  control.timelineScroll=scroll;control.timelineContent=scroll:GetNamedChild('Scroll'):GetNamedChild('Child');control.timelineContent:SetResizeToFitDescendents(false);control.timelineRows={}
  control:SetHandler('OnRectWidthChanged',function() self:RefreshTimelineCards(control,marks) end)
  control:SetHandler('OnEffectivelyShown',function() self:RefreshTimelineCards(control,marks) end)
 end
 local scroll,content=control.timelineScroll,control.timelineContent;scroll:SetWidth(width);content:SetWidth(width-28)
 for _,r in ipairs(control.timelineRows) do r:SetHidden(true) end
 local items={}
 if marks then for id,m in pairs(d.importantTimes or {}) do items[#items+1]={id=id,label=m.label,detail=tostring(m.offsetMinutes)..' minutes from event - token key: '..id} end table.sort(items,function(a,b) return a.id<b.id end)
 else for _,r in ipairs(d.reminders or {}) do items[#items+1]={id=r.id,label=r.label,detail=(r.paused and 'Paused' or r.enabled==false and 'Disabled' or 'Enabled')..' · '..self:DescribeTimelineAnchor(r.start,d)..(r.once and not r.onceUntilFinish and '' or ' → '..self:DescribeTimelineAnchor(r.finish,d))..'\n'..(r.once and (r.onceUntilFinish and 'Once within window' or 'Once') or 'Every '..tostring(r.intervalMinutes)..' minutes')..' · '..(r.timeSensitive and 'Time-sensitive' or 'Normal')..' · '..#(r.messageIds or {})..' messages'} end end
 local y=0
 for i,item in ipairs(items) do
  local card=control.timelineRows[i]
  if not card then
   local name=control.timelineControlName..'Card'..i
   card=WINDOW_MANAGER:CreateControl(name,content,CT_CONTROL);card:SetMouseEnabled(true)
   card.backdrop=WINDOW_MANAGER:CreateControlFromVirtual(name..'Backdrop',card,'ZO_DefaultBackdrop');card.backdrop:SetAnchorFill(card);card.backdrop:SetCenterColor(0.025,0.025,0.035,0.95);card.backdrop:SetEdgeColor(0.55,0.43,0.22,0.8)
   card.label=WINDOW_MANAGER:CreateControl(name..'Label',card,CT_LABEL);card.label:SetFont('ZoFontGame');card.label:SetAnchor(TOPLEFT,card,TOPLEFT,12,8);card.label:SetColor(0.95,0.82,0.45,1)
   local function wheel(_,delta) ZO_Scroll_OnMouseWheel(scroll,delta) end card:SetHandler('OnMouseWheel',wheel);card.label:SetMouseEnabled(true);card.label:SetHandler('OnMouseWheel',wheel)
   control.timelineRows[i]=card
  end
  card:SetHidden(false);card:SetWidth(width-28);card:ClearAnchors();card:SetAnchor(TOPLEFT,content,TOPLEFT,0,y);card.label:SetWidth(width-56);card.label:SetHeight(10000)
  local selected=marks and self.scheduleEditor.markId==item.id or not marks and self:GetSelectedTimelineReminder() and self:GetSelectedTimelineReminder().id==item.id
  card.label:SetText((selected and '|cE8C56ASelected · |r' or '')..item.label..'\n|cBDB8AA'..item.detail..'|r');local height=math.max(60,card.label:GetTextHeight()+16);card.label:SetHeight(height-16);card:SetHeight(height)
  local function choose(_,button,inside) if button==MOUSE_BUTTON_INDEX_LEFT and inside then if marks then self.scheduleEditor.markId=item.id else self.scheduleEditor.reminderId=item.id end self:RefreshSettingsUI() end end
  card:SetHandler('OnMouseUp',choose);card.label:SetHandler('OnMouseUp',choose);y=y+height+6
 end
 content:SetHeight(math.max(y,1));control:SetHeight(180);ZO_Scroll_UpdateScrollBar(scroll,true)
end
local build=S.BuildScheduleOptionControls
function S:BuildScheduleOptionControls()
 local controls=build(self)
 local function draft() return self:GetScheduleEditorDraft() end
 local function row() return self:GetSelectedTimelineReminder() end
 local function active() return draft().timelineVersion==1 end
 local function refresh() dirty(self) end
 -- Keep existing date picker, recurrence, rotation, previews and Save actions.
 for _,c in ipairs(controls) do
  local ref=c.reference or ''
  if ref=='SCM_EventTimingSubmenu' then for i=5,#c.controls do local old=c.controls[i].disabled;c.controls[i].disabled=function() return active() or old and old() end end end
  if ref:match('^SCM_Phase') or ref=='SCM_MessageDeliverySubmenu' then local old=c.disabled;c.disabled=function() return active() or old and old() end end
  if c.name=='Schedule type' then local old=c.disabled;c.disabled=function() return active() or old and old() end end
 end
 local function field(name,key,numeric)
  return {type='editbox',name=name,getFunc=function() return tostring(row() and row()[key] or '') end,setFunc=function(v) if row() then row()[key]=numeric and (tonumber(v) or v) or v;refresh() end end,disabled=function() return not active() or not row() end}
 end
 local function flag(name,key)
  return {type='checkbox',name=name,getFunc=function() return row() and row()[key]==true end,setFunc=function(v) if row() then row()[key]=v;refresh() end end,disabled=function() return not active() or not row() or key=='onceUntilFinish' and not row().once end}
 end
 local function selectedMark()
  local marks=draft().importantTimes or {};local id=self.scheduleEditor.markId
  if not marks[id] then for key in pairs(marks) do id=key;break end self.scheduleEditor.markId=id end
  return marks[id],id
 end
 local named={
  {type='description',text='Name a deadline such as Ticket sales close, then use it as a reminder start or end. Negative minutes are before the actual event; positive minutes are after.'},
  {type='custom',minHeight=180,maxHeight=180,createFunc=function(c) self:RefreshTimelineCards(c,true) end,refreshFunc=function(c) self:RefreshTimelineCards(c,true) end},
  {type='button',name='Add important time',func=function() self:AddTimelineImportantTime() end},
  {type='editbox',name='Important time name',getFunc=function() local m=selectedMark();return m and m.label or '' end,setFunc=function(v) local m=selectedMark();if m then m.label=v;refresh() end end},
  {type='description',text=function() local m,id=selectedMark();if not m then return 'Add an important time to see its message substitutions.' end return 'Message substitutions for '..m.label..': %eventwhen:'..id..'% - %eventdate:'..id..'% - %eventtime:'..id..'% - %eventcountdown:'..id..'%' end},
  {type='editbox',name='Important time minutes before / after event',getFunc=function() local m=selectedMark();return m and tostring(m.offsetMinutes) or '' end,setFunc=function(v) local m=selectedMark();if m then m.offsetMinutes=tonumber(v) or v;refresh() end end},
  {type='button',name='Remove important time',func=function() local _,id=selectedMark();if not self:RemoveTimelineImportantTime(id) then self:ShowStatusMessage('Choose another start or end for reminders using this important time before removing it.') end end},
 }
 local duration={type='editbox',name='Event duration (minutes, optional)',tooltip='Whole minutes from the actual event start to its end. Leave blank to retain only reminder windows. Invitations stop at event end; a one-time notice exactly on the end boundary retains its grace.',getFunc=function()return tostring(draft().eventDurationMinutes or '')end,setFunc=function(value)if value=='' then draft().eventDurationMinutes=nil else draft().eventDurationMinutes=tonumber(value) or value end;refresh()end}
 local rowState={type='dropdown',name='Reminder state',tooltip='Pause or disable only this period without deleting messages or cooldown history.',choices={'Enabled','Paused','Disabled'},getFunc=function()local r=row();return r and (r.paused and 'Paused' or r.enabled==false and 'Disabled' or 'Enabled') or 'Enabled'end,setFunc=function(value)local r=row();if r then r.enabled=value~='Disabled';r.paused=value=='Paused';refresh()end end}
 local pane={
  duration,
  {type='description',text='Keep the actual event date and time above. Add as many reminder periods or one-time milestones as you need. The latest active normal period wins an overlap; one-time milestones keep their own delivery. You always press Enter to send.'},
  {type='submenu',name='Important times',controls=named},
  {type='header',name='Reminders'},
  {type='custom',minHeight=180,maxHeight=180,createFunc=function(c) self:RefreshTimelineCards(c,false) end,refreshFunc=function(c) self:RefreshTimelineCards(c,false) end},
  {type='button',name='Add reminder',func=function() self:AddTimelineReminder() end},
  {type='button',name='Preview timeline',func=function()
   local c,reason=self:NormalizeSchedule(draft());if not c then self:ShowStatusMessage(reason);return end
   local occurrence=self:GetUpcomingScheduleOccurrences(c,GetTimeStamp(),1,true)[1] or self:BuildScheduleOccurrence(c,c.eventAtUtc)
   if not occurrence then self:ShowStatusMessage('No event occurrence is available.');return end
   self:AddLocalChatMessage('[SmartChatMsg] Event: '..self:FormatScheduleDateTime(occurrence.eventAtUtc,c))
   for _,r in ipairs(c.reminders) do local first=self:ResolveTimelineAnchor(c,occurrence,r.start);local last=(not r.once or r.onceUntilFinish) and self:ResolveTimelineAnchor(c,occurrence,r.finish)
    self:AddLocalChatMessage(r.label..': '..self:FormatScheduleDateTime(first,c)..(last and ' → '..self:FormatScheduleDateTime(last,c) or ' · Once')..' · '..(r.timeSensitive and 'Time-sensitive' or 'Normal'))
   end
  end},
  {type='header',name=function() local r=row();return 'Selected reminder / '..(r and r.label or 'Choose a reminder') end},
  field('Reminder name','label'),
 }
 local function append(c) pane[#pane+1]=c end
 for _,which in ipairs({'start','finish'}) do
  local key=which;local title=key=='start' and 'Start' or 'End';local suffix=key=='start' and 'start' or 'end'
  local function anchor() local r=row();return r and r[key] end
  append({type='dropdown',name=title..' time is based on',choices={'Minutes before / after event','Calendar day and local clock','An important time'},getFunc=function() local a=anchor();return a and ({OFFSET='Minutes before / after event',DAY='Calendar day and local clock',MARK='An important time'})[a.kind] or 'Minutes before / after event' end,setFunc=function(v) if not row() then return end if v=='Calendar day and local clock' then row()[key]={kind='DAY',days=-1,time='08:00 PM'} elseif v=='An important time' then local _,id=selectedMark();if not id then id=self:AddTimelineImportantTime() end row()[key]={kind='MARK',name=id} else row()[key]={kind='OFFSET',minutes=key=='start' and -60 or 0} end refresh() end,disabled=function() return not row() or key=='finish' and row().once and not row().onceUntilFinish end})
  local function anchorField(name,kind,member)
   append({type='editbox',name=name,getFunc=function() local a=anchor();return a and tostring(a[member] or '') or '' end,setFunc=function(v) local a=anchor();if a and a.kind==kind then a[member]=member=='time' and v or tonumber(v) or v;refresh() end end,disabled=function() local a=anchor();return not a or a.kind~=kind or key=='finish' and row().once and not row().onceUntilFinish end})
  end
  anchorField('Minutes before / after event ('..suffix..')','OFFSET','minutes')
  anchorField('Calendar days before / after event ('..suffix..')','DAY','days')
  anchorField('Local clock time ('..suffix..', for example 08:00 PM)','DAY','time')
  append({type='button',name='Use selected important time for '..suffix,tooltip='Select a card under Important times, then click here.',func=function() local _,id=selectedMark();if row() and id then row()[key]={kind='MARK',name=id};refresh() end end,disabled=function() return not row() or not selectedMark() or key=='finish' and row().once and not row().onceUntilFinish end})
  append({type='description',text=function() local a=anchor();local mark=a and a.kind=='MARK' and (draft().importantTimes or {})[a.name];return mark and title..': '..mark.label or '' end})
 end
 append(rowState);append(flag('Allow brief notice after event end (advanced)','allowAfterEventEnd'));append(flag('Prepare only once','once'));append(flag('Keep entire reminder window available until sent','onceUntilFinish'));append(field('Repeat every (minutes)','intervalMinutes',true));append(flag('Time-sensitive reminder','timeSensitive'))
 append({type='description',text='Time-sensitive reminders can bypass ordinary reminder pacing. Lateness allowance is the number of minutes a one-time reminder remains available. Offline or expired milestones are skipped.'})
 append(field('Lateness allowance (minutes)','lateMinutes',true))
 append({type='custom',minHeight=230,maxHeight=230,createFunc=function(c) self:RefreshScheduleMessagePool(c,'TIMELINE') end,refreshFunc=function(c) self:RefreshScheduleMessagePool(c,'TIMELINE') end})
 append({type='description',text='Check the messages this reminder may use. Click any message text to test it at a simulated time inside this reminder. Message group selectors support regular / month-final events and faction rotation.'})
 append({type='button',name='Remove selected reminder',func=function() local r=row();if r then self:RemoveTimelineReminder(r.id) end end,disabled=function() return #(draft().reminders or {})<=1 end})
 local combine={
  {type='description',text='Verify the true event date and time above, then save this event first. Explicitly choose other saved schedules from this guild to combine. This event’s actual date, time and repeat pattern remain authoritative. Messages retain their IDs and history; source schedules are backed up and disabled. Review Preview timeline after combining. Similar command names are never combined automatically.'},
 }
 for _,command in ipairs(self.savedVars.commands or {}) do
  local id=command.id
  combine[#combine+1]={type='checkbox',name=command.name or id,getFunc=function() draft();return (self.scheduleEditor.mergeSources or {})[id]==true end,setFunc=function(value) draft();self.scheduleEditor.mergeSources=self.scheduleEditor.mergeSources or {};self.scheduleEditor.mergeSources[id]=value;self:RefreshSettingsUI() end,disabled=function() local _,target,guild=self:GetScheduleEditorDraft();return target==id or not self:GetGuildSchedule(id,guild) end}
 end
 combine[#combine+1]={type='button',name='Combine selected schedules into this event',disabled=function() local _,target,guild=self:GetScheduleEditorDraft();return not active() or not self.MergeTimelineEvents or self.scheduleEditor.dirty or not self:GetGuildSchedule(target,guild) end,func=function()
  local _,target,guild=self:GetScheduleEditorDraft();local ids={}
  for id,chosen in pairs(self.scheduleEditor.mergeSources or {}) do if chosen and id~=target and self:GetGuildSchedule(id,guild) then ids[#ids+1]=id end end
  table.sort(ids);if #ids==0 then self:ShowStatusMessage('Select at least one source schedule.');return end
  local ok,reason=self:MergeTimelineEvents(target,guild,ids)
  self:ShowStatusMessage(ok and 'Schedules combined. Review this event and its reminders.' or reason or 'Could not combine schedules.')
  if ok then self.scheduleEditor=nil end self:RefreshSettingsUI()
 end}
 append({type='submenu',name='Combine other saved schedules',controls=combine})
 local conversion={type='button',name='Convert this event to reminder timeline',tooltip='Explicitly converts the existing phases into reminder rows, retaining message IDs, message groups and a backup of the original settings. Review the reminders before saving.',func=function() local ok,reason=self:ConvertScheduleDraftToTimeline();if not ok then self:ShowStatusMessage(reason) end end,disabled=function() return draft().mode~='EVENT' or active() end}
 -- Insert before the existing Save buttons so every edit participates in the
 -- same validation, disabled-save and activation workflow.
 local index=#controls+1;for i,c in ipairs(controls) do if c.name=='Save and activate' then index=i;break end end
 table.insert(controls,index,conversion);table.insert(controls,index+1,{type='submenu',reference='SCM_TimelineSubmenu',name='Event timeline',controls=pane,disabled=function() return not active() end})
 return controls
end
-- Message libraries show reminder membership rather than obsolete phase tags.
local phaseText=S.GetScheduleMessagePhaseText
function S:GetScheduleMessagePhaseText(messageId,schedule)
 if not schedule or schedule.timelineVersion~=1 then return phaseText(self,messageId,schedule) end
 local labels={}
 for _,row in ipairs(schedule.reminders or {}) do if includes(row.messageIds,messageId) then labels[#labels+1]=row.label end end
 local text=#labels>0 and table.concat(labels,' · ') or 'Not selected for any reminder'
 if schedule.specialPattern and schedule.specialPattern~='NONE' then text=text..' · '..self:GetScheduleVariantLabel(self:GetScheduleMessageVariant(schedule,messageId),schedule.specialPattern) end
 return text
end
local sortEntries=S.SortScheduledMessageEntries
function S:SortScheduledMessageEntries(entries,schedule)
 if not schedule or schedule.timelineVersion~=1 then return sortEntries(self,entries,schedule) end
 local ranks={};local occurrence=schedule.eventAtUtc and {eventAtUtc=schedule.eventAtUtc}
 for index,row in ipairs(schedule.reminders or {}) do
  local at=occurrence and self:ResolveTimelineAnchor(schedule,occurrence,row.start) or index
  for _,id in ipairs(row.messageIds or {}) do ranks[id]=math.min(ranks[id] or math.huge,at or index) end
 end
 local decorated={};for index,entry in ipairs(entries) do decorated[#decorated+1]={entry=entry,rank=ranks[entry.id] or math.huge,index=index} end
 table.sort(decorated,function(a,b)return a.rank==b.rank and a.index<b.index or a.rank<b.rank end)
 local result={};for _,item in ipairs(decorated) do result[#result+1]=item.entry end;return result
end
local expansion=S.RefreshEventTimingExpansion
function S:RefreshEventTimingExpansion()
 expansion(self)
 local draft=self:GetScheduleEditorDraft();local control=_G.SCM_TimelineSubmenu
 local key=self.scheduleEditor and self.scheduleEditor.key;local state=self.timelineExpansion
 local active=draft.timelineVersion==1
 if active and control and not control.disabled and (not state or not state.active or state.control~=control or state.key~=key) then
  if not control.open then control.open=true;control.animation:PlayFromStart() end
 end
 self.timelineExpansion={key=key,control=control,active=active}
end
