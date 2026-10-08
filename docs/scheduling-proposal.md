# Proposal: event scheduling in Eastern Time

Status: the first event-window implementation is included in SmartChatMsg 1.10.0.
This document records the original design proposal. Use [the current user
guide](../README.md) for actual settings, supported behavior and limitations.
Message-only sharing was added separately and does not transfer schedules.

## Intended behavior

Configure an event reminder once, then have SmartChatMsg automatically enable
its messages during a specified start/end window while you are logged in.
Different saved variants can apply before the event day, on the event day, and
while the event is underway. The addon continues to populate the chat input for
you to send, matching its existing behavior.

Example: a trial takes place Friday, October 16, 2026 at 8:00 PM Eastern.
Reminders start Thursday at noon and stop Friday at 9:00 PM. Earlier reminders
can say “our trial is Friday”; Friday reminders can say “our trial is tonight”;
after 8:00 PM a selected variant can say “our trial is underway.” Each phase can
have its own interval. At 9:00 PM, that schedule stops generating messages.

## What the existing code already provides

- `SCM_Settings.lua:GetRunAtOptions` lists On Demand, Startup, and Scheduled.
  Its Messages behavior controls save the selected mode per Command + Guild.
- `SCM_SavedVars.lua:GetGuildRunAt`, `SetGuildRunAt`, and import/export already
  understand `SCHEDULED`, but do not store start/end dates or event phases.
- `SmartChatMsg.lua:BuildStartupQueueEntries` consumes `STARTUP` only. There is
  no scheduler that consumes `SCHEDULED`.
- Existing repeat/retry timers, zone eligibility, cooldowns, pending-input
  ownership, and message rotation provide useful execution pieces.
- Countdown formatting detects dates/times in ordinary message text. Its generic
  timezone aliases currently depend on the user's local DST flag; scheduling
  needs its own target-date-aware Eastern conversion instead.

The Scheduled option is therefore a saved placeholder today, not a working
start/end-window feature.

## Recommended settings

Keep the schedule attached to a **Command + Guild** combination, matching its
channel and automation settings. Under **Run At → Scheduled**, show:

| Setting | Meaning |
| --- | --- |
| Enabled | Save the event without having it run yet |
| Schedule starts (Eastern Time) | Earliest permitted population |
| Event starts (Eastern Time) | Reference time for event-relative wording/phases |
| Schedule ends (Eastern Time) | Stop boundary; exclusive |
| Delivery behavior | Repeat at an interval, or existing Auto Populate on Zone |
| Default interval/cooldown | Reuse the command/guild's existing configuration |
| Phase/message assignments | Which saved message IDs are eligible in each phase |
| Resume button | Clear an explicit user pause during an active window |

Use explicit `YYYY-MM-DD` dates and a 12-hour time with mandatory AM/PM. Show
the resolved EST/EDT abbreviation and UTC instant as a small confirmation beneath
the fields, so everyone can check the same event. UTC confirmation is useful
here because it disambiguates a scheduling choice; other execution details stay
out of the normal settings flow.

Reject invalid calendar dates and require
`scheduleStart <= eventStart < scheduleEnd`. If users later need reminders only
after an event begins, relax the event/start relationship deliberately. Keep the
first implementation to one event window per combination; multiple event
windows and recurrence can follow separately.

## Eastern Time and daylight saving

Use **America/New_York/Eastern Time**, rather than always EST. Eastern follows
UTC−5 in standard time and UTC−4 in daylight time. Resolve the offset for the
entered date, independently of the player's computer timezone and current DST
state. Store the final start/event/end instants as UTC Unix seconds, alongside
the entered Eastern dates for editing.

