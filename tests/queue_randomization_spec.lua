local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
local function queued(random)
 f.reset();s.scheduleStartupEndsAt=now+180
 for _,id in ipairs({'ad','other'}) do
  f.entry(id..'message',id,'Amber Traders',id..' notice','Guild')
  s:SetGuildRunAt(id,'Amber Traders','ON_DEMAND')
  s:QueueChatPopulation(id,'Amber Traders',nil,{commandId=id,guildName='Amber Traders'},3)
 end
 now=now+180;local result
 s.PopulateChatBufferForCommand=function(_,id)result=id;return true end
 zo_random=function(lo,hi)return random=='last' and hi or lo end
 s:ProcessChatPopulationQueue();return result
end
local a=queued('first');local b=queued('last');assert(a~=b,'equally eligible queue entries must randomize at release')
print('queue delivery ties randomize after startup without changing priority')
