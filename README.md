# SmartChatMsg 3.0

ESO chat announcements, on demand or on a scheduled Period Timeline. SmartChatMsg prepares chat; press Enter to send.

- [Complete 3.0 user guide](docs/SmartChatMsg-3.0.md)
- [Standalone HTML help guide](SmartChatMsg_Help_Guide_v3.0.html)
- [Optional web companion](https://scm.perdues.me)

Requires ESO API 101051, LibAddonMenu-2.0 >=34 and LibAddonMenuDatePicker. LibDebugLogger is optional. Sliders are built into LibAddonMenu.

## Quick start

1. Install the SmartChatMsg folder into live/AddOns and enable its dependencies.
2. Open `/scm`, create a command, select its guild and output channel, and add messages.
3. Choose On Demand, Startup, or Scheduled. For Scheduled, configure the event and its periods, then Save and activate.
4. Press Enter when an announcement is prepared.

For easier planning, install and run the addon at least once, exit ESO fully, and open live/SavedVariables/SmartChatMsg.lua at https://scm.perdues.me. Apply edits, download updated Lua, and replace the saved file only while ESO is closed. Back up first.

## Version 3.0

Multiple periods per event provide different timing, frequencies and message pools. Includes recurrence, rotations/cancellations, named important times, time-sensitive one-time notices, availability hours, per-period or shared daily limits, incoming duplicate detection and readable status. See the guide for full settings, examples and screenshot capture placeholders.

Older schedule formats are not loaded or automatically converted. Preserve a backup before updating.


Native settings import merges commands/messages, retaining items absent from the import and recipient usage history. Matching events receive the imported timeline/settings. Web selective event bundles and native text exports use different transfer formats; see the guide before sharing.


## Optional native Event Planner

Use `/scm schedule` for the new resizable three-column ESO window: command/event list, period cards, and a wider editor with message previews. `/scm` retains the original settings as an alternate interface. The planner now includes Global settings, Guild settings, import/export and an Advanced tab. Drafts use Save/Cancel and preserve live cooldown/usage history. See the guide’s Custom ESO Event Planner section for the current scope and testing steps.

[Original/new ESO settings parity checklist](docs/ESO-Planner-Settings-Parity.md) documents every control and its location.
