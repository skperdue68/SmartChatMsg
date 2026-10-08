# SmartChatMsg (v1.11.0)

SmartChatMsg is an Elder Scrolls Online addon for reusable chat messages: guild
recruitment, trial reminders, auctions, officer notices, and other announcements.
Create a slash command, save message variations for a guild, and choose Zone,
Guild, or Officer output.

**SmartChatMsg fills the chat box; you still press Enter to send.** Automation
runs while ESO and the addon are running. It does not silently send messages.

## Current features

- Custom commands with separate settings/cooldowns for each **Command + Guild**.
- Multiple message variants; rotation favors less recently/frequently used messages.
- On Demand, Startup, and Scheduled operation; Repeat and Zone-based delivery.
- Eastern Time event windows, automatic activation/stopping, and message phases.
- Coordination with other players' matching messages to avoid duplicate announcements.
- Message-only sharing that merges templates without replacing personal settings.
- Full settings backup/restore, including schedule configuration.
- Optional live status window, populate sounds, and chat channel restoration.

## Install or update

Install **LibAddonMenu-2.0 (release 34 or newer)** and **LibAddonMenuDatePicker**.
The DatePicker dependency adds the calendar selector used by scheduling. Copy the complete addon release/branch into
your SmartChatMsg addon folder, including every file listed in `SmartChatMsg.txt`.
Copying only the main Lua file misses the scheduling and sharing modules.
Reload the UI after updating. Export your settings before trying a new setup.

The runtime files are `SCM_MessageSharing.lua`, `SCM_SavedVars.lua`,
`SCM_Calendar.lua`, `SCM_Recurrence.lua`, `SCM_Schedules.lua`, `SCM_Scheduler.lua`,
`SCM_ScheduleSettings.lua`, `SCM_StatusPanel.lua`, `SCM_Settings.lua`, `SCM_IncomingChat.lua`, and
`SmartChatMsg.lua`, loaded by `SmartChatMsg.txt`.

## First setup and commands

1. Open `/scm` and create a command, such as `recruit`; it becomes `/recruit`.
2. In Messages settings, select that command and your guild.
3. Select Zone, Guild, or Officer output and save your message templates.
4. Choose the desired behavior. For a manual message, use `/recruit 1`, where
   `1` is that guild's slot in your own guild list.

| Command | Purpose |
| --- | --- |
| `/scm` | Open settings. |
| `/scm schedule` | Open settings; expand Event Scheduling (Eastern Time). |
| `/scm status` | Toggle the live status window. |
| `/scmdebug on`, `/scmdebug off`, `/scmdebug status` | Control debugging; `/scmdebug` toggles it. |
| `/recruit 1` | Run your custom command for local guild slot 1. |
| `/recruit 1 off` | Stop ordinary automation, or persistently pause a schedule. |

Guild parameters `1`–`5`, `g1`–`g5`, and `o1`–`o5` resolve the corresponding local
guild slots. For example, `2`, `g2`, and `o2` select the same guild. Set Default
Guild to run without a guild parameter. Select the saved output channel in settings.

**Run At** chooses how a combination starts:

- **On Demand:** run the command to populate a message/start its configured automation.
- **Startup:** the combination enters the startup queue after login/player activation.
- **Scheduled:** save an enabled window in Event Scheduling. No command is needed
  at its start time. Selecting Scheduled without a valid saved window does nothing.

## Set up a schedule

Select a command, guild, and output channel in Messages Settings, then open
**Event Scheduling (Eastern Time)**. Choose what you want to do:

- **Run during a window:** pick a start date/time and stop date/time, choose
  messages, and set how often to prepare one. No event date is required.
- **Remind me at set times:** pick the first date/time and recurrence. Each
  occurrence prepares one message; no separate event or stop date is required.
- **Promote an event:** pick the event date/time, how many days beforehand to
  begin promoting it, and how long after the start to stop.

Dates use a calendar picker; times use Eastern Time (ET). Saved schedules reopen
with readable date/time values. Internal timestamps never appear as settings.
The preview shows upcoming occurrences before you save. Enable the schedule and
click **Save schedule** to activate it; changes remain a draft until saved.

### Repeat a schedule

Choose once, daily, weekly, every two weeks, monthly on the selected date, or
monthly on the selected weekday (for example, the third Friday). The selected
initial date anchors recurring weeks and months. Weekday selections and the
custom interval refine repeated reminders. Timed reminders have a two-minute
eligibility window; overdue offline reminders are skipped. Schedule recurrence is separate from
how often a message is prepared during an active window.

Eastern wall-clock times remain consistent across daylight saving changes.
Dates that do not exist in a month and times skipped by the spring clock change
are skipped. Preview the next occurrences to check your choice.

### Choose several messages for each event phase

Expand the message choices and check the variations you want. You can assign
several messages to each phase and assign one message to several phases:

- **Before event day:** promotion start until midnight on the Eastern event day.
- **On event day:** midnight until the event starts.
- **When the event starts:** event start until promotion ends.

SmartChatMsg randomly selects from the messages eligible in the current phase,
using its existing message rotation. Each phase can use its own interval; a
phase can also prepare a message once. Missing phase choices do not fall back to
an unrelated phase. Simple windows and timed reminders use one message pool.

Event templates can include `%eventdate%`, `%eventtime%`, and `%eventwhen%`.
They refer to the current occurrence of a recurring event. Example:
`%guild% trial %eventwhen%, %eventdate% at %eventtime%.`

### Start, stop, and multiple promotions

Enabled schedules engage automatically while ESO is running and stop at their
window end. Logging in late uses the current occurrence rather than replaying
missed reminders. SmartChatMsg fills chat; you still press Enter to send.

