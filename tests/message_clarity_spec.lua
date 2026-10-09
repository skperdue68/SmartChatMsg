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
