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
