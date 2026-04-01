SmartChatMsg = SmartChatMsg or {}

SmartChatMsg.settings = SmartChatMsg.settings or {
    createMode = false,
    editMode = false,
    pendingCommand = "",
    pendingReminderMinutes = "",
    pendingAutoPopulateOnZone = false,
    pendingGuildReminderMinutes = "",
    pendingGuildAutoPopulateOnZone = false,
    pendingImportExportText = "",
    editingOriginalCommandId = nil,

    pendingNewMessageText = "",
    pendingMessageEdits = {},
    selectedMessageEntryIds = {},

    panel = nil,
    controls = {},
    deleteDialogRegistered = false,
    deleteMessageDialogRegistered = false,
    deleteSelectedMessagesDialogRegistered = false,
    importDialogRegistered = false,
}

local LAM2 = LibAddonMenu2

local DROPDOWN_WIDTH = 280
local LABEL_WIDTH = 180
local ROW_WIDTH = 700
local MESSAGE_BOX_WIDTH = 360
local MESSAGE_BOX_HEIGHT = 90
local CHECKBOX_WIDTH = 28

local DELETE_DIALOG_NAME = "SCM_CONFIRM_DELETE_MESSAGE_TYPE"
local DELETE_MESSAGE_DIALOG_NAME = "SCM_CONFIRM_DELETE_MESSAGE_ENTRY"
local DELETE_SELECTED_MESSAGES_DIALOG_NAME = "SCM_CONFIRM_DELETE_SELECTED_MESSAGE_ENTRIES"
local IMPORT_SETTINGS_DIALOG_NAME = "SCM_CONFIRM_IMPORT_SETTINGS"

local function RegisterDeleteDialogs()
    if not SmartChatMsg.settings.deleteDialogRegistered then
        ZO_Dialogs_RegisterCustomDialog(DELETE_DIALOG_NAME, {
            title = { text = "Delete Command" },
            mainText = { text = "Are you sure you want to delete this Command? Any messages associated to this Command will also be deleted." },
            buttons = {
                {
                    text = SI_DIALOG_CONFIRM,
                    callback = function(dialog)
                        local data = dialog.data
                        if data and data.callback then
                            data.callback()
                        end
                    end,
                },
                { text = SI_DIALOG_CANCEL },
            },
        })

        SmartChatMsg.settings.deleteDialogRegistered = true
    end

    if not SmartChatMsg.settings.deleteMessageDialogRegistered then
        ZO_Dialogs_RegisterCustomDialog(DELETE_MESSAGE_DIALOG_NAME, {
            title = { text = "Delete Message" },
            mainText = { text = "Are you sure you want to delete this message?" },
            buttons = {
                {
                    text = SI_DIALOG_CONFIRM,
                    callback = function(dialog)
                        local data = dialog.data
                        if data and data.callback then
                            data.callback()
                        end
                    end,
                },
                { text = SI_DIALOG_CANCEL },
            },
        })

        SmartChatMsg.settings.deleteMessageDialogRegistered = true
    end

    if not SmartChatMsg.settings.deleteSelectedMessagesDialogRegistered then
        ZO_Dialogs_RegisterCustomDialog(DELETE_SELECTED_MESSAGES_DIALOG_NAME, {
            title = { text = "Delete Selected Messages" },
            mainText = { text = "Are you sure you want to delete the selected messages?" },
            buttons = {
                {
                    text = SI_DIALOG_CONFIRM,
                    callback = function(dialog)
                        local data = dialog.data
                        if data and data.callback then
                            data.callback()
                        end
                    end,
                },
                { text = SI_DIALOG_CANCEL },
            },
        })

        SmartChatMsg.settings.deleteSelectedMessagesDialogRegistered = true
    end

    if not SmartChatMsg.settings.importDialogRegistered then
        ZO_Dialogs_RegisterCustomDialog(IMPORT_SETTINGS_DIALOG_NAME, {
            title = { text = "Import Settings" },
            mainText = { text = "Importing will replace all existing SmartChatMsg settings. Are you sure?" },
            buttons = {
                {
                    text = SI_DIALOG_CONFIRM,
                    callback = function(dialog)
                        local data = dialog.data
                        if data and data.callback then
                            data.callback()
                        end
                    end,
                },
                { text = SI_DIALOG_CANCEL },
            },
        })

        SmartChatMsg.settings.importDialogRegistered = true
    end
end

function SmartChatMsg:HasAnyGuilds()
    for guildIndex = 1, 5 do
        local guildId = GetGuildId(guildIndex)
        if guildId and guildId ~= 0 then
            return true
        end
    end

    return false
end

function SmartChatMsg:CanUseMessagesSection()
    return self:HasCommands() and self:HasAnyGuilds()
end

function SmartChatMsg.settings:GetSelectedMessageEntryCount()
    local count = 0

    for _, isSelected in pairs(self.selectedMessageEntryIds or {}) do
        if isSelected then
            count = count + 1
        end
    end

    return count
end

function SmartChatMsg.settings:ClearSelectedMessageEntries()
    self.selectedMessageEntryIds = {}
end

function SmartChatMsg.settings:ClearPendingMessageEdits()
    self.pendingMessageEdits = {}
end

function SmartChatMsg.settings:GetPendingMessageEdit(entryId)
    if type(entryId) ~= "string" or entryId == "" then
        return nil
    end

    return self.pendingMessageEdits[entryId]
end

function SmartChatMsg.settings:GetEffectiveMessageText(entry)
    if type(entry) ~= "table" or type(entry.id) ~= "string" then
        return ""
    end

    local pendingText = self:GetPendingMessageEdit(entry.id)
    if pendingText ~= nil then
        return pendingText
    end

    return entry.text or ""
end

function SmartChatMsg.settings:IsMessageEntryDirty(entry)
    if type(entry) ~= "table" or type(entry.id) ~= "string" then
        return false
    end

    local pendingText = self:GetPendingMessageEdit(entry.id)
    if pendingText == nil then
        return false
    end

    return pendingText ~= (entry.text or "")
end

function SmartChatMsg.settings:SetPendingMessageEdit(entryId, text, originalText)
    if type(entryId) ~= "string" or entryId == "" then
        return
    end

    local value = text or ""
    local baseline = originalText or ""

    if value == baseline then
        self.pendingMessageEdits[entryId] = nil
    else
        self.pendingMessageEdits[entryId] = value
    end
end

function SmartChatMsg.settings:InitializeState()
    self.pendingCommand = ""
    self.pendingReminderMinutes = ""
    self.pendingAutoPopulateOnZone = false
    self.pendingGuildReminderMinutes = ""
    self.pendingGuildAutoPopulateOnZone = false
    self.editingOriginalCommandId = nil
    self.editMode = false
    self.pendingNewMessageText = ""
    self:ClearPendingMessageEdits()
    self:ClearSelectedMessageEntries()

    if SmartChatMsg:HasCommands() then
        self.createMode = false
    else
        self.createMode = true
    end

    SmartChatMsg:SetSelectedCommand(nil)

    if not SmartChatMsg:CanUseMessagesSection() then
        SmartChatMsg:SetMessagesSelectedCommand(nil)
        SmartChatMsg:SetSelectedGuildIndex(nil)
    end
end

function SmartChatMsg.settings:IsEditorVisible()
    return self.createMode or self.editMode
end

