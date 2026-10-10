local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset()
f.entry('a','ad','Amber Traders','At %eventtime%','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-08',eventTime='09:00 PM',promotionDays=2,endDelayMinutes=20,intervalMinutes=5}))
local schedule=s:GetGuildSchedule('ad','Amber Traders')
now=schedule.eventAtUtc-3600
local row=s:GetRepeatStatusPanelRows()[1]
assert(row.displayName:find('(Scheduled)',1,true),row.displayName)
assert(row.displayName:find('Starts in 1:00:00',1,true),row.displayName)
now=schedule.eventAtUtc
assert(s:GetRepeatStatusPanelRows()[1].displayName:find('Started',1,true))
schedule.messagePhases={a={DAY=true,SOON=true}}
eq(s:GetScheduleMessagePhaseText('a',schedule),'Event day')
eq(s:GetScheduleMessagePhaseText('other',schedule),'Before event day · Event day · Until end')
schedule.startingSoonEnabled=true
eq(s:GetScheduleMessagePhaseText('a',schedule),'Event day · Starting soon')
assert(s:GetScheduleMessagePhaseText('other',schedule):find('Starting soon',1,true))
eq(s:GetScheduleMessagePhaseText('a',{mode='WINDOW'}),'While active')
f.reset();f.entry('a','ad','Amber Traders','At %eventtime%','Guild')
eq(s:ResolveScheduledEventTokens('At %eventtime%','ad','Amber Traders'),'At %eventtime%')
s:SetGuildReminderMinutes('ad','Amber Traders',5);s:RegisterDynamicCommands();SLASH_COMMANDS['/recruit']('1')
assert(s:GetRepeatStatusPanelRows()[1].displayName:find('(On Demand)',1,true))

-- A native-label mock reproduces the previous height constraining new text.
f.reset();f.entry('a','ad','Amber Traders',string.rep('A long message ',25),'Guild')
s.savedVars.selectedMessagesCommand='ad'
s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end
local function control(parent)
    local c={parent=parent,width=0,height=0,children={},handlers={}}
    function c:GetWidth() return self.width end
    function c:SetWidth(v) self.width=v end
    function c:SetHeight(v) self.height=v end
    function c:SetText(v) self.text=v end
    function c:GetTextHeight() return math.min(self.height,math.ceil(#(self.text or '')/math.max(1,math.floor(self.width/8)))*20) end
    function c:SetHandler(k,v) self.handlers[k]=v end
    function c:GetNamedChild(k) if not self.children[k] then self.children[k]=control(self);self.children[k].width=420 end;return self.children[k] end
    return setmetatable(c,{__index=function(_,key) if key:match('^Set') or key=='ClearAnchors' then return function() end end end})
end
WINDOW_MANAGER={CreateControl=function(_,_,p) return control(p) end,CreateControlFromVirtual=function(_,_,p) return control(p) end}
ZO_CheckButton_SetCheckState=function() end;ZO_CheckButton_SetToggleFunction=function() end
ZO_Scroll_ResetToTop=function() end;ZO_Scroll_UpdateScrollBar=function() end
local pool=control();pool.width=520
s:RefreshScheduleMessagePool(pool,'DAY')
local item=pool.scheduleRows[1]
assert(item.height>100,'long messages must be fully visible')
assert(item.backdrop,'checkbox and text should share a border')
assert(item.label.width<=420-50,'text must fit actual scroll viewport')
local first=item.height
pool.width=300;s:RefreshScheduleMessagePool(pool,'DAY')
assert(item.height>first,'narrower viewport must remeasure all lines')
print('message clarity checks passed')

local realPreview=s.TestMessagePreview
local tested
s.TestMessagePreview=function(_,id,phase) tested={id=id,phase=phase} end
MOUSE_BUTTON_INDEX_LEFT=1
item.label.handlers.OnMouseUp(item.label,1,true)
eq(tested.id,"a");eq(tested.phase,"DAY")
tested=nil
item.label.handlers.OnMouseUp(item.label,2,true)
eq(tested,nil,"right click must not run a test")
item.label.handlers.OnMouseUp(item.label,1,false)
eq(tested,nil,"release outside must not run a test")
print("phase message links test the displayed row without toggling selection")

-- Reproduce clicking the assigned Event day wording from the Before-event pool.
s.TestMessagePreview=realPreview
f.reset();f.entry('phase','ad','Amber Traders','Meet %eventwhen% at %eventtime%!','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-10-06',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=60,intervalMinutes=15,recurrence='WEEKLY',startingSoonEnabled=true,startingSoonMinutes=120}))
s.savedVars.selectedMessagesCommand='ad'
now=s:ParseEasternDateTime('2026-10-09','08:00 PM')
local notices={};s.AddLocalChatMessage=function(_,text) notices[#notices+1]=text end
local preview,context
s.TestMessagePreview=function(self,id,phase) preview,context=realPreview(self,id,phase);return preview,context end
s:RefreshScheduleMessagePool(pool,'BEFORE')
local row=pool.scheduleRows[1]
local dayLink
for _,link in ipairs(row.phaseLinks or {}) do if link.phase=='DAY' then dayLink=link end end
assert(dayLink,'assigned Event day must have its own preview link')
dayLink.handlers.OnMouseUp(dayLink,1,true)
eq(context.phase,'DAY','assigned Event day link cannot use containing BEFORE phase')
eq(s:GetSchedulePhase(context.schedule,context.now),'DAY')
assert(preview:find('today',1,true),preview)
assert(not preview:find('(1d)',1,true),preview)
assert(preview:find('08:00 PM',1,true),preview)
assert(notices[#notices-1]:find('Event day',1,true))
eq(s:GetScheduleParts(context.now,context.schedule).day,13,'preview must use next weekly event')
-- Message text still tests the containing phase; phase links never toggle usage.
row.label.handlers.OnMouseUp(row.label,1,true)
eq(context.phase,'BEFORE')
assert(preview:find('tomorrow',1,true),preview)
print('assigned phase links use their own simulated clock and recurring occurrence')

for _,link in ipairs(row.phaseLinks) do
 if link.phase then
  link.handlers.OnMouseUp(link,1,true)
  eq(context.phase,link.phase)
  eq(s:GetSchedulePhase(context.schedule,context.now),link.phase,'every link must pick a clock inside its own phase')
  assert(link.width<=row.label.width,'phase links must wrap within the message row')
 end
end
assert(row.height>=row.label.height+row.phaseLinkContainer.height+16,'message and phase links must fit inside their border')
assert(s:GetGuildSchedule('ad','Amber Traders').messagePhases.phase==nil,'testing links must not change message inclusion')
print('all assigned phase links stay inside their phase and row bounds')
