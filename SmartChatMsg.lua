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

    local retryMinutes = self:GetGuildReminderRetryMinutes(commandId, guildName) or 5
    local timerName = self:GetReminderTimerName(commandId, guildName)
    if not timerName then
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
    if type(metadata) == "table" and metadata.autoPopulate == true then
        self:DebugLog(string.format(
            "Auto populate debug: confirmed sent by watcher for commandId=%s guildName=%s zoneId=%s",
            tostring(metadata.commandId),
            tostring(metadata.guildName),
            tostring(metadata.zoneId)
        ))
        self:MarkAutoPopulateSent(metadata.commandId, metadata.guildName, metadata.zoneId)
    elseif type(metadata) == "table" and metadata.reminderRepeat == true then
        self:HandleReminderPopulateSuccess(metadata)
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


function SmartChatMsg:IsInParentZone(zoneId)
    if type(zoneId) ~= "number" or zoneId == 0 then
        return false
    end

    local parentZoneId = GetParentZoneId(zoneId)
    if not parentZoneId or parentZoneId == 0 or parentZoneId == zoneId then
        return true
    end

    return false
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
end


function SmartChatMsg:HandleZoneAutoPopulate()
    local currentZoneId = GetZoneId(GetUnitZoneIndex("player"))
    local previousZoneId = self.lastKnownZoneId

    self.lastKnownZoneId = currentZoneId

    if not self.hasSeenInitialPlayerActivated then
        self.hasSeenInitialPlayerActivated = true
        self:DebugLog("Auto populate debug: initial player activation seen, skipping")
        return
    end

    if not currentZoneId or currentZoneId == 0 then
        self:DebugLog("Auto populate debug: current zone id was invalid")
        return
    end

    if not previousZoneId or previousZoneId == 0 or previousZoneId == currentZoneId then
        self:DebugLog(string.format(
            "Auto populate debug: zone change ignored previousZoneId=%s currentZoneId=%s",
            tostring(previousZoneId),
            tostring(currentZoneId)
        ))
        return
    end

    if not self:IsInParentZone(currentZoneId) then
        self:DebugLog(string.format(
            "Auto populate debug: skipped because currentZoneId=%s is not a parent zone",
            tostring(currentZoneId)
        ))
        return
    end

    local active = self:GetActiveAutoPopulate()
    if not active then
        self:DebugLog("Auto populate debug: no active auto populate command")
        return
    end

    local shouldSkip, elapsed, cooldown = self:ShouldSkipAutoPopulateForZone(active.commandId, active.guildName, currentZoneId)
    if shouldSkip then
        self:DebugLog(string.format(
            "Auto populate debug: skipped for commandId=%s guildName=%s zoneId=%s because elapsed=%s cooldown=%s",
            tostring(active.commandId),
            tostring(active.guildName),
            tostring(currentZoneId),
            tostring(elapsed),
            tostring(cooldown)
        ))
        return
    end

    self:DebugLog(string.format(
        "Auto populate debug: firing for commandId=%s guildName=%s currentZoneId=%s previousZoneId=%s",
        tostring(active.commandId),
        tostring(active.guildName),
        tostring(currentZoneId),
        tostring(previousZoneId)
    ))

    local ok, err = self:PopulateChatBufferForCommand(
        active.commandId,
        active.guildName,
        nil,
        {
            autoPopulate = true,
            commandId = active.commandId,
            guildName = active.guildName,
            zoneId = currentZoneId,
        }
    )

    if not ok then
        self:ClearActiveAutoPopulate()
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
        return
    end

    local command = self:GetCommandById(active.commandId)
    if command then
        local commandName = self:BuildSlashCommandName(command.name or "") or "command"
        local zoneName = self:GetAutoPopulateZoneDisplayName(currentZoneId)
        local message = string.format("Auto populated %s for %s. Run the command again to turn it off.", commandName, zoneName)
        if CENTER_SCREEN_ANNOUNCE then
            CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, message)
        else
            d(message)
        end
    end

    PlaySound(SOUNDS.DEFAULT_CLICK)
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

    local armedRestore = self:ArmPendingRestoreState(previousChannelInfo, resolvedMessageText, restoreMetadata)
    self:DebugLog("PopulateChatBufferForCommand armedRestore=" .. tostring(armedRestore))

    if channel == "Zone" then
        self:DebugLog("PopulateChatBufferForCommand starting chat input for Zone")
        StartChatInput(resolvedMessageText, CHAT_CHANNEL_ZONE)

        if type(restoreMetadata) == "table" and (restoreMetadata.autoPopulate == true or restoreMetadata.reminderRepeat == true) then
            self:DebugLog(string.format(
                "PopulateChatBufferForCommand playing populate sound for commandId=%s guildName=%s autoPopulate=%s reminderRepeat=%s",
                tostring(commandId),
                tostring(guildName),
                tostring(restoreMetadata.autoPopulate == true),
                tostring(restoreMetadata.reminderRepeat == true)
            ))
            self:PlayPopulateSound(commandId, guildName)
        end

        self:MarkMessageEntryUsed(selectedEntry)
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
            self:MarkMessageEntryUsed(selectedEntry)
            return true
        end

        local channelId = CHAT_CHANNEL_OFFICER_1 + (guildSlot - 1)
        self:DebugLog("PopulateChatBufferForCommand starting chat input for Officer channelId=" .. tostring(channelId))
        StartChatInput(resolvedMessageText, channelId)
        self:MarkMessageEntryUsed(selectedEntry)
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

    local numericParam = tonumber(trimmed)
    if numericParam and numericParam >= 1 and numericParam <= 5 and numericParam == math.floor(numericParam) then
        return {
            guildSlot = numericParam,
            channelOverride = nil, -- use saved channel
            reminderParamText = tostring(numericParam),
        }
    end

    local prefix, slotText = trimmed:match("^([go])([1-5])$")
    if prefix and slotText then
        local guildSlot = tonumber(slotText)
        return {
            guildSlot = guildSlot,
            channelOverride = (prefix == "g") and "Guild" or "Officer",
            reminderParamText = trimmed,
        }
    end

    return false
