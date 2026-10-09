# SmartChatMsg (v1.11.8)

SmartChatMsg is an Elder Scrolls Online addon for reusable chat messages: guild
recruitment, trial reminders, auctions, officer notices, and other announcements.
Create a slash command, save message variations for a guild, and choose Zone,
Guild, or Officer output.

**SmartChatMsg fills the chat box; you still press Enter to send.** Automation
runs while ESO and the addon are running. It does not silently send messages.

On each addon load or UI reload, SmartChatMsg announces that it is running and
holds **scheduled** messages for **3 minutes**. Ordinary On Demand commands and
the separate Startup queue keep their existing behavior. After you send a
scheduled message, every other Command + Guild schedule waits **5 minutes**;
the sender keeps its own configured repeat interval. These pauses apply to
Repeat and On zone arrival schedules, including manual requests for scheduled
commands. They do not change event dates or saved intervals, and an unsent
message timing out does not start the shared pause.

Startup, schedule starts/ends, phase changes, and cooldown notices appear locally
in chat through `CHAT_SYSTEM:AddMessage`; they are never sent to your guild.
Phase notices name the new period (Before event day, Event day, Starting soon,
or Event started), its frequency, and the Eastern end time. The status window
shows startup/shared pauses and distinguishes a prepared message awaiting Enter
from protected player text. More than one schedule may be active, but they share
one chat input and only eligible current-phase messages are prepared.

The actionable status cards show scheduled commands **only during their current
window**. Their button cycles **Disabled -> Enabled -> Paused -> Disabled**, displaying
the next action: Enable, Pause, or Disable. On/Paused/Off uses the saved schedule
state, so a paused schedule cannot be accidentally reactivated by the next tick.
While On, the status includes the current wait: startup, cooldown, shared pause,
zone arrival, or a message ready for Enter. Pausing or switching Off withdraws
untouched generated text while preserving player edits. Larger cards keep all
four lines inside their border. Ordinary repeat cards use the same toggle cycle;
their pause state lasts for the current session, like their ordinary automation.

Click **Auto** or **Repeat Commands** to collapse/expand that section. Empty
sections collapse automatically; newly available content opens them. Your manual
collapse choice stays respected while the same content remains available. Auto
contains zone tracking, while Repeat Commands contains current schedule cards and
running/paused ordinary repeats. Upcoming schedules remain in settings rather
than duplicating all their details above the cards. Each current scheduled card
shows its readable ET promotion start/end below status. **Next Send** appears only
while the card is Active. Enable/Pause/Disable use ESO's textured button style,
and the cards reserve scrollbar space and fit above the main window's bottom edge.

Schedule-only message groups retain their saved names and IDs for configuration,
but no longer register slash commands. They run through their schedules and card
controls. If the same name also has an On Demand or Startup guild configuration,
its slash command remains available for that combination. Ordinary repeats are
started by their slash command; inactive ordinary entries are not listed in the
running-repeat section. Previously a scheduled slash request could do nothing
visible because it still honored the schedule's startup/cooldown limits.

For messages containing **`%eventtime%`**, the countdown now uses the current
scheduled occurrence's UTC event timestamp directly. It does not infer an event
date from a standalone clock time. This fixes the extra-day countdown after UTC
midnight while it is still the prior evening in Eastern Time. The normal embedded
time parser remains in use for messages without that event token.

For testing, **`/scm resetcooldowns`** clears command/guild usage cooldowns, observed
peer cooldowns, per-zone cooldowns, retry deadlines, once-per-occurrence markers,
and the shared five-minute pause. Enabled schedules in their current window can
prepare another message. It keeps templates, message rotation counts, event
dates, intervals, and On/Paused/Off state. It does **not** bypass the three-minute
startup wait or run schedules outside their window. This deliberately forgets
cooldown usage history, so Last Sent can read Never afterward.

