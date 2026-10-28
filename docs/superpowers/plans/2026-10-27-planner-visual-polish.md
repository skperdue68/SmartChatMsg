# Planner Visual Polish Implementation Plan

Approved design: latest charcoal/blue concept, readable native fonts, muted gold selection, teal frequency, native checkboxes/sliders, centered buttons. Retain all scheduling behavior and the existing settings.

- [x] Add failing native-control regressions for button label centering, native checkbox state toggles/disabled behavior, slim slider track/thumb, separate Starts/Stops/frequency controls, card sizing and active-vs-editing identity.
- [x] Apply shared theme and built-in font hierarchy in SCM_PlannerControls.lua. Use a dedicated centered label on buttons so control height changes stay centered.
- [x] Native checkbox virtual and native slider textures; preserve saved data and numeric behavior.
- [x] Period cards measure each text control, frequency on its own row; edited card selected background; current saved active period green indicator with tooltip and once-per-second indicator-only refresh.
- [x] Documentation, all specs, package validation, commit/push PR. ESO in-game visual verification required.

Verified 66 Lua spec files, including distinct editing/live activity, timer-only updates, disabled native checkbox handling, native thumb dimensions, centered labels and separate measured card lines. ESO appearance still requires an in-game check.
