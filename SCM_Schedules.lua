SmartChatMsg = SmartChatMsg or {}
local phases = {"ANY", "BEFORE", "DAY", "LIVE"}
local function positiveInteger(value)
    value = tonumber(value)
    return value and value > 0 and value < math.huge and value == math.floor(value) and value or nil
end

function SmartChatMsg:NormalizeSchedule(data)
    if type(data) ~= "table" then return nil, "Schedule not configured." end
    local result = {enabled=data.enabled == true, paused=data.paused == true, timeZone="America/New_York",
        delivery=data.delivery, intervalMinutes=positiveInteger(data.intervalMinutes), messagePhases={}, phaseIntervals={}}
    if result.delivery ~= "REPEAT" and result.delivery ~= "ZONE" then return nil,"Choose Repeat or Zone delivery." end
    if not result.intervalMinutes then return nil,"Enter a positive whole-number interval in minutes." end
    for _, name in ipairs({"start", "event", "end"}) do
        local date, time = self:Trim(data[name.."Date"] or ""), self:Trim(data[name.."Time"] or "")
        local fold = data[name.."Fold"]
        local utc, reason = self:ParseEasternDateTime(date,time,fold)
        if not utc then return nil,name..": "..reason end
        result[name.."Date"],result[name.."Time"],result[name.."Fold"] = date,time,fold
        result[name == "start" and "startsAtUtc" or name == "end" and "endsAtUtc" or "eventAtUtc"] = utc
    end
    if result.startsAtUtc > result.eventAtUtc or result.eventAtUtc >= result.endsAtUtc then
        return nil,"Schedule start must be at/before the event, and schedule end must be after the event."
    end
    for id, assignments in pairs(type(data.messagePhases) == "table" and data.messagePhases or {}) do
        if type(id) == "string" and type(assignments) == "table" then
            result.messagePhases[id]={}
            for _, phase in ipairs(phases) do result.messagePhases[id][phase]=assignments[phase] == true end
        end
    end
    for _, phase in ipairs({"BEFORE","DAY","LIVE"}) do
        local raw = type(data.phaseIntervals) == "table" and data.phaseIntervals[phase] or nil
        if raw ~= nil and raw ~= "" then
            local interval=positiveInteger(raw)
            if not interval then return nil,phase..": interval must be a positive whole number or blank." end
            result.phaseIntervals[phase]=interval
        end
    end
    result.nextDueAt = positiveInteger(data.nextDueAt)
    result.nextDuePhase = data.nextDuePhase
    return result
end

function SmartChatMsg:GetGuildSchedule(commandId,guildName)
    local settings=self:GetCommandGuildSettings(commandId,guildName,false)
    return settings and settings.schedule or nil
end

function SmartChatMsg:SaveGuildSchedule(commandId,guildName,draft)
    if not self:GetCommandById(commandId) or not self:GetGuildSlotByName(guildName) then
        return false,"Select an available command and guild."
    end
    local schedule,reason=self:NormalizeSchedule(draft)
    if not schedule then return false,reason end
    if schedule.enabled and schedule.delivery=="ZONE" then
        for id,byGuild in pairs(self.savedVars.commandGuildSettings or {}) do
            for key,settings in pairs(byGuild) do
                local other=settings.schedule
                if settings.runAt=="SCHEDULED" and other and other.enabled and other.delivery=="ZONE"
                    and (id~=commandId or key~=self:NormalizeKey(guildName)) then
                    return false,"Only one enabled scheduled Zone combination is supported. Disable the other schedule first."
                end
            end
        end
    end
    local settings=self:GetCommandGuildSettings(commandId,guildName,true)
    if self.StopScheduledDelivery then self:StopScheduledDelivery(commandId,guildName) end
    local active=self.GetActiveAutoPopulate and self:GetActiveAutoPopulate()
    if active and active.commandId==commandId and self:StringsEqualIgnoreCase(active.guildName,guildName) then self:ClearActiveAutoPopulate() end
    settings.schedule,settings.runAt=schedule,"SCHEDULED"
    if self.TickSchedules then self:TickSchedules() end
    return true
end

function SmartChatMsg:GetGuildScheduleState(commandId,guildName,utc)
    if self:GetGuildRunAt(commandId,guildName)~="SCHEDULED" then return "ON_DEMAND" end
    local schedule=self:GetGuildSchedule(commandId,guildName)
    if not schedule then return "UNCONFIGURED" end
    if not schedule.enabled then return "DISABLED" end
    utc=utc or GetTimeStamp()
    if utc>=schedule.endsAtUtc then return "FINISHED" end
    if schedule.paused then return "PAUSED" end
    if utc<schedule.startsAtUtc then return "WAITING" end
    return "RUNNING",self:GetSchedulePhase(schedule,utc)
