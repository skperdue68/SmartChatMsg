# SmartChatMsg 2.1.0 — User Guide

SmartChatMsg prepares reusable messages in ESO's chat box. **Press Enter to send them.** It runs only while you are online with the addon loaded; it cannot send announcements while ESO is closed.

## Install or update

Install the SmartChatMsg addon folder and enable **LibAddonMenu-2.0** and **LibAddonMenuDatePicker**. Keep your existing SavedVariables file when updating. Open the settings with `/scm`, and open the status window with `/scm status`.

## Commands, guilds, and messages

Create a command name, then select that command and a guild under **Create / Edit / Delete Messages**. A command can have different settings and messages for different guilds. Choose **Guild**, **Officer**, **Zone**, or **Group (/g)** as its output channel. Group prepares messages for your current ESO group; the selected guild still identifies the configuration and substitutions, rather than the recipients. Enter a message and click **Add**; add several variations to have the addon choose randomly. Existing messages can be updated or deleted.

The selected **command + guild** is the unit of scheduling and cooldown coordination. Zone messages still belong to that selected combination, but their output and incoming matching use Zone chat.

## Global settings

- **Default guild:** used when you launch an ordinary command without a guild number.
- **Scheduling timezone:** Eastern (ET), Central (CT), Mountain (MT), or Pacific (PT). Eastern is the default. US daylight-saving rules are applied for the date, independently of your computer's timezone. Mountain follows the DST-observing Mountain rules, rather than Arizona's year-round standard time.
- **Chat revert time:** how long an unchanged prepared message can wait before timing out. Player edits are protected.

The global timezone is a fallback. Each guild can choose its own timezone under **Scheduling → Guild timezone**, with **Use global default** selected initially. This default applies to all schedules for that guild, across commands. For example, one guild can use Eastern while another uses Pacific. Selecting a guild changes the Scheduling heading, picker labels, previews, event substitutions, and status dates to that guild's effective zone.

Changing a guild timezone moves that guild's existing schedules to the **same clock time in the new zone**. For example, 8 PM Eastern becomes 8 PM Pacific. Other guilds are unchanged. Changing the global timezone moves only schedules for guilds using **Use global default**; explicit guild choices stay fixed. Choosing Use global default again moves the guild's schedules back to the current global zone. Unsaved schedule edits are retained when you change the guild choice. Event recurrence, midnight boundaries, event substitutions, faction rotation, and month-final selection use the guild's zone. Literal text such as `8 PM ET` inside a message keeps its explicit timezone meaning; edit that text yourself if needed. Prefer `%eventtime%` for scheduled events.

Dates and times in settings are readable calendar values; stored UTC timestamps are internal. The spring DST hour that does not exist cannot be selected for an anchor. Repeating occurrences that land in that missing hour are skipped. During the repeated autumn hour, scheduling uses the first occurrence by default; legacy explicitly selected second-occurrence values are retained.

## Choose how a combination starts: Run At

| Run At | What happens | How to launch |
| --- | --- | --- |
| **On Demand** | Waits for you to start it; can prepare once or repeat. | Type your custom slash command, such as `/recruit 1`. |
| **Startup** | Enters a queue when the addon initializes, including after a UI reload. It uses the ordinary command's behavior settings. | Starts automatically; its slash command remains available. |
| **Scheduled** | Runs only within the saved schedule's eligible times. | Click **Save and activate**; no slash command is needed. |

A name used exclusively for Scheduled combinations has no custom slash command. Changing a combination to On Demand or Startup restores the command. If another guild uses the same name for an ordinary combination, its command remains available.

### Request an extra scheduled reminder

Use **`/scm send <command> [guild number]`**, for example `/scm send mafiapvp 1`. The shorter `/scm mafiapvp 1` also works. Names are case-insensitive and may include the leading slash. Use the explicit `send` form if a name conflicts with built-in actions such as `retry` or `status`.

The guild number is optional when the command has only one Scheduled guild. If it has several, the configured Default guild is used when that guild has a Scheduled combination; otherwise specify a guild number from 1 to 5. The saved output channel remains in effect.

This requests one randomly selected message for the **current phase and occurrence**, with normal substitutions/countdowns. The schedule must be enabled, unpaused, and inside its active window. It overrides its own repeat interval, zone cooldown, and prepare-only-once completion so you can call an extra reminder. It still respects matching messages from other players, the three-minute startup delay, the five-minute pause after another schedule, and zone eligibility. A request during a pacing delay is rejected with an explanation; try again after that delay.

