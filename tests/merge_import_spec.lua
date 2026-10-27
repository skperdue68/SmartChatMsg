local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
local function find(id)for _,m in ipairs(s.savedVars.messages)do if m.id==id then return m end end end
f.reset();ZO_SavedVars={NewAccountWide=function()return s.savedVars end}
local a=f.entry('local-a','ad','Amber Traders','Same notice.','Guild');a.useCount=8;a.lastUsedAt=77;a.name='Local label'
f.entry('custom','ad','Amber Traders','My custom notice.','Guild');f.entry('other-message','other','Blue Traders','Unrelated notice.','Officer')
s.savedVars.defaultGuildIndex=2;s.savedVars.revertChatSeconds=95;s.savedVars.schedulingTimeZone='PT'
local settings=s:GetCommandGuildSettings('ad','Amber Traders',true);settings.runAt='ON_DEMAND';settings.lastUsedAt=77;settings.observedChatCooldowns={['*']={at=77,delaySeconds=60}};settings.lastAutoPopulateSentAtByZone={['41']=55};settings.disabledMessageIds={custom=true}
local incoming={commands={{id='foreign-command',name='RECRUIT'}},messages={{id='foreign-a',commandId='foreign-command',guildIndex=1,guildName='Amber Traders',text='Same notice.',name='Shared label',useCount=999,lastUsedAt=999},{id='new-message',commandId='foreign-command',guildIndex=1,guildName='Amber Traders',text='New notice.'}},chatChannels={['foreign-command']={['amber traders']='Officer'}},commandGuildSettings={['foreign-command']={['amber traders']={runAt='ON_DEMAND',reminderMinutes=30,disabledMessageIds={['foreign-a']=true}}}}}
assert(s:ApplyImportedSettings(incoming));eq(#s:GetCommands(),2);eq(#s.savedVars.messages,4);eq(find('local-a').name,'Shared label');eq(find('local-a').useCount,8);eq(find('local-a').lastUsedAt,77);assert(find('custom'));assert(find('other-message'))
eq(find('new-message').useCount,0);eq(find('new-message').lastUsedAt,nil);eq(s:GetSavedChatChannel('ad','Amber Traders'),'Officer')
settings=s:GetCommandGuildSettings('ad','Amber Traders',false);assert(settings.disabledMessageIds['local-a']);assert(settings.disabledMessageIds.custom);eq(settings.lastUsedAt,77);eq(settings.observedChatCooldowns['*'].at,77);eq(settings.lastAutoPopulateSentAtByZone['41'],55)
eq(s.savedVars.defaultGuildIndex,2);eq(s.savedVars.revertChatSeconds,95);eq(s:GetSchedulingTimeZone(),'PT')
assert(s:ApplyImportedSettings(incoming));eq(#s.savedVars.messages,4,'repeated imports are idempotent')
incoming.messages[1].id='local-a';incoming.messages[1].text='Changed wording.';assert(s:ApplyImportedSettings(incoming));eq(find('local-a').text,'Changed wording.');eq(#s.savedVars.messages,4)
local before=s.savedVars;local invalid=copy(incoming);invalid.commandGuildSettings['foreign-command']['amber traders'].schedule={mode='WINDOW'};assert(not s:ApplyImportedSettings(invalid));eq(s.savedVars,before,'invalid merge is transactional')
print('PASS additive merge by command name/guild and message ID/text, idempotence and recipient history')

-- Matching periods retain local IDs and quota history; absent commands/messages survive.
f.reset();f.entry('template','ad','Amber Traders','Event notice.','Guild');f.entry('extra','other','Blue Traders','Keep me.','Officer')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',recurrence='WEEKLY',timelineVersion=1,importantTimes={},reminders={{id='local-row',label='Promotion',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=15,lateMinutes=5,messageIds={'template'}}}}))
local old=s:GetGuildSchedule('ad','Amber Traders');old.timelineUsage={['1794099600:local-row']={lastSentAt=100,nextDueAt=1000}};old.availabilityUsage={['local-row:2026-11-07']={count=2,lastAt=100},['_command:2026-11-07']={count=2,lastAt=100}}
local schedule=copy(old);schedule.reminders[1].id='foreign-row';schedule.reminders[1].messageIds={'foreign-template'};schedule.timelineUsage={bad={lastSentAt=999999}}
local shared={commands={{id='foreign',name='recruit'}},messages={{id='foreign-template',commandId='foreign',guildName='Amber Traders',text='Event notice.'}},commandGuildSettings={foreign={['amber traders']={runAt='SCHEDULED',schedule=schedule}}},chatChannels={}}
assert(s:ApplyImportedSettings(shared));local restored=s:GetGuildSchedule('ad','Amber Traders');eq(restored.reminders[1].id,'local-row');eq(restored.reminders[1].messageIds[1],'template');eq(restored.timelineUsage['1794099600:local-row'].nextDueAt,1000);eq(restored.timelineUsage.bad,nil);eq(restored.availabilityUsage['_command:2026-11-07'].count,2);assert(find('extra'))
assert(s:ApplyImportedSettings(shared));eq(#s.savedVars.messages,2)
print('PASS semantic period identity, pool remapping and local quota/runtime preservation')

-- Global records omitted from partial text exports do not reset personal defaults.
f.reset();s.savedVars.defaultGuildIndex=2;s.savedVars.revertChatSeconds=120;s.savedVars.schedulingTimeZone='PT'
f.entry('mine','ad','Amber Traders','Keep local.','Guild')
assert(s:ImportSettingsFromString('SCM_EXPORT_V2\nCOMMAND|foreign|recruit||\nMESSAGE|added|foreign|Amber Traders|Amber Traders|Added body.||\nEND'))
eq(s.savedVars.defaultGuildIndex,2);eq(s.savedVars.revertChatSeconds,120);eq(s:GetSchedulingTimeZone(),'PT');assert(find('mine'));assert(find('added'));eq(#s:GetCommands(),2)
-- Conflicting foreign UUIDs cannot overwrite a different local command/message.
local collision={commands={{id='other',name='new-event'}},messages={{id='mine',commandId='other',guildName='Amber Traders',text='Different imported body.'}},chatChannels={},commandGuildSettings={}}
assert(s:ApplyImportedSettings(collision));eq(find('mine').text,'Keep local.');eq(#s:GetCommands(),3);eq(#s.savedVars.messages,3)
assert(s:ApplyImportedSettings(collision));eq(#s:GetCommands(),3);eq(#s.savedVars.messages,3)
print('PASS partial global settings and UUID collisions across independently configured accounts')

-- Rotating activity names reconcile across different donor IDs.
f.reset();f.entry('trial','ad','Amber Traders','Trial activity %eventactivity%.','Guild');f.entry('local-only','ad','Amber Traders','Personal wording.','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-11-07',eventTime='08:00 PM',recurrence='WEEKLY',specialPattern='EVENT_ROTATION',rotationEvents={{id='local-activity',name='Cloudrest'}},timelineVersion=1,importantTimes={},messageVariants={trial='local-activity',['local-only']='local-activity'},reminders={{id='period',label='Promotion',start={kind='OFFSET',minutes=-60},finish={kind='OFFSET',minutes=0},intervalMinutes=15,lateMinutes=5,messageIds={'trial'}}}}))
local rotated=copy(s:GetGuildSchedule('ad','Amber Traders'));rotated.rotationEvents[1].id='donor-activity';rotated.messageVariants={['foreign-trial']='donor-activity'};rotated.reminders[1].messageIds={'foreign-trial'}
assert(s:ApplyImportedSettings({commands={{id='donor',name='recruit'}},messages={{id='foreign-trial',commandId='donor',guildName='Amber Traders',text='Trial activity %eventactivity%.'}},commandGuildSettings={donor={['amber traders']={runAt='SCHEDULED',schedule=rotated}}},chatChannels={}}))
local rotation=s:GetGuildSchedule('ad','Amber Traders');eq(rotation.rotationEvents[1].id,'local-activity');eq(rotation.messageVariants.trial,'local-activity');assert(find('local-only'));eq(#s.savedVars.messages,2,'different activity/message IDs must not duplicate a matched template')
print('PASS activity ID reconciliation keeps local groups valid across accounts')
