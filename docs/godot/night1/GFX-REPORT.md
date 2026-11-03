# Night 1 graphics report

## Theme moods

| Theme | Mood |
|---|---|
| temple | Warm gold dusk |
| snow | Cold blue dawn |
| jungle | Humid green haze |
| city | Sodium night |
| dock | Industrial blue hour |
| caves | Cool subterranean glow |
| ruins | Violet twilight |
| plains | Harsh dry noon |

The eight presets live in `godot/scripts/gfx_theme_presets.gd`. Each controls sun color, angle and energy; ambient color and energy; fog color, density and height; ACES exposure; and glow intensity. The battle environment and light use those values on every theme.

## Tier matrix

| Feature | High | Medium | Low |
|---|---|---|---|
| Renderer | Forward+ | Forward+ | Compatibility on restart |
| Soft directional shadows | On | Hard shadows | Off |
| SSAO | On | Off | Off |
| Glow on emissive sabers, bolts and beacons | Full | Reduced | Off |
| Fog | Distance + subtle height | Distance only | Off |
| Volumetric fog | Off (height fog used) | Off | Off |
| Unit rim and selection ring | On | On | On, Compatibility shader |
| FX lights and sparks | Full | Reduced | No lights, four sparks max |
| Cinematic depth of field | Existing action camera only | Off | Off |
| Scorch marks | 24 maximum, fade in three turns | 24 maximum | 12 maximum |

The graphics menu keeps its existing Low/Medium/High choice. Effects follow the selected tier automatically; no separate effect toggle is needed.

## Performance

Same 1920×1080 capture harness, seed 17, 45 measured frames after scene warmup, VSync off. Runs were sequential on this machine. Draw calls and triangle counts are frame maxima. FPS is a short capture sample and can vary with machine load; Low ran through the Compatibility software driver here, so its FPS is not a phone benchmark.

| Theme | Low triangles | Low draws | High before FPS | High after FPS | High change |
|---|---:|---:|---:|---:|---:|
| temple | 147,704 | 43 | 33.1 | 30.1 | -8.8% |
| snow | 151,247 | 57 | 26.7 | 27.8 | +4.0% |
| jungle | 231,233 | 47 | 23.8 | 27.5 | +15.8% |
| city | 175,252 | 61 | 23.0 | 28.6 | +24.3% |
| dock | 183,582 | 54 | 22.8 | 30.3 | +32.9% |
| caves | 247,240 | 53 | 23.7 | 24.9 | +4.8% |
| ruins | 270,424 | 52 | 22.5 | 23.8 | +5.7% |
| plains | 217,695 | 51 | 24.4 | 25.0 | +2.5% |

All eight Low views are below 300,000 triangles and 150 draw calls. The largest is ruins at 270,424 triangles and 52 draws. The largest measured High FPS regression is temple at 8.8%, below the 15% limit.

## Captures

All images are native 1920×1080 PNGs. Each row links to the before and after views for both required tiers.

| Theme | High before | High after | Low before | Low after |
|---|---|---|---|---|
| temple | [before high](../shots/night1-gfx-before-temple-high.png) | [after high](../shots/night1-gfx-after-temple-high.png) | [before low](../shots/night1-gfx-before-temple-low.png) | [after low](../shots/night1-gfx-after-temple-low.png) |
| snow | [before high](../shots/night1-gfx-before-snow-high.png) | [after high](../shots/night1-gfx-after-snow-high.png) | [before low](../shots/night1-gfx-before-snow-low.png) | [after low](../shots/night1-gfx-after-snow-low.png) |
| jungle | [before high](../shots/night1-gfx-before-jungle-high.png) | [after high](../shots/night1-gfx-after-jungle-high.png) | [before low](../shots/night1-gfx-before-jungle-low.png) | [after low](../shots/night1-gfx-after-jungle-low.png) |
| city | [before high](../shots/night1-gfx-before-city-high.png) | [after high](../shots/night1-gfx-after-city-high.png) | [before low](../shots/night1-gfx-before-city-low.png) | [after low](../shots/night1-gfx-after-city-low.png) |
| dock | [before high](../shots/night1-gfx-before-dock-high.png) | [after high](../shots/night1-gfx-after-dock-high.png) | [before low](../shots/night1-gfx-before-dock-low.png) | [after low](../shots/night1-gfx-after-dock-low.png) |
| caves | [before high](../shots/night1-gfx-before-caves-high.png) | [after high](../shots/night1-gfx-after-caves-high.png) | [before low](../shots/night1-gfx-before-caves-low.png) | [after low](../shots/night1-gfx-after-caves-low.png) |
| ruins | [before high](../shots/night1-gfx-before-ruins-high.png) | [after high](../shots/night1-gfx-after-ruins-high.png) | [before low](../shots/night1-gfx-before-ruins-low.png) | [after low](../shots/night1-gfx-after-ruins-low.png) |
| plains | [before high](../shots/night1-gfx-before-plains-high.png) | [after high](../shots/night1-gfx-after-plains-high.png) | [before low](../shots/night1-gfx-before-plains-low.png) | [after low](../shots/night1-gfx-after-plains-low.png) |

[Mid-attack FX capture](../shots/night1-gfx-fx.png) shows the saber swing trail and opposing blaster bolts.

## Verification and scope

- `gfx_night1_test.gd` covers all eight presets, tier effects, Compatibility-safe unit rims, selection rings, scorch cap/fade, cinematic depth of field, and tier round-trips.
- The existing graphics suites cover live switching, renderer restart behavior, resource limits, and screens.
- `./godot/test.sh` exited 0 with zero SCRIPT ERROR lines and zero failures in every suite; Normal rescue bot was 10/20. The separate FX unit test passed 10 checks with zero failures.
- Volumetric fog was skipped in favor of height fog on High to keep the render cost within the measured FPS limit.
- No art assets or models were downloaded or changed.