If your chat contains a draft or another prepared message, the request waits without replacing it. If its phase, occurrence, or schedule changes while waiting, it is discarded. Request it again for the new phase. A reminder already waiting in chat is kept rather than duplicated.

**Press Enter to send.** Preparing or requesting alone does not record a send. A confirmed send updates usage, resets the next automatic send to the current phase's normal interval, and pauses other schedules for five minutes. It does not enable a disabled schedule, resume a paused one, or change phase assignments. A phase set to prepare only once remains complete after an extra manual send.

### Ordinary On Demand and Startup behavior

- **Repeat Every (mins):** after you send a prepared message, wait this long before preparing another. Leave repeating disabled for a one-time command.
- **Retry Delay (mins):** when a prepared repeated message times out unsent, controls the retry delay. Zero or blank uses the normal repeat interval. An explicit retry cannot exceed either Repeat Every or Cooldown; the smaller limit applies. Lowering either limit also clamps saved Retry Delay. Automatic retry is inactive when repeating is off. Scheduled combinations retain their schedule interval cap.
- **Auto Populate Chat on Zone:** prepares messages on eligible zone arrivals instead of ordinary repeating. Only one Zone automation owner can be active at a time.
- **Cooldown (mins):** prevents another automatic message for the same zone until that zone's cooldown has elapsed. It is separate from Repeat Every.
- **Open Status Panel on Run:** opens the status window when the combination runs.
- **Notify Sound:** plays the chosen sound when a message is prepared; **None** is silent, and **Preview** lets you hear the selection.

For example, Repeat Every 10 and Cooldown 60 caps Retry Delay to 10 minutes. Repeat Every 60 and Cooldown 10 also caps Retry Delay to 10 minutes. Zero or blank still resumes the normal repeat interval after timeout. Zone delivery uses its own per-zone cooldown instead of this repeat loop. Scheduled combinations use the delivery and intervals inside Scheduling.

## Scheduling with Period Timeline

Set **Run At** to **Scheduled**, choose the guild/output channel, then open **Scheduling**. Set one actual **Event date and time**, its optional duration, and recurrence. There is no Schedule type selector and no old-format conversion button.

Under **Period Timeline**, select or add a period. Set its **Period Label**, **Period Status**, **Period Starts** and **Period Stops** dates/server clocks, **Repeat Frequency**, and message-pool checkboxes. One randomly selected eligible message is prepared each time it is due. Different periods can use different frequencies and messages without separate commands. **Send once** makes a one-time notice; its lateness allowance controls how late that notice can appear while online.

Normal periods start on or before the event. **Allow promotion after event starts** permits underway invitations; event duration limits them unless the explicit after-event exception is enabled. For an 8–10 PM event, use a pre-event period ending at 8 PM and an underway period from 8–10 PM with its own messages. You can add a Send once announcement at 8 PM too.

Dates use the date-picker extension; clocks use constrained hour/minute/AM-PM choices in the guild timezone. Period dates follow future occurrences and keep server clocks consistent through daylight saving. Existing period anchors retain their meaning until edited. Invalid clocks and backwards periods are rejected.

Native sliders mirror the web editor: duration **0 = Not set** through **240 minutes**, recurrence interval **1–10**, period repeat frequency **1–1440 minutes**, and daily announcement maximum **0 = Unlimited** through **20**. Not set and Unlimited are stored by omitting the optional value, not as a zero-length event or zero allowed messages. Existing larger values are retained until deliberately changed. Slider labels show readable durations.

**Important times** provides named moments for substitutions such as `%eventtime:tickets%` and `%eventcountdown:tickets%`. Each period has a bounded, scrollable message-pool selector. **Availability** can restrict its days/hours and daily maximum. **Preview Period Timeline** and clicking a message preview show what the periods will do.

Use **Save and activate** to validate and enable, or **Save disabled** to keep the configuration off. Draft edits do not change the running schedule until saved. ESO must be running; press Enter to send prepared text. Scheduling is disabled for On Demand and Startup combinations, which retain their ordinary command-wide pools.

Only current Period Timeline schedules load or import. Older phase/window/reminder schedules are not converted. Imports containing unsupported schedules are rejected before replacing current settings; on startup unsupported schedule records are ignored while their command/message content remains. A fresh editor starts directly in the current format.

