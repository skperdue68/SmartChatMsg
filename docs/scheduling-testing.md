# Try simple scheduling in ESO

Version 1.11.2 status checks: after the startup wait, run `/scm resetcooldowns`.
An enabled current schedule should prepare chat and announce Press Enter locally.
Leave one unsent and confirm the timeout notice explains the next attempt time.
Cycle a current card Off -> Paused -> On -> Paused -> Off, checking both button
text and actual delivery. Pausing must retain player edits and stop delivery.
Confirm future/expired schedules are absent from the actionable cards, and all
four text lines stay inside each enlarged box. Reset cooldowns while a schedule
is paused/off: its state and dates must stay unchanged. Reset during startup:
the three-minute wait must still apply. The reset also clears once markers so
current one-shot reminders can be tested again; it does not replay old events.

Install the complete addon and LibAddonMenu-2.0 release 34 or newer plus
LibAddonMenuDatePicker. Reload the UI. Export existing settings first.

Version 1.11.1: expect a local "SmartChatMsg is running" notice and a three-minute
hold on scheduled delivery after login/reload. Start ordinary scheduling tests
after that hold expires. With two active schedules, confirm that sending one
defers the other for five minutes, but does not alter either saved interval.
An unsent preparation timing out must not begin that shared pause. Confirm local
notices at schedule start/end and at Before event day -> Event day -> Starting
soon -> Event started, naming the new frequency. All notices should appear in
chat, even when center-screen announcements are enabled.

1. In Messages Settings select a command, guild, and output channel. Add at least
   three message variants. Set Run At to Scheduled and open Scheduling (Eastern Time) inside Create / Edit / Delete Messages.
2. Choose Run during a window. Use the calendar for today and set start a few
   minutes ahead and stop ten minutes later. Set the message interval to one
   minute. Select several messages, review the preview, and click Save and activate.
3. Confirm the status shows readable ET dates. At start chat should populate;
   press Enter to send. Type your own text before the next interval: it must
   remain untouched. At stop untouched generated chat withdraws, edits survive.
4. Reopen the schedule: calendar and time values must match what you saved.
   Change your computer timezone and verify the selected calendar day stays the
   same and ET occurrence times do not shift.
5. Choose Remind me at set times. Try every two weeks with a first date and time.
   Preview must show the correct alternating weeks, with no event/end field.
6. Try monthly date and monthly weekday recurrence. Preview January 31 and a
   fifth weekday to verify missing dates skip the month. Preview across March
   and November clock changes to verify Eastern wall-clock behavior.
7. Choose Promote an event. Pick its date/time and promotion lead/stop delay.
   Select multiple messages in each phase and give the phases distinct wording.
   Verify day-before, event-day, and event-start deliveries use their own pools.
   Choose Prepare only once when event starts and verify it doesn't keep repeating.
8. Repeat with two different commands; confirm both engage without overwriting
   each other or typed chat. Pause one and reload; only the other may continue.
9. Export full settings, import, and reopen: modes, dates, recurrence, interval,
   message pools and pauses must survive. Old saved event schedules must load.
10. Have another player post a selected template on the same output channel and
    guild. The cooldown resets with 30–90 seconds extra delay. A different guild
    or channel must not reset it; own outgoing messages are ignored.

Automatic scheduling requires ESO to be running. It prepares messages for Enter,
not silent sends, and does not replay offline occurrences.

## Test incoming-message detection by yourself

Create a test message such as `SCM solo cooldown test` with Zone output. Enable
`/scmdebug on`, then enter:

```lua
/script SmartChatMsg:HandleIncomingChatMessage(nil, CHAT_CHANNEL_ZONE, "SCM Test Player", "SCM solo cooldown test", false, "@SCMTestSender")
```

This calls the real incoming-message handler locally; it sends no chat. A match
logs `Incoming match` and updates the actual saved cooldown with the random
30–90-second delay. The command need not be running. Use your rendered message
text to test substitutions or a changing countdown. Use `CHAT_CHANNEL_GUILD_1`
for your first guild or `CHAT_CHANNEL_OFFICER_1` for its officer chat. Changing
the channel or guild must prevent a match unless a corresponding template exists.
Sending the message yourself normally is ignored. This simulation checks the
matching and cooldown path; a second player is still needed to test live reception.

## Check the settings cleanup

Scheduling must be disabled with Run At set to On Demand or Startup, and enabled
with Run At set to Scheduled. Change command or guild above it and verify the
schedule belongs to that selection. Save disabled must preserve the schedule
without running it. Save and activate must activate it. Invalid saves must keep
the previous saved schedule. Edits must show Unsaved changes until saved.
A prepared message must say Message ready — press Enter; typed or edited chat
must say Waiting for your chat, without overwriting the text.

## Test Starting soon and longer message lists

In Promote an event, expand Event and promotion timing and enable Starting soon.
Set the lead time to five minutes for a quick test and the event time a little
over five minutes ahead. Open Starting soon, select its messages and set its
Message interval override to one minute. Save and activate. It should change
from On event day to Starting soon exactly five minutes before the event, then
to From event start at the event time. An untouched pending message from the
earlier phase is replaced; edits remain protected. Default lead time is 120
minutes, and existing schedules leave this optional phase disabled.

Add at least ten message variations, including messages that wrap over several
lines. Every phase checklist should remain inside its scroll area. Use the wheel
over text or a checkbox, or drag the scrollbar, to reach and select the last row.
Changing a selection must preserve the scroll position. Check that the interval
and once-only controls below the list remain visible and do not overlap it.
