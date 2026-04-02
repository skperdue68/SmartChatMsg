SmartChatMsg (v1.5.3.1)
=====================

SmartChatMsg is an ESO addon for players who regularly post reusable chat messages such as guild recruitment ads, trial announcements, officer notices, and other repeated chat content.

It lets you create your own slash commands, store multiple message variants for each command, organize those messages by guild, and populate the correct message into chat with the proper channel selected.

WHAT'S NEW IN 1.5.3.1
-------------------
- Message usage and command last-used are now recorded only after the watcher confirms the populated message was actually sent
- Regular slash-command populates now use the same sent-confirmation flow as repeat and zone auto populate
- Zone auto populate keeps the original triggering zone id when recording the per-zone cooldown after send
- Added Populate Sound at the Command + Guild level
- Added a Preview button for the selected populate sound
- Limited the sound dropdown to a curated set of useful ESO sounds
- Included DUEL_START by default and None for silent operation
- Populate sound now plays when a message is automatically populated by Auto Populate Chat on Zone or Repeat Every

CORE FEATURES
-------------
- Dynamic custom slash commands
- Command names are sanitized and registered as slash commands
- Supports parameters 1-5, g1-g5, and o1-o5
- g# and o# resolve to the same guild slot as the matching number
- Optional default guild for commands used without a guild parameter
- Multiple saved messages per command and guild
- Saved output channel selection for Zone, Guild, or Officer chat
- Automatic chat channel restore after message send
- Timeout restore also clears the pending chat buffer
- Repeat Every (mins) stored per Command + Guild
- Retry Delay (mins) stored per Command + Guild
- Auto Populate Chat on Zone stored per Command + Guild
- Cooldown (mins) stored per Command + Guild
- Populate Sound stored per Command + Guild
- Import/export support for current settings
- Built-in substitutions for %time%, %guild%, and %zone%
- /scm opens the settings panel
- /scmdebug toggles debug logging, or accepts on, off, and status

HOW IT WORKS
------------
1. Create a command in the settings panel.
2. Pick a command and a guild in the Messages section.
3. Choose the output channel for that command/guild combination.
4. Add one or more saved messages.
5. Optionally configure Repeat, Retry, Auto Populate on Zone, Cooldown, and Populate Sound.
6. Run the slash command when you want SmartChatMsg to populate a message.

The addon places a message into the chat input instead of silently posting it, so you can review the text before sending it.

SLASH COMMAND USAGE
-------------------
If your command name is recruit, SmartChatMsg registers /recruit.

Examples:
- /recruit
- /recruit 1
- /recruit g1
- /recruit o1
- /recruit off
- /recruit 2 off

Behavior:
- Using the command normally starts or restarts that command for the resolved guild.
- Adding off turns off repeat and/or zone auto populate for that command and guild.
- 1, g1, and o1 all resolve to guild slot 1. The same pattern applies for 2 through 5.
- If no guild parameter is supplied, SmartChatMsg uses the configured default guild when one is set.

MESSAGES AND MESSAGE ROTATION
-----------------------------
Each command can have multiple saved messages for the same guild.

When SmartChatMsg populates a message, it selects from the saved entries using a weighted system that favors messages that were used less recently and less often. This helps rotate your saved messages instead of always picking the same one.

Built-in substitutions:
- %time% becomes morning, afternoon, or evening
- %guild% becomes the resolved guild name
- %zone% becomes your current zone name

Substitutions are case-insensitive.

OUTPUT CHANNELS
---------------
Output channel is saved per Command + Guild.

Available options:
- Zone
- Guild (/g#)
- Officer (/o#)

When SmartChatMsg populates a message, it switches the chat input to the selected destination, fills in the message, and restores your previous chat channel after the message is sent. If the message is not sent in time, the addon restores the previous channel after the global timeout and clears the pending chat text.

REPEAT EVERY (MINS)
-------------------
Repeat Every creates a repeat cycle for the selected command and guild.

How it works:
- Run the command once to start it.
- After the configured number of minutes, SmartChatMsg repopulates a message into chat.
- Once that message is actually sent, the next repeat cycle is scheduled.

Notes:
- Repeat is configured per Command + Guild.
- Setting a valid Repeat value turns off Auto Populate Chat on Zone for that same command/guild.
- Running the command again restarts the cycle.
- Using the command with off stops the automation.

RETRY DELAY (MINS)
------------------
Retry Delay only matters when Repeat Every is active.

- If a repeated message is populated but not sent, SmartChatMsg can try again after the retry delay.
- If Retry Delay is 0, blank, or invalid, SmartChatMsg skips retry and resumes the normal repeat schedule after timeout.
- Retry Delay is automatically capped so it cannot exceed Repeat Every.

AUTO POPULATE CHAT ON ZONE
--------------------------
Auto Populate Chat on Zone is the alternative automation mode.

How it works:
- Run the slash command once to activate it for the selected command and guild.
- When you change into a parent zone, SmartChatMsg can populate a message for that zone.
- SmartChatMsg waits for the outgoing chat watcher to confirm the message was actually sent before recording last-used state for that auto-populate event.
- The zone cooldown is recorded against the original zone id that triggered the auto-populate, even if you change zones before sending.
- Running the command again, or using off, turns it off.

Important behavior:
- Auto Populate is stored per Command + Guild.
- Turning it on clears Repeat Every for that same command/guild.
- Only one active auto-populate command can run at a time.
- The first player activation after login is ignored.
- Zone auto populate only fires on actual zone changes.
- It only fires for parent zones.

COOLDOWN (MINS)
---------------
Cooldown applies to Auto Populate Chat on Zone and is stored per Command + Guild.

The cooldown is tracked by zone, and the timestamp is only recorded after the watcher confirms the populated message was actually sent. The recorded zone is the zone that triggered the auto-populate event, not a later zone you may have entered before sending.

Defaults and validation:
- Default is 60 minutes
- Invalid, blank, or non-positive values normalize back to 60

POPULATE SOUND
--------------
Populate Sound is stored per Command + Guild.

- Default is DUEL_START
- None disables sound completely
- The sound plays when a message is automatically populated by Repeat or Auto Populate Chat on Zone
- Preview lets you test the currently selected sound from settings

GLOBAL SETTINGS
---------------
Default Guild:
- Used when you run a command without specifying a guild slot

Auto-Remove Pending Chat Timeout:
- Global revert timer for all commands
- Restores the previous chat channel if a populated message is not sent in time
- Clears the pending chat buffer at timeout
- Minimum valid value is 30 seconds
- Default is 60 seconds

IMPORT / EXPORT
---------------
SmartChatMsg supports import and export of settings.

Export includes commands, messages, saved output channels, per-command/per-guild settings, default guild, global revert timeout, and active auto-populate state.

Import replaces existing SmartChatMsg settings and requires confirmation before applying.

BASIC SETUP EXAMPLE
-------------------
1. Open settings with /scm.
2. Add a command named recruit.
3. In the Messages section, select recruit.
4. Select the guild it belongs to.
5. Set Output Channel to Zone.
6. Add several recruitment messages.
7. Optionally enable either Repeat Every or Auto Populate Chat on Zone.
8. Use /recruit or /recruit 1 in chat.

INCLUDED COMMANDS
-----------------
- /scm
- /scmdebug
