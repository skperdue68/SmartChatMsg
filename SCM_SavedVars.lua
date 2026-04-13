SmartChatMsg = SmartChatMsg or {}
SmartChatMsg.name = SmartChatMsg.name or "SmartChatMsg"

SmartChatMsg.defaults = {
    commands = {}, -- { { id = "...", name = "...", reminderMinutes = n|nil, lastUsedAt = unixTime|nil }, ... }
    selectedCommand = nil, -- commandId

    messages = {}, -- { { id = "...", commandId = "...", guildIndex = n, guildName = "...", text = "..." }, ... }

    chatChannels = {}, -- [commandId] = { [guildKey] = "Zone"|"Guild"|"Officer" }
    commandGuildSettings = {}, -- [commandId] = { [guildKey] = { reminderMinutes = n|nil, reminderRetryMinutes = n, autoPopulateOnZone = bool, autoPopulateCooldownMinutes = n, runAt = "ON_DEMAND"|"STARTUP"|"SCHEDULED", openStatusPanelOnRun = bool, populateSound = "DUEL_START"|"NONE"|soundKey, lastUsedAt = unixTime|nil, lastUsedParamText = "..."|nil, lastUsedGuildIndex = n|nil, lastAutoPopulateSentAtByZone = { [zoneKey] = unixTime, ... } }, ... }

    selectedMessagesCommand = nil, -- commandId
    selectedMessagesGuildIndex = nil,
    selectedMessagesChannel = nil,

    defaultGuildIndex = nil,
    revertChatSeconds = 60,
    activeAutoPopulate = nil, -- { commandId = "...", guildName = "..." }
    globalExecutionStatus = "available",
    statusPanelState = {
        visible = false,
        offsetX = -40,
        offsetY = 180,
    },
}

function SmartChatMsg:InitializeSavedVars()
    self.savedVars = ZO_SavedVars:NewAccountWide("SmartChatMsgSavedVars", 1, nil, self.defaults)

    if type(self.savedVars.commands) ~= "table" then
        self.savedVars.commands = {}
    end

    if type(self.savedVars.messages) ~= "table" then
        self.savedVars.messages = {}
    end

    if type(self.savedVars.chatChannels) ~= "table" then
        self.savedVars.chatChannels = {}
    end

    if type(self.savedVars.commandGuildSettings) ~= "table" then
        self.savedVars.commandGuildSettings = {}
    end

    if type(self.savedVars.defaultGuildIndex) ~= "number"
        or self.savedVars.defaultGuildIndex < 1
        or self.savedVars.defaultGuildIndex > 5
        or self.savedVars.defaultGuildIndex ~= math.floor(self.savedVars.defaultGuildIndex) then
        self.savedVars.defaultGuildIndex = nil
    end

    if self.savedVars.defaultGuildIndex then
        local guildId = GetGuildId(self.savedVars.defaultGuildIndex)
        if not guildId or guildId == 0 then
            self.savedVars.defaultGuildIndex = nil
        end
    end

    self.savedVars.revertChatSeconds = self:NormalizeRevertChatSeconds(self.savedVars.revertChatSeconds)

    if self.savedVars.globalExecutionStatus ~= "busy" and self.savedVars.globalExecutionStatus ~= "available" then
        self.savedVars.globalExecutionStatus = "available"
    end

    self.savedVars.globalExecutionStatus = "available"

    if type(self.savedVars.statusPanelState) ~= "table" then
        self.savedVars.statusPanelState = {
            visible = false,
            offsetX = -40,
            offsetY = 180,
        }
    else
        local state = self.savedVars.statusPanelState
        state.visible = state.visible == true

        if type(state.offsetX) ~= "number" then
            state.offsetX = -40
        else
            state.offsetX = math.floor(state.offsetX)
        end

        if type(state.offsetY) ~= "number" then
            state.offsetY = 180
        else
            state.offsetY = math.floor(state.offsetY)
        end
    end

    if type(self.savedVars.activeAutoPopulate) ~= "table" then
        self.savedVars.activeAutoPopulate = nil
    else
        local active = self.savedVars.activeAutoPopulate
        if type(active.commandId) ~= "string" or active.commandId == ""
            or type(active.guildName) ~= "string" or self:Trim(active.guildName) == "" then
            self.savedVars.activeAutoPopulate = nil
        else
            active.guildName = self:Trim(active.guildName)
        end
    end

    for _, command in ipairs(self.savedVars.commands) do
        if type(command) == "table" then
            command.name = self:SanitizeCommandName(command.name or "")
            command.reminderMinutes = self:NormalizeReminderMinutes(command.reminderMinutes)

            if type(command.lastUsedAt) ~= "number" or command.lastUsedAt < 0 then
                command.lastUsedAt = nil
            else
                command.lastUsedAt = math.floor(command.lastUsedAt)
            end
        end
    end


    for commandId, byGuild in pairs(self.savedVars.commandGuildSettings) do
        if type(commandId) ~= "string" or commandId == "" or type(byGuild) ~= "table" then
            self.savedVars.commandGuildSettings[commandId] = nil
        else
            local cleanedByGuild = {}
            for guildKey, settings in pairs(byGuild) do
                local normalizedGuildKey = self:NormalizeKey(guildKey)
                if normalizedGuildKey and type(settings) == "table" then
                    local cleanedZoneTimestamps = {}

                    if type(settings.lastAutoPopulateSentAtByZone) == "table" then
                        for zoneKey, timestamp in pairs(settings.lastAutoPopulateSentAtByZone) do
                            local normalizedZoneKey = tostring(zoneKey or "")
                            if normalizedZoneKey ~= "" and type(timestamp) == "number" and timestamp >= 0 then
                                cleanedZoneTimestamps[normalizedZoneKey] = math.floor(timestamp)
                            end
                        end
                    end

                    cleanedByGuild[normalizedGuildKey] = {
                        reminderMinutes = self:NormalizeReminderMinutes(settings.reminderMinutes),
                        reminderRetryMinutes = self:NormalizeReminderRetryMinutes(settings.reminderRetryMinutes),
                        autoPopulateOnZone = self:NormalizeAutoPopulateOnZone(settings.autoPopulateOnZone),
                        autoPopulateCooldownMinutes = self:NormalizeAutoPopulateCooldownMinutes(settings.autoPopulateCooldownMinutes),
                        runAt = self:NormalizeRunAt(settings.runAt),
                        openStatusPanelOnRun = self:NormalizeOpenStatusPanelOnRun(settings.openStatusPanelOnRun),
                        populateSound = self:NormalizePopulateSound(settings.populateSound),
                        lastUsedAt = (type(settings.lastUsedAt) == "number" and settings.lastUsedAt >= 0) and math.floor(settings.lastUsedAt) or nil,
                        lastUsedParamText = self:Trim(settings.lastUsedParamText or ""),
                        lastUsedGuildIndex = (type(settings.lastUsedGuildIndex) == "number" and settings.lastUsedGuildIndex >= 1 and settings.lastUsedGuildIndex <= 5 and settings.lastUsedGuildIndex == math.floor(settings.lastUsedGuildIndex)) and settings.lastUsedGuildIndex or nil,
                        lastAutoPopulateSentAtByZone = cleanedZoneTimestamps,
                    }

                    if cleanedByGuild[normalizedGuildKey].lastUsedParamText == "" then
                        cleanedByGuild[normalizedGuildKey].lastUsedParamText = nil
                    end
                end
            end
            self.savedVars.commandGuildSettings[commandId] = next(cleanedByGuild) and cleanedByGuild or nil
        end
    end

    for _, command in ipairs(self.savedVars.commands) do
        if type(command) == "table" and type(command.id) == "string" and command.id ~= "" then
            local legacyAutoPopulateOnZone = self:NormalizeAutoPopulateOnZone(command.autoPopulateOnZone)

            if command.reminderMinutes ~= nil or legacyAutoPopulateOnZone ~= nil then
                local knownGuildNames = {}
                if type(self.savedVars.chatChannels[command.id]) == "table" then
                    for guildKey, _ in pairs(self.savedVars.chatChannels[command.id]) do
                        knownGuildNames[guildKey] = guildKey
                    end
                end

                for _, entry in ipairs(self:GetSavedMessageEntriesArray()) do
                    if type(entry) == "table" and entry.commandId == command.id then
                        local guildName = entry.guildName
                        if (not guildName or guildName == "") and entry.guildIndex then
                            guildName = self:GetGuildNameByIndex(entry.guildIndex)
                        end
                        local guildKey = self:NormalizeKey(guildName)
                        if guildKey then
                            knownGuildNames[guildKey] = guildName
                        end
                    end
                end

                for guildKey, guildName in pairs(knownGuildNames) do
                    local settings = self:GetCommandGuildSettings(command.id, guildName, true)
                    if settings.reminderMinutes == nil then
                        settings.reminderMinutes = self:NormalizeReminderMinutes(command.reminderMinutes)
                    end
                    if settings.reminderRetryMinutes == nil then
                        settings.reminderRetryMinutes = self:NormalizeReminderRetryMinutes(nil)
                    end
                    if settings.autoPopulateOnZone == nil and legacyAutoPopulateOnZone ~= nil then
                        settings.autoPopulateOnZone = legacyAutoPopulateOnZone
                    end
                    if settings.autoPopulateCooldownMinutes == nil then
                        settings.autoPopulateCooldownMinutes = self:NormalizeAutoPopulateCooldownMinutes(nil)
                    end
                    if settings.runAt == nil then
                        settings.runAt = self:NormalizeRunAt(nil)
                    end
                    if settings.openStatusPanelOnRun == nil then
                        settings.openStatusPanelOnRun = self:NormalizeOpenStatusPanelOnRun(nil)
                    end
                    if settings.populateSound == nil then
                        settings.populateSound = self:NormalizePopulateSound(nil)
                    end
                end
            end

            command.autoPopulateOnZone = nil
        end
    end

    local normalizedMessages = {}
    for _, entry in ipairs(self:GetSavedMessageEntriesArray()) do
        if type(entry) == "table" then
            local commandId = type(entry.commandId) == "string" and entry.commandId or ""
            local guildName = self:Trim(entry.guildName or "")

            if guildName == "" and entry.guildIndex then
                guildName = self:Trim(self:GetGuildNameByIndex(entry.guildIndex) or "")
                if guildName ~= "" then
                    entry.guildName = guildName
                end
            end

            local messageText = self:Trim(entry.text or "")
            local entryId = nil
            if commandId ~= "" and messageText ~= "" then
                entryId = self:GenerateMessageEntryIdForCommandGuild(commandId, guildName, messageText)
            end

            entryId = self:Trim(entryId or entry.id or "")
            if entryId == "" then
                entryId = self:GenerateUuid()
            end

            entry.commandName = self:GetMessageCommandName(commandId, entry)
            entry.id = entryId

            if normalizedMessages[entryId] and normalizedMessages[entryId] ~= entry then
                local counter = 2
                local uniqueId = entryId .. "_" .. tostring(counter)
                while normalizedMessages[uniqueId] do
                    counter = counter + 1
                    uniqueId = entryId .. "_" .. tostring(counter)
                end
                entryId = uniqueId
                entry.id = entryId
            end

            normalizedMessages[entryId] = entry
        end
    end
    self.savedVars.messages = normalizedMessages
