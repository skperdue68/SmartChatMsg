local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
local tests={}
local function test(name,fn) tests[#tests+1]={name,fn} end
local function setup()
    f.reset();s.repeatPanelPaused={}
    CHAT_SYSTEM.messages={};function CHAT_SYSTEM:AddMessage(t) self.messages[#self.messages+1]=t end
    f.entry('a','ad','Amber Traders','A scheduled message','Guild')
    assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='WINDOW',enabled=true,delivery='REPEAT',
        startDate='2026-10-08',startTime='08:00 PM',endDate='2026-10-08',endTime='09:00 PM',intervalMinutes=5}))
    now=s:GetGuildSchedule('ad','Amber Traders').startsAtUtc
end
test('scheduled toggle cycles Off On Paused Off with Enable Pause Disable buttons',function()
    setup();local c=s:GetGuildSchedule('ad','Amber Traders');c.enabled=false
    local function row(state,label)
        local rows=s:GetRepeatStatusPanelRows();eq(#rows,1)
        eq(rows[1].controlState,state);eq(rows[1].toggleText,label)
    end
    row('OFF','Enable');s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders')
    row('ON','Pause')
    assert(s.pendingRestoreState,'On must prepare eligible scheduled text')
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');row('PAUSED','Disable')
    eq(s.pendingRestoreState,nil);s:TickSchedules();eq(s.pendingRestoreState,nil)
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');row('OFF','Enable')
    s:TickSchedules();eq(s.pendingRestoreState,nil)
end)
test('rows exist only inside the occurrence, even when off or paused',function()
    setup();local c=s:GetGuildSchedule('ad','Amber Traders')
    now=c.startsAtUtc-1;eq(#s:GetRepeatStatusPanelRows(),0)
    now=c.startsAtUtc;c.enabled=false;eq(#s:GetRepeatStatusPanelRows(),1)
    c.paused=true;assert(s:GetRepeatStatusPanelRows()[1].statusText:find('Paused',1,true)==1)
    now=c.endsAtUtc;eq(#s:GetRepeatStatusPanelRows(),0)
end)
test('active cards show actual startup delay, shared spacing, cooldown and ready state',function()
    setup();s.scheduleStartupEndsAt=now+180
    assert(s:GetRepeatStatusPanelRows()[1].statusText:find('Startup delay',1,true))
    s.scheduleStartupEndsAt=nil;s.scheduledSendPause={senderKey='other::amber traders',endsAt=now+300}
    assert(s:GetRepeatStatusPanelRows()[1].statusText:find('5-minute pause',1,true))
    s.scheduledSendPause=nil;s:GetGuildSchedule('ad','Amber Traders').nextDueAt=now+100
    local c=s:GetGuildSchedule('ad','Amber Traders');c.nextDuePhase=s:GetSchedulePhase(c,now)
    c.nextDueOccurrence=s:GetScheduleOccurrence(c,now).occurrenceKey
    assert(s:GetRepeatStatusPanelRows()[1].statusText:find('Cooldown',1,true))
    c.nextDueAt=nil;assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:ProcessChatPopulationQueue()
    assert(s:GetRepeatStatusPanelRows()[1].statusText:find('press Enter',1,true))
end)
test('cooldown reset clears usage, peer, zone, retry and once deadlines without changing schedule state',function()
    setup();local c=s:GetGuildSchedule('ad','Amber Traders');c.paused=true
    local settings=s:GetCommandGuildSettings('ad','Amber Traders',true)
    settings.lastUsedAt=now;settings.lastUsedParamText='1';settings.lastAutoPopulateSentAtByZone={['41']=now}
    settings.observedChatCooldowns={['*']={at=now,delaySeconds=60}}
    c.nextDueAt=now+100;c.completedOccurrences={test=true}
    s.scheduledSendPause={senderKey='other',endsAt=now+300};s.scheduleStartupEndsAt=now+180
    local date=c.startsAtUtc;s:ResetAllCooldowns()
    eq(c.startsAtUtc,date);eq(c.paused,true);eq(c.enabled,true);eq(c.intervalMinutes,5)
    eq(settings.lastUsedAt,nil);eq(settings.lastUsedParamText,'1')
    eq(next(settings.lastAutoPopulateSentAtByZone),nil);eq(next(settings.observedChatCooldowns),nil)
    eq(c.nextDueAt,nil);eq(next(c.completedOccurrences),nil);eq(s.scheduledSendPause,nil)
    eq(s.scheduleStartupEndsAt,now+180);eq(s.pendingRestoreState,nil)
end)
test('pause preserves player edits and can resume without a duplicate unsent buffer',function()
    setup();s:TickSchedules();assert(s.pendingRestoreState)
    CHAT_SYSTEM:GetEditControl():SetText('My edited message')
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders')
    eq(CHAT_SYSTEM:GetEditControl():GetText(),'My edited message');eq(s.pendingRestoreState,nil)
    assert(s:GetRepeatStatusPanelRows()[1].statusText:find('Paused',1,true)==1)
end)
test('all four card lines fit inside the backdrop with padding',function()
    setup();TOPLEFT='TOPLEFT';BOTTOMLEFT='BOTTOMLEFT';TOPRIGHT='TOPRIGHT'
    local function control()
        local c={top=0,height=0}
        function c:SetDimensions(w,h) self.width,self.height=w,h end
        function c:SetWidth(w) self.width=w end
        function c:SetHeight(h) self.height=h end
        function c:GetText() return '' end
        function c:IsHidden() return false end
        function c:SetAnchor(_,relative,point,_,y)
            self.top=(relative.top or 0)+(point==BOTTOMLEFT and relative.height or 0)+(y or 0)
        end
        return setmetatable(c,{__index=function() return function() end end})
    end
    local panel={rows={},repeatRows={}}
    for _,name in ipairs({'dragBar','titleLabel','divider','listHeader','currentLabel','footerLabel',
        'repeatDivider','repeatHeader','repeatScroll','repeatEmptyLabel','statusLabel','commandLabel',
        'guildLabel','channelLabel','repeatScrollChild'}) do panel[name]=control() end
    for i=1,2 do
        local row=control()
        for _,name in ipairs({'backdrop','toggleButton','commandLabel','statusLabel','detailsLabel','timingLabel'}) do row[name]=control() end
        panel.repeatRows[i]=row
    end
    s:ApplyStatusPanelLayout(panel,640)
    for _,row in ipairs(panel.repeatRows) do
        assert(row.commandLabel.top>=row.top+8)
        assert(row.timingLabel.top+row.timingLabel.height<=row.top+row.height-8,'timing line must be inside card')
    end
    assert(panel.repeatRows[2].top>panel.repeatRows[1].top+panel.repeatRows[1].height,'cards must not overlap')
end)
test('ordinary repeat controls cycle and stop queued work',function()
    setup();s:SetGuildRunAt('ad','Amber Traders','ON_DEMAND');s:SetGuildReminderMinutes('ad','Amber Traders',5)
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');eq(s:GetReminderPanelControlState('ad','Amber Traders'),'ON')
    assert(s.pendingRestoreState)
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');eq(s.pendingRestoreState,nil)
    eq(s:GetReminderPanelControlState('ad','Amber Traders'),'PAUSED')
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');eq(s:GetReminderPanelControlState('ad','Amber Traders'),'OFF')
end)
test('prepared and expired unsent messages produce visible local notices',function()
    setup();s:TickSchedules()
    assert(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]:find('Press Enter',1,true))
    local timer=assert(EVENT_MANAGER.updates[s.restoreWatcherTimeoutName]);timer.callback()
    assert(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]:find('was not sent',1,true))
    eq(s:GetGuildLastUsedAt('ad','Amber Traders'),nil)
    assert(s:GetGuildSchedule('ad','Amber Traders').nextDueAt>now)
end)
test('reset re-arms an active schedule and protects typed text',function()
    setup();local c=s:GetGuildSchedule('ad','Amber Traders')
    c.nextDueAt=now+100;c.nextDuePhase=s:GetSchedulePhase(c,now);c.nextDueOccurrence=s:GetScheduleOccurrence(c,now).occurrenceKey
    CHAT_SYSTEM:GetEditControl():SetText('My draft')
    s:ResetAllCooldowns();eq(s.pendingRestoreState,nil);eq(CHAT_SYSTEM:GetEditControl():GetText(),'My draft')
    CHAT_SYSTEM:GetEditControl():SetText('');s:TickSchedules();assert(s.pendingRestoreState)
end)
test('panel cannot enable a second scheduled Zone owner',function()
    setup();local c=s:GetGuildSchedule('ad','Amber Traders');c.delivery='ZONE';c.enabled=false
    f.entry('z','other','Blue Traders','Other zone message')
    assert(s:SaveGuildSchedule('other','Blue Traders',{mode='WINDOW',enabled=true,delivery='ZONE',
        startDate='2026-10-08',startTime='08:00 PM',endDate='2026-10-08',endTime='09:00 PM',intervalMinutes=5}))
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders')
    eq(c.enabled,false);eq(c.paused,false)
    assert(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]:find('Only one enabled',1,true))
end)
test('paused state survives settings import and always disables next',function()
    setup()
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders')
    ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
    local export=s:BuildExportString();assert(s:ImportSettingsFromString(export))
    local state,nextState=s:GetReminderPanelControlState('ad','Amber Traders');eq(state,'PAUSED');eq(nextState,'OFF')
end)
local failures=0
for _,t in ipairs(tests) do local ok,err=pcall(t[2]);if ok then print('PASS '..t[1]) else failures=failures+1;print('FAIL '..t[1]..': '..tostring(err)) end end
assert(failures==0,tostring(failures)..' status tests failed')
