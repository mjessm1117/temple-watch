# W28 Lane E — Phone movement rescue (tap to move like XCOM iOS)

Jess played the live build on his iPhone (2026-11-12): "Movement was hard." UI "not playable".
His screenshots: /home/jess/projects/tw-logs/w28/phone-ui/2026-11-12-jess-iphone-1.png and -2.png (iPhone 16 Pro Max landscape, 956x440 CSS pt @3x). LOOK AT BOTH. Note there is no visible blue move area on the map, and a ladder of white rings off to the right that means nothing to a player.

Setup, rules, gate and final-message format: docs/godot/w28/COMMON.md (base c507f7b, worktree /home/jess/projects/tw-w28/phone-move, branch w28/phone-move, prefix `w28e_`, logs tw-logs/w28/phone-move/). Lane D (HUD/buttons/safe area) runs in parallel; never edit its files.

## Target flow (XCOM 2 iOS; refs tw-reference/phone/, private, never copy into repo)
1. Selected unit shows its reach on the map at all times on its turn: blue outline = 1-action move, yellow/gold outline = dash (uses both actions). Readable on the brown gate map on Low, top-down and tilted camera.
2. Tap a tile → path line + destination marker + cover shields at the destination + "1 AP"/"2 AP" tag + danger marks (overwatch, reveal) from the existing preview APIs. Nothing moves yet.
3. Tap the same tile again (or a big Confirm button near the bottom-center) → unit moves. Tap a different tile → re-preview. Tap the unit or the empty sky / back → cancel.
4. Taps on tiles must hit what the finger meant: tile pick tolerance tuned for a ~10 mm fingertip at 956x440 and 844x390; ignore taps that started as a camera drag; a drag that starts on a unit or button must not pan.
5. Camera on phone: one-finger drag pans, two-finger pinch zooms, two-finger twist rotates; auto-frames the selected unit and its reach inside lane D's free map area (`hud_safe_rect28()` via guarded has_method; fall back to the full viewport minus 25% bottom / 12% top).
6. Remove or replace the white ring ladder with something that reads (if it is the dash/path preview, make it the path line from step 2).
Keep the XCOM rules: 2 actions per turn, firing ends the turn. Keep mission 1 rules from COMMON.

## Proof
- godot/tests/phonemove28_test.gd: drives real InputEventScreenTouch/Drag at 956x440 and 844x390: tap-preview-tap-move, re-target, cancel, drag-pan doesn't move a unit, drag starting on a unit doesn't pan, reach outline visible (non-empty mesh/count) for the selected unit.
- tools/web/w28e_move_check.cjs (Playwright chromium, ~/.cache/ms-playwright, iPhone emulation isMobile + hasTouch + dpr 3) on a local export build: touch-tap a reachable tile twice, confirm the unit moved; screenshot preview + after at 956x440 and 390x844 into tw-logs/w28/phone-move/.
- Before/after sheet tw-logs/w28/phone-move/2026-11-12-phone-move-before-after.jpg (Jess's shot vs ours, reach + path visible).

## Lease
touch_input.gd, touch_scroll.gd (only if needed), w24_command_move_controls.gd, w27c_phone_preview.gd, battle11_camera.gd, cam_combat.gd, the move-reach/path drawing script(s) you find (name them in your report; if one is in lane D's lease, add a w28e_ helper instead), new w28e_* files, the two tests above.
NOT yours (lane D): tools/web shell/export files, phone_layout.gd, hud_*.gd, battle13_bar.gd, reinforcement_marker.gd, w23_uiart_alerts.gd, w24_hud_*, w27c_phone_overlay_guard.gd.
Expose: `move_preview_state28()` (tile, cost, confirmed?) so lane D's HUD can show Confirm.

## Done means
Tests pass, web check moves a unit by touch at both sizes, sheet made, COMMON gate green (Normal rescue 9–11/20, bot must still move: update the bot only via the API if the 2-tap flow changes its path). Portrait draws may rise ≤5 for the reach outline; report before→after.