function SmartChatMsg.settings:ResetNewMessageSection()
    self.pendingNewMessageText = ""
    self:ClearPendingMessageEdits()
    self:ClearSelectedMessageEntries()

    if self.controls.newMessageEditBox then
        self.controls.newMessageEditBox:SetText("")
    end

    if SmartChatMsg:IsMessagesSelectionComplete() then
        local commandId = SmartChatMsg.savedVars.selectedMessagesCommand
        local guildName = SmartChatMsg:GetSelectedGuildNameForMessages()
        local savedChannel = SmartChatMsg:GetSavedChatChannel(commandId, guildName)

        if savedChannel then
            SmartChatMsg:SetSelectedMessagesChannel(savedChannel)
        else
            SmartChatMsg:SetSelectedMessagesChannel(nil)
        end

        local reminderMinutes = SmartChatMsg:GetGuildReminderMinutes(commandId, guildName)
        self.pendingGuildReminderMinutes = reminderMinutes and tostring(reminderMinutes) or ""
        self.pendingGuildAutoPopulateOnZone = SmartChatMsg:GetGuildAutoPopulateOnZone(commandId, guildName) == true
    else
        SmartChatMsg:SetSelectedMessagesChannel(nil)
        self.pendingGuildReminderMinutes = ""
        self.pendingGuildAutoPopulateOnZone = false
    end

    SmartChatMsg:RefreshSettingsUI()
end

function SmartChatMsg.settings:EnableCreateState()
    self.createMode = true
    self.editMode = false
    self.editingOriginalCommandId = nil
    self.pendingCommand = ""
    self.pendingReminderMinutes = ""

    SmartChatMsg:SetSelectedCommand(nil)

    if self.controls.commandEditBox then
        self.controls.commandEditBox:SetText("")
    end

    if self.controls.commandReminderEditBox then
        self.controls.commandReminderEditBox:SetText("")
    end

    SmartChatMsg:RefreshSettingsUI()
end

function SmartChatMsg.settings:EnableEditState(commandId)
    local command = SmartChatMsg:GetCommandById(commandId)
    if not command then
        self:ResetEditorState()
        return
    end

    self.createMode = false
    self.editMode = true
    self.editingOriginalCommandId = command.id
    self.pendingCommand = command.name or ""
    self.pendingReminderMinutes = ""
    self.pendingAutoPopulateOnZone = false

    SmartChatMsg:SetSelectedCommand(command.id)

    if self.controls.commandEditBox then
        self.controls.commandEditBox:SetText(self.pendingCommand)
    end

    if self.controls.commandReminderEditBox then
        self.controls.commandReminderEditBox:SetText(self.pendingReminderMinutes)
    end

    if self.controls.commandAutoPopulateCheckbox then
        ZO_CheckButton_SetCheckState(self.controls.commandAutoPopulateCheckbox, self.pendingAutoPopulateOnZone)
    end

    SmartChatMsg:RefreshSettingsUI()
end

function SmartChatMsg.settings:ResetEditorState()
    self.pendingCommand = ""
    self.pendingReminderMinutes = ""
    self.pendingAutoPopulateOnZone = false
    self.editingOriginalCommandId = nil
    self.editMode = false

    if SmartChatMsg:HasCommands() then
        self.createMode = false
    else
        self.createMode = true
    end

    SmartChatMsg:SetSelectedCommand(nil)

    if self.controls.commandEditBox then
        self.controls.commandEditBox:SetText("")
    end

    if self.controls.commandAutoPopulateCheckbox then
        ZO_CheckButton_SetCheckState(self.controls.commandAutoPopulateCheckbox, false)
    end

    SmartChatMsg:RefreshSettingsUI()
end

function SmartChatMsg.settings:SaveCommand()
    local text = self.pendingCommand or ""

    if self.createMode then
        local ok, err = SmartChatMsg:AddCommand(text)

        if not ok then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
            return
        end

        PlaySound(SOUNDS.DEFAULT_CLICK)
        self:ResetEditorState()
        return
    end

    if self.editMode then
        local commandId = self.editingOriginalCommandId
        local ok, err = SmartChatMsg:RenameCommand(commandId, text)

        if not ok then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
            return
        end

        PlaySound(SOUNDS.DEFAULT_CLICK)
        self:ResetEditorState()
    end
end

function SmartChatMsg.settings:ExportSettings()
    self.pendingImportExportText = SmartChatMsg:BuildExportString()

    if self.controls.importExportEditBox then
        self.controls.importExportEditBox:SetText(self.pendingImportExportText)
        self.controls.importExportEditBox:TakeFocus()
    end

    local message = "Export completed successfully."
    d(message)

    if CENTER_SCREEN_ANNOUNCE then
        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, message)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.DEFAULT_CLICK, message)
    end

    PlaySound(SOUNDS.DEFAULT_CLICK)
end

function SmartChatMsg.settings:ImportSettings()
    local rawText = self.pendingImportExportText or ""
    if SmartChatMsg:Trim(rawText) == "" then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Paste exported settings first.")
        return
    end

    ZO_Dialogs_ShowDialog(IMPORT_SETTINGS_DIALOG_NAME, {
        callback = function()
            local ok, err = SmartChatMsg:ImportSettingsFromString(rawText)
            if not ok then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
                return
            end

            self:InitializeState()
            self.pendingImportExportText = ""
            if self.controls.importExportEditBox then
                self.controls.importExportEditBox:SetText("")
            end
            SmartChatMsg:RefreshSettingsUI()

            local message = "Import completed successfully."
            d(message)

            if CENTER_SCREEN_ANNOUNCE then
                CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, message)
            else
                ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.DEFAULT_CLICK, message)
            end

            PlaySound(SOUNDS.MESSAGE_BROADCAST)
        end,
    })
end

function SmartChatMsg.settings:CopyExportText()
    local text = self.pendingImportExportText or ""
    if SmartChatMsg:Trim(text) == "" then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Nothing to copy. Export settings first.")
        return
    end

    if self.controls.importExportEditBox then
        self.controls.importExportEditBox:SetText(text)
        self.controls.importExportEditBox:TakeFocus()
    end

    local message = "Export text selected. Press Ctrl+C to copy."
    d(message)

    if CENTER_SCREEN_ANNOUNCE then
        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_SMALL_TEXT, SOUNDS.DEFAULT_CLICK, message)
    else
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.DEFAULT_CLICK, message)
    end

    PlaySound(SOUNDS.DEFAULT_CLICK)
end

function SmartChatMsg.settings:ClearImportExportText()
    self.pendingImportExportText = ""
    if self.controls.importExportEditBox then
        self.controls.importExportEditBox:SetText("")
    end
    PlaySound(SOUNDS.DEFAULT_CLICK)
end

function SmartChatMsg.settings:DeleteCurrentCommand()
    if not self.editMode or not self.editingOriginalCommandId or self.editingOriginalCommandId == "" then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No Command is selected to delete.")
        return
    end

    ZO_Dialogs_ShowDialog(DELETE_DIALOG_NAME, {
        callback = function()
            local ok, err = SmartChatMsg:DeleteCommand(self.editingOriginalCommandId)

            if not ok then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
                return
            end

            PlaySound(SOUNDS.DEFAULT_CLICK)
            self:ResetEditorState()

            if not SmartChatMsg:CanUseMessagesSection() then
                SmartChatMsg:SetMessagesSelectedCommand(nil)
                SmartChatMsg:SetSelectedGuildIndex(nil)
            end
        end,
    })
