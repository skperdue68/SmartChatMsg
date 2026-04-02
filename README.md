# SmartChatMsg (v1.5.3)

SmartChatMsg is an Elder Scrolls Online addon for players who regularly post reusable chat messages such as guild recruitment ads, trial announcements, officer notices, and other repeated chat content.

It lets you create your own slash commands, store multiple message variants for each command, organize those messages by guild, and then populate the correct message into chat with the proper channel selected.

## What's New in 1.5.3
- Added **Populate Sound** at the **Command + Guild** level
- Added a **Preview** button for the selected populate sound
- Limited the sound dropdown to a curated set of useful ESO sounds
- Included **DUEL_START** by default and **None** for silent operation
- Populate sound now plays when a message is automatically populated by **Auto Populate Chat on Zone** or by **Repeat Every** automation

## Core Features
- Dynamic custom slash commands
- Command names are sanitized and registered as slash commands
- Supports parameters `1`-`5`, `g1`-`g5`, and `o1`-`o5`
- `g#` and `o#` resolve to the same guild slot as the matching number
- Optional default guild for commands used without a guild parameter
- Multiple saved messages per command and guild
- Saved output channel selection for **Zone**, **Guild**, or **Officer** chat
- Automatic chat channel restore after message send
- Timeout restore also clears the pending chat buffer
- **Repeat Every (mins)** stored per **Command + Guild**
- **Retry Delay (mins)** stored per **Command + Guild**
- **Auto Populate Chat on Zone** stored per **Command + Guild**
- **Cooldown (mins)** stored per **Command + Guild**
- **Populate Sound** stored per **Command + Guild**
- Import/export support for current settings
- Built-in substitutions for `%time%`, `%guild%`, and `%zone%`
- `/scm` opens the settings panel
- `/scmdebug` toggles debug logging, or accepts `on`, `off`, and `status`

## How SmartChatMsg Works
1. Create a command in the settings panel.
2. Pick a command and a guild in the Messages section.
3. Choose the output channel for that command/guild combination.
4. Add one or more saved messages.
5. Optionally configure Repeat, Retry, Auto Populate on Zone, Cooldown, and Populate Sound.
6. Run the slash command in chat when you want SmartChatMsg to populate a message.

The addon places a message into the chat input instead of silently posting it. That gives you a chance to review the text before actually sending it.

## Slash Command Usage
If your command name is `recruit`, SmartChatMsg registers `/recruit`.

Typical usage:
- `/recruit`
- `/recruit 1`
- `/recruit g1`
- `/recruit o1`

Behavior:
- Using the command normally starts or restarts that command for the resolved guild.
- Adding `off` turns off repeat and/or zone auto populate for that command and guild.
- `1`, `g1`, and `o1` all resolve to guild slot 1. The same pattern applies for 2 through 5.
- If no guild parameter is supplied, SmartChatMsg uses the configured default guild when one is set.

Examples:
- `/recruit` uses the default guild
- `/recruit 2` targets guild slot 2
- `/recruit g3` targets guild slot 3
- `/recruit o4` still targets guild slot 4
- `/recruit off` turns off automation for the default guild
- `/recruit 2 off` turns off automation for guild slot 2

## Messages and Message Selection
Each command can have multiple saved messages for the same guild.

When SmartChatMsg needs to populate a message, it selects from the saved entries using a weighted system that favors messages that were used less recently and less often. This helps rotate your saved messages instead of always picking the same one.

Substitutions are applied when the message is populated:
- `%time%` becomes `morning`, `afternoon`, or `evening`
- `%guild%` becomes the resolved guild name
- `%zone%` becomes your current zone name

Substitutions are case-insensitive, so `%TIME%`, `%Guild%`, and `%Zone%` also work.

## Output Channel Behavior
Output channel is saved per **Command + Guild**.

