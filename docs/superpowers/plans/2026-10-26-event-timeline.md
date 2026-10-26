# Event Timeline Implementation Plan

> Execute with superpowers:executing-plans, retaining a work ledger.

**Goal:** One real event with flexible reminders in ESO and a matching standalone Node editor.
**Architecture:** Additive versioned event timeline on existing schedules; shared documented JSON-compatible field contract in both repositories. Keep legacy execution available during migration. Web parses Lua as data and preserves runtime fields.
**Tech Stack:** ESO Lua 5.1, LibAddonMenu, Node built-in HTTP and test modules, browser JavaScript.
**Spec:** ../specs/2026-10-26-event-timeline-design.md

## Global constraints
Preserve IDs, account data, cooldowns and locks. No live file writes. Full in-game parity. New app repository SmartChatMsg-Web with Node server. Time-sensitive still requires Enter. No inferred legacy grouping without review.

## Tasks
- [ ] Baseline tests; establish isolated addon branch and standalone web repository.
- [ ] Define and test timeline normalization, anchors, recurrence and named-time contract.
- [ ] Implement delivery selection, row cooldown state, priority and expiry; exercise confirmed/unsent/peer cases.
- [ ] Add addon timeline cards/editor, message selection, preview and status; keep legacy settings supported.
- [ ] Implement safe Lua reader/writer, account selection and three-way configuration merge with runtime preservation.
- [ ] Add local Node server and event editor matching mockup, reminders and message editor.
- [ ] Add week/month overview and projections using actual event anchors with DST-aware local clocks.
- [ ] Add reviewable legacy consolidation and portable addon import/export.
- [ ] Run complete Lua/Node suites, browser visual QA, documentation, final review and submit separate PRs.

## Review focus
Legacy schedules without timeline; DST change weeks; import into a different guild slot; stale snapshots containing newer cooldowns; delayed milestone when user chat is busy.
