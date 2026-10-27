# SmartChatMsg (v2.1.0)

**[Open the standalone HTML help guide v2.1.0](SmartChatMsg_Help_Guide_v2.1.0.html)** (included with the addon).

**[Read the complete SmartChatMsg 2.1.0 user guide](docs/SmartChatMsg-2.1.0.md)** for all configuration options, examples, timezone changes, recurrence, message groups, and phase behavior.

**2.1.0:** Adds event reminder timelines, named important times, time-sensitive milestones, the optional Node web editor, preserving helper consolidation and timeline transfer. Long status countdowns include days; Next Send includes the local clock.

**2.0.13:** Adds **All events** to month-final message groups. One message can serve both regular and month-final occurrences in its selected phases. The Group button cycles Regular events → Month-final events → All events; import/export preserves the choice. **After event starts** replaces the Until end phase label and contains **Promote after start (minutes)**: 0 stops at the event start; a positive duration keeps ongoing-event messages eligible afterward. Existing message selections are preserved.

**2.0.12:** Fixes `/scm retry` when chat is already empty at timeout. Ready scheduled reminders enter the queue in random order. Use `/scm send <command> [guild number]` (or `/scm <command> [guild number]`) to request an extra current-phase reminder, overriding its own interval while respecting peer cooldowns and shared pacing. Usage and once-only completion are recorded after a confirmed send.

**2.0.11:** Fixes duplicate MungeOverlay control errors while opening settings. Schedule rows and their templated children now have stable unique names across phase lists, refreshes and message-group changes. Newly relevant settings sections open automatically, including faction rotation, mode timing, repeat options and phase lists; ordinary refreshes preserve manual collapse.

**2.0.10:** `/scm retry` restores the most recent untouched message cleared by the unsent timeout. It keeps the same saved message and channel, recalculates substitutions/countdowns, protects your chat draft, and respects current schedule eligibility and peer cooldowns.

**2.0.9:** Import/export identifies guilds by name and remaps them to the recipient's slots, including the default guild, last-used guild parameters and /g1 or /o1 references in messages. Missing-guild records are skipped with local chat details. New exports use SCM_EXPORT_V2; legacy V1 imports use available guild names rather than assuming the sender's slot order.

**2.0.8:** Adds independent event countdowns and time offsets such as `%eventtime-1h%` and `%eventcountdown-1h%`. Explicit countdowns suppress automatic insertion. Event phase changes start fresh cooldowns while retaining send history and startup/shared pacing.

**2.0.7:** Fixes Scheduling overlapping saved messages on first opening settings. The message editor reserves its full height immediately and stays synchronized as messages change.

**2.0.6:** Assigned phase names are separate preview links: clicking Event day tests Event day, even from a Before event day message row. The links wrap to fit the row.

**2.0.5:** Test messages locally using the normal parser and substitutions. The Test button beside Lock uses the current time; clicking message text in a phase simulates a time inside that phase. Previews include unsaved edits and do not send, change cooldowns, or change phase selections. Event and promotion timing opens automatically when selecting an event configuration.

**2.0.3:** Group (/g) is available as an output channel, including scheduled delivery, incoming cooldown matching, status labels, and settings transfer. The standalone HTML guide now matches the addon version and includes all current scheduling features.

**2.0.2:** Scheduled message views sort by earliest selected phase, ending with unused messages. Live checkbox edits update the order while preserving scroll position and existing sections.

**2.0.1:** Scheduling now includes a **Guild timezone** default shared by all
commands for that guild. Choose ET/CT/MT/PT or **Use global default**. Guild changes
keep existing clock times and affect only that guild; global changes affect only
guilds that inherit the default. Guild choices are included in full export/import.

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
or Event started), its frequency, and the selected-zone end time. The status window
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
shows its readable selected-zone promotion start/end below status. **Next Send** appears only
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
- Configurable ET/CT/MT/PT event windows, automatic activation/stopping, and message phases.
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
| `/scm schedule` | Open settings; expand Create / Edit / Delete Messages, then Scheduling (selected timezone). |
| `/scm status` | Toggle the live status window. |
| `/scm resetcooldowns` | Clear existing cooldowns for testing; preserve schedule dates and paused/off states. |
| `/scmdebug on`, `/scmdebug off`, `/scmdebug status` | Control debugging; `/scmdebug` toggles it. |
| `/recruit 1` | Run your custom command for local guild slot 1. |
| `/recruit 1 off` | Stop ordinary automation, or persistently pause a schedule. |

