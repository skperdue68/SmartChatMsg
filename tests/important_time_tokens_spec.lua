local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq;f.reset()
local entry=f.entry('a','ad','Amber Traders','Raffle %eventwhen% at %eventtime%. Sales close %eventwhen:tickets% at %eventtime:tickets% (%eventcountdown:tickets%).','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',promotionDays=3,endDelayMinutes=10,intervalMinutes=60,timelineVersion=1,importantTimes={tickets={label='Ticket sales close',offsetMinutes=-60}},reminders={{id='a',start={kind='DAY',days=-3,time='08:00 PM'},finish={kind='OFFSET',minutes=0},messageIds={'a'},intervalMinutes=60}}}))
local c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc-86400
local text=s:ApplyMessageSubstitutions(entry.text,'ad','Amber Traders')
eq(text,'Raffle tomorrow at 08:00 PM EST. Sales close tomorrow at 07:00 PM EST (23h).')
now=now+3600;assert(s:MatchesIncomingMessage(entry,'Amber Traders',s:NormalizeIncomingChatText(text)))
print('named important-time day/time/countdown substitutions and incoming matching passed')

now=c.eventAtUtc-3*3600
eq(s:ApplyMessageSubstitutions('Sales close at %eventtime:tickets%.','ad','Amber Traders'),'Sales close at 07:00 PM EST (2h).')
