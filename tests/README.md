# Regression tests

Run each `tests/*_spec.lua` from the repository root with Lua 5.1. Each spec loads the ESO fixture, which supplies mocked game APIs and loads the real addon manifest. The GitHub workflow runs every spec.

Tests cover the legacy scheduler, new timelines, priority/expiry, confirmation vs timeout, relevant peer suppression, safe validation, timezone/DST anchors, migration history, named times, portable guild import/export, locked messages, native settings controls and status layout.

These tests cannot verify the actual ESO renderer or game API restrictions. Before release, smoke-test the timeline cards, date picker, selected-row checklist, local notifications, protected chat edits and Enter confirmation inside ESO.

The optional Node editor has its own unit and browser suites in `skperdue68/SmartChatMsg-Web`. Both editors use timeline schema version 1; coordinate schema changes across repositories.
