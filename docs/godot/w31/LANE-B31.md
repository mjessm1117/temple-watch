# W31 Lane B31 — Phone aim and action hierarchy

## Goal (player-visible)
In portrait mode (390×844), the shooter stays visible during the aim card — you can see who's firing and who they're targeting. The move destination card marks the exact tile where an enemy has Overwatch/LOC (a "danger tile"). The aim card shows hit% and crit% once, not three times. EVAC marker doesn't overlap squad figures.

## Base
- Worktree: /home/jess/projects/tw-w31/b31 (branch w31/b31, commit ee920313)
- W31 audit findings: portrait aim cuts shooter out (cam_combat.gd:173-217); aim% repeated 3×; EVAC label overlaps squad; route trigger boolean hides exact danger tile

## Write lease (exclusive — do NOT touch any other scripts)
```
godot/scripts/game.gd                 ← 614 lines, OVER limit; surgical edits only, extract to w31b_*.gd
godot/scripts/cam_combat.gd
godot/scripts/input_controls.gd
godot/scripts/hud_controls.gd
godot/scripts/hud_phone.gd            ← 594 lines, near limit; surgical edits preferred
godot/scripts/hud_phone_layout.gd
godot/scripts/w30d_ability_hud.gd
godot/scripts/map_art_grid.gd
godot/scripts/w28e_evac_marker.gd
godot/scripts/w31b_*.gd               ← new helpers go here
godot/tests/phoneaim31_test.gd        ← new test
```
Do NOT touch: test.sh, any script outside this list, any ability/data files.

## Steps

### 1. Import warmup
```bash
mkdir -p /home/jess/projects/tw-logs/w31/b31/
/home/jess/projects/.tools/godot/godot --headless --import \
  --path /home/jess/projects/tw-w31/b31/godot \
  > /home/jess/projects/tw-logs/w31/b31/import.log 2>&1
echo "IMPORT_EXIT=$?"
grep -c "SCRIPT ERROR" /home/jess/projects/tw-logs/w31/b31/import.log || true
```
Must complete with 0 SCRIPT ERRORs.

### 2. Portrait aim camera — keep shooter visible
Read `godot/scripts/cam_combat.gd` lines 173–217 (aim camera logic) and lines 348–427 (return/frame logic).

The audit's portrait aim capture showed the acting unit off-screen. Fix: when the aim card opens in portrait orientation, adjust the camera so the actor-to-target segment fits within the safe battle viewport. Clamp the camera position to keep the actor visible (a small offset from screen edge is fine, it doesn't need to be centered). Do not change landscape behavior.

If cam_combat.gd logic extraction is needed, put it in `godot/scripts/w31b_aim_frame.gd`.

### 3. Move preview — mark the first danger tile
Read `godot/scripts/input_controls.gd` lines 106–133 (route safety logic).

Currently route safety is boolean (safe/unsafe path). Fix: for each tile in the preview route, check if it enters an enemy's Overwatch cone or confirmed line-of-sight. Mark the first such tile with a distinct highlight color (e.g., red/orange tile tint vs. the normal blue/gold from W28). The card label can say "DANGER · 1 enemy sightline" instead of just "EXPOSED". The existing EXPOSED data should already provide the information; this is a presentation change.

### 4. Aim card — remove duplicate odds
Read `godot/scripts/hud_phone.gd` lines 297–314 and `godot/scripts/w30d_ability_hud.gd` lines 185–209.

The audit found hit% repeated in the left aim card, the target strip, and the bottom confirmation strip. Fix: keep one clean hit/crit header with cover and flank modifiers. Remove or suppress the duplicate from the confirmation strip in portrait. XCOM 2 iOS reference: one odds row with hit% / crit% prominently, rest as modifiers.

### 5. EVAC marker — prevent squad overlap
Read `godot/scripts/w28e_evac_marker.gd` and `godot/scripts/map_art_grid.gd` lines 55–59.

The EVAC Label3D overlaps squad figures. Fix: during the evacuation phase, offset the EVAC label vertically above the tile (or use a billboard that projects above units). Alternatively, check if the label position can be anchored at tile top rather than center, so standing units don't block it.

### 6. Write phoneaim31_test.gd
Tests must cover:
- phonehud28_test layout checks still pass at 844×390 and 390×844 (run inline or by calling the existing test logic)
- phonemove28_test: 36/36 checks still pass
- New check: portrait aim camera leaves the actor box within the safe viewport (Rect2 intersection check with the screen)
- New check: input_controls route-preview returns a "first_danger_tile" key (or equivalent) for a route with known enemy LOC
- New check: aim card node hierarchy has at most one hit-odds header widget (no duplicate)
- New check: EVAC marker world position is above unit tile center by ≥0.5 units