end

function SmartChatMsg:GetScheduleIntervalMinutes(commandId,guildName)
    local schedule=self:GetGuildSchedule(commandId,guildName)
    if not schedule then return nil end
    local phase=self:GetSchedulePhase(schedule,GetTimeStamp())
    return schedule.phaseIntervals[phase] or schedule.intervalMinutes
end

function SmartChatMsg:GetScheduledMessageEntries(commandId,guildName)
    local state,phase=self:GetGuildScheduleState(commandId,guildName)
    if state~="RUNNING" then return {} end
    local schedule=self:GetGuildSchedule(commandId,guildName)
    local result={}
    for _,entry in ipairs(self:GetMessageEntriesForCommandAndGuild(commandId,guildName)) do
        local assigned=schedule.messagePhases[entry.id]
        if not assigned or assigned.ANY or assigned[phase] then result[#result+1]=entry end
    end
    return result
end

function SmartChatMsg:ExportScheduleRecords()
    local lines={}
    local function encode(fields)
        for index,value in ipairs(fields) do fields[index]=self:EscapeImportExportField(value) end
        return table.concat(fields,"|")
    end
    for id,byGuild in pairs(self.savedVars.commandGuildSettings or {}) do
        for guild,settings in pairs(byGuild) do
            local s=settings.schedule
            if s then
                local fields={"SCHEDULE_V1",id,guild,s.enabled and "1" or "0",s.paused and "1" or "0",s.delivery,tostring(s.intervalMinutes)}
                for _,name in ipairs({"start","event","end"}) do
                    fields[#fields+1]=s[name.."Date"]; fields[#fields+1]=s[name.."Time"]; fields[#fields+1]=s[name.."Fold"] or ""
                end
                for _,phase in ipairs({"BEFORE","DAY","LIVE"}) do fields[#fields+1]=tostring(s.phaseIntervals[phase] or "") end
                lines[#lines+1]=encode(fields)
                for messageId,assigned in pairs(s.messagePhases) do
                    local row={"SCHEDULEMESSAGE_V1",id,guild,messageId}
                    for _,phase in ipairs(phases) do row[#row+1]=assigned[phase] and "1" or "0" end
                    lines[#lines+1]=encode(row)
                end
            end
        end
    end
    return lines
end

function SmartChatMsg:ImportScheduleRecords(records,imported)
    local candidates={}
    local commands={}
    for _,command in ipairs(imported.commands) do commands[command.id]=true end
    for _,row in ipairs(records) do
        for i,value in ipairs(row) do row[i]=self:UnescapeImportExportField(value) end
        local kind,id,guild=row[1],row[2],self:NormalizeKey(row[3])
        if commands[id] and guild then
            candidates[id]=candidates[id] or {}; candidates[id][guild]=candidates[id][guild] or {messagePhases={}}
            local d=candidates[id][guild]
            if kind=="SCHEDULE_V1" then
                d.enabled,d.paused,d.delivery,d.intervalMinutes=row[4]=="1",row[5]=="1",row[6],row[7]
                local index=8
                for _,name in ipairs({"start","event","end"}) do
                    d[name.."Date"],d[name.."Time"],d[name.."Fold"]=row[index],row[index+1],row[index+2]; index=index+3
                end
                d.phaseIntervals={BEFORE=row[17],DAY=row[18],LIVE=row[19]}
            else
                if not row[4] or row[4]=="" then return false,"Imported schedule message is missing its ID." end
                d.messagePhases[row[4]]={ANY=row[5]=="1",BEFORE=row[6]=="1",DAY=row[7]=="1",LIVE=row[8]=="1"}
            end
        end
    end
    local enabledZones=0
    for id,byGuild in pairs(candidates) do
        for guild,draft in pairs(byGuild) do
            local schedule,reason=self:NormalizeSchedule(draft)
            if not schedule then return false,"Imported schedule: "..reason end
            if schedule.enabled and schedule.delivery=="ZONE" then enabledZones=enabledZones+1 end
            if enabledZones>1 then return false,"Import contains more than one enabled scheduled Zone combination." end
            imported.commandGuildSettings[id]=imported.commandGuildSettings[id] or {}
            imported.commandGuildSettings[id][guild]=imported.commandGuildSettings[id][guild] or {}
            imported.commandGuildSettings[id][guild].schedule=schedule
        end
    end
    return true
end
