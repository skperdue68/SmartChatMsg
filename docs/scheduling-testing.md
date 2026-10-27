# SmartChatMsg 3.0 scheduling checks

Use synthetic messages and a backup SavedVariables file. These manual checks complement the Lua specs; ESO UI and actual chat behavior need in-game verification.

1. Install every file listed in SmartChatMsg.txt and the required libraries. Confirm version 3.0 and API 101051, then open /scm.
2. Create On Demand and Startup combinations. Test Repeat Frequency, Retry Delay capped by both frequency/cooldown, Auto Populate Chat on Zone disabling repeat, enabled message pools, sound and status options. Verify the global pending-chat slider covers 30–300 seconds.
3. Create a Scheduled event with duration and several periods. Check calendars, server-time selectors, pool scrolling, adding/deleting messages and no settings overlap. Preview substitutions inside each period and save/reopen.
4. Without duration, after-start promotion must be disabled. With duration, test underway invitations and the closing-announcement exception. Confirm periods stop at the intended end.
5. Test Send once, lateness and time-sensitive notices. Preparing is not sending; expiration must not post a stale starting announcement. Confirm startup and ordinary inter-schedule spacing, protected player text and randomized eligible schedule selection.
6. Test Availability weekdays, overnight hours, date/weekday overrides and resets. Check per-period daily maximum, then Share Limit to ALL periods. Actual sends/peer matches count; preparation/timeouts do not. Reload and confirm usage persists. Verify status identifies period versus command limits.
7. Test weekly, biweekly and last-weekday monthly recurrence across DST. Verify guild timezone overrides and same-clock timezone changes. Repeat weekdays select event occurrences, not advertising days.
8. Check regular/month-final/all-event pools, regular fallback, faction rotations, activity rotations and Keep/Postpone cancellation behavior. Calendar important times must follow future event occurrences.
9. Export/import between clients with different guild-slot orders and command IDs. Confirm guild-name mapping, missing-guild explanations, all delivery settings and preserved recipient counters.
10. Prepare a message, let it time out and use /scm retry. Test /scm send with an eligible scheduled command. Inspect status card routing after active-first sorting and readable Next Send details.

The optional web companion is https://scm.perdues.me. Install/run the addon once and exit ESO before taking its SavedVariables snapshot. The native addon remains the execution engine.


Import merge checks: retain custom commands/messages absent from a partial import; repeat the import without duplicates; change donor IDs while keeping command names/text; confirm changed text with the same message ID updates that template; confirm recipient usage/cooldowns and per-period/shared caps remain. Inspect incoming timeline replacement for a matched event and verify retained unselected templates are not silently enabled.
