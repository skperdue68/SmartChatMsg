# SmartChatMsg (v1.10.0)

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

Keep **LibAddonMenu-2.0** installed. Copy the complete addon release/branch into
your SmartChatMsg addon folder, including every file listed in `SmartChatMsg.txt`.
Copying only the main Lua file misses the scheduling and sharing modules.
Reload the UI after updating. Export your settings before trying a new setup.

The runtime files are `SCM_MessageSharing.lua`, `SCM_SavedVars.lua`,
`SCM_Calendar.lua`, `SCM_Schedules.lua`, `SCM_Scheduler.lua`,
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

## Schedule an event

You need **one command and one schedule per event**, rather than separate commands
for the day before, event day, and event start.

1. Create `/trial`, select its guild/channel, and save its message variations.
2. Open **Event Scheduling (Eastern Time)**. Check the displayed command/guild.
3. Check **Enable scheduled window** and choose **REPEAT** or **ZONE** delivery.
4. Enter three dates/times: **start** for reminders, **event** for the event itself,
   and **end** for when reminders stop.
5. Set the default interval in whole minutes. Optional BEFORE, DAY, and LIVE
   overrides use their own interval; blank overrides inherit the default.
6. Assign messages to phases, then click **Save schedule**.

Dates use `YYYY-MM-DD`; times use `HH:MM AM/PM`. Start must be at or before the
event, and end must be after it. Invalid drafts do not replace saved schedules.
Start is inclusive; end is exclusive.

### Message phases

Use **Message number to assign** to select a message from the displayed numbered
list, then check its allowed phases. Save the schedule to apply your edits.

| Phase | When eligible | Friday 8 PM trial example |
| --- | --- | --- |
| ANY | Anywhere inside the reminder window | “Ask an officer about joining our trial.” |
| BEFORE | Before midnight on the event's Eastern calendar day | “Our Friday trial is coming up!” |
| DAY | Event-day midnight until event start | “Our trial is tonight at 8 PM!” |
| LIVE | Event start until reminder end | “Our trial is underway!” |

Unassigned messages default to ANY. Uncheck ANY to restrict a message to other
phases. Multiple boxes may be checked; unchecking every box excludes the message.
Several messages can share a phase; the addon rotates among currently eligible
messages. An empty phase waits instead of borrowing messages from another phase.

BEFORE means before the event day, not specifically the preceding 24 hours. DAY
covers the whole event day before the start. There is no separate “30 minutes
before start” phase or arbitrary per-message time window in this implementation.

### Example and simultaneous events

For a Friday 8 PM trial, start reminders Thursday at noon and stop Friday at
9 PM. Set the default interval to 60 minutes, DAY to 30, and LIVE to 10. The addon
automatically changes phase as those boundaries pass.

To promote a Saturday auction at the same time, create `/auction` with its own
window for the same guild. Both REPEAT schedules can run together with independent
cooldowns. Each command/guild has one event window. Only one enabled scheduled
ZONE combination is supported; it waits for an existing manual Zone owner to
stop before taking ownership. Weekly recurrence is not included.

### Automatic start, stop, and pause

- Log in before start: it waits, then engages at start.
- Log in inside the window: it engages using the current phase, without replaying
  missed offline reminders.
- At end: it stops creating reminders and withdraws untouched scheduled text
  still pending in chat. Player-edited text is preserved.
- Log in after end: it stays finished.
- `/trial 1 off` or **Pause saved schedule** persists a pause through UI reloads.
  Use **Resume saved schedule** to resume within the window.

REPEAT starts its next interval after a confirmed send. An unsubmitted reminder
uses the restore timeout, then the effective Retry Delay or schedule interval.
ZONE uses eligible zone arrivals and the interval as its per-zone cooldown;
existing zone exclusions remain in effect.

Busy chat input waits rather than being replaced. Manual requests take priority
over Startup requests, then scheduled requests. Queued scheduled work is checked
again against its window, phase, guild, and Zone eligibility before delivery.

### Eastern Time

**All schedule times use ET, independently of your computer timezone.** The addon
converts dates to fixed timestamps using US Eastern daylight saving rules:
EST is UTC−5 and EDT is UTC−4. Supported dates are 2007–2099. Correct clock time
is still needed; conversion does not require identifying your computer timezone.

Missing spring clock-change times are rejected. During the repeated November
hour, choose EDT for the first occurrence or EST for the second using that
timestamp's **repeated-hour choice**. Leave Automatic for ordinary times.

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
