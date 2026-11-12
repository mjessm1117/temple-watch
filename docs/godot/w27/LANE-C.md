# W27 Lane C — Phone hierarchy + perf (worktree tw-w27/phone, branch w27/phone)

Read docs/godot/w27/COMMON.md first and follow it exactly. Lane prefix `w27c_`.

## Lease
godot/scripts/hud_phone.gd, hud_phone_layout.gd, hud_phone_action_art.gd, hud_phone_camera_art.gd, decision22_threat.gd, touch_input.gd, map_art_batch.gd, map_art_geometry.gd, gfx_unit_readability.gd (all under godot/scripts/), new godot/tests/phone27_test.gd, new w27c_* helpers.

## Goal (audit gaps 5, 6, 8, 11, 12, 13, 14) — phone UI is Jess's top priority
1. Gap 5: portrait aim shows 85% twice in two cards over the shooter/target. ONE compact odds card, anchored so shooter and target stay visible, with cover/height/flank reasons (use B's decision_preview27 if present). Ref phone/2026-11-10-xcom2-ios-06.png.
2. Gap 6: enemy turn stacks comms, objective HP and action text over enemies. Show one actor + reason + outcome card (B's intent_explain27 if present); defer non-urgent comms until the enemy turn ends.
3. Gap 8: portrait Low gate draw calls 183 (185 in blast), target ≤150. Consolidate material/alpha buckets in map_art_batch/map_art_geometry. Measure before/after on gate, shrine, rescue.
4. Gap 12: draw lane A's wave_entry27 as an entry arrow + countdown on the board (guarded).
5. Gap 13: side readability at tactical zoom — bigger side shape on unit plates (ally vs enemy silhouette, not just a pip), keep W26 colors.
6. Gap 14: End Turn sits near the menu button. Separate the irreversible control; raise narrow-view unit pick radius above 28 px and check the 18 px drag threshold doesn't eat taps.
7. Gap 11 display: render B's cover/height/flank preview in the phone layout.
All targets ≥44 px. Test 390x844 and 844x390.

## Test
phone27_test.gd: one odds card in portrait aim (no duplicate), enemy-turn overlay count ≤1 card + objective strip, End Turn ≥ N px from menu, pick radius, draw calls ≤150 portrait gate Low (or report exact number if not reached), no overlap between HUD hit areas.
