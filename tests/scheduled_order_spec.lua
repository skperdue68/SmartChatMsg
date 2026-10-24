local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
local function setup()
    f.reset()
    for _,id in ipairs({'ad','other','third'}) do
        if id=='third' then s.savedVars.commands[#s.savedVars.commands+1]={id=id,name=id} end
        f.entry(id..'msg',id,'Amber Traders',id..' notice.','Guild')
        assert(s:SaveGuildSchedule(id,'Amber Traders',{mode='WINDOW',enabled=true,startDate='2026-10-24',startTime='12:00 PM',endDate='2026-10-24',endTime='11:00 PM',intervalMinutes=180}))
    end
    now=s:GetGuildSchedule('ad','Amber Traders').startsAtUtc
end
local function sent()
    local p=assert(s.pendingRestoreState)
    CHAT_SYSTEM:GetEditControl():SetText('')
    s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_GUILD_1,'My Character',p.rawExpectedText,false,'@Me')
end
-- Choosing a different legal shuffle outcome must change the first ready sender.
local original=zo_random
setup();zo_random=function(lo,hi) return hi end;s:TickSchedules()
local first=s.pendingRestoreState.metadata.commandId
setup();zo_random=function(lo,hi) return lo end;s:TickSchedules()
assert(first~=s.pendingRestoreState.metadata.commandId,'ready schedules must not always use sorted command order')
local seen={}
for i=1,3 do
    local id=assert(s.pendingRestoreState).metadata.commandId
    assert(not seen[id],'no duplicate in a ready batch');seen[id]=true;sent()
    if i<3 then
        now=now+299;s:TickSchedules();eq(s.pendingRestoreState,nil,'cross-schedule spacing remains enforced')
        now=now+1;s:TickSchedules();assert(s.pendingRestoreState)
    end
end
assert(seen.ad and seen.other and seen.third)
-- An explicit request stays ahead of shuffled automatic requests.
setup();CHAT_SYSTEM:GetEditControl():SetText('draft');s:TickSchedules()
assert(s:RequestScheduledDelivery('third','Amber Traders',true))
CHAT_SYSTEM:GetEditControl():SetText('');s:ProcessChatPopulationQueue()
eq(s.pendingRestoreState.metadata.commandId,'third')
zo_random=original
print('ready schedules shuffle without duplicates and retain spacing and manual priority')
