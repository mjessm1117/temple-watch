# Wave 15 cine report

## Result

1. **PASS — shot cinematic.** The existing lit bolt, muzzle flash, impact sparks, miss pass, and hit stop now play under a closer over-shoulder camera push. The aim UI and unrelated allies clear during the beat. Kill shots add a 0.22 s falling-target frame after the existing 0.055 s slow motion hit stop. Click/tap skip and the persisted CINE toggle work. The Low test measured a 905 ms normal shot.
2. **PASS — aim lighting.** The shooter has a warm key and the target a cool rim on Medium/High. Far DOF and a soft vignette run on Medium/High. Low uses a 2D background tint with no DOF or new post process.
3. **PASS — theme mood.** The theme key is stronger, ambient has a readability floor, and a tinted fill and two cheap prop-zone lamps appear on Medium/High. Low substitutes two emissive floor pools. High/Medium keep directional shadows and the existing unit rim treatment.
4. **PASS — tests and captures.** `cine15_test` checks fire/start/end, skip, setting off, Low fallback, rendered Low draw ceilings, and Medium DOF/lights. Before and after phone and desktop aim/impact plus three-theme tactical captures are below. Every PNG was inspected at native size.

## Render measurements

Godot 4.7.2, Xvfb/Mesa llvmpipe. Phone: 844×390 Compatibility/Low. Desktop: 1366×768 Forward+/High. Values are frame draw calls / triangles. The aim/impact capture moved the target from one to three tiles away to show the shot path, so those before→after figures include the changed framing and visible geometry. Tactical scenes use the same fixture and camera. Software rendering is a draw-budget check, not a device FPS measurement.

| Screen | Before → after draws | Before → after triangles | Before | After |
| --- | ---: | ---: | --- | --- |
| Phone aim | 89 → 96 (+7.9%) | 75,687 → 63,875 | [PNG](../../shots/wave15-cine-before-phone-low-temple-aim.png) | [PNG](../../shots/wave15-cine-after-phone-low-temple-aim.png) |
| Phone impact | 110 → 65 | 141,283 → 108,195 | [PNG](../../shots/wave15-cine-before-phone-low-temple-impact.png) | [PNG](../../shots/wave15-cine-after-phone-low-temple-impact.png) |
| Phone temple tactical | 74 → 76 (+2.7%) | 108,458 → 108,462 | [PNG](../../shots/wave15-cine-before-phone-low-temple-tactical.png) | [PNG](../../shots/wave15-cine-after-phone-low-temple-tactical.png) |
| Phone snow tactical | 79 → 81 (+2.5%) | 104,910 → 104,914 | [PNG](../../shots/wave15-cine-before-phone-low-snow-tactical.png) | [PNG](../../shots/wave15-cine-after-phone-low-snow-tactical.png) |
| Phone city tactical | 76 → 78 (+2.6%) | 98,491 → 98,495 | [PNG](../../shots/wave15-cine-before-phone-low-city-tactical.png) | [PNG](../../shots/wave15-cine-after-phone-low-city-tactical.png) |
| Desktop aim | 94 → 99 | 184,109 → 133,347 | [PNG](../../shots/wave15-cine-before-desktop-high-temple-aim.png) | [PNG](../../shots/wave15-cine-after-desktop-high-temple-aim.png) |
| Desktop impact | 142 → 92 | 363,243 → 292,247 | [PNG](../../shots/wave15-cine-before-desktop-high-temple-impact.png) | [PNG](../../shots/wave15-cine-after-desktop-high-temple-impact.png) |
| Desktop temple tactical | 120 → 120 | 227,018 → 227,018 | [PNG](../../shots/wave15-cine-before-desktop-high-temple-tactical.png) | [PNG](../../shots/wave15-cine-after-desktop-high-temple-tactical.png) |
| Desktop snow tactical | 130 → 130 | 183,311 → 183,311 | [PNG](../../shots/wave15-cine-before-desktop-high-snow-tactical.png) | [PNG](../../shots/wave15-cine-after-desktop-high-snow-tactical.png) |
| Desktop city tactical | 122 → 122 | 219,068 → 219,068 | [PNG](../../shots/wave15-cine-before-desktop-high-city-tactical.png) | [PNG](../../shots/wave15-cine-after-desktop-high-city-tactical.png) |

The highest Low increase is phone aim at +7.9%, within the +15% lane budget. The rendered Low test ceilings are 103 draws in aim and 85 draws in temple tactical. No new Low post process is enabled.

## Gate

- Fresh import and final headless import: exit 0. [Import log](import.log)
- `./godot/test.sh`: exit 0, zero `SCRIPT ERROR`, 57 suite results reporting zero failures; Normal rescue 9/20. Cine Low 19 checks / 0 failures; Cine Medium 4 / 0. [Test log](test.log)
- `git diff --check`: clean.
