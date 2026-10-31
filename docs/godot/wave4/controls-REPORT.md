# Controls lane report

## Player changes

- Selecting a soldier shows blue one action and yellow dash borders. Hover previews a path, AP cost, distance, and directional half/full cover shields. First click locks the destination; second click or Enter moves there. Esc or right click cancels.
- Shoot, Strike, and Push enter target mode. Tab and Shift+Tab cycle only legal, spotted targets. The camera frames shooter and target. Shoot and Strike show hit, crit, graze, cover, line of sight, range, and every modifier from `Shot.calculate`. Push explicitly shows that it has no hit or crit roll. Enter or a target click confirms.
- A soldier with no AP automatically yields selection to the next ready soldier. Tab cycles the squad outside target mode. Ending a turn with unused actions asks for a second Enter or button press.
- Q/E rotate 90 degrees with a 0.28 second blend; WASD and screen edges pan; the wheel zooms over 0.25 seconds. Selection and movement glide the camera to the active soldier. Enemy activity briefly frames each enemy that moved or spent AP. Space skips camera activity. The ability bar and HUD show hotkeys.
- `game.gd` is 515 lines, with HUD and input rule helpers in separate scripts. No mission or shot rules were copied.

## See it in game

Open the Rescue mission. Select a soldier, hover blue and yellow tiles, click a destination twice, then press 2 to select Shoot. Tab between targets; Enter confirms. Press Q/E and WASD to move the camera. Press End Turn while squad members still have AP to see the warning.

The timing choices were checked against the installed XCOM 2 WotC `defaultcamera.ini`: targeting blend 0.75 seconds, retargeting 0.5–1.6 seconds, zoom ramp 0.25 seconds. Temple Watch uses shorter targeting and enemy pans for its compact map.

## Tests

- `./godot/test.sh`: 140 checks, 0 failures, no script errors.
- `godot --headless --path godot -s tests/controls_test.gd`: 20 checks, 0 failures.

## Screenshots

- [Move ranges and ability bar](../shots/wave4-controls-overview.png)
- [Targeting odds and modifiers](../shots/wave4-controls-targeting.png)
- [Shot feedback](../shots/wave4-controls-shot.png)

## Integration requests

- `godot/tests/run.gd`: The runner has a fixed test list and does not auto-discover `controls_test.gd`. Add `const ControlsTest = preload("res://tests/controls_test.gd")` beside its other test constants, then add `await ControlsTest.run_checks(self, check)` in `run()` after `_test_difficulty()` and before the `--quick` branch. The new test exposes this static function, so it can be registered without duplicating checks.

## Open problems

- `mission.end_turn()` resolves the whole enemy phase synchronously. The controls lane can frame enemies that moved or spent AP after the phase resolves, but precise per action camera timing requires a public event or action log from the mission lane.
