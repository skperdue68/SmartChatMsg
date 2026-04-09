SmartChatMsg = SmartChatMsg or {}

SmartChatMsg.name = "SmartChatMsg"
SmartChatMsg.dynamicCommands = SmartChatMsg.dynamicCommands or {}
SmartChatMsg.commandReminderTimers = SmartChatMsg.commandReminderTimers or {}
SmartChatMsg.activeReminderStates = SmartChatMsg.activeReminderStates or {}
SmartChatMsg.lastKnownZoneId = SmartChatMsg.lastKnownZoneId or nil
SmartChatMsg.hasSeenInitialPlayerActivated = SmartChatMsg.hasSeenInitialPlayerActivated or false
SmartChatMsg.pendingRestoreState = SmartChatMsg.pendingRestoreState or nil
SmartChatMsg.restoreWatcherEventName = SmartChatMsg.name .. "_RestoreWatcher"
SmartChatMsg.restoreWatcherTimeoutName = SmartChatMsg.name .. "_RestoreWatcherTimeout"
SmartChatMsg.debugEnabled = SmartChatMsg.debugEnabled == true
SmartChatMsg.logger = SmartChatMsg.logger or nil

SmartChatMsg.statusPanel = SmartChatMsg.statusPanel or nil
SmartChatMsg.statusPanelVisible = SmartChatMsg.statusPanelVisible == true
SmartChatMsg.statusPanelRefreshName = SmartChatMsg.name .. "_StatusPanelRefresh"
SmartChatMsg.startupQueue = SmartChatMsg.startupQueue or {}
SmartChatMsg.startupQueueCurrent = SmartChatMsg.startupQueueCurrent or nil
SmartChatMsg.startupQueueInitialized = SmartChatMsg.startupQueueInitialized == true
SmartChatMsg.startupQueueDelayName = SmartChatMsg.name .. "_StartupQueueDelay"

SmartChatMsg.autoPopulateTestHouseZoneId = SmartChatMsg.autoPopulateTestHouseZoneId or 1109
SmartChatMsg.infiniteArchiveZoneId = SmartChatMsg.infiniteArchiveZoneId or 1463


function SmartChatMsg:DebugLog(message)
    if not self.debugEnabled then
        return
    end

    local text = tostring(message)

    if self.logger and self.logger.Debug then
        self.logger:Debug(text)
    end

    d("[SmartChatMsg] " .. text)
end

function SmartChatMsg:FormatChatChannelInfo(channelInfo)
    if not channelInfo then
        return "nil"
    end

    return string.format(
        "short=%s kind=%s index=%s id=%s target=%s",
        tostring(channelInfo.short or "unknown"),
        tostring(channelInfo.kind or "unknown"),
        tostring(channelInfo.index or "-"),
        tostring(channelInfo.id or "nil"),
        tostring(channelInfo.target or "none")
    )
end

function SmartChatMsg:BuildSlashCommandName(commandName)
    if type(commandName) ~= "string" then
        return nil
    end

    local trimmed = self:Trim(commandName)
    if trimmed == "" then
        return nil
    end

    local cleaned = zo_strlower(trimmed):gsub("[^%w]", "")
    if cleaned == "" then
        return nil
    end

    return "/" .. cleaned
end

function SmartChatMsg:GetCurrentTimeTokenValue()
    local hour = tonumber(os.date("%H")) or 12
    if hour < 12 then
        return "morning"
    elseif hour < 18 then
        return "afternoon"
    end

    return "evening"
end

function SmartChatMsg:GetCurrentZoneName()
    local zoneName = GetUnitZone("player")
    zoneName = self:Trim(zoneName or "")
    if zoneName ~= "" then
        return zoneName
    end

    local zoneId = GetZoneId(GetUnitZoneIndex("player"))
    if zoneId and zoneId ~= 0 and GetZoneNameById then
        zoneName = self:Trim(GetZoneNameById(zoneId) or "")
        if zoneName ~= "" then
            return zoneName
        end
    end

    return nil
end

function SmartChatMsg:ApplyMessageSubstitutions(text, commandId, guildName)
    local result = tostring(text or "")

    local substitutions = {
        ["time"] = self:GetCurrentTimeTokenValue(),
        ["guild"] = self:Trim(guildName or ""),
        ["zone"] = self:GetCurrentZoneName() or "",
    }

    result = result:gsub("%%([%a]+)%%", function(tokenName)
        local normalizedToken = zo_strlower(tokenName or "")
        local replacement = substitutions[normalizedToken]
        if replacement ~= nil and replacement ~= "" then
            return replacement
        end

        return "%" .. tostring(tokenName or "") .. "%"
    end)

    return result
end


function SmartChatMsg:ShowCommandTestNotification(commandName, parameterValue)
    local message = string.format("SmartChatMsg test: command %s called with parameter %s", tostring(commandName), tostring(parameterValue))

    d(message)

    if CENTER_SCREEN_ANNOUNCE then
        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, message)
    end
end

function SmartChatMsg:ShowStatusMessage(message)
    if CENTER_SCREEN_ANNOUNCE then
        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, tostring(message or ""))
    else
        d(tostring(message or ""))
    end
end

function SmartChatMsg:GetSlashCommandDisplayName(commandId, fallbackSlashCommandName)
    local commandName = self:GetCommandNameById(commandId)
    local slashCommandName = self:BuildSlashCommandName(commandName or "") or fallbackSlashCommandName or "/command"
    return slashCommandName
end

function SmartChatMsg:GetGuildSlotByName(guildName)
    if type(guildName) ~= "string" or guildName == "" then
        return nil
    end

    for guildIndex = 1, 5 do
        local guildId = GetGuildId(guildIndex)
        if guildId and guildId ~= 0 then
            local currentGuildName = GetGuildName(guildId)
            if currentGuildName and self:StringsEqualIgnoreCase(currentGuildName, guildName) then
                return guildIndex
            end
        end
    end

    return nil
end

function SmartChatMsg:GetMessageEntriesForCommandAndGuild(commandId, guildName)
    local results = {}

    if type(commandId) ~= "string" or commandId == "" then
        return results
    end

    if type(guildName) ~= "string" or guildName == "" then
        return results
    end

    for _, entry in ipairs(self.savedVars.messages or {}) do
        if type(entry) == "table" and entry.commandId == commandId then
            local entryGuildName = entry.guildName

            if (not entryGuildName or entryGuildName == "") and entry.guildIndex then
                entryGuildName = self:GetGuildNameByIndex(entry.guildIndex)
            end

            if entryGuildName and self:StringsEqualIgnoreCase(entryGuildName, guildName) then
                table.insert(results, entry)
            end
        end
    end

    return results
end


function SmartChatMsg:GetMessageUsageTimestamp(entry)
    local value = type(entry) == "table" and entry.lastUsedAt or nil
    if type(value) ~= "number" or value < 0 then
        return nil
    end

    return math.floor(value)
end

function SmartChatMsg:GetMessageUseCount(entry)
    local value = type(entry) == "table" and entry.useCount or nil
    if type(value) ~= "number" or value < 0 then
        return 0
    end

    return math.floor(value)
end

