# Graphics tiers

Implemented on `gfx/tiers` for Jess's 2026-11-01 approval. High preserves the existing presentation; graphics preferences never change mission, map, difficulty or balance data.

## Player setting and startup

The existing temple **Presentation settings** and the title screen now have a shared Graphics selector: **Low / Medium / High**. It saves `user://graphics.cfg`, loads at boot, defaults to High on desktop and Low on Android/iOS, and applies presentation changes immediately. A renderer mismatch displays **“Renderer change applies on restart.”**

`application/config/project_settings_override` points to `user://override.cfg`. Selecting Low writes `gl_compatibility`; Medium/High write `forward_plus`, including the `.mobile` override. Unrelated override entries are preserved. Godot's `rendering_device/fallback_to_opengl3` remains explicitly enabled. The controller reads the actual renderer, so a saved High/Medium preference runs as Low when Godot starts in Compatibility. Selecting High again cannot upgrade that running process; it requires restart and supported hardware.

This uses Godot's documented [startup override mechanism](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html#class-projectsettings-property-application-config-project-settings-override) and [renderer fallback behavior](https://docs.godotengine.org/en/4.5/tutorials/rendering/renderers.html).

## What changes

| Setting | Low | Medium | High (existing look) |
| --- | --- | --- | --- |
| Renderer after restart | Compatibility | Forward+ | Forward+ |
| Shadows | Off | Hard directional, 1024 atlas | Existing soft directional, 2048 battle atlas; original project settings outside battle |
| Battle SSAO | Off | Half resolution, original low sampling quality, 60% intensity | Existing half resolution/low sampling quality, full authored intensity |
| Glow | Off | 60% authored intensity | Original authored glow |
| SSIL / volumetric fog | Off | Preserve authored enable state; 60% intensity/density if enabled | Preserve authored enable state and values |
| Ordinary distance fog, sky, lighting palette | Retained, including existing Compatibility exposure compensation | Retained | Unchanged |
| MSAA | Off | Off | Original viewport values (battle off, UI stages 2× where authored) |
| Screen-space AA | Off in Compatibility | FXAA | Original viewport values |
| Imported mesh LOD threshold | Battle 12; other viewports 3× their original threshold | Battle 6; others 1.5× | Battle 4; others unchanged |
| Explicit Meshy prop LODs | Existing LOD1 at every distance | Switch at 60% of original distance | Original distances and meshes |
| Weather / dust / ember counts | 20%, CPU particles in Compatibility | 50%, GPU particles | 100%, original GPU particles |
| Texture dimensions | Runtime copies capped at 1024 on either axis | Original | Original |
| 3D render scale | 0.75 on Android/iOS only; desktop 1.0 | Original/native | Original/native |
| Cover damage scars | One batched transparent mesh instead of unsupported projected decals | Original decals | Original decals |

Changes cover newly created battle objects, temple/galaxy subviewports, portraits and existing objects when the setting changes. Per-object baselines restore High after repeated switches. LOD tagging does not depend on sibling node names. Texture reductions use copies; source assets, imports and `props.json` are unchanged. Tactical grid shader parameters continue updating on their original materials.

