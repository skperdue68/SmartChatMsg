local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset();s.savedVars.commands={};s.savedVars.messages={}
local memberships={{guildId=101,guildName='Amber Traders'},{guildId=202,guildName='Blue Traders'}}
local advertisedCount
GetGuildId=function(slot) return memberships[slot] and memberships[slot].guildId or 0 end
GetGuildName=function(id) for _,row in pairs(memberships) do if row.guildId==id then return row.guildName end end;return '' end
GetNumGuilds=function() return advertisedCount or #memberships end
ZO_SavedVars={NewAccountWide=function() return s.savedVars end}
s:InitializeSavedVars();eq(#s.savedVars.commands,0);eq(#s.savedVars.guildRoster,2)
eq(s.savedVars.guildRoster[1].guildId,101);eq(s.savedVars.guildRoster[1].guildIndex,1);eq(s.savedVars.guildRoster[1].guildName,'Amber Traders');eq(s.savedVars.guildRosterUpdatedAt,now)
local cached=s.savedVars.guildRoster;local timestamp=s.savedVars.guildRosterUpdatedAt
-- Incomplete API responses must not replace any part of the previous snapshot.
now=now+60;memberships[2].guildName=' ';assert(not s:RefreshGuildRoster(true));eq(s.savedVars.guildRoster,cached);eq(s.savedVars.guildRosterUpdatedAt,timestamp)
memberships[2].guildName='Blue Traders';advertisedCount=3;assert(not s:RefreshGuildRoster(true));eq(s.savedVars.guildRoster,cached)
advertisedCount=nil;memberships[2].guildId=101;assert(not s:RefreshGuildRoster(true));eq(s.savedVars.guildRoster,cached)
memberships[2].guildId=202
local originalId=GetGuildId;GetGuildId=function(slot) if slot==2 then error('not ready') end;return originalId(slot) end
assert(not s:RefreshGuildRoster(true));eq(s.savedVars.guildRoster,cached);GetGuildId=originalId
-- Names and slot order refresh together, without requiring any commands/messages.
memberships={{guildId=202,guildName='Blue Traders Renamed'},{guildId=101,guildName='Amber Traders'}}
assert(s:RefreshGuildRoster(false));eq(s.savedVars.guildRoster[1].guildId,202);eq(s.savedVars.guildRoster[1].guildName,'Blue Traders Renamed');eq(s.savedVars.guildRoster[2].guildIndex,2);eq(s.savedVars.guildRosterUpdatedAt,now)
-- Startup zero is protected, including across repeated SavedVars reloads.
cached=s.savedVars.guildRoster;timestamp=s.savedVars.guildRosterUpdatedAt;memberships={};now=now+60
assert(not s:RefreshGuildRoster(false));s:InitializeSavedVars();eq(s.savedVars.guildRoster[1].guildId,202);eq(s.savedVars.guildRosterUpdatedAt,timestamp)
assert(s:RefreshGuildRoster(true));eq(#s.savedVars.guildRoster,0);eq(s.savedVars.guildRosterUpdatedAt,now)
-- Invalid old cache fields sanitize when no ready response can replace them.
s.savedVars.guildRoster='bad';s.savedVars.guildRosterUpdatedAt=math.huge;s:InitializeSavedVars();eq(#s.savedVars.guildRoster,0);eq(s.savedVars.guildRosterUpdatedAt,nil)
s.savedVars.guildRoster={{guildId=101,guildIndex=1,guildName='Good'},{guildId=202,guildIndex=1,guildName='Duplicate slot'}};s.savedVars.guildRosterUpdatedAt=42
s:InitializeSavedVars();eq(#s.savedVars.guildRoster,0);eq(s.savedVars.guildRosterUpdatedAt,nil)
-- GetNumGuilds is optional; valid live slots still refresh on older API fixtures.
GetNumGuilds=nil;memberships={{guildId=303,guildName='New Guild'}};assert(s:RefreshGuildRoster(false));eq(s.savedVars.guildRoster[1].guildName,'New Guild')
local last=s.savedVars.guildRosterUpdatedAt;local originalName=GetGuildName;GetGuildName=nil;now=now+1
assert(not s:RefreshGuildRoster(true));eq(s.savedVars.guildRosterUpdatedAt,last);GetGuildName=originalName
-- Portable text exports omit membership metadata. Import retains/refetches the
-- recipient roster, rather than adopting a source player's cached memberships.
local text=s:BuildExportString();assert(not text:find('guildRoster',1,true));assert(not text:find('New Guild',1,true))
assert(s:ImportSettingsFromString(text));eq(s.savedVars.guildRoster[1].guildId,303)
memberships={{guildId=404,guildName='Recipient New Guild'}};assert(s:ImportSettingsFromString(text));eq(s.savedVars.guildRoster[1].guildId,404)
-- Exercise real addon-load registration, activation and guarded self join/leave.
EVENT_PLAYER_ACTIVATED=300;EVENT_GUILD_SELF_JOINED=301;EVENT_GUILD_SELF_LEFT=302
for _,method in ipairs({'ClearActiveAutoPopulate','ClearPendingRestoreState','CreateSettingsPanel','CreateStatusPanel','RegisterDynamicCommands','RegisterIncomingChatWatcher','InitializeScheduler','HandleZoneAutoPopulate','TickSchedules','InitializeStartupQueueOnce'}) do s[method]=function() end end
s.GetStatusPanelVisiblePreference=function() return false end
local loaded=assert(EVENT_MANAGER.events[s.name..EVENT_ADD_ON_LOADED]);loaded(EVENT_ADD_ON_LOADED,s.name)
local activate=assert(EVENT_MANAGER.events[s.name..'_PlayerActivated'..EVENT_PLAYER_ACTIVATED]);local joined=assert(EVENT_MANAGER.events[s.name..'_GuildRoster'..EVENT_GUILD_SELF_JOINED..EVENT_GUILD_SELF_JOINED]);local left=assert(EVENT_MANAGER.events[s.name..'_GuildRoster'..EVENT_GUILD_SELF_LEFT..EVENT_GUILD_SELF_LEFT])
memberships={};activate();eq(#s.savedVars.guildRoster,0)
memberships={{guildId=505,guildName='Joined Guild'}};joined();eq(s.savedVars.guildRoster[1].guildId,505)
memberships={};left();eq(#s.savedVars.guildRoster,0)
EVENT_GUILD_SELF_JOINED=nil;EVENT_GUILD_SELF_LEFT=nil;s:RegisterGuildRosterEvents()
print('Guild roster caches IDs/names/slots on empty accounts, protects partial startup data, refreshes recipient membership and self events, and persists across reloads')
