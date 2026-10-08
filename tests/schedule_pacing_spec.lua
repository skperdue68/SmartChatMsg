local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
local tests={}
local function test(name,fn) tests[#tests+1]={name,fn} end
local function setup()
    f.reset()
    s.scheduleStartupEndsAt=nil;s.scheduledSendPause=nil;s.scheduleNoticeStates={}
    CHAT_SYSTEM.messages={}
    function CHAT_SYSTEM:AddMessage(text) self.messages[#self.messages+1]=text end
    for _,id in ipairs({'ad','other'}) do
        f.entry(id..'msg',id,'Amber Traders',id..' scheduled message','Guild')
        assert(s:SaveGuildSchedule(id,'Amber Traders',{mode='WINDOW',enabled=true,delivery='REPEAT',
            startDate='2026-10-08',startTime='08:00 PM',endDate='2026-10-08',endTime='09:00 PM',intervalMinutes=1}))
    end
    now=s:GetGuildSchedule('ad','Amber Traders').startsAtUtc
end
local function sent()
    local pending=assert(s.pendingRestoreState)
    local text=pending.rawExpectedText
    CHAT_SYSTEM:GetEditControl():SetText('')
    s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_GUILD_1,'My Character',text,false,'@Me')
end
test('startup holds automatic and manual scheduled delivery for exactly 180 seconds',function()
    setup();s:InitializeScheduler()
    eq(s.pendingRestoreState,nil)
    local ok,reason=s:RequestScheduledDelivery('ad','Amber Traders',true)
    eq(ok,false);assert(reason:find('Startup',1,true))
    assert(s:GetScheduleStatusText('ad','Amber Traders'):find('Startup',1,true))
    now=now+179;s:TickSchedules();eq(s.pendingRestoreState,nil)
    now=now+1;s:TickSchedules();assert(s.pendingRestoreState)
    local found=false
    for _,text in ipairs(CHAT_SYSTEM.messages) do if text:find('SmartChatMsg is running',1,true) then found=true end end
    assert(found,'startup announcement must appear in local chat')
end)
test('a confirmed scheduled send holds other schedules for 300 seconds, including queued work',function()
    setup()
    assert(s:RequestScheduledDelivery('ad','Amber Traders',true))
    assert(s:RequestScheduledDelivery('other','Amber Traders',true))
    s:ProcessChatPopulationQueue();sent()
    s:ProcessChatPopulationQueue();eq(s.pendingRestoreState,nil)
    assert(next(s.chatPopulationQueue),'other queued request must survive pause')
    local ok,reason=s:RequestScheduledDelivery('other','Amber Traders',true)
    eq(ok,false);assert(reason:find('5-minute',1,true))
    now=now+299;s:ProcessChatPopulationQueue();eq(s.pendingRestoreState,nil)
    now=now+1;s:ProcessChatPopulationQueue();assert(s.pendingRestoreState)
    eq(s.pendingRestoreState.metadata.commandId,'other')
end)
test('the sender keeps its own interval and timeout does not pause other activities',function()
    setup();assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:ProcessChatPopulationQueue();sent()
    now=now+60;assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:ProcessChatPopulationQueue()
    eq(s.pendingRestoreState.metadata.commandId,'ad')
    setup();assert(s:RequestScheduledDelivery('ad','Amber Traders',true));s:ProcessChatPopulationQueue()
    local timer=assert(EVENT_MANAGER.updates[s.restoreWatcherTimeoutName])
    timer.callback();eq(s.scheduledSendPause,nil)
    assert(s:RequestScheduledDelivery('other','Amber Traders',true));s:ProcessChatPopulationQueue()
    eq(s.pendingRestoreState.metadata.commandId,'other')
end)
test('local notices reach chat even with a center-screen announcer and debug disabled',function()
    setup();CENTER_SCREEN_ANNOUNCE={AddMessage=function() end}
    s:ShowStatusMessage('visible notice');eq(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages],'visible notice')
    local old=d;d=function() error('must not use d') end
    s:HandleScmDebugCommand('status');d=old
    assert(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]:find('Debug is',1,true))
    CENTER_SCREEN_ANNOUNCE=nil
end)
test('startup does not delay ordinary on-demand commands',function()
    setup();s:InitializeScheduler()
    s:SetGuildRunAt('ad','Amber Traders','ON_DEMAND')
    assert(s:PopulateChatBufferForCommand('ad','Amber Traders'))
    assert(s.pendingRestoreState)
    sent();eq(s.scheduledSendPause,nil)
end)
test('a queued reminder that expires during the pause is not delivered afterward',function()
    setup();assert(s:RequestScheduledDelivery('ad','Amber Traders',true))
    assert(s:RequestScheduledDelivery('other','Amber Traders',true));s:ProcessChatPopulationQueue();sent()
    now=s:GetGuildSchedule('other','Amber Traders').endsAtUtc
    s:ProcessChatPopulationQueue();eq(s.pendingRestoreState,nil);eq(next(s.chatPopulationQueue),nil)
end)
test('phase transitions announce once with the active frequency and ET end time',function()
    setup();s:CancelQueuedChatPopulation('ad','Amber Traders');s:CancelQueuedChatPopulation('other','Amber Traders')
    assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,delivery='REPEAT',
        eventDate='2026-10-10',eventTime='08:00 PM',promotionDays=2,endDelayMinutes=20,
        intervalMinutes=180,phaseIntervals={DAY=120,SOON=30},startingSoonEnabled=true,startingSoonMinutes=120,phaseOnce={LIVE=true}}))
    local config=s:GetGuildSchedule('ad','Amber Traders')
    now=config.startsAtUtc;s:NotifyScheduleTransition('ad','Amber Traders','RUNNING')
    local count=#CHAT_SYSTEM.messages
    now=s:ParseEasternDateTime('2026-10-10','12:00 AM');s:NotifyScheduleTransition('ad','Amber Traders','RUNNING')
    eq(#CHAT_SYSTEM.messages,count+1)
    local notice=CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]
    assert(notice:find('Event day',1,true));assert(notice:find('120 minutes',1,true));assert(notice:find('EDT',1,true))
    s:NotifyScheduleTransition('ad','Amber Traders','RUNNING');eq(#CHAT_SYSTEM.messages,count+1)
    now=config.eventAtUtc-120*60;s:NotifyScheduleTransition('ad','Amber Traders','RUNNING')
    assert(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]:find('Starting soon',1,true))
    now=config.eventAtUtc;s:NotifyScheduleTransition('ad','Amber Traders','RUNNING')
    assert(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]:find('one announcement',1,true))
    now=config.endsAtUtc;s:NotifyScheduleTransition('ad','Amber Traders','FINISHED')
    assert(CHAT_SYSTEM.messages[#CHAT_SYSTEM.messages]:find('schedule ended',1,true))
end)
local failures=0
for _,t in ipairs(tests) do local ok,err=pcall(t[2]);if ok then print('PASS '..t[1]) else failures=failures+1;print('FAIL '..t[1]..': '..tostring(err)) end end
assert(failures==0,tostring(failures)..' pacing tests failed')
