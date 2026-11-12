# W24 Controls Audit (READ-ONLY)

Owner: temple-watch. Jess: "W24 = Battle feel continued" (ask-60b805b6), then in chat: "And controls!!"
Goal: measure how the game handles input on the PHONE (touch) and on PC (mouse and keyboard), compare it with XCOM 2 (PC and the iOS port), rank the gaps, and propose 2-3 fix lanes. No code changes.
A separate battle-feel audit (docs/godot/w24/AUDIT.md) runs at the same time and covers hit punch, pacing and the enemy turn. Do not repeat its work. Focus on INPUT.

## Setup
- Worktree: /home/jess/projects/tw-w24/controls-audit on a new branch w24/controls-audit off main aa19dd0.
- Same setup as docs/godot/w22/COMMON.md "Setup": rsync the untracked godot/assets and addons, then run `godot --headless --import`. The Godot binary is /home/jess/projects/.tools/godot/godot.
- Do NOT edit tracked game files. Probe and capture scripts may live in tw-logs/w24/controls/tools/.
- Outputs go ONLY to /home/jess/projects/tw-logs/w24/controls/.

## Read first
- tw-logs/w20/2026-11-09-jess-playtest-notes.md and tw-logs/w16/2026-11-06-jess-playtest-notes.md. They hold Jess's own control complaints: camera facing backwards, phone camera, buttons, can't end turn, mis-taps.
- input_controls.gd, cam_combat.gd, combat_targeting.gd, hud_phone*.gd, hud_controls.gd, battle12_aim.gd, plus any gesture/touch helpers. Map the full input path from the raw event to the action.
- tw-reference/ for the XCOM 2 refs. They are private and must never be copied into the repo. tw-reference/phone/ may be empty; if so, use XCOM 2 iOS control conventions as documented publicly, and cite them.

## Measure. Phone 390x844 portrait and 844x390 landscape, simulated touch. PC 1366x768, mouse + keys.
1. **Camera.**
   - Phone: one-finger drag pan, two-finger rotate, pinch zoom and double-tap.
   - PC: edge pan, WASD, Q/E rotate, wheel zoom, middle-drag.
   - Check for: snapping back, fighting the auto-follow, inverted axes, the camera facing the wrong way, how far zoom goes, and drag dead-zones.
   - Are drags that start on a unit, tile or button handled correctly? Pan vs select must be told apart.
2. **Select and cycle units.** Tap or click a unit. Tab and next-unit buttons. Does a unit get selected by accident while panning?
3. **Move.** Tap a tile, then preview, then confirm. Measure:
   - mis-tap rate on small or far tiles
   - whether the dash zone is clear
   - whether a confirm step is needed on the phone (XCOM iOS uses tap → path preview → tap again)
   - how cancel works
4. **Act.** Check the ability bar, choosing a target, cycling targets (swipe and arrows), confirm and cancel, and the back button or Esc. Count taps for each action and compare them to XCOM 2. Check the hotkeys 1-9, Enter, Esc, Tab, Y (overwatch), R (reload), H (hunker), End/Backspace (end turn), and say which exist.
5. **End turn.** How reachable and safe is it? Is there a mis-tap guard when units still have actions? Is there a confirm?
6. **Feedback on input.** Hover and press states, tap ripples, haptic (web vibrate), the cursor tile highlight, the disabled-button reason, and whether input locks during animations with no cue.
7. **Touch-target audit.** Every battle control must be at least 44 px with spacing. Check for overlapping hit areas, safe-area insets (notch and home bar), and iPhone Safari page rubber-banding during drags (OWNER rule 12).
8. **Input latency.** Measure the ms from tap to visual response, for select, move preview and the action bar, on Low.
9. **Settings.** Camera sensitivity, invert, edge-pan toggle, confirm-move toggle, and keybinding remap. Say which exist.

## Output
- CONTROLS-REPORT.md, under 160 lines:
  - **Top 12 control gaps,** ranked by player impact. For each: platform, repro steps, screenshot or clip file, XCOM 2 equivalent, cause (file:line), fix idea, and risk.
  - **Tap-count table:** ours vs XCOM 2 for move, shoot, ability, overwatch and end turn.
  - **Proposed 2-3 controls lanes,** with DISJOINT write leases (exact file lists), one test each (`<lane>24_test.gd`), and the gaps each one fixes.
  - **Overlap note:** list every file this report's lanes would write that a battle-feel lane might also want (input_controls, cam_combat, hud_phone, combat_targeting, battle12_aim). Suggest one owner for each.
- 2026-11-11-controls-audit-sheet.jpg: one JPG with 4-6 panels, ours vs the XCOM 2 ref. Keep it in tw-logs only.
- Final message: top 5 gaps, lane split, overlap note, sheet path.

## Boundaries
- The repo is read-only. No commits, no pushes, no Meshy calls.
- Never delete untracked files. No `git stash -u` / `git clean`.
- Never copy XCOM 2 images into the repo.
