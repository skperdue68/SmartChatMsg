SmartChatMsg 1.11.7 — quick user guide

Store reusable recruitment, trial, auction and other announcements. SmartChatMsg
fills your chat box; you still press Enter to send. See README.md for the full guide.

SCHEDULE STARTUP AND SPACING
At login/UI reload, a local chat message confirms SmartChatMsg is running.
Scheduled messages wait 3 minutes before preparing chat. After you send one,
other Command + Guild schedules wait 5 minutes; its own repeat interval is kept.
Unsent messages timing out do not start this shared pause. Ordinary On Demand
commands and the separate Startup queue keep their existing behavior.
Starts, ends, phase changes and cooldown notices appear locally in chat.
Phase changes explain the new period and frequency; times are shown in ET.
The status window distinguishes a message ready for Enter from protected player
text, startup delay and the shared pause. Full current settings help: README.md.

STATUS CONTROLS AND TESTING
Click Auto or Repeat Commands to expand/collapse; empty sections collapse.
Promotion start/end dates appear inside current scheduled cards. Next Send only
appears while Active. Controls use textured ESO buttons, with space for scrollbars.
Schedule-only names do not create slash commands; On Demand/Startup names still
do. Ordinary repeats start by slash command and appear while running or paused.
Scheduled %eventtime% countdowns use the saved occurrence timestamp directly,
fixing an extra day caused by UTC midnight during the previous Eastern evening.
Cards show scheduled commands only within their current window. Buttons cycle
Disabled -> Enabled -> Paused -> Disabled and show the next action. Paused/Off stops
delivery without losing templates or dates, and protects edited chat. All four
card lines fit within the border.
/scm resetcooldowns clears existing cooldowns and retry/once markers for testing.
Dates, intervals, paused/off states and the 3-minute startup wait are preserved.
An enabled current schedule may prepare a message immediately. Prepared messages
and unsent timeouts now announce themselves in local chat.

SETUP AND COMMANDS
Open /scm. Create a command, select it and a guild in Messages settings, choose
Zone/Guild/Officer output, and save message variations. Each Command + Guild has
its own settings/cooldown. /trial 1 targets local guild slot 1; parameters 1–5,
g1–g5 and o1–o5 resolve the corresponding slots. Set Default Guild to omit a slot.

/scm schedule opens settings; expand Event Scheduling (Eastern Time).
/scm status toggles the live status window.
/scmdebug on/off/status controls debugging; /scmdebug toggles it.
/trial 1 off stops ordinary automation or persistently pauses that schedule.

SCHEDULE AN EVENT
One command/schedule holds all stages of one event. Select the command/guild,
open Event Scheduling, enable the window, choose REPEAT or ZONE, and enter
reminder start, event start, and reminder end. Set a default interval in whole
minutes and optional phase overrides. Select a displayed message number, check
its phases, and Save schedule. Invalid drafts leave the saved schedule unchanged.

Dates: YYYY-MM-DD. Times: HH:MM AM/PM, always Eastern Time. Start must be at/before
the event and end after it. ET conversion uses EST/EDT rules for the entered date
(2007–2099), independently of your computer timezone. Missing spring times are
rejected; repeated November times require EDT (first) or EST (second).

ANY:    Anywhere inside the window.
BEFORE: Before the event's Eastern calendar day.
DAY:    Event-day midnight until event start.
LIVE:   Event start until reminder end.

Unassigned messages default to ANY. Uncheck ANY to restrict a message. Several
messages can share a phase; uncheck every phase to exclude one. Empty phases wait.
BEFORE is not a fixed preceding 24 hours; there is no separate “30 minutes before”
phase. Example: Friday 8 PM trial, reminders Thursday noon to Friday 9 PM, default
interval 60 minutes, DAY 30, LIVE 10. The addon changes phases automatically.

Use separate commands, such as /trial and /auction, for simultaneous events in
one guild. Their REPEAT schedules/cooldowns are independent. Each command/guild
has one event window; only one enabled scheduled ZONE combination is supported.

START, STOP AND STATUS
Enabled saved schedules need no slash command at start. Before start they wait;
inside the window they engage; at end they stop. Late login uses the current
phase without replaying missed reminders. ESO must be running. Start is inclusive;
end exclusive. There is no weekly recurrence or offline delivery.

Pause saved schedule or /trial 1 off persists through reload. Resume saved schedule
still respects the window. Busy input waits. Untouched pending text withdraws at
end; player edits survive. REPEAT intervals follow confirmed sends. ZONE uses zone
arrivals and the interval as its per-zone cooldown. Existing zone exclusions apply.

/scm status shows command/guild states, phases, Eastern boundaries, next eligible
Repeat delivery and blockers, alongside Zone cooldowns. WAITING is before start;
RUNNING is inside the enabled window; PAUSED is explicitly stopped; FINISHED is
past end. Busy input or a cooldown can delay a RUNNING combination.