end

function SmartChatMsg:Trim(value)
    if type(value) ~= "string" then
        return ""
    end

    return value:match("^%s*(.-)%s*$") or ""
end

function SmartChatMsg:StringsEqualIgnoreCase(a, b)
    if type(a) ~= "string" or type(b) ~= "string" then
        return false
    end

    return zo_strlower(a) == zo_strlower(b)
end

function SmartChatMsg:NormalizeKey(value)
    local trimmed = self:Trim(value or "")
    if trimmed == "" then
        return nil
    end

    return zo_strlower(trimmed)
end

function SmartChatMsg:SanitizeCommandName(value)
    local trimmed = self:Trim(value or "")
    if trimmed == "" then
        return ""
    end

    return (trimmed:gsub("[^%w]", ""))
end

function SmartChatMsg:NormalizeReminderMinutes(value)
    if value == nil then
        return nil
    end

    if type(value) == "string" then
        value = self:Trim(value)
        if value == "" then
            return nil
        end
    end

    local numericValue = tonumber(value)
    if not numericValue or numericValue <= 0 or numericValue ~= math.floor(numericValue) then
        return nil
    end

    return numericValue
end

function SmartChatMsg:NormalizeReminderRetryMinutes(value)
    if value == nil then
        return 0
    end

    if type(value) == "string" then
        value = self:Trim(value)
        if value == "" then
            return 0
        end
    end

    local numericValue = tonumber(value)
    if not numericValue or numericValue ~= math.floor(numericValue) or numericValue <= 0 then
        return 0
    end

    return numericValue
end

function SmartChatMsg:NormalizeAutoPopulateOnZone(value)
    return value == true
end

function SmartChatMsg:NormalizeAutoPopulateCooldownMinutes(value)
    if value == nil then
        return 60
    end

    if type(value) == "string" then
        value = self:Trim(value)
        if value == "" then
            return 60
        end
    end

    local numericValue = tonumber(value)
    if not numericValue or numericValue <= 0 or numericValue ~= math.floor(numericValue) then
        return 60
    end

    return numericValue
end

function SmartChatMsg:NormalizePopulateSound(value)
    local normalized = zo_strupper(self:Trim(tostring(value or "DUEL_START")))
    if normalized == "" then
        normalized = "DUEL_START"
    end

    if normalized == "NONE" then
        return "NONE"
    end

    if type(SOUNDS) == "table" and SOUNDS[normalized] then
        return normalized
    end

    return "DUEL_START"
end

function SmartChatMsg:NormalizeRunAt(value)
    local normalized = zo_strupper(self:Trim(tostring(value or "ON_DEMAND")))
    if normalized == "STARTUP" or normalized == "SCHEDULED" then
        return normalized
    end

    return "ON_DEMAND"
end

function SmartChatMsg:NormalizeOpenStatusPanelOnRun(value)
    return value == true
end

function SmartChatMsg:NormalizeRevertChatSeconds(value)
    if value == nil then
        return 60
    end

    if type(value) == "string" then
        value = self:Trim(value)
        if value == "" then
            return 60
        end
    end

    local numericValue = tonumber(value)
    if not numericValue or numericValue ~= math.floor(numericValue) or numericValue < 30 then
        return 30
    end

    return numericValue
end

function SmartChatMsg:GenerateUuid()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return (template:gsub("[xy]", function(c)
        local value
        if c == "x" then
            value = zo_random(0, 15)
        else
            value = zo_random(8, 11)
        end
        return string.format("%x", value)
    end))
end

function SmartChatMsg:BuildDeterministicMessageHash(sourceText)
    local hash = 5381
    local text = tostring(sourceText or "")

    for index = 1, #text do
        local byteValue = string.byte(text, index)
        hash = ((hash * 33) + byteValue) % 4294967296
    end

    return string.format("%08X", hash)
end

function SmartChatMsg:BuildMessageIdentitySource(channel, guildName, messageText)
    local normalizedChannel = self:Trim(channel or "")
    local normalizedGuildName = self:Trim(guildName or "")
    local normalizedMessageText = self:Trim(messageText or "")

    if normalizedChannel == "Zone" then
        return normalizedMessageText
    end

    return normalizedGuildName .. "||" .. normalizedMessageText
end

function SmartChatMsg:GenerateMessageEntryIdForChannel(channel, guildName, messageText)
    return self:BuildDeterministicMessageHash(self:BuildMessageIdentitySource(channel, guildName, messageText))
end

function SmartChatMsg:GetMessageEntryChannel(commandId, guildName)
    local channel = self:GetSavedChatChannel(commandId, guildName)
    channel = self:Trim(channel or "")

    if channel == "Guild" or channel == "Officer" or channel == "Zone" then
        return channel
    end

    return "Guild"
end

function SmartChatMsg:GenerateMessageEntryIdForCommandGuild(commandId, guildName, messageText)
    return self:GenerateMessageEntryIdForChannel(self:GetMessageEntryChannel(commandId, guildName), guildName, messageText)
end

function SmartChatMsg:BuildSavedMessageEntryIdLookup()
    local lookup = {}

    for entryId, entry in pairs(self.savedVars.messages or {}) do
        if type(entry) == "table" then
            local normalizedEntryId = type(entry.id) == "string" and entry.id ~= "" and entry.id or tostring(entryId or "")
            if normalizedEntryId ~= "" then
                entry.id = normalizedEntryId
                lookup[normalizedEntryId] = entry
            end
        end
    end

    return lookup
end

function SmartChatMsg:GetMessageCommandName(commandId, fallbackEntry)
    local commandName = self:Trim(self:GetCommandNameById(commandId) or "")
    if commandName ~= "" then
        return commandName
    end

    if type(fallbackEntry) == "table" then
        commandName = self:Trim(fallbackEntry.commandName or "")
        if commandName ~= "" then
            return commandName
        end
    end

    return nil
end