end

function SmartChatMsg.settings:SaveMessagesSection()
    local selectedChannel = SmartChatMsg:GetSelectedMessagesChannel()
    if selectedChannel == "Select a Chat Channel" then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Select a Chat Channel first.")
        return
    end

    local rows = self.controls.savedMessageRows or {}
    for _, row in ipairs(rows) do
        if row and row.entryId and row.editBox then
            local trimmed = SmartChatMsg:Trim(row.editBox:GetText() or "")
            if trimmed == "" then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Existing messages must contain at least one non-space character.")
                return
            end
        end
    end

    for _, row in ipairs(rows) do
        if row and row.entryId and row.editBox then
            local trimmed = SmartChatMsg:Trim(row.editBox:GetText() or "")
            local ok, err = SmartChatMsg:UpdateMessageEntry(row.entryId, trimmed)
            if not ok then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
                return
            end
        end
    end

    local newText = SmartChatMsg:Trim(self.pendingNewMessageText or "")
    if newText ~= "" then
        local ok, err = SmartChatMsg:AddMessageEntryForSelection(newText)
        if not ok then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
            return
        end
    end

    PlaySound(SOUNDS.DEFAULT_CLICK)
    self.pendingNewMessageText = ""
    self:ClearSelectedMessageEntries()

    if self.controls.newMessageEditBox then
        self.controls.newMessageEditBox:SetText("")
    end

    SmartChatMsg:RefreshSettingsUI()
end

function SmartChatMsg.settings:DeleteSelectedMessages()
    local selectedIds = {}

    for entryId, isSelected in pairs(self.selectedMessageEntryIds or {}) do
        if isSelected then
            table.insert(selectedIds, entryId)
        end
    end

    if #selectedIds == 0 then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "No messages are selected.")
        return
    end

    ZO_Dialogs_ShowDialog(DELETE_SELECTED_MESSAGES_DIALOG_NAME, {
        callback = function()
            local ok, err = SmartChatMsg:DeleteMessageEntries(selectedIds)

            if not ok then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
                return
            end

            self:ClearSelectedMessageEntries()
            PlaySound(SOUNDS.DEFAULT_CLICK)
            SmartChatMsg:RefreshSettingsUI()
        end,
    })
end

local function BuildCommandDropdown(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_CommandDropdownContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 40)

    local label = WINDOW_MANAGER:CreateControl("SCM_CommandDropdownLabel", container, CT_LABEL)
    label:SetFont("ZoFontWinH4")
    label:SetText("Command")
    label:SetDimensions(LABEL_WIDTH, 30)
    label:SetAnchor(LEFT, container, LEFT, 0, 0)

    local comboBoxControl = WINDOW_MANAGER:CreateControlFromVirtual("SCM_CommandDropdownCombo", container, "ZO_ComboBox")
    comboBoxControl:SetDimensions(DROPDOWN_WIDTH, 28)
    comboBoxControl:SetAnchor(LEFT, label, RIGHT, 10, 0)

    local comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    comboBox:SetSortsItems(false)

    local addButton = WINDOW_MANAGER:CreateControl("SCM_CommandDropdownAddButton", container, CT_BUTTON)
    addButton:SetDimensions(28, 28)
    addButton:SetAnchor(LEFT, comboBoxControl, RIGHT, 8, 0)
    addButton:SetFont("ZoFontGameLargeBold")
    addButton:SetText("+")
    addButton:SetNormalFontColor(1, 1, 1, 1)
    addButton:SetMouseOverFontColor(1, 0.9, 0.4, 1)
    addButton:SetPressedFontColor(0.7, 0.7, 0.7, 1)

    addButton:SetHandler("OnMouseEnter", function(self)
        InitializeTooltip(InformationTooltip, self, TOP, 0, 8)
        SetTooltipText(InformationTooltip, "Add Command")
    end)

    addButton:SetHandler("OnMouseExit", function()
        ClearTooltip(InformationTooltip)
    end)

    addButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:EnableCreateState()
    end)

    local function RefreshDropdown()
        comboBox:ClearItems()

        local options = SmartChatMsg:GetCommandOptions()
        local currentSelection = SmartChatMsg:GetSelectedCommand()

        for _, option in ipairs(options) do
            local entry = comboBox:CreateItemEntry(option.name, function()
                if option.mode == "create" then
                    SmartChatMsg.settings:EnableCreateState()
                elseif option.mode == "select" then
                    SmartChatMsg.settings:ResetEditorState()
                else
                    SmartChatMsg.settings:EnableEditState(option.value)
                end
            end)
            comboBox:AddItem(entry)
        end

        comboBox:SetSelectedItem(currentSelection.name)
    end

    container.RefreshDropdown = RefreshDropdown
    RefreshDropdown()

    SmartChatMsg.settings.controls.commandDropdown = container
    return container
end


local function BuildCommandEditor(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_CommandEditorContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 96)

    local label = WINDOW_MANAGER:CreateControl("SCM_CommandEditorLabel", container, CT_LABEL)
    label:SetFont("ZoFontWinH4")
    label:SetText("Enter Command Name")
    label:SetDimensions(LABEL_WIDTH, 30)
    label:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)

    local backdrop = WINDOW_MANAGER:CreateControlFromVirtual("SCM_CommandEditorBackdrop", container, "ZO_EditBackdrop")
    backdrop:SetDimensions(DROPDOWN_WIDTH, 30)
    backdrop:SetAnchor(TOPLEFT, label, BOTTOMLEFT, 0, 4)

    local editBox = WINDOW_MANAGER:CreateControlFromVirtual("SCM_CommandEditorEditBox", backdrop, "ZO_DefaultEditForBackdrop")
    editBox:SetAnchorFill(backdrop)
    editBox:SetMaxInputChars(25)
    editBox:SetText("")

    editBox:SetHandler("OnTextChanged", function(self)
        local text = self:GetText() or ""

        if zo_strlen(text) > 25 then
            text = zo_strsub(text, 1, 25)
            self:SetText(text)
        end

        SmartChatMsg.settings.pendingCommand = text
    end)

    local saveButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_CommandEditorSaveButton", container, "ZO_DefaultButton")
    saveButton:SetDimensions(90, 28)
    saveButton:SetAnchor(TOPLEFT, editBox, BOTTOMLEFT, 0, 8)
    saveButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:SaveCommand()
    end)

    local resetButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_CommandEditorResetButton", container, "ZO_DefaultButton")
    resetButton:SetDimensions(90, 28)
    resetButton:SetAnchor(LEFT, saveButton, RIGHT, 8, 0)
    resetButton:SetText("Reset")
    resetButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:ResetEditorState()
    end)

    local deleteButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_CommandEditorDeleteButton", container, "ZO_DefaultButton")
    deleteButton:SetDimensions(90, 28)
    deleteButton:SetAnchor(LEFT, resetButton, RIGHT, 8, 0)
    deleteButton:SetText("Delete")
    deleteButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:DeleteCurrentCommand()
    end)

    container.RefreshEditor = function()
        if SmartChatMsg.settings.controls.commandEditBox then
            SmartChatMsg.settings.controls.commandEditBox:SetText(SmartChatMsg.settings.pendingCommand or "")
        end

        if SmartChatMsg.settings.createMode then
            saveButton:SetText("Add")
        elseif SmartChatMsg.settings.editMode then
            saveButton:SetText("Update")
        else
            saveButton:SetText("Add")
        end

        deleteButton:SetHidden(not SmartChatMsg.settings.editMode)
        container:SetHidden(not SmartChatMsg.settings:IsEditorVisible())
    end

    SmartChatMsg.settings.controls.commandEditBox = editBox
    SmartChatMsg.settings.controls.commandEditor = container

    container:RefreshEditor()
    return container