**High ceiling decision:** the shipped environments do not enable SSIL or volumetric fog. Turning them on would change today's look. Their authored states are therefore preserved on High, rather than adding the proposed future effects. The existing brazier flame geometry and four-light limit remain; the particle multiplier applies to emitters, including theme dust/embers. Compatibility does not support FXAA, so Low does not request it. See Godot's [antialiasing support table](https://docs.godotengine.org/en/4.5/tutorials/3d/3d_antialiasing.html).

## Rendered measurements

Godot **4.7.2**, NVIDIA **GeForce RTX 4090 Laptop GPU**, Linux/Xvfb, **1366×768**, VSync disabled. `cache` / Listening Post Besh is **34×34**, tied for the largest authored map area. Same seed (17), units, turn, camera and HUD on every tier. Each sample uses 600 frame intervals after a three-second warmup. Counts are the maximum observed engine counters, including HUD/subviewports and extra rendering passes. “Primitives” is Godot's `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, a conservative budget counter including triangles and any other primitives.

| Tier | FPS average | FPS p95 | Frame time p95 | Max draw calls | Max primitives |
| --- | ---: | ---: | ---: | ---: | ---: |
| Low | 33.67 | 45.41 | 52.22 ms | 100 | 230,948 |
| Medium | 25.76 | 49.25 | 61.02 ms | 128 | 416,261 |
| High | 25.10 | 48.43 | 62.83 ms | 128 | 472,325 |

Raw results: [low.json](low.json), [medium.json](medium.json), [high.json](high.json). The JSON also records FPS at the p95 frame time (the slow-frame interpretation), separately from the 95th percentile of instantaneous FPS.

**Low passes the ≤150 draw / ≤300,000 primitive budgets.** These are desktop renderer measurements, not phone benchmarks. Other Godot jobs were active on this shared host during the captures; timing varied substantially between runs. The recorded run does **not** establish sustained 60 FPS or a smooth 30 FPS floor. Device profiling and an uncontended timing run remain required before certifying those targets. No frame intervals were trimmed from the reported timing samples.

## Verification

- `./godot/test.sh` runs isolated user storage, four real restart/persistence processes, all existing suites, and the new graphics suite three times. Low explicitly uses `--rendering-method gl_compatibility`; Medium/High use Forward+.
- The graphics suite loads **dock, city, jungle, snow, temple, ruins, plains and caves**, plus the largest map, **22 temple rooms**, **14 galaxy planets**, and the title/settings UI.
- It verifies mobile/desktop defaults, actual renderer fallback policy, saved overrides including mobile, invalid preference recovery, unrelated override preservation, repeated live switching, unchanged mission state, restoration of High, every explicit LOD group, texture reduction/source preservation, particles and cover-damage representation.
- Actual OpenGL and Vulkan runs compile/render all these scenes. No shader required replacement: existing terrain, stone, planet, atmosphere, nebula, star and UI shaders work in Compatibility. The projected-decal limitation has a batched mesh fallback.
- The capture helper lets the initial battle finish setting up before replacing its fixture. Rebuilding it before the first frame produced Compatibility texture-leak diagnostics during shutdown; normal scene lifecycles and the settled fixture are clean.

Final result: **`./godot/test.sh` exited 0; every suite reported 0 failures**, with no script or engine errors. Normal remains **10/20 wins (50%)**, inside the unchanged **9–12/20 (45–60%)** band. [Full headless log](headless.log).

| Final scene suite | Headless checks | Actual renderer checks | Failures/errors |
| --- | ---: | ---: | ---: |
| Low / Compatibility | 267 | 267 | 0 |
| Medium / Forward+ | 159 | 159 | 0 |
| High / Forward+ | 177 | 177 | 0 |

These final rendered checks include the cover-damage fallback and existing Presentation settings page: [Low](verify-low.log), [Medium](verify-medium.log), [High](verify-high.log).

Reproduce headless verification:

```bash
./godot/test.sh
```

Reproduce actual rendered verification and regenerate images/numbers (requires Xvfb and a graphics driver):

```bash
# NVIDIA PRIME variables select the discrete GPU on the verification host.
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  ./godot/tests/graphics-render.sh
```

The render runner checks process status and rejects script, shader/engine errors, and assertion failures. Logs are [Low](render-low.log), [Medium](render-medium.log), [High](render-high.log). The ordinary headless runner cannot establish shader compatibility or meaningful rendering performance by itself.

## Captures

Identical battle view: [Low](../shots/tiers-low.png), [Medium](../shots/tiers-med.png), [High](../shots/tiers-high.png). [Graphics setting](../shots/tiers-settings.png).

## Remaining device checks

No physical Android/iOS device, WebGL export, Vulkan-unavailable hardware, or D3D12 device was available. OS-default selection and forced-Compatibility fallback are tested; actual driver-failure recovery relies on Godot's enabled fallback. Mobile 0.75 scaling, power/thermal behavior, memory use and sustained phone FPS remain unmeasured. Low's scar meshes approximate the cover bounds rather than projecting precisely onto irregular models. Draw/primitive budgets were measured at the specified overview, not across every camera angle or late-battle reinforcements.

## Performance A/B

The identical `graphics_perf.gd` harness ran in a temporary `7c682bd` worktree and on `gfx/tiers`. It loaded `cache` with seed 17 and the same battle camera/HUD at 1366×768, disabled VSync, waited three seconds, then measured 600 process-frame intervals. Each run used a fresh `XDG_DATA_HOME`, Xvfb at `1366x768x24`, `__NV_PRIME_RENDER_OFFLOAD=1`, and `__GLX_VENDOR_LIBRARY_NAME=nvidia`. Base and High used Forward+; Low used Compatibility. The base imported its own unchanged assets before timing. The values below are medians of three sequential runs per variant; draw calls and primitives are the maximum observed within each run.

| Variant | Avg fps | p95 frame ms | Draws | Primitives |
| --- | ---: | ---: | ---: | ---: |
| Base `7c682bd` | 29.78 | 87.93 | 128 | 472,325 |
| High | 34.10 | 84.40 | 128 | 472,325 |
| Low | 36.31 | 82.80 | 100 | 230,948 |

Individual runs, in execution order: base **36.77/70.70**, **28.75/90.40**, **29.78/87.93**; High **34.10/84.40**, **35.78/80.97**, **33.98/85.90**; Low **32.61/86.66**, **36.31/82.80**, **48.63/39.38** (fps/p95 ms). All nine exited zero with no script or engine errors. An earlier pass before adding four scene-settling frames also showed matching base/High render counters and near-equal median fps; its apparent 35% High p95 regression disappeared on the corrected pass. That pass included immediate fixture replacement, which emitted Compatibility texture-leak errors on shutdown, so it is superseded here.

For a direct Wave 9 method check, `map_preview.gd -- cache --fps --benchmark --authored` ran once on each tree at 1920×1080, with its own 10-second warmup and 1,200-frame sample. Base measured **27.8 fps / 41.00 ms p95**, High **27.9 fps / 38.76 ms p95**; both had **128 draws**. The script exited 1 for both because its 60 fps assertion failed, after printing valid samples; neither had a script error. Wave 9's historical **244.8 fps / 9.10 ms** capture recorded **99 draws** on an earlier scene state, so it is not an A/B against today's `7c682bd`. Other Godot processes used the same RTX 4090 during the three-run checks, and timing swung widely even between base runs. The exact cause of the historical-to-current absolute fps gap remains unresolved; the current base result shows it is not attributable to tier code. Competing GPU jobs and intervening scene content are outside this file lease and were left untouched.

**Verdict:** High has no reproducible performance regression against `7c682bd` under the identical standalone harness. It has exactly the same measured rendering work, while its corrected median fps is 14.5% higher and p95 frame time 4.0% lower than base. These host-contended absolute fps values are not a device performance certification. The old 25 fps entry above came from sampling inside a suite that first loads every battle and repeatedly switches tiers. `graphics-render.sh` now runs captures separately from the standalone benchmark and writes `perf-{low,medium,high}.log`; the old JSON files remain historical measurements.