Guild parameters `1`â€“`5`, `g1`â€“`g5`, and `o1`â€“`o5` resolve the corresponding local
guild slots. For example, `2`, `g2`, and `o2` select the same guild. Set Default
Guild to run without a guild parameter. Select the saved output channel in settings.

**Run At** chooses how a combination starts:

- **On Demand:** run the command to populate a message/start its configured automation.
- **Startup:** the combination enters the startup queue after login/player activation.
- **Scheduled:** save an enabled window in Scheduling. No command is needed
  at its start time. Selecting Scheduled without a valid saved window does nothing.

## Set up a schedule

Select a command, guild, and output channel in Messages Settings, set **Run At** to **Scheduled**, then open
**Scheduling (selected timezone)** inside **Create / Edit / Delete Messages**. Choose what you want to do:

- **Run during a window:** pick a start date/time and stop date/time, choose
  messages, and set how often to prepare one. No event date is required.
- **Remind me at set times:** pick the first date/time and recurrence. Each
  occurrence prepares one message; no separate event or stop date is required.
- **Promote an event:** pick the event date/time, how many days beforehand to
  begin promoting it, and how long after the start to stop.

Dates use a calendar picker; times use your global scheduling timezone (ET by default). Saved schedules reopen
with readable date/time values. Internal timestamps never appear as settings.
The review shows the start, stop, event time (when applicable), and upcoming occurrences. **Save and activate** starts automatically at the scheduled time while you are online; **Save disabled** keeps your setup without running it. Changes remain a draft until saved. The Scheduling section is disabled unless Run At is Scheduled for the selected command and guild.

### Repeat a schedule

Choose once, daily, weekly, every two weeks, monthly on the selected date, or
monthly on the selected weekday (for example, the third Friday). The selected
initial date anchors recurring weeks and months. Weekday selections and the
custom interval under **More repeat options** refine repeated reminders. Timed reminders have a two-minute
eligibility window; overdue offline reminders are skipped. Schedule recurrence is separate from
how often a message is prepared during an active window.

Selected-zone wall-clock times remain consistent across daylight saving changes.
Dates that do not exist in a month and times skipped by the spring clock change
are skipped. Preview the next occurrences to check your choice.

### Choose several messages for each event phase

Expand the message choices and check the variations you want. Each checklist
has a bounded scroll area; use its scrollbar or mouse wheel to see all messages.
Long messages wrap within their own rows. You can assign
several messages to each phase and assign one message to several phases:

- **Before event day:** promotion start until midnight on the selected-zone event day.
- **On event day:** midnight until the event starts.
- **Starting soon (optional):** enable this in Event and promotion timing and
  enter the lead time in minutes (120 means two hours). It takes over from the
  earlier phase at that threshold and runs until the event starts, within the
  promotion window. Select its messages and a Message interval override, such
  as five minutes. It can begin the previous evening for an early-morning event.
- **After event starts:** event start until the post-start duration ends. Set Promote after start (minutes) in this section to 0 to stop exactly at event start, or a positive value such as 120 to promote for two hours afterward. Its interval override controls frequency within that duration.

SmartChatMsg randomly selects from the messages eligible in the current phase,
using its existing message rotation. Each phase can use its own interval; a
phase can also prepare a message once. Missing phase choices do not fall back to
an unrelated phase. Simple windows and timed reminders use one message pool.
With Starting soon enabled, Before event day and On event day end when that
phase begins. Leave it disabled to retain the original three event phases.
Full settings export/import includes its lead time, messages, interval and
once-only option. Existing schedules leave it disabled.

Event templates can include `%eventdate%`, `%eventtime%`, and `%eventwhen%`.
`%eventwhen%` describes the selected-zone calendar day: weekday/date when further away,
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
with an extra random 30â€“90 seconds; they do not resume paused schedules.
The status panel reports engagement, waiting, and the next eligible time in your scheduling timezone.
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
| `%eventdate%` | Configured event's selected-zone date, e.g. `10/16/2026`. |
| `%eventtime%` | Selected-zone time with its standard/daylight abbreviation, e.g. `08:00 PM EDT`. |
| `%eventwhen%` | Today, tomorrow, or weekday/date, using the event's selected-zone date. |

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
and adds a random **30â€“90 seconds** to its cooldown. An active Repeat cycle is
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
phase, selected-zone window boundaries, and next eligible Repeat delivery. Blocking
reasons include busy input, cooldown, an empty phase, or another Zone owner.

For ordinary On Demand/Startup combinations:

