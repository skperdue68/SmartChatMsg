local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
local entry=f.entry('private','ad','Amber Traders','My personal announcement','Guild')
assert(s:SetMessageLocked('private',true));eq(entry.locked,true)
local settings=s:GetCommandGuildSettings('ad','Amber Traders',true)
settings.runAt='STARTUP';settings.openStatusPanelOnRun=true;settings.populateSound='NONE'
settings.reminderMinutes=7;settings.reminderRetryMinutes=2;settings.autoPopulateCooldownMinutes=42
s.savedVars.statusPanelState={visible=true,offsetX=123,offsetY=456}
local exported=s:BuildExportString()
assert(not exported:find('My personal announcement',1,true),'private content must not export')
eq(s:BuildMessageShareString('ad','Amber Traders'),nil)
s.savedVars.statusPanelState={visible=false,offsetX=0,offsetY=0}
settings.runAt='ON_DEMAND';settings.openStatusPanelOnRun=false;settings.populateSound='DUEL_START'
assert(s:ImportSettingsFromString(exported))
eq(#s.savedVars.messages,1);eq(s.savedVars.messages[1].locked,true)
settings=s:GetCommandGuildSettings('ad','Amber Traders',true)
eq(settings.runAt,'STARTUP');eq(settings.openStatusPanelOnRun,true);eq(settings.populateSound,'NONE')
eq(settings.reminderMinutes,7);eq(settings.reminderRetryMinutes,2);eq(settings.autoPopulateCooldownMinutes,42)
eq(s.savedVars.statusPanelState.visible,true);eq(s.savedVars.statusPanelState.offsetX,123);eq(s.savedVars.statusPanelState.offsetY,456)
assert(s:SetMessageLocked('private',false));assert(s:BuildExportString():find('My personal announcement',1,true))
assert(s:SetMessageLocked('private',true))
assert(s:ImportSettingsFromString('SCM_EXPORT_V1\nCOMMAND|new-id|recruit||\nMESSAGE|private|new-id||Amber Traders|Replacement||\nEND'))
eq(#s.savedVars.messages,1);eq(s.savedVars.messages[1].text,'My personal announcement');eq(s.savedVars.messages[1].commandId,'new-id')
eq(s.savedVars.messages[1].locked,true)
local before=s.savedVars
assert(not s:ImportSettingsFromString('bad data'));eq(s.savedVars,before)
assert(s:ImportSettingsFromString('SCM_EXPORT_V1\nCOMMAND|other|unrelated||\nEND'));eq(#s.savedVars.messages,0)

f.reset();entry=f.entry('private','ad','Amber Traders','Private event message','Guild')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,delivery='REPEAT',eventDate='2026-10-08',eventTime='09:00 PM',promotionDays=2,endDelayMinutes=20,intervalMinutes=5,messagePhases={private={DAY=true}}}))
assert(s:SetMessageLocked('private',true))
exported=s:BuildExportString();assert(not exported:find('SCHEDULEMESSAGE_V1|ad|amber traders|private',1,true))
assert(s:ImportSettingsFromString(exported))
eq(s:GetGuildSchedule('ad','Amber Traders').messagePhases.private.DAY,true)
eq(s:GetGuildSchedule('ad','Amber Traders').messagePhases.private.BEFORE,false)
eq(s.savedVars.messages[1].locked,true)
s:InitializeSavedVars();eq(s.savedVars.messages[1].locked,true)
s:SetGuildRunAt('ad','Amber Traders','ON_DEMAND');assert(SLASH_COMMANDS['/recruit'])
s:SetGuildRunAt('ad','Amber Traders','SCHEDULED');eq(SLASH_COMMANDS['/recruit'],nil)
s:SetGuildRunAt('ad','Amber Traders','STARTUP');assert(SLASH_COMMANDS['/recruit'])
local stable=s.savedVars
assert(not s:ImportSettingsFromString('SCM_EXPORT_V1\nSTATUSPANEL|1|bad|10\nEND'));eq(s.savedVars,stable)
print('personal message locking and settings round-trip checks passed')
