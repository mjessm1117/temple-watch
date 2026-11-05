# Art swap after Wave 13

## Shipped art

Merged `art/blender1` into `art/swap13`, then copied all nine approved phone-slim GLBs over the game’s existing resource paths. The five unit models are `agent`, `jedi`, `scout`, `sithHeavy`, and `trooper`; the four map models are `relay`, `gantry`, `statue`, and `shuttle`. Each replacement is byte-identical to its staged `_v2` GLB in the merge commit. The old `.glb.import` files retain `meshes/generate_lods=true` and the existing resource UIDs. Removed `assets/models_v2/` so there is one copy of each model in the build.

Selected Meshy batch-6 `half_cover` and `_lod1` pairs for temple, dock, plains, city, ruins, and caves in `props.json`. A top-level `meshy_lod_assets` list keeps the derived LOD1 resources in the disposable Web copy; the existing `meshy_theme_batch.gd` distance and quality switching uses the matching filenames. The caves texture lift moved to the new cover path and increased from 0.14 to 0.30 after the first capture showed the rocks too dark. Jungle `cover_half_jungle_v6` remains staged and unselected.

## Visual and rendered-frame comparison

[Before/after sheet](/home/jess/projects/tw-logs/art13/art13-before-after.jpg) is one 1800 px wide JPG. It compares the same rescue battle camera on main `6ad3117` and this swap for temple, city, and caves at 844×390 Compatibility/Low and 1366×768 Forward+/Medium. The main worktree was isolated at `/tmp/art13-base` for capture. All twelve PNG captures are in `/home/jess/projects/tw-logs/art13/`.

The standard `gfx13_test.gd` rescue-scene sample below records the **maximum rendered-frame** counters over 120 frames with the same resolution and Compatibility/Low settings on both builds. The desktop row is 1366×768, still Compatibility/Low for a like-for-like performance sample. Renderer is Mesa llvmpipe, so these are geometry and draw-call counts, not device frame-rate results. The separate desktop images use Forward+/Medium as requested.

| Typical rescue fight | Triangles before → after | Draw calls before → after |
|---|---:|---:|
| Phone, 844×390 | 124,713 → 109,651 | 82 → 82 |
| Desktop, 1366×768 | 154,001 → 105,195 | 102 → 103 |

For the matching scene captures, the single captured frame measured:

| Theme | Phone triangles / draws before → after | Desktop triangles / draws before → after |
|---|---:|---:|
| Temple | 69,777 / 20 → 64,271 / 20 | 259,574 / 43 → 174,611 / 43 |
| City | 41,587 / 25 → 54,972 / 21 | 152,815 / 50 → 152,807 / 42 |
| Caves | 75,817 / 26 → 70,581 / 22 | 262,393 / 51 → 178,043 / 43 |

City’s phone triangle count rises because the replacement cover has more top-level geometry; its draw calls fall. The other five shown tri/draw comparisons are lower or equal except for the typical-fight desktop draw calls (+1). All counts are scene-dependent and are affected by Godot’s LOD selection.

## Gates

- `python3 tools/web/prepare_web.py /tmp/art13-webcheck`: exit 0; 40 unused Meshy GLBs and 116 duplicate rasters omitted. All nine swapped originals, six v6 covers, and six `_lod1` companions (21 GLBs) are present and absent from the omitted list.
- Godot 4.7.2 headless import: exit 0 after the GLB swap.
- `./godot/test.sh`: exit 0; 47 zero-failure result lines, 0 `SCRIPT ERROR`, 0 `ERROR:` lines; Normal rescue **9/20** wins, within the required 9–11 band. `map_art_test` alone reports 179,474 checks, 0 failures.
- `git diff --check` and `git diff --cached --check`: clean.
- No `public/`, `functions/`, `tests/`, or `worker.js` files were changed. No push.

## Review fix pass

The map-art loader fits each model uniformly to at most 0.98 m horizontal span and 0.8 m height. The table uses the loader's recorded world-space AABB for tile (5, 5), in **width × depth × height** metres. Screen area is the same AABB's eight corners projected through the 844×390 battle camera; it is a repeatable projected bounding box, not a count of opaque pixels. The before column is main `6ad3117`, and after is the final swap.

| Theme | World bounds before → after (m) | Phone projected box area before → after (px²) | Area ratio |
|---|---|---:|---:|
| Temple | 0.980×0.864×0.799 → 0.962×0.953×0.800 | 3,720 → 3,916 | 105.3% |
| Ruins | 0.968×0.785×0.800 → 0.977×0.980×0.800 | 3,478 → 4,034 | 116.0% |
| Plains | 0.980×0.980×0.721 → 0.956×0.876×0.800 | 3,793 → 3,689 | 97.2% |
| Dock | 0.980×0.922×0.797 → 0.980×0.980×0.797 | 3,873 → 4,033 | 104.1% |
| City | 0.980×0.404×0.786 → 0.960×0.960×0.800 | 2,532 → 3,929 | 155.2% |
| Caves | 0.980×0.980×0.747 → 0.960×0.950×0.800 | 3,874 → 3,901 | 100.7% |

The caves swap entered review at 0.960×0.459×0.800 m; its narrow depth caused the shard silhouette. Widened the positions and corrected the normals in both LOD GLBs to make the final 0.960×0.950×0.800 m fit. Its three final dimensions differ from the old prop by 2.0%, 3.1%, and 7.1%. Raised the caves texture contrast lift to 0.40 and added a restrained purple emission to separate it from the dark floor at phone Low. City received a 0.12 material lift; its phone projected area already exceeds the old piece, so no scale change was needed. Temple, ruins, plains, and dock have no footprint or height dimension more than 20% smaller than before.

The sheet was regenerated at 1800×3597 px and inspected. It retains temple, city, and caves at phone Low and desktop Medium, and adds a phone aim-camera row from the same capture sequence used by `battle13_test.gd`, comparing main `6ad3117` with this swap. Its path remains `/home/jess/projects/tw-logs/art13/art13-before-after.jpg`.

The larger unit GLB source files use many more small buffer views and a larger JSON table; their embedded WebP textures retain the same byte counts and 1024×1024 resolution as main. The real Web export remains below the shipped PCK limit, so the triangle-saving unit geometry was retained. Reimport also exposed a stale `shuttle.glb` image name: the GLB requested `shuttle_Image_0.webp` while the checked-in extracted file is `shuttle_0.webp`. The GLB image name now matches the existing texture.

### Fix-pass gates

- Real `tools/web/export_web.sh` run with its output redirected to `/tmp/art13-web-export`: final `index.pck` **24,961,840 bytes**, versus shipped **26,663,064 bytes** (1,701,224 bytes smaller). The export reported no `SCRIPT ERROR`, `Parse Error`, or `ERROR:` lines.
- `python3 tools/web/prepare_web.py /tmp/art13-webcheck2`: exit 0; 40 unused Meshy GLBs and 116 duplicate rasters omitted.
- Final Godot 4.7.2 headless import: exit 0; 0 `SCRIPT ERROR`, 0 `ERROR:` lines.
- Final `./godot/test.sh`: exit 0; 47 zero-failure result lines, 0 `SCRIPT ERROR`, 0 `ERROR:` lines. Normal rescue **9/20** wins; `map_art_test` **179,474 checks, 0 failures**.
- `git diff --check` and staged diff check: clean. No web-game files changed; no push.
