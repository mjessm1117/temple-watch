# Wave 14 map lane

## Player result

All eight battle themes now have map-seeded floor wear and sparse vertex-coloured surface marks. Non-blocking, instanced bits of stone, metal debris, foliage, snow, or crystal sit on open tiles away from cover and units. Med/High adds one warm or cool accent light and a small floor decal; Low uses material and vertex tint with no added light, decal, shadow, fog, glow, or post effect. Move-range outlines are strongest close to the selected unit and fade with distance. No mission, LOS, cover, tile, AI, or balance data changed.

## Low Compatibility rendering

Seed 17, same eight mission maps and camera at 844×390 and 1366×768; maxima over 24 rendered frames per view. Values are **triangles / draw calls**, before → after. The fixture renders the battle map and mission markers; the separate rescue shots below show the in-game HUD and grid. Renderer: Mesa Intel RPL-S Compatibility.

| Theme | Phone 844×390 | Desktop 1366×768 |
| --- | ---: | ---: |
| Temple | 59,032 / 23 → 60,044 / 25 | 58,976 / 22 → 60,044 / 25 |
| Dock | 59,114 / 30 → 59,322 / 31 | 59,066 / 29 → 59,370 / 32 |
| City | 59,917 / 28 → 60,259 / 30 | 59,917 / 28 → 60,259 / 30 |
| Ruins | 169,640 / 27 → 171,030 / 29 | 171,140 / 27 → 172,530 / 29 |
| Snow | 49,493 / 34 → 51,261 / 35 | 49,493 / 34 → 51,261 / 35 |
| Jungle | 129,266 / 24 → 131,375 / 24 | 129,238 / 23 → 131,375 / 24 |
| Plains | 77,044 / 26 → 77,814 / 27 | 77,008 / 25 → 77,814 / 27 |
| Caves | 74,844 / 27 → 77,054 / 28 | 74,812 / 26 → 77,054 / 28 |

The largest draw increase is Temple desktop, **22 → 25 (+13.6%)**. The largest triangle increase is Snow, **49,493 → 51,261 (+3.6%)**. Both are below the +15% lane limit. Clutter uses the existing MultiMesh batch. Every added prop mesh is under 800 triangles; the art has no collision.

The full rescue fight was also measured at both exact sizes with [map14_perf.gd](map14_perf.gd): same seed, fixed SubViewport, 90 Low Compatibility frames on Mesa Intel RPL-S. Phone: **104,523 triangles / 81 draws → 106,271 / 85** (+1.7% / +4.9%). Desktop: **101,081 / 102 → 102,093 / 104** (+1.0% / +2.0%). These counters include the units, HUD, and range grid. The one-off window runs exited 0 and logged Godot GL texture cleanup warnings at exit; the required `test.sh` gate had no `ERROR` or `SCRIPT ERROR` lines.

## Captures

All theme images are real Low Compatibility renders, inspected at both sizes. Each pair uses the same mission seed and camera.

| Theme | Phone before → after | Desktop before → after |
| --- | --- | --- |
| Temple | [before](../../shots/wave14-map-before-temple-phone.png) → [after](../../shots/wave14-map-after-temple-phone.png) | [before](../../shots/wave14-map-before-temple-desktop.png) → [after](../../shots/wave14-map-after-temple-desktop.png) |
| Dock | [before](../../shots/wave14-map-before-dock-phone.png) → [after](../../shots/wave14-map-after-dock-phone.png) | [before](../../shots/wave14-map-before-dock-desktop.png) → [after](../../shots/wave14-map-after-dock-desktop.png) |
| City | [before](../../shots/wave14-map-before-city-phone.png) → [after](../../shots/wave14-map-after-city-phone.png) | [before](../../shots/wave14-map-before-city-desktop.png) → [after](../../shots/wave14-map-after-city-desktop.png) |
| Ruins | [before](../../shots/wave14-map-before-ruins-phone.png) → [after](../../shots/wave14-map-after-ruins-phone.png) | [before](../../shots/wave14-map-before-ruins-desktop.png) → [after](../../shots/wave14-map-after-ruins-desktop.png) |
| Snow | [before](../../shots/wave14-map-before-snow-phone.png) → [after](../../shots/wave14-map-after-snow-phone.png) | [before](../../shots/wave14-map-before-snow-desktop.png) → [after](../../shots/wave14-map-after-snow-desktop.png) |
| Jungle | [before](../../shots/wave14-map-before-jungle-phone.png) → [after](../../shots/wave14-map-after-jungle-phone.png) | [before](../../shots/wave14-map-before-jungle-desktop.png) → [after](../../shots/wave14-map-after-jungle-desktop.png) |
| Plains | [before](../../shots/wave14-map-before-plains-phone.png) → [after](../../shots/wave14-map-after-plains-phone.png) | [before](../../shots/wave14-map-before-plains-desktop.png) → [after](../../shots/wave14-map-after-plains-desktop.png) |
| Caves | [before](../../shots/wave14-map-before-caves-phone.png) → [after](../../shots/wave14-map-after-caves-phone.png) | [before](../../shots/wave14-map-before-caves-desktop.png) → [after](../../shots/wave14-map-after-caves-desktop.png) |

Actual rescue scene: [phone grid before](../../shots/wave14-map-before-grid-phone.png) → [after](../../shots/wave14-map-after-grid-phone.png); [desktop grid before](../../shots/wave14-map-before-grid-desktop.png) → [after](../../shots/wave14-map-after-grid-desktop.png).

## Verification and remaining gaps

`./godot/test.sh` exited **0** with **0 SCRIPT ERROR lines** and **0 failures in every suite**; Normal rescue remained **9/20**. The map art regression passed **185,795 checks, 0 failures**, including identical map/RNG state, passability, LOS, cover, and elevation after art builds. The `map14` suite checks both viewport sizes, seeded surfaces, safe prop placement and mesh budgets, accent light/decal tier rules, Low effects, and grid fade. It passed **594 checks, 0 failures** on each headless tier and **626 checks, 0 failures** with Low captures. [Full gate log](full-gate.log) and `git diff --check` are clean.

XCOM 2 still has much richer authored scene composition, cover silhouettes, and dramatic local light. The new marks and small props reduce repetition but do not replace new cover assets or camera work. The battle lane owns phone tactical framing and HUD overlap; no map-lane code touches that camera. No cross-lane edit is required.

An optional Meshy quote for one additional cover silhouette in each of the seven decided themes is **210 credits** at the batch ledger's 20-credit preview and 10-credit refine rates (7 × 30). **0 credits spent.** Jungle half cover is excluded pending Jess's decision; `cover_half_jungle_v6` remains unwired.