function SmartChatMsg:GetSavedMessageEntriesTable()
    if type(self.savedVars.messages) ~= "table" then
        self.savedVars.messages = {}
    end

    return self.savedVars.messages
end

function SmartChatMsg:GetSavedMessageEntriesArray()
    local results = {}

    for entryId, entry in pairs(self:GetSavedMessageEntriesTable()) do
        if type(entry) == "table" then
            if type(entry.id) ~= "string" or entry.id == "" then
                entry.id = tostring(entryId or "")
            end
            table.insert(results, entry)
        end
    end

    table.sort(results, function(a, b)
        local aId = type(a) == "table" and a.id or ""
        local bId = type(b) == "table" and b.id or ""
        return tostring(aId) < tostring(bId)
    end)

    return results
end

function SmartChatMsg:GetSavedMessageEntryById(entryId)
    if type(entryId) ~= "string" or entryId == "" then
        return nil
    end

    local entry = self:GetSavedMessageEntriesTable()[entryId]
    if type(entry) ~= "table" then
        return nil
    end

    if type(entry.id) ~= "string" or entry.id == "" then
        entry.id = entryId
    end

    return entry
end

function SmartChatMsg:SetSavedMessageEntry(entryId, entry)
    if type(entryId) ~= "string" or entryId == "" or type(entry) ~= "table" then
        return
    end

    entry.id = entryId
    self:GetSavedMessageEntriesTable()[entryId] = entry
end

function SmartChatMsg:RemoveSavedMessageEntry(entryId)
    if type(entryId) ~= "string" or entryId == "" then
        return
    end

    self:GetSavedMessageEntriesTable()[entryId] = nil
end


function SmartChatMsg:EscapeImportExportField(value)
    local text = tostring(value or "")
    text = text:gsub("%%", "%%25")
    text = text:gsub(string.char(13), "%%0D")
    text = text:gsub(string.char(10), "%%0A")
    text = text:gsub("|", "%%7C")
    return text
end

function SmartChatMsg:UnescapeImportExportField(value)
    local text = tostring(value or "")
    text = text:gsub("%%0D", string.char(13))
    text = text:gsub("%%0A", string.char(10))
    text = text:gsub("%%7C", "|")
    text = text:gsub("%%25", "%%")
    return text
end

function SmartChatMsg:BuildExportString()
    local lines = { "SCM_EXPORT_V1" }

    table.insert(lines, string.format("DEFAULT|%s", self:EscapeImportExportField(self.savedVars.defaultGuildIndex or "")))
    table.insert(lines, string.format("GENERALREVERT|%s", self:EscapeImportExportField(self.savedVars.revertChatSeconds or 60)))

    for _, command in ipairs(self.savedVars.commands or {}) do
        if type(command) == "table" then
            table.insert(lines, table.concat({
                "COMMAND",
                self:EscapeImportExportField(command.id or ""),
                self:EscapeImportExportField(command.name or ""),
                self:EscapeImportExportField(command.reminderMinutes or ""),
                self:EscapeImportExportField(command.lastUsedAt or ""),
            }, "|"))
        end
    end

    for _, entry in ipairs(self:GetSavedMessageEntriesArray()) do
        if type(entry) == "table" then
            table.insert(lines, table.concat({
                "MESSAGE",
                self:EscapeImportExportField(entry.id or ""),
                self:EscapeImportExportField(entry.commandId or ""),
                self:EscapeImportExportField(entry.guildIndex or ""),
                self:EscapeImportExportField(entry.guildName or ""),
                self:EscapeImportExportField(entry.text or ""),
                self:EscapeImportExportField(entry.lastUsedAt or ""),
                self:EscapeImportExportField(entry.useCount or ""),
                self:EscapeImportExportField(entry.commandName or self:GetMessageCommandName(entry.commandId, entry) or ""),
            }, "|"))
        end
    end

    for commandId, byGuild in pairs(self.savedVars.chatChannels or {}) do
        if type(byGuild) == "table" then
            for guildKey, channel in pairs(byGuild) do
                table.insert(lines, table.concat({
                    "CHANNEL",
                    self:EscapeImportExportField(commandId),
                    self:EscapeImportExportField(guildKey),
                    self:EscapeImportExportField(channel),
                }, "|"))
            end
        end
    end

    for commandId, byGuild in pairs(self.savedVars.commandGuildSettings or {}) do
        if type(byGuild) == "table" then
            for guildKey, settings in pairs(byGuild) do
                if type(settings) == "table" then
                    local zonePairs = {}
                    if type(settings.lastAutoPopulateSentAtByZone) == "table" then
                        for zoneKey, timestamp in pairs(settings.lastAutoPopulateSentAtByZone) do
                            if type(timestamp) == "number" and timestamp > 0 then
                                table.insert(zonePairs, tostring(zoneKey) .. "=" .. tostring(math.floor(timestamp)))
                            end
                        end
                    end

                    table.insert(lines, table.concat({
                        "GUILDSETTING",
                        self:EscapeImportExportField(commandId),
                        self:EscapeImportExportField(guildKey),
                        self:EscapeImportExportField(settings.reminderMinutes or ""),
                        self:EscapeImportExportField(settings.reminderRetryMinutes or 0),
                        self:EscapeImportExportField(settings.autoPopulateOnZone == true and "1" or "0"),
                        self:EscapeImportExportField(settings.autoPopulateCooldownMinutes or 60),
                        self:EscapeImportExportField(settings.lastUsedAt or ""),
                        self:EscapeImportExportField(settings.lastUsedParamText or ""),
                        self:EscapeImportExportField(settings.lastUsedGuildIndex or ""),
                        self:EscapeImportExportField(table.concat(zonePairs, ",")),
                        self:EscapeImportExportField(settings.populateSound or "DUEL_START"),
                        self:EscapeImportExportField(settings.runAt or "ON_DEMAND"),
                        self:EscapeImportExportField(settings.openStatusPanelOnRun == true and "1" or "0"),
                    }, "|"))
                end
            end
        end
    end

    local active = self.savedVars.activeAutoPopulate
    if type(active) == "table" then
        table.insert(lines, table.concat({
            "ACTIVE",
            self:EscapeImportExportField(active.commandId or ""),
            self:EscapeImportExportField(active.guildName or ""),
        }, "|"))
    end

    table.insert(lines, "END")
    return table.concat(lines, string.char(10))
end

function SmartChatMsg:ApplyImportedSettings(imported)
    if type(imported) ~= "table" then
        return false, "Import data is invalid."
    end

    self.savedVars.commands = imported.commands or {}
    self.savedVars.messages = imported.messages or {}
    self.savedVars.chatChannels = imported.chatChannels or {}
    self.savedVars.commandGuildSettings = imported.commandGuildSettings or {}
    self.savedVars.defaultGuildIndex = imported.defaultGuildIndex
    self.savedVars.revertChatSeconds = self:NormalizeRevertChatSeconds(imported.revertChatSeconds)
    self.savedVars.activeAutoPopulate = imported.activeAutoPopulate
    self.savedVars.selectedCommand = nil
    self.savedVars.selectedMessagesCommand = nil
    self.savedVars.selectedMessagesGuildIndex = nil
    self.savedVars.selectedMessagesChannel = nil

    self:InitializeSavedVars()

    if self.RegisterDynamicCommands then
        self:RegisterDynamicCommands()
    end

    return true
end

