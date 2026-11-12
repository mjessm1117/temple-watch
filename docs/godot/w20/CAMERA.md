# W20 lane C — battle camera faces the action + phone camera controls (lane name: camera)
Read COMMON.md first. Worktree ../tw-w20/camera.
## Jess wants
"The map camera is stuck facing backwards and the camera doesn't control on phone well. The buttons need to be sized appropriately."
The audit found every map starts at yaw 45° regardless of where the enemies and objective are. On phone, one-finger drag pans, and rotation needs a two-finger twist that snaps 90°. Tap-to-move gets lost on gestures.
## Do
1. **Starting yaw.** Compute it so the camera sits behind the squad looking toward the objective/enemy centroid. Snap to the nearest of 4 or 8 headings so the grid stays readable. Do this on every map, and also after each turn start if the squad has rotated around the objective.
2. **Phone controls (XCOM mobile feel).**
   - One-finger drag pans.
   - Add on-screen rotate left/right buttons, at least 48 px, placed so they don't overlap actions.
   - Add a "re-centre on selected unit" button.
   - Pinch zooms, with smooth eased transitions.
   - Keep the two-finger twist.
   - Tap-to-move must not be swallowed: raise the drag threshold to suit @3x screens (logical px) and accept a tap after a tiny jitter.
3. **Battle HUD button sizes** at 956x440@3 and 844x390:
   - Every control is >= 44 logical px and not clipped.
   - The bottom action row is not crowded.
   - Floating name/HP labels must not overlap units or each other when units are adjacent. Shrink them, stack them, or show them only for the selected unit and targets.
## File lease
- godot/scenes/rescue.tscn, scripts/game.gd, scripts/battle11_camera.gd, scripts/touch_input.gd, scripts/input_controls.gd, scripts/hud_phone*.gd, scripts/hud_controls.gd, scripts/hud_ability_button.gd, scripts/cam_combat.gd
- unit label code if it lives in a hud_* file
- new tests/camera20_test.gd
## Tests (camera20)
- The starting camera on relay, rescue and ilum faces the objective/enemies (angle from the camera forward vector to the target centroid < 50°).
- The rotate buttons change yaw by one step.
- A tap with a 6-logical-px jitter still moves the unit.
- All battle HUD controls are >= 44 px and inside the viewport at both phone sizes.

Sheet: the start view of 3 maps before and after, plus the phone HUD with the rotate buttons.