### Recurrence

Choose once, daily, weekly, every other week, monthly on date, or monthly on weekday. The original event date anchors the pattern. The recurrence interval multiplies the chosen unit; Every other week × 2 means every four weeks. Weekday choices describe event occurrences, not advertising days. Use period Availability for advertising days/hours.

## Repeat schedule and More repeat options

Recurrence repeats the **whole window, reminder, or event**. It does not control how frequently messages appear within a window.

- **Does not repeat:** one occurrence.
- **Daily:** repeats by calendar day.
- **Weekly:** repeats each week on the anchor weekday, unless you select other weekdays.
- **Every other week:** repeats in two-week blocks anchored by the original date's week.
- **Monthly on date:** the original day number; months without that date are skipped.
- **Monthly on weekday:** the original weekday and its position in the month, such as the third Friday; months without that occurrence are skipped.

**Custom repeat interval (optional)** multiplies the selected recurrence. Blank or 1 uses the normal pattern. Daily + 3 means every three days; Weekly + 2 means every two weeks; Every other week + 2 means every four weeks; Monthly + 2 means every two months.

**Repeat on weekdays (optional)** filters/adds eligible weekdays for Daily, Weekly, and Every other week. With no weekdays selected, Weekly/Every other week use the anchor weekday. With Monday and Thursday selected, Weekly produces events on both days each eligible week, at the anchor's clock time. Every other week uses those days in alternate eligible weeks. Daily still honors its day interval as well as the weekday filter. Dates before the original anchor are not generated. This option does not change monthly patterns.

## Special event patterns

These are optional refinements for **repeating scheduled event** schedules. They work with any supported recurrence; Every other week is not required.

### Faction rotation

Select **Special event pattern → Faction rotation**. Under **Faction rotation**, choose the first faction, optional second/third factions, and **Faction frequency (weeks)**. Choose **Not used** for slots you do not need.

The **Event date under Event date and time** starts the first faction's block. Each selected faction runs for the chosen number of calendar weeks, then the order repeats. The complete cycle is frequency × number of selected factions: three factions at four weeks each gives 12 weeks; two factions at two weeks each gives four weeks. Rotation continues across weeks you are offline.

**Use `%eventfaction%` in a message to show the proper full faction name for that event.** In phase message rows, choose All selected factions for a reusable template or choose one faction for wording specific to it. Phase selections still control when the message runs.

### Last event of month

Select **Special event pattern → Last event of month**. This finds the last actual scheduled event in each calendar month, using your recurrence and scheduling timezone. It is not tied to raffles, a fixed weekday, or the month's last calendar day.

Under each phase, click the **Group** button beneath a message to cycle **Regular events → Month-final events → All events → Regular events**. Existing/unmarked messages remain regular by default. Mark special month-final announcements as Month-final events. Choose All events when the same text should be eligible for either kind of occurrence; its phase checkboxes still control when it runs. For example, one All events message assigned to Starting soon can announce ticket sales are closed for both regular and month-final drawings. Save and activate after changing assignments.

The final event uses its month-final pool throughout promotion, including promotion that starts in the previous month. All events messages join both pools within their selected phases. If no messages for the combination are marked month-final, regular messages are used instead, together with All events messages. Once a special pool exists, its phase checkboxes are respected; a phase with neither month-final nor All events messages intentionally has no messages. Each pool can have several random variations. Full import/export preserves All events, including the personal assignments of locked messages.

### Test a message before using it

Click **Test** beside a message's **Lock / Unlock** button to display the parsed message in your local chat using the current time. This uses the same substitutions and countdown parser as delivery, including unsaved message edits. For the selected scheduled command/guild, unsaved schedule edits are used too.

In a scheduling phase, click the **message text** to test that specific message at a simulated time inside the phase section you are viewing. The phase names beside **Used:** are separate links: clicking **Event day** tests Event day even when the row appears in Before event day. Each link uses a time inside its own named phase. The checkbox still controls inclusion; clicking the text does not toggle it. A local heading shows the phase and simulated date/time, followed by the completed message:

- **Before event day:** normally the event's clock time on the previous calendar day, adjusted to fit the configured phase.
- **Event day:** midway through the eligible event-day period before Starting soon.
- **Starting soon:** midway through the configured Starting soon period.
- **After event starts:** midway between the event start and promotion end. With a duration of 0 there is no time in this phase to preview.
- **While active:** midway through a window or reminder occurrence.