end

local function BuildMessagesCommandDropdown(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_MessagesCommandDropdownContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 40)

    local label = WINDOW_MANAGER:CreateControl("SCM_MessagesCommandDropdownLabel", container, CT_LABEL)
    label:SetFont("ZoFontWinH4")
    label:SetText("Command")
    label:SetDimensions(LABEL_WIDTH, 30)
    label:SetAnchor(LEFT, container, LEFT, 0, 0)

    local comboBoxControl = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesCommandDropdownCombo", container, "ZO_ComboBox")
    comboBoxControl:SetDimensions(DROPDOWN_WIDTH, 28)
    comboBoxControl:SetAnchor(LEFT, label, RIGHT, 10, 0)

    local comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    comboBox:SetSortsItems(false)

    local function RefreshDropdown()
        comboBox:ClearItems()

        local options = SmartChatMsg:GetMessagesCommandOptions()
        local currentSelection = SmartChatMsg:GetMessagesSelectedCommand()

        for _, option in ipairs(options) do
            local entry = comboBox:CreateItemEntry(option.name, function()
                SmartChatMsg:SetMessagesSelectedCommand(option.value)
                SmartChatMsg.settings:ResetNewMessageSection()
                SmartChatMsg:RefreshSettingsUI()
            end)
            comboBox:AddItem(entry)
        end

        comboBox:SetSelectedItem(currentSelection.name)
    end

    container.RefreshDropdown = RefreshDropdown
    RefreshDropdown()

    SmartChatMsg.settings.controls.messagesCommandDropdown = container
    return container
end

local function BuildMessagesChannelDescription(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_MessagesChannelDescriptionContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 24)

    local label = WINDOW_MANAGER:CreateControl("SCM_MessagesChannelDescriptionLabel", container, CT_LABEL)
    label:SetFont("ZoFontGame")
    label:SetDimensions(ROW_WIDTH, 24)
    label:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
    label:SetText("Select a Chat Channel for output")

    container.RefreshDescription = function()
        container:SetHidden(not SmartChatMsg:IsMessagesSelectionComplete())
    end

    container:RefreshDescription()
    SmartChatMsg.settings.controls.messagesChannelDescription = container
    return container
end

local function BuildMessagesGuildDropdown(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_MessagesGuildDropdownContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 40)

    local label = WINDOW_MANAGER:CreateControl("SCM_MessagesGuildDropdownLabel", container, CT_LABEL)
    label:SetFont("ZoFontWinH4")
    label:SetText("Guild")
    label:SetDimensions(LABEL_WIDTH, 30)
    label:SetAnchor(LEFT, container, LEFT, 0, 0)

    local comboBoxControl = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesGuildDropdownCombo", container, "ZO_ComboBox")
    comboBoxControl:SetDimensions(DROPDOWN_WIDTH, 28)
    comboBoxControl:SetAnchor(LEFT, label, RIGHT, 10, 0)

    local comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    comboBox:SetSortsItems(false)

    local function RefreshDropdown()
        comboBox:ClearItems()

        local options = SmartChatMsg:GetGuildOptions()
        local currentSelection = SmartChatMsg:GetSelectedGuildDisplayName()

        for _, option in ipairs(options) do
            local entry = comboBox:CreateItemEntry(option.name, function()
                SmartChatMsg:SetSelectedGuildIndex(option.value)
                SmartChatMsg.settings:ResetNewMessageSection()
                SmartChatMsg:RefreshSettingsUI()
            end)
            comboBox:AddItem(entry)
        end

        comboBox:SetSelectedItem(currentSelection)
    end

    container.RefreshDropdown = RefreshDropdown
    RefreshDropdown()

    SmartChatMsg.settings.controls.messagesGuildDropdown = container
    return container
end

local function BuildDefaultGuildDropdown(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_DefaultGuildDropdownContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 40)

    local label = WINDOW_MANAGER:CreateControl("SCM_DefaultGuildDropdownLabel", container, CT_LABEL)
    label:SetFont("ZoFontWinH4")
    label:SetText("Default Guild")
    label:SetDimensions(LABEL_WIDTH, 30)
    label:SetAnchor(LEFT, container, LEFT, 0, 0)

    local comboBoxControl = WINDOW_MANAGER:CreateControlFromVirtual("SCM_DefaultGuildDropdownCombo", container, "ZO_ComboBox")
    comboBoxControl:SetDimensions(DROPDOWN_WIDTH, 28)
    comboBoxControl:SetAnchor(LEFT, label, RIGHT, 10, 0)

    local comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    comboBox:SetSortsItems(false)

    local function RefreshDropdown()
        comboBox:ClearItems()

        local options = SmartChatMsg:GetDefaultGuildOptions()
        local currentSelection = SmartChatMsg:GetDefaultGuildDisplayName()

        for _, option in ipairs(options) do
            local entry = comboBox:CreateItemEntry(option.name, function()
                SmartChatMsg:SetDefaultGuildIndex(option.value)
                SmartChatMsg:RefreshSettingsUI()
            end)
            comboBox:AddItem(entry)
        end

        comboBox:SetSelectedItem(currentSelection)
    end

    container.RefreshDropdown = RefreshDropdown
    RefreshDropdown()

    SmartChatMsg.settings.controls.defaultGuildDropdown = container
    return container
end

local function BuildMessagesChannelDropdown(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_MessagesChannelDropdownContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 40)

    local label = WINDOW_MANAGER:CreateControl("SCM_MessagesChannelDropdownLabel", container, CT_LABEL)
    label:SetFont("ZoFontWinH4")
    label:SetText("Chat Channel")
    label:SetDimensions(LABEL_WIDTH, 30)
    label:SetAnchor(LEFT, container, LEFT, 0, 0)

    local comboBoxControl = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesChannelDropdownCombo", container, "ZO_ComboBox")
    comboBoxControl:SetDimensions(DROPDOWN_WIDTH, 28)
    comboBoxControl:SetAnchor(LEFT, label, RIGHT, 10, 0)

    local comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    comboBox:SetSortsItems(false)

    local function RefreshDropdown()
        comboBox:ClearItems()

        local options = SmartChatMsg:GetChatChannelOptions()
        local currentSelection = SmartChatMsg:GetSelectedMessagesChannel()

        for _, optionName in ipairs(options) do
            local entry = comboBox:CreateItemEntry(optionName, function()
                SmartChatMsg:SetSelectedMessagesChannel(optionName)
                SmartChatMsg:RefreshSettingsUI()
            end)
            comboBox:AddItem(entry)
        end

        comboBox:SetSelectedItem(currentSelection)
        container:SetHidden(not SmartChatMsg:IsMessagesSelectionComplete())
    end

    container.RefreshDropdown = RefreshDropdown
    RefreshDropdown()

    SmartChatMsg.settings.controls.messagesChannelDropdown = container
    return container
end