Every scheduled preparation now announces **Press Enter to send** and its chat
timeout. If it is not sent before that timeout, a local notice explains the next
attempt time; this interval is a retry wait, not evidence of a successful send.

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
| `/scm schedule` | Open settings; expand Create / Edit / Delete Messages, then Scheduling (Eastern Time). |
| `/scm status` | Toggle the live status window. |
| `/scm resetcooldowns` | Clear existing cooldowns for testing; preserve schedule dates and paused/off states. |
| `/scmdebug on`, `/scmdebug off`, `/scmdebug status` | Control debugging; `/scmdebug` toggles it. |
| `/recruit 1` | Run your custom command for local guild slot 1. |
| `/recruit 1 off` | Stop ordinary automation, or persistently pause a schedule. |

Guild parameters `1`–`5`, `g1`–`g5`, and `o1`–`o5` resolve the corresponding local
guild slots. For example, `2`, `g2`, and `o2` select the same guild. Set Default
Guild to run without a guild parameter. Select the saved output channel in settings.

**Run At** chooses how a combination starts:

- **On Demand:** run the command to populate a message/start its configured automation.
- **Startup:** the combination enters the startup queue after login/player activation.
- **Scheduled:** save an enabled window in Scheduling. No command is needed
  at its start time. Selecting Scheduled without a valid saved window does nothing.

## Set up a schedule

Select a command, guild, and output channel in Messages Settings, set **Run At** to **Scheduled**, then open
**Scheduling (Eastern Time)** inside **Create / Edit / Delete Messages**. Choose what you want to do:

- **Run during a window:** pick a start date/time and stop date/time, choose
  messages, and set how often to prepare one. No event date is required.
- **Remind me at set times:** pick the first date/time and recurrence. Each
  occurrence prepares one message; no separate event or stop date is required.
- **Promote an event:** pick the event date/time, how many days beforehand to
  begin promoting it, and how long after the start to stop.

Dates use a calendar picker; times use Eastern Time (ET). Saved schedules reopen
with readable date/time values. Internal timestamps never appear as settings.
The review shows the start, stop, event time (when applicable), and upcoming occurrences. **Save and activate** starts automatically at the scheduled time while you are online; **Save disabled** keeps your setup without running it. Changes remain a draft until saved. The Scheduling section is disabled unless Run At is Scheduled for the selected command and guild.

### Repeat a schedule

Choose once, daily, weekly, every two weeks, monthly on the selected date, or
monthly on the selected weekday (for example, the third Friday). The selected
initial date anchors recurring weeks and months. Weekday selections and the
custom interval under **More repeat options** refine repeated reminders. Timed reminders have a two-minute
eligibility window; overdue offline reminders are skipped. Schedule recurrence is separate from
how often a message is prepared during an active window.

Eastern wall-clock times remain consistent across daylight saving changes.
Dates that do not exist in a month and times skipped by the spring clock change
are skipped. Preview the next occurrences to check your choice.

### Choose several messages for each event phase

Expand the message choices and check the variations you want. Each checklist
has a bounded scroll area; use its scrollbar or mouse wheel to see all messages.
Long messages wrap within their own rows. You can assign
several messages to each phase and assign one message to several phases:

- **Before event day:** promotion start until midnight on the Eastern event day.
- **On event day:** midnight until the event starts.
- **Starting soon (optional):** enable this in Event and promotion timing and
  enter the lead time in minutes (120 means two hours). It takes over from the
  earlier phase at that threshold and runs until the event starts, within the
  promotion window. Select its messages and a Message interval override, such
  as five minutes. It can begin the previous evening for an early-morning event.
- **From event start until promotion ends:** event start until promotion ends.

SmartChatMsg randomly selects from the messages eligible in the current phase,
using its existing message rotation. Each phase can use its own interval; a
phase can also prepare a message once. Missing phase choices do not fall back to
an unrelated phase. Simple windows and timed reminders use one message pool.
With Starting soon enabled, Before event day and On event day end when that
phase begins. Leave it disabled to retain the original three event phases.
Full settings export/import includes its lead time, messages, interval and
once-only option. Existing schedules leave it disabled.

Event templates can include `%eventdate%`, `%eventtime%`, and `%eventwhen%`.
`%eventwhen%` describes the Eastern calendar day: weekday/date when further away,
tomorrow the day before, and today throughout the event day (including after
the start). It does not change to hours/minutes or "already started". Countdown
annotations and phase-specific message wording provide those details.
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

## Settings backup and restore

