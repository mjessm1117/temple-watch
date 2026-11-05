# Wave 13 — home

## Player changes

- Galaxy opens from the live teaser on the Temple home screen. The starfield and planet map now occupy the full height of the strategy view, with threat and mission markers on the map and a narrower briefing panel beside it. The Temple button and Escape return to home.
- The Temple cutaway has deeper recessed room faces and lit thresholds. Room plates now show **BUILT**, **BUILDING**, or **EMPTY**. Longer desktop names wrap at word boundaries or scale to fit; alerts stay in the command bar and galaxy teaser rather than covering room names. Phone room details remain available through the Rooms drawer.
- Compatibility renders the small galaxy planets with fewer triangles. No Low-tier post effect or project quality setting changed.
- Follow-up: desktop room names, state, and battle bonus now occupy separate lines inside their own room targets. This removes the WAR ROOM / ARCHIVES clipping and collisions with neighboring floor labels. Phone keeps room names in the Rooms drawer. The phone galaxy briefing has visible left and right tab scroll controls.

## Visual evidence

| View | Before | After |
| --- | --- | --- |
| Temple, 844×390 | [before](../../shots/wave13-home-before-temple-phone.png) | [after](../../shots/wave13-home-after-temple-phone.png) |
| Temple, 1366×768 | [before](../../shots/wave13-home-before-temple-desktop.png) | [after](../../shots/wave13-home-after-temple-desktop.png) |
| Galaxy, 844×390 | [before](../../shots/wave13-home-before-galaxy-phone.png) | [after](../../shots/wave13-home-after-galaxy-phone.png) |
| Galaxy, 1366×768 | [before](../../shots/wave13-home-before-galaxy-desktop.png) | [after](../../shots/wave13-home-after-galaxy-desktop.png) |

## Low renderer measurements

Compatibility/GLES3, Mesa llvmpipe software renderer. Counts are from the rendered scene at each resolution. FPS is an instantaneous engine estimate from the capture; concurrent test jobs made it noisy, so it is not a phone hardware benchmark.

| View | Before draw calls / triangles | After draw calls / triangles | FPS estimate before → after |
| --- | ---: | ---: | ---: |
| Temple, phone | 250 / 205,392 | 257 / 174,960 | 11 → 7–12 |
| Galaxy, phone | 99 / 80,841 | 98 / 43,203 | 25 → 26–42 |
| Temple, desktop | 413 / 225,106 | 425–426 / 188,578–188,580 | 9 → 2–10 |
| Galaxy, desktop | 157 / 85,117 | 144 / 46,135 | 16 → 12–23 |

## Remaining gap to XCOM 2

The geoscape still uses a stylized orbital map rather than detailed planet surfaces and mission animations. The Temple uses modular procedural architecture and small figures, but it has less environmental detail and lighting depth than a hand-built cutaway. Phone room names are accessed through the Rooms drawer because the cutaway targets are too small for readable labels at 844×390.

## Gate

- Fix follow-up: desktop room plates now stack name, state and bonus inside the upper part of each room target, so "WAR ROOM" and "ARCHIVES" show in full and no plate touches another room's. The phone briefing tab row scrolls, with ‹ › buttons and a scrollbar.
- `home13_test` collects the global rects of every visible room name, state, bonus and alert plate, fails if two from different rooms intersect, and checks each text fits its rect, at both sizes. Captures: desktop 1,115 checks, phone 19 checks, zero failures (`after-desktop.log`, `after-phone.log`).
- Import: passed, no script errors (`import-final2.log`).
- Full `./godot/test.sh`: exit 0, zero `SCRIPT ERROR` lines, every suite zero failures (`test-final2.log`). Normal rescue was 9/20.
- `git diff --check`: clean.
