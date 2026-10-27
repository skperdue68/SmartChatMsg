local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset()
local template='Good %timeofday%, Family! Join %guild% for a fabulous adventure together!'
local function matches(text,source)
 local e={commandId='ad',text=source or template}
 return s:MatchesIncomingMessage(e,'Amber Traders',s:NormalizeIncomingChatText(text))
end
assert(matches('Good afternoon, Family! Join Amber Traders for a fabulous adventurre together!'),'extra letter plus greeting')
assert(matches('Good evening, Family! Join Amber Traders for a fabulous adveture together!'),'missing letter')
assert(matches('Good morning, Family! Join Amber Traders for a fabulous adventuer together!'),'transposed letters')
assert(not matches('Good midnight, Family! Join Amber Traders for a fabulous adventurre together!'),'invalid substitution')
assert(not matches('Good morning, Family! Join Blue Traders for a fabulous adventurre together!'),'different guild')
assert(not matches('Good morning, Family! Join Amber Traders for an entirely different gathering together!'),'different text')
assert(not matches('Trial strats!','Trial starts!'),'short messages stay exact')
local price='Family business: buy raffle tickets for 500g and join our fabulous gathering tonight!'
assert(not matches(price:gsub('500g','501g'),price),'numbers remain exact')
local link='Family business: |H1:guild:101|hAmber Traders|h welcomes fabulous adventurers and allies!'
assert(not matches(link:gsub('guild:101','guild:102'),link),'guild links remain exact')
assert(matches(link:gsub('adventurers','adventurres'),link),'typo outside link')
local countdown='Family business: this fabulous gathering starts at 3AM ET and everyone is welcome!'
assert(matches('Family business: this fabulous gatherring starts at 3AM ET (~17h) and everyone is welcome!',countdown),'generated countdown plus typo')
assert(not matches('Family business: this fabulous gatherring starts at 4AM ET (~17h) and everyone is welcome!',countdown),'different event clock')
f.reset();local e=f.entry('typo','ad','Amber Traders',template,'Guild')
f.incoming(CHAT_CHANNEL_GUILD_1+1,'Good morning, Family! Join Amber Traders for a fabulous adventurre together!');eq(s:GetGuildLastUsedAt('ad','Amber Traders'),nil)
f.incoming(CHAT_CHANNEL_GUILD_1,'Good morning, Family! Join Amber Traders for a fabulous adventurre together!');eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now);eq(e.useCount,1)
print('PASS conservative spelling matches, validated substitutions, protected identities and cooldown scope')

-- Resolved rotating activity names remain identities, not spelling candidates.
local original=s.GetScheduledEventTokenValue
s.GetScheduledEventTokenValue=function(self,token,...) if token=='eventactivity' then return 'Cloudrest' end;return original(self,token,...) end
local rotating='Family business: join our fabulous %eventactivity% adventure and bring your friends!'
assert(matches('Family business: join our fabulous Cloudrest adventurre and bring your friends!',rotating))
assert(not matches('Family business: join our fabulous Cloudrests adventure and bring your friends!',rotating))
s.GetScheduledEventTokenValue=original
f.reset();f.entry('typo','ad','Amber Traders',template,'Guild');f.incoming(CHAT_CHANNEL_GUILD_1,'Good morning, Family! Join Amber Traders for a fabulous adventurre together!','My Character','@Me');eq(s:GetGuildLastUsedAt('ad','Amber Traders'),nil)

assert(matches('Good morning, Family! Join Amber Traders for a fabulous adventxre together!'),'substituted letter')
local long=string.rep('fabulous ',35)..'tonight!'
assert(matches(long:gsub('fabulous','fabuloous',3),long),'long messages allow three letter edits')
assert(not matches(long:gsub('fabulous','fabuloous',4),long),'long-message limit is three edits')
assert(not matches('Good morning, Family? Join Amber Traders for a fabulous adventure together!'),'punctuation remains exact')
