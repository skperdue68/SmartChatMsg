local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq;f.reset()
f.entry('a','ad','Amber Traders','Event','Guild')
local function config(mark) return {mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',recurrence='WEEKLY',timelineVersion=1,importantTimes={close={label='Closing',offsetMinutes=mark}},reminders={{id='repeat',start={kind='OFFSET',minutes=0},finish={kind='OFFSET',minutes=60},intervalMinutes=15,messageIds={'a'}},{id='once',start={kind='OFFSET',minutes=0},once=true,lateMinutes=5,intervalMinutes=15,messageIds={'a'}}}} end
assert(s:SaveGuildSchedule('ad','Amber Traders',config(-60)));local c=s:GetGuildSchedule('ad','Amber Traders');now=c.eventAtUtc;eq(s:GetActiveTimelineReminder(c,now).id,'once','once must win a tie with a repeating row')
c.timelineUsage[tostring(now)..':once']={completed=true};eq(s:GetActiveTimelineReminder(c,now).id,'repeat')
for _,item in ipairs({{'other',-120},{'third',-60}}) do local id,offset=item[1],item[2];if id=='third' then s.savedVars.commands[#s.savedVars.commands+1]={id=id,name=id} end;f.entry(id,id,'Amber Traders','%eventtime:close%','Guild');assert(s:SaveGuildSchedule(id,'Amber Traders',config(offset)));assert(s:MergeTimelineEvents('ad','Amber Traders',{id})) end
c=s:GetGuildSchedule('ad','Amber Traders');local offsets={};for _,mark in pairs(c.importantTimes) do offsets[mark.offsetMinutes]=true end;assert(offsets[-120] and offsets[-60],'separate combines must not overwrite important times')
assert(not s:MergeTimelineEvents('ad','Amber Traders',{'other'}),'repeat combination rejects')
print('same-start once priority, independent named times and repeat-merge rejection verified')
