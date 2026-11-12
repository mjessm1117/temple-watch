# W24 Battle Feel Audit, part 2 (READ-ONLY)

Owner: temple-watch. Jess picked "W24 = Battle feel continued" (ask-60b805b6).
Goal: re-measure battle feel on main aa19dd0, after W22 (pacing, impacts, aim, threat) and W23 (look). Find what still falls short of XCOM 2. Rank the gaps, then propose 3-5 fix lanes with file leases that don't overlap. Change no code.

## Setup
- Worktree: /home/jess/projects/tw-w24/audit, on a new branch w24/audit off main aa19dd0.
- Set up the same way as docs/godot/w22/COMMON.md "Setup": rsync the untracked godot/assets and addons, then run `godot --headless --import`. The Godot binary is /home/jess/projects/.tools/godot/godot.
- Do NOT edit tracked game files. Capture and measure scripts can live in tw-logs/w24/audit/tools/, which is outside the repo.
- Write outputs ONLY to /home/jess/projects/tw-logs/w24/audit/.

## Read first
- docs/godot/w22/AUDIT.md: the method and the W22 baseline numbers. Re-use its measures so before/after can be compared.
- tw-logs/w22/ audit report, tw-reference/W22-GAPS.md and W23-GAPS.md: the open gaps.
- tw-logs/w20/2026-11-09-jess-playtest-notes.md: Jess's own complaints about camera, buttons and the phone.
- tw-reference/*.jpg: the XCOM 2 refs. They are private; never copy them into the repo.

## Measure (landscape 1280x720 AND portrait 390x844, on Low)
Use the gate defense map plus 2 other themes. Re-measure the W22 baseline numbers wherever they exist.
1. **Turn flow.** Measure:
   - taps and seconds from selecting a unit to the end of its action, for move, shoot, Force and overwatch
   - enemy-turn time
   - dead time with no feedback
   - camera moves per turn, and any snaps or whiplash
2. **Hit / miss / kill punch.** For each weapon type (blaster, saber, Force, grenade or blast), measure:
   - the time from the shot to the hit showing
   - hit-stop, camera impulse, sound and damage number
   - the death animation and the ragdoll or fall
   - Compare against the XCOM 2 shot-to-impact beat. Misses should read as misses, not as nothing happening.
3. **Aim and decide.** Check:
   - the hit-chance breakdown (cover, height, flank)
   - flank and cover shields shown before you commit
   - the move-path preview of danger, such as overwatch cones and enemies you will reveal
   - the cancel/undo flow
4. **Movement.** Check:
   - path smoothness
   - vaulting, climbing and doors
   - Jedi leap or dash moments
   - the pace of the dash compared with a normal move
   - footstep and animation sync
5. **Enemy turn and AI legibility.** Can the player see why an enemy acted? Check that flanks, overwatch triggers, grenades and reinforcements are each telegraphed.
6. **Abilities.** Check how the top 10 most-used class abilities (W18) feel. Are their VFX and sound distinct? Rate each 1-3 for feel.
7. **Tactical depth that drives feel.** Check:
   - destructible cover
   - height advantage
   - overwatch ambush moments
   - "clutch" moments such as the last unit standing or a 1 HP survive
   - concealment, if any
8. **Phone feel.** Check:
   - tap accuracy on units and tiles
   - drag and pinch on the camera
   - mis-tap risk on End Turn
   - fps during blasts
   - portrait Low draw calls (W23 left this at 180; the target is 150 or fewer)

## Output
- AUDIT-REPORT.md, under 200 lines:
  - **Before/after table:** W22 baseline vs now, for every repeated measure.
  - **Top 15 battle-feel gaps,** ranked by player impact. For each gap give:
    - where it shows
    - the screenshot or clip file
    - the XCOM 2 ref
    - the cause (file:line)
    - the fix idea
    - the phone perf risk
  - **Proposed 3-5 lanes** with leases that don't overlap. For each lane give:
    - its exact file list
    - one test name, `<lane>24_test.gd`
    - the gaps it fixes
    - the cross-lane contracts, as guarded has_method hooks
  - Each shared file goes to one lane only.
  - Flag any lane that needs new art. Give it a free source first (shader, Blender or CC0). List a Meshy credit quote separately and only if it's needed. NEVER call Meshy.
- 2026-11-11-battle-audit-sheet.jpg: one JPG with 4-6 panels, showing our game next to XCOM 2 for the worst gaps. Keep it in tw-logs only.
- Final message: the top 5 gaps, the lane split, any Meshy quote, and the sheet path.

## Boundaries
- The repo is read-only. No commits, no pushes, no Meshy calls.
- Don't delete untracked files. No `git stash -u` or `git clean`.
- Never print MESHY_KEY. Never copy XCOM 2 images into the repo.
