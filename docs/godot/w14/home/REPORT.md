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

## Review fix pass — 2026-11-05

Phone room names now use short 16 px type in a single batched canvas. The rendered uppercase ink measures 14 px tall in the 844×390 capture. All seven initially built rooms have labels; the empty rooms keep their outlines and full names in Rooms. `home14_test` checks type height, all built labels, pairwise overlap, and the hidden phone state plates. Built rooms have brighter recessed walls and shared flickering monitors; larger figures from `human.glb` and the room props show through the opened middle band. Unbuilt rooms remain dark. The phone galaxy initially shows the mission category and title; MORE reveals the full detail, so no line is cut by the briefing button.

The four recaptured after shots were inspected at native size:

| Screen | Phone | Desktop |
| --- | --- | --- |
| Temple | [after](../../shots/wave14-home-after-temple-phone.png) | [after](../../shots/wave14-home-after-temple-desktop.png) |
| Galaxy | [after](../../shots/wave14-home-after-galaxy-phone.png) | [after](../../shots/wave14-home-after-galaxy-desktop.png) |

Compatibility/Low capture totals (draw calls / triangles):

| View | Wave 13 baseline → fix pass draws | Wave 13 baseline → fix pass triangles |
| --- | ---: | ---: |
| Temple phone | 257 → 278 (+8.2%) | 174,960 → 174,377 |
| Temple desktop | 425–426 → 427 | 188,578–188,580 → 193,845 |
| Galaxy phone | 98 → 102 | 43,203 → 43,696 |
| Galaxy desktop | 144 → 145 | 46,135 → 46,142 |

No Meshy credits used.

Fix pass gate: headless import succeeded; `./godot/test.sh` exited 0 with 49 zero-failure suite lines, 0 `SCRIPT ERROR`, and Normal rescue 9/20. Phone `home14_test` passed 101 checks; desktop passed 59. `git diff --check` is clean. Logs: `import-fix.log`, `test-fix.log`, and the four `capture-*-fix.log` files in this folder.