end

function SmartChatMsg:HandleDynamicSlashCommand(commandId, slashCommandName, rawParam)
    local trimmedParam = self:Trim(rawParam or "")
    local guildSlot = nil
    local channelOverride = nil
    local reminderParamText = nil

    if trimmedParam ~= "" then
        local parsed = self:ParseCommandParameter(trimmedParam)

        if parsed == false then
            ZO_Alert(
                UI_ALERT_CATEGORY_ERROR,
                SOUNDS.NEGATIVE_CLICK,
                string.format("%s requires 1-5, g1-g5, or o1-o5.", slashCommandName)
            )
            return
        end

        guildSlot = parsed.guildSlot
        channelOverride = parsed.channelOverride
        reminderParamText = parsed.reminderParamText
    else
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
        "HandleDynamicSlashCommand commandId=%s slashCommand=%s guildSlot=%s guildName=%s channelOverride=%s rawParam=%s",
        tostring(commandId),
        tostring(slashCommandName),
        tostring(guildSlot),
        tostring(guildName),
        tostring(channelOverride),
        tostring(trimmedParam)
    ))

    local toggledMessages = {}

    if self:ToggleOffActiveAutoPopulateIfMatching(commandId, guildName) then
        table.insert(toggledMessages, string.format("%s auto populate has been turned off.", slashCommandName))
    end

    if self:IsReminderAutomationActive(commandId, guildName) then
        self:DeactivateReminderAutomation(commandId, guildName, "matching reminder toggled off")
        table.insert(toggledMessages, string.format("%s repeat-after has been turned off.", slashCommandName))
    end

    if #toggledMessages > 0 then
        local message = table.concat(toggledMessages, " ")
        if CENTER_SCREEN_ANNOUNCE then
            CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, message)
        else
            d(message)
        end
        PlaySound(SOUNDS.DEFAULT_CLICK)
        return
    end

    local activeAutoPopulate = self:GetActiveAutoPopulate()
    if activeAutoPopulate and self:GetGuildAutoPopulateOnZone(commandId, guildName) then
        ZO_Alert(
            UI_ALERT_CATEGORY_ERROR,
            SOUNDS.NEGATIVE_CLICK,
            string.format("%s cannot start auto populate because %s is already running for %s.", slashCommandName, self:BuildSlashCommandName(self:GetCommandNameById(activeAutoPopulate.commandId) or "command") or "another command", tostring(activeAutoPopulate.guildName))
        )
        return
    end

    local ok, err = self:PopulateChatBufferForCommand(commandId, guildName, channelOverride)
    if not ok then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
        return
    end

    self:MarkCommandUsed(commandId, guildName, reminderParamText, guildSlot)
    self:ScheduleCommandReminder(commandId, guildName)

    if self:GetGuildAutoPopulateOnZone(commandId, guildName) then
        self:SetActiveAutoPopulate(commandId, guildName)
    end

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
    SmartChatMsg:RegisterDynamicCommands()

    if LibDebugLogger and LibDebugLogger.Create then
        SmartChatMsg.logger = LibDebugLogger.Create("SmartChatMsg")
    else
        SmartChatMsg.logger = nil
    end

    SLASH_COMMANDS["/scm"] = function()
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
    end)
end

EVENT_MANAGER:RegisterForEvent(SmartChatMsg.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)