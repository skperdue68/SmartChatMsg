local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();f.entry('a','ad','Amber Traders','Group test announcement','Group')
eq(s:GetSavedChatChannel('ad','Amber Traders'),'Group')
s.savedVars.selectedMessagesCommand='ad';s.savedVars.selectedMessagesGuildIndex=1
s:SetSelectedMessagesChannel('Group (/p)');eq(s:GetSelectedMessagesChannel(),'Group (/p)')
assert(s:PopulateChatBufferForCommand('ad','Amber Traders'))
eq(CHAT_SYSTEM.channel,CHAT_CHANNEL_PARTY)
local expected=s.pendingRestoreState.rawExpectedText;CHAT_SYSTEM:GetEditControl():SetText('')
s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_PARTY,'My Character',expected,false,'@Me')
eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now)
now=now+100
f.incoming(CHAT_CHANNEL_ZONE,'Group test announcement');eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now-100)
f.incoming(CHAT_CHANNEL_PARTY,'Group test announcement');eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now)
f.entry('b','other','Amber Traders','Group test announcement','Guild')
f.incoming(CHAT_CHANNEL_PARTY,'Group test announcement');eq(s:GetGuildLastUsedAt('other','Amber Traders'),nil)
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
assert(s:ImportSettingsFromString(s:BuildExportString()));eq(s:GetSavedChatChannel('ad','Amber Traders'),'Group')
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='WINDOW',enabled=true,startDate='2026-10-09',startTime='08:00 PM',endDate='2026-10-09',endTime='09:00 PM',intervalMinutes=5}))
now=s:GetGuildSchedule('ad','Amber Traders').startsAtUtc;s:ResetAllCooldowns();s:TickSchedules()
eq(CHAT_SYSTEM.channel,CHAT_CHANNEL_PARTY);assert(s.pendingRestoreState.metadata.scheduledDelivery)
eq(s:GetAutoPopulateChannelStatusText('ad','Amber Traders'),'Group (/p)')
print('Group output, matching, scheduled delivery and export checks passed')
