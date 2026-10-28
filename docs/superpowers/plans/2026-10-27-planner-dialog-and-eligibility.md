# Planner dialog and live eligibility

Approved scope: fix the Guild settings dialog appearing in the launcher location after save; add a live eligibility countdown between Stops and frequency on the active period card.

- [x] Reproduced the button/dialog shared-key collision with a failing regression.
- [x] Separate the centered modal container; enforce consistent pooled control kinds.
- [x] Test live deadline scope, startup/pacing, disabled sending, quota, period-end and separate guild usage.
- [x] Render active-card eligibility on a separate measured line. Timer changes do not rebuild the editor; phase/card-height changes reflow only the sidebar with scroll anchors.
- [x] Verify opening, saving, reopening and cancelling Guild settings keeps launcher geometry and dialog child ownership intact.
- [x] Update guide; final review/package/PR checks.

Tests: 71 Lua spec files. Native font metrics and mouse/focus layout still need in-game verification.
