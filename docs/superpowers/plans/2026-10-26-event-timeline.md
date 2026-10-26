# Event Timeline Implementation Plan

> Execute with superpowers:executing-plans, retaining a work ledger.

**Goal:** One real event with flexible reminders in ESO and a matching standalone Node editor.
**Architecture:** Additive versioned event timeline on existing schedules; shared documented JSON-compatible field contract in both repositories. Keep legacy execution available during migration. Web parses Lua as data and preserves runtime fields.
**Tech Stack:** ESO Lua 5.1, LibAddonMenu, Node built-in HTTP and test modules, browser JavaScript.
**Spec:** ../specs/2026-10-26-event-timeline-design.md

## Global constraints
Preserve IDs, account data, cooldowns and locks. No live file writes. Full in-game parity. New app repository SmartChatMsg-Web with Node server. Time-sensitive still requires Enter. No inferred legacy grouping without review.

## Tasks
- [x] Baseline tests; establish isolated addon branch and standalone web repository.
- [x] Define and test timeline normalization, anchors, recurrence and named-time contract.
- [x] Implement delivery selection, row cooldown state, priority and expiry; exercise confirmed/unsent/peer cases.
- [x] Add addon timeline cards/editor, message selection, preview and status; keep legacy settings supported.
- [x] Implement safe Lua reader/writer, account selection and three-way configuration merge with runtime preservation.
- [x] Add local Node server and event editor matching mockup, reminders and message editor.
- [x] Add week/month overview and projections using actual event anchors with DST-aware local clocks.
- [x] Add reviewable legacy consolidation and portable addon import/export.
- [x] Run complete Lua/Node suites, browser visual QA, documentation, final review and submit separate PRs.

## Review focus
Legacy schedules without timeline; DST change weeks; import into a different guild slot; stale snapshots containing newer cooldowns; delayed milestone when user chat is busy.

## Implementation record

Implemented additive timeline version 1 in SCM_Timeline.lua, in-game editor in SCM_TimelineSettings.lua, preservation/consolidation and transfer in SCM_TimelineTransfer.lua. Matching accepts recognized recent day wording and changing countdowns; named important times support date/day/time/countdown tokens. Queue ties randomize by eligible batch while older queued work stays ahead of newly due repeats. Status cards show days and local-clock eligibility times.

SmartChatMsg-Web is a separate private Node repository with a local loopback server, branded editor, calendar, safe Lua parser and three-way configuration merge. Migration is explicit and validates latest runtime before download.

Verification: 44 Lua spec files, 39 Node unit tests, durable browser workflow tests and actual addon normalization of all 31 converted schedules from the supplied file passed. Independent reviews identified and drove fixes for timeout retries, source-time collisions, once-row ties, validation, cross-guild message isolation, numeric weekday keys, monthly cadence and latest-snapshot completion migration. No live ESO UI smoke test was available. PR submission follows final commits.

Final review follow-ups: latest-snapshot migration remaps new completion identities; month patterns cannot lose occurrences; repeated helper combines retain independent named times; same-start once rows cannot starve; technical WINDOW parent anchors and message offsets are preserved; full event previews and lossless Lua UTF-8/raw-byte serialization verified.
