# Jungle half cover v7

Merged `w16/jungle` at `246dc82`, brightened both v7 GLBs in Blender, and mapped the jungle `half_cover` entry in `godot/data/maps/props.json` to v7. The old procedural cover remains in code as an unused fallback. Godot's existing paired loader finds `_lod1.glb` automatically.

## Art and budget

Blender raised texture brightness by 18% with a small shadow lift and raised color separation by 8%. Untextured bark materials received the same brightness lift. The result remains stone grey and timber brown in the 844×390 battle view. No Meshy credits were used.

| Asset | Triangles | GLB before → after | Godot extracted PNG before → after | Texture |
|---|---:|---:|---:|---:|
| v7 | 1,500 | 492,408 → 305,616 B | 81,488 → 200,319 B | 512×512 |
| v7 LOD1 | 800 | 484,004 → 253,740 B | 81,488 → 200,319 B | 512×512 |

The combined GLB and extracted texture bytes fell from 573,896 to 505,935 for LOD0 and from 565,492 to 454,059 for LOD1. Godot regenerated the standalone PNGs from the embedded GLB texture during import. Triangle counts and texture dimensions did not change.

## Visual review

[Before and after JPG](/home/jess/projects/tw-logs/w17/2026-11-07-jungle-v7-before-after.jpg) compares old procedural cover with brightened v7 at the same map tile, camera pitch and yaw, 844×390 Compatibility/Low frame, plus a close view. The stone and trunk silhouette reads at battle distance.

## Gate

Initial and final headless imports exited 0. Capture scripts exited 0. The software OpenGL capture reported two texture cleanup warnings after each image saved. `./godot/test.sh` exited 0: all suites reported 0 failures, 0 `SCRIPT ERROR`, 0 `Parse Error`, and 0 `ERROR:`. Normal rescue scored 9/20. Map art passed 189,169 checks; map14 and phone17 passed with 0 failures. Full logs are in `/home/jess/projects/tw-logs/w17/jungle/`.