Write test to: `godot/tests/phoneaim31_test.gd`

### 7. Run focused phoneaim31_test
```bash
/home/jess/projects/.tools/godot/godot --headless \
  --path /home/jess/projects/tw-w31/b31/godot \
  -s tests/phoneaim31_test.gd -- --graphics=low \
  > /home/jess/projects/tw-logs/w31/b31/phoneaim31.log 2>&1
echo "PHONEAIM31_EXIT=$?"
grep -E "RESULTS|FAIL:|SCRIPT ERROR" /home/jess/projects/tw-logs/w31/b31/phoneaim31.log | tail -10
```
Must show 0 failures.

Also run focused phonehud28_test and phonemove28_test to confirm no regression:
```bash
/home/jess/projects/.tools/godot/godot --headless \
  --path /home/jess/projects/tw-w31/b31/godot \
  -s tests/phonehud28_test.gd -- --graphics=low \
  > /home/jess/projects/tw-logs/w31/b31/phonehud28-check.log 2>&1
grep "PHONEHUD28\|RESULTS" /home/jess/projects/tw-logs/w31/b31/phonehud28-check.log | tail -3

/home/jess/projects/.tools/godot/godot --headless \
  --path /home/jess/projects/tw-w31/b31/godot \
  -s tests/phonemove28_test.gd -- --graphics=low \
  > /home/jess/projects/tw-logs/w31/b31/phonemove28-check.log 2>&1
grep "PHONEMOVE28\|RESULTS" /home/jess/projects/tw-logs/w31/b31/phonemove28-check.log | tail -3
```
Both must show 0 failures.

### 8. Run full gate
```bash
cd /home/jess/projects/tw-w31/b31/godot && \
  bash test.sh > /home/jess/projects/tw-logs/w31/b31/gate.log 2>&1
echo "GATE_EXIT=$?"
grep -c "SCRIPT ERROR" /home/jess/projects/tw-logs/w31/b31/gate.log || true
grep "Normal rescue bot" /home/jess/projects/tw-logs/w31/b31/gate.log
grep "^TEST RESULTS\|RESULTS:" /home/jess/projects/tw-logs/w31/b31/gate.log | tail -5
grep -c "Godot Engine" /home/jess/projects/tw-logs/w31/b31/gate.log
```
Expected: GATE_EXIT=0, 0 SCRIPT ERRORs, 0 failures, ≥135 suites, Normal rescue bot 9–11/20.

If phoneaim31_test is not registered in test.sh, that is correct — integration handles test.sh.

### 9. Commit
```bash
cd /home/jess/projects/tw-w31/b31
git add godot/scripts/game.gd godot/scripts/cam_combat.gd godot/scripts/input_controls.gd \
        godot/scripts/hud_controls.gd godot/scripts/hud_phone.gd godot/scripts/hud_phone_layout.gd \
        godot/scripts/w30d_ability_hud.gd godot/scripts/map_art_grid.gd \
        godot/scripts/w28e_evac_marker.gd godot/scripts/w31b_*.gd \
        godot/tests/phoneaim31_test.gd 2>/dev/null
git diff --cached --stat
git commit -m "W31 B31: portrait aim keeps shooter, danger tile, aim hierarchy, EVAC offset

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git rev-parse --short HEAD
git status --short --untracked-files=no
```

### 10. Report
Return:
- Commit SHA on w31/b31
- phonehud28 result in full gate (should be 67/0)
- phonemove28 result in full gate (should be 36/0)
- Gate: suites / failures / SCRIPT ERRORs / Normal rescue

## Boundaries
- game.gd is 614 lines — over 600 limit. Extract new code to w31b_*.gd; surgical edits in game.gd only.
- hud_phone.gd is 594 lines — near limit. Avoid adding more than ~6 lines inline; extract to w31b_*.gd.
- Do NOT touch test.sh. Integration registers the new test.
- Do NOT touch ability data, mission scripts, rendering scripts.
- phonemove28_test must still pass 36/36 after your changes.
- Gate must be 0 failures before committing (against existing 135 suites).
- Finish, commit, EXIT. Do not wait on remote CI.
- Timeout budget: 120 minutes.