local function BuildMessagesBehaviorSettings(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_MessagesBehaviorSettingsContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 116)

    local reminderLabel = WINDOW_MANAGER:CreateControl("SCM_MessagesReminderLabel", container, CT_LABEL)
    reminderLabel:SetFont("ZoFontWinH4")
    reminderLabel:SetText("Reminder Minutes for this Command + Guild")
    reminderLabel:SetDimensions(ROW_WIDTH, 30)
    reminderLabel:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)

    local reminderBackdrop = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesReminderBackdrop", container, "ZO_EditBackdrop")
    reminderBackdrop:SetDimensions(120, 30)
    reminderBackdrop:SetAnchor(TOPLEFT, reminderLabel, BOTTOMLEFT, 0, 4)

    local reminderEditBox = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesReminderEditBox", reminderBackdrop, "ZO_DefaultEditForBackdrop")
    reminderEditBox:SetAnchorFill(reminderBackdrop)
    reminderEditBox:SetMaxInputChars(4)
    reminderEditBox:SetText("")
    reminderEditBox:SetHandler("OnTextChanged", function(self)
        local text = self:GetText() or ""
        local digitsOnly = text:gsub("[^%d]", "")

        if digitsOnly ~= text then
            self:SetText(digitsOnly)
            return
        end

        SmartChatMsg.settings.pendingGuildReminderMinutes = digitsOnly
    end)

    local autoPopulateCheckbox = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesAutoPopulateCheckbox", container, "ZO_CheckButton")
    autoPopulateCheckbox:SetAnchor(TOPLEFT, reminderBackdrop, BOTTOMLEFT, 0, 14)
    ZO_CheckButton_SetLabelText(autoPopulateCheckbox, "Auto Populate On Zone for this Command + Guild")
    ZO_CheckButton_SetToggleFunction(autoPopulateCheckbox, function(_, checked)
        SmartChatMsg.settings.pendingGuildAutoPopulateOnZone = checked == true
    end)

    local autoPopulateDescription = WINDOW_MANAGER:CreateControl("SCM_MessagesAutoPopulateDescription", container, CT_LABEL)
    autoPopulateDescription:SetFont("ZoFontGame")
    autoPopulateDescription:SetDimensions(ROW_WIDTH - 36, 36)
    autoPopulateDescription:SetAnchor(TOPLEFT, autoPopulateCheckbox, BOTTOMLEFT, 24, 2)
    autoPopulateDescription:SetText("These settings apply only to the currently selected Command and Guild. Reminders also remember the parameter used, such as the guild number.")

    SmartChatMsg.settings.controls.messagesBehaviorReminderEditBox = reminderEditBox
    SmartChatMsg.settings.controls.messagesBehaviorAutoPopulateCheckbox = autoPopulateCheckbox
    SmartChatMsg.settings.controls.messagesBehaviorSettings = container

    container:RefreshEditor()
    return container
end