Under the current US rules, DST begins on the second Sunday in March and ends
on the first Sunday in November. In 2026 those dates are March 8 and November 1.
See [NIST's daylight-saving rules](https://www.nist.gov/pml/time-and-frequency-division/popular-links/daylight-saving-time-dst).

ESO's Lua environment cannot be assumed to ship an IANA timezone database.
Implement a small pure calendar/Eastern conversion module for modern dates
(2007 onward), with its rule clearly documented and tested. Do not derive the
offset from `os.date('*t').isdst` on the player's computer or parse a local
`os.time` value as if it were Eastern. If rules change, this isolated module is
the place to update.

Reject the nonexistent 2:00–2:59 AM interval on spring-forward day. For the
repeated 1:00–1:59 AM interval on fall-back day, require the user to choose the
first occurrence (EDT) or second occurrence (EST). Do not silently select one.

## Event-relative variants

Give each saved message an optional schedule phase assignment. Continue using
the existing weighted rotation among eligible variants:

| Phase | Eligibility |
| --- | --- |
| Any active time | The full configured window |
| Before event day | Before midnight Eastern at the start of the event's date |
| Event day, before start | From that midnight until the event instant |
| Event underway | From the event instant until the schedule end |

Start/end boundaries still apply to every phase. Add optional interval overrides
per phase, so earlier reminders might repeat every hour and event-day reminders
every 15 minutes. If the active phase has no assigned messages, stop population
and show “No message for this phase”; do not fall back to an advertisement
whose event wording is now wrong.

For predictable output, new event-aware tokens such as `%eventdate%`,
`%eventtime%`, and `%eventwhen%` should come from the schedule's explicit event
instant. `%eventwhen%` can produce “today,” “tomorrow,” or an Eastern weekday/date.
Existing messages and their embedded-time parser continue to work. Do not infer
the schedule window from a date mentioned casually in message text: one message
can mention several dates or refer to a different event.

When event tokens are added, extend incoming-template matching with typed rules
for those exact generated spans. Keep guild identity and explicit event identity
required, so reminders for different events do not suppress one another.

## Runtime and conflict handling

Use one scheduler to reevaluate enabled windows every second and immediately on
login, `/reloadui`, and settings save. Compare current UTC timestamps on every
evaluation and immediately before any population; timer callbacks alone are
insufficient after a loading screen or long client stall.

1. **Waiting:** before the start boundary, retain the saved schedule without
   registering its message delivery timers.
2. **Running:** at/after start and before end, choose the current phase and start
   the selected repeat or zone behavior. All population paths must also check
   the window, phase, channel availability, and current cooldown.
3. **Paused:** an explicit `off` persists a pause for this event window. The next
   scheduler tick and a reload must not reactivate it. Resume requires the user
   or editing/rearming the schedule.
4. **Finished:** at/after end, cancel schedule-owned repeat/retry jobs and remove
   queued population requests. Withdraw untouched schedule-owned chat input;
   preserve user edits. Mark the event window completed without deleting it.

Logging in partway through a window starts the currently valid phase, subject to
cooldown. Logging in after the end does nothing. Do not replay a backlog of
missed reminders or send anything while ESO is closed.

Scheduled repeat and scheduled zone modes remain mutually exclusive for one
combination. A manual command whose Run At mode is Scheduled must respect the
window; outside it, show its start/end information without populating. Existing
On Demand/Startup combinations keep their current behavior.

There is one chat input. Use a shared population queue for simultaneous manual,
startup, and scheduled requests, with manual input taking priority. Never
overwrite text the player is typing or another pending addon message. Deduplicate
queued requests per combination and discard requests when their window/phase
expires. Recheck phase when a queued request is finally handled.

The current code also supports only one active zone-auto-populate combination.
The first implementation should permit only one enabled **scheduled Zone**
combination at a time. If a manually active zone command already owns that slot,
the scheduled window waits with a visible “Waiting for active zone command”
state and reevaluates after the slot is released. It must not silently replace
the user's active command. Multiple scheduled Repeat combinations can share the
population queue. Supporting multiple concurrent zone commands is a later change
to that existing interface.

If a matched peer message resets the combination, keep the event window active
but defer delivery using the incoming-coordination PR's cooldown and 30–90-second
delay. A deferred job that falls at/after the end is canceled. Observed messages
must not unpause a schedule or restart a finished window.

## Saved data and status

Store schedule configuration under the existing Command + Guild settings:

```lua
schedule = {
    enabled = true,
    timeZone = "America/New_York",
    startsAtUtc = 1792080000, -- October 15, 2026 at noon EDT
    eventAtUtc = 1792195200,
    endsAtUtc = 1792198800,
    paused = false,
    phases = {
        -- phase names, optional interval overrides, and saved message IDs
    },
}
```

Retain the entered civil timestamps and fall-back choices alongside these UTC
values. Runtime ownership IDs and transient queue state are not exported. Extend
SavedVariables sanitization and versioned import/export so schedules, pauses,
message assignments, and event identities survive reloads and transfers. Older
settings without a schedule remain valid. Legacy `SCHEDULED` records lacking
dates show “Schedule not configured” and do nothing until saved successfully.

The status panel should show Waiting/Running/Paused/Finished, current phase,
window boundaries in Eastern, and the next eligible delivery time. A blocked
channel, busy chat input, cooldown, or conflicting zone owner should have a short
visible reason. The UI must derive deadlines from the same scheduling helpers as
the actual delivery checks.

## Implementation sequence and acceptance checks

1. Build pure date validation, Eastern conversion, and phase/window eligibility.
   Test leap days, invalid dates, DST changes, and start/end equality boundaries
   under clients in different local timezones.
2. Add persisted schedule/phase fields, migration, import/export, and settings
   validation. Verify old On Demand/Startup settings still round-trip.
3. Add the scheduler and population queue. Test overlapping Repeat windows,
   channel loss, busy input, stale callbacks, login/reload, manual `off`/Resume,
   and the single active Zone owner policy.
4. Connect phase filtering and event tokens. Test Eastern midnight changes,
   event-start changes, weighted selection within a phase, missing assignments,
   and queued requests that become stale.
5. Integrate peer cooldown coordination, pending-input withdrawal, and status.
   Test a peer match just before the schedule end, untouched versus edited input,
   stopped/paused schedules, and reload during a deferred delivery.
6. Try a short real window with two players in ESO: verify automatic activation,
   phase changes, cooldown cooperation, and automatic stopping. No message may
   be populated at or after its window end.

This proposal recommends a one-event-window implementation first. Weekly
recurrence, multiple events per combination, server-time choices, and arbitrary
relative phase editors should remain separate follow-up work.
