# Wave 4 integration report

## Player changes

- Hunker Down is available on the ability bar with hotkey **7**. The selected unit panel shows **HUNKERED +30 DEF** while it lasts.
- The announced reinforcement tile has a bright amber entry marker on the board. It updates after each turn and disappears when the troops arrive.
- Unit views crouch according to cover against their most threatening visible opponent. Push staggers its target; damaging hits play the hit cue; critical hits and kills briefly slow the presentation. Changed cover rebuilds from the mission grid and sheds chunks at each changed tile.
- Move previews count flank opportunities. The targeting panel calls out flanks and their critical bonus, shows damage and possible lethal damage, and keeps Push's guaranteed knockback separate from hit and crit odds. Player attack feedback follows camera arrival and projectile travel. Enemy activation, movement, attacks, Push, and Overwatch use ordered mission events; **Space** skips the playback.
- The Wave 4 art report and its four before/after captures are at the Wave 4 report and screenshot paths.

## How to see it

Launch `res://scenes/rescue.tscn`. Select a soldier and hover a reachable tile for the move path, AP cost, and cover faces. Press **2** to target a flanked enemy and inspect the critical line. Press **7** with AP remaining to hunker. On turn 4, look for the amber marker at `(23,15)`; it disappears when reinforcements land on turn 5.

## Verification

`./godot/test.sh`: **203 checks passed / 0 failed; no script errors**. The Normal fixed-seed rescue bot won 11/20 runs. The runner now includes `controls_test.gd` and `fx_test.gd`. The three final captures were made at 1366 × 768 by `godot/scripts/final_capture.gd`, which loads `res://scenes/rescue.tscn` directly.

## Screenshots

- [Move preview](../shots/wave4-final-move.png)
- [Flanked target and breakdown](../shots/wave4-final-flank.png)
- [Reinforcement entry marker](../shots/wave4-final-reinforcement.png)
- [Art before/after report](art-REPORT.md)

## Open problems

- The mission still resolves rules synchronously before enemy playback. The event trail presents those actions in order, but it does not pause rule decisions between animations.
- Godot reports ObjectDB leak warnings on teardown, including after a passing test run. No script errors were reported.
- Integrated scene frame time was not measured in this pass; the art lane's direct-display benchmark is recorded in [art-REPORT.md](art-REPORT.md).