function SmartChatMsg:ImportSettingsFromString(rawText)
    local text = self:Trim(rawText or "")
    if text == "" then
        return false, "Paste exported settings first."
    end

    local lines = {}
    local normalizedText = text:gsub(string.char(13), "")
    for line in (normalizedText .. string.char(10)):gmatch("(.-)" .. string.char(10)) do
        if line ~= "" then
            table.insert(lines, line)
        end
    end

    if #lines == 0 or lines[1] ~= "SCM_EXPORT_V1" then
        return false, "Import text must start with SCM_EXPORT_V1."
    end

    local imported = {
        commands = {},
        messages = {},
        chatChannels = {},
        commandGuildSettings = {},
        defaultGuildIndex = nil,
        revertChatSeconds = 60,
        activeAutoPopulate = nil,
    }

    local commandIds = {}
    local messageIds = {}

    for index = 2, #lines do
        local line = lines[index]
        if line == "END" then
            break
        end

        local parts = {}
        for part in (line .. "|"):gmatch("(.-)|") do
            table.insert(parts, part)
        end

        local recordType = table.remove(parts, 1)

        if recordType == "DEFAULT" then
            local guildIndex = tonumber(self:UnescapeImportExportField(parts[1] or ""))
            if guildIndex and guildIndex >= 1 and guildIndex <= 5 and guildIndex == math.floor(guildIndex) then
                imported.defaultGuildIndex = guildIndex
            end
        elseif recordType == "GENERALREVERT" then
            imported.revertChatSeconds = self:NormalizeRevertChatSeconds(self:UnescapeImportExportField(parts[1] or ""))
        elseif recordType == "COMMAND" then
            local id = self:UnescapeImportExportField(parts[1] or "")
            local name = self:SanitizeCommandName(self:UnescapeImportExportField(parts[2] or ""))
            local reminderMinutes = self:NormalizeReminderMinutes(self:UnescapeImportExportField(parts[3] or ""))
            local lastUsedAt = nil

            if parts[5] ~= nil then
                -- Legacy format: COMMAND|id|name|reminderMinutes|autoPopulateOnZone|lastUsedAt
                lastUsedAt = tonumber(self:UnescapeImportExportField(parts[5] or ""))
            else
                -- Current format: COMMAND|id|name|reminderMinutes|lastUsedAt
                lastUsedAt = tonumber(self:UnescapeImportExportField(parts[4] or ""))
            end

            local importedNameExists = false

            for _, existingCommand in ipairs(imported.commands) do
                if self:StringsEqualIgnoreCase(existingCommand.name, name) then
                    importedNameExists = true
                    break
                end
            end

            if id ~= "" and name ~= "" and not commandIds[id] and not importedNameExists and zo_strlen(name) <= 25 then
                commandIds[id] = true
                table.insert(imported.commands, {
                    id = id,
                    name = name,
                    reminderMinutes = reminderMinutes,
                    lastUsedAt = lastUsedAt and math.floor(lastUsedAt) or nil,
                })
            end
        elseif recordType == "MESSAGE" then
            local id = self:UnescapeImportExportField(parts[1] or "")
            local commandId = self:UnescapeImportExportField(parts[2] or "")
            local guildIndex = tonumber(self:UnescapeImportExportField(parts[3] or ""))
            local guildName = self:Trim(self:UnescapeImportExportField(parts[4] or ""))
            local messageText = self:Trim(self:UnescapeImportExportField(parts[5] or ""))
            local lastUsedAt = tonumber(self:UnescapeImportExportField(parts[6] or ""))
            local useCount = tonumber(self:UnescapeImportExportField(parts[7] or ""))
            local commandName = self:SanitizeCommandName(self:UnescapeImportExportField(parts[8] or ""))

            if id ~= "" and not messageIds[id] and commandIds[commandId] and messageText ~= "" then
                messageIds[id] = true
                imported.messages[id] = {
                    id = id,
                    commandId = commandId,
                    commandName = commandName ~= "" and commandName or self:GetCommandNameById(commandId),
                    guildIndex = guildIndex and math.floor(guildIndex) or nil,
                    guildName = guildName,
                    text = messageText,
                    lastUsedAt = lastUsedAt and math.floor(lastUsedAt) or nil,
                    useCount = useCount and math.floor(useCount) or nil,
                }
            end
        elseif recordType == "CHANNEL" then
            local commandId = self:UnescapeImportExportField(parts[1] or "")
            local guildKey = self:NormalizeKey(self:UnescapeImportExportField(parts[2] or ""))
            local channel = self:UnescapeImportExportField(parts[3] or "")

            if commandIds[commandId] and guildKey and (channel == "Zone" or channel == "Guild" or channel == "Officer") then
                imported.chatChannels[commandId] = imported.chatChannels[commandId] or {}
                imported.chatChannels[commandId][guildKey] = channel
            end

elseif recordType == "GUILDSETTING" then
    local commandId = self:UnescapeImportExportField(parts[1] or "")
    local guildKey = self:NormalizeKey(self:UnescapeImportExportField(parts[2] or ""))
    local reminderMinutes = self:NormalizeReminderMinutes(self:UnescapeImportExportField(parts[3] or ""))
    local reminderRetryMinutes = 5
    local autoPopulateOnZone = false
    local autoPopulateCooldownMinutes = 60
    local lastUsedAt = nil
    local lastUsedParamText = nil
    local lastUsedGuildIndex = nil
    local zoneTimestampText = ""
    local populateSound = "DUEL_START"
    local runAt = "ON_DEMAND"
    local openStatusPanelOnRun = false

    if parts[11] ~= nil then
        reminderRetryMinutes = self:NormalizeReminderRetryMinutes(self:UnescapeImportExportField(parts[4] or ""))
        autoPopulateOnZone = self:UnescapeImportExportField(parts[5] or "") == "1"
        autoPopulateCooldownMinutes = self:NormalizeAutoPopulateCooldownMinutes(self:UnescapeImportExportField(parts[6] or ""))

        local part11 = self:UnescapeImportExportField(parts[11] or "")
        local normalizedPart11 = self:NormalizePopulateSound(part11)
        local looksLikeCurrentSoundField = (part11 == "") or part11 == "NONE" or normalizedPart11 ~= "DUEL_START" or part11 == "DUEL_START"

        if looksLikeCurrentSoundField then
            -- Current format:
            -- GUILDSETTING|commandId|guildKey|reminderMinutes|retry|autoPopulate|cooldown|lastUsedAt|lastUsedParamText|lastUsedGuildIndex|zoneTimestamps|populateSound|openStatusPanelOnRun
            lastUsedAt = tonumber(self:UnescapeImportExportField(parts[7] or ""))
            lastUsedParamText = self:Trim(self:UnescapeImportExportField(parts[8] or ""))
            lastUsedGuildIndex = tonumber(self:UnescapeImportExportField(parts[9] or ""))
            zoneTimestampText = self:UnescapeImportExportField(parts[10] or "")
            populateSound = normalizedPart11
            openStatusPanelOnRun = self:UnescapeImportExportField(parts[12] or "") == "1"

            local possibleRunAt = self:UnescapeImportExportField(parts[12] or "")
            if possibleRunAt == "ON_DEMAND" or possibleRunAt == "STARTUP" or possibleRunAt == "SCHEDULED" or parts[13] ~= nil then
                runAt = self:NormalizeRunAt(possibleRunAt)
                openStatusPanelOnRun = self:UnescapeImportExportField(parts[13] or "") == "1"
            end
        else
            -- Legacy format with per-guild revert:
            -- GUILDSETTING|commandId|guildKey|reminderMinutes|retry|autoPopulate|cooldown|revert|lastUsedAt|lastUsedParamText|lastUsedGuildIndex|zoneTimestamps
            lastUsedAt = tonumber(self:UnescapeImportExportField(parts[8] or ""))
            lastUsedParamText = self:Trim(self:UnescapeImportExportField(parts[9] or ""))
            lastUsedGuildIndex = tonumber(self:UnescapeImportExportField(parts[10] or ""))
            zoneTimestampText = self:UnescapeImportExportField(parts[11] or "")
        end
    elseif parts[10] ~= nil then
        -- Legacy format:
        -- GUILDSETTING|commandId|guildKey|reminderMinutes|retry|autoPopulate|cooldown|lastUsedAt|lastUsedParamText|lastUsedGuildIndex|zoneTimestamps
        reminderRetryMinutes = self:NormalizeReminderRetryMinutes(self:UnescapeImportExportField(parts[4] or ""))
        autoPopulateOnZone = self:UnescapeImportExportField(parts[5] or "") == "1"
        autoPopulateCooldownMinutes = self:NormalizeAutoPopulateCooldownMinutes(self:UnescapeImportExportField(parts[6] or ""))
        lastUsedAt = tonumber(self:UnescapeImportExportField(parts[7] or ""))
        lastUsedParamText = self:Trim(self:UnescapeImportExportField(parts[8] or ""))
        lastUsedGuildIndex = tonumber(self:UnescapeImportExportField(parts[9] or ""))
        zoneTimestampText = self:UnescapeImportExportField(parts[10] or "")
    elseif parts[9] ~= nil then
        reminderRetryMinutes = self:NormalizeReminderRetryMinutes(self:UnescapeImportExportField(parts[4] or ""))
        autoPopulateOnZone = self:UnescapeImportExportField(parts[5] or "") == "1"
        autoPopulateCooldownMinutes = self:NormalizeAutoPopulateCooldownMinutes(self:UnescapeImportExportField(parts[6] or ""))
        lastUsedAt = tonumber(self:UnescapeImportExportField(parts[7] or ""))
        lastUsedParamText = self:Trim(self:UnescapeImportExportField(parts[8] or ""))
        lastUsedGuildIndex = tonumber(self:UnescapeImportExportField(parts[9] or ""))
    elseif parts[8] ~= nil then
        autoPopulateOnZone = self:UnescapeImportExportField(parts[4] or "") == "1"
        autoPopulateCooldownMinutes = self:NormalizeAutoPopulateCooldownMinutes(self:UnescapeImportExportField(parts[5] or ""))
        lastUsedAt = tonumber(self:UnescapeImportExportField(parts[6] or ""))
        lastUsedParamText = self:Trim(self:UnescapeImportExportField(parts[7] or ""))
        lastUsedGuildIndex = tonumber(self:UnescapeImportExportField(parts[8] or ""))
    else
        autoPopulateOnZone = self:UnescapeImportExportField(parts[4] or "") == "1"
        lastUsedAt = tonumber(self:UnescapeImportExportField(parts[5] or ""))
        lastUsedParamText = self:Trim(self:UnescapeImportExportField(parts[6] or ""))
        lastUsedGuildIndex = tonumber(self:UnescapeImportExportField(parts[7] or ""))
    end
    local lastAutoPopulateSentAtByZone = {}
            if zoneTimestampText ~= "" then
                for pairText in string.gmatch(zoneTimestampText, "([^,]+)") do
                    local zoneKey, timestampText = pairText:match("^([^=]+)=(%d+)$")
                    local timestamp = tonumber(timestampText)
                    if zoneKey and zoneKey ~= "" and timestamp and timestamp > 0 then
                        lastAutoPopulateSentAtByZone[zoneKey] = math.floor(timestamp)
                    end
                end
            end

            if commandIds[commandId] and guildKey then
                imported.commandGuildSettings[commandId] = imported.commandGuildSettings[commandId] or {}
                imported.commandGuildSettings[commandId][guildKey] = {
                    reminderMinutes = reminderMinutes,
                    reminderRetryMinutes = reminderRetryMinutes,
                    autoPopulateOnZone = autoPopulateOnZone,
                    autoPopulateCooldownMinutes = autoPopulateCooldownMinutes,
                    lastUsedAt = lastUsedAt and math.floor(lastUsedAt) or nil,
                    lastUsedParamText = lastUsedParamText ~= "" and lastUsedParamText or nil,
                    lastUsedGuildIndex = lastUsedGuildIndex and math.floor(lastUsedGuildIndex) or nil,
                    lastAutoPopulateSentAtByZone = lastAutoPopulateSentAtByZone,
                    populateSound = self:NormalizePopulateSound(populateSound),
                    runAt = self:NormalizeRunAt(runAt),
                    openStatusPanelOnRun = self:NormalizeOpenStatusPanelOnRun(openStatusPanelOnRun),
                }
            end
        elseif recordType == "ACTIVE" then
            local commandId = self:UnescapeImportExportField(parts[1] or "")
            local guildName = self:Trim(self:UnescapeImportExportField(parts[2] or ""))
            if commandIds[commandId] and guildName ~= "" then
                imported.activeAutoPopulate = {
                    commandId = commandId,
                    guildName = guildName,
                }
            end
        end
    end

    return self:ApplyImportedSettings(imported)