function SmartChatMsg:SelectWeightedMessageEntry(messages)
    if type(messages) ~= "table" or #messages == 0 then
        return nil
    end

    local ranked = {}
    for _, entry in ipairs(messages) do
        if type(entry) == "table" then
            table.insert(ranked, entry)
        end
    end

    if #ranked == 0 then
        return nil
    end

    table.sort(ranked, function(a, b)
        local aLastUsed = self:GetMessageUsageTimestamp(a)
        local bLastUsed = self:GetMessageUsageTimestamp(b)

        if aLastUsed == nil and bLastUsed ~= nil then
            return true
        end

        if aLastUsed ~= nil and bLastUsed == nil then
            return false
        end

        if aLastUsed ~= bLastUsed then
            return (aLastUsed or 0) < (bLastUsed or 0)
        end

        local aUseCount = self:GetMessageUseCount(a)
        local bUseCount = self:GetMessageUseCount(b)

        if aUseCount ~= bUseCount then
            return aUseCount < bUseCount
        end

        return tostring(a.id or "") < tostring(b.id or "")
    end)

    local totalWeight = 0
    for index = 1, #ranked do
        totalWeight = totalWeight + (#ranked - index + 1)
    end

    local roll = zo_random(1, totalWeight)
    local runningWeight = 0

    for index, entry in ipairs(ranked) do
        runningWeight = runningWeight + (#ranked - index + 1)
        if roll <= runningWeight then
            return entry
        end
    end

    return ranked[1]
end

function SmartChatMsg:MarkMessageEntryUsed(entry)
    if type(entry) ~= "table" then
        return
    end

    entry.useCount = self:GetMessageUseCount(entry) + 1
    entry.lastUsedAt = GetTimeStamp()
end

function SmartChatMsg:MarkCommandUsed(commandId, guildName, paramText, guildIndex)
    local command = self:GetCommandById(commandId)
    if not command then
        self:DebugLog("Reminder debug: MarkCommandUsed aborted, command not found for commandId=" .. tostring(commandId))
        return
    end

    local timestamp = GetTimeStamp()
    command.lastUsedAt = timestamp
    self:SetGuildLastUsedState(commandId, guildName, timestamp, paramText, guildIndex)

    self:DebugLog(string.format(
        "Reminder debug: MarkCommandUsed commandId=%s guildName=%s guildIndex=%s lastUsedAt=%s paramText=%s",
        tostring(commandId),
        tostring(guildName),
        tostring(guildIndex),
        tostring(timestamp),
        tostring(paramText or "")
    ))
end

function SmartChatMsg:GetReminderTimerName(commandId, guildName)
    if type(commandId) ~= "string" or commandId == "" then
        return nil
    end

    local guildKey = self:NormalizeKey(guildName) or "default"
    return "SmartChatMsgReminder_" .. commandId .. "_" .. guildKey
end

function SmartChatMsg:GetReminderStateKey(commandId, guildName)
    if type(commandId) ~= "string" or commandId == "" then
        return nil
    end

    local guildKey = self:NormalizeKey(guildName)
    if not guildKey then
        return nil
    end

    return commandId .. "::" .. guildKey
end

function SmartChatMsg:SetReminderAutomationActive(commandId, guildName, isActive)
    local stateKey = self:GetReminderStateKey(commandId, guildName)
    if not stateKey then
        return
    end

    if isActive then
        self.activeReminderStates[stateKey] = true
    else
        self.activeReminderStates[stateKey] = nil
    end
end

function SmartChatMsg:IsReminderAutomationActive(commandId, guildName)
    local stateKey = self:GetReminderStateKey(commandId, guildName)
    return stateKey and self.activeReminderStates[stateKey] == true or false
end

function SmartChatMsg:DeactivateReminderAutomation(commandId, guildName, reason)
    self:SetReminderAutomationActive(commandId, guildName, false)
    self:ClearCommandReminder(commandId, guildName)

    local pendingState = self.pendingRestoreState
    local metadata = pendingState and pendingState.metadata or nil
    if type(metadata) == "table"
        and metadata.reminderRepeat == true
        and metadata.commandId == commandId
        and self:StringsEqualIgnoreCase(metadata.guildName or "", guildName or "") then
        self:ClearPendingRestoreState(reason or "reminder automation deactivated")
    end
end

function SmartChatMsg:ClearCommandReminder(commandId, guildName)
    local timerName = self:GetReminderTimerName(commandId, guildName)
    if timerName then
        self:DebugLog("Reminder debug: clearing timer " .. tostring(timerName))
        EVENT_MANAGER:UnregisterForUpdate(timerName)
    else
        self:DebugLog("Reminder debug: ClearCommandReminder had no timerName for commandId=" .. tostring(commandId))
    end
end

function SmartChatMsg:PlayPopulateSound(commandId, guildName)
    local soundKey = self:GetGuildPopulateSound(commandId, guildName)
    if soundKey == "NONE" then
        return
    end

    if type(SOUNDS) == "table" and SOUNDS[soundKey] then
        PlaySound(SOUNDS[soundKey])
    end
end

function SmartChatMsg:HandleReminderPopulateSuccess(metadata)
    if type(metadata) ~= "table" then
        return
    end

    self:DebugLog(string.format(
        "Reminder debug: confirmed sent by watcher for commandId=%s guildName=%s",
        tostring(metadata.commandId),
        tostring(metadata.guildName)
    ))

    self:MarkCommandUsed(metadata.commandId, metadata.guildName, metadata.paramText, metadata.guildIndex)
    self:ScheduleCommandReminder(metadata.commandId, metadata.guildName)
end

function SmartChatMsg:HandleReminderPopulateTimeout(metadata)
    if type(metadata) ~= "table" then
        return
    end

    if not self:IsReminderAutomationActive(metadata.commandId, metadata.guildName) then
        self:DebugLog("Reminder debug: timeout ignored because reminder automation is inactive")
        return
    end

    local commandId = metadata.commandId
    local guildName = metadata.guildName
    local expectedLastUsedAt = metadata.lastUsedAt

    if type(commandId) ~= "string" or commandId == "" or type(guildName) ~= "string" or guildName == "" then
        return
    end

    local currentLastUsedAt = self:GetGuildLastUsedAt(commandId, guildName)
    self:DebugLog(string.format(
        "Reminder debug: timeout handling commandId=%s guildName=%s expectedLastUsedAt=%s currentLastUsedAt=%s",
        tostring(commandId),
        tostring(guildName),
        tostring(expectedLastUsedAt),
        tostring(currentLastUsedAt)
    ))

    if currentLastUsedAt ~= expectedLastUsedAt then
        self:DebugLog(string.format(
            "Reminder debug: timeout retry skipped because lastUsedAt changed for commandId=%s guildName=%s",
            tostring(commandId),
            tostring(guildName)
        ))
        return
    end

    local retryMinutes = self:GetGuildEffectiveReminderRetryMinutes(commandId, guildName) or 0
    local timerName = self:GetReminderTimerName(commandId, guildName)
    if not timerName then
        return
    end

    if retryMinutes <= 0 then
        self:DebugLog(string.format(
            "Reminder debug: retry disabled, resuming repeat-after schedule commandId=%s guildName=%s",
            tostring(commandId),
            tostring(guildName)
        ))
        self:ScheduleCommandReminder(commandId, guildName)
        return
    end

    local delayMs = retryMinutes * 60 * 1000
    self:DebugLog(string.format(
        "Reminder debug: scheduling retry timer timerName=%s commandId=%s guildName=%s retryMinutes=%s delayMs=%s",
        tostring(timerName),
        tostring(commandId),
        tostring(guildName),
        tostring(retryMinutes),
        tostring(delayMs)
    ))

    EVENT_MANAGER:RegisterForUpdate(timerName, delayMs, function()
        self:DebugLog(string.format(
            "Reminder debug: retry timer fired timerName=%s commandId=%s guildName=%s",
            tostring(timerName),
            tostring(commandId),
            tostring(guildName)
        ))

        EVENT_MANAGER:UnregisterForUpdate(timerName)
        self:TriggerReminderPopulate(commandId, guildName, expectedLastUsedAt, "retry")
    end)
end

function SmartChatMsg:TriggerReminderPopulate(commandId, guildName, expectedLastUsedAt, reason)
    if not self:IsReminderAutomationActive(commandId, guildName) then
        self:DebugLog("Reminder debug: populate skipped because reminder automation is inactive")
        return
    end

    local command = self:GetCommandById(commandId)
    if not command then
        self:DebugLog("Reminder debug: populate aborted, command not found for commandId=" .. tostring(commandId))
        return
    end

    if not self:GetGuildReminderMinutes(commandId, guildName) then
        self:DebugLog("Reminder debug: populate aborted, repeat-after is not configured for commandId=" .. tostring(commandId))
        return
    end

    local currentLastUsedAt = self:GetGuildLastUsedAt(commandId, guildName)
    self:DebugLog(string.format(
        "Reminder debug: attempting populate commandId=%s guildName=%s reason=%s expectedLastUsedAt=%s currentLastUsedAt=%s",
        tostring(commandId),
        tostring(guildName),
        tostring(reason or "initial"),
        tostring(expectedLastUsedAt),
        tostring(currentLastUsedAt)
    ))

    if currentLastUsedAt ~= expectedLastUsedAt then
        self:DebugLog(string.format(
            "Reminder debug: populate skipped because lastUsedAt changed for commandId=%s guildName=%s",
            tostring(commandId),
            tostring(guildName)
        ))
        return
    end

    local metadata = {
        reminderRepeat = true,
        commandId = commandId,
        guildName = guildName,
        lastUsedAt = expectedLastUsedAt,
        paramText = self:GetGuildLastUsedParamText(commandId, guildName),
        guildIndex = self:GetGuildLastUsedGuildIndex(commandId, guildName),
        reason = reason or "initial",
    }

    local ok, err = self:PopulateChatBufferForCommand(commandId, guildName, nil, metadata)
    if not ok then
        self:DebugLog(string.format(
            "Reminder debug: populate failed commandId=%s guildName=%s err=%s",
            tostring(commandId),
            tostring(guildName),
            tostring(err)
        ))
        return
    end

    self:DebugLog(string.format(
        "Reminder debug: populate armed successfully for commandId=%s guildName=%s",
        tostring(commandId),
        tostring(guildName)
    ))
end

function SmartChatMsg:ScheduleCommandReminder(commandId, guildName)
    local command = self:GetCommandById(commandId)
    if not command then
        self:DebugLog("Reminder debug: schedule aborted, command not found for commandId=" .. tostring(commandId))
        return
    end

    local reminderMinutes = self:GetGuildReminderMinutes(commandId, guildName)
    self:ClearCommandReminder(commandId, guildName)

    if not reminderMinutes then
        self:SetReminderAutomationActive(commandId, guildName, false)
        self:DebugLog(string.format(
            "Reminder debug: schedule aborted, no repeat-after configured for commandId=%s commandName=%s guildName=%s",
            tostring(commandId),
            tostring(command.name or "unknown"),
            tostring(guildName)
        ))
        return
    end

    self:SetReminderAutomationActive(commandId, guildName, true)

    local lastUsedAt = self:GetGuildLastUsedAt(commandId, guildName)
    if type(lastUsedAt) ~= "number" or lastUsedAt <= 0 then
        self:DebugLog(string.format(
            "Reminder debug: schedule aborted, invalid lastUsedAt=%s for commandId=%s commandName=%s guildName=%s",
            tostring(lastUsedAt),
            tostring(commandId),
            tostring(command.name or "unknown"),
            tostring(guildName)
        ))
        self:SetReminderAutomationActive(commandId, guildName, false)
        return
    end

    local timerName = self:GetReminderTimerName(commandId, guildName)
    if not timerName then
        self:DebugLog("Reminder debug: schedule aborted, timerName was nil for commandId=" .. tostring(commandId))
        return
    end

    local delayMs = reminderMinutes * 60 * 1000
    self:DebugLog(string.format(
        "Reminder debug: scheduling repeat-after timer timerName=%s commandId=%s commandName=%s guildName=%s repeatAfterMinutes=%s delayMs=%s lastUsedAt=%s",
        tostring(timerName),
        tostring(commandId),
        tostring(command.name or "unknown"),
        tostring(guildName),
        tostring(reminderMinutes),
        tostring(delayMs),
        tostring(lastUsedAt)
    ))

    EVENT_MANAGER:RegisterForUpdate(timerName, delayMs, function()
        self:DebugLog(string.format(
            "Reminder debug: repeat-after timer fired timerName=%s commandId=%s guildName=%s",
            tostring(timerName),
            tostring(commandId),
            tostring(guildName)
        ))

        EVENT_MANAGER:UnregisterForUpdate(timerName)
        self:TriggerReminderPopulate(commandId, guildName, lastUsedAt, "initial")
    end)
end

function SmartChatMsg:ClearActiveAutoPopulate()
    self.savedVars.activeAutoPopulate = nil
end

function SmartChatMsg:ToggleOffActiveAutoPopulateIfMatching(commandId, guildName)
    local active = self:GetActiveAutoPopulate()
    if not active then
        return false
    end

    if active.commandId == commandId and self:StringsEqualIgnoreCase(active.guildName, guildName) then
        local pendingState = self.pendingRestoreState
        local metadata = pendingState and pendingState.metadata or nil
        if type(metadata) == "table"
            and metadata.autoPopulate == true
            and metadata.commandId == commandId
            and self:StringsEqualIgnoreCase(metadata.guildName or "", guildName or "") then
            self:ClearPendingRestoreState("matching auto populate toggled off")
        end

        self:ClearActiveAutoPopulate()
        if self.statusPanelVisible then
            self:RefreshStatusPanel()
        end
        return true
    end

    return false
end

function SmartChatMsg:GetPreciseChatChannelInfo()
    if not CHAT_SYSTEM then
        return nil
    end

    local cd, target = CHAT_SYSTEM:GetCurrentChannelData()
    if not cd then
        return nil
    end

    local id = cd.id
    local info = {
        id = id,
        target = target,
        kind = "unknown",
        index = nil,
        short = "unknown",
    }

    if id == CHAT_CHANNEL_ZONE then
        info.kind = "zone"
        info.short = "zone"
    elseif id == CHAT_CHANNEL_PARTY then
        info.kind = "group"
        info.short = "group"
    elseif id == CHAT_CHANNEL_SAY then
        info.kind = "say"
        info.short = "say"
    elseif id == CHAT_CHANNEL_YELL then
        info.kind = "yell"
        info.short = "yell"
    elseif id == CHAT_CHANNEL_EMOTE then
        info.kind = "emote"
        info.short = "emote"
    elseif id == CHAT_CHANNEL_WHISPER or id == CHAT_CHANNEL_WHISPER_SENT then
        info.kind = "tell"
        info.short = "tell"
    elseif id >= CHAT_CHANNEL_GUILD_1 and id <= CHAT_CHANNEL_GUILD_5 then
        local index = id - CHAT_CHANNEL_GUILD_1 + 1
        info.kind = "guild"
        info.index = index
        info.short = "g" .. index
    elseif id >= CHAT_CHANNEL_OFFICER_1 and id <= CHAT_CHANNEL_OFFICER_5 then
        local index = id - CHAT_CHANNEL_OFFICER_1 + 1
        info.kind = "officer"
        info.index = index
        info.short = "o" .. index
    end

    return info
end

function SmartChatMsg:RestoreChatChannel(channelInfo)
    if not channelInfo or not CHAT_SYSTEM or not channelInfo.id then
        self:DebugLog("RestoreChatChannel aborted: missing channel info")
        return false
    end

    self:DebugLog("Restoring chat channel: " .. self:FormatChatChannelInfo(channelInfo))
    CHAT_SYSTEM:SetChannel(channelInfo.id, channelInfo.target)
    return true
end

function SmartChatMsg:ClearPendingChatBuffer()
    self:DebugLog("ClearPendingChatBuffer start")

    local cleared = false

    if CHAT_SYSTEM and CHAT_SYSTEM.textEntry and CHAT_SYSTEM.textEntry.EditControl then
        local editControl = CHAT_SYSTEM.textEntry.EditControl

        if editControl.SetText then
            editControl:SetText("")
            cleared = true
        end

        if editControl.LoseFocus then
            editControl:LoseFocus()
        end
    end

    if CHAT_SYSTEM and CHAT_SYSTEM.textEntry then
        if CHAT_SYSTEM.textEntry.SetText then
            CHAT_SYSTEM.textEntry:SetText("")
            cleared = true
        end

        if CHAT_SYSTEM.textEntry.LoseFocus then
            CHAT_SYSTEM.textEntry:LoseFocus()
        end
    end

    if ZO_ChatWindowTextEntryEditBox then
        if ZO_ChatWindowTextEntryEditBox.SetText then
            ZO_ChatWindowTextEntryEditBox:SetText("")
            cleared = true
        end

        if ZO_ChatWindowTextEntryEditBox.LoseFocus then
            ZO_ChatWindowTextEntryEditBox:LoseFocus()
        end
    end

    if CHAT_SYSTEM and CHAT_SYSTEM.Maximize then
        CHAT_SYSTEM:Maximize()
    end

    if CHAT_SYSTEM and CHAT_SYSTEM.Minimize then
        CHAT_SYSTEM:Minimize()
    end

    self:DebugLog("ClearPendingChatBuffer result=" .. tostring(cleared))
    return cleared
end


function SmartChatMsg:NormalizeChatText(text)
    local value = self:Trim(text or "")
    value = zo_strlower(value)

    value = value:gsub("|c%x%x%x%x%x%x", "")
    value = value:gsub("|r", "")
    value = value:gsub("[%c]", " ")
    value = value:gsub("[%p]", " ")
    value = value:gsub("%s+", " ")

    return self:Trim(value)
end

function SmartChatMsg:GetLevenshteinDistance(a, b)
    a = a or ""
    b = b or ""

    local lenA = #a
    local lenB = #b

    if lenA == 0 then
        return lenB
    end

    if lenB == 0 then
        return lenA
    end

    local matrix = {}

    for i = 0, lenA do
        matrix[i] = {}
        matrix[i][0] = i
    end

    for j = 0, lenB do
        matrix[0][j] = j
    end

    for i = 1, lenA do
        local charA = a:sub(i, i)

        for j = 1, lenB do
            local cost = (charA == b:sub(j, j)) and 0 or 1

            local deletion = matrix[i - 1][j] + 1
            local insertion = matrix[i][j - 1] + 1
            local substitution = matrix[i - 1][j - 1] + cost

            matrix[i][j] = math.min(deletion, insertion, substitution)
        end
    end

    return matrix[lenA][lenB]
end

function SmartChatMsg:GetFuzzyMessageMatchDetails(expectedText, actualText)
    local expected = self:NormalizeChatText(expectedText)
    local actual = self:NormalizeChatText(actualText)

    local details = {
        expected = expected,
        actual = actual,
        matched = false,
        method = "none",
        similarity = 0,
        distance = nil,
    }

    if expected == "" or actual == "" then
        return details
    end

    if expected == actual then
        details.matched = true
        details.method = "exact"
        details.similarity = 1
        details.distance = 0
        return details
    end

    if expected:find(actual, 1, true) or actual:find(expected, 1, true) then
        local shorterLength = math.min(#expected, #actual)
        details.method = "contains"
        details.matched = shorterLength >= math.max(8, math.floor(math.min(#expected, #actual) * 0.8))
        details.similarity = shorterLength / math.max(#expected, #actual)
        return details
    end

    local distance = self:GetLevenshteinDistance(expected, actual)
    local longest = math.max(#expected, #actual)
    local similarity = 1 - (distance / longest)

    details.method = "levenshtein"
    details.distance = distance
    details.similarity = similarity
    details.matched = similarity >= 0.82

    return details
end

function SmartChatMsg:IsFuzzyMessageMatch(expectedText, actualText)
    return self:GetFuzzyMessageMatchDetails(expectedText, actualText).matched
end

function SmartChatMsg:IsOutgoingChatMessageType(messageType)
    if type(messageType) ~= "number" then
        return false
    end

    -- Channel ids
    if messageType == CHAT_CHANNEL_SAY
        or messageType == CHAT_CHANNEL_YELL
        or messageType == CHAT_CHANNEL_EMOTE
        or messageType == CHAT_CHANNEL_PARTY
        or messageType == CHAT_CHANNEL_ZONE
        or messageType == CHAT_CHANNEL_WHISPER
        or messageType == CHAT_CHANNEL_WHISPER_SENT
        or (messageType >= CHAT_CHANNEL_GUILD_1 and messageType <= CHAT_CHANNEL_GUILD_5)
        or (messageType >= CHAT_CHANNEL_OFFICER_1 and messageType <= CHAT_CHANNEL_OFFICER_5) then
        return true
    end

    -- Category ids fallback
    if messageType == CHAT_CATEGORY_SAY
        or messageType == CHAT_CATEGORY_YELL
        or messageType == CHAT_CATEGORY_EMOTE
        or messageType == CHAT_CATEGORY_PARTY
        or messageType == CHAT_CATEGORY_ZONE
        or messageType == CHAT_CATEGORY_WHISPER_SENT
        or messageType == CHAT_CATEGORY_WHISPER
        or messageType == CHAT_CATEGORY_GUILD_1
        or messageType == CHAT_CATEGORY_GUILD_2
        or messageType == CHAT_CATEGORY_GUILD_3
        or messageType == CHAT_CATEGORY_GUILD_4
        or messageType == CHAT_CATEGORY_GUILD_5
        or messageType == CHAT_CATEGORY_OFFICER_1
        or messageType == CHAT_CATEGORY_OFFICER_2
        or messageType == CHAT_CATEGORY_OFFICER_3
        or messageType == CHAT_CATEGORY_OFFICER_4
        or messageType == CHAT_CATEGORY_OFFICER_5 then
        return true
    end

    return false
end

function SmartChatMsg:ClearPendingRestoreState(reason)
    if self.pendingRestoreState then
        self:DebugLog(string.format(
            "Clearing pending restore state reason=%s previousChannel=%s expectedText=%s",
            tostring(reason or "unspecified"),
            self:FormatChatChannelInfo(self.pendingRestoreState.previousChannel),
            tostring(self.pendingRestoreState.expectedText or "")
        ))
    else
        self:DebugLog("ClearPendingRestoreState called with no pending state reason=" .. tostring(reason or "unspecified"))
    end

    self.pendingRestoreState = nil
    EVENT_MANAGER:UnregisterForEvent(self.restoreWatcherEventName, EVENT_CHAT_MESSAGE_CHANNEL)
    EVENT_MANAGER:UnregisterForUpdate(self.restoreWatcherTimeoutName)
end

function SmartChatMsg:HandleRestoreWatcherChatMessage(eventCode, messageType, fromName, text, isCustomerService)
    local state = self.pendingRestoreState
    if not state then
        self:DebugLog("HandleRestoreWatcherChatMessage called without pending state")
        return
    end

    self:DebugLog(string.format(
        "Chat watcher eventCode=%s messageType=%s fromName=%s text=%s",
        tostring(eventCode),
        tostring(messageType),
        tostring(fromName or ""),
        tostring(text or "")
    ))

    if not self:IsOutgoingChatMessageType(messageType) then
        self:DebugLog(string.format("Chat watcher ignored non-outgoing event type=%s text=%s", tostring(messageType), tostring(text or "")))
        return
    end

    local details = self:GetFuzzyMessageMatchDetails(state.expectedText, text or "")
    self:DebugLog(string.format(
        "Watcher saw outgoing message type=%s method=%s matched=%s similarity=%.3f expected=%s actual=%s",
        tostring(messageType),
        tostring(details.method),
        tostring(details.matched),
        tonumber(details.similarity or 0),
        tostring(details.expected),
        tostring(details.actual)
    ))

    if not details.matched then
        return
    end

    local metadata = state.metadata
    if type(metadata) == "table" then
        if type(metadata.selectedEntryId) == "string" and metadata.selectedEntryId ~= "" then
            for _, entry in ipairs(self.savedVars.messages or {}) do
                if type(entry) == "table" and entry.id == metadata.selectedEntryId then
                    self:MarkMessageEntryUsed(entry)
                    break
                end
            end
        end

        if metadata.autoPopulate == true then
            self:DebugLog(string.format(
                "Auto populate debug: confirmed sent by watcher for commandId=%s guildName=%s zoneId=%s",
                tostring(metadata.commandId),
                tostring(metadata.guildName),
                tostring(metadata.zoneId)
            ))
            self:MarkCommandUsed(metadata.commandId, metadata.guildName, metadata.paramText, metadata.guildIndex)
            self:MarkAutoPopulateSent(metadata.commandId, metadata.guildName, metadata.zoneId)
        elseif metadata.reminderRepeat == true then
            self:HandleReminderPopulateSuccess(metadata)
        elseif metadata.commandId and metadata.guildName then
            self:MarkCommandUsed(metadata.commandId, metadata.guildName, metadata.paramText, metadata.guildIndex)
            if self:GetGuildReminderMinutes(metadata.commandId, metadata.guildName) then
                self:ScheduleCommandReminder(metadata.commandId, metadata.guildName)
            end
            if metadata.activateAutoPopulate == true and self:GetGuildAutoPopulateOnZone(metadata.commandId, metadata.guildName) then
                self:SetActiveAutoPopulate(metadata.commandId, metadata.guildName)
            end
        end

        if metadata.startupQueue == true then
            self:HandleStartupQueuePopulateSuccess(metadata)
        end
    end

    self:DebugLog("Watcher matched populated message; restoring previous channel")
    local restored = self:RestoreChatChannel(state.previousChannel)
    self:DebugLog("Restore attempt after watcher match restored=" .. tostring(restored))
    self:ClearPendingRestoreState("watcher matched outgoing message")
end

function SmartChatMsg:GetRestoreWatcherTimeoutSeconds(metadata)
    return self:GetRevertChatSeconds() or 60
end

function SmartChatMsg:ArmPendingRestoreState(previousChannelInfo, expectedText, metadata)
    self:ClearPendingRestoreState("arming new restore state")

    if not previousChannelInfo or not previousChannelInfo.id then
        self:DebugLog("ArmPendingRestoreState skipped: no previous channel info")
        return false
    end

    local normalizedExpected = self:NormalizeChatText(expectedText)
    if normalizedExpected == "" then
        self:DebugLog("ArmPendingRestoreState skipped: expected text normalized to empty")
        return false
    end

    local timeoutSeconds = self:GetRestoreWatcherTimeoutSeconds(metadata)

    self.pendingRestoreState = {
        previousChannel = previousChannelInfo,
        expectedText = normalizedExpected,
        metadata = type(metadata) == "table" and metadata or nil,
        timeoutSeconds = timeoutSeconds,
        armedAt = GetFrameTimeMilliseconds and GetFrameTimeMilliseconds() or nil,
    }

    self:DebugLog("Armed restore watcher with previous channel: " .. self:FormatChatChannelInfo(previousChannelInfo))
    self:DebugLog("Expected outgoing text: " .. tostring(normalizedExpected))
    self:DebugLog("Restore watcher timeout seconds: " .. tostring(timeoutSeconds))

    EVENT_MANAGER:RegisterForEvent(
        self.restoreWatcherEventName,
        EVENT_CHAT_MESSAGE_CHANNEL,
        function(...)
            SmartChatMsg:HandleRestoreWatcherChatMessage(...)
        end
    )

    EVENT_MANAGER:RegisterForUpdate(self.restoreWatcherTimeoutName, timeoutSeconds * 1000, function()
        local pendingState = SmartChatMsg.pendingRestoreState
        local pendingTimeoutSeconds = pendingState and pendingState.timeoutSeconds or timeoutSeconds
        SmartChatMsg:DebugLog("Restore watcher timed out after " .. tostring(pendingTimeoutSeconds) .. " seconds")
        if pendingState and pendingState.previousChannel then
            SmartChatMsg:DebugLog("Timeout restore attempting previous channel: " .. SmartChatMsg:FormatChatChannelInfo(pendingState.previousChannel))
            local restored = SmartChatMsg:RestoreChatChannel(pendingState.previousChannel)
            SmartChatMsg:DebugLog("Timeout restore result=" .. tostring(restored))
        end

        local cleared = SmartChatMsg:ClearPendingChatBuffer()
        SmartChatMsg:DebugLog("Timeout clear pending chat result=" .. tostring(cleared))

        if pendingState and type(pendingState.metadata) == "table" and pendingState.metadata.reminderRepeat == true then
            SmartChatMsg:HandleReminderPopulateTimeout(pendingState.metadata)
        end

        if pendingState and type(pendingState.metadata) == "table" and pendingState.metadata.startupQueue == true then
            SmartChatMsg:HandleStartupQueuePopulateTimeout(pendingState.metadata)
        end

        SmartChatMsg:ClearPendingRestoreState("restore timeout")
    end)

    return true
end

function SmartChatMsg:SetActiveAutoPopulate(commandId, guildName)
    local command = self:GetCommandById(commandId)
    if not command then
        self:ClearActiveAutoPopulate()
        return
    end

    if not self:GetGuildAutoPopulateOnZone(commandId, guildName) then
        self:ClearActiveAutoPopulate()
        return
    end

    local normalizedGuildName = self:Trim(guildName or "")
    if normalizedGuildName == "" then
        self:ClearActiveAutoPopulate()
        return
    end

    self.savedVars.activeAutoPopulate = {
        commandId = commandId,
        guildName = normalizedGuildName,
    }
end

function SmartChatMsg:GetActiveAutoPopulate()
    local active = self.savedVars.activeAutoPopulate
    if type(active) ~= "table" then
        return nil
    end

    if type(active.commandId) ~= "string" or active.commandId == "" then
        return nil
    end

    if type(active.guildName) ~= "string" or active.guildName == "" then
        return nil
    end

    local command = self:GetCommandById(active.commandId)
    if not command or not self:GetGuildAutoPopulateOnZone(active.commandId, active.guildName) then
        return nil
    end

    return active
end



function SmartChatMsg:GetPlayerZoneId()
    local zoneIndex = GetUnitZoneIndex("player")
    if not zoneIndex then
        return nil
    end

    local zoneId = GetZoneId(zoneIndex)
    if type(zoneId) ~= "number" or zoneId == 0 then
        return nil
    end

    return zoneId
end

function SmartChatMsg:IsAutoPopulateTestHouseZone(zoneId)
    return type(zoneId) == "number" and zoneId == self.autoPopulateTestHouseZoneId
end

function SmartChatMsg:GetZoneCategory(zoneId)
    if type(zoneId) ~= "number" or zoneId == 0 then
        return "UNKNOWN"
    end

    if self:IsAutoPopulateTestHouseZone(zoneId) then
        return "OVERLAND_TEST_HOUSE"
    end

    if zoneId == self.infiniteArchiveZoneId then
        return "INFINITE_ARCHIVE"
    end

    if IsActiveWorldBattleground() then
        return "BATTLEGROUND"
    end

    if GetCurrentZoneHouseId() ~= 0 then
        return "HOUSE"
    end

    if IsPlayerInAvAWorld() then
        return "AVA_WORLD"
    end

    if IsUnitInDungeon("player") then
        return "INSTANCE"
    end

    return "OVERLAND"
end

function SmartChatMsg:IsAutoPopulateEligibleZone(zoneId)
    local category = self:GetZoneCategory(zoneId)
    return category == "OVERLAND" or category == "OVERLAND_TEST_HOUSE", category
end

function SmartChatMsg:GetAutoPopulateZoneRejectionReason(zoneId)
    local category = self:GetZoneCategory(zoneId)

    if category == "UNKNOWN" then
        return category, "zone id is missing or invalid"
    elseif category == "INFINITE_ARCHIVE" then
        return category, "Infinite Archive is excluded from auto populate"
    elseif category == "BATTLEGROUND" then
        return category, "Battlegrounds are excluded from auto populate"
    elseif category == "HOUSE" then
        return category, "housing is excluded except for the configured test house zone"
    elseif category == "AVA_WORLD" then
        return category, "AvA zones are excluded from auto populate"
    elseif category == "INSTANCE" then
        return category, "instanced PvE zones are excluded from auto populate"
    elseif category == "OVERLAND_TEST_HOUSE" then
        return category, "test house override is allowed"
    elseif category == "OVERLAND" then
        return category, "overland zone is allowed"
    end

    return tostring(category), "zone category is not eligible for auto populate"
end

function SmartChatMsg:GetEffectiveAutoPopulateZoneId(zoneId)
    if type(zoneId) ~= "number" or zoneId == 0 then
        return nil
    end

    local isEligible = self:IsAutoPopulateEligibleZone(zoneId)
    if isEligible then
        return zoneId
    end

    return nil
end

function SmartChatMsg:GetAutoPopulateZoneDisplayName(zoneId)
    if type(zoneId) ~= "number" or zoneId == 0 then
        return "unknown"
    end

    if GetZoneNameById then
        local zoneName = self:Trim(GetZoneNameById(zoneId) or "")
        if zoneName ~= "" then
            return zoneName
        end
    end

    return tostring(zoneId)
end

function SmartChatMsg:ShouldSkipAutoPopulateForZone(commandId, guildName, zoneId)
    local lastSentAt = self:GetGuildAutoPopulateLastSentAt(commandId, guildName, zoneId)
    if type(lastSentAt) ~= "number" or lastSentAt <= 0 then
        return false, nil, nil
    end

    local now = GetTimeStamp()
    local elapsed = now - lastSentAt
    local cooldownMinutes = self:GetGuildAutoPopulateCooldownMinutes(commandId, guildName)
    local cooldownSeconds = (cooldownMinutes or 60) * 60

    if elapsed < cooldownSeconds then
        return true, elapsed, cooldownSeconds
    end

    return false, elapsed, cooldownSeconds
end

function SmartChatMsg:GetAutoPopulateCooldownEndsAt(commandId, guildName, zoneId)
    local lastSentAt = self:GetGuildAutoPopulateLastSentAt(commandId, guildName, zoneId)
    if type(lastSentAt) ~= "number" or lastSentAt <= 0 then
        return nil
    end

    local cooldownMinutes = self:GetGuildAutoPopulateCooldownMinutes(commandId, guildName)
    local cooldownSeconds = (cooldownMinutes or 60) * 60
    return lastSentAt + cooldownSeconds
end

function SmartChatMsg:FormatUnixTimestampForDisplay(timestamp)
    if type(timestamp) ~= "number" or timestamp <= 0 then
        return "unknown"
    end

    return os.date("%m/%d/%Y %I:%M %p", timestamp)
end

function SmartChatMsg:ShowAutoPopulateCooldownAlert(commandId, guildName, zoneId)
    local command = self:GetCommandById(commandId)
    local commandDisplayName = self:BuildSlashCommandName(command and command.name or "") or "/command"
    local zoneName = self:GetAutoPopulateZoneDisplayName(zoneId)
    local cooldownEndsAt = self:GetAutoPopulateCooldownEndsAt(commandId, guildName, zoneId)
    local untilText = self:FormatUnixTimestampForDisplay(cooldownEndsAt)
    local message = string.format("%s Zone %s is in cooldown until %s.", commandDisplayName, zoneName, untilText)
    ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NONE, message)
end

function SmartChatMsg:MarkAutoPopulateSent(commandId, guildName, zoneId)
    local timestamp = GetTimeStamp()
    self:SetGuildAutoPopulateLastSentAt(commandId, guildName, zoneId, timestamp)

    self:DebugLog(string.format(
        "Auto populate debug: marked sent commandId=%s guildName=%s zoneId=%s sentAt=%s",
        tostring(commandId),
        tostring(guildName),
        tostring(zoneId),
        tostring(timestamp)
    ))

    if self.statusPanelVisible then
        self:RefreshStatusPanel()
    end
end


function SmartChatMsg:HandleZoneAutoPopulate()
    local currentZoneId = self:GetPlayerZoneId()
    local trackedZoneId = self:GetEffectiveAutoPopulateZoneId(currentZoneId)
    local previousZoneId = self.lastKnownZoneId
    local isInitialActivation = not self.hasSeenInitialPlayerActivated

    self.lastKnownZoneId = currentZoneId
    self.hasSeenInitialPlayerActivated = true

    if isInitialActivation then
        self:DebugLog(string.format(
            "Auto populate debug: initial player activation evaluating currentZoneId=%s trackedZoneId=%s",
            tostring(currentZoneId),
            tostring(trackedZoneId)
        ))
    end

    if not trackedZoneId then
        local category, reason = self:GetAutoPopulateZoneRejectionReason(currentZoneId)
        self:DebugLog(string.format(
            "Auto populate debug: skipped because currentZoneId=%s category=%s reason=%s",
            tostring(currentZoneId),
            tostring(category),
            tostring(reason)
        ))
        return
    end

    local active = self:GetActiveAutoPopulate()
    if not active then
        self:DebugLog("Auto populate debug: no active auto populate command")
        return
    end

    local shouldSkip, elapsed, cooldown = self:ShouldSkipAutoPopulateForZone(active.commandId, active.guildName, trackedZoneId)
    if shouldSkip then
        self:DebugLog(string.format(
            "Auto populate debug: skipped for commandId=%s guildName=%s zoneId=%s because elapsed=%s cooldown=%s",
            tostring(active.commandId),
            tostring(active.guildName),
            tostring(trackedZoneId),
            tostring(elapsed),
            tostring(cooldown)
        ))

        if isInitialActivation then
            self:ShowAutoPopulateCooldownAlert(active.commandId, active.guildName, trackedZoneId)
        end

        if self.statusPanelVisible then
            self:RefreshStatusPanel()
        end
        return
    end

    self:DebugLog(string.format(
        "Auto populate debug: firing for commandId=%s guildName=%s currentZoneId=%s trackedZoneId=%s previousZoneId=%s initialActivation=%s",
        tostring(active.commandId),
        tostring(active.guildName),
        tostring(currentZoneId),
        tostring(trackedZoneId),
        tostring(previousZoneId),
        tostring(isInitialActivation)
    ))

    local guildIndex = self:GetGuildSlotByName(active.guildName)
    local paramText = guildIndex and tostring(guildIndex) or nil

    local ok, err = self:PopulateChatBufferForCommand(
        active.commandId,
        active.guildName,
        nil,
        {
            autoPopulate = true,
            commandId = active.commandId,
            guildName = active.guildName,
            guildIndex = guildIndex,
            paramText = paramText,
            zoneId = trackedZoneId,
        }
    )

    if not ok then
        self:ClearActiveAutoPopulate()
        if self.statusPanelVisible then
            self:RefreshStatusPanel()
        end
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
        return
    end

    if self.statusPanelVisible then
        self:RefreshStatusPanel()
    end

    local command = self:GetCommandById(active.commandId)
    if command then
        local commandName = self:BuildSlashCommandName(command.name or "") or "command"
        local zoneName = self:GetAutoPopulateZoneDisplayName(trackedZoneId)
        local message = string.format("Auto populated %s for %s. Run the command again to turn it off.", commandName, zoneName)
        if CENTER_SCREEN_ANNOUNCE then
            CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, message)
        else
            d(message)
        end
    end
end

function SmartChatMsg:PopulateChatBufferForCommand(commandId, guildName, channelOverride, restoreMetadata)
    self:DebugLog(string.format(
        "PopulateChatBufferForCommand start commandId=%s guildName=%s channelOverride=%s",
        tostring(commandId),
        tostring(guildName),
        tostring(channelOverride)
    ))

    local messages = self:GetMessageEntriesForCommandAndGuild(commandId, guildName)
    self:DebugLog("PopulateChatBufferForCommand message count=" .. tostring(#messages))
    if #messages == 0 then
        self:DebugLog("PopulateChatBufferForCommand aborted: no saved messages")
        return false, "No messages are saved for that command and guild."
    end

    local selectedEntry = self:SelectWeightedMessageEntry(messages)
    if not selectedEntry then
        self:DebugLog("PopulateChatBufferForCommand aborted: no selected entry")
        return false, "No messages are saved for that command and guild."
    end

    self:DebugLog("PopulateChatBufferForCommand selected entry id=" .. tostring(selectedEntry.id or "nil"))

    local messageText = self:Trim(selectedEntry.text or "")
    if messageText == "" then
        self:DebugLog("PopulateChatBufferForCommand aborted: selected message text was empty")
        return false, "The selected message is empty."
    end

    local resolvedMessageText = self:Trim(self:ApplyMessageSubstitutions(messageText, commandId, guildName) or "")
    self:DebugLog("PopulateChatBufferForCommand resolved text=" .. tostring(resolvedMessageText))
    if resolvedMessageText == "" then
        self:DebugLog("PopulateChatBufferForCommand aborted: resolved message text was empty")
        return false, "The selected message is empty after substitutions."
    end

    local channel = channelOverride or self:GetSavedChatChannel(commandId, guildName)
    self:DebugLog("PopulateChatBufferForCommand resolved channel=" .. tostring(channel))

    local previousChannelInfo = self:GetPreciseChatChannelInfo()
    self:DebugLog("PopulateChatBufferForCommand previous channel=" .. self:FormatChatChannelInfo(previousChannelInfo))

    local watcherMetadata = nil
    if type(restoreMetadata) == "table" then
        watcherMetadata = {}
        for key, value in pairs(restoreMetadata) do
            watcherMetadata[key] = value
        end
    else
        watcherMetadata = {}
    end
    watcherMetadata.commandId = watcherMetadata.commandId or commandId
    watcherMetadata.guildName = watcherMetadata.guildName or guildName
    watcherMetadata.selectedEntryId = selectedEntry.id

    local armedRestore = self:ArmPendingRestoreState(previousChannelInfo, resolvedMessageText, watcherMetadata)
    self:DebugLog("PopulateChatBufferForCommand armedRestore=" .. tostring(armedRestore))

    if channel == "Zone" then
        self:DebugLog("PopulateChatBufferForCommand starting chat input for Zone")
        StartChatInput(resolvedMessageText, CHAT_CHANNEL_ZONE)
        self:PlayPopulateSound(commandId, guildName)
        return true
    end

    if channel == "Guild" or channel == "Officer" then
        local guildSlot = self:GetGuildSlotByName(guildName)
        self:DebugLog("PopulateChatBufferForCommand guildSlot=" .. tostring(guildSlot))
        if not guildSlot then
            self:ClearPendingRestoreState("guild slot unavailable before StartChatInput")
            return false, "That guild is not currently available."
        end

        if channel == "Guild" then
            local channelId = CHAT_CHANNEL_GUILD_1 + (guildSlot - 1)
            self:DebugLog("PopulateChatBufferForCommand starting chat input for Guild channelId=" .. tostring(channelId))
            StartChatInput(resolvedMessageText, channelId)
            self:PlayPopulateSound(commandId, guildName)
            return true
        end

        local channelId = CHAT_CHANNEL_OFFICER_1 + (guildSlot - 1)
        self:DebugLog("PopulateChatBufferForCommand starting chat input for Officer channelId=" .. tostring(channelId))
        StartChatInput(resolvedMessageText, channelId)
        self:PlayPopulateSound(commandId, guildName)
        return true
    end

    self:ClearPendingRestoreState("no saved chat channel resolved")
    return false, "No chat channel is saved for that command and guild."
end

function SmartChatMsg:ParseCommandParameter(rawParam)
    local trimmed = zo_strlower(self:Trim(rawParam or ""))
    if trimmed == "" then
        return nil
    end

    local result = {
        guildSlot = nil,
        channelOverride = nil,
        reminderParamText = nil,
        stopAutomation = false,
    }

    local tokenCount = 0
    for token in string.gmatch(trimmed, "%S+") do
        tokenCount = tokenCount + 1
        if tokenCount > 2 then
            return false
        end

        if token == "off" then
            if result.stopAutomation then
                return false
            end
            result.stopAutomation = true
        else
            local numericParam = tonumber(token)
            if numericParam and numericParam >= 1 and numericParam <= 5 and numericParam == math.floor(numericParam) then
                if result.guildSlot ~= nil then
                    return false
                end
                result.guildSlot = numericParam
                result.channelOverride = nil
                result.reminderParamText = tostring(numericParam)
            else
                local prefix, slotText = token:match("^([go])([1-5])$")
                if not prefix or not slotText or result.guildSlot ~= nil then
                    return false
                end

                local guildSlot = tonumber(slotText)
                result.guildSlot = guildSlot
                result.channelOverride = (prefix == "g") and "Guild" or "Officer"
                result.reminderParamText = token
            end
        end
    end

    if result.guildSlot == nil and result.stopAutomation == false then
        return false
    end

    return result
end

function SmartChatMsg:ShouldOpenStatusPanelOnRun(commandId, guildName)
    if self:GetGuildOpenStatusPanelOnRun(commandId, guildName) ~= true then
        return false
    end

    if self:GetGuildAutoPopulateOnZone(commandId, guildName) == true then
        return true
    end

    local repeatMinutes = self:GetGuildReminderMinutes(commandId, guildName)
    return type(repeatMinutes) == "number" and repeatMinutes > 0
end

function SmartChatMsg:OpenStatusPanelOnRunIfConfigured(commandId, guildName)
    if self:ShouldOpenStatusPanelOnRun(commandId, guildName) then
        self:SetStatusPanelVisible(true)
    end
end

function SmartChatMsg:HandleDynamicSlashCommand(commandId, slashCommandName, rawParam)
    local trimmedParam = self:Trim(rawParam or "")
    local guildSlot = nil
    local channelOverride = nil
    local reminderParamText = nil
    local stopAutomation = false

    if trimmedParam ~= "" then
        local parsed = self:ParseCommandParameter(trimmedParam)

        if parsed == false then
            ZO_Alert(
                UI_ALERT_CATEGORY_ERROR,
                SOUNDS.NEGATIVE_CLICK,
                string.format("%s accepts off, 1-5, g1-g5, o1-o5, or a combination like '1 off'.", slashCommandName)
            )
            return
        end

        stopAutomation = parsed and parsed.stopAutomation == true
        guildSlot = parsed and parsed.guildSlot or nil
        channelOverride = parsed and parsed.channelOverride or nil
        reminderParamText = parsed and parsed.reminderParamText or nil
    end

    if guildSlot == nil then
        guildSlot = self:GetDefaultGuildIndex()

        if not guildSlot then
            ZO_Alert(
                UI_ALERT_CATEGORY_ERROR,
                SOUNDS.NEGATIVE_CLICK,
                string.format("%s requires 1-5, g1-g5, or o1-o5, or a Default Guild must be set.", slashCommandName)
            )
            return
        end

        reminderParamText = tostring(guildSlot)
    end

    local guildName = self:GetGuildNameByIndex(guildSlot)
    if not guildName then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, string.format("Guild slot %d is not available.", guildSlot))
        return
    end

    self:DebugLog(string.format(
        "HandleDynamicSlashCommand commandId=%s slashCommand=%s guildSlot=%s guildName=%s channelOverride=%s stopAutomation=%s rawParam=%s",
        tostring(commandId),
        tostring(slashCommandName),
        tostring(guildSlot),
        tostring(guildName),
        tostring(channelOverride),
        tostring(stopAutomation),
        tostring(trimmedParam)
    ))

    local commandDisplayName = self:GetSlashCommandDisplayName(commandId, slashCommandName)

    if stopAutomation then
        local stoppedParts = {}

        if self:ToggleOffActiveAutoPopulateIfMatching(commandId, guildName) then
            table.insert(stoppedParts, "auto populate")
        end

        if self:IsReminderAutomationActive(commandId, guildName) then
            self:DeactivateReminderAutomation(commandId, guildName, "explicit off parameter")
            table.insert(stoppedParts, "repeat")
        end

        local message
        if #stoppedParts > 0 then
            message = string.format("%s stopped %s for %s.", commandDisplayName, table.concat(stoppedParts, " and "), guildName)
            PlaySound(SOUNDS.DEFAULT_CLICK)
        else
            message = string.format("%s had nothing active to stop for %s.", commandDisplayName, guildName)
            PlaySound(SOUNDS.NEGATIVE_CLICK)
        end

        self:ShowStatusMessage(message)
        return
    end

    local autoPopulateEnabled = self:GetGuildAutoPopulateOnZone(commandId, guildName) == true

    self:OpenStatusPanelOnRunIfConfigured(commandId, guildName)

    local activeAutoPopulate = self:GetActiveAutoPopulate()
    if activeAutoPopulate and autoPopulateEnabled then
        local sameAutoPopulate = activeAutoPopulate.commandId == commandId and self:StringsEqualIgnoreCase(activeAutoPopulate.guildName or "", guildName or "")
        if not sameAutoPopulate then
            ZO_Alert(
                UI_ALERT_CATEGORY_ERROR,
                SOUNDS.NEGATIVE_CLICK,
                string.format("%s cannot start auto populate because %s is already running for %s.", commandDisplayName, self:BuildSlashCommandName(self:GetCommandNameById(activeAutoPopulate.commandId) or "command") or "another command", tostring(activeAutoPopulate.guildName))
            )
            return
        end
    end

    if autoPopulateEnabled then
        self:SetActiveAutoPopulate(commandId, guildName)
        if self.statusPanelVisible then
            self:RefreshStatusPanel()
        end

        self:DebugLog(string.format(
            "Auto populate debug: armed immediately from slash command commandId=%s guildName=%s",
            tostring(commandId),
            tostring(guildName)
        ))

        local currentZoneId = self:GetPlayerZoneId()
        local trackedZoneId = self:GetEffectiveAutoPopulateZoneId(currentZoneId)

        if not trackedZoneId then
            local category, reason = self:GetAutoPopulateZoneRejectionReason(currentZoneId)
            self:DebugLog(string.format(
                "Auto populate debug: manual start did not populate because currentZoneId=%s category=%s reason=%s",
                tostring(currentZoneId),
                tostring(category),
                tostring(reason)
            ))

            self:ShowStatusMessage(string.format("%s started auto populate for %s.", commandDisplayName, guildName))
            PlaySound(SOUNDS.DEFAULT_CLICK)
            return
        end

        local shouldSkip, elapsed, cooldown = self:ShouldSkipAutoPopulateForZone(commandId, guildName, trackedZoneId)
        if shouldSkip then
            self:DebugLog(string.format(
                "Auto populate debug: manual start skipped populate due to cooldown commandId=%s guildName=%s zoneId=%s elapsed=%s cooldown=%s",
                tostring(commandId),
                tostring(guildName),
                tostring(trackedZoneId),
                tostring(elapsed),
                tostring(cooldown)
            ))
            self:ShowAutoPopulateCooldownAlert(commandId, guildName, trackedZoneId)
            self:ShowStatusMessage(string.format("%s started auto populate for %s.", commandDisplayName, guildName))
            PlaySound(SOUNDS.DEFAULT_CLICK)
            return
        end

        self:ShowStatusMessage(string.format("%s started auto populate for %s.", commandDisplayName, guildName))
        PlaySound(SOUNDS.DEFAULT_CLICK)
        self:HandleZoneAutoPopulate()
        return
    end

    local ok, err = self:PopulateChatBufferForCommand(
        commandId,
        guildName,
        channelOverride,
        {
            commandId = commandId,
            guildName = guildName,
            guildIndex = guildSlot,
            paramText = reminderParamText,
            activateAutoPopulate = autoPopulateEnabled,
        }
    )
    if not ok then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
        return
    end

    local startedParts = { "started" }
    if self:GetGuildReminderMinutes(commandId, guildName) then
        table.insert(startedParts, "repeat")
    end
    if self:GetGuildAutoPopulateOnZone(commandId, guildName) then
        table.insert(startedParts, "auto populate")
    end

    self:ShowStatusMessage(string.format("%s %s for %s.", commandDisplayName, table.concat(startedParts, " with "), guildName))
    PlaySound(SOUNDS.DEFAULT_CLICK)
end

function SmartChatMsg:UnregisterDynamicCommands()
    for slashCommandName, _ in pairs(self.dynamicCommands) do
        SLASH_COMMANDS[slashCommandName] = nil
    end

    self.dynamicCommands = {}
end

function SmartChatMsg:RegisterDynamicCommands()
    self:UnregisterDynamicCommands()

    local seenCommands = {}

    for _, command in ipairs(self:GetCommands()) do
        if type(command) == "table" and type(command.id) == "string" and type(command.name) == "string" then
            local slashCommandName = self:BuildSlashCommandName(command.name)

            if slashCommandName and not seenCommands[slashCommandName] then
                seenCommands[slashCommandName] = true
                self.dynamicCommands[slashCommandName] = command.id

                SLASH_COMMANDS[slashCommandName] = function(paramText)
                    SmartChatMsg:HandleDynamicSlashCommand(command.id, slashCommandName, paramText)
                end
            end
        end
    end
end


function SmartChatMsg:BuildStartupQueueEntries()
    local entries = {}

    for _, command in ipairs(self:GetCommands()) do
        if type(command) == "table" and type(command.id) == "string" and command.id ~= "" then
            for guildIndex = 1, 5 do
                local guildId = GetGuildId(guildIndex)
                if guildId and guildId ~= 0 then
                    local guildName = self:GetGuildNameByIndex(guildIndex)
                    if guildName and self:GetGuildRunAt(command.id, guildName) == "STARTUP" then
                        table.insert(entries, {
                            commandId = command.id,
                            guildName = guildName,
                            guildIndex = guildIndex,
                            paramText = tostring(guildIndex),
                        })
                    end
                end
            end
        end
    end

    return entries
end

function SmartChatMsg:GetStartupQueueRetryDelayMilliseconds()
    return zo_random(0, 20000)
end

function SmartChatMsg:ScheduleStartupQueueNextStep(delayMs, reason)
    EVENT_MANAGER:UnregisterForUpdate(self.startupQueueDelayName)

    local queueCount = #(self.startupQueue or {})
    if queueCount <= 0 then
        self:DebugLog("Startup queue: nothing left to schedule reason=" .. tostring(reason or "unspecified"))
        return
    end

    local effectiveDelayMs = math.max(0, math.floor(tonumber(delayMs) or 0))
    self:DebugLog(string.format(
        "Startup queue: scheduling next step delayMs=%s remaining=%s reason=%s",
        tostring(effectiveDelayMs),
        tostring(queueCount),
        tostring(reason or "unspecified")
    ))

    EVENT_MANAGER:RegisterForUpdate(self.startupQueueDelayName, effectiveDelayMs, function()
        EVENT_MANAGER:UnregisterForUpdate(SmartChatMsg.startupQueueDelayName)
        SmartChatMsg:ProcessStartupQueue()
    end)
end

function SmartChatMsg:FinalizeStartupQueueCurrent(success, reason)
    local current = self.startupQueueCurrent
    self.startupQueueCurrent = nil

    if not current then
        self:DebugLog("Startup queue: finalize called with no current item reason=" .. tostring(reason or "unspecified"))
        return
    end

    self:DebugLog(string.format(
        "Startup queue: finalizing commandId=%s guildName=%s success=%s reason=%s",
        tostring(current.commandId),
        tostring(current.guildName),
        tostring(success == true),
        tostring(reason or "unspecified")
    ))

    if success ~= true then
        table.insert(self.startupQueue, current)
        self:ScheduleStartupQueueNextStep(self:GetStartupQueueRetryDelayMilliseconds(), reason or "startup queue retry")
        return
    end

    if #(self.startupQueue or {}) > 0 then
        self:ScheduleStartupQueueNextStep(0, reason or "startup queue continue")
    end
end

function SmartChatMsg:HandleStartupQueuePopulateSuccess(metadata)
    if type(metadata) ~= "table" or metadata.startupQueue ~= true then
        return
    end

    self:FinalizeStartupQueueCurrent(true, "startup queue message sent")
end

function SmartChatMsg:HandleStartupQueuePopulateTimeout(metadata)
    if type(metadata) ~= "table" or metadata.startupQueue ~= true then
        return
    end

    self:FinalizeStartupQueueCurrent(false, "startup queue timed out")
end

function SmartChatMsg:ProcessStartupQueue()
    if not self.startupQueueInitialized then
        self:DebugLog("Startup queue: process skipped because queue has not been initialized")
        return
    end

    if self.startupQueueCurrent then
        self:DebugLog("Startup queue: process skipped because current item is still active")
        return
    end

    if self.pendingRestoreState then
        self:DebugLog("Startup queue: process skipped because restore watcher is already armed")
        return
    end

    local queue = self.startupQueue or {}
    if #queue <= 0 then
        self:DebugLog("Startup queue: complete")
        return
    end

    local entry = table.remove(queue, 1)
    self.startupQueue = queue
    self.startupQueueCurrent = entry

    local slashCommandName = self:GetSlashCommandDisplayName(entry.commandId)
    self:DebugLog(string.format(
        "Startup queue: processing commandId=%s guildName=%s paramText=%s remainingAfterPop=%s",
        tostring(entry.commandId),
        tostring(entry.guildName),
        tostring(entry.paramText),
        tostring(#queue)
    ))

    self:HandleDynamicSlashCommand(entry.commandId, slashCommandName, entry.paramText)

    local pendingState = self.pendingRestoreState
    local metadata = pendingState and pendingState.metadata or nil
    if type(metadata) == "table"
        and metadata.commandId == entry.commandId
        and self:StringsEqualIgnoreCase(metadata.guildName or "", entry.guildName or "") then
        metadata.startupQueue = true
        return
    end

    self:FinalizeStartupQueueCurrent(true, "startup queue completed without pending chat")
end

function SmartChatMsg:InitializeStartupQueueOnce()
    if self.startupQueueInitialized then
        return
    end

    self.startupQueueInitialized = true
    self.startupQueue = self:BuildStartupQueueEntries()
    self.startupQueueCurrent = nil

    self:DebugLog("Startup queue: initialized with " .. tostring(#(self.startupQueue or {})) .. " entries")

    if #(self.startupQueue or {}) > 0 then
        self:ScheduleStartupQueueNextStep(0, "startup queue initialize")
    end
end

function SmartChatMsg:FormatStatusDuration(secondsRemaining)
    if type(secondsRemaining) ~= "number" or secondsRemaining <= 0 then
        return "Ready"
    end

    local total = math.max(0, math.floor(secondsRemaining))
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)
    local seconds = total % 60

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, seconds)
    end

    return string.format("%02d:%02d", minutes, seconds)
end

function SmartChatMsg:GetStatusPanelZoneTimerText(zoneId, secondsRemaining, isCurrent)
    if isCurrent then
        if not self:IsAutoPopulateEligibleZone(zoneId) then
            return "N/A", false
        end
    else
        if type(zoneId) ~= "number" or zoneId == 0 then
            return "N/A", false
        end
    end

    return self:FormatStatusDuration(secondsRemaining), true
end

function SmartChatMsg:GetStatusPanelMaxVisibleCooldownRows()
    return 10
end

function SmartChatMsg:GetStatusPanelScrollOffset()
    local panel = self.statusPanel
    if not panel then
        return 0
    end
    local value = tonumber(panel.cooldownScrollOffset) or 0
    return math.max(0, math.floor(value))
end

function SmartChatMsg:SetStatusPanelScrollOffset(offset, totalRows)
    local panel = self.statusPanel
    if not panel then
        return
    end
    local maxVisible = self:GetStatusPanelMaxVisibleCooldownRows()
    local maxOffset = math.max(0, (tonumber(totalRows) or 0) - maxVisible)
    local clamped = math.max(0, math.min(maxOffset, math.floor(tonumber(offset) or 0)))
    panel.cooldownScrollOffset = clamped
end

function SmartChatMsg:AdjustStatusPanelScrollOffset(delta, totalRows)
    local current = self:GetStatusPanelScrollOffset()
    self:SetStatusPanelScrollOffset(current + (delta or 0), totalRows)
end


function SmartChatMsg:GetAutoPopulateChannelStatusText(commandId, guildName)
    local channel = self:GetSavedChatChannel(commandId, guildName)
    local guildSlot = self:GetGuildSlotByName(guildName)

    if channel == "Guild" and guildSlot then
        return string.format("Guild (/g%d)", guildSlot)
    elseif channel == "Officer" and guildSlot then
        return string.format("Officer (/o%d)", guildSlot)
    elseif channel == "Zone" then
        return "Zone"
    end

    return channel or "Unknown"
end

function SmartChatMsg:GetAutoPopulateStatusRows(commandId, guildName)
    local rows = {}
    local seenZoneKeys = {}
    local currentZoneId = GetZoneId(GetUnitZoneIndex("player"))
    local currentTrackedZoneId = self:GetEffectiveAutoPopulateZoneId(currentZoneId)
    local otherRows = {}

    local function buildRow(zoneId, isCurrent)
        if type(zoneId) ~= "number" or zoneId == 0 then
            return nil
        end

        local zoneKey = tostring(zoneId)
        if seenZoneKeys[zoneKey] then
            return nil
        end
        seenZoneKeys[zoneKey] = true

        local zoneName = self:GetAutoPopulateZoneDisplayName(zoneId)
        local cooldownEndsAt = self:GetAutoPopulateCooldownEndsAt(commandId, guildName, zoneId)
        local secondsRemaining = nil
        if type(cooldownEndsAt) == "number" and cooldownEndsAt > 0 then
            secondsRemaining = cooldownEndsAt - GetTimeStamp()
        end

        local statusText, isApplicable = self:GetStatusPanelZoneTimerText(zoneId, secondsRemaining, isCurrent)

        return {
            zoneId = zoneId,
            zoneName = zoneName,
            isCurrent = isCurrent == true,
            secondsRemaining = secondsRemaining,
            statusText = statusText,
            isApplicable = isApplicable,
            isReady = isApplicable and (type(secondsRemaining) ~= "number" or secondsRemaining <= 0) or false,
        }
    end

    local currentRow = buildRow(currentTrackedZoneId or currentZoneId, true)
    if currentRow then
        table.insert(rows, currentRow)
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    local byZone = settings and settings.lastAutoPopulateSentAtByZone or nil
    if type(byZone) == "table" then
        for zoneKey, timestamp in pairs(byZone) do
            if type(timestamp) == "number" and timestamp > 0 then
                local zoneId = tonumber(zoneKey)
                local row = buildRow(zoneId, false)
                if row then
                    table.insert(otherRows, row)
                end
            end
        end
    end

    table.sort(otherRows, function(a, b)
        if a.isApplicable ~= b.isApplicable then
            return a.isApplicable == true
        end

        if a.isReady ~= b.isReady then
            return a.isReady == true
        end

        if a.isReady and b.isReady then
            local aName = zo_strlower(a.zoneName or "")
            local bName = zo_strlower(b.zoneName or "")
            if aName == bName then
                return (a.zoneId or 0) < (b.zoneId or 0)
            end
            return aName < bName
        end

        local aSeconds = math.max(0, math.floor(tonumber(a.secondsRemaining) or 0))
        local bSeconds = math.max(0, math.floor(tonumber(b.secondsRemaining) or 0))
        if aSeconds == bSeconds then
            local aName = zo_strlower(a.zoneName or "")
            local bName = zo_strlower(b.zoneName or "")
            if aName == bName then
                return (a.zoneId or 0) < (b.zoneId or 0)
            end
            return aName < bName
        end
        return aSeconds < bSeconds
    end)

    for _, row in ipairs(otherRows) do
        table.insert(rows, row)
    end

    return rows
end

function SmartChatMsg:GetStatusPanelTimerColor(secondsRemaining, isApplicable)
    if isApplicable == false then
        return 0.70, 0.70, 0.70, 1
    end

    if type(secondsRemaining) ~= "number" or secondsRemaining <= 0 then
        return 0.32, 0.86, 0.45, 1
    end

    if secondsRemaining <= 60 then
        return 0.92, 0.28, 0.22, 1
    end

    return 0.95, 0.62, 0.24, 1
end

function SmartChatMsg:EstimateStatusPanelTextWidth(text)
    local value = tostring(text or "")
    local length = zo_strlen(value)
    local bonus = 0
    if value:find("%u%u") then
        bonus = bonus + 8
    end
    if value:find("[/():]", 1) then
        bonus = bonus + 10
    end
    return math.floor((length * 7.4) + bonus)
end

function SmartChatMsg:GetStatusPanelMeasuredTextWidth(control, fallbackText)
    if control and control.GetTextDimensions then
        local measuredWidth = select(1, control:GetTextDimensions())
        if type(measuredWidth) == "number" and measuredWidth > 0 then
            return math.floor(measuredWidth + 0.5)
        end
    end

    if control and control.GetTextWidth then
        local measuredWidth = control:GetTextWidth()
        if type(measuredWidth) == "number" and measuredWidth > 0 then
            return math.floor(measuredWidth + 0.5)
        end
    end

    return self:EstimateStatusPanelTextWidth(fallbackText)
end

function SmartChatMsg:GetStatusPanelMeasuredTextHeight(control, fallbackHeight)
    if control and control.GetTextDimensions then
        local _, measuredHeight = control:GetTextDimensions()
        if type(measuredHeight) == "number" and measuredHeight > 0 then
            return math.floor(measuredHeight + 0.5)
        end
    end

    return fallbackHeight or 24
end

function SmartChatMsg:GetStatusPanelTargetSize(active, rows)
    local panel = self.statusPanel
    local minWidth = 460
    local maxWidth = 980
    local contentWidth = 0

    local function measured(control, fallback)
        return self:GetStatusPanelMeasuredTextWidth(control, fallback)
    end

    if active and panel then
        local firstLineWidth = 0
        local firstLineControls = {
            panel.statusLabel,
            panel.commandLabel,
            panel.guildLabel,
            panel.channelLabel,
        }

        for _, control in ipairs(firstLineControls) do
            if control and not control:IsHidden() then
                firstLineWidth = firstLineWidth + measured(control, control.GetText and control:GetText() or "")
            end
        end
        if firstLineWidth > 0 then
            firstLineWidth = firstLineWidth + 54
            contentWidth = math.max(contentWidth, firstLineWidth)
        end

        local stackedControls = {
            panel.titleLabel,
            panel.listHeader,
            panel.currentLabel,
            panel.footerLabel,
        }

        for _, control in ipairs(stackedControls) do
            if control and not control:IsHidden() then
                contentWidth = math.max(contentWidth, measured(control, control.GetText and control:GetText() or ""))
            end
        end

        for _, row in ipairs(panel.rows or {}) do
            if row and not row:IsHidden() then
                local rowWidth = 0
                if row.zone1 and not row.zone1:IsHidden() then
                    rowWidth = rowWidth + measured(row.zone1, row.zone1:GetText())
                end
                if row.timer1 and not row.timer1:IsHidden() then
                    rowWidth = rowWidth + 14 + measured(row.timer1, row.timer1:GetText())
                end
                if row.zone2 and not row.zone2:IsHidden() then
                    rowWidth = rowWidth + 30 + measured(row.zone2, row.zone2:GetText())
                end
                if row.timer2 and not row.timer2:IsHidden() then
                    rowWidth = rowWidth + 14 + measured(row.timer2, row.timer2:GetText())
                end
                contentWidth = math.max(contentWidth, rowWidth)
            end
        end
    elseif active then
        local commandName = self:BuildSlashCommandName(self:GetCommandNameById(active.commandId) or "") or "/command"
        contentWidth = math.max(contentWidth, self:EstimateStatusPanelTextWidth("SmartChatMsg Status"))
        contentWidth = math.max(contentWidth, self:EstimateStatusPanelTextWidth("Zone Cooldowns"))
        contentWidth = math.max(contentWidth, self:EstimateStatusPanelTextWidth("Tracked Zones: 0 | Showing 0-0"))
        contentWidth = math.max(contentWidth,
            self:EstimateStatusPanelTextWidth("Auto: Active") +
            self:EstimateStatusPanelTextWidth(tostring(commandName)) +
            self:EstimateStatusPanelTextWidth(tostring(active.guildName)) +
            self:EstimateStatusPanelTextWidth(tostring(self:GetAutoPopulateChannelStatusText(active.commandId, active.guildName))) +
            54
        )
    else
        contentWidth = math.max(
            self:EstimateStatusPanelTextWidth("Auto: Inactive"),
            self:EstimateStatusPanelTextWidth("Tracked Zones: 0 | Showing 0-0")
        )
    end

    local width = math.max(minWidth, math.min(maxWidth, contentWidth + 72))

    local height = 58
    if panel then
        local visibleControls = {
            panel.titleLabel,
            panel.statusLabel,
            panel.commandLabel,
            panel.guildLabel,
            panel.channelLabel,
            panel.listHeader,
            panel.currentLabel,
            panel.footerLabel,
        }

        for _, control in ipairs(visibleControls) do
            if control and not control:IsHidden() then
                height = height + self:GetStatusPanelMeasuredTextHeight(control, 18) + 4
            end
        end

        if panel.divider and not panel.divider:IsHidden() then
            height = height + 6
        end

        local visibleRowCount = 0
        for _, row in ipairs(panel.rows or {}) do
            if row and not row:IsHidden() then
                visibleRowCount = visibleRowCount + 1
            end
        end

        if panel.currentRow and not panel.currentRow:IsHidden() then
            height = height + 14 + 6
        end

        height = height + (visibleRowCount * 14) + math.max(0, visibleRowCount - 1) * 2 + 4
    else
        local visibleRowCount = math.min(#(rows or {}), self:GetStatusPanelMaxVisibleCooldownRows())
        height = active and (150 + (visibleRowCount * 16)) or 120
    end

    height = math.max(120, math.min(680, height))
    return width, height
end

function SmartChatMsg:ApplyStatusPanelLayout(panel, width)
    if not panel then
        return
    end

    local contentWidth = math.max(372, width - 48)
    local timerWidth = 70
    local columnGap = 24
    local pairGap = 12
    local singleLineHeight = 14
    local halfWidth = math.floor((contentWidth - columnGap) / 2)
    local zoneWidth = math.max(90, halfWidth - timerWidth - pairGap)

    local closeButtonReserve = 30

    panel.dragBar:SetWidth(math.max(120, contentWidth - closeButtonReserve))
    panel.titleLabel:SetWidth(math.max(120, contentWidth - closeButtonReserve))
    panel.divider:SetWidth(contentWidth)
    panel.listHeader:SetWidth(contentWidth)
    panel.currentLabel:SetWidth(contentWidth)
    panel.footerLabel:SetWidth(contentWidth)

    local firstLineGap = 3
    local statusWidth = math.max(60, self:EstimateStatusPanelTextWidth(panel.statusLabel:GetText()))
    local commandWidth = math.max(110, self:EstimateStatusPanelTextWidth(panel.commandLabel:GetText()))
    local guildWidth = math.max(110, self:EstimateStatusPanelTextWidth(panel.guildLabel:GetText()))
    local remainingWidth = contentWidth - statusWidth - commandWidth - guildWidth - (firstLineGap * 3)
    local channelWidth = math.max(110, remainingWidth)

    panel.statusLabel:SetDimensions(statusWidth, singleLineHeight)
    panel.commandLabel:SetDimensions(commandWidth, singleLineHeight)
    panel.guildLabel:SetDimensions(guildWidth, singleLineHeight)
    panel.channelLabel:SetDimensions(channelWidth, singleLineHeight)

    panel.statusLabel:ClearAnchors()
    panel.commandLabel:ClearAnchors()
    panel.guildLabel:ClearAnchors()
    panel.channelLabel:ClearAnchors()
    panel.divider:ClearAnchors()
    panel.listHeader:ClearAnchors()
    panel.currentLabel:ClearAnchors()
    panel.footerLabel:ClearAnchors()

    panel.statusLabel:SetAnchor(TOPLEFT, panel.titleLabel, BOTTOMLEFT, 0, 8)
    panel.commandLabel:SetAnchor(TOPLEFT, panel.statusLabel, TOPRIGHT, firstLineGap, 0)
    panel.guildLabel:SetAnchor(TOPLEFT, panel.commandLabel, TOPRIGHT, firstLineGap, 0)
    panel.channelLabel:SetAnchor(TOPLEFT, panel.guildLabel, TOPRIGHT, firstLineGap, 0)

    panel.divider:SetAnchor(TOPLEFT, panel.statusLabel, BOTTOMLEFT, 0, 8)
    panel.listHeader:SetAnchor(TOPLEFT, panel.divider, BOTTOMLEFT, 0, 8)
    panel.currentLabel:SetAnchor(TOPLEFT, panel.listHeader, BOTTOMLEFT, 0, 6)

    if panel.currentRow then
        panel.currentRow:SetDimensions(contentWidth, singleLineHeight)
        panel.currentRow:ClearAnchors()
        panel.currentRow:SetAnchor(TOPLEFT, panel.currentLabel, BOTTOMLEFT, 0, 2)

        panel.currentRow.zone:ClearAnchors()
        panel.currentRow.timer:ClearAnchors()

        local currentZoneWidth = math.max(90, contentWidth - timerWidth - pairGap)
        panel.currentRow.zone:SetDimensions(currentZoneWidth, singleLineHeight)
        panel.currentRow.timer:SetDimensions(timerWidth, singleLineHeight)

        panel.currentRow.zone:SetAnchor(TOPLEFT, panel.currentRow, TOPLEFT, 0, 0)
        panel.currentRow.timer:SetAnchor(TOPLEFT, panel.currentRow.zone, TOPRIGHT, pairGap, 0)

        panel.currentRow.zone:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        panel.currentRow.timer:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        if panel.currentRow.zone.SetMaxLineCount then panel.currentRow.zone:SetMaxLineCount(1) end
        if panel.currentRow.timer.SetMaxLineCount then panel.currentRow.timer:SetMaxLineCount(1) end
        panel.currentRow.zone:SetHeight(singleLineHeight)
        panel.currentRow.timer:SetHeight(singleLineHeight)
    end

    for index, row in ipairs(panel.rows or {}) do
        row:SetDimensions(contentWidth, singleLineHeight)
        row:ClearAnchors()
        local previous = index == 1 and panel.currentRow or panel.rows[index - 1]
        row:SetAnchor(TOPLEFT, previous, BOTTOMLEFT, 0, index == 1 and 6 or 2)

        row.zone1:ClearAnchors()
        row.timer1:ClearAnchors()
        row.zone2:ClearAnchors()
        row.timer2:ClearAnchors()

        if row.isSingleSpan then
            local spanZoneWidth = math.max(90, contentWidth - timerWidth - pairGap)
            row.zone1:SetDimensions(spanZoneWidth, singleLineHeight)
            row.timer1:SetDimensions(timerWidth, singleLineHeight)
            row.zone2:SetDimensions(0, singleLineHeight)
            row.timer2:SetDimensions(0, singleLineHeight)

            row.zone1:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)
            row.timer1:SetAnchor(TOPLEFT, row.zone1, TOPRIGHT, pairGap, 0)
        else
            row.zone1:SetDimensions(zoneWidth, singleLineHeight)
            row.timer1:SetDimensions(timerWidth, singleLineHeight)
            row.zone2:SetDimensions(zoneWidth, singleLineHeight)
            row.timer2:SetDimensions(timerWidth, singleLineHeight)

            row.zone1:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)
            row.timer1:SetAnchor(TOPLEFT, row.zone1, TOPRIGHT, pairGap, 0)
            row.zone2:SetAnchor(TOPLEFT, row.timer1, TOPRIGHT, columnGap, 0)
            row.timer2:SetAnchor(TOPLEFT, row.zone2, TOPRIGHT, pairGap, 0)
        end

        row.zone1:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        row.timer1:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        row.zone2:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
        row.timer2:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)

        if row.zone1.SetMaxLineCount then row.zone1:SetMaxLineCount(1) end
        if row.timer1.SetMaxLineCount then row.timer1:SetMaxLineCount(1) end
        if row.zone2.SetMaxLineCount then row.zone2:SetMaxLineCount(1) end
        if row.timer2.SetMaxLineCount then row.timer2:SetMaxLineCount(1) end

        row.zone1:SetHeight(singleLineHeight)
        row.timer1:SetHeight(singleLineHeight)
        row.zone2:SetHeight(singleLineHeight)
        row.timer2:SetHeight(singleLineHeight)
    end

    local lastControl = panel.statusLabel

    if panel.channelLabel and not panel.channelLabel:IsHidden() then
        lastControl = panel.channelLabel
    elseif panel.guildLabel and not panel.guildLabel:IsHidden() then
        lastControl = panel.guildLabel
    elseif panel.commandLabel and not panel.commandLabel:IsHidden() then
        lastControl = panel.commandLabel
    end

    if panel.currentRow and not panel.currentRow:IsHidden() then
        lastControl = panel.currentRow
    elseif panel.currentLabel and not panel.currentLabel:IsHidden() then
        lastControl = panel.currentLabel
    elseif panel.listHeader and not panel.listHeader:IsHidden() then
        lastControl = panel.listHeader
    elseif panel.divider and not panel.divider:IsHidden() then
        lastControl = panel.divider
    end

    for _, row in ipairs(panel.rows or {}) do
        if row and not row:IsHidden() then
            lastControl = row
        end
    end

    panel.footerLabel:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 8)
end

function SmartChatMsg:StartStatusPanelSizeAnimation(targetWidth, targetHeight)
    local panel = self.statusPanel
    if not panel then
        return
    end

    panel.targetWidth = math.floor(targetWidth or panel:GetWidth())
    panel.targetHeight = math.floor(targetHeight or panel:GetHeight())

    if panel.isAnimatingSize then
        return
    end

    panel.isAnimatingSize = true
    EVENT_MANAGER:RegisterForUpdate(self.name .. "_StatusPanelResize", 16, function()
        local activePanel = SmartChatMsg.statusPanel
        if not activePanel then
            EVENT_MANAGER:UnregisterForUpdate(SmartChatMsg.name .. "_StatusPanelResize")
            return
        end

        local currentWidth = activePanel:GetWidth()
        local currentHeight = activePanel:GetHeight()
        local targetW = activePanel.targetWidth or currentWidth
        local targetH = activePanel.targetHeight or currentHeight

        local nextWidth = currentWidth + ((targetW - currentWidth) * 0.30)
        local nextHeight = currentHeight + ((targetH - currentHeight) * 0.30)

        if math.abs(targetW - nextWidth) < 2 then
            nextWidth = targetW
        end
        if math.abs(targetH - nextHeight) < 2 then
            nextHeight = targetH
        end

        nextWidth = math.floor(nextWidth + 0.5)
        nextHeight = math.floor(nextHeight + 0.5)

        activePanel:SetDimensions(nextWidth, nextHeight)
        SmartChatMsg:ApplyStatusPanelLayout(activePanel, nextWidth)

        if nextWidth == targetW and nextHeight == targetH then
            activePanel.isAnimatingSize = false
            EVENT_MANAGER:UnregisterForUpdate(SmartChatMsg.name .. "_StatusPanelResize")
        end
    end)
end

function SmartChatMsg:SaveStatusPanelPosition(panel)
    if not panel or not panel.GetLeft or not panel.GetTop then
        return
    end

    local left = panel:GetLeft()
    local top = panel:GetTop()
    if type(left) ~= "number" or type(top) ~= "number" then
        return
    end

    self:SetStatusPanelAnchorOffsets(math.floor(left + 0.5), math.floor(top + 0.5))
end

function SmartChatMsg:CreateStatusPanel()
    if self.statusPanel then
        return self.statusPanel
    end

    local offsetX, offsetY = self:GetStatusPanelAnchorOffsets()

    local panel = WINDOW_MANAGER:CreateTopLevelWindow("SCM_StatusPanel")
    panel:SetDimensions(460, 120)
    panel:SetHidden(true)
    panel:SetMovable(true)
    panel:SetMouseEnabled(true)
    panel:SetClampedToScreen(true)
    panel:ClearAnchors()
    panel:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, offsetX, offsetY)
    panel.cooldownScrollOffset = 0
    panel.currentCooldownRows = {}

    local backdrop = WINDOW_MANAGER:CreateControlFromVirtual("SCM_StatusPanelBackdrop", panel, "ZO_DefaultBackdrop")
    backdrop:SetAnchorFill(panel)
    backdrop:SetCenterColor(0.05, 0.05, 0.05, 0.90)
    backdrop:SetEdgeColor(0.75, 0.62, 0.28, 0.95)
    backdrop:SetMouseEnabled(true)

    local dragBar = WINDOW_MANAGER:CreateControl("SCM_StatusPanelDragBar", panel, CT_CONTROL)
    dragBar:SetDimensions(412, 22)
    dragBar:SetAnchor(TOPLEFT, panel, TOPLEFT, 16, 10)
    dragBar:SetMouseEnabled(true)

    local title = WINDOW_MANAGER:CreateControl("SCM_StatusPanelTitle", panel, CT_LABEL)
    title:SetFont("ZoFontWinH4")
    title:SetColor(0.95, 0.83, 0.46, 1)
    title:SetText("SmartChatMsg Status")
    title:SetAnchor(TOPLEFT, dragBar, TOPLEFT, 0, 0)

    local closeButton = WINDOW_MANAGER:CreateControl("SCM_StatusPanelCloseButton", panel, CT_BUTTON)
    closeButton:SetDimensions(24, 24)
    closeButton:SetAnchor(TOPRIGHT, panel, TOPRIGHT, -10, 8)
    closeButton:SetFont("ZoFontWinH3")
    closeButton:SetText("X")
    closeButton:SetNormalFontColor(0.92, 0.92, 0.92, 1)
    closeButton:SetMouseOverFontColor(1, 0.35, 0.35, 1)
    closeButton:SetPressedFontColor(0.75, 0.75, 0.75, 1)
    closeButton:SetHandler("OnClicked", function()
        SmartChatMsg:SetStatusPanelVisible(false)
    end)
    closeButton:SetHandler("OnMouseEnter", function(control)
        InitializeTooltip(InformationTooltip, control, TOP, 0, 8)
        SetTooltipText(InformationTooltip, "Close Status Panel")
    end)
    closeButton:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)

    local statusLabel = WINDOW_MANAGER:CreateControl("SCM_StatusPanelState", panel, CT_LABEL)
    statusLabel:SetFont("ZoFontGameSmall")
    statusLabel:SetAnchor(TOPLEFT, title, BOTTOMLEFT, 0, 8)

    local commandLabel = WINDOW_MANAGER:CreateControl("SCM_StatusPanelCommand", panel, CT_LABEL)
    commandLabel:SetFont("ZoFontGameSmall")
    commandLabel:SetAnchor(TOPLEFT, statusLabel, TOPRIGHT, 18, 0)

    local guildLabel = WINDOW_MANAGER:CreateControl("SCM_StatusPanelGuild", panel, CT_LABEL)
    guildLabel:SetFont("ZoFontGameSmall")
    guildLabel:SetAnchor(TOPLEFT, commandLabel, TOPRIGHT, 18, 0)

    local channelLabel = WINDOW_MANAGER:CreateControl("SCM_StatusPanelChannel", panel, CT_LABEL)
    channelLabel:SetFont("ZoFontGameSmall")
    channelLabel:SetAnchor(TOPLEFT, guildLabel, TOPRIGHT, 18, 0)

    local divider = WINDOW_MANAGER:CreateControl("SCM_StatusPanelDivider", panel, CT_BACKDROP)
    divider:SetDimensions(412, 2)
    divider:SetAnchor(TOPLEFT, statusLabel, BOTTOMLEFT, 0, 8)
    divider:SetCenterColor(0.35, 0.35, 0.35, 0.9)
    divider:SetEdgeColor(0, 0, 0, 0)

    local listHeader = WINDOW_MANAGER:CreateControl("SCM_StatusPanelListHeader", panel, CT_LABEL)
    listHeader:SetFont("ZoFontGameSmall")
    listHeader:SetColor(0.95, 0.83, 0.46, 1)
    listHeader:SetAnchor(TOPLEFT, divider, BOTTOMLEFT, 0, 8)

    local currentLabel = WINDOW_MANAGER:CreateControl("SCM_StatusPanelCurrentLabel", panel, CT_LABEL)
    currentLabel:SetFont("ZoFontGameSmall")
    currentLabel:SetColor(0.95, 0.83, 0.46, 1)
    currentLabel:SetText("Current Zone")
    currentLabel:SetAnchor(TOPLEFT, listHeader, BOTTOMLEFT, 0, 6)

    local currentRow = WINDOW_MANAGER:CreateControl("SCM_StatusPanelCurrentRow", panel, CT_CONTROL)
    currentRow:SetDimensions(412, 16)
    currentRow:SetAnchor(TOPLEFT, currentLabel, BOTTOMLEFT, 0, 2)

    local currentZone = WINDOW_MANAGER:CreateControl("SCM_StatusPanelCurrentZone", currentRow, CT_LABEL)
    currentZone:SetFont("ZoFontGameSmall")
    currentZone:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

    local currentTimer = WINDOW_MANAGER:CreateControl("SCM_StatusPanelCurrentTimer", currentRow, CT_LABEL)
    currentTimer:SetFont("ZoFontGameSmall")
    currentTimer:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

    currentRow.zone = currentZone
    currentRow.timer = currentTimer

    local rows = {}
    local previous = currentRow
    for index = 1, 10 do
        local row = WINDOW_MANAGER:CreateControl("SCM_StatusPanelRow" .. tostring(index), panel, CT_CONTROL)
        row:SetDimensions(412, 16)
        row:SetAnchor(TOPLEFT, previous, BOTTOMLEFT, 0, index == 1 and 6 or 2)

        local zone1 = WINDOW_MANAGER:CreateControl("SCM_StatusPanelRowZone1" .. tostring(index), row, CT_LABEL)
        zone1:SetFont("ZoFontGameSmall")
        zone1:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        local timer1 = WINDOW_MANAGER:CreateControl("SCM_StatusPanelRowTimer1" .. tostring(index), row, CT_LABEL)
        timer1:SetFont("ZoFontGameSmall")
        timer1:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

        local zone2 = WINDOW_MANAGER:CreateControl("SCM_StatusPanelRowZone2" .. tostring(index), row, CT_LABEL)
        zone2:SetFont("ZoFontGameSmall")
        zone2:SetHorizontalAlignment(TEXT_ALIGN_LEFT)

        local timer2 = WINDOW_MANAGER:CreateControl("SCM_StatusPanelRowTimer2" .. tostring(index), row, CT_LABEL)
        timer2:SetFont("ZoFontGameSmall")
        timer2:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)

        row.zone1 = zone1
        row.timer1 = timer1
        row.zone2 = zone2
        row.timer2 = timer2
        rows[index] = row
        previous = row
    end

    local footerLabel = WINDOW_MANAGER:CreateControl("SCM_StatusPanelFooter", panel, CT_LABEL)
    footerLabel:SetFont("ZoFontGameSmall")
    footerLabel:SetColor(0.80, 0.80, 0.80, 1)
    footerLabel:SetAnchor(TOPLEFT, previous, BOTTOMLEFT, 0, 8)

    local function beginMove(control)
        if not panel.isMoving and control == panel.dragBar then
            panel.isMoving = true
            panel:StartMoving()
        end
    end

    local function endMove(control)
        if panel.isMoving then
            panel.isMoving = false
            panel:StopMovingOrResizing()
            SmartChatMsg:SaveStatusPanelPosition(panel)
        end
    end

    dragBar:SetHandler("OnMouseDown", function(control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            beginMove(control)
        end
    end)
    dragBar:SetHandler("OnMouseUp", function(control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT then
            endMove(control)
        end
    end)
    panel:SetHandler("OnMoveStop", function()
        panel.isMoving = false
        SmartChatMsg:SaveStatusPanelPosition(panel)
    end)
    panel:SetHandler("OnMouseWheel", function(_, delta)
        local currentRows = panel.currentCooldownRows or {}
        if #currentRows <= SmartChatMsg:GetStatusPanelMaxVisibleCooldownRows() then
            return
        end
        SmartChatMsg:AdjustStatusPanelScrollOffset(delta > 0 and -1 or 1, #currentRows)
        SmartChatMsg:RefreshStatusPanel()
    end)

    panel.backdrop = backdrop
    panel.dragBar = dragBar
    panel.titleLabel = title
    panel.closeButton = closeButton
    panel.statusLabel = statusLabel
    panel.commandLabel = commandLabel
    panel.guildLabel = guildLabel
    panel.channelLabel = channelLabel
    panel.divider = divider
    panel.listHeader = listHeader
    panel.currentLabel = currentLabel
    panel.currentRow = currentRow
    panel.footerLabel = footerLabel
    panel.rows = rows

    self.statusPanel = panel
    self:ApplyStatusPanelLayout(panel, panel:GetWidth())
    return panel
end

function SmartChatMsg:RefreshStatusPanel()
    local panel = self:CreateStatusPanel()
    if not panel or panel:IsHidden() then
        return
    end

    local active = self:GetActiveAutoPopulate()
    local rows = {}

    if not active then
        panel.statusLabel:SetColor(0.82, 0.82, 0.82, 1)
        panel.statusLabel:SetText("Auto: Inactive")
        panel.commandLabel:SetHidden(true)
        panel.guildLabel:SetHidden(true)
        panel.channelLabel:SetHidden(true)
        panel.divider:SetHidden(true)
        panel.listHeader:SetHidden(true)
        panel.currentLabel:SetHidden(true)
        panel.currentRow:SetHidden(true)
        panel.footerLabel:SetHidden(false)
        panel.footerLabel:SetText("Tracked Zones: 0 | Showing 0-0")

        for _, row in ipairs(panel.rows) do
            row:SetHidden(true)
        end

        panel.currentCooldownRows = {}
        self:SetStatusPanelScrollOffset(0, 0)

        local width, height = self:GetStatusPanelTargetSize(nil, rows)
        self:StartStatusPanelSizeAnimation(width, height)
        return
    end

    local commandName = self:BuildSlashCommandName(self:GetCommandNameById(active.commandId) or "") or "/command"
    panel.statusLabel:SetColor(0.32, 0.86, 0.45, 1)
    panel.statusLabel:SetText("Auto: Active")

    panel.commandLabel:SetHidden(false)
    panel.guildLabel:SetHidden(false)
    panel.channelLabel:SetHidden(false)
    panel.divider:SetHidden(false)
    panel.listHeader:SetHidden(false)
    panel.currentLabel:SetHidden(false)
    panel.currentRow:SetHidden(false)
    panel.footerLabel:SetHidden(false)

    panel.commandLabel:SetText(tostring(commandName))
    panel.guildLabel:SetText(tostring(active.guildName))
    panel.channelLabel:SetText(tostring(self:GetAutoPopulateChannelStatusText(active.commandId, active.guildName)))
    panel.listHeader:SetText("Zone Cooldowns")
    panel.currentLabel:SetText("Current Zone")

    rows = self:GetAutoPopulateStatusRows(active.commandId, active.guildName)

    local currentRowData = nil
    local scrollRows = {}
    for _, rowData in ipairs(rows) do
        if rowData.isCurrent and not currentRowData then
            currentRowData = rowData
        else
            table.insert(scrollRows, rowData)
        end
    end

    if currentRowData then
        panel.currentRow:SetHidden(false)
        panel.currentRow.zone:SetText(tostring(currentRowData.zoneName))
        panel.currentRow.zone:SetColor(1, 1, 1, 1)
        panel.currentRow.timer:SetText(tostring(currentRowData.statusText))
        panel.currentRow.timer:SetColor(self:GetStatusPanelTimerColor(currentRowData.secondsRemaining, currentRowData.isApplicable))
    else
        panel.currentRow:SetHidden(true)
        panel.currentRow.zone:SetText("")
        panel.currentRow.timer:SetText("")
    end

    panel.currentCooldownRows = scrollRows

    local maxVisible = self:GetStatusPanelMaxVisibleCooldownRows()
    self:SetStatusPanelScrollOffset(self:GetStatusPanelScrollOffset(), #scrollRows)
    local startIndex = self:GetStatusPanelScrollOffset() + 1
    local endIndex = math.min(#scrollRows, startIndex + maxVisible - 1)

    local rowIndex = 1
    local dataIndex = startIndex
    while dataIndex <= endIndex and rowIndex <= #panel.rows do
        local row = panel.rows[rowIndex]
        local first = scrollRows[dataIndex]
        local second = nil

        local candidate = scrollRows[dataIndex + 1]
        if candidate and (dataIndex + 1) <= endIndex then
            second = candidate
        end

        row:SetHidden(false)
        row.isSingleSpan = false

        row.zone1:SetHidden(false)
        row.timer1:SetHidden(false)
        row.zone1:SetText(tostring(first.zoneName))
        row.zone1:SetColor(0.92, 0.92, 0.92, 1)
        row.timer1:SetText(tostring(first.statusText))
        row.timer1:SetColor(self:GetStatusPanelTimerColor(first.secondsRemaining, first.isApplicable))

        if second and not row.isSingleSpan then
            row.zone2:SetHidden(false)
            row.timer2:SetHidden(false)
            row.zone2:SetText(tostring(second.zoneName))
            row.zone2:SetColor(0.92, 0.92, 0.92, 1)
            row.timer2:SetText(tostring(second.statusText))
            row.timer2:SetColor(self:GetStatusPanelTimerColor(second.secondsRemaining, second.isApplicable))
        else
            row.zone2:SetHidden(true)
            row.timer2:SetHidden(true)
            row.zone2:SetText("")
            row.timer2:SetText("")
        end

        dataIndex = dataIndex + (second and 2 or 1)
        rowIndex = rowIndex + 1
    end

    for index = rowIndex, #panel.rows do
        local row = panel.rows[index]
        row:SetHidden(true)
        row.isSingleSpan = false
        row.zone1:SetText("")
        row.timer1:SetText("")
        row.zone2:SetText("")
        row.timer2:SetText("")
    end

    local showingFrom = #scrollRows > 0 and startIndex or 0
    local showingTo = #scrollRows > 0 and endIndex or 0
    local moreText = #scrollRows > maxVisible and " | Mouse wheel to scroll" or ""
    local totalTracked = #scrollRows + (currentRowData and 1 or 0)
    panel.footerLabel:SetText(string.format("Tracked Zones: %d | Other Zones %d-%d%s", totalTracked, showingFrom, showingTo, moreText))

    self:ApplyStatusPanelLayout(panel, panel:GetWidth())

    local width, height = self:GetStatusPanelTargetSize(active, rows)
    self:StartStatusPanelSizeAnimation(width, height)
end

function SmartChatMsg:SetStatusPanelVisible(shouldShow)
    local panel = self:CreateStatusPanel()
    local visible = shouldShow == true
    self.statusPanelVisible = visible
    self:SetStatusPanelVisiblePreference(visible)
    panel:SetHidden(not visible)

    EVENT_MANAGER:UnregisterForUpdate(self.statusPanelRefreshName)
    if visible then
        self:RefreshStatusPanel()
        EVENT_MANAGER:RegisterForUpdate(self.statusPanelRefreshName, 1000, function()
            SmartChatMsg:RefreshStatusPanel()
        end)
    end
end

function SmartChatMsg:ToggleStatusPanel()
    self:SetStatusPanelVisible(not self.statusPanelVisible)
end

local function OnAddonLoaded(event, addonName)
    if addonName ~= SmartChatMsg.name then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(SmartChatMsg.name, EVENT_ADD_ON_LOADED)

    SmartChatMsg:InitializeSavedVars()
    SmartChatMsg:ClearActiveAutoPopulate()
    SmartChatMsg.activeReminderStates = {}
    SmartChatMsg:ClearPendingRestoreState()
    SmartChatMsg:CreateSettingsPanel()
    SmartChatMsg:CreateStatusPanel()
    SmartChatMsg:RegisterDynamicCommands()

    if SmartChatMsg:GetStatusPanelVisiblePreference() then
        SmartChatMsg:SetStatusPanelVisible(true)
    end

    if LibDebugLogger and LibDebugLogger.Create then
        SmartChatMsg.logger = LibDebugLogger.Create("SmartChatMsg")
    else
        SmartChatMsg.logger = nil
    end

    SLASH_COMMANDS["/scm"] = function(paramText)
        local normalized = zo_strlower(SmartChatMsg:Trim(paramText or ""))
        if normalized == "status" then
            SmartChatMsg:ToggleStatusPanel()
            return
        elseif normalized ~= "" then
            d("[SmartChatMsg] Usage: /scm or /scm status")
            return
        end

        SmartChatMsg:OpenSettings()
    end

    SLASH_COMMANDS["/scmdebug"] = function(paramText)
        local normalized = zo_strlower(SmartChatMsg:Trim(paramText or ""))

        if normalized == "" then
            SmartChatMsg.debugEnabled = not SmartChatMsg.debugEnabled
        elseif normalized == "on" or normalized == "1" or normalized == "true" then
            SmartChatMsg.debugEnabled = true
        elseif normalized == "off" or normalized == "0" or normalized == "false" then
            SmartChatMsg.debugEnabled = false
        elseif normalized == "status" then
            d("[SmartChatMsg] Debug is " .. (SmartChatMsg.debugEnabled and "ON" or "OFF"))
            return
        else
            d("[SmartChatMsg] Usage: /scmdebug, /scmdebug on, /scmdebug off, /scmdebug status")
            return
        end

        d("[SmartChatMsg] Debug is now " .. (SmartChatMsg.debugEnabled and "ON" or "OFF"))
    end

    EVENT_MANAGER:RegisterForEvent(SmartChatMsg.name .. "_PlayerActivated", EVENT_PLAYER_ACTIVATED, function()
        SmartChatMsg:HandleZoneAutoPopulate()
        SmartChatMsg:InitializeStartupQueueOnce()
    end)
end

EVENT_MANAGER:RegisterForEvent(SmartChatMsg.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)