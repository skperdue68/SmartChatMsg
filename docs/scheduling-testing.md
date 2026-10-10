# Try SmartChatMsg 2.0 scheduling in ESO

Version 2.0.2: check messages appear in earliest-phase order, with unused messages last. Toggle phase checkboxes while scrolled partway down a long pool; confirm the visible message and row offset stay stable, selection belongs to the correct message, open sections stay open, and unsaved text edits are retained. Confirm ordinary message lists and random selection are unchanged.

Version 2.0.1: configure two guilds with the same event clock time but different
Guild timezone defaults. Verify each heading, event token, phase midnight, and
status date uses its own zone. Change one guild and confirm the other is untouched.
Change Global Settings and confirm only inherited guild defaults follow it.
Test Use global default, export/import, and switching zones with unsaved edits.


Version 2.0 checks:
- Confirm Scheduling begins below Enter Message with a clear gap, including after adding/deleting messages.
- Choose any repeating Promote an event schedule and Last event of month. Each phase row has a Group button; click Regular events/Month-final events and save. Reopen and verify the selection. Check regular fallback with no special messages.
- Change global Scheduling timezone ET/CT/MT/PT. Heading, picker labels, previews, event tokens, midnight starts, recurrence and faction/month-final selection must follow the new zone. Existing 8 PM anchors must remain 8 PM in the new zone. Export, switch zones, import and verify the exported zone returns.
- Verify (Scheduled) has a space before Starts in. The status suffix names the same phase as settings and its effective interval, one announcement, or on-zone delivery. Check long labels and promotion dates fit inside the enlarged card.
- Test phase interval overrides and Prepare only once: send once, let the interval pass, confirm no second send in that phase; advance to the next phase and a later recurring event.
- Smoke-test On Demand and Startup commands, plus the three-minute scheduled startup hold and five-minute spacing between different scheduled combinations.

Version 1.12.0: confirm Auto and Repeat Commands collapse when empty and can be
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

## Message visibility and identity (1.11.8)

- Confirm a scheduled card shows (Scheduled) and Starts in until the event time,
  then Started. On Demand repeats should display (On Demand).
- Resize/open the schedule message selection. Long messages and the Used phase
  line should wrap fully within each bordered checkbox row, without overlap.
- Toggle phase assignments, save, and inspect the phase captions in the saved
  message editor. Starting soon should appear only when enabled.
- Confirm Share Messages is absent and Import / Export Settings remains.

## Personal lock and transfer checks (1.11.8)

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

## Three-state cycle and new IDs (1.11.8)

- A disabled current schedule shows Enable. Click it: Active, button Pause.
  Click Pause: Paused, button Disable. Click Disable: Inactive, button Enable.
- Pausing/disabling must withdraw unchanged prepared text, cancel queued work,
  and preserve player edits. Enabling still respects all delivery gates.
- Repeat these checks with an ordinary command started through its slash handler.
  After Disable it leaves the running list; restart using the slash handler.
- Import a same-name command under a new ID. Verify its imported channel/event
  time and local locked message/phase choices remain consistent.

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

## Zero-day promotion (1.11.8)

Set an event to 8 PM ET with 0 promotion days and an event-day message. The
promotion window must start at 12 AM ET, prepare nothing before that boundary,
and become eligible at midnight. Starting soon and live phases remain unchanged.
Repeat the check with weekly recurrence and a daylight-saving transition date.
The first actual preparation still obeys startup/cooldown/spacing/chat gates.

## Faction rotation and month-final raffles (1.12.0)

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

For raffles, keep Every other week and the original first drawing date. Choose
Last raffle of the month + 50/50. Add both regular and combined raffle/50-50
announcements under the same command. In each message row choose Regular drawings
or Month-final drawings. Unassigned messages default to Regular
drawings in this pattern. Select each message's desired promotion phases.
The pool is determined by the drawing's Eastern date, throughout its promotion:
if the next scheduled drawing falls in another month, this drawing is month-final.
It is the last actual biweekly drawing, not the calendar's last Saturday. For an
October 10 anchor, October 10 is regular and October 24 is month-final; January
2, 16 and 30 likewise use regular, regular, month-final pools.
If no messages are marked month-final for this command/guild, regular messages
are used for every drawing. Once special messages are configured, their phase
selections apply; an intentionally empty special phase does not use regular text.
Mark only the special messages, once per message; the choice is shared across phases.

Save and activate after reviewing the next events and their faction/group labels.
Pattern settings, order, block length and message groups are included in settings
export/import. Local locked messages keep their personal group and phase choices.
Incoming matching resolves %eventfaction% to the expected occurrence's faction.
Changing to a window/non-repeating schedule turns the special pattern off.

## Local message previews

- Test an ordinary message beside Lock: substitutions appear in local chat; the input stays unchanged.
- Edit message text without saving and test it: the edited text is used.
- Edit an event time without saving and click its message text in each phase: the local heading shows a time inside that phase, and event tokens/countdowns agree with it.
- Confirm clicking the text does not change its checkbox; use the checkbox to enable/disable the message.
- Test a recurring event after the anchor date and around a DST transition.
- Test a phase excluded by the promotion window: a clear local notice appears.
- Confirm tests leave cooldowns, schedule activation, once-per-phase flags, and pending chat text unchanged.
