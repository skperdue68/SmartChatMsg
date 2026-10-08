# Simple scheduling Implementation Plan
> For agentic workers: use superpowers:subagent-driven-development.
Goal: implement approved simple scheduling and recurrence UI with DatePicker.
Architecture: existing schedule config stays authoritative; calendar occurrence projection feeds state, queue validation, deadlines and event substitutions. Settings owns editable draft and friendly controls. Keep old EVENT config backward compatible.
Tech stack: ESO Lua 5.1, LibAddonMenu 2.0, LibAddonMenuDatePicker.
Spec: ../specs/2026-10-08-simple-scheduling.md
Global constraints: all displayed dates ET, no raw epoch; no automatic send without Enter; no offline backlog; preserve import/export, peer cooldown and typed input.
Review focus: DST/missing month days; stale callbacks between occurrences; legacy settings migration; DatePicker calendar day shifting by timezone; phase random eligibility with multiple selected messages.
Task 1 Engine: SCM_Calendar.lua, SCM_Recurrence.lua new, SCM_Schedules.lua, SCM_Scheduler.lua, SCM_SavedVars.lua only export routing if needed; tests/recurrence_spec.lua. Expose NormalizeSchedule(data), GetScheduleOccurrence(schedule,utc), GetUpcomingScheduleOccurrences(schedule,utc,count), same public existing scheduler methods; modes WINDOW/REMINDER/EVENT, recurrence NONE/DAILY/WEEKLY/BIWEEKLY/MONTHLY_DATE/MONTHLY_WEEKDAY with recurrenceInterval and weekdays map (Lua weekday 1=Sunday), promotionDays/endDelayMinutes, phaseOnce map. Preserve stored anchor dates. Write failing tests, implement recurrence/phase projection, test old and new suites, self-review.
Task 2 UI: SCM_ScheduleSettings.lua, tests/simple_schedule_ui_spec.lua. Replace dense form with schedule kind/DatePicker/time/recurrence and optional submenus. Use engine data contract above, checklist phase pools, human dates, preview. Inspect DatePicker source then date-carrier bridge, test callback roundtrips including legacy reload, self-review.
Task 3 Integration: SmartChatMsg.txt dependency/new module load; README.md/docs help changes. Review tasks for correctness, run Lua 5.1 suites, repair any failures, inspect PR diff and open one PR targeting main for user test. Package addon ZIP and brief test instructions if feasible.
- [x] Engine tests/implementation
- [x] UI tests/implementation
- [x] Review/integration/tests
- [ ] Push branch/open PR

Rulings: preserve legacy exact event windows until promotion offsets are edited; reminder eligibility is two minutes, without offline replay; recurrence projection keeps ET wall time and skips missing dates/times. Passive peer observations delay later manual/startup activation. Local notices announce transitions and cooldown deadlines once per change. DatePicker v7 upstream manifest requires LAM >=34; dependency floor adjusted to34.
