# SmartChatMsg 3.03

ESO chat announcements, on demand or on a scheduled Period Timeline. SmartChatMsg prepares chat; press Enter to send.

- [Complete 3.03 user guide](docs/SmartChatMsg-3.03.md)
- [Standalone HTML help guide](SmartChatMsg_Help_Guide_v3.03.html)
- [Optional web companion](https://scm.perdues.me)

Requires ESO API 101051, LibAddonMenu-2.0 >=34 and LibAddonMenuDatePicker. LibDebugLogger is optional. Sliders are built into LibAddonMenu.

## Quick start

1. Install the SmartChatMsg folder into live/AddOns and enable its dependencies.
2. Open `/scm`, create a command, select its guild and output channel, and add messages.
3. Choose On Demand, Startup, or Scheduled. For Scheduled, configure the event and its periods, then Save and activate.
4. Press Enter when an announcement is prepared.

For easier planning, install and run the addon at least once, exit ESO fully, and open live/SavedVariables/SmartChatMsg.lua at https://scm.perdues.me. Apply edits, download updated Lua, and replace the saved file only while ESO is closed. Back up first.

## Version 3.03

Multiple periods per event provide different timing, frequencies and message pools. Includes recurrence, rotations/cancellations, named important times, time-sensitive one-time notices, availability hours, per-period or shared daily limits, incoming duplicate detection and readable status. See the guide for full settings, examples and screenshot capture placeholders.

Older schedule formats are not loaded or automatically converted. Preserve a backup before updating.


Native settings import merges commands/messages, retaining items absent from the import and recipient usage history. Matching events receive the imported timeline/settings. Web selective event bundles and native text exports use different transfer formats; see the guide before sharing.


## Optional native Event Planner

Use `/scm schedule` for the new resizable three-column ESO window: command/event list, period cards, and a wider editor with message previews. `/scm` retains the original settings as an alternate interface. The planner now includes Global settings, Guild settings, import/export and an Advanced tab. Drafts use Save/Cancel and preserve live cooldown/usage history. See the guide’s Custom ESO Event Planner section for the current scope and testing steps.

[Original/new ESO settings parity checklist](docs/ESO-Planner-Settings-Parity.md) documents every control and its location.


Share cooldowns between Guild and Officer chat is an optional command/guild setting in /scm and /scm schedule Command Settings. It defaults off. When enabled, matching announcements from other players in either channel for the same guild reset that combination’s cooldown and normal usage counters, including scheduled usage. Output routing stays as selected; Zone and Group do not participate. Reading Officer announcements does not require permission to send there. Settings exports preserve this option; older exports leave it off.

Condensed dates and times now default on when a command/guild has no saved preference. An explicit false keeps long formatting, including through imports and planner saves. The web companion also provides password-required loading for protected configurations and message Lock/Unlock controls; locked messages can still be disabled in pools.

## Month-final occurrence labels

For a repeating Last event of month pattern, optional **Regular event label** and **Last event of month label** fields name the two occurrence types (up to 80 characters each). Use, for example, Bi-weekly raffle and Bi-weekly + 50/50. The custom planner exposes these in Advanced; the original scheduling settings expose them below Special event pattern. Labels do not change the message pools, event dates, or delivery rules. Blank labels retain the standard names. Full SavedVariables and native import/export preserve both labels, including files edited by the web companion.

The web sidebar shows the next scheduled occurrence date, not the original recurrence anchor. It adds the selected faction, rotating activity, or regular/month-final label. The Event Date field still edits the recurrence anchor. Upcoming events shows the type for each listed date; past one-off events have no upcoming occurrence.

## Display names and slash-command names

Commands/events have a friendly **Display name** (1–80 characters, spaces and punctuation allowed) and a separate **Slash-command name** (1–25 letters/numbers). New entries derive the slash name from the display name until you customize it. For example, Sunday Fishing can use fftg. Editing the display name after customizing the slash name leaves fftg unchanged. Both editors remove invalid slash characters on leaving the field and before Save, updating the visible field even when validation blocks a reserved or duplicate name.

Existing command IDs, messages, schedules and usage are retained. Old files without displayName show their existing name; names with spaces retain the original as the display name while the slash identity is sanitized. Friendly names appear in the planner list, web sidebar and calendar. Scheduled entries keep a slash identity for matching/imports but still do not create runnable slash commands. Display-name changes apply to every guild using that command. Transfers carry both fields; merge matching uses the slash-command identity, not the cosmetic display name.
