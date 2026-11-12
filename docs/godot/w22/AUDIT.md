# W22 Audit: Battle feel (lane tw-w22-audit)

Main repo: /home/jess/projects/temple-watch, at HEAD 81c7644 (W21 shipped). This lane is **read-only for game code**:
- no edits under godot/, tools/, or docs/ (except new files in docs/godot/w22/)
- no commits to game files, and no push, merge or tag
- no subagents

## Goal
Jess picked **Battle feel** for Wave 22 (ask-bc527bfc). Measure how a turn of combat FEELS on a phone and compare it beat by beat with XCOM 2. The output feeds 3–5 parallel fix lanes.

## Setup
Run `godot --headless --import` first. The binary is /home/jess/projects/.tools/godot/godot. Capture at 844x390 (phone landscape), Compatibility/Low. Also check 1366x768. Use the first mission (defend the Temple gate) plus 2 other maps. Drive them with the rescue bot or scripted inputs.

## Steps
1. **Turn timeline.** Record one full player turn and one full enemy turn as frame sequences or short clips. Log the time of each beat:
   - select unit
   - move preview
   - move
   - aim open
   - hit-chance shown
   - fire
   - projectile/saber
   - impact
   - damage number
   - death
   - camera return
   - next unit
   - enemy turn start/end

   Flag dead time over 0.5 s, beats that skip feedback, and enemy turns that feel slow or invisible (does the camera follow enemy moves and shots?).
2. **Hit and kill punch.** For blaster hit, blaster miss, saber strike, Force push, grenade/explosion, crit, and kill, list what happens:
   - hit-stop/freeze frames
   - camera shake
   - flash/rim light
   - knockback or reaction animation
   - ragdoll/death anim
   - particles, decals, sound
   - damage number style
   - slow-mo or kill-cam

   Mark anything missing or weak. Name the files that do each (combat_scene, cam_combat, fx files, unit_view, audio).
3. **Aim and decide.** Look at the aim view (W13/W19 aim cam):
   - Is the hit % big and clear?
   - Are the reasons for the % shown (cover, flank, height)?
   - Does a flanked enemy show it (XCOM yellow/red shield)?
   - Are cover shields on move tiles readable on the phone?
   - Is Overwatch visible?
   - Is the danger zone/enemy line of sight shown before moving?
4. **Movement feel.** Look at:
   - path preview line
   - blue/yellow (1-action vs 2-action) range split
   - run/vault animation
   - camera follow speed
   - footstep/dust feedback
   - whether the unit snaps or slides
5. **Audio.** Inventory the sound effects and music in battle: what exists, what's silent (saber hum/clash, blaster, impacts, UI clicks, enemy alert, kill sting, mission music).
6. **Enemy reveal and threat.** XCOM's "pod reveal" camera beat, enemy alert, the villain intro. Do enemies telegraph? Does the player know what will happen at End Turn?
7. **Performance.** Record fps during heavy moments (explosion, multi-unit enemy turn) at Low. Note any hitch over 50 ms.
8. **XCOM 2 notes.** Use docs/XCOM2-STUDY.md, the existing tw-reference/ shots and W12–W21 GAPS files. For each beat above, write 2–3 lines on how XCOM 2 does it. Port mechanics only.

## Output
- Captures go to /home/jess/projects/tw-logs/w22/audit/. Capture scripts go in /home/jess/projects/tw-logs/w22/audit/scripts/.
- Make one contact sheet at /home/jess/projects/tw-logs/w22/audit/2026-11-10-audit-sheet.jpg, with at most 8 panels. It stays outside the repo.
- Write the report to /home/jess/projects/tw-logs/w22/audit/AUDIT-REPORT.md. It needs:
  - the turn timeline table (with times)
  - the hit/kill punch table
  - the audio inventory
  - the top 15 feel problems, ranked by how much a player would notice them, each with cause, files and line ranges, proposed fix and size (S/M/L)
  - the XCOM notes
- End the report with a **proposed W22 lane split** of 3–5 lanes with disjoint file leases. List every file each lane may write. Name the test file each lane adds (e.g. `godot/tests/<lane>22_test.gd`). Mark shared files and say which lane owns each.
- Final message: report path, sheet path, top 5 problems in one line each, and the lane split.

## Boundaries
- Read-only game code, as above.
- Never commit XCOM images. Never print MESHY_KEY. Spend no Meshy credits.
- Do not delete or move untracked files in the repo.
