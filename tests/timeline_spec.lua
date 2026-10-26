local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
local d={mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',promotionDays=13,endDelayMinutes=10,recurrence='BIWEEKLY',intervalMinutes=60,timelineVersion=1,importantTimes={tickets={label='Ticket sales close',offsetMinutes=-60}},reminders={
 {id='early',label='Early promotion',start={kind='DAY',days=-13,time='08:00 PM'},finish={kind='DAY',days=-1,time='12:00 AM'},intervalMinutes=360,messageIds={'early'}},
 {id='close',label='Ticket sales close',start={kind='MARK',name='tickets'},once=true,lateMinutes=5,timeSensitive=true,messageIds={'closed'}},
 {id='start',label='Starting',start={kind='OFFSET',minutes=0},once=true,lateMinutes=5,timeSensitive=true,messageIds={'starting'}}}}
f.entry('early','ad','Amber Traders','Drawing %eventwhen% %eventtime%','Guild')
f.entry('closed','ad','Amber Traders','Sales closed!','Guild')
f.entry('starting','ad','Amber Traders','Starting now!','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
local config=s:GetGuildSchedule('ad','Amber Traders');assert(config.reminders,'timeline must survive normalization')
now=config.eventAtUtc-3600
local row,start,finish=s:GetActiveTimelineReminder(config,now);eq(row.id,'close');eq(start,now);eq(finish,now+300)
eq(s:GetSchedulePhase(config,now),'close')
eq(s:GetScheduledMessageEntries('ad','Amber Traders')[1].id,'closed')
s.scheduledSendPause={senderKey='other',endsAt=now+300};eq(s:GetSchedulePacingDelay('ad','Amber Traders'),nil)
now=config.eventAtUtc;eq(s:GetActiveTimelineReminder(config,now).id,'start')
now=config.eventAtUtc+301;eq(s:GetActiveTimelineReminder(config,now),nil)
-- Calendar opening remains 8 PM local across the fall DST change.
local occurrence=s:BuildScheduleOccurrence(config,config.eventAtUtc)
local opening=s:ResolveTimelineAnchor(config,occurrence,config.reminders[1].start)
eq(s:FormatScheduleDateTime(opening,config),'2026-10-25 08:00 PM EDT')
now=config.eventAtUtc-3600
eq(s:GetScheduledEventTokenValue('eventwhen-1h','ad','Amber Traders'),'today')
print('timeline normalization, boundaries, milestone priority and civil calendar anchors passed')
