# Mobile web 3 load speed

Measured on 2026-11-04 with Godot 4.7.2. The source build is the original Web export (`index.pck` 64,979,884 bytes); the optimized build comes from `./tools/web/export_web.sh`. The script copies `godot/` to a temporary directory, runs Godot's importer there, changes only the copy's texture `.import` files, and exports to `build/web/`. Windows and Linux presets, source assets, and source `.import` files are unchanged.

## Download size

All numbers below are bytes (decimal MB = 1,000,000 bytes). The transfer estimate uses gzip level 6 for HTML, JavaScript, JSON, wasm, and pck, plus raw PNGs, matching the baseline Pages behavior. It counts **every** emitted web file, including PWA icons and the splash image, so actual first-visit requests can be slightly lower.

| File | Before raw | Before gzip | After raw | After gzip | Change in gzip |
|---|---:|---:|---:|---:|---:|
| `index.pck` | 64,979,884 | 62,786,448 | 26,583,384 | 24,610,531 | −38,175,917 |
| `index.wasm` | 39,514,754 | 10,114,291 | 39,514,754 | 10,114,291 | 0 |
| `index.js` | 279,815 | 68,740 | 279,815 | 68,740 | 0 |
| **All emitted files, estimated transfer** | — | **73,014,148 (73.01 MB)** | — | **34,927,261 (34.93 MB)** | **−38,086,887 (−52.2%)** |

### Inside the pack

The measurement uses `tools/web/list_pack.gd` to mount each `.pck` in an otherwise empty project and sum file lengths. The small difference from the physical pack size is pack directory and alignment overhead. Imported `.ctex` and images are counted as textures; imported `.scn`, GLBs, and meshes as GLB/mesh. Categories are sorted by baseline bytes, largest first.

| Type | Before files | Before bytes | After files | After bytes |
|---|---:|---:|---:|---:|
| Textures | 189 | 39,640,866 | 154 | 3,388,136 |
| GLB/mesh | 106 | 22,302,910 | 74 | 20,483,320 |
| Data | 111 | 1,757,220 | 110 | 1,753,026 |
| Other (scripts, UIDs, metadata) | 697 | 1,174,724 | 554 | 877,058 |
| Audio | 0 | 0 | 0 | 0 |
| Fonts | 0 | 0 | 0 | 0 |
| **Pack file payload** | **1,103** | **64,875,720** | **892** | **26,501,540** |

Largest baseline entries (the suffix identifies the imported resource):

| Bytes | Type | Entry |
|---:|---|---|
| 1,495,786 | Texture | `heavy_texture_0.webp-…ctex` |
| 1,355,526 each × 3 | Texture | `scout_texture_0.webp-…ctex` (battle, loadout, UI copies) |
| 1,346,416 each × 3 | Texture | `jedi_texture_0.webp-…ctex` (battle, loadout, UI copies) |
| 1,339,818 | Texture | `medic_texture_0.webp-…ctex` |
| 917,559 | GLB/mesh | `human.glb-…scn` |
| 915,624 | GLB/mesh | `medic.glb-…scn` |
| 899,693 | GLB/mesh | `trooper.glb-…scn` |
| 899,508 | GLB/mesh | second `trooper.glb-…scn` |

### What was removed from the web copy

- **32 Meshy GLBs** (and their import metadata): old temple and jungle variants and generated `_lod1` review models. The copy script checks each candidate's full `res://` path against all game JSON and non-authoring scripts. `data/maps/props.json` is the runtime selector for Meshy themes and objectives; it points to none of the excluded variants. Authoring `*_stage.gd` and `*_capture.gd` files can mention review models but are not called by the game. The real asset files remain intact.
- **102 standalone raster source files** (and their import metadata) in the disposable copy. A scan of game scripts and JSON finds no direct `res://assets/*.png`, `.webp`, or `.jpg` load path. Every asset GLB was checked at the binary glTF level: its images use embedded `bufferView`s and no external image URI. Godot re-extracts the images needed by retained GLBs during import. Dynamic `res://assets/loadout/icons/%s.svg` icons remain included.
- **`godot/tests/`** is absent from the web copy after checking that game scripts, JSON, and `project.godot` contain no `res://tests/` load path. The full test suite still runs from the untouched source tree.
- Reference art, screenshots, and source art live outside the `godot/` project and were already absent from the original pack. No file in those directories was removed.