**Import / Export Settings** includes commands, messages, channels, behavior,
schedule dates/times, intervals, phase assignments, pauses, and general settings.
Import replaces addon settings and unlocked messages after confirmation; local
locked messages survive while their command remains. The separate Share Messages
settings panel has been removed.

### Customize an imported schedule

Full settings export includes event dates/times and message-phase assignments.
After import, select the command/guild, edit its window and intervals in Event
Scheduling, change phase checkboxes, and **Save and activate**. Edits affect only your
own copy. For example, keep Friday's event start but begin your reminders later.

Full import replaces all settings and may import enabled schedules; review them
before copying another player's setup.

## Testing and limitations

- [Short-window scheduling and two-player trial](docs/scheduling-testing.md).
- [Incoming-message coordination checks](docs/incoming-chat-testing.md).

Automated checks cover calendar/DST rules, boundaries, queues, edited input,
coordination, persistence, sharing, and settings callbacks. Actual ESO UI layout,
loading screens, channel restoration, and two-player operation still need in-game
verification. There is no recurring event scheduler or offline posting.

### Message list and command identity (1.11.8)

Repeat cards show (Scheduled), (On Demand), or (Startup). Scheduled cards show
the countdown to the current occurrence's event time, changing to Started at
that time. Window/reminder schedules use their activation time.

Schedule message pools place each checkbox and complete wrapped message inside
a bordered row. Used lists its selected promotion phases; Before event day may
cover multiple days, based on your promotion lead time. Starting soon appears
only when that phase is enabled. Saved message editor rows also show the phases.

On Demand messages can use countdowns from supported literal dates/times.
%eventdate%, %eventtime%, and %eventwhen% need a saved event configuration for
the command/guild; without one the tokens remain unchanged. An On Demand repeat
interval does not itself supply an event date/time.

### Personal messages and complete settings exports (1.11.8)

Use **Lock** beside a saved message to keep it personal. **Unlock** includes it
in the next export. A Locked caption also appears in schedule message pools.
Locking affects transfer only: sending, editing, deletion, and incoming matching
continue normally. A lock is per message, not per command.

Exports omit locked message text and its phase-assignment records. Imports keep
local locked messages, usage and phase assignments when the parent command
survives by ID, or by the same name ignoring case if its ID changed. A matching
imported message ID cannot overwrite a local lock. If the command is gone after
import, its locked messages are removed too. Imported schedule dates and other
settings still apply; locking a message does not lock its command settings.

Export/import includes Run At, Open Status Panel on Run, Notify Sound, repeat,
retry and cooldown settings, channels, schedules, phase intervals/assignments,
and status window saved visibility/position. Old exports without window-state
records retain your current window preferences. Runtime queues/timers and the
editor's current selection are not transferred.

Changing Run At updates slash registration immediately. A scheduled-only name
has no slash command; an On Demand or Startup combination restores it. Names
shared with another ordinary guild configuration remain registered.

### Status controls and matching (1.11.8)

The button always shows the next action: Enable makes the command active; Pause
stops delivery while keeping it paused; Disable switches it off. The next click
on a disabled current schedule enables it directly, without an intermediate pause.
Ordinary repeats retain their existing visibility rules: after disabling they
leave the running list and can be restarted using their slash command.

Incoming matching normalizes capitalization, whitespace, chat colors and supported
link presentation. Template substitutions and generated countdowns are recognized
at their proper positions. Fixed wording/punctuation and channel/guild identity
remain required. Arbitrary typo/wording fuzzy matching is not enabled.

Import tests verify that a same-name command with a different imported ID maps
locked messages to the new command while preserving local phase assignments and
the imported channel and schedule. Old command/guild keys do not remain.

NEXT OCCURRENCE DISPLAY (1.11.8)
Below Repeat schedule, Next event shows the calculated Eastern date/time without
changing the original recurrence anchor. Windows/reminders use Next window or
Next reminder. After an event starts, Next event shows the following occurrence,
even while the current promotion remains active. One-time events show None
scheduled when no future start remains. This preview reflects unsaved edits.

Promotion days: 0 starts at midnight Eastern on event day. Select On event day
messages; Starting soon and live messages still follow their configured phases.
Positive lead values start that many days before the event at its clock time.
Delivery still honors startup delay, cooldowns, shared spacing and chat availability.