All event substitutions and countdowns share that simulated clock and the same occurrence, including recurrence and faction rotation. If a phase has no time in the configured promotion window, the test explains that instead. Configure valid dates and times before testing scheduled messages. A message need not be enabled for that phase to test it.

Tests appear only for you through `SmartChatMsg:AddLocalChatMessage`. They do not place text in the chat input, send anything, consume a once-per-phase delivery, enable a schedule, or reset cooldowns.

## Message substitutions and countdowns

| Substitution | Meaning |
| --- | --- |
| `%eventtime%` | Current scheduled occurrence's clock time and timezone, such as 08:00 PM PDT. |
| `%eventdate%` | Current occurrence's calendar date. |
| `%eventwhen%` | Today, tomorrow, or weekday plus date, according to the occurrence. |
| `%eventfaction%` | Full faction name for the occurrence's configured rotation. |

Example: `Council orders: bring your sparkle! Our %eventfaction% PvP crew gathers %eventwhen% at %eventtime%.`

Event substitutions require an event schedule for the command/guild. Ordinary messages can also use the existing literal date/time countdown parser; a bare On Demand repeat does not create an event anchor. `%eventwhen%` describes the event's calendar day; it is not itself an hourly countdown. Supported event-time substitutions receive the countdown calculated directly from the occurrence's UTC timestamp. The fixed text and explicit event identity remain important for incoming matching.

## Other players' announcements and cooldowns

The addon monitors incoming messages even when your command is stopped or paused. It ignores your own messages. Guild and Officer announcements must arrive in that same channel for the same guild; Zone announcements must arrive in Zone chat; Group announcements must arrive in Group chat. Group chat has no guild identity, so matching applies only to matching templates configured for Group output. When a recognized template matches, the entire command + guild is recorded as used, and a random 30–90 seconds is added to its cooldown to stagger users.

Matching tolerates supported substitution values, formatting, spacing, and generated countdown annotations such as `(~23h)`. It does not accept arbitrary word changes or typos as a general fuzzy match. Unchecked phase messages are still saved templates available for monitoring; excluding one from your delivery pool does not delete it. A match does not enable a stopped command or unpause a schedule.

## Startup delay, chat protection, and status

On each addon load/UI reload, scheduled activity waits **three minutes**. After you confirm a scheduled send, other command + guild schedules wait **five minutes**. Another scheduled send extends spacing for the other combinations; the sender keeps its own interval, including intervals shorter than five minutes. Ordinary On Demand/Startup commands do not use the scheduled startup delay.

Busy chat input is protected. The addon does not overwrite what you type. Local messages announce addon startup, schedule starts/ends, phase changes, and cooldown skips through `CHAT_SYSTEM:AddMessage`; these notices are only for you.

The status window has collapsible Auto and Repeat Commands sections. Empty sections collapse. Scheduled cards appear only within their current eligible window. Cards show the type, event countdown, current phase and effective delivery frequency, promotion start/end, channel, and last sent time. **Next Send** appears only while Active. The button shows the next action and cycles **Enable → Pause → Disable → Enable**. Paused and Inactive cards retain their configurations.

Ordinary repeating commands appear after you launch them and can be paused/resumed from their cards. Once disabled, launch their slash command to start them again.

## Export, import, and personal messages

Use **Import / Export Settings** for full settings transfer. It includes command names, messages, channels, Run At, Open Status Panel on Run, Notify Sound, ordinary repeat/retry/zone settings, schedules, recurrence, phase assignments/intervals/once choices, Starting soon, faction order/frequency, month-final groups, global timezone, per-guild timezone defaults, and status-panel preferences. Guild defaults are identified by guild name, not the receiver's guild-slot number. Older exports without guild choices use the exported global timezone (or Eastern for older exports without any timezone). Import is a replacement operation; back up first. Saved last-used times and per-zone send history are included; pending chat buffers, session startup holds, shared spacing, and schedule retry/once runtime markers are not transferred.

**Lock** keeps a message personal: locked messages are omitted from exports and preserved through imports when their parent command still exists, even if the imported same-name command has a different ID. Their personal phase/group assignments are retained. If the parent command no longer exists after import, those messages are removed too. A Locked indicator identifies them. Locking affects transfer, not sending or incoming detection.

