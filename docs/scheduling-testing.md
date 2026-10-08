# Trying event scheduling

Install the complete current addon, including the updated manifest and
all `SCM_*.lua` files. Keep your existing LibAddonMenu2 dependency. Export current
settings before trying a new window so you can restore your configuration.

## Configure a short window

1. Open `/scm` (or `/scm schedule`). In Messages Settings, select your command,
   guild, and output channel, and save the messages you want to use.
2. Open **Event Scheduling (Eastern Time)**. Confirm the displayed command/guild.
3. Enable the window. Choose REPEAT, with a one-minute default interval. Enter
   today's Eastern date and start/event/end times a few minutes apart. Dates use
   `YYYY-MM-DD`; times use `HH:MM AM/PM`. Start must be at or before the event;
   end must be after it.
4. Assign messages using their displayed numbers. For a phase-specific message,
   uncheck ANY, then check DAY or LIVE. BEFORE means before the event's Eastern
   calendar day; DAY means midnight until event start; LIVE means event start
   until window end. Unassigned messages apply to ANY phase. Unchecking all
   phases deliberately disables that message for this schedule.
5. Optional phase interval overrides must be positive whole minutes; leave blank
   to inherit the default. Click **Save schedule**. Invalid edits stay in the
   draft and do not replace the previous saved schedule.

Example message: `%guild% trial %eventwhen%, %eventdate% at %eventtime%.`
The tokens produce an Eastern date, time with EDT/EST, and today/tomorrow or a
weekday/date. Original event identity remains required for peer matching.

## Verify behavior in ESO

- Before start, `/scm status` shows WAITING and no scheduled text appears.
- At start, an eligible message fills the chat box. Press Enter to send it.
  The next interval starts on a confirmed send; unsubmitted text uses the
  existing restore timeout and configured retry, or the schedule interval.
- Type your own text before a delivery is due. It should remain untouched.
  Clear/send it and let the scheduler deliver. Manual requests take priority
  over Startup requests, which take priority over scheduled requests.
- At event start, verify LIVE selection. If the current phase has no eligible
  messages, delivery waits instead of selecting another phase's message.
- Leave an untouched scheduled message pending until end: it should withdraw.
  Edit the pending text: your edits should survive end and restore timeout.
- Run `/yourcommand 1 off` (use the appropriate guild slot) to pause. Reload UI:
  it must remain paused. Resume through scheduling settings. Incoming peer
  messages must not resume a paused schedule.
- With a second player, send a matching message on the same configured channel
  and guild. Your combination's cooldown should reset with an extra 30–90
  seconds. Different event dates/times and different guilds must not match.
- Repeat with ZONE delivery. Travel between eligible overland zones; busy-input
  requests must be revalidated after travel, and excluded zones must not deliver.
  Only one enabled scheduled Zone combination is supported. An existing manual
  Zone owner keeps ownership until stopped.
- Export/import, then reload: window dates, pauses, phase assignments, and
  intervals should survive. Import errors must leave current settings intact.

ET follows US Eastern daylight saving rules from 2007 through 2099. Spring
missing times are rejected. In the repeated November hour, choose EDT (first)
or EST (second) for that timestamp. Your computer's timezone does not change the
schedule. Try the same configuration with clients in different timezones.

This first implementation supports one event window per command/guild and no
weekly recurrence. Automation runs while ESO is running; late login selects the
current phase without replaying offline deliveries. It populates chat and still
requires you to send. Automated tests use mocked ESO APIs; real ESO UI and
two-player trials remain necessary.

## Automated checks

For the full setup and editable import/export choices, see [the user guide](../README.md).
Message-only sharing does not copy schedule times or phase assignments; full
settings export does. Recipients can edit imported schedules and save their own
times and message-phase choices. Full import replaces existing settings.

From the repository root with Lua 5.1:

```
lua tests/calendar_spec.lua
lua tests/incoming_chat_spec.lua
lua tests/schedules_spec.lua
```
