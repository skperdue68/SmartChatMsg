local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local function setup()
 f.reset();f.entry('normal','ad','Amber Traders','Tickets are available.','Guild');f.entry('start','ad','Amber Traders','Starting now!','Guild')
 assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',recurrence='BIWEEKLY',timelineVersion=1,reminders={{id='normal',label='Promotion',start={kind='OFFSET',minutes=-120},finish={kind='OFFSET',minutes=-1},intervalMinutes=60,messageIds={'normal'}},{id='start',label='Starting',start={kind='OFFSET',minutes=0},once=true,timeSensitive=true,lateMinutes=5,intervalMinutes=60,messageIds={'start'}}}}))
 local c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc
 return c
end
local c=setup();s.scheduleStartupEndsAt=now+180;s:TickSchedules();eq(s.pendingRestoreState,nil,'startup hold remains')
s.scheduleStartupEndsAt=now;s.scheduledSendPause={senderKey='other',endsAt=now+300}
s:SetGuildLastUsedState('ad','Amber Traders',now-60,'1',1)
s:GetCommandGuildSettings('ad','Amber Traders',true).observedChatCooldowns={['*']={at=now-60,delaySeconds=60}}
s:TickSchedules();assert(s.pendingRestoreState,'milestone bypasses prior normal usage and another schedule pause')
eq(s.pendingRestoreState.metadata.selectedEntryId,'start')
f.incoming(CHAT_CHANNEL_GUILD_1,'Tickets are available.')
assert(s.pendingRestoreState,'old-phase peer post must not withdraw the milestone')
f.incoming(CHAT_CHANNEL_GUILD_1,'Starting now!')
eq(s.pendingRestoreState,nil,'same milestone peer suppresses duplicate')
assert(c.timelineUsage[tostring(c.eventAtUtc)..':start'].completed)
c=setup();CHAT_SYSTEM:GetEditControl():SetText('My own message');s:TickSchedules();eq(CHAT_SYSTEM:GetEditControl():GetText(),'My own message')
now=now+301;CHAT_SYSTEM:GetEditControl():SetText('');s:TickSchedules();eq(s.pendingRestoreState,nil,'expired milestone skips')
c=setup();s:TickSchedules();local text=s.pendingRestoreState.rawExpectedText;CHAT_SYSTEM:GetEditControl():SetText('');s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_GUILD_1,'My Character',text,false,'@Me')
assert(c.timelineUsage[tostring(c.eventAtUtc)..':start'].completed,'confirmation completes milestone')
s:TickSchedules();eq(s.pendingRestoreState,nil,'once remains completed')
print('time-sensitive delivery startup, priority, user text, peer scope, expiry and confirmation verified')