local function BuildMessagesEditor(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_MessagesEditorContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 0)

    local countLabel = WINDOW_MANAGER:CreateControl("SCM_MessagesEditorCountLabel", container, CT_LABEL)
    countLabel:SetFont("ZoFontGame")
    countLabel:SetDimensions(ROW_WIDTH, 24)
    countLabel:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)

    local rowsContainer = WINDOW_MANAGER:CreateControl("SCM_ExistingMessagesRows", container, CT_CONTROL)
    rowsContainer:SetAnchor(TOPLEFT, countLabel, BOTTOMLEFT, 0, 8)
    rowsContainer:SetDimensions(ROW_WIDTH, 0)

    local addLabel = WINDOW_MANAGER:CreateControl("SCM_EnterMessageLabel", container, CT_LABEL)
    addLabel:SetFont("ZoFontWinH4")
    addLabel:SetText("Enter Message")
    addLabel:SetDimensions(LABEL_WIDTH, 30)

    local addBackdrop = WINDOW_MANAGER:CreateControlFromVirtual("SCM_EnterMessageBackdrop", container, "ZO_EditBackdrop")
    addBackdrop:SetDimensions(MESSAGE_BOX_WIDTH, MESSAGE_BOX_HEIGHT)

    local addEditBox = WINDOW_MANAGER:CreateControlFromVirtual("SCM_EnterMessageEditBox", addBackdrop, "ZO_DefaultEditMultiLineForBackdrop")
    addEditBox:SetAnchorFill(addBackdrop)
    addEditBox:SetFont("ZoFontChat")
    addEditBox:SetMaxInputChars(360)
    addEditBox:SetText("")
    addEditBox:SetHandler("OnTextChanged", function(self)
        local text = self:GetText() or ""

        if zo_strlen(text) > 360 then
            text = zo_strsub(text, 1, 360)
            self:SetText(text)
            return
        end

        SmartChatMsg.settings.pendingNewMessageText = text
    end)

    local addButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesEditorAddButton", container, "ZO_DefaultButton")
    addButton:SetDimensions(90, 28)
    addButton:SetText("Add")
    addButton:SetHandler("OnClicked", function()
        local trimmed = SmartChatMsg:Trim(SmartChatMsg.settings.pendingNewMessageText or "")
        if trimmed == "" then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Message must contain at least one non-space character.")
            return
        end

        local ok, err = SmartChatMsg:AddMessageEntryForSelection(trimmed)
        if not ok then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
            return
        end

        SmartChatMsg.settings.pendingNewMessageText = ""

        if SmartChatMsg.settings.controls.newMessageEditBox then
            SmartChatMsg.settings.controls.newMessageEditBox:SetText("")
        end

        PlaySound(SOUNDS.DEFAULT_CLICK)
        SmartChatMsg:RefreshSettingsUI()
    end)

    local resetButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_MessagesEditorResetButton", container, "ZO_DefaultButton")
    resetButton:SetDimensions(90, 28)
    resetButton:SetText("Reset")
    resetButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings.pendingNewMessageText = ""

        if SmartChatMsg.settings.controls.newMessageEditBox then
            SmartChatMsg.settings.controls.newMessageEditBox:SetText("")
        end

        PlaySound(SOUNDS.DEFAULT_CLICK)
        SmartChatMsg:RefreshSettingsUI()
    end)

    SmartChatMsg.settings.controls.savedMessageRows = SmartChatMsg.settings.controls.savedMessageRows or {}
    SmartChatMsg.settings.nextSavedMessageRowControlId = SmartChatMsg.settings.nextSavedMessageRowControlId or 1

    local function SetRowTextColor(editBox, isDirty)
        if not editBox then
            return
        end

        if isDirty then
            editBox:SetColor(0.95, 0.78, 0.18, 1)
        else
            editBox:SetColor(1, 1, 1, 1)
        end
    end

    local function ClearSavedMessageRows()
        local rows = SmartChatMsg.settings.controls.savedMessageRows or {}
        for _, row in ipairs(rows) do
            if row then
                row:SetHidden(true)
            end
        end

        SmartChatMsg.settings.controls.savedMessageRows = {}
    end

    local function GetCountText(count)
        if count == 0 then
            return "No Matching Messages"
        elseif count == 1 then
            return "(1) Matching Message Found"
        end

        return string.format("(%d) Matching Messages Found", count)
    end

    local function RefreshRowState(rowData)
        if not rowData or not rowData.entry then
            return
        end

        local currentEntry = rowData.entry
        local currentText = SmartChatMsg.settings:GetEffectiveMessageText(currentEntry)
        local isDirty = SmartChatMsg.settings:IsMessageEntryDirty(currentEntry)

        if rowData.editBox:GetText() ~= currentText then
            rowData.editBox:SetText(currentText)
        end

        SetRowTextColor(rowData.editBox, isDirty)

        if rowData.statusLabel then
            if isDirty then
                rowData.statusLabel:SetText("Pending Update")
                rowData.statusLabel:SetColor(0.95, 0.78, 0.18, 1)
            else
                rowData.statusLabel:SetText("")
            end
        end

        if rowData.updateButton then
            rowData.updateButton:SetEnabled(isDirty)
        end

        if rowData.revertButton then
            rowData.revertButton:SetHidden(not isDirty)
        end

        if rowData.deleteButton then
            rowData.deleteButton:SetHidden(isDirty)
        end
    end

    local function CreateSavedMessageRow(index, entry, anchorTarget, anchorPoint)
        local controlId = SmartChatMsg.settings.nextSavedMessageRowControlId
        SmartChatMsg.settings.nextSavedMessageRowControlId = controlId + 1

        local row = WINDOW_MANAGER:CreateControl(string.format("SCM_SavedMessageRow%d", controlId), rowsContainer, CT_CONTROL)
        row:SetDimensions(ROW_WIDTH, MESSAGE_BOX_HEIGHT + 24)

        if anchorTarget then
            row:SetAnchor(TOPLEFT, anchorTarget, anchorPoint or BOTTOMLEFT, 0, index == 1 and 0 or 10)
        else
            row:SetAnchor(TOPLEFT, rowsContainer, TOPLEFT, 0, 0)
        end

        local backdrop = WINDOW_MANAGER:CreateControlFromVirtual(string.format("SCM_SavedMessageBackdrop%d", controlId), row, "ZO_EditBackdrop")
        backdrop:SetDimensions(MESSAGE_BOX_WIDTH, MESSAGE_BOX_HEIGHT)
        backdrop:SetAnchor(TOPLEFT, row, TOPLEFT, 0, 0)

        local editBox = WINDOW_MANAGER:CreateControlFromVirtual(string.format("SCM_SavedMessageEditBox%d", controlId), backdrop, "ZO_DefaultEditMultiLineForBackdrop")
        editBox:SetAnchorFill(backdrop)
        editBox:SetFont("ZoFontChat")
        editBox:SetMaxInputChars(360)

        local statusLabel = WINDOW_MANAGER:CreateControl(string.format("SCM_SavedMessageStatusLabel%d", controlId), row, CT_LABEL)
        statusLabel:SetFont("ZoFontGame")
        statusLabel:SetDimensions(MESSAGE_BOX_WIDTH, 20)
        statusLabel:SetAnchor(TOPLEFT, backdrop, BOTTOMLEFT, 0, 4)

        local updateButton = WINDOW_MANAGER:CreateControlFromVirtual(string.format("SCM_SavedMessageUpdateButton%d", controlId), row, "ZO_DefaultButton")
        updateButton:SetDimensions(70, 28)
        updateButton:SetText("Update")
        updateButton:SetAnchor(TOPLEFT, backdrop, TOPRIGHT, 12, 0)

        local revertButton = WINDOW_MANAGER:CreateControlFromVirtual(string.format("SCM_SavedMessageRevertButton%d", controlId), row, "ZO_DefaultButton")
        revertButton:SetDimensions(70, 28)
        revertButton:SetText("Revert")
        revertButton:SetAnchor(LEFT, updateButton, RIGHT, 6, 0)

        local deleteButton = WINDOW_MANAGER:CreateControlFromVirtual(string.format("SCM_SavedMessageDeleteButton%d", controlId), row, "ZO_DefaultButton")
        deleteButton:SetDimensions(70, 28)
        deleteButton:SetText("Delete")
        deleteButton:SetAnchor(LEFT, updateButton, RIGHT, 6, 0)

        local rowData = {
            control = row,
            entry = entry,
            backdrop = backdrop,
            editBox = editBox,
            statusLabel = statusLabel,
            updateButton = updateButton,
            revertButton = revertButton,
            deleteButton = deleteButton,
        }

        editBox:SetHandler("OnTextChanged", function(self)
            local text = self:GetText() or ""

            if zo_strlen(text) > 360 then
                text = zo_strsub(text, 1, 360)
                self:SetText(text)
                return
            end

            SmartChatMsg.settings:SetPendingMessageEdit(entry.id, text, entry.text or "")
            RefreshRowState(rowData)
        end)

        updateButton:SetHandler("OnClicked", function()
            if not SmartChatMsg.settings:IsMessageEntryDirty(entry) then
                return
            end

            local text = SmartChatMsg.settings:GetEffectiveMessageText(entry)
            local trimmed = SmartChatMsg:Trim(text)

            if trimmed == "" then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, "Message must contain at least one non-space character.")
                return
            end

            local ok, err = SmartChatMsg:UpdateMessageEntry(entry.id, trimmed)
            if not ok then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
                return
            end

            SmartChatMsg.settings.pendingMessageEdits[entry.id] = nil
            PlaySound(SOUNDS.DEFAULT_CLICK)
            SmartChatMsg:RefreshSettingsUI()
        end)

        revertButton:SetHandler("OnClicked", function()
            SmartChatMsg.settings.pendingMessageEdits[entry.id] = nil
            rowData.editBox:SetText(entry.text or "")
            RefreshRowState(rowData)
            PlaySound(SOUNDS.DEFAULT_CLICK)
        end)

        deleteButton:SetHandler("OnClicked", function()
            ZO_Dialogs_ShowDialog(DELETE_MESSAGE_DIALOG_NAME, {
                callback = function()
                    local ok, err = SmartChatMsg:DeleteMessageEntry(entry.id)
                    if not ok then
                        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, err)
                        return
                    end

                    SmartChatMsg.settings.pendingMessageEdits[entry.id] = nil
                    PlaySound(SOUNDS.DEFAULT_CLICK)
                    SmartChatMsg:RefreshSettingsUI()
                end,
            })
        end)

        SmartChatMsg.settings.controls.savedMessageRows[#SmartChatMsg.settings.controls.savedMessageRows + 1] = row
        RefreshRowState(rowData)

        return row
    end

    local function RefreshEditor()
        local hasCompleteSelection = SmartChatMsg:IsMessagesSelectionComplete()
        local selectedChannel = SmartChatMsg:GetSelectedMessagesChannel()
        local hasChannel = selectedChannel ~= "Select a Chat Channel"
        local entries = SmartChatMsg:GetMessageEntriesForSelection()
        local shouldShow = hasCompleteSelection and hasChannel

        if addEditBox:GetText() ~= (SmartChatMsg.settings.pendingNewMessageText or "") then
            addEditBox:SetText(SmartChatMsg.settings.pendingNewMessageText or "")
        end

        countLabel:SetText(GetCountText(#entries))

        ClearSavedMessageRows()

        if not shouldShow then
            countLabel:SetHidden(true)
            rowsContainer:SetHidden(true)
            addLabel:SetHidden(true)
            addBackdrop:SetHidden(true)
            addButton:SetHidden(true)
            resetButton:SetHidden(true)
            container:SetHidden(true)
            rowsContainer:SetHeight(0)
            container:SetHeight(0)
            return
        end

        container:SetHidden(false)
        countLabel:SetHidden(false)
        rowsContainer:SetHidden(false)
        addLabel:SetHidden(false)
        addBackdrop:SetHidden(false)
        addButton:SetHidden(false)
        resetButton:SetHidden(false)

        local lastRow = nil
        local rowsHeight = 0

        for index, entry in ipairs(entries) do
            local row = CreateSavedMessageRow(index, entry, lastRow, BOTTOMLEFT)
            lastRow = row
            rowsHeight = rowsHeight + MESSAGE_BOX_HEIGHT + 24
            if index > 1 then
                rowsHeight = rowsHeight + 10
            end
        end

        rowsContainer:SetHeight(rowsHeight)

        if lastRow then
            addLabel:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, 14)
        else
            addLabel:SetAnchor(TOPLEFT, rowsContainer, TOPLEFT, 0, 0)
        end

        addBackdrop:SetAnchor(TOPLEFT, addLabel, BOTTOMLEFT, 0, 4)
        addButton:SetAnchor(TOPLEFT, addBackdrop, TOPRIGHT, 12, 0)
        resetButton:SetAnchor(LEFT, addButton, RIGHT, 8, 0)

        local totalHeight = 24
        if rowsHeight > 0 then
            totalHeight = totalHeight + 8 + rowsHeight + 14
        else
            totalHeight = totalHeight + 8
        end

        totalHeight = totalHeight + 30 + 4 + MESSAGE_BOX_HEIGHT
        container:SetHeight(totalHeight)
    end

    container.RefreshEditor = RefreshEditor

    SmartChatMsg.settings.controls.newMessageEditBox = addEditBox
    SmartChatMsg.settings.controls.messagesEditor = container

    container:RefreshEditor()
    return container
end

local function BuildImportExportEditor(parent)
    local container = WINDOW_MANAGER:CreateControl("SCM_ImportExportContainer", parent, CT_CONTROL)
    container:SetDimensions(ROW_WIDTH, 220)

    local description = WINDOW_MANAGER:CreateControl("SCM_ImportExportDescription", container, CT_LABEL)
    description:SetFont("ZoFontGame")
    description:SetDimensions(ROW_WIDTH, 36)
    description:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
    description:SetText("Use Export to generate a backup string for all SmartChatMsg settings.")

    local backdrop = WINDOW_MANAGER:CreateControlFromVirtual("SCM_ImportExportBackdrop", container, "ZO_EditBackdrop")
    backdrop:SetDimensions(ROW_WIDTH - 12, 120)
    backdrop:SetAnchor(TOPLEFT, description, BOTTOMLEFT, 0, 8)

    local editBox = WINDOW_MANAGER:CreateControlFromVirtual("SCM_ImportExportEditBox", backdrop, "ZO_DefaultEditMultiLineForBackdrop")
    editBox:SetAnchorFill(backdrop)
    editBox:SetFont("ZoFontChat")
    editBox:SetMaxInputChars(20000)
    editBox:SetText("")
    editBox:SetHandler("OnTextChanged", function(self)
        local text = self:GetText() or ""
        if zo_strlen(text) > 20000 then
            text = zo_strsub(text, 1, 20000)
            self:SetText(text)
            return
        end

        SmartChatMsg.settings.pendingImportExportText = text
    end)

    local exportButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_ExportSettingsButton", container, "ZO_DefaultButton")
    exportButton:SetDimensions(90, 28)
    exportButton:SetText("Export")
    exportButton:SetAnchor(TOPLEFT, backdrop, BOTTOMLEFT, 0, 10)
    exportButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:ExportSettings()
    end)

    local importButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_ImportSettingsButton", container, "ZO_DefaultButton")
    importButton:SetDimensions(90, 28)
    importButton:SetText("Import")
    importButton:SetAnchor(LEFT, exportButton, RIGHT, 8, 0)
    importButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:ImportSettings()
    end)

    local clearButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_ClearImportExportButton", container, "ZO_DefaultButton")
    clearButton:SetDimensions(90, 28)
    clearButton:SetText("Clear")
    clearButton:SetAnchor(LEFT, importButton, RIGHT, 8, 0)
    clearButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:ClearImportExportText()
    end)

    local copyButton = WINDOW_MANAGER:CreateControlFromVirtual("SCM_CopyExportSettingsButton", container, "ZO_DefaultButton")
    copyButton:SetDimensions(90, 28)
    copyButton:SetText("Copy")
    copyButton:SetAnchor(LEFT, clearButton, RIGHT, 8, 0)
    copyButton:SetHandler("OnClicked", function()
        SmartChatMsg.settings:CopyExportText()
    end)

    container.RefreshEditor = function()
        if SmartChatMsg.settings.controls.importExportEditBox and SmartChatMsg.settings.controls.importExportEditBox:GetText() ~= (SmartChatMsg.settings.pendingImportExportText or "") then
            SmartChatMsg.settings.controls.importExportEditBox:SetText(SmartChatMsg.settings.pendingImportExportText or "")
        end
    end

    SmartChatMsg.settings.controls.importExportEditBox = editBox
    SmartChatMsg.settings.controls.importExportEditor = container

    container:RefreshEditor()
    return container
