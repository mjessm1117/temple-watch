# W31 B31 — Gate + Commit

The fix for the feelcam22 regression is already applied to the working tree:
- `godot/scripts/map_art_grid.gd` line ~220: `move_preview` call now gated with `if game.mission.phase == "player" and not game.get("playing_enemy_events", false):`

## Steps

### 1. Import warmup
```bash
/home/jess/projects/.tools/godot/godot --headless --import \
  --path /home/jess/projects/tw-w31/b31/godot \
  > /home/jess/projects/tw-logs/w31/b31/import2.log 2>&1
echo "IMPORT2_EXIT=$?"
grep -c "SCRIPT ERROR" /home/jess/projects/tw-logs/w31/b31/import2.log || true
```

### 2. Full gate
```bash
cd /home/jess/projects/tw-w31/b31/godot && \
  bash test.sh > /home/jess/projects/tw-logs/w31/b31/gate2.log 2>&1
echo "GATE2_EXIT=$?"
grep -c "SCRIPT ERROR" /home/jess/projects/tw-logs/w31/b31/gate2.log || true
grep "Normal rescue bot" /home/jess/projects/tw-logs/w31/b31/gate2.log
grep "^TEST RESULTS\|RESULTS:" /home/jess/projects/tw-logs/w31/b31/gate2.log | tail -5
grep "FEELCAM22" /home/jess/projects/tw-logs/w31/b31/gate2.log | head -5
```
Expected: 0 SCRIPT ERRORs, 0 failures, ≥135 suites, Normal rescue 9–11/20, FEELCAM22 0 failures.

### 3. Commit (only if gate clean)
```bash
cd /home/jess/projects/tw-w31/b31
git add godot/scripts/cam_combat.gd godot/scripts/hud_controls.gd godot/scripts/hud_phone.gd \
        godot/scripts/input_controls.gd godot/scripts/map_art_grid.gd \
        godot/scripts/w28e_evac_marker.gd godot/scripts/hud_phone_layout.gd \
        godot/scripts/w30d_ability_hud.gd godot/scripts/w31b_*.gd \
        godot/tests/phoneaim31_test.gd 2>/dev/null
git diff --cached --stat
git commit -m "W31 B31: portrait aim keeps shooter, danger tile, aim hierarchy, EVAC offset

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git rev-parse --short HEAD
```

### 4. Report
Return:
- Gate: suites / failures / SCRIPT ERRORs / Normal rescue
- FEELCAM22 bench time and pass/fail
- Commit SHA

## Boundaries
- Do NOT touch test.sh or ability data.
- Do NOT edit any scripts beyond staging the already-modified files.
- Gate must be 0 failures before committing.
- Finish, commit, EXIT. Do not wait on remote CI.
- Timeout: 60 minutes.