Use separate commands for independent promotions. Multiple Repeat schedules can
run together, sharing the chat box without replacing typed text. Only one Zone
automation can own zone arrivals at a time. Zone output is also available with
scheduled interval delivery.

Pause/resume in scheduling settings. `/yourcommand 1 off` pauses that guild's
schedule until resumed. Peer messages reset the matching command/guild cooldown
with an extra random 30–90 seconds; they do not resume paused schedules.
The status panel reports engagement, waiting, and the next eligible time in ET.
Local notifications announce schedule starts/ends and cooldown delays once per
change. These notices are visible only to you. Matching peer messages are
recorded even while a command is inactive, and later activation honors that
recorded cooldown.

## Message substitutions and countdowns

| Token | Result |
| --- | --- |
| `%guild%` | Resolved guild name. |
| `%zone%` | Your current zone name. |
| `%time%`, `%timeofday%`, `%greeting%` | Morning, afternoon, or evening. |
| `%eventdate%` | Configured event's Eastern date, e.g. `10/16/2026`. |
| `%eventtime%` | Eastern time with EDT/EST, e.g. `08:00 PM EDT`. |
| `%eventwhen%` | Today, tomorrow, or weekday/date, using the event's Eastern date. |

Tokens are case-insensitive and resolved when chat is populated. Event tokens
require a configured event. Example:

```
%guild% trial %eventwhen%, %eventdate% at %eventtime%. Ask an officer to join!
```

The embedded-time formatter can recognize ordinary event date/time text and add
a countdown. Countdown formatting changes message text; the saved scheduling
window controls when the command can run. Include event dates/times to help
distinguish your announcements from different events.

## Incoming duplicate coordination

The other player does not need SmartChatMsg. Their matching Zone, Guild, or
Officer message records usage for your entire **Command + Guild** combination
and adds a random **30–90 seconds** to its cooldown. An active Repeat cycle is
deferred. Your own messages and customer-service messages are excluded.

Guild/Officer matching uses the actual receiving guild and configured channel,
independently of local slot order. Zone chat checks all Zone combinations and
updates each match once. Zone observations apply to the current zone;
Guild/Officer observations apply across zones.

The complete fixed wording and guild identity must match. Greetings, known zone
substitutions, and recognized generated countdown additions may differ. Original
event dates/times and explicit timezones remain required; schedule event tokens
retain the configured event identity. Case, spacing, colors, and link display
style are normalized. Similar wording/substrings and variable-only templates
do not establish message identity.

Untouched pending duplicates withdraw; edited text remains. Peer matches cannot
activate stopped automation, unpause schedules, or extend their end time.
The extra cooldown delay survives UI reloads.

## Status and ordinary automation

Open `/scm status` for Zone cooldowns and scheduled commands. Schedules show
WAITING, RUNNING, PAUSED, or FINISHED (or disabled/configuration states), current
phase, Eastern window boundaries, and next eligible Repeat delivery. Blocking
reasons include busy input, cooldown, an empty phase, or another Zone owner.

For ordinary On Demand/Startup combinations:

- **Repeat Every:** repopulates after the configured minutes following a confirmed send.
- **Retry Delay:** retries an unsubmitted repeated message after timeout; zero/blank
  resumes the normal repeat interval. Effective retry is capped to Repeat.
- **Auto Populate Chat on Zone:** uses eligible parent-zone evaluations instead
  of Repeat. Only one Zone owner can be active; per-zone cooldown defaults to 60 minutes.
- **Populate Sound:** defaults to DUEL_START; None is silent. Preview tests the sound.

Repeat and ordinary Zone auto populate are alternatives for a combination.
Scheduled combinations use the schedule's delivery mode and intervals instead.
The global pending-chat timeout defaults to 60 seconds, with a minimum of 30.
The prior channel is restored after a confirmed send. At timeout, restoration
and clearing occur only while pending text is unchanged; player edits survive.

## Export/import and sharing

| Option | Includes | Effect of import |
| --- | --- | --- |
| Import / Export Settings | Commands, messages, channels, behavior, schedule dates/times, intervals, phase assignments, pauses, and general settings | Replaces addon settings after confirmation. |
| Share Messages | Raw templates for the selected command/guild/channel | Adds missing templates, skips exact duplicates, and preserves existing messages/settings/usage. |

### Share templates with another player

1. Select your command, guild, and output channel in Messages settings.
2. Open **Share Messages**, click **Export Messages**, and copy the generated text.
3. The recipient selects their destination command and the same guild/channel.
   Command names can differ; the guild can occupy a different local slot.
4. They paste into **Shared message text** and click **Import Messages (merge)**.

The complete payload is validated before messages are added. Sharing does not
copy/activate schedules, change channels, or reset personal cooldowns. Imported
templates immediately participate in incoming matching. Event-token users must
configure the matching event separately. New scheduled templates use ANY until
the recipient assigns their phases.

### Customize an imported schedule

Full settings export includes event dates/times and message-phase assignments.
After import, select the command/guild, edit its window and intervals in Event
Scheduling, change phase checkboxes, and **Save schedule**. Edits affect only your
own copy. For example, keep Friday's event start but begin your reminders later.

Full import replaces all settings and may import enabled schedules; review them
before copying another player's setup. Message-only sharing uses a separate
format and cannot be mistaken for a full settings backup by full import.

## Testing and limitations

- [Short-window scheduling and two-player trial](docs/scheduling-testing.md).
- [Incoming-message coordination checks](docs/incoming-chat-testing.md).
- [Message-sharing checks](docs/message-sharing-testing.md).

Automated checks cover calendar/DST rules, boundaries, queues, edited input,
coordination, persistence, sharing, and settings callbacks. Actual ESO UI layout,
loading screens, channel restoration, and two-player operation still need in-game
verification. There is no recurring event scheduler or offline posting.
