# SmartChatMsg (v1.5.3.1)

SmartChatMsg is an Elder Scrolls Online addon for players who regularly post reusable chat messages such as guild recruitment ads, trial announcements, officer notices, and other repeated chat content.

It lets you create your own slash commands, store multiple message variants for each command, organize those messages by guild, and then populate the correct message into chat with the proper channel selected.

## Incoming duplicate-message coordination

SmartChatMsg now watches other players' Zone, Guild, and Officer chat. When an
incoming message matches a saved template for that channel, it records usage for
the entire **Command + Guild** combination and adds a random **30–90 seconds**
to its cooldown. An already-running Repeat timer restarts with the same extra
delay. Receiving a match does not start automation that is inactive.

- Your own account/character and customer-service messages are excluded.
- Guild and Officer chat are matched only against the receiving guild and the
  corresponding saved output channel. Guild slot order is resolved locally.
- Zone chat searches all combinations configured for Zone output. If several
  combinations match, each is updated once. All variants share that combination's
  cooldown; the matched saved entry also updates its message-rotation usage.
- `%guild%`, literal guild names, and guild-link IDs remain required. Greetings
  (`%time%`, `%timeofday%`, `%greeting%`) and `%zone%` can vary.
- The existing embedded-time parser/formatter identifies where it inserts a
  countdown. Only recognized countdowns and automatically added AM/PM/timezone
  text can vary there. Original event dates, times, explicit timezones, and other
  parenthesized text stay required. Unannotated originals also match.
- Matching ignores case, whitespace differences, color codes, and link display
  style numbers. It requires the complete fixed wording, without fuzzy substring
  matching. Variable-only templates do not establish a message identity; zone
  substitutions must be recognized zone names, and repeated substitutions must
  agree within a message.
- Zone observations reset the cooldown in your current zone, preserving the
  existing per-zone behavior. Guild/Officer observations apply across zones.
  The added delay survives `/reloadui` and appears in the existing status timers.
- If a matching command/guild message is already waiting in your chat input,
  its unchanged text is withdrawn and its timeout is canceled. Edited text is
  preserved. A canceled startup item releases the startup queue.

See [the testing guide](docs/incoming-chat-testing.md) for installation and
two-player checks. Scheduling is a separate proposal and is not implemented by
this change.

## What's New in 1.5.3
- Added **Populate Sound** at the **Command + Guild** level
- Added a **Preview** button for the selected populate sound
- Limited the sound dropdown to a curated set of useful ESO sounds
- Included **DUEL_START** by default and **None** for silent operation
- Populate sound now plays whenever SmartChatMsg successfully populates a message into chat, including manual slash command starts, Auto Populate Chat on Zone, and Repeat Every
- Auto Populate Chat on Zone now evaluates the current zone on startup and shows a top-right cooldown alert if that zone is still cooling down
- Zone auto populate no longer requires the current zone id to differ from the last seen zone id before it evaluates whether it should fire automation

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
- When the watcher evaluates a parent zone, including on startup and after travel, SmartChatMsg can populate a message for that zone.
- The message is placed into chat input and can then be sent by you.
- Running the command again, or using `off`, turns it off.

Important behavior:
- Auto Populate is stored per **Command + Guild**.
- Turning it on clears **Repeat Every** for that same command/guild.
- Only one active auto-populate command can run at a time.
- The first player activation after login is ignored.
- Zone auto populate evaluates the current parent zone whenever the watcher runs, including on startup.
- On startup, if the current zone is still in cooldown, SmartChatMsg shows a top-right alert telling you when that cooldown ends instead of populating immediately.
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
- The selected sound plays whenever SmartChatMsg populates a message into chat, including manual slash command starts, **Repeat**, and **Auto Populate Chat on Zone**
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
- `/scm schedule` opens settings for the Event Scheduling submenu
- `/scm status` toggles the live cooldown and scheduling status panel
- `/scmdebug` toggles or controls debug logging

## Files
- `SCM_SavedVars.lua`
- `SCM_Settings.lua`
- `SmartChatMsg.lua`

## Event Scheduling

Select a command/guild in Messages Settings, then configure **Event Scheduling
(Eastern Time)**. Save an enabled start/event/end window with Repeat or Zone
delivery, optional phase intervals, and message assignments. Schedules activate
and stop automatically while the game is running. Messages fill the chat box;
press Enter to send. Use `%eventdate%`, `%eventtime%`, and `%eventwhen%` for event
details. `off` pauses a schedule until Resume in settings.

Install all files from the addon manifest, including `SCM_Calendar.lua`,
`SCM_Schedules.lua`, `SCM_Scheduler.lua`, and `SCM_ScheduleSettings.lua`.
See [the scheduling trial instructions](docs/scheduling-testing.md) for setup,
daylight saving behavior, and a short two-player test.