- **Repeat Every:** repopulates after the configured minutes following a confirmed send.
- **Retry Delay:** retries an unsubmitted repeated message after timeout; zero/blank
  resumes the normal repeat interval. Explicit retry is capped to Cooldown and may exceed Repeat; lowering Cooldown also clamps saved Retry. No repeat means no automatic retry. Scheduled combinations keep their schedule interval cap.
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
verification. Events recur while you are online; there is no offline posting.

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
Below Repeat schedule, Next event shows the calculated selected-zone date/time without
changing the original recurrence anchor. Windows/reminders use Next window or
Next reminder. After an event starts, Next event shows the following occurrence,
even while the current promotion remains active. One-time events show None
scheduled when no future start remains. This preview reflects unsaved edits.

Promotion days: 0 starts at midnight in your selected timezone on event day. Select On event day
messages; Starting soon and live messages still follow their configured phases.
Positive lead values start that many days before the event at its clock time.
Delivery still honors startup delay, cooldowns, shared spacing and chat availability.

The promotion-days field also shows a short explanation and a calculated
Promotion starts date/time, reflecting unsaved edits and the next event occurrence.

## Faction rotation and month-final events (2.0)

Select the command/guild in Create/Edit/Delete Messages, choose Scheduled, and
open Scheduling. Choose Promote an event and your repeat schedule, then select
the optional Special event pattern. Existing schedules default to None.

For PvP, choose Faction rotation. Open its section and set Faction frequency (weeks)
(default 4), First faction, Second faction, and Third faction using dropdowns.
Second/third can be Not used. Each selected faction must appear only once.
The complete cycle is frequency times the number of selected factions:
two factions at two weeks each repeat every four weeks. The original event date is the first event of
the first faction's block; choose a date that anchors your real rotation.
AD -> EP -> DC with 4 weeks each repeats after 12 calendar weeks, even after
time offline or daylight-saving changes. The schedule still controls event days.
%eventfaction% inserts Aldmeri Dominion, Ebonheart Pact, or Daggerfall Covenant
for the occurrence being promoted; it is independent of your character's faction.
The next-event preview shows the calculated faction.

Each phase's message row has an event-group dropdown. Choose All selected factions to
reuse a template with %eventfaction%, or choose one faction for special wording.
Phase checkboxes and interval overrides still decide when messages are eligible.
Multiple eligible messages are chosen randomly as before.

Choose Last event of month with any repeating event schedule; Every other week
is not required. Add regular and month-final announcements under the same command.
In each message row click the Group button to cycle Regular events, Month-final events, or All events. Unassigned
messages default to Regular events. Select each message's desired promotion phases.
The last scheduled event in each calendar month uses the month-final pool throughout
its promotion. This follows your recurrence, not a fixed weekday or raffle rule.
For example, biweekly events anchored October 10 use regular messages October 10
and month-final messages October 24.
If no messages are marked month-final for this command/guild, regular messages
are used for every event. Once special messages are configured, their phase
selections apply; an intentionally empty special phase does not use regular text.
All events messages join either pool within their selected phases. Use one All events
Starting soon message when the same reminder applies to both kinds of drawing.
Mark only the special messages, once per message; the choice is shared across phases.

Save and activate after reviewing the next events and their faction/group labels.
Pattern settings, order, block length and message groups are included in settings
export/import. Local locked messages keep their personal group and phase choices.
Incoming matching resolves %eventfaction% to the expected occurrence's faction.
Changing to a window/non-repeating schedule turns the special pattern off.

## Version 2.1.0 event timelines

One scheduled event can now contain multiple reminder periods and time-sensitive milestones, each with its own frequency and random message pool. Actual event dates remain separate from promotion timing. Existing schedules continue working until explicitly converted.

Named important times support cutoff date/day/time/countdown substitutions. Matching accepts recognized changing countdowns and recent midnight wording without treating arbitrary dates as wildcards.