## Texture and audio choice

Godot's extracted model textures are reimported in the temporary project as **Lossy WebP, quality 0.60, maximum dimension 512 px**. Mipmaps remain enabled. The build script forces one final texture reimport after GLB extraction, because a prior clean build retained one larger lossless import. This reduced texture payload from 39.64 MB to 3.39 MB. Lossy WebP is decoded by Godot without relying on S3TC/BPTC GPU support, so it is the common path for Android Chrome and iPhone Safari. It is smaller in this build than the previous lossless imports; VRAM-uncompressed would send substantially more data. The tradeoff is higher decoded texture memory than GPU block compression and some softness in close views. [Godot image import modes](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html), [size limit option](https://docs.godotengine.org/en/stable/classes/class_resourceimportertexture.html).

There are no WAV, OGG, or MP3 entries in the baseline pack and no audio source files under `godot/assets/`; conversion would save zero bytes.

## Loading and repeat visits

`godot/web/shell.html` shows a themed progress bar, numeric percent, and “Loading Temple Watch...” immediately, then “Preparing Temple Watch...” during engine setup. It uses inline CSS/JS and system fonts. Captures: [mid-load](../shots/mobile-web3-loading.png) and [title](../shots/mobile-web3-title.png).

Godot's PWA worker is enabled with threads still disabled. `tools/web/version_service_worker.py` replaces the generated cache version with a hash of the exported files and makes new workers activate and claim clients. The shell registers the worker at the relative `./` scope, which resolves to `/temple-watch-play/` on Pages, asks for an update, and reloads an old controlled page when the new worker claims it. On the local subpath test, the first visit populated the cache with `index.pck`; the second visit served `index.pck`, `index.wasm`, and `index.js` from the service worker with no pack re-download. The changed-build simulation replaced the cached pack with a new byte length and removed the old cache; the worker fetches with `cache: reload` to avoid stale browser HTTP cache. [Godot PWA behavior](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html).

## Phone timing and visual check

The headless Chromium phone harness is `node tools/web/measure_web.cjs`: 844×390, touch enabled, device scale 1, local HTTP server under `/temple-watch-play/`, fresh browser context. It waits for Godot's load overlay to leave, then captures the title. The **155 s** baseline supplied for live GitHub Pages is a different network run; the local unoptimized baseline below is the direct comparison for this harness. The local server sends raw files, while the transfer column above estimates Pages gzip. The original local build downloaded 104,774,453 raw bytes across pck/wasm/js; the optimized build downloaded 66,377,953. These are transfer payloads before the small HTML/icon files. The first optimized visit passes through the new worker and fetches those assets from the server; the repeat visit serves them from CacheStorage.

| Run | Time to title | Last pck/wasm response end | Page errors |
|---|---:|---:|---:|
| Original export, local harness | 6.05 s | 0.42 s | 0 |
| Optimized export, local harness | 7.94 s | 0.74 s | 0 |
| Original export, live Pages baseline supplied | about 155 s | not recorded | not recorded |

The optimized local run did **not** improve time to title on this fast local server: 7.94 s versus 6.05 s. The result is consistent with PWA setup and run-to-run startup variation; their individual contributions were not measured. The supplied 155 s baseline was measured on live Pages, which cannot be compared directly with this local run; no optimized Pages deployment was authorized, so live after timing remains unmeasured. The 38.09 MB estimated transfer reduction should help on slower links, but that effect has not been timed on the live host.

The title, Direct Rescue battle, opening story choices, and Temple home were visually inspected at 844×390. Unit silhouettes, cover blocks, grid, room outlines, and home labels remain distinguishable. Textures are a little softer at close zoom due to the 512 px cap and lossy encoding. The home's narrow resource row remains dense, but the labels can be read. Actual Android Chrome and iPhone Safari were not available in this headless check.

## Validation

- `./godot/test.sh`: **EXIT=0**, 0 script errors, every suite 0 failures, Normal rescue bot **10/20**.
- Optimized web export reaches the title with 0 page errors and first/repeat cache checks as above.
- `node tools/web/check_cache_update.cjs`: **EXIT=0**. The simulated next pack was one byte larger; the new cache contained that exact byte length, the old cache was removed, the server saw two pack GETs (first build and changed build), and there were 0 page errors.