end

function SmartChatMsg:GetCommands()
    return self.savedVars.commands or {}
end

function SmartChatMsg:HasCommands()
    return #self:GetCommands() > 0
end

function SmartChatMsg:SortCommands()
    table.sort(self.savedVars.commands, function(a, b)
        local aName = type(a) == "table" and a.name or ""
        local bName = type(b) == "table" and b.name or ""
        return zo_strlower(aName) < zo_strlower(bName)
    end)
end

function SmartChatMsg:GetCommandById(commandId)
    if type(commandId) ~= "string" or commandId == "" then
        return nil
    end

    for _, command in ipairs(self:GetCommands()) do
        if type(command) == "table" and command.id == commandId then
            return command
        end
    end

    return nil
end

function SmartChatMsg:GetCommandNameById(commandId)
    local command = self:GetCommandById(commandId)
    if command then
        return command.name
    end

    return nil
end


function SmartChatMsg:GetCommandGuildSettings(commandId, guildName, createIfMissing)
    if type(commandId) ~= "string" or commandId == "" then
        return nil
    end

    local guildKey = self:NormalizeKey(guildName)
    if not guildKey then
        return nil
    end

    if type(self.savedVars.commandGuildSettings[commandId]) ~= "table" then
        if not createIfMissing then
            return nil
        end
        self.savedVars.commandGuildSettings[commandId] = {}
    end

    local byGuild = self.savedVars.commandGuildSettings[commandId]
    if type(byGuild[guildKey]) ~= "table" then
        if not createIfMissing then
            return nil
        end
        byGuild[guildKey] = {}
    end

    return byGuild[guildKey]
end