## Quick test

Create a dedicated test command and one message, choose your guild and output channel, and set Run At to Scheduled. For a simple test, set an event 15 minutes ahead and a period starting now and stopping at the event, with a five-minute Repeat Frequency. Save and activate. Wait for the three-minute startup hold if you just loaded the addon, leave chat input empty, and watch `/scm status`. Press Enter when a message is prepared. A housing zone is convenient for a Zone test; use guild chat when testing guild-channel matching.

`/scm resetcooldowns` clears existing cooldowns for testing, including once-completion deadlines. It preserves schedule dates, paused/disabled states, and the startup delay. Other schedules' spacing is also reset. A future or expired schedule remains future or expired; resetting cooldowns does not move its dates.

When you select **Scheduled**, **Event date and time** opens automatically so the event date and time are visible. You can collapse it yourself; ordinary settings refreshes keep that choice. Selecting a different event configuration opens its timing section again.

## Multiple event deadlines and countdowns

Use `%eventtime%` for the event clock time and `%eventcountdown%` for its remaining duration. Add an offset to either token using a whole number of minutes (`m`), hours (`h`), or days (`d`): `%eventtime-30m%`, `%eventtime-2h%`, `%eventcountdown-3h%`, `%eventcountdown-1d%`, or `%eventtime+30m%`. Tokens are case-insensitive. Offsets are elapsed durations: `-1d` is exactly 24 hours, including across DST. The offset time is displayed in the guild scheduling timezone using the abbreviation applicable to that instant.

For an 8 PM raffle whose ticket sales close at 7 PM, use:

`The raffle is %eventwhen% at %eventtime% (%eventcountdown%). Ticket sales close at %eventtime-1h% (%eventcountdown-1h%).`

At 5 PM this reads: **The raffle is today at 08:00 PM EDT (3h). Ticket sales close at 07:00 PM EDT (2h).** The two countdowns use the same scheduled occurrence and clock, including local phase previews. Each is formatted as a compact duration, `soon` when very close, `now` at the deadline, or `passed` after it. Put parentheses in the template if you want them.

When any valid explicit `%eventcountdown%` token is present, automatic embedded-time countdown insertion is suppressed for the entire message to avoid duplicate or misplaced countdowns. Templates without explicit countdowns keep their existing automatic behavior; an offset event time receives a countdown to that offset deadline. Unknown/malformed tokens remain literal. Event tokens require a schedule for the command/guild. Incoming matching accepts changing explicit countdowns but still requires the event and offset clock times to match. Full export/import preserves these templates without any additional configuration.

For the raffle, set **Starting soon begins** to **60 minutes**. Include ticket-sales messages in Before event day and On event day, and use sales-closed messages in Starting soon. Under After event starts, set Promote after start to 0 to stop at the drawing time. For an ongoing activity such as PvP, use a positive duration and messages such as "We're already in Cyrodiil; come join us!" in After event starts. Existing Until end selections are retained under this clearer phase name. Changing the duration to 0 keeps those selections saved for later, but they cannot run until the duration is positive again. Zero is included in full import/export. A midnight event with 0 promotion days and 0 post-start minutes has no promotion time and must use an earlier promotion start or a positive post-start duration.

## Cooldowns when an event phase changes

When an event enters a new phase, announcements sent or observed in the previous phase no longer delay its first message. This applies to repeat, peer-message and zone cooldowns and also works after a UI reload. New observations or sends in the current phase start normal cooldowns. Last-send history is preserved; once-per-phase completion remains independent for each phase. Startup delay, spacing between different schedules, busy-input protection and ordinary On Demand cooldowns retain their behavior.

## Sharing settings with different guild-slot orders

New full exports start with `SCM_EXPORT_V2` and identify guilds by name. The recipient can have the same guild in a different slot: a sender's Alphabet Mafia in slot 1 can become the recipient's slot 3. The default guild, message association, guild/officer output, last-used command guild parameters, schedules, active zone selection and guild timezone settings follow the matching name.

Standalone `/g1` and `/o1` references inside saved message text are stored as named references in the export and restored to the recipient's appropriate `/gN` or `/oN`. Other channel references such as Group `/g`, URLs and longer numbers such as `/g10` are left unchanged. The named reference encoding is internal to the export; write normal message text in settings.

