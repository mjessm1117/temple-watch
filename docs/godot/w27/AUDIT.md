# W27 Battle Feel Audit, part 3 (READ-ONLY)

Owner: temple-watch. Jess picked "W27 = More battle feel" (ask-e2d1f7fd).
Goal: re-measure battle feel on main d676da7, after W24 (turn/camera, impact, threat, controls) and W26 (difficulty, side colors, phone HUD). Find what still falls short of XCOM 2. Rank the gaps, then propose 3-5 fix lanes with file leases that don't overlap. Change no code.

## Setup
- Worktree: /home/jess/projects/tw-w27/audit, on a new branch w27/audit off main d676da7 (`git worktree add`). Do NOT touch the main checkout at /home/jess/projects/temple-watch (it has uncommitted files).
- Set up the same way as docs/godot/w22/COMMON.md "Setup": rsync the untracked godot/assets and addons, then run `godot --headless --import`. The Godot binary is /home/jess/projects/.tools/godot/godot.
- Do NOT edit tracked game files. Capture and measure scripts can live in tw-logs/w27/audit/tools/, which is outside the repo.
- Write outputs ONLY to /home/jess/projects/tw-logs/w27/audit/.

## Read first
- docs/godot/w24/AUDIT.md: the method. tw-logs/w24/audit/ report: the W24 baseline numbers. Re-use its measures so before/after can be compared.
- docs/godot/w26/AUDIT.md and the tw-logs/w26/ audit report: what W26 changed (fewer first-mission enemies, side colors, HUD fonts).
- tw-logs/w25/2026-11-10-jess-playtest-notes.md: Jess's latest notes ("gameplay weak, far from XCOM"). These outrank your own taste.
- tw-reference/*.jpg and tw-reference/phone/*: the XCOM 2 refs (PC + iOS). Private; never copy them into the repo.

## Measure (landscape 844x390 AND portrait 390x844, on Low; spot-check desktop 1366x768)
Use the gate defense map plus 2 other themes. Re-measure every W24 baseline number that exists.
1. **Turn flow.** Taps and seconds from select to action end (move, shoot, Force, overwatch); enemy-turn time; dead time with no feedback; camera moves per turn, snaps or whiplash.
2. **Hit / miss / kill punch.** Per weapon type (blaster, saber, Force, grenade/blast): shot-to-impact time, hit-stop, camera impulse, sound, damage number, death/fall. Misses must read as misses. Compare to the XCOM 2 shot-to-impact beat.
3. **Aim and decide.** Hit-chance breakdown, flank/cover shields before commit, move-path danger preview (overwatch, reveals), cancel/undo.
4. **Movement.** Path smoothness, vault/climb/doors, Jedi leap/dash, footstep and animation sync.
5. **Enemy turn and AI legibility.** Can the player see why an enemy acted? Flanks, overwatch triggers, grenades, reinforcements telegraphed?
6. **Abilities.** Top 10 most-used class abilities: distinct VFX and sound? Rate each 1-3.
7. **Tactical depth that drives feel.** Destructible cover, height advantage, overwatch ambush moments, clutch moments (last unit, 1 HP survive), mission variety in the first 3 missions. Is there a real decision every turn, or is it "walk up and shoot"? This is Jess's "gameplay weak" complaint: name the missing decisions concretely.
8. **First 3 missions pacing.** Win rate and turns-to-win on Normal for missions 1-3 after W26 difficulty changes. Too easy now? Too samey?
9. **Phone feel.** Tap accuracy, drag/pinch camera, End Turn mis-tap risk, fps during blasts, portrait Low draw calls (target 150 or fewer; W24 left it ~176-186).

## Output
- AUDIT-REPORT.md, under 200 lines:
  - **Before/after table:** W24 baseline vs now, for every repeated measure.
  - **Top 15 battle-feel gaps,** ranked by player impact. Each: where it shows, screenshot/clip file, XCOM 2 ref, cause (file:line), fix idea, phone perf risk.
  - **Proposed 3-5 lanes** with leases that don't overlap. Each: exact file list, one test name `<lane>27_test.gd`, gaps it fixes, cross-lane contracts as guarded has_method hooks. Each shared file goes to one lane only.
  - Flag any lane that needs new art. Free source first (shader, Blender, CC0). Meshy credit quote separately and only if needed. NEVER call Meshy.
- 2026-11-11-w27-battle-audit-sheet.jpg: one JPG, 4-6 panels, our game next to XCOM 2 for the worst gaps. tw-logs only.
- Final message: top 5 gaps, the lane split, any Meshy quote, the sheet path.

## Boundaries
- The repo is read-only. No commits, no pushes, no Meshy calls.
- Don't delete untracked files. No `git stash -u` or `git clean`.
- Never print MESHY_KEY. Never copy XCOM 2 images into the repo.
