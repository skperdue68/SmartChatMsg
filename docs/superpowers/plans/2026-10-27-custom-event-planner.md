# Custom ESO Event Planner Implementation Plan

**Goal:** Build the approved three-column ESO planner alongside the existing settings.
**Architecture:** Native XML window shell, Lua controls/view and an isolated draft controller. Reuse the existing normalization, recurrence, parser, cooldown and scheduler APIs. /scm schedule opens the new window; /scm retains existing settings.
**Spec:** Approved rendering in this conversation: events left, periods middle, selected settings/messages right, preview, Save/Cancel, resizable and position persistence.

## Tasks
- [x] Controller tests first: six stable-ID periods, private drafts, Cancel, validated saves, current cooldown/usage preservation, simulated previews, message selections and shared guild/channel context.
- [x] Implement SCM_PlannerModel.lua with validation and existing scheduler integration; no migration or new schedule format.
- [x] Native XML shell plus SCM_PlannerControls.lua and SCM_PlannerWindow.lua: responsive three columns, searchable events, period cards, event/period/library tabs, inline validation, date calendar/time selection, sliders, checkboxes, message previews. Existing settings remains accessible for advanced editing and import/export.
- [x] UI callback tests with native control doubles; manifest XML parse and release packaging checks.
- [x] Add /scm schedule entry and settings-launch button, docs. Run all specs, review diff, commit/push PR.

## Constraints and rulings
- Preserve all settings not edited here, message IDs, cooldowns and live send/peer usage. Saving must merge current runtime state, not restore a stale snapshot.
- Closing, selecting another event/guild and opening existing settings must guard unsaved changes with an in-window discard/cancel confirmation.
- Existing advanced settings remain available; do not remove the existing interface.
- Use existing dependencies only. Native calendar controls avoid assumptions about embedding private DatePicker internals.
- All clocks use the selected guild scheduling timezone, never the operating system local zone.
- Keep active event/period IDs stable when sorting; retain all message pools and patterns.

## Verification ledger
Design approved by user. Plan execution is inline; no parallel implementers.

Implementation and 66 Lua specs pass. Native-control callback test covers all six period cards, tabs, draft edits, Save/Cancel, calendar Cancel, geometry and command launch. Review corrected shared daily-limit capture/display; regression test failed before and passes after the fix. Native slider mouse input is explicitly enabled. XML parses; manifest paths exist; release ZIP verified. ESO in-game visual validation remains required.

Ruling: Keep advanced patterns, named important times, recurrence cancellation, availability overrides and import/export in Existing settings for this first optional window. The new window preserves those fields unchanged and links to the old editor with an unsaved-draft guard. This avoids a second implementation of advanced semantics while evaluating the new native layout.
