# Try simple scheduling in ESO

Install the complete addon and LibAddonMenu-2.0 release 34 or newer plus
LibAddonMenuDatePicker. Reload the UI. Export existing settings first.

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
