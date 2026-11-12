# W28 Lane D — Phone battle HUD rescue (buttons, cut-off, clutter)

Jess played the live build on his iPhone (2026-11-12): "The UI is really not playable, needs a better pass. Buttons were not accessible. Movement was hard. All of it was not good."
His screenshots: /home/jess/projects/tw-logs/w28/phone-ui/2026-11-12-jess-iphone-1.png and -2.png (iPhone 16 Pro Max landscape, 2868x1320 px = 956x440 CSS pt @3x). LOOK AT BOTH before starting.

Setup, rules, gate and final-message format: docs/godot/w28/COMMON.md (base c507f7b, worktree /home/jess/projects/tw-w28/phone-hud, branch w28/phone-hud, prefix `w28d_`, logs tw-logs/w28/phone-hud/). Lane E (movement) runs in parallel; never edit its files.

## Root problem to prove or disprove first
Our gate tests Godot headless at 844x390. Nobody tested the real WEB export at real iPhone size with touch. project.godot base is 1366x768 with stretch canvas_items/expand, so on a 440pt-tall phone every UI px is ~0.57 pt: a "44 px" button is ~25 pt on glass. Measure it, then fix it.

## What is broken in Jess's shots (fix every one)
1. Bottom HUD is cut off the screen: unit card ("Sgt. Rhal Dax", HP line hidden), red bar at bottom-left, action buttons. Cause is likely canvas taller than the visible area (iOS Safari toolbar / home indicator, 100vh, no safe-area). Fix in the web shell: `viewport-fit=cover`, size canvas to `window.visualViewport`, pass `env(safe-area-inset-*)` into Godot (JavaScriptBridge) so phone_layout.gd uses real insets; re-layout on resize/orientation.
2. Action buttons overlap into unreadable text ("1 APIOM 1 AP3", "MOVE" drawn over "HOLD 0/6 · TEMPLE OUTER GATE 32 ..."). Objective caption must never overlap the action bar; button labels must never overlap each other.
3. Buttons too small to hit. Every tappable control ≥44 CSS pt on glass at 956x440, 844x390 and 390x844, spacing ≥8 pt. Use a phone UI scale (content_scale_factor or a HUD scale) on touch/mobile only; desktop 1366x768 must not change.
4. Top-left chip "ZONE -2 2 IN 2T" is cryptic and its text clips its box; the portrait chip shows "v 2 in 2T" text over the soldier face. Replace with plain words that fit, e.g. "Reinforcements in 2 turns" (icon + short text), never over a portrait.
5. Floating unit bars: big cyan diamonds + wide bars float over units, overlap each other and slide under the top bar. Make them compact (XCOM iOS: small pips under/over the head), cap their screen size, clamp below the top bar, fade/stack when units overlap.
6. "L C R" vertical panel on the right is unlabeled. Replace with clear camera icons (rotate left / center on unit / rotate right) with tooltips or tiny labels, ≥44 pt, out of the map center; or fold into a single camera button if lane E's gestures cover it.
7. "HOLD ZONE" world label is huge and covers the map. Shrink, keep the green zone outline readable.
8. Layout must match XCOM iOS shape (refs tw-reference/phone/, private, never copy into repo): unit card bottom-left, ability row bottom-center with big icons + 1-word labels, End Turn bottom-right, objective in a slim top strip, nothing in the middle third of the screen.

## Proof harness (new, required)
Write tools/web/w28d_phone_harness.cjs (Playwright chromium, already in ~/.cache/ms-playwright). It serves a fresh `tools/web/export_web.sh` build locally and opens it with iPhone emulation (isMobile, hasTouch, dpr 3) at 956x440, 844x390 and 390x844. It starts mission 1 and:
- screenshots each size into tw-logs/w28/phone-hud/
- reads every visible tappable control's on-screen rect in CSS pt (expose a debug JSON from Godot via JavaScriptBridge, e.g. `window.tw_hud_rects()`), FAILs any <44 pt, any overlap between controls/labels, any rect outside the visible viewport or safe area
- taps (touch events, not mouse) select unit → Move → End Turn and checks each responded.
Simulate a 34 pt bottom inset + 59 pt side inset (Dynamic Island) in one run to prove nothing gets cut off.

## Lease
tools/web/* (shell template, harness), godot/export_presets.cfg web head include only, phone_layout.gd, hud_phone.gd, hud_phone_layout.gd, hud_phone_action_art.gd, hud_phone_camera_art.gd, hud_controls.gd, hud_ability_button.gd, hud_pips.gd, hud18_icon.gd, hud18_tags.gd, hud_night1.gd, battle13_bar.gd, reinforcement_marker.gd, w23_uiart_alerts.gd, w24_hud_controls_settings.gd, w24_hud_feedback.gd, w27c_phone_overlay_guard.gd, new w28d_* files, test godot/tests/phonehud28_test.gd. hud_phone.gd is 779 lines: split new work into w28d_ helpers, don't grow it.
NOT yours (lane E): touch_input.gd, w24_command_move_controls.gd, w27c_phone_preview.gd, battle11_camera.gd, cam_combat.gd, move-range/path drawing. If you need something from them, use a guarded `has_method` call.
Expose for lane E: `hud_safe_rect28()` (the free map area in screen px, excluding HUD + insets) and `hud_scale28()`.

## Done means
Harness PASS at all 3 sizes + inset run, 0 controls <44 pt, 0 overlaps, 0 cut-off; before/after sheet tw-logs/w28/phone-hud/2026-11-12-phone-hud-before-after.jpg (Jess's shot vs ours at 956x440, plus 390x844); COMMON gate green; desktop 1366x768 screenshot unchanged in layout. Report harness numbers per size.
