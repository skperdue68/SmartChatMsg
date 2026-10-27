local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset();f.entry('a','ad','Amber Traders','First announcement');f.entry('b','ad','Amber Traders','Second announcement')
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end;s.RefreshSettingsUI=function() end
local d=s:GetScheduleEditorDraft();d.mode='EVENT';d.eventDate='2026-10-16';d.eventTime='08:00 PM';d.startDate='2026-10-15';d.startTime='08:00 PM';d.endDate='2026-10-16';d.endTime='09:00 PM';d.messagePhases.a={BEFORE=true};d.messagePhases.b={LIVE=true}
eq(d.timelineVersion,1);d.reminders[1].messageIds={'a'}
local first=d.reminders[1];eq(first.messageIds[1],'a');assert(first.id)
local second=s:AddTimelineReminder();assert(second.id~=first.id);eq(s:GetSelectedTimelineReminder(),second)
local choices=s:GetScheduleMessageChecklist('TIMELINE');eq(#choices,2);choices[1].setFunc(true);eq(second.messageIds[1],'a');choices[1].setFunc(false);eq(#second.messageIds,0)
local id=s:AddTimelineImportantTime('Ticket sales close',-60);assert(d.importantTimes[id]);second.start={kind='MARK',name=id};assert(not s:RemoveTimelineImportantTime(id));second.start={kind='OFFSET',minutes=-60};assert(s:RemoveTimelineImportantTime(id))
second.messageIds={'a'};second.finish={kind='OFFSET',minutes=0};local ctx,reason=s:GetTimelinePreviewContext(second.id);assert(ctx,reason);eq(ctx.reminderId,second.id);assert(ctx.now>=ctx.occurrence.eventAtUtc-3600 and ctx.now<ctx.occurrence.eventAtUtc)
local function find(list,name) for _,c in ipairs(list) do if c.name==name then return c end;if c.controls then local v=find(c.controls,name);if v then return v end end end end
local controls=s:BuildScheduleOptionControls();assert(find(controls,'Period Timeline'));assert(find(controls,'Add period'));assert(find(controls,'Important times'));assert(find(controls,'Save and activate'));assert(find(controls,'Period Label'));assert(find(controls,'Period Starts date'))
find(controls,'Period Starts hour').setFunc('06');eq(second.start.time,'06:00 PM')
find(controls,'Send once').setFunc(true);eq(second.once,true)
find(controls,'Time-sensitive reminder').setFunc(true);eq(second.timeSensitive,true)
find(controls,'Period Label').setFunc('Tickets close');eq(second.label,'Tickets close')
assert(s:RemoveTimelineReminder(second.id));eq(s:GetSelectedTimelineReminder(),first)
print('PASS timeline editor conversion, stable rows, message selections, named-time references, simulated row preview and control callbacks')
-- Native reminder cards stay bounded, wrap, select by stable ID and expose wheel input.
local function native()
 local c={width=320}
 function c:GetWidth() return self.width end
 function c:SetWidth(v) self.width=v end
 function c:SetHeight(v) self.height=v end
 function c:SetText(v) self.text=v end
 function c:GetTextHeight() return math.ceil(#(self.text or '')/math.max(1,self.width/8))*20 end
 function c:GetNamedChild(k) self.children=self.children or {};self.children[k]=self.children[k] or native();return self.children[k] end
 function c:SetHandler(k,v) self[k]=v end
 function c:SetHidden(v) self.hidden=v end
 function c:SetAnchor(_,p,_,x,y) self.y=y end
 function c:ClearAnchors() end
 function c:SetFont() end
 function c:SetMouseEnabled() end
 function c:SetAnchorFill() end
 function c:SetCenterColor() end
 function c:SetEdgeColor() end
 function c:SetColor() end
 function c:SetResizeToFitDescendents() end
 return c
end
WINDOW_MANAGER={CreateControl=function() return native() end,CreateControlFromVirtual=function() return native() end}
function ZO_Scroll_UpdateScrollBar() end
function ZO_Scroll_OnMouseWheel(c,delta) c.offset=(c.offset or 0)-delta*40 end
MOUSE_BUTTON_INDEX_LEFT=1
local holder=native();first.label=string.rep('A reminder with a long readable title ',8)
s:RefreshTimelineCards(holder,false);eq(holder.height,180);assert(holder.timelineRows[1].height>=holder.timelineRows[1].label:GetTextHeight()+16)
local added=s:AddTimelineReminder();s:RefreshTimelineCards(holder,false);holder.timelineRows[1].OnMouseUp(nil,1,true);eq(s:GetSelectedTimelineReminder(),first)
holder.timelineRows[1].label.OnMouseWheel(nil,-1);eq(holder.timelineScroll.offset,40)
assert(holder.timelineRows[1].label.text:find('2026-',1,true));assert(holder.timelineRows[1].label.text:find('Normal',1,true))
-- Testing one row never changes the real clock, saved schedule or selected row.
local observed; s.AddLocalChatMessage=function(_,text) observed=text end
local before=GetTimeStamp();local output,testContext=s:TestMessagePreview('a','TIMELINE');assert(output and testContext);eq(GetTimeStamp(),before);eq(testContext.reminderId,first.id)
assert(not find(controls,'Combine selected schedules into this event'))
-- Legacy modes have no implicit conversion.
f.reset();s.savedVars.selectedMessagesCommand='ad';s.scheduleEditor=nil
local legacy=s:GetScheduleEditorDraft();eq(legacy.timelineVersion,1);assert(not find(controls,'Convert this event to reminder timeline'))
print('PASS native timeline cards, wrapped summaries, selection, wheel input and preview clock isolation')
-- Shared legacy migration keeps civil day boundaries across the DST change.
f.reset();f.entry('migration','ad','Amber Traders','Migration announcement');s.savedVars.selectedMessagesCommand='ad';s.scheduleEditor=nil
local legacyEvent={mode='EVENT',timeZone='ET',eventDate='2026-11-02',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=60,intervalMinutes=15,phaseOnce={BEFORE=true},messagePhases={migration={BEFORE=true}}}
local normalized=assert(s:NormalizeSchedule(legacyEvent));assert(s.BuildLegacyTimelineRows,'Shared conversion helper missing')
local migrated,variants=s:BuildLegacyTimelineRows(legacyEvent,'ad','Amber Traders',normalized.eventAtUtc)
assert(migrated,variants);eq(migrated[1].start.kind,'DAY');eq(migrated[1].start.days,-2);eq(migrated[1].start.time,'08:00 PM');eq(migrated[1].onceUntilFinish,true);eq(migrated[1].messageIds[1],'migration')
local window={mode='WINDOW',timeZone='ET',startDate='2026-11-01',startTime='08:00 AM',endDate='2026-11-01',endTime='09:00 PM',intervalMinutes=30}
local windows=assert(s:BuildLegacyTimelineRows(window,'ad','Amber Traders',normalized.eventAtUtc));eq(#windows,1);eq(windows[1].start.kind,'DAY');eq(windows[1].start.days,-1)
local reminder={mode='REMINDER',timeZone='ET',startDate='2026-11-02',startTime='07:00 PM',intervalMinutes=30}
local singles=assert(s:BuildLegacyTimelineRows(reminder,'ad','Amber Traders',normalized.eventAtUtc));eq(#singles,1);eq(singles[1].once,true);eq(singles[1].lateMinutes,2)
print('PASS shared legacy conversion for events, windows, reminders and full once windows')