function SmartChatMsg:GetGuildReminderMinutes(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if settings and settings.reminderMinutes ~= nil then
        return self:NormalizeReminderMinutes(settings.reminderMinutes)
    end

    local command = self:GetCommandById(commandId)
    if not command then
        return nil
    end

    return self:NormalizeReminderMinutes(command.reminderMinutes)
end

function SmartChatMsg:GetGuildAutoPopulateOnZone(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if settings and settings.autoPopulateOnZone ~= nil then
        return self:NormalizeAutoPopulateOnZone(settings.autoPopulateOnZone)
    end

    return false
end

function SmartChatMsg:GetGuildReminderRetryMinutes(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if settings and settings.reminderRetryMinutes ~= nil then
        return self:NormalizeReminderRetryMinutes(settings.reminderRetryMinutes)
    end

    return 0
end

function SmartChatMsg:GetGuildEffectiveReminderRetryMinutes(commandId, guildName)
    local retryMinutes = self:GetGuildReminderRetryMinutes(commandId, guildName)
    if retryMinutes == nil or retryMinutes <= 0 then
        return 0
    end

    local reminderMinutes = self:GetGuildReminderMinutes(commandId, guildName)
    if reminderMinutes == nil or reminderMinutes <= 0 then
        return 0
    end

    if retryMinutes > reminderMinutes then
        return reminderMinutes
    end

    return retryMinutes
end

function SmartChatMsg:GetGuildAutoPopulateCooldownMinutes(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if settings and settings.autoPopulateCooldownMinutes ~= nil then
        return self:NormalizeAutoPopulateCooldownMinutes(settings.autoPopulateCooldownMinutes)
    end

    return 60
end

function SmartChatMsg:GetGuildPopulateSound(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if settings and settings.populateSound ~= nil then
        return self:NormalizePopulateSound(settings.populateSound)
    end

    return self:NormalizePopulateSound(nil)
end

function SmartChatMsg:GetGuildRunAt(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if settings and settings.runAt ~= nil then
        return self:NormalizeRunAt(settings.runAt)
    end

    return "ON_DEMAND"
end

function SmartChatMsg:GetGuildOpenStatusPanelOnRun(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if settings and settings.openStatusPanelOnRun ~= nil then
        return self:NormalizeOpenStatusPanelOnRun(settings.openStatusPanelOnRun)
    end

    return false
end

function SmartChatMsg:GetRevertChatSeconds()
    return self:NormalizeRevertChatSeconds(self.savedVars.revertChatSeconds)
end

function SmartChatMsg:GetGuildLastUsedAt(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if not settings then
        return nil
    end

    return (type(settings.lastUsedAt) == "number" and settings.lastUsedAt > 0) and math.floor(settings.lastUsedAt) or nil
end

function SmartChatMsg:GetGuildLastUsedParamText(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if not settings or type(settings.lastUsedParamText) ~= "string" or settings.lastUsedParamText == "" then
        return nil
    end

    return settings.lastUsedParamText
end

function SmartChatMsg:GetGuildLastUsedGuildIndex(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if not settings then
        return nil
    end

    local value = settings.lastUsedGuildIndex
    if type(value) ~= "number" or value < 1 or value > 5 or value ~= math.floor(value) then
        return nil
    end

    return value
end

function SmartChatMsg:GetGuildAutoPopulateLastSentAt(commandId, guildName, zoneId)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if not settings or type(settings.lastAutoPopulateSentAtByZone) ~= "table" then
        return nil
    end

    local zoneKey = tostring(zoneId or "")
    if zoneKey == "" then
        return nil
    end

    local value = settings.lastAutoPopulateSentAtByZone[zoneKey]
    if type(value) ~= "number" or value <= 0 then
        return nil
    end

    return math.floor(value)
end

function SmartChatMsg:SetGuildAutoPopulateLastSentAt(commandId, guildName, zoneId, timestamp)
    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return
    end

    settings.lastAutoPopulateSentAtByZone = settings.lastAutoPopulateSentAtByZone or {}

    local zoneKey = tostring(zoneId or "")
    if zoneKey == "" then
        return
    end

    if type(timestamp) == "number" and timestamp > 0 then
        settings.lastAutoPopulateSentAtByZone[zoneKey] = math.floor(timestamp)
    else
        settings.lastAutoPopulateSentAtByZone[zoneKey] = nil
    end
end

function SmartChatMsg:SetGuildReminderMinutes(commandId, guildName, reminderMinutes)
    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return false, "Select a Guild first."
    end

    settings.reminderMinutes = self:NormalizeReminderMinutes(reminderMinutes)
    return true
end

function SmartChatMsg:SetGuildReminderRetryMinutes(commandId, guildName, retryMinutes)
    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return false, "Select a Guild first."
    end

    local normalizedRetryMinutes = self:NormalizeReminderRetryMinutes(retryMinutes)
    local reminderMinutes = self:GetGuildReminderMinutes(commandId, guildName)
    if reminderMinutes ~= nil and reminderMinutes > 0 and normalizedRetryMinutes > reminderMinutes then
        normalizedRetryMinutes = reminderMinutes
    end

    settings.reminderRetryMinutes = normalizedRetryMinutes
    return true
end

function SmartChatMsg:SetGuildAutoPopulateOnZone(commandId, guildName, autoPopulateOnZone)
    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return false, "Select a Guild first."
    end

    settings.autoPopulateOnZone = self:NormalizeAutoPopulateOnZone(autoPopulateOnZone)
    return true
end

function SmartChatMsg:SetGuildAutoPopulateCooldownMinutes(commandId, guildName, cooldownMinutes)
    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return false, "Select a Guild first."
    end

    settings.autoPopulateCooldownMinutes = self:NormalizeAutoPopulateCooldownMinutes(cooldownMinutes)
    return true
end

function SmartChatMsg:SetGuildPopulateSound(commandId, guildName, populateSound)
    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return false, "Select a Guild first."
    end

    settings.populateSound = self:NormalizePopulateSound(populateSound)
    return true
end

function SmartChatMsg:SetGuildRunAt(commandId, guildName, runAt)
    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return false, "Select a Guild first."
    end

    settings.runAt = self:NormalizeRunAt(runAt)
    return true
end

function SmartChatMsg:SetGuildOpenStatusPanelOnRun(commandId, guildName, openStatusPanelOnRun)
    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return false, "Select a Guild first."
    end

    settings.openStatusPanelOnRun = self:NormalizeOpenStatusPanelOnRun(openStatusPanelOnRun)
    return true
end

function SmartChatMsg:SetRevertChatSeconds(revertSeconds)
    self.savedVars.revertChatSeconds = self:NormalizeRevertChatSeconds(revertSeconds)
    return true
end

function SmartChatMsg:GetStatusPanelState()
    local state = self.savedVars.statusPanelState
    if type(state) ~= "table" then
        self.savedVars.statusPanelState = {
            visible = false,
            offsetX = -40,
            offsetY = 180,
        }
        state = self.savedVars.statusPanelState
    end

    state.visible = state.visible == true
    state.offsetX = type(state.offsetX) == "number" and math.floor(state.offsetX) or -40
    state.offsetY = type(state.offsetY) == "number" and math.floor(state.offsetY) or 180
    return state
end

function SmartChatMsg:GetStatusPanelVisiblePreference()
    return self:GetStatusPanelState().visible == true
end

function SmartChatMsg:SetStatusPanelVisiblePreference(visible)
    self:GetStatusPanelState().visible = visible == true
end

function SmartChatMsg:GetStatusPanelAnchorOffsets()
    local state = self:GetStatusPanelState()
    return state.offsetX, state.offsetY
end

function SmartChatMsg:SetStatusPanelAnchorOffsets(offsetX, offsetY)
    local state = self:GetStatusPanelState()
    state.offsetX = type(offsetX) == "number" and math.floor(offsetX) or -40
    state.offsetY = type(offsetY) == "number" and math.floor(offsetY) or 180
end

function SmartChatMsg:SetGuildLastUsedState(commandId, guildName, lastUsedAt, paramText, guildIndex)
    local settings = self:GetCommandGuildSettings(commandId, guildName, true)
    if not settings then
        return
    end

    settings.lastUsedAt = (type(lastUsedAt) == "number" and lastUsedAt > 0) and math.floor(lastUsedAt) or nil
    settings.lastUsedParamText = self:Trim(paramText or "")
    if settings.lastUsedParamText == "" then
        settings.lastUsedParamText = nil
    end

    if type(guildIndex) == "number" and guildIndex >= 1 and guildIndex <= 5 and guildIndex == math.floor(guildIndex) then
        settings.lastUsedGuildIndex = guildIndex
    else
        settings.lastUsedGuildIndex = nil
    end
end

function SmartChatMsg:ClearGuildLastUsedState(commandId, guildName)
    local settings = self:GetCommandGuildSettings(commandId, guildName, false)
    if not settings then
        return
    end

    settings.lastUsedAt = nil
    settings.lastUsedParamText = nil
    settings.lastUsedGuildIndex = nil
end

function SmartChatMsg:DeleteCommandGuildSettingsForCommand(commandId)
    if type(commandId) == "string" and commandId ~= "" then
        self.savedVars.commandGuildSettings[commandId] = nil
    end
end

function SmartChatMsg:GetCommandReminderMinutes(commandId)
    return self:GetGuildReminderMinutes(commandId, self:GetSelectedGuildNameForMessages())
end

function SmartChatMsg:GetCommandReminderRetryMinutes(commandId)
    return self:GetGuildReminderRetryMinutes(commandId, self:GetSelectedGuildNameForMessages())
end

function SmartChatMsg:GetCommandAutoPopulateOnZone(commandId)
    return self:GetGuildAutoPopulateOnZone(commandId, self:GetSelectedGuildNameForMessages())
end

function SmartChatMsg:GetCommandAutoPopulateCooldownMinutes(commandId)
    return self:GetGuildAutoPopulateCooldownMinutes(commandId, self:GetSelectedGuildNameForMessages())
end

function SmartChatMsg:GetCommandRevertChatSeconds(commandId)
    return self:GetRevertChatSeconds()
end

function SmartChatMsg:SetCommandReminderMinutes(commandId, reminderMinutes)
    return self:SetGuildReminderMinutes(commandId, self:GetSelectedGuildNameForMessages(), reminderMinutes)
end

function SmartChatMsg:SetCommandReminderRetryMinutes(commandId, retryMinutes)
    return self:SetGuildReminderRetryMinutes(commandId, self:GetSelectedGuildNameForMessages(), retryMinutes)
end

function SmartChatMsg:SetCommandAutoPopulateOnZone(commandId, autoPopulateOnZone)
    return self:SetGuildAutoPopulateOnZone(commandId, self:GetSelectedGuildNameForMessages(), autoPopulateOnZone)
end

function SmartChatMsg:SetCommandAutoPopulateCooldownMinutes(commandId, cooldownMinutes)
    return self:SetGuildAutoPopulateCooldownMinutes(commandId, self:GetSelectedGuildNameForMessages(), cooldownMinutes)
end

function SmartChatMsg:SetCommandRevertChatSeconds(commandId, revertSeconds)
    return self:SetRevertChatSeconds(revertSeconds)
end

function SmartChatMsg:CommandNameExists(name, excludeId)
    local sanitized = self:SanitizeCommandName(name)
    if sanitized == "" then
        return false
    end

    for _, command in ipairs(self:GetCommands()) do
        if type(command) == "table"
            and command.id ~= excludeId
            and self:StringsEqualIgnoreCase(command.name, sanitized) then
            return true
        end
    end

    return false
end

function SmartChatMsg:GetCommandOptions()
    local options = {}

    if not self:HasCommands() then
        table.insert(options, {
            name = "Add A Command",
            value = nil,
            mode = "create",
        })
    else
        table.insert(options, {
            name = "Select a Command",
            value = nil,
            mode = "select",
        })

        for _, command in ipairs(self:GetCommands()) do
            if type(command) == "table" and type(command.id) == "string" and type(command.name) == "string" then
                table.insert(options, {
                    name = command.name,
                    value = command.id,
                    mode = "edit",
                })
            end
        end
    end

    return options
end

function SmartChatMsg:GetSelectedCommand()
    local selectedId = self.savedVars.selectedCommand

    if not self:HasCommands() then
        return {
            name = "Add A Command",
            value = nil,
            mode = "create",
        }
    end

    if not selectedId then
        return {
            name = "Select a Command",
            value = nil,
            mode = "select",
        }
    end

    local command = self:GetCommandById(selectedId)
    if command then
        return {
            name = command.name,
            value = command.id,
            mode = "edit",
        }
    end

    return {
        name = "Select a Command",
        value = nil,
        mode = "select",
    }
end

function SmartChatMsg:SetSelectedCommand(commandId)
    if not commandId or commandId == "" then
        self.savedVars.selectedCommand = nil
        return
    end

    local command = self:GetCommandById(commandId)
    if not command then
        self.savedVars.selectedCommand = nil
        return
    end

    self.savedVars.selectedCommand = command.id
end

function SmartChatMsg:AddCommand(name, reminderMinutes, autoPopulateOnZone)
    local sanitized = self:SanitizeCommandName(name)

    if sanitized == "" then
        return false, "Command must contain at least one alphanumeric character."
    end

    if zo_strlen(sanitized) > 25 then
        return false, "Command must be 25 characters or less."
    end

    if self:CommandNameExists(sanitized) then
        return false, "That Command already exists."
    end

    local command = {
        id = self:GenerateUuid(),
        name = sanitized,
        reminderMinutes = nil,
        lastUsedAt = nil,
    }

    table.insert(self.savedVars.commands, command)
    self:SortCommands()

    self.savedVars.selectedCommand = nil

    if self.RegisterDynamicCommands then
        self:RegisterDynamicCommands()
    end

    return true
end

function SmartChatMsg:GetGuildNameByIndex(guildIndex)
    if not guildIndex then
        return nil
    end

    local guildId = GetGuildId(guildIndex)
    if not guildId or guildId == 0 then
        return nil
    end

    local guildName = GetGuildName(guildId)
    if not guildName or guildName == "" then
        guildName = string.format("Guild %d", guildIndex)
    end

    return guildName
end

function SmartChatMsg:GetGuildIndexByName(guildName)
    if not guildName or guildName == "" then
        return nil
    end

    for guildIndex = 1, 5 do
        local currentGuildName = self:GetGuildNameByIndex(guildIndex)
        if currentGuildName and self:StringsEqualIgnoreCase(currentGuildName, guildName) then
            return guildIndex
        end
    end

    return nil
end

function SmartChatMsg:GetGuildOptions()
    local options = {
        {
            name = "Select a Guild",
            value = nil,
        },
    }

    for guildIndex = 1, 5 do
        local guildId = GetGuildId(guildIndex)
        if guildId and guildId ~= 0 then
            local guildName = GetGuildName(guildId)
            if not guildName or guildName == "" then
                guildName = string.format("Guild %d", guildIndex)
            end

            table.insert(options, {
                name = string.format("%s (/g%d)", guildName, guildIndex),
                value = guildIndex,
            })
        end
    end

    return options
end

function SmartChatMsg:GetSelectedGuildDisplayName()
    local selectedIndex = self.savedVars.selectedMessagesGuildIndex

    if not selectedIndex then
        return "Select a Guild"
    end

    for _, option in ipairs(self:GetGuildOptions()) do
        if option.value == selectedIndex then
            return option.name
        end
    end

    return "Select a Guild"
end

function SmartChatMsg:GetDefaultGuildIndex()
    local guildIndex = self.savedVars.defaultGuildIndex
    if type(guildIndex) ~= "number" then
        return nil
    end

    local guildId = GetGuildId(guildIndex)
    if not guildId or guildId == 0 then
        return nil
    end

    return guildIndex
end

function SmartChatMsg:GetDefaultGuildOptions()
    local options = {
        {
            name = "Select a Default Guild",
            value = nil,
        },
    }

    for guildIndex = 1, 5 do
        local guildId = GetGuildId(guildIndex)
        if guildId and guildId ~= 0 then
            local guildName = GetGuildName(guildId)
            if not guildName or guildName == "" then
                guildName = string.format("Guild %d", guildIndex)
            end

            table.insert(options, {
                name = guildName,
                value = guildIndex,
            })
        end
    end

    return options
end

function SmartChatMsg:GetDefaultGuildDisplayName()
    local guildIndex = self:GetDefaultGuildIndex()
    if not guildIndex then
        return "Select a Default Guild"
    end

    for _, option in ipairs(self:GetDefaultGuildOptions()) do
        if option.value == guildIndex then
            return option.name
        end
    end

    return "Select a Default Guild"
end

function SmartChatMsg:SetDefaultGuildIndex(guildIndex)
    if guildIndex == nil then
        self.savedVars.defaultGuildIndex = nil
        return
    end

    if type(guildIndex) ~= "number"
        or guildIndex < 1
        or guildIndex > 5
        or guildIndex ~= math.floor(guildIndex) then
        return
    end

    local guildId = GetGuildId(guildIndex)
    if not guildId or guildId == 0 then
        return
    end

    self.savedVars.defaultGuildIndex = guildIndex
end

function SmartChatMsg:GetMessagesCommandOptions()
    local options = {
        {
            name = "Select a Command",
            value = nil,
        },
    }

    for _, command in ipairs(self:GetCommands()) do
        if type(command) == "table" and type(command.id) == "string" and type(command.name) == "string" then
            table.insert(options, {
                name = command.name,
                value = command.id,
            })
        end
    end

    return options
end

function SmartChatMsg:GetMessagesSelectedCommand()
    local selectedId = self.savedVars.selectedMessagesCommand

    if not selectedId then
        return {
            name = "Select a Command",
            value = nil,
        }
    end

    local command = self:GetCommandById(selectedId)
    if command then
        return {
            name = command.name,
            value = command.id,
        }
    end

    return {
        name = "Select a Command",
        value = nil,
    }
end

function SmartChatMsg:GetSelectedGuildNameForMessages()
    return self:GetGuildNameByIndex(self.savedVars.selectedMessagesGuildIndex)
end

function SmartChatMsg:GetSelectedGuildIndexForMessages()
    local guildName = self:GetSelectedGuildNameForMessages()
    return self:GetGuildIndexByName(guildName)
end

function SmartChatMsg:GetChatChannelOptions()
    local guildIndex = self:GetSelectedGuildIndexForMessages()
    local options = {}

    local selectedChannel = self:GetSelectedMessagesChannel()

    if selectedChannel == "Select a Chat Channel" then
        table.insert(options, "Select a Chat Channel")
    end

    if guildIndex then
        table.insert(options, string.format("Guild (/g%d)", guildIndex))
        table.insert(options, string.format("Officer (/o%d)", guildIndex))
    else
        table.insert(options, "Guild")
        table.insert(options, "Officer")
    end

    table.insert(options, "Zone")

    return options
end

function SmartChatMsg:GetSavedChatChannel(commandId, guildName)
    if type(commandId) ~= "string" or commandId == "" then
        return nil
    end

    local guildKey = self:NormalizeKey(guildName)
    if not guildKey then
        return nil
    end

    local byCommand = self.savedVars.chatChannels[commandId]
    if type(byCommand) ~= "table" then
        return nil
    end

    local channel = byCommand[guildKey]
    if channel ~= "Zone" and channel ~= "Guild" and channel ~= "Officer" then
        return nil
    end

    return channel
end

function SmartChatMsg:SetSavedChatChannel(commandId, guildName, channel)
    if type(commandId) ~= "string" or commandId == "" then
        return
    end

    local guildKey = self:NormalizeKey(guildName)
    if not guildKey then
        return
    end

    if type(self.savedVars.chatChannels[commandId]) ~= "table" then
        self.savedVars.chatChannels[commandId] = {}
    end

    if channel ~= "Zone" and channel ~= "Guild" and channel ~= "Officer" then
        self.savedVars.chatChannels[commandId][guildKey] = nil

        if next(self.savedVars.chatChannels[commandId]) == nil then
            self.savedVars.chatChannels[commandId] = nil
        end
        return
    end

    self.savedVars.chatChannels[commandId][guildKey] = channel
end

function SmartChatMsg:DeleteSavedChatChannelsForCommand(commandId)
    if type(commandId) == "string" and commandId ~= "" then
        self.savedVars.chatChannels[commandId] = nil
    end
end

function SmartChatMsg:GetSelectedMessagesChannel()
    local commandId = self.savedVars.selectedMessagesCommand
    local guildName = self:GetSelectedGuildNameForMessages()
    local savedChannel = self:GetSavedChatChannel(commandId, guildName)

    if savedChannel == "Guild" or savedChannel == "Officer" or savedChannel == "Zone" then
        local guildIndex = self:GetSelectedGuildIndexForMessages()

        if savedChannel == "Guild" and guildIndex then
            return string.format("Guild (/g%d)", guildIndex)
        end

        if savedChannel == "Officer" and guildIndex then
            return string.format("Officer (/o%d)", guildIndex)
        end

        return savedChannel
    end

    return "Select a Chat Channel"
end

function SmartChatMsg:SetSelectedMessagesChannel(channel)
    local normalizedChannel = nil

    if type(channel) == "string" then
        if channel == "Zone" then
            normalizedChannel = "Zone"
        elseif channel:find("^Guild %(/g%d%)$") or channel == "Guild" then
            normalizedChannel = "Guild"
        elseif channel:find("^Officer %(/o%d%)$") or channel == "Officer" then
            normalizedChannel = "Officer"
        end
    end

    local commandId = self.savedVars.selectedMessagesCommand
    local guildName = self:GetSelectedGuildNameForMessages()

    if normalizedChannel ~= "Guild" and normalizedChannel ~= "Officer" and normalizedChannel ~= "Zone" then
        self.savedVars.selectedMessagesChannel = nil
        self:SetSavedChatChannel(commandId, guildName, nil)
        return
    end

    self.savedVars.selectedMessagesChannel = normalizedChannel
    self:SetSavedChatChannel(commandId, guildName, normalizedChannel)
end

function SmartChatMsg:SetMessagesSelectedCommand(commandId)
    if not commandId or commandId == "" then
        self.savedVars.selectedMessagesCommand = nil
        self.savedVars.selectedMessagesChannel = nil
        return
    end

    local command = self:GetCommandById(commandId)
    if not command then
        self.savedVars.selectedMessagesCommand = nil
        self.savedVars.selectedMessagesChannel = nil
        return
    end

    self.savedVars.selectedMessagesCommand = command.id

    local guildName = self:GetSelectedGuildNameForMessages()
    self.savedVars.selectedMessagesChannel = self:GetSavedChatChannel(command.id, guildName)
end

function SmartChatMsg:SetSelectedGuildIndex(guildIndex)
    self.savedVars.selectedMessagesGuildIndex = guildIndex

    if not guildIndex then
        self.savedVars.selectedMessagesChannel = nil
        return
    end

    local commandId = self.savedVars.selectedMessagesCommand
    local guildName = self:GetSelectedGuildNameForMessages()
    self.savedVars.selectedMessagesChannel = self:GetSavedChatChannel(commandId, guildName)
end

function SmartChatMsg:IsMessagesSelectionComplete()
    return self.savedVars.selectedMessagesCommand ~= nil and self.savedVars.selectedMessagesGuildIndex ~= nil
end

function SmartChatMsg:GetMessageEntriesForSelection()
    local results = {}

    if not self:IsMessagesSelectionComplete() then
        return results
    end

    local selectedCommandId = self.savedVars.selectedMessagesCommand
    local selectedGuildName = self:GetSelectedGuildNameForMessages()

    if not selectedCommandId or not selectedGuildName or selectedGuildName == "" then
        return results
    end

    for _, entry in ipairs(self:GetSavedMessageEntriesArray()) do
        if type(entry) == "table" and entry.commandId == selectedCommandId then
            local entryGuildName = entry.guildName

            if (not entryGuildName or entryGuildName == "") and entry.guildIndex then
                entryGuildName = self:GetGuildNameByIndex(entry.guildIndex)
            end

            if entryGuildName and self:StringsEqualIgnoreCase(entryGuildName, selectedGuildName) then
                if not entry.guildName or entry.guildName == "" then
                    entry.guildName = entryGuildName
                end

                table.insert(results, entry)
            end
        end
    end

    table.sort(results, function(a, b)
        local aId = type(a) == "table" and a.id or ""
        local bId = type(b) == "table" and b.id or ""
        return tostring(aId) < tostring(bId)
    end)

    return results
end

function SmartChatMsg:AddMessageEntryForSelection(text)
    if not self:IsMessagesSelectionComplete() then
        return false, "Select a Command and Guild first."
    end

    local trimmed = self:Trim(text)
    if trimmed == "" then
        return false, "Message must contain at least one non-space character."
    end

    local channel = self:GetSelectedMessagesChannel()
    if channel == "Select a Chat Channel" then
        return false, "Select a Chat Channel first."
    end

    local guildIndex = self.savedVars.selectedMessagesGuildIndex
    local guildName = self:GetSelectedGuildNameForMessages()
    local commandId = self.savedVars.selectedMessagesCommand

    local entryId = self:GenerateMessageEntryIdForChannel(channel, guildName, trimmed)
    local entry = {
        id = entryId,
        commandId = commandId,
        commandName = self:GetMessageCommandName(commandId),
        guildIndex = guildIndex,
        guildName = guildName,
        text = trimmed,
    }

    self:SetSavedMessageEntry(entryId, entry)

    return true
end

function SmartChatMsg:UpdateMessageEntry(entryId, text)
    local trimmed = self:Trim(text)
    if trimmed == "" then
        return false, "Message must contain at least one non-space character."
    end

    local channel = self:GetSelectedMessagesChannel()
    if channel == "Select a Chat Channel" then
        return false, "Select a Chat Channel first."
    end

    local guildIndex = self.savedVars.selectedMessagesGuildIndex
    local guildName = self:GetSelectedGuildNameForMessages()
    local commandId = self.savedVars.selectedMessagesCommand

    local entry = self:GetSavedMessageEntryById(entryId)
    if not entry then
        return false, "That message entry no longer exists."
    end

    self:RemoveSavedMessageEntry(entryId)

    local newEntryId = self:GenerateMessageEntryIdForChannel(channel, guildName, trimmed)
    entry.text = trimmed
    entry.commandId = commandId
    entry.commandName = self:GetMessageCommandName(commandId, entry)
    entry.guildIndex = guildIndex
    entry.guildName = guildName
    entry.id = newEntryId

    self:SetSavedMessageEntry(newEntryId, entry)
    return true
end

function SmartChatMsg:DeleteMessageEntry(entryId)
    if self:GetSavedMessageEntryById(entryId) then
        self:RemoveSavedMessageEntry(entryId)
        return true
    end

    return false, "That message entry no longer exists."
end

function SmartChatMsg:DeleteMessageEntries(entryIds)
    if type(entryIds) ~= "table" then
        return false, "No message entries were selected."
    end

    local toDelete = {}
    for _, entryId in ipairs(entryIds) do
        toDelete[entryId] = true
    end

    local removedCount = 0

    for entryId, _ in pairs(toDelete) do
        if self:GetSavedMessageEntryById(entryId) then
            self:RemoveSavedMessageEntry(entryId)
            removedCount = removedCount + 1
        end
    end

    if removedCount == 0 then
        return false, "No matching message entries were selected."
    end

    return true
end

function SmartChatMsg:RenameCommand(commandId, newName, reminderMinutes, autoPopulateOnZone)
    local sanitizedNew = self:SanitizeCommandName(newName)

    if sanitizedNew == "" then
        return false, "Command must contain at least one alphanumeric character."
    end

    if zo_strlen(sanitizedNew) > 25 then
        return false, "Command must be 25 characters or less."
    end

    local command = self:GetCommandById(commandId)
    if not command then
        return false, "The selected Command no longer exists."
    end

    if self:CommandNameExists(sanitizedNew, commandId) then
        return false, "That Command already exists."
    end

    command.name = sanitizedNew

    for _, entry in ipairs(self:GetSavedMessageEntriesArray()) do
        if type(entry) == "table" and entry.commandId == commandId then
            entry.commandName = sanitizedNew
        end
    end

    self:SortCommands()

    if self.RegisterDynamicCommands then
        self:RegisterDynamicCommands()
    end

    return true
end

function SmartChatMsg:DeleteCommand(commandId)
    if type(commandId) ~= "string" or commandId == "" then
        return false, "No Command was selected."
    end

    local foundIndex = nil

    for i, command in ipairs(self:GetCommands()) do
        if type(command) == "table" and command.id == commandId then
            foundIndex = i
            break
        end
    end

    if not foundIndex then
        return false, "The selected Command no longer exists."
    end

    table.remove(self.savedVars.commands, foundIndex)

    if type(self.savedVars.messages) == "table" then
        for entryKey, entry in pairs(self:GetSavedMessageEntriesTable()) do
            if type(entry) == "table" and entry.commandId == commandId then
                self.savedVars.messages[entryKey] = nil
            end
        end
    end

    self:DeleteSavedChatChannelsForCommand(commandId)
    self:DeleteCommandGuildSettingsForCommand(commandId)

    if self.savedVars.selectedMessagesCommand == commandId then
        self.savedVars.selectedMessagesCommand = nil
    end

    if self.savedVars.selectedCommand == commandId then
        self.savedVars.selectedCommand = nil
    end

    if self.RegisterDynamicCommands then
        self:RegisterDynamicCommands()
    end

    return true
end
