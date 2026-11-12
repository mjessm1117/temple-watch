# W20 lane tw-w20-phone — make iPhones get the phone layout

Setup:
1. `cd /home/jess/projects/temple-watch && git worktree add ../tw-w20/phone -b w20/phone fbc2447`
2. Work in /home/jess/projects/tw-w20/phone and run `godot --headless --import` first.

Rules: commit locally only. No push, merge or tag. No subagents.

## Why
Jess's iPhone (2868x1320 physical px, devicePixelRatio 3) gets the DESKTOP layout. The cause is `godot/scripts/phone_layout.gd` `narrow()`, which requires the long side < 1200 px. Several files also do ad-hoc `size.x < 900` checks. The result on phone: a small Temple, keyboard hints (Tab/Enter/Esc, "G galaxy · Esc close", "1–7 stations"), the desktop battle HUD with side panels, and small buttons.

Jess's shots (study them): /home/jess/projects/tw-logs/w20/jess-shots/. Findings: /home/jess/projects/tw-logs/w20/2026-11-09-jess-shots-findings.md.

## Do
1. **Phone detection.** `phone_layout.narrow()` must use LOGICAL size: physical px ÷ the device scale. On web, get devicePixelRatio via JavaScriptBridge; elsewhere use DisplayServer.screen_get_scale().
   - Also treat these as phone when the logical short side is < 900: `OS.has_feature("web_ios")`, `"web_android"`, `"mobile"`, or a touchscreen.
   - Desktop 1366x768 and 1920x1080 with no touch must stay desktop.
   - Add a static test override so tests can simulate a device.
2. **Route every ad-hoc phone width check** through phone_layout. Known ones: story_screen.gd, story14_comms.gd, battle12_aim.gd, promotion_screen.gd, loadout_stage.gd. `rg` for more.
3. **Touch wording.** On touch devices, hide or replace keyboard and mouse hints with touch wording. Examples: Tab/Enter/Esc, "G galaxy · Esc close", "1–7 stations", "Esc returns to the lineup", "Click a soldier" → "Tap a soldier".
4. **Tofu boxes.** Find the glyphs that render as empty boxes (examples: "comms ▯ armory" link lines, "Temple view", "Temple", "DEPLOY", the "Galaxy" minimap title). Use a glyph the bundled font has, or drop it.
5. **Full screen.** The shots show dark bands on the left and right (~6.5% each). Find the cause in the UI root max width, the safe-area handling, or the web export html/canvas. Use the full screen while still keeping the notch/home-bar safe-area insets.

## File lease
- phone_layout.gd plus each file holding an ad-hoc phone check or a keyboard-hint string.
- The font/glyph sources for the tofu labels.
- The UI root/safe-area script.
- tools/web export template only if it causes the bands.
- New test godot/tests/phone_detect20_test.gd and its test.sh line.
- Do NOT change game rules, balance, art, story text or camera behaviour beyond what the layout switch already selects.

## Tests
phone_detect20 must assert:
- phone layout for 2868x1320@3, 2556x1179@3, 844x390@1 and 1792x828@2
- desktop for 1366x768@1 and 1920x1080@1
- no "Tab"/"Esc"/"Enter" hint strings visible in touch mode on Temple, loadout or battle

Full gate per CLAUDE.md: import, test.sh exit 0, 0 SCRIPT ERROR, 0 fails, Normal 9–11/20, and `git diff --check`.

## Proof
Do a local web export, then use Playwright/headless Chrome with an iPhone emulation (viewport 956x440, deviceScaleFactor 3, isMobile, hasTouch). Capture title, Temple home, loadout and battle before and after. Build one sheet at /home/jess/projects/tw-logs/w20/phone/2026-11-09-phone-detect-sheet.jpg and LOOK at it. Also run a desktop 1366x768 shot to show nothing regressed.

Final message: SHA, sheet path, and gate numbers.
