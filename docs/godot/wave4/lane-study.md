# Lane: study — why does our build not feel like XCOM 2?
Read WAVE4.md first; its rules apply. Branch: wave4/study. Reasoning lane, no gameplay code.

FILE LEASE: `docs/godot/wave4/FEEL-GAP.md`, `docs/godot/wave4/study-REPORT.md`, `docs/godot/shots/wave4-study-*.png`, throwaway scripts under `/tmp/` only.

Goal: a precise, evidence-backed gap list between XCOM 2 WotC and our Godot build, for the next wave.
1. Dig into the XCOM 2 configs for feel: action/camera timings, move/dash ranges, aim/crit/flank/height numbers, overwatch, pod activation and scamper, enemy turn pacing, UI flow (select → preview → confirm), what the player sees before every shot. Cite file + key for each number.
2. Run our build (tests, demo mode, capture scripts) and measure: clicks per turn, seconds per action and per enemy turn, camera blend times, dead time, what info is missing at decision moments, map shape (routes, flanks, high ground, entry directions).
3. Write FEEL-GAP.md: top 15 gaps ranked by how much they hurt feel, each with XCOM evidence, our current behavior (with file:function), and a concrete fix sized S/M/L. Mark each claim "verified" or "inferred".
