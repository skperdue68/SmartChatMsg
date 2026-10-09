# Try simple scheduling in ESO

Version 1.11.7: confirm Auto and Repeat Commands collapse when empty and can be
toggled by their headers. Promotion start/end should appear in current cards,
without the duplicate summary above. Next Send must be absent while Paused/Off.
Check native button styling, scrollbar clearance, and the section's bottom fit.
Schedule-only slash names are no longer registered. Start an ordinary On Demand
repeat by its command, send it, confirm its next interval, then test card pause/off.
Mixed names retain their slash command for ordinary guild configurations.
For countdown regression: an event at 9 PM ET viewed at 8 PM ET must display 1h,
including when the UTC date has already changed; verify the next recurring event
and both EST/EDT. Incoming copies with that countdown must still reset cooldowns.

Version 1.11.2 status checks: after the startup wait, run `/scm resetcooldowns`.
An enabled current schedule should prepare chat and announce Press Enter locally.
Leave one unsent and confirm the timeout notice explains the next attempt time.
Cycle a current card Disabled -> Enabled -> Paused -> Disabled, checking both button
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

## Message visibility and identity (1.11.7)

- Confirm a scheduled card shows (Scheduled) and Starts in until the event time,
  then Started. On Demand repeats should display (On Demand).
- Resize/open the schedule message selection. Long messages and the Used phase
  line should wrap fully within each bordered checkbox row, without overlap.
- Toggle phase assignments, save, and inspect the phase captions in the saved
  message editor. Starting soon should appear only when enabled.
- Confirm Share Messages is absent and Import / Export Settings remains.

## Personal lock and transfer checks (1.11.7)

1. Add a personal message, assign its event phases, and click Lock. Confirm the
   Locked caption and Unlock button. Check the schedule pool caption too.
2. Export. The private text and its SCHEDULEMESSAGE record must be absent.
3. Import an export containing the same command. The local message, lock, usage,
   and phase assignments should remain; unlocked messages follow the imported set.
4. Test a same-name command with a different imported ID. The protected message
   should belong to the imported command. A colliding message ID cannot replace it.
5. Import a setup without its command. The private message should be removed.
6. Unlock it before exporting when you actually want to transfer that content.
7. Round-trip Notify Sound, Open Status Panel on Run, Run At, repeat/retry/cooldown,
   event settings and status window visibility/position.
8. Switch Run At between Scheduled, On Demand, and Startup. Ordinary modes must
   restore the slash handler; Scheduled removes it unless another guild needs it.
9. Confirm the space below Notify Sound is smaller and rows remain separated.

## Three-state cycle and new IDs (1.11.7)

- A disabled current schedule shows Enable. Click it: Active, button Pause.
  Click Pause: Paused, button Disable. Click Disable: Inactive, button Enable.
- Pausing/disabling must withdraw unchanged prepared text, cancel queued work,
  and preserve player edits. Enabling still respects all delivery gates.
- Repeat these checks with an ordinary command started through its slash handler.
  After Disable it leaves the running list; restart using the slash handler.
- Import a same-name command under a new ID. Verify its imported channel/event
  time and local locked message/phase choices remain consistent.

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