If the recipient does not belong to a referenced guild, that record is skipped. Local chat reports its record type, command/message details and missing guild name. If a message mentions a second guild whose channel cannot be resolved, the message is skipped rather than redirected to another guild. Other valid records continue importing. Global command definitions have no guild slot and remain available. Existing personal locks keep their usual protection while their parent command exists.

Older `SCM_EXPORT_V1` files remain readable. Where a named record identifies the sender's slot, it is mapped to the recipient's slot. A legacy slot-only reference with no reliable source guild name is skipped and explained in chat; it is never assumed to mean the recipient's same numbered slot. For best results, re-export using the updated addon. Both players need an addon version that supports V2 to exchange new exports. Import still replaces unlocked settings, so keep a backup first.

## Restore a message that timed out

Use **`/scm retry`** after an announcement disappears because it timed out before you pressed Enter. The timeout notification also tells you this command. It restores the same saved message to its original output channel and recalculates substitutions/countdowns for the current time. Press Enter to send; restoring alone does not mark it used or sent.

Only the most recent expired message can be retried. Recovery is retained when the timeout clears unchanged text **or when the chat input is already empty when the timeout fires**. A nonempty edited draft is preserved instead and is not stored for recovery. The recovery is session-only and ends on UI reload/logout. A newer recoverable timeout replaces it; a matching confirmed send consumes it.

Retry leaves typed chat and existing pending messages alone. It explains if the command/guild or message is gone, the scheduled window has ended, the schedule is paused, the message is excluded from the current phase, or another announcement was used after the timeout. Current startup/shared pacing and incoming-message cooldown protections still apply. The command does not revive completed startup-queue actions or reset cooldowns. It can restore an unsent timed-out scheduled message before its automatic retry interval.

Faction frequency is under **Scheduling > Faction rotation > Faction frequency (weeks)**. The section is enabled only for a repeating **Promote an event** schedule with **Special event pattern = Faction rotation**. For weekly PvP with four weeks per faction, choose Weekly, set Custom repeat interval to 1, and Faction frequency to 4.

## Automatically revealed settings

When a setting makes another section relevant, that section opens automatically. This includes selecting Scheduled in Run At, changing the schedule type, selecting Faction rotation, choosing a repeating schedule with weekday options, enabling Starting soon, and revealing message group choices in the phase lists. Enclosing sections open as needed so the newly relevant controls are visible.

You can collapse any section afterward. Ordinary refreshes, message edits, and saves preserve that choice. Switching to a different command/guild reveals its relevant settings again. Selecting another option and then returning to a previously disabled section opens it again. Sections that remain irrelevant stay disabled through the normal settings behavior.

## Order of ready schedules and once-only reminders

When several scheduled combinations are ready, their initial queue order is shuffled. Waiting requests retain that order across scheduler ticks; manual requests keep priority over automatic ones. Chat protection, per-command intervals, and the five-minute pause between different schedules still apply.

Prepare only once completes after a **confirmed send** or a matching announcement from another player during the phase. Merely placing text in chat does not complete it. An unsent message may retry after its timeout delay while the same phase and occurrence remain eligible. A set-time reminder still expires after its two-minute eligibility window; missed occurrences are not queued as a backlog.


VERSION 2.1.0 REMINDER TIMELINES
See SmartChatMsg_Help_Guide_v2.1.0.html for the full timeline and web editor guide. Configure the actual event once, then add repeat windows or once-only milestones. Time-sensitive milestones bypass ordinary cooldown/pacing but retain startup hold, peer duplicate protection and your typed chat. Test each row with simulated time inside its window. Named important time tickets supports %eventwhen:tickets%, %eventdate:tickets%, %eventtime:tickets% and %eventcountdown:tickets%. Existing schedules remain usable without conversion. Review helper consolidation before saving.


### Enabled messages for On Demand and Startup

In ordinary message rows, the Enabled checkbox includes or excludes a template from On Demand, Startup, ordinary repeat and Zone selection. Disabled text stays stored and can still be previewed. Retry cannot restore a disabled template. If none are enabled, no message is prepared. Disabling untouched prepared text withdraws it while preserving player edits.

Scheduled phases and reminder rows keep their own message pools and ignore these ordinary flags; returning to ordinary mode restores the selections. Incoming peer matching still recognizes disabled templates. SavedVariables and full settings import/export preserve the flags by guild name and message UUID. Identical text with different UUIDs remains distinct, and local locked templates retain private choices.
