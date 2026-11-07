# W16 jungle half cover — staged review

The new prop is staged at `godot/assets/maps/meshy7/cover_half_jungle_v7.glb`, with `_lod1.glb` beside it. **No game wiring changed.** The [comparison sheet](../../shots/w16-jungle-before-after.jpg) shows OLD procedural, rejected v6 sandbags, and v7 in the jungle map at both requested sizes. The original full captures are [844×390](../../shots/w16-jungle-844x390.png) and [1366×768](../../shots/w16-jungle-1366x768.png), rendered in Compatibility/Low.

## Spend and fit

One Meshy preview and one refine succeeded, for **30/40 authorized credits**. The preview had a broad, solid cover face, so it passed the gate for refinement. Task IDs and read-only balances before and after each call are in [ledger.md](ledger.md). The submitted text and texture brief is [brief.json](brief.json).

| Mesh | Triangles | Width × depth × height (m) | Floor |
|---|---:|---|---:|
| LOD0 | 1,500 | 0.955 × 0.700 × 0.796 | 0.0001 m |
| LOD1 | 800 | 0.951 × 0.700 × 0.796 | 0.0002 m |

The model is within one 1 m tile. The map-art loader and review harness floor-fit half cover to **0.8 m display height**; cover rules and line of sight remain unchanged. Fit used the same Blender script as v6, then `prop.mjs` simplification. After the refine, I added a small dark brown low-poly trunk across the stone because Meshy's original trunk was grey and indistinct at battle-camera distance. That local mesh edit used no additional credits.

## Visual read

**Stronger than OLD and v6:** v7 is a broad, opaque ruin mass instead of a pale bag pile. Its dark grey-green stone and diagonal brown timber separate from the yellow-green jungle floor at both sizes. There are no leaves, vines, sandbags, crates, or ground plate in the staged model.

**Limitations:** the Meshy stone is upright and rectilinear, not convincingly toppled. The original carved face is subtle from the high camera. The added timber reads clearly as wood by color and angle, but its low-poly top is straighter than a natural fallen trunk. The prop is darker than nearby cover. Jess should judge the sheet before any swap.

## Gate and later wiring

Godot headless import exited 0. Both capture scripts saved with code 0. The isolated software OpenGL capture emitted two texture-leak messages at shutdown after saving each image. `./godot/test.sh` exited **0**. Every suite reported **0 failures**, including 185,795 map-art checks; the gate log contains **0 SCRIPT ERROR** and **0 ERROR:** lines. `git diff --check` and `git diff --cached --check` are clean.

Later wiring, if approved: in `godot/data/maps/props.json`, add the one jungle mapping line `"half_cover": "res://assets/maps/meshy7/cover_half_jungle_v7.glb"` (with a comma after the existing `full_cover` line). The existing mapped-cover branch in `map_art_geometry.gd` will then use this prop only for jungle.