Available options:
- **Zone**
- **Guild (/g#)**
- **Officer (/o#)**

When SmartChatMsg populates a message, it switches the chat input to the selected destination, fills in the message, and then restores your previous chat channel after the message is sent. If the message is not sent in time, the addon restores the previous channel after the global timeout and clears the pending chat text.

## Repeat Every (mins)
Repeat Every creates a repeat cycle for the selected command and guild.

How it works:
- Run the command once to start it.
- SmartChatMsg records the last-used state.
- After the configured number of minutes, it repopulates a message into the chat input.
- Once that populated message is confirmed as sent, the next repeat cycle is scheduled.

Notes:
- Repeat is configured per **Command + Guild**.
- Setting a valid Repeat value turns off **Auto Populate Chat on Zone** for that same command/guild.
- Running the command again restarts the cycle.
- Using the command with `off` stops the automation.

## Retry Delay (mins)
Retry Delay is only relevant when **Repeat Every** is active.

How it works:
- If the repeated message is populated but not actually sent, SmartChatMsg can try again after the retry delay.
- If Retry Delay is `0`, blank, or invalid, SmartChatMsg skips retry and resumes the normal repeat schedule after the populate attempt times out.
- Retry Delay is automatically capped so it cannot exceed **Repeat Every**.

## Auto Populate Chat on Zone
Auto Populate Chat on Zone is the alternative automation mode.

How it works:
- Run the slash command once to activate it for the selected command and guild.
- When you change into a parent zone, SmartChatMsg can populate a message for that zone.
- The message is placed into chat input and can then be sent by you.
- Running the command again, or using `off`, turns it off.

Important behavior:
- Auto Populate is stored per **Command + Guild**.
- Turning it on clears **Repeat Every** for that same command/guild.
- Only one active auto-populate command can run at a time.
- The first player activation after login is ignored.
- Zone auto populate only fires on actual zone changes, not when the zone did not change.
- It only fires for parent zones.

## Cooldown (mins)
Cooldown applies to **Auto Populate Chat on Zone** and is stored per **Command + Guild**.

The cooldown is tracked by zone, so the addon can avoid repeatedly populating the same message again too soon for the same zone.

Defaults and validation:
- Default is `60` minutes
- Invalid, blank, or non-positive values normalize back to `60`

## Populate Sound
Populate Sound is stored per **Command + Guild**.

Behavior:
- Default sound is **DUEL_START**
- **None** disables populate sound completely
- The selected sound plays when a message is automatically populated by **Repeat** or **Auto Populate Chat on Zone**
- The **Preview** button lets you test the currently selected sound from the settings panel

## Global Settings
### Default Guild
Default Guild is used when you run a command without specifying a guild slot.

### Auto-Remove Pending Chat Timeout
This is the global revert timer.

Behavior:
- Applies to all commands
- Restores the previous chat channel if the pending populated message is not sent in time
- Clears the pending chat buffer at timeout
- Minimum valid value is 30 seconds
- Default is 60 seconds

## Import and Export
SmartChatMsg includes import/export support for settings.

Export includes:
- Commands
- Messages
- Saved output channels
- Per-command/per-guild behavior settings
- Default guild
- Global revert timeout
- Active auto-populate state

Import behavior:
- Import replaces existing SmartChatMsg settings
- Import requires confirmation before applying
- Success and error feedback are shown in-game

## Basic Setup Example
Example setup for a recruitment command:
1. Open settings with `/scm`.
2. Add a command named `recruit`.
3. In the Messages section, select `recruit`.
4. Select the guild you want it associated with.
5. Set Output Channel to `Zone`.
6. Add several recruitment messages.
7. Optionally enable either Repeat Every or Auto Populate Chat on Zone.
8. Use `/recruit` or `/recruit 1` in chat.

## Tips
- Save more than one message per command/guild to improve rotation variety.
- Use `%guild%` and `%zone%` to reduce how many separate message variants you need.
- Use Repeat for timed reposting.
- Use Auto Populate on Zone for travel-based reminders.
- Use `off` to clearly stop automation for a specific command/guild.

## Included Commands
- `/scm` opens SmartChatMsg settings
- `/scmdebug` toggles or controls debug logging

## Files
- `SCM_SavedVars.lua`
- `SCM_Settings.lua`
- `SmartChatMsg.lua`
