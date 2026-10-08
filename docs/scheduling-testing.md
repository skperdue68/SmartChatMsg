# Try simple scheduling in ESO

Install the complete addon and LibAddonMenu-2.0 release 34 or newer plus
LibAddonMenuDatePicker. Reload the UI. Export existing settings first.

1. In Messages Settings select a command, guild, and output channel. Add at least
   three message variants. Open Event Scheduling (Eastern Time).
2. Choose Run during a window. Use the calendar for today and set start a few
   minutes ahead and stop ten minutes later. Set the message interval to one
   minute. Select several messages, enable, preview, and save.
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
   Choose Once for event start and verify it doesn't keep repeating.
8. Repeat with two different commands; confirm both engage without overwriting
   each other or typed chat. Pause one and reload; only the other may continue.
9. Export full settings, import, and reopen: modes, dates, recurrence, interval,
   message pools and pauses must survive. Old saved event schedules must load.
10. Have another player post a selected template on the same output channel and
    guild. The cooldown resets with 30–90 seconds extra delay. A different guild
    or channel must not reset it; own outgoing messages are ignored.

Automatic scheduling requires ESO to be running. It prepares messages for Enter,
not silent sends, and does not replay offline occurrences.