end

function SmartChatMsg:RefreshSettingsUI()
    if self.settings.controls.commandDropdown and self.settings.controls.commandDropdown.RefreshDropdown then
        self.settings.controls.commandDropdown:RefreshDropdown()
    end

    if self.settings.controls.commandEditor and self.settings.controls.commandEditor.RefreshEditor then
        self.settings.controls.commandEditor:RefreshEditor()
    end

    if self.settings.controls.defaultGuildDropdown and self.settings.controls.defaultGuildDropdown.RefreshDropdown then
        self.settings.controls.defaultGuildDropdown:RefreshDropdown()
    end

    if self.settings.controls.messagesCommandDropdown and self.settings.controls.messagesCommandDropdown.RefreshDropdown then
        self.settings.controls.messagesCommandDropdown:RefreshDropdown()
    end

    if self.settings.controls.messagesGuildDropdown and self.settings.controls.messagesGuildDropdown.RefreshDropdown then
        self.settings.controls.messagesGuildDropdown:RefreshDropdown()
    end

    if self.settings.controls.messagesChannelDropdown and self.settings.controls.messagesChannelDropdown.RefreshDropdown then
        self.settings.controls.messagesChannelDropdown:RefreshDropdown()
    end

    if self.settings.controls.messagesBehaviorSettings and self.settings.controls.messagesBehaviorSettings.RefreshEditor then
        self.settings.controls.messagesBehaviorSettings:RefreshEditor()
    end

    if self.settings.controls.messagesEditor and self.settings.controls.messagesEditor.RefreshEditor then
        self.settings.controls.messagesEditor:RefreshEditor()
    end

    if self.settings.controls.importExportEditor and self.settings.controls.importExportEditor.RefreshEditor then
        self.settings.controls.importExportEditor:RefreshEditor()
    end

    if self.settings.panel then
        CALLBACK_MANAGER:FireCallbacks("LAM-RefreshPanel", self.settings.panel)
    end
end

