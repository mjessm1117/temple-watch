# Wave 15 armory report

## Changes

- Built a layered 3D hangar from instanced ribs, weapon racks, crates, a workbench, ceiling fixtures and a metallic floor. High uses two ceiling spotlights and a specular floor; Low uses emissive geometry and no new post effect. The desktop camera drifts within ±3°.
- Added visible armor plates by armor tier, a hip blaster for troopers, mod glow, and a saber hilt whose size and finish follow its Mk tier. Crystal color changes the blade. Gear actions rebuild the hero in the same action frame.
- Added a selected gear preview with 120 px art on phone and 200 px art on desktop, plus stats. The phone hero remains clear of the roster; slot cards remain in view.

## Captures and performance

Native-size captures were visually inspected. Draws and triangles are `Performance` monitors in the rendered capture, not headless test values. The phone used Compatibility/Low at 844×390; desktop used Forward+/High at 1366×768.

| View | Before draws / triangles | After draws / triangles | After FPS sample | Shots |
| --- | ---: | ---: | ---: | --- |
| Phone Low | 113 / 24,611 | 107 / 25,661 | 72 | [before](../../shots/wave15-armory-before-phone-low.png) · [after](../../shots/wave15-armory-after-phone-low.png) |
| Desktop High | 190 / 44,618 | 145 / 47,148 | 68 | [before](../../shots/wave15-armory-before-desktop-high.png) · [after](../../shots/wave15-armory-after-desktop-high.png) |
| Different loadout, desktop High | — | 153 / 47,250 | 48 | [violet crystal and armored robes](../../shots/wave15-armory-after-desktop-high-different.png) |

Low's draw ceiling is 130 (baseline × 1.15, rounded up); observed 107. FPS samples vary with host load. The Low screenshot is a rendering sample, not a sustained device benchmark.

## Gate

- Fresh-worktree and final headless import: exit 0; [import log](import.log).
- `./godot/test.sh`: exit 0; 56 zero-failure result lines, 0 `SCRIPT ERROR`, 0 failures; Normal rescue 9/20. New `armory15_test`: 14 checks, 0 failures. [Full test log](test.log).
- `git diff --check`: clean.
