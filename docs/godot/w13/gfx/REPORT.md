# Wave 13 gfx: battle-map look

## Player-visible changes

- Battle terrain has clearer stone joints, chipped stone and roughness detail on Medium and High. Low keeps material detail off and gains only a small in-material contact tint.
- Medium and High have restrained color grading; Medium gains soft directional shadows. Existing theme fog, key/rim lighting and High SSAO remain in place. Low keeps fog, glow, SSAO, shadows and color grading disabled.
- Move-range tiles use a quieter fill and a sharper outline. The selected unit has a brighter, tile-sized ring. Existing path lines gain an unshaded cyan material. Existing cover shields and team-colored unit rims remain visible.
- No map, cover, LOS, tile, combat or balance data changed. No GLBs or textures were added.

## Screenshots

| Renderer and size | Before | After |
| --- | --- | --- |
| Low 844×390 | [phone before](../../shots/wave13-gfx-before-low-phone.png) | [phone after](../../shots/wave13-gfx-after-low-phone.png) |
| Low 1366×768 | [desktop before](../../shots/wave13-gfx-before-low-desktop.png) | [desktop after](../../shots/wave13-gfx-after-low-desktop.png) |
| High 844×390 | [phone before](../../shots/wave13-gfx-before-high-phone.png) | [phone after](../../shots/wave13-gfx-after-high-phone.png) |
| High 1366×768 | [desktop before](../../shots/wave13-gfx-before-high-desktop.png) | [desktop after](../../shots/wave13-gfx-after-high-desktop.png) |

## Low performance

The capture suite sampled 120 rendered frames per size on Mesa llvmpipe Compatibility/GLES3. FPS is a software-renderer estimate, not a phone measurement. Other Godot jobs were active on this host, so FPS is noisy; draw calls and primitives are the more stable comparison.

| Size | Draw calls before → after | Triangles before → after | FPS estimate before → after |
| --- | ---: | ---: | ---: |
| 844×390 | 60 → 60 | 80,931 → 81,739 | 30.9 → 15.8 |
| 1366×768 | 249 → 249 | 156,889 → 156,889 | 7.9 → 7.9 |

The small phone triangle delta follows the initial battle-camera settle; no mesh geometry changed. Low draw calls are unchanged, and it adds no screen-space or other per-pixel post effect. The Low tier still renders within the existing 300K triangle ceiling. The software FPS numbers do not establish a phone FPS change while other jobs compete for the host CPU.

## Verification

- Headless import: passed.
- `gfx13_test` checks both viewport sizes, map materials, selected-marker tile bounds, range-grid presence and Low settings. Rendered Low and High captures: zero suite failures.
- Full `./godot/test.sh`: exit 0; every suite reports zero failures; zero `SCRIPT ERROR` lines. Normal rescue is 9/20 in both checks. W11 families: holocron 8/20, evacuation 16/20, duel 16/20, all inside their bands.
- `git diff --check`: clean.

## Remaining gaps and cross-lane request

- XCOM 2 still has richer authored set dressing and cinematic combat framing; the procedural map and existing GLBs cannot match that asset detail within this lane.
- At 844×390, the initial battle camera places the selected unit partly behind the bottom HUD. **Battle lane request:** keep the selected unit inside the unobscured map area on phone. Camera/HUD files are outside the gfx lease.
- Medium still uses material contact tint for ambient occlusion; High uses SSAO. Enabling Medium SSAO would change the existing graphics-tier contract tested by `graphics_test.gd`, outside this lane's test lease.
- Headless import generated untracked `.uid` files outside the gfx lease. They were left untouched and are not part of this commit.