SUBSTITUTIONS
%guild%: resolved guild name. %zone%: current zone name.
%time%, %timeofday%, %greeting%: morning, afternoon or evening.
%eventdate%: configured event's Eastern date.
%eventtime%: Eastern event time with EDT/EST.
%eventwhen%: today, tomorrow or weekday/date in Eastern Time.
Tokens are case-insensitive; event tokens require a configured event.
Example: %guild% trial %eventwhen%, %eventdate% at %eventtime%.
Ordinary recognized event date/time text can also receive an automatic countdown.

OTHER PLAYERS' MATCHING MESSAGES
Matching incoming Zone/Guild/Officer messages reset the whole Command + Guild
usage/cooldown with an extra random 30–90 seconds. Your own messages are ignored.
Guild/channel identity and fixed event identity are retained; recognized greetings,
zone names and generated countdown additions may vary. Matching uses complete
fixed wording, not similar substrings. The other player does not need SmartChatMsg.

An active Repeat is delayed, but peers cannot start inactive automation, resume
paused schedules or extend their end. Untouched pending duplicates withdraw;
edited text stays. The extra cooldown survives UI reloads.

FULL SETTINGS BACKUP/RESTORE
Import / Export Settings includes commands, messages, channels, behavior, schedule
dates/times, intervals, message phases, pauses and general settings. Full import
replaces settings and unlocked messages after confirmation. Locked messages
remain if their commands survive; review imported enabled schedules.
After import, edit dates/times and phase assignments and Save schedule. Changes
affect only your copy. The separate Share Messages settings panel is removed.

ORDINARY AUTOMATION
On Demand starts through your command; Startup queues after login. Repeat Every
controls repetitions. Retry Delay handles unsubmitted repeated messages and is
capped to Repeat; zero/blank resumes the normal repeat interval. Auto Populate
Chat on Zone uses eligible parent-zone evaluations and a per-zone cooldown
(default 60 minutes). Repeat and Zone are alternatives. Scheduled mode uses its
own delivery/intervals. Populate Sound defaults to DUEL_START; None is silent,
and Preview tests it. Channel restoration follows confirmed sends or unchanged
pending-text timeouts. The timeout defaults to 60 seconds (minimum 30).

UPDATE AND TEST
Keep LibAddonMenu-2.0 installed. Install every file listed in SmartChatMsg.txt,
including SCM_Calendar, SCM_Schedules, SCM_Scheduler, SCM_ScheduleSettings and
SCM_MessageSharing Lua modules. Reload UI after updating.
See README.md and docs/scheduling-testing.md, docs/incoming-chat-testing.md and
docs/message-sharing-testing.md. Automated tests do not replace in-game UI,
loading-screen and two-player trials.

MESSAGE VISIBILITY AND CARD LABELS
Repeat cards identify Scheduled, On Demand, or Startup. Scheduled cards show
Starts in and the countdown to the current occurrence, then Started.
Scheduling checkboxes and complete message previews share bordered rows.
Used identifies the selected phases; Before event day can cover multiple days.
On Demand supports literal date/time countdowns. Event substitutions need a
saved event configuration; repeat intervals alone do not define event times.

PERSONAL MESSAGE LOCKS (1.11.7)
Click Lock beside a message to exclude it from export and protect it on import.
Unlock reverses this. Locked appears below the message and in schedule pools.
The message still sends and matches normally. Its phase choices are preserved.
Import keeps it if the command remains by ID or name; deleting its command from
the imported setup removes the message. Command settings themselves are not locked.
Exports also capture status window saved visibility and position, in addition to
Open Status Panel on Run, Notify Sound, Run At and other behavior/schedule settings.
On Demand and Startup restore slash commands; scheduled-only names remove them.

SIMPLE STATUS CYCLE (1.11.7)
Disabled -> Enabled -> Paused -> Disabled; buttons show Enable, Pause, Disable.
Disabled ordinary repeats leave the list; restart them through their command.
Matching tolerates case, spacing, formatting, substitutions and countdown changes,
but not arbitrary typos or different fixed wording/punctuation.
Same-name command imports with new IDs preserve and remap local locked messages.

NEXT OCCURRENCE DISPLAY (1.11.7)
Below Repeat schedule, Next event shows the calculated Eastern date/time without
changing the original recurrence anchor. Windows/reminders use Next window or
Next reminder. After an event starts, Next event shows the following occurrence,
even while the current promotion remains active. One-time events show None
scheduled when no future start remains. This preview reflects unsaved edits.

Promotion days: 0 starts at the event clock time, not midnight. To promote only
from midnight on event day, use 1 day of lead, deselect every Before event day
message and select On event day messages. Delivery still honors startup delay,
cooldowns, shared spacing and chat availability.
