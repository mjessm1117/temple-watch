# W21 Audit: Menus & Temple (lane tw-w21-audit)

Main repo: /home/jess/projects/temple-watch, at HEAD b0eb42f (W20 shipped). This lane is **read-only for game code**:
- no edits under godot/, tools/, or docs/ (except new files in docs/godot/w21/)
- no commits to game files, and no push, merge or tag
- no subagents

## Goal
Jess picked **Menus & Temple** for Wave 21 (ask-97670432). Map every non-battle screen and compare each one to XCOM 2's Avenger and menu screens. The output feeds 3–5 parallel fix lanes.

## Setup
Work in the main repo, read-only. Run `godot --headless --import` first. The binary is /home/jess/projects/.tools/godot/godot. Capture at 844x390 (phone landscape) and 1366x768, Compatibility/Low, from a fresh save. Also capture a save that has finished mission 1 (rooms unlocked, roster grown).

## Steps
1. **Screen inventory.** Capture every non-battle screen:
   - title
   - settings
   - pause / in-battle menu
   - opening story
   - briefing
   - Temple home and each Temple room (training, armory/squad, research, infirmary, comms, whatever exists)
   - galaxy map and its drawer
   - hiring
   - promotion / rank-up
   - mission end / debrief
   - save/load
   - Sith/Shadow War panel
   - journal

   For each screen, record the scene/script files, how you got there (the click path), and how you get back.
2. **Flow.** Draw the navigation map, screen to screen. Flag the following:
   - dead ends
   - double-Back traps
   - screens reachable only one way
   - places where Back goes somewhere surprising
   - more than 3 taps to reach a common action (equip, research, launch mission)
3. **Temple home vs Avenger.** At 844x390:
   - What is the focal point, and how many labels/chips compete with it?
   - Room readability: can a player tell what each room does and whether it needs attention (badges)?
   - Does the Temple feel alive (staff, animation, light)?
   - Are the rooms 3D or flat?
   - Does tapping a room zoom into it, or does a flat panel pop over?

   Compare against the Avenger frames in /home/jess/projects/tw-reference/ (app268500-*, app593380-*, w20-side-by-side material, W20-GAPS.md item 4) and docs/XCOM2-STUDY.md.
4. **Menu look and consistency.** Across all screens, list where the following change for no reason:
   - fonts
   - colours
   - panel styles
   - button shapes
   - header bars

   Flag dim or low-contrast text (WCAG AA below 4.5:1), tofu boxes, clipped or overlapping text, and placeholder icons. Use the earlier tooling critique findings in /home/jess/projects/tw-logs/tooling/ (tap targets, dim labels) as a starting list. Re-check each finding and drop it if fixed.
5. **Tap targets.** At 844x390 and 390x844, measure every tappable control on the screens in step 1. Output a table that lists any control under 44 px, any overlap, and any control within 12 px of a screen edge.
6. **Juice.** Note screen transitions (cut, fade or slide), button press feedback, hover/press sounds, and idle motion. XCOM uses camera moves between Avenger rooms.
7. **XCOM 2 notes.** For each area below, write 2–3 lines on how XCOM 2 does it:
   - title
   - Avenger hub
   - room drill-in
   - armory
   - research
   - Geoscape drawer
   - debrief

   Port mechanics only. Never copy XCOM assets.

## Output
- PNG captures go to /home/jess/projects/tw-logs/w21/audit/. Capture scripts go in /home/jess/projects/tw-logs/w21/audit/scripts/.
- Make one contact sheet at /home/jess/projects/tw-logs/w21/audit/2026-11-10-audit-sheet.jpg, with at most 8 panels. Show our screens next to XCOM ones where useful. The sheet stays outside the repo.
- Write the report to /home/jess/projects/tw-logs/w21/audit/AUDIT-REPORT.md. It needs:
  - the screen inventory
  - the flow map
  - the top 15 problems, ranked by how much a player would notice them, each with cause, files and line ranges, proposed fix and size (S/M/L)
  - the tap-target table
  - the XCOM notes
- End the report with a **proposed W21 lane split** of 3–5 lanes with disjoint file leases. List every file each lane may write. Name the test file each lane adds (e.g. `godot/tests/<lane>21_test.gd`). Mark any file that two lanes would both need, and say which lane owns it.
- Final message: report path, sheet path, top 5 problems in one line each, and the lane split.

## Boundaries
- Read-only game code, as above.
- Never commit XCOM images. Never print MESHY_KEY. Spend no Meshy credits.
- Do not delete or move untracked files in the repo.
