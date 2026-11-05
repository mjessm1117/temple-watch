# Wave 13 — home

## Player changes

- Galaxy opens from the live teaser on the Temple home screen. The starfield and planet map now occupy the full height of the strategy view, with threat and mission markers on the map and a narrower briefing panel beside it. The Temple button and Escape return to home.
- The Temple cutaway has deeper recessed room faces and lit thresholds. Room plates now show **BUILT**, **BUILDING**, or **EMPTY**. Longer desktop names wrap at word boundaries or scale to fit; alerts stay in the command bar and galaxy teaser rather than covering room names. Phone room details remain available through the Rooms drawer.
- Compatibility renders the small galaxy planets with fewer triangles. No Low-tier post effect or project quality setting changed.

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

- Import: passed, no script errors (`import-final.log`).
- `home13_test`: layout, labels, room states, map markers, Low renderer setting, navigation at both sizes; captures passed.
- Full `./godot/test.sh`: exit 0, zero `SCRIPT ERROR` lines, every suite zero failures (`test-final.log`). Normal rescue was 9/20; Wave 11 families were 8/20, 16/20, and 16/20.
- `git diff --check`: clean.