function SmartChatMsg:CreateSettingsPanel()
    self.settings:InitializeState()
    RegisterDeleteDialogs()

    local panelData = {
        type = "panel",
        name = "SmartChatMsg",
        displayName = "SmartChatMsg",
        author = "evainefaye",
        version = "1.3.2",
        registerForRefresh = true,
        registerForDefaults = false,
    }

    self.settings.panel = LAM2:RegisterAddonPanel("SmartChatMsgOptionsPanel", panelData)

    local commandDropdownHolder
    local commandEditorHolder
    local defaultGuildDropdownHolder
    local messagesCommandDropdownHolder
    local messagesGuildDropdownHolder
    local messagesChannelDropdownHolder
    local messagesBehaviorSettingsHolder
    local messagesEditorHolder
    local importExportHolder

    local optionsTable = {
        {
            type = "description",
            text = "Allows you to create custom command(s) that can be filtered by guild number and used to output one of several random messages to the appropriate chat type.",
            width = "full",
        },
        {
            type = "submenu",
            name = "General",
            controls = {
                {
                    type = "description",
                    text = "Select the Default Guild to use when a slash command is run without a numeric guild parameter.",
                    width = "full",
                },
                {
                    type = "custom",
                    reference = "SCM_DefaultGuildDropdownHolder",
                    createFunc = function(control)
                        control:SetHeight(40)
                        defaultGuildDropdownHolder = BuildDefaultGuildDropdown(control)
                        defaultGuildDropdownHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if defaultGuildDropdownHolder and defaultGuildDropdownHolder.RefreshDropdown then
                            defaultGuildDropdownHolder:RefreshDropdown()
                        end

                        control:SetHeight(SmartChatMsg:HasAnyGuilds() and 40 or 0)
                    end,
                },
            },
        },
        {
            type = "submenu",
            name = "Commands",
            controls = {
                {
                    type = "description",
                    text = "Select a command to edit, or delete it, or create a new command. You must have at least one command defined before you can create associated messages.",
                    width = "full",
                },
                {
                    type = "custom",
                    reference = "SCM_CommandDropdownHolder",
                    createFunc = function(control)
                        control:SetHeight(40)
                        commandDropdownHolder = BuildCommandDropdown(control)
                        commandDropdownHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function()
                        if commandDropdownHolder and commandDropdownHolder.RefreshDropdown then
                            commandDropdownHolder:RefreshDropdown()
                        end
                    end,
                },
                {
                    type = "custom",
                    reference = "SCM_CommandEditorHolder",
                    createFunc = function(control)
                        control:SetHeight(96)
                        commandEditorHolder = BuildCommandEditor(control)
                        commandEditorHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if commandEditorHolder and commandEditorHolder.RefreshEditor then
                            commandEditorHolder:RefreshEditor()
                        end

                        if SmartChatMsg.settings:IsEditorVisible() then
                            control:SetHeight(96)
                        else
                            control:SetHeight(0)
                        end
                    end,
                },
            },
        },
        {
            type = "submenu",
            name = "Messages",
            disabled = function()
                return not SmartChatMsg:CanUseMessagesSection()
            end,
            controls = {
                {
                    type = "description",
                    text = "Select a Command and a Guild for which you would like this message to apply.",
                    width = "full",
                },
                {
                    type = "custom",
                    reference = "SCM_MessagesCommandDropdownHolder",
                    createFunc = function(control)
                        control:SetHeight(40)
                        messagesCommandDropdownHolder = BuildMessagesCommandDropdown(control)
                        messagesCommandDropdownHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if messagesCommandDropdownHolder and messagesCommandDropdownHolder.RefreshDropdown then
                            messagesCommandDropdownHolder:RefreshDropdown()
                        end

                        control:SetHeight(SmartChatMsg:CanUseMessagesSection() and 40 or 0)
                    end,
                },
                {
                    type = "custom",
                    reference = "SCM_MessagesGuildDropdownHolder",
                    createFunc = function(control)
                        control:SetHeight(40)
                        messagesGuildDropdownHolder = BuildMessagesGuildDropdown(control)
                        messagesGuildDropdownHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if messagesGuildDropdownHolder and messagesGuildDropdownHolder.RefreshDropdown then
                            messagesGuildDropdownHolder:RefreshDropdown()
                        end

                        control:SetHeight(SmartChatMsg:CanUseMessagesSection() and 40 or 0)
                    end,
                },
                {
                    type = "custom",
                    reference = "SCM_MessagesChannelDescriptionHolder",
                    createFunc = function(control)
                        control:SetHeight(24)
                        local messagesChannelDescriptionHolder = BuildMessagesChannelDescription(control)
                        messagesChannelDescriptionHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if SmartChatMsg.settings.controls.messagesChannelDescription and SmartChatMsg.settings.controls.messagesChannelDescription.RefreshDescription then
                            SmartChatMsg.settings.controls.messagesChannelDescription:RefreshDescription()
                        end

                        control:SetHeight(SmartChatMsg:IsMessagesSelectionComplete() and 24 or 0)
                    end,
                },
                {
                    type = "custom",
                    reference = "SCM_MessagesChannelDropdownHolder",
                    createFunc = function(control)
                        control:SetHeight(40)
                        messagesChannelDropdownHolder = BuildMessagesChannelDropdown(control)
                        messagesChannelDropdownHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if messagesChannelDropdownHolder and messagesChannelDropdownHolder.RefreshDropdown then
                            messagesChannelDropdownHolder:RefreshDropdown()
                        end

                        control:SetHeight(SmartChatMsg:IsMessagesSelectionComplete() and 40 or 0)
                    end,
                },
                {
                    type = "custom",
                    reference = "SCM_MessagesBehaviorSettingsHolder",
                    createFunc = function(control)
                        control:SetHeight(116)
                        messagesBehaviorSettingsHolder = BuildMessagesBehaviorSettings(control)
                        messagesBehaviorSettingsHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if messagesBehaviorSettingsHolder and messagesBehaviorSettingsHolder.RefreshEditor then
                            messagesBehaviorSettingsHolder:RefreshEditor()
                        end

                        control:SetHeight(SmartChatMsg:IsMessagesSelectionComplete() and 116 or 0)
                    end,
                },
                {
                    type = "custom",
                    reference = "SCM_MessagesEditorHolder",
                    createFunc = function(control)
                        control:SetHeight(0)
                        messagesEditorHolder = BuildMessagesEditor(control)
                        messagesEditorHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if messagesEditorHolder and messagesEditorHolder.RefreshEditor then
                            messagesEditorHolder:RefreshEditor()

                            local hasChannel = SmartChatMsg:GetSelectedMessagesChannel() ~= "Select a Chat Channel"
                            local shouldShow = SmartChatMsg:IsMessagesSelectionComplete() and hasChannel

                            control:SetHeight(shouldShow and messagesEditorHolder:GetHeight() or 0)
                        else
                            control:SetHeight(0)
                        end
                    end,
                },
            },
        },
        {
            type = "submenu",
            name = "Import / Export",
            controls = {
                {
                    type = "custom",
                    reference = "SCM_ImportExportHolder",
                    createFunc = function(control)
                        control:SetHeight(220)
                        importExportHolder = BuildImportExportEditor(control)
                        importExportHolder:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
                    end,
                    refreshFunc = function(control)
                        if importExportHolder and importExportHolder.RefreshEditor then
                            importExportHolder:RefreshEditor()
                        end

                        control:SetHeight(220)
                    end,
                },
            },
        },
    }

    LAM2:RegisterOptionControls("SmartChatMsgOptionsPanel", optionsTable)
end

function SmartChatMsg:OpenSettings()
    if self.settings and self.settings.panel then
        self.settings:InitializeState()
        LAM2:OpenToPanel(self.settings.panel)
        self:RefreshSettingsUI()
    end
end
