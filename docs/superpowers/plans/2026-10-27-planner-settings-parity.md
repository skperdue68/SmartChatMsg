# Planner Settings Parity Implementation Plan

User requirement: every setting/action exposed by the existing ESO settings must be accessible directly within the custom planner. No fallback to old settings counts as parity. Retain original settings while evaluating the planner.

Architecture: native planner tabs and styled dialogs using existing shared normalization, recurrence, parsing, export/import and runtime APIs. Preserve live usage. Implement independent domains in separate files, then integrate and verify together.

- [x] Account/global dialog: default guild, default timezone, 30–300s chat-clear slider, transactional Save/Cancel, tooltips. Guild timezone directly in event settings. Styled text export/import/clear with merge confirmation and existing native transport.
- [x] Advanced event tab: monthly ordinal/weekday, recurrence weekdays, special patterns, faction frequency/order, rotating activities add/rename/reorder/remove, occurrence cancellation/undo including earlier dates, named important times date/time/add/remove with tokens.
- [x] Parent integration: command rename/delete; preview sound; availability weekday/date override/reset; message group selectors; once/late ranges, period pause/status and after-start permission; preview timeline, message revert/delete-selected equivalent where old actions exposed.
- [x] Audit checklist mapping every old control/action to a location. Test each independent domain and integrations with Lua 5.1 native doubles; preserve global/cooldown/live usages; build ZIP and push PR.

Constraints: no legacy schedule conversion; no added dependencies; do not send notifications to other people. All clocks use guild scheduling timezone. Save confirmation must not discard drafts. Existing UI style maintained; contextual fields hidden/disabled when irrelevant. General settings operations re-use timezone normalization atomically and refresh stale event drafts after applying timezone changes.

Implementation complete. The independent global/transfer and advanced domains were integrated with command rename/delete, guild timezone, availability overrides, message groups, individual Apply/Revert and exact numeric controls. Review caught and regression-tested Retry Delay enablement after Repeat changes. Native round-trip export/import, real timezone operations and no-guild global access are covered. No known old-only settings; see docs/ESO-Planner-Settings-Parity.md. Final package and all-suite checks follow.
