# ESO settings parity audit

Audited against the current LibAddonMenu settings assembled by `SCM_Settings.lua`, `SCM_ScheduleSettings.lua`, `SCM_TimelineSettings.lua` and `SCM_Availability.lua`. This covers controls actually exposed by the current Period Timeline editor, not removed legacy modes or unused internal functions.

**Result: no known configuration control remains exclusive to the original settings. No control was omitted because of an ESO limitation.** The original settings are retained as an optional alternate interface.

| Original control or action | New planner location |
| --- | --- |
| Default guild, including clearing the default | Global settings dialog |
| Default scheduling timezone | Global settings dialog |
| Auto-remove pending chat timeout, 30–300 seconds | Global settings dialog, slider and exact entry |
| Create/select command | Events list and + Event; command name in Event/Command tab |
| Rename command | Event/Command tab name field, Save changes; ID retained across guilds |
| Delete command and its associated content | Event/Command tab, Delete command (all guilds), confirmation |
| Select message command, guild and output channel | Events list and top context controls; Guild/Officer/Zone/Group |
| Run At: On Demand, Startup, Scheduled | Event/Command tab |
| Ordinary Repeat Frequency, Retry Delay and Cooldown | Command tab, sliders and exact numbers; Retry capped at smaller active repeat/cooldown |
| Auto Populate Chat on Zone | Command tab; repeat/retry controls disabled when inapplicable |
| Open Status Panel on Run | Event/Command tab, all run types |
| Notify sound and sound Preview | Event/Command tab; saved custom sound retained |
| New message name/text and Add | Messages tab, + Message |
| Existing name/text, Update, Revert, Delete | Messages tab, Apply, Revert, Remove; live count and unsaved border |
| Message enablement for ordinary pool | Messages tab and ordinary pool checkboxes |
| Template test with substitutions | Messages and Period tabs, Test; simulated selected period for scheduled entries |
| Message membership/phase display | Messages tab, Used period labels; Period pool checkboxes |
| Guild timezone override or follow global | Guild settings dialog, top-right button |
| Event date, hour, minute, AM/PM | Event tab, calendar and server-time controls |
| Repeat schedule and interval | Event tab, recurrence and interval slider/exact entry |
| Monthly ordinal and weekday | Advanced tab, Monthly on and Weekday |
| Optional recurrence weekday selection | Advanced tab; these are occurrence days, not advertising days |
| Special pattern | Advanced tab; None, Faction rotation, Rotating event, Last event of month |
| Faction frequency and all three ordered faction selectors, optional unused slots | Advanced tab |
| Rotation activity frequency, add, select, rename, move up/down and remove | Advanced tab; stable activity IDs and reference guards |
| Cancellation occurrence, keep/postpone rotation, cancel and undo | Advanced tab |
| Earlier cancellation date and undo | Advanced tab, calendar selector |
| Important-time add/select/name/date/hour/minute/AM-PM/remove | Advanced tab, native calendar/time controls; stable token key displayed |
| Important-time substitution guidance | Advanced tab, eventwhen/eventdate/eventtime/eventcountdown named tokens |
| Event duration | Event tab |
| Select/add/remove period | Middle list and Period tab |
| Preview Period Timeline | Middle-column Preview timeline button |
| Period label and status, including pause | Period tab, Enabled and Paused controls |
| Period Starts and Stops date/hour/minute/AM-PM | Period tab, calendar and time controls |
| Allow promotion after event starts | Period tab, enabled with positive event duration |
| Closing announcement after event end | Period tab |
| Send once and once-anytime-in-window | Period tab |
| Repeat frequency and lateness allowance | Period tab; exact numeric entry, lateness 1–1440 minutes |
| Time-sensitive delivery | Period tab |
| Per-period daily limit and Share Limit to ALL periods | Period tab |
| Select period messages | Period tab, message checkboxes |
| Regular/month-final/all, faction/all-factions and activity/all-activities message groups | Period message cards and Messages tab |
| Availability enabled, allowed clocks and all seven announcement weekdays | Period tab |
| Weekday override selection, start/end and Reset | Period tab, Availability overrides |
| Date override selection, start/end and Reset | Period tab, Availability overrides |
| Current day count and override precedence guidance | Period tab |
| Save and activate / Save disabled | Event Enabled checkbox plus Save changes |
| Next event/upcoming occurrences | Event tab and middle summary |
| Import, Export and Clear text | Import / Export dialog; existing native merge transport |

## Presentation and save behavior

- The top Guild control selects an editing context. It does not set the default guild. The top clock describes the effective guild timezone; Global settings contains the account default.
- Event/period changes use the private draft and Save changes. Individual message Apply saves only that template's text/name, matching the original message Update scope; Revert restores that template. Pool, group and schedule changes still need Save changes. Root Cancel discards unapplied edits after confirmation.
- Global and Guild settings use their own Save/Cancel dialogs. Opening them guards pending event edits. Changes reuse the existing timezone APIs and refresh the event draft afterward.
- Import requires confirmation and uses the same merge API as the original settings; Export includes saved configuration. It asks you to save a pending event draft first. Selective web exports remain a separate web feature.
- Calendar/time widgets replace raw earlier-date text where appropriate. Numeric fields accept exact valid values as well as slider movement. Unsupported/invalid inputs never become saved strings or negative durations.
- The planner remains accessible without guild membership for command management and global settings. Guild-dependent delivery controls become available when a guild can be selected.
- Existing cooldowns, message usage and observed-chat history remain intact. No new schedule format, conversion step, library or dependency is introduced.

## Verification

Lua 5.1 regression coverage includes controller history preservation, native control callbacks, advanced draft mutations, important-time reference guards, rotation IDs, availability inheritance/reset, command renaming, individual Apply/Revert, disabled-field dependencies, exact numeric input, global/guild timezone refresh, no-guild access and the actual native export/import merge path. In-game visual/focus testing remains necessary because the native test doubles cannot render ESO controls.