The separate [SmartChatMsg-Web](https://github.com/skperdue68/SmartChatMsg-Web) Node application offers the same event structure plus a week/month overview and cooldown-preserving SavedVariables editing. Both addon and web editor retain full scheduling. Read the HTML guide for migration and installation details.

Status cards show days in long countdowns, compact promotion details and local-clock Next Send estimates. Equally eligible queued automatic reminders randomize their order without starving older queued work.


### Rotating events and cancelled occurrences

Choose **Rotating event** under Special event pattern for a repeating Promote an event schedule. Add 1–50 named activities, order them with Move activity up/down, and set Occurrences per activity (1–1000). Each activity has a stable ID; renaming or moving it preserves message assignments. Use `%eventactivity%` in templates and choose All activities or a specific activity in each message row. The rotation runs from the original Event date even while offline and works with reminder timelines.

In **Occurrence cancellations**, select a nominal occurrence and choose **Keep rotation** or **Postpone rotation**, then save. Both suppress that occurrence's reminders, queued requests and manual sends. Keep advances the rotation as usual; Postpone holds one nominal slot. For faction rotations, Postpone holds the schedule-zone civil-day span from that occurrence to its next nominal occurrence before applying the existing calendar-week blocks. A biweekly cancellation therefore holds two weeks; a monthly cancellation holds its actual month span. Dates outside the repeat cadence never advance or hold either rotation. DST does not change the civil-day calculation.

Upcoming dates show the projected activity/faction and cancellation state. Saved cancellations remain available for Undo, including after changing patterns; Undo removes the exception without changing the recurrence anchor. Cancellation changes take effect on Save; an untouched prepared chat message is withdrawn and player-edited text is preserved. There is no automatic cancellation announcement.

SavedVariables contain `specialPattern="EVENT_ROTATION"`, `rotationEvents={{id="stable-id",name="Activity"},...}`, `rotationEvery=1`, and `occurrenceExceptions={["YYYY-MM-DD"]={action="KEEP" or "POSTPONE"}}`. These are configuration, work entirely offline, and survive full import/export; message IDs and locally locked group assignments remain intact. Text backups add `SCHEDULEEVENTROTATION_V1`, ordered `SCHEDULEACTIVITY_V1`, and `SCHEDULEEXCEPTION_V1` records. Invalid counts, dates, actions, duplicate IDs and missing activity references are rejected.


The addon also caches your current guild memberships (display names, ESO guild IDs and slot numbers) in SavedVariables, even before you create any commands or messages. The web editor can use this roster to populate guild choices. Login/player activation refreshes the cache, while incomplete startup API responses preserve the last valid snapshot. Exit ESO to flush the latest roster to disk before opening the SavedVariables file in the web editor. Membership metadata stays with the recipient account and is excluded from portable text settings exports.


For monthly weekday schedules, choose **Repeat schedule -> Monthly on weekday**, then **Monthly on -> Last** and **Weekday -> Sunday** (or any other weekday). First, Second, Third, Fourth and Fifth are also available. Last runs in every month, including months with four or five Sundays; Fifth skips months without that fifth weekday. The Event date anchors the first eligible date and starting month; the custom repeat interval still counts months. Existing schedules retain their anchored ordinal weekday until changed. Same day each month continues to repeat by calendar date. These choices are saved as `monthlyWeek` (1-5 or `"LAST"`) and `monthlyWeekday` (Sunday=1 through Saturday=7), and survive SavedVariables and full text import/export through `SCHEDULEMONTHLY_V1` records.


### Reminder availability and daily limits

In a reminder timeline, select a reminder and open **Reminder availability**. Enable **Limit reminder availability**, choose the allowed weekdays, enter usual hours as `HH:MM` (24-hour clock), and optionally set **Maximum announcements per server day** from 1 to 1000. Blank means unlimited. Use `00:00` to `24:00` for all day; an end earlier than the start continues into the next day. These limits narrow the reminder's overall promotion period. Time-sensitive and manual requests obey them. **Prepare only once** still means once per event occurrence; use a repeating reminder with a daily maximum for daily announcements.

Choose an override weekday or opening date and edit its hours. Date overrides take priority over weekday overrides, then usual hours. A new date override inherits that weekday's current hours. **Reset selected date hours** or **Reset selected weekday hours** removes only that override, preserving other settings and counters. Excluded weekdays stay excluded. An overnight override belongs to the date its window opens, including the continuation after midnight.

Hours and calendar-day counters use the schedule's guild/server scheduling timezone, including daylight saving. A full day can last 23 or 25 hours. A nonexistent spring clock skips that slice; repeated fall clocks use the first start and second end. The daily maximum counts the actual calendar day on which an announcement is sent or observed, even for an overnight window. Confirmed sends and relevant matching peer messages count, including while this client is paused or outside allowed hours within the overall promotion period. Preparing chat, timeout and retry do not count. You still press Enter to send.

Daily counts persist in SavedVariables and survive hours edits, override resets and full Lua saves. Portable text settings exports include availability configuration and overrides, but not another player's daily counters; importing preserves the recipient's matching reminder counters and existing recipient history. The explicit reset-all-cooldowns command clears daily counters too. Advanced calendar editing is available at [scm.perdues.me](https://scm.perdues.me).
