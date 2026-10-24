local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset()
f.entry('day','ad','Amber Traders','Join before the event!','Guild')
f.entry('live','ad','Amber Traders','Already in Cyrodiil; come join us!','Guild')
local d={mode='EVENT',enabled=true,eventDate='2026-10-24',eventTime='08:00 PM',promotionDays=0,endDelayMinutes=0,
    intervalMinutes=180,messagePhases={day={DAY=true},live={LIVE=true}}}
local cfg,reason=s:NormalizeSchedule(d)
assert(cfg,reason)
eq(cfg.endsAtUtc,cfg.eventAtUtc,'zero stops at the event start')
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
cfg=s:GetGuildSchedule('ad','Amber Traders');now=cfg.eventAtUtc-1;s:TickSchedules()
eq(s.pendingRestoreState.metadata.selectedEntryId,'day')
now=cfg.eventAtUtc;s:TickSchedules()
eq(s:GetGuildScheduleState('ad','Amber Traders'),'FINISHED')
eq(s.pendingRestoreState,nil,'stop at start withdraws unsent pre-event text')
eq(CHAT_SYSTEM:GetEditControl():GetText(),'')
eq(#s:GetScheduledMessageEntries('ad','Amber Traders'),0)
assert(not s:HandleScmCommand('send recruit 1'),'manual request cannot revive expired promotion')
-- Zero survives a repeating occurrence and settings transfer.
d.recurrence='WEEKLY';now=1000000
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
cfg=s:GetGuildSchedule('ad','Amber Traders')
local event=cfg.eventAtUtc
local nextEvent=s:GetScheduleOccurrence(cfg,event)
eq(nextEvent.eventAtUtc,event+7*86400);eq(nextEvent.endsAtUtc,nextEvent.eventAtUtc)
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
assert(s:ImportSettingsFromString(s:BuildExportString()))
eq(s:GetGuildSchedule('ad','Amber Traders').endDelayMinutes,0)
-- The post-start phase uses its own pool and interval and stops exclusively.
d.recurrence='NONE';d.endDelayMinutes=120;d.phaseIntervals={LIVE=15};now=1000000
assert(s:SaveGuildSchedule('ad','Amber Traders',d))
cfg=s:GetGuildSchedule('ad','Amber Traders');now=cfg.eventAtUtc-60
s:MarkCommandUsed('ad','Amber Traders','1',1)
now=cfg.eventAtUtc;s:TickSchedules()
eq(s.pendingRestoreState.metadata.selectedEntryId,'live')
eq(s:GetScheduleIntervalMinutes('ad','Amber Traders'),15)
eq(cfg.endsAtUtc,now+7200)
local text=s.pendingRestoreState.rawExpectedText
CHAT_SYSTEM:GetEditControl():SetText('')
s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_GUILD_1,'My Character',text,false,'@Me')
eq(cfg.nextDueAt,now+900)
now=cfg.endsAtUtc;s:TickSchedules();eq(s:GetGuildScheduleState('ad','Amber Traders'),'FINISHED')
-- The duration lives with the post-start messages and accepts zero in UI too.
s.savedVars.selectedMessagesCommand='ad';s.GetSelectedGuildNameForMessages=function() return 'Amber Traders' end
s.RefreshSettingsUI=function() end
local function find(list,name)
    for _,c in ipairs(list) do
        if c.name==name then return c end
        if c.controls then local match=find(c.controls,name);if match then return match end end
    end
end
local controls=s:BuildScheduleOptionControls()
local after=assert(find(controls,'After event starts'),'post-start messages need a clear settings section')
local duration=assert(find(after.controls,'Promote after start (minutes)'))
duration.setFunc('0');eq(s:GetScheduleEditorDraft().endDelayMinutes,'0')
local normalized=assert(s:NormalizeSchedule(s:GetScheduleEditorDraft()))
eq(normalized.endsAtUtc,normalized.eventAtUtc)
eq(s:GetMessagePreviewContext(s.savedVars.messages[2],'LIVE'),nil,'zero has no post-start preview time')
for _,value in ipairs({-1,1.5,'bad',math.huge}) do d.endDelayMinutes=value;assert(not s:NormalizeSchedule(d)) end
d.endDelayMinutes=0;d.eventTime='12:00 AM';assert(not s:NormalizeSchedule(d),'empty promotion window is invalid')
print('zero stops at event start; post-start messages have their own duration, interval, pool and transfer')
