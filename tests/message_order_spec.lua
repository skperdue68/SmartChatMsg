local f=dofile('tests/eso_fixture.lua');local s,eq=f.scm,f.eq
f.reset()
local schedule={mode='EVENT',startingSoonEnabled=true,messagePhases={
    a={LIVE=true},b={},c={SOON=true},d={DAY=true},e={BEFORE=true},f={DAY=true,LIVE=true}}}
local entries={};for _,id in ipairs({'a','b','c','d','e','f','g'}) do entries[#entries+1]={id=id} end
local function ids(list) local out={};for _,entry in ipairs(list) do out[#out+1]=entry.id end;return table.concat(out,',') end
eq(ids(s:SortScheduledMessageEntries(entries,schedule)),'e,g,d,f,c,a,b')
eq(ids(entries),'a,b,c,d,e,f,g','sorting must not change the saved source list')
schedule.messagePhases.e={LIVE=true}
eq(ids(s:SortScheduledMessageEntries(entries,schedule)),'g,d,f,c,a,e,b')
schedule.startingSoonEnabled=false
eq(ids(s:SortScheduledMessageEntries(entries,schedule)),'g,d,f,a,e,b,c')
-- Preserve the visible message and within-row offset when sorting long rows.
local viewport={offset=110,extent=600}
function viewport:GetScrollOffsets() return 0,self.offset end
function viewport:GetScrollExtents() return 0,self.extent end
function viewport:SetVerticalScroll(value) self.offset=value end
local container={scroll=viewport}
ZO_Scroll_UpdateScrollBar=function() end
local before={{id='a',y=0,height=100},{id='b',y=106,height=80},{id='c',y=192,height=150}}
local snapshot=s:CaptureMessageListScroll(container,before)
s:RestoreMessageListScroll(container,snapshot,{{id='c',y=0,height=150},{id='a',y=156,height=100},{id='b',y=262,height=80}})
eq(viewport.offset,266)
viewport.extent=200;s:RestoreMessageListScroll(container,snapshot,{{id='b',y=300,height=80}})
eq(viewport.offset,200,'clamp scroll if list shrinks')
print('scheduled phase ordering and scroll anchoring checks passed')

-- Exercise the actual pool refresh: sorted callbacks keep scroll anchoring and
-- reuse controls rather than reconstructing the section.
f.reset();s.savedVars.selectedMessagesCommand='ad';s.savedVars.selectedMessagesGuildIndex=1
for _,id in ipairs({'a','b','c','d','e','f'}) do f.entry(id,'ad','Amber Traders',string.rep(id..' message ',20),'Guild') end
assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,eventDate='2026-10-13',eventTime='08:00 PM',promotionDays=1,endDelayMinutes=20,intervalMinutes=30,
    messagePhases={a={BEFORE=true},b={DAY=true},c={DAY=true},d={DAY=true},e={DAY=true},f={DAY=true}}}))
local creates=0
local function control()
    local c={width=520,height=0,children={},handlers={}}
    function c:GetWidth() return self.width end
    function c:SetWidth(v) self.width=v end
    function c:SetHeight(v) self.height=v end
    function c:SetText(v) self.text=v end
    function c:GetTextHeight() return math.ceil(#(self.text or '')/math.max(1,math.floor(self.width/8)))*20 end
    function c:GetNamedChild(k) self.children[k]=self.children[k] or control();return self.children[k] end
    function c:SetHandler(k,v) self.handlers[k]=v end
    function c:GetScrollOffsets() return 0,self.offset or 0 end
    function c:GetScrollExtents() return 0,math.max(0,self:GetNamedChild('Child').height-230) end
    function c:SetVerticalScroll(v) self.offset=v end
    return setmetatable(c,{__index=function(_,k) if k:match('^Set') or k=='ClearAnchors' then return function() end end end})
end
WINDOW_MANAGER={CreateControl=function() creates=creates+1;return control() end,
    CreateControlFromVirtual=function(_,_,_,template)
        creates=creates+1;local c=control();if template=='ZO_ScrollContainer' then c.scroll=c:GetNamedChild('Scroll') end;return c
    end}
ZO_CheckButton_SetCheckState=function(c,v) c.checked=v end
ZO_CheckButton_SetToggleFunction=function(c,v) c.toggle=v end
ZO_CheckButton_IsChecked=function(c) return c.checked end
ZO_Scroll_ResetToTop=function(c) c.scroll.offset=0 end
local pool=control();s:RefreshScheduleMessagePool(pool,'BEFORE')
local before=creates;local first=pool.scheduleRows[1];eq(first.messageId,'a')
pool.scheduleScroll.scroll.offset=pool.scheduleRowPositions[2].y+4
s.RefreshSettingsUI=function() s:RefreshScheduleMessagePool(pool,'BEFORE') end
first.check.checked=false;first.check.toggle(first.check)
eq(pool.scheduleRows[1].messageId,'b');eq(pool.scheduleRows[6].messageId,'a')
eq(pool.scheduleScroll.scroll.offset,4);eq(creates,before)
eq(pool.scheduleRows[1].check.checked,false)
print('live pool reorder preserves visible message and existing controls')
