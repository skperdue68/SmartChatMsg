local f=dofile('tests/eso_fixture.lua')
local s,eq=f.scm,f.eq
f.reset()
local function schedule()
    f.entry('a','ad','Amber Traders','Scheduled notice','Guild')
    assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='WINDOW',enabled=true,delivery='REPEAT',startDate='2026-10-08',startTime='08:00 PM',endDate='2026-10-08',endTime='09:00 PM',intervalMinutes=5}))
    now=s:GetGuildSchedule('ad','Amber Traders').startsAtUtc
end
local tests={};local function test(n,fn) tests[#tests+1]={n,fn} end
test('scheduled event countdown uses event UTC timestamp after UTC midnight',function()
    f.reset();f.entry('a','ad','Amber Traders','PvP today at %eventtime%','Guild')
    assert(s:SaveGuildSchedule('ad','Amber Traders',{mode='EVENT',enabled=true,delivery='REPEAT',
        eventDate='2026-10-08',eventTime='09:00 PM',promotionDays=2,endDelayMinutes=20,intervalMinutes=5}))
    now=s:ParseEasternDateTime('2026-10-08','08:00 PM')
    local row=s:GetRepeatStatusPanelRows()[1]
    assert(row.displayName:find('(Scheduled) Starts in ',1,true))
    assert(row.statusText:find('On event day (every 5 minutes)',1,true))
    local text=s:ApplyMessageSubstitutions('PvP today at %eventtime%','ad','Amber Traders')
    assert(text:find('(1h)',1,true),text);assert(not text:find('1d',1,true),text)
    f.incoming(CHAT_CHANNEL_GUILD_1,text);eq(s:GetGuildLastUsedAt('ad','Amber Traders'),now)
end)
test('schedule-only entries have no slash handler, mixed and ordinary entries do',function()
    f.reset();schedule();s:RegisterDynamicCommands();eq(SLASH_COMMANDS['/recruit'],nil)
    f.entry('mixed','ad','Blue Traders','Ordinary notice');s:SetGuildReminderMinutes('ad','Blue Traders',5)
    s:RegisterDynamicCommands();assert(SLASH_COMMANDS['/recruit'])
    s:SetGuildRunAt('ad','Blue Traders','SCHEDULED');eq(SLASH_COMMANDS['/recruit'],nil)
    s:SetGuildRunAt('ad','Blue Traders','ON_DEMAND');assert(SLASH_COMMANDS['/recruit'])
end)
test('promotion dates live on cards and Next Send is active-only',function()
    f.reset();schedule();local row=s:GetRepeatStatusPanelRows()[1]
    assert(row.promotionText:find('2026-10-08',1,true));assert(row.promotionText:find('EDT',1,true))
    assert(s:GetRepeatCardTimingText(row):find('Next Send:',1,true))
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');row=s:GetRepeatStatusPanelRows()[1]
    assert(not s:GetRepeatCardTimingText(row):find('Next',1,true));assert(row.promotionText)
end)
test('empty sections collapse, new content expands, clicks remain respected',function()
    f.reset();s.statusSectionStates={}
    eq(s:GetStatusSectionExpanded('auto',false),false)
    eq(s:GetStatusSectionExpanded('repeat',false),false)
    eq(s:GetStatusSectionExpanded('repeat',true),true)
    s:ToggleStatusSection('repeat');eq(s:GetStatusSectionExpanded('repeat',true),false)
    eq(s:GetStatusSectionExpanded('repeat',false),false)
    eq(s:GetStatusSectionExpanded('repeat',true),true)
end)
test('ordinary repeat begins by command, can pause and resume, then hides when off',function()
    f.reset();f.entry('a','ad','Amber Traders','Ordinary notice','Guild');s:SetGuildReminderMinutes('ad','Amber Traders',5)
    eq(#s:GetRepeatStatusPanelRows(),0);s:RegisterDynamicCommands();SLASH_COMMANDS['/recruit']('1')
    assert(s.pendingRestoreState);eq(#s:GetRepeatStatusPanelRows(),1)
    local text=s.pendingRestoreState.rawExpectedText;CHAT_SYSTEM:GetEditControl():SetText('')
    s:HandleRestoreWatcherChatMessage(2,CHAT_CHANNEL_GUILD_1,'My Character',text,false,'@Me')
    assert(s:IsReminderAutomationActive('ad','Amber Traders'))
    eq(s:GetReminderNextTriggerAt('ad','Amber Traders'),now+300)
    local timer=assert(EVENT_MANAGER.updates[s:GetReminderTimerName('ad','Amber Traders')])
    now=now+300;timer.callback();assert(s.pendingRestoreState)
    eq(s.pendingRestoreState.metadata.reminderRepeat,true)
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');assert(s:GetRepeatStatusPanelRows()[1].statusText:find('Paused',1,true)==1)
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');eq(#s:GetRepeatStatusPanelRows(),0)
end)
test('actual panel refresh collapses empty bodies, nests dates, uses buttons and keeps viewport inside',function()
    f.reset();s.statusPanel=nil;s.statusSectionStates={};s.statusPanelVisible=true
    TOPLEFT='TOPLEFT';TOPRIGHT='TOPRIGHT';BOTTOMLEFT='BOTTOMLEFT';BOTTOMRIGHT='BOTTOMRIGHT';MOUSE_BUTTON_INDEX_LEFT=1
    local function control(name,parent)
        local c={name=name,parent=parent,width=0,height=0,text='',hidden=false,handlers={},children={}}
        function c:GetText() return self.text end
        function c:SetText(t) self.text=t end
        function c:SetDimensions(w,h) self.width,self.height=w,h end
        function c:SetWidth(w) self.width=w end
        function c:SetHeight(h) self.height=h end
        function c:GetWidth() return self.width end
        function c:GetHeight() return self.height end
        function c:GetTop()
            local a=rawget(self,'anchor')
            if not a then return rawget(self,'parent') and self.parent:GetTop() or 0 end
            return a.relative:GetTop()+(a.point==BOTTOMLEFT and a.relative:GetHeight() or 0)+a.y
        end
        function c:GetBottom() return self:GetTop()+self.height end
        function c:GetLeft() return rawget(self,'parent') and self.parent:GetLeft() or 0 end
        function c:GetRight() return self:GetLeft()+self.width end
        function c:SetAnchor(_,relative,point,_,y) self.anchor={relative=relative or self.parent,point=point,y=y or 0} end
        function c:ClearAnchors() self.anchor=nil end
        function c:IsHidden() return self.hidden end
        function c:SetHidden(v) self.hidden=v end
        function c:GetTextDimensions() local _,n=self.text:gsub('\n','');return #self.text*7,16*(n+1) end
        function c:SetHandler(k,fn) self.handlers[k]=fn end
        function c:GetHandler(k) return self.handlers[k] end
        function c:GetNamedChild(k) if not self.children[k] then self.children[k]=control(self.name..k,self) end;return self.children[k] end
        return setmetatable(c,{__index=function() return function() end end})
    end
    GuiRoot=control('Root');GuiRoot:SetDimensions(1920,1080)
    WINDOW_MANAGER={}
    function WINDOW_MANAGER:CreateTopLevelWindow(name) return control(name,GuiRoot) end
    function WINDOW_MANAGER:CreateControl(name,parent) return control(name,parent) end
    function WINDOW_MANAGER:CreateControlFromVirtual(name,parent,template) local c=control(name,parent);c.template=template;return c end
    local p=s:CreateStatusPanel();p:SetHidden(false);s:RefreshStatusPanel()
    assert(p.footerLabel:IsHidden());assert(p.repeatScroll:IsHidden())
    schedule();s:RefreshStatusPanel();local row=p.repeatRows[1]
    assert(row.statusLabel:GetText():find('Promotion:',1,true))
    assert(not p.footerLabel:GetText():find('recruit',1,true),'summary must not duplicate schedule cards')
    eq(row.toggleButton.template,'ZO_DefaultButton')
    assert(row.timingLabel:GetText():find('Next Send:',1,true))
    local _,height=s:GetStatusPanelTargetSize(nil,{})
    assert(p.repeatScroll:GetBottom()-p:GetTop()<height,'viewport must fit with bottom padding')
    assert(row:GetWidth()<=p.repeatScroll:GetWidth()-32,'cards must reserve scrollbar space')
    p.repeatHeader:GetHandler('OnMouseUp')(p.repeatHeader,1,true)
    assert(p.repeatScroll:IsHidden())
    p.repeatHeader:GetHandler('OnMouseUp')(p.repeatHeader,1,true)
    assert(not p.repeatScroll:IsHidden())
    s:ToggleReminderAutomationFromStatusPanel('ad','Amber Traders');s:RefreshStatusPanel()
    assert(not p.repeatRows[1].timingLabel:GetText():find('Next',1,true))
    s:SetGuildAutoPopulateOnZone('other','Blue Traders',true);s:SetActiveAutoPopulate('other','Blue Traders');s:RefreshStatusPanel()
    assert(not p.footerLabel:IsHidden(),'active Auto section expands')
    p.statusLabel:GetHandler('OnMouseUp')(p.statusLabel,1,true);assert(p.footerLabel:IsHidden())
    p.statusLabel:GetHandler('OnMouseUp')(p.statusLabel,1,true);assert(not p.footerLabel:IsHidden())
    s:ClearActiveAutoPopulate();s:RefreshStatusPanel();assert(p.footerLabel:IsHidden())
    s.statusPanel=nil;s.statusPanelVisible=false
end)
local failures=0
for _,t in ipairs(tests) do local ok,err=pcall(t[2]);if ok then print('PASS '..t[1]) else failures=failures+1;print('FAIL '..t[1]..': '..tostring(err)) end end
assert(failures==0,tostring(failures)..' status layout tests failed')
