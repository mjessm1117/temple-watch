# Wave 14 home lane

## Player changes

- Phone Temple room names are visible on the cutaway without opening Rooms. A single canvas overlay draws the names, preserving clickable room targets and keeping Low draw calls close to Wave 13.
- Built rooms have recessed lit panels and floor wear. Empty and building states remain distinct, while existing figures and holograms keep moving.
- The galaxy shows travel routes between worlds. The existing shaded planet shaders, nebula, regional haze and parallax remain active. Phone briefing has a short visible excerpt and a More button that moves to the full briefing.
- The inspected phone hero now clears the roster. Lit racks sit behind the hero, and armory tile headings have their own top row.
- Title, graphics settings, research and forge were checked at 844×390 and 1366×768. They retain the Wave 13 shared theme.

## Captures

All captures were inspected at full size. Before files are copied from the Wave 13 merged baseline; after files are fresh Compatibility/Low renders.

| Screen | 844×390 | 1366×768 |
| --- | --- | --- |
| Temple | [before](../../shots/wave14-home-before-temple-phone.png) · [after](../../shots/wave14-home-after-temple-phone.png) | [before](../../shots/wave14-home-before-temple-desktop.png) · [after](../../shots/wave14-home-after-temple-desktop.png) |
| Galaxy | [before](../../shots/wave14-home-before-galaxy-phone.png) · [after](../../shots/wave14-home-after-galaxy-phone.png) | [before](../../shots/wave14-home-before-galaxy-desktop.png) · [after](../../shots/wave14-home-after-galaxy-desktop.png) |
| Armory | [before](../../shots/wave14-home-before-armory-phone.png) · [after](../../shots/wave14-home-after-armory-phone.png) | [before](../../shots/wave14-home-before-armory-desktop.png) · [after](../../shots/wave14-home-after-armory-desktop.png) |
| Title | [phone](../../shots/wave14-home-after-menu-phone.png) | [desktop](../../shots/wave14-home-after-menu-desktop.png) |
| Settings | [phone](../../shots/wave14-home-after-settings-phone.png) | [desktop](../../shots/wave14-home-after-settings-desktop.png) |
| Research | [phone](../../shots/wave14-home-after-research-phone.png) | [desktop](../../shots/wave14-home-after-research-desktop.png) |
| Forge | [phone](../../shots/wave14-home-after-forge-phone.png) | [desktop](../../shots/wave14-home-after-forge-desktop.png) |

## Low performance

Draw calls / triangles. Before is the Wave 13 merged report's Low count; after is this lane's Compatibility capture on Intel Mesa. The armory's archived phone Low capture predates the final Wave 13 gear art, so its difference includes that art change and is not an isolated Wave 14 cost. Desktop armory has no archived Low baseline. No Low post effect or quality setting changed.

| View | Before → after draw calls | Before → after triangles |
| --- | ---: | ---: |
| Temple phone | 257 → 267 | 174,960 → 175,723 |
| Temple desktop | 425–426 → 429 | 188,578–188,580 → 188,837 |
| Galaxy phone | 98 → 106 | 43,203 → 44,022 |
| Galaxy desktop | 144 → 145 | 46,135 → 46,142 |
| Armory phone, archived early W13 Low | 77 → 103 | 22,279 → 23,145 |
| Armory desktop | unavailable → 118 | unavailable → 23,889 |

## Remaining gap and cross-lane requests

The galaxy still uses a stylized orbital view rather than a textured geographic globe. Temple rooms remain modular and smaller than a bespoke cutaway set; phone labels are necessarily small at 844×390, with Rooms available for larger text. Hero gear silhouettes still change less than XCOM 2's equipment preview. No cross-lane requests. No Meshy credits used.

## Gate

Import completed. `godot/test.sh` exited 0, with 0 `SCRIPT ERROR` lines, 49 zero-failure suite lines and no failed suite; Normal rescue was 9/20. `home14_test`: phone 63 checks, desktop 59 checks, zero failures. `armory13_test`: 253 checks, zero failures. `git diff --check` is clean. Full output is in `test-final.log`.
