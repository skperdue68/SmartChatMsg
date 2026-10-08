# Event Scheduling Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for inline implementation, followed by one independent whole-branch review.

**Goal:** Activate and stop configured event reminders within Eastern Time windows, using event-relative saved-message phases.

**Architecture:** A pure calendar module resolves Eastern civil times into UTC. A scheduler owns bounded delivery and a shared chat-population queue; existing sending, cooldown, and message rotation remain the execution layer. A LibAddonMenu settings submenu edits the selected command/guild schedule.

**Tech Stack:** ESO Lua 5.1, LibAddonMenu-2.0, native ESO events; no new addon dependencies.

**Spec:** [Merged scheduling proposal](../../scheduling-proposal.md).

## Global constraints

- One event window per Command + Guild; one enabled scheduled Zone combination.
- Start inclusive, end exclusive; no posting or backlog while offline.
- Eastern offset resolved for the target date, independently of the computer timezone.
- Explicit manual `off` persists a pause; stopped, paused, and finished jobs cannot be restarted by peers.
- Preserve edited chat input and On Demand/Startup behavior.
- Valid phases: Any, Before event day, Event day before start, Event underway.

## Review focus

- DST gaps/folds must reject or require an explicit EST/EDT choice (Task 1).
- Loading stalls and clock changes must not deliver outside the window (Task 3).
- Queue items invalidated by edits, imports, or phase changes must be discarded (Tasks 2–3).
- Peer use during a pending send must defer without unpausing or bypassing the end (Task 3).
- Existing settings imports and message deletion must not select another phase by accident (Tasks 2–4).

### Task 1: Eastern civil-time conversion

**Files:** Create `SCM_Calendar.lua`; test `tests/calendar_spec.lua`.

**Interfaces:** `ParseEasternDateTime(date, time, fold) -> utc|nil, error`; `GetEasternParts(utc) -> table`; `FormatEasternDateTime(utc) -> string`; `GetSchedulePhase(schedule, utc) -> BEFORE|DAY|LIVE`.

- [x] Write literal UTC fixtures for winter/summer, leap dates, March gaps, November folds, and Eastern midnight phases.
- [x] Run the Lua 5.1 test and observe missing conversion failures.
- [x] Implement Gregorian calendar arithmetic and US Eastern rules for 2007–2099 without local `os.time`/DST assumptions.
- [x] Run calendar tests and existing incoming-chat suite; commit the tested unit.

### Task 2: Schedule configuration and persistence

**Files:** Create `SCM_Schedules.lua`; modify `SCM_SavedVars.lua`, manifest; test `tests/schedules_spec.lua`.

**Interfaces:** `NormalizeSchedule(data) -> schedule|nil`; `SaveGuildSchedule(commandId,guildName,draft) -> ok,error`; `GetGuildSchedule(...) -> schedule|nil`; `GetGuildScheduleState(...,utc) -> state,phase`; `ExportScheduleRecords() -> lines`; `ImportScheduleRecord(parts,imported)`.

- [x] Test invalid ordering, disabled/missing schedules, reload/round-trip, single Zone owner, persisted pause, phase assignments, and old V1 imports.
- [x] Observe failures; implement validated data and backward-compatible additive V1 schedule records.
- [x] Integrate SavedVariables cleanup and import/export; run both suites plus incoming regression checks; commit.

### Task 3: Runtime, population queue, and peer coordination

**Files:** Create `SCM_Scheduler.lua`; modify `SmartChatMsg.lua`, `SCM_IncomingChat.lua`; extend `tests/schedules_spec.lua`.

**Interfaces:** `TickSchedules()`, `InitializeScheduler()`, `QueueChatPopulation(...)`, `ProcessChatPopulationQueue()`, `PauseGuildSchedule(...)`, `ResumeGuildSchedule(...)`, `ScheduleNextScheduledDelivery(...)`, `HandleScheduledPopulateTimeout(metadata)`.

- [x] Test starts/ends, phase filtering, no offline backlog, paused reload, multiple repeats, manual priority, busy/edited input, stale queue entries, peer delays, expiration, and Zone conflict.
- [x] Observe failures; implement a one-second scheduler with window checks before every delivery and a deduplicated shared queue.
- [x] Wire existing repeat/zone/manual/startup/populate/watchers into scheduled ownership without activating inactive schedules.
- [x] Add schedule-derived event tokens and typed incoming matching; test differing countdowns while retaining event identity.
- [x] Run all suites, inspect owned-timer cleanup and regression behavior; commit.

### Task 4: Settings, status, and testing instructions

**Files:** Create `SCM_ScheduleSettings.lua`; modify `SCM_Settings.lua`, `SmartChatMsg.lua`, `README.md`; create `docs/scheduling-testing.md`.

**Interfaces:** `BuildScheduleOptionControls()`, `GetScheduleEditorDraft()`, `GetScheduleStatusText(...)`.

- [x] Test saved settings callbacks through a LibAddonMenu fixture, transactional Save, phase assignments, Pause/Resume, and invalid fields remaining editable.
- [x] Observe failures; build the Eastern start/event/end editor, fold choices, delivery mode, interval/phase assignment fields, and visible status.
- [x] Add entry points from Run At settings and `/scm schedule`; document exact install files, safe two-player trial, and limitations.
- [x] Run all Lua tests and `git diff --check`; request independent review, repair findings with regression checks, then open a scheduling implementation PR.

## Execution record

- Baseline: merged `Add-Countdown-Substitution` at `c6d1a35d3bb0fca8f8b300b7e0a4b08062973f45`; existing 33 Lua 5.1 checks pass.
- Authorization: user merged the scheduling design and asked to continue; implement inline.

- Completed calendar, persistence, runtime queue, phase/event tokens, editor, live status, and trial documentation.
- Independent review findings repaired with regressions: stale Zone requests, edited-input timeout ownership, startup priority/discard ownership, malformed imports, exact eventwhen identity, and saved-editor callbacks.
- Final checks: 12 calendar checks, 33 incoming checks, 31 scheduling checks under Lua 5.1; whitespace validation. Real ESO UI/two-player checks remain documented manual validation.
- UI integration uses the existing settings panel submenu instead of creating another panel. `/scm schedule` opens the existing panel.
