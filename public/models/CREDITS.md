# 3D assets: sources and licenses

| File | What | Author | License | Source |
| --- | --- | --- | --- | --- |
| `human.glb` | Rigged mannequin + 29 animation clips (idle, walk, jog, pistol aim/shoot, sword idle/attack, spell cast, hit, knockback, death ×2, crouch, jump, interact, kneel, cheer, lie down / get up, lifted, throw, block) | Quaternius — Universal Animation Library 1 & 2 | CC0 1.0 (public domain) | https://quaternius.com/packs/universalanimationlibrary.html (files via the CC0 mirror https://github.com/tilakpatell/tilakverse-assets) |
| `beast.glb` | Rigged creature (Terentatek, horrors) with idle, walk, run, punch, hit, death, jump | Quaternius — Ultimate Space Kit, `Enemy_Large` | CC0 1.0 (public domain) | https://quaternius.com/ (same mirror) |
| `../vendor/three.module.min.js`, `GLTFLoader.js`, `SkeletonUtils.js`, `BufferGeometryUtils.js`, `meshopt_decoder.module.js` | Three.js r169 and its example loaders (imports rewritten to local paths) | Three.js authors; meshoptimizer by Arseny Kapoulkine | MIT | https://github.com/mrdoob/three.js |

Changes made for this game (allowed by CC0): animations trimmed to the clips we use and renamed, scale tracks dropped, keyframes resampled, geometry quantized and meshopt-compressed (21 MB → 1.2 MB). Robes, armor, helmets, sabers and blasters are low-poly parts built in code (`public/js/view3d/figures.js`) and attached to bones; terrain, scenery and effects are also built in code (`board.js`, `themes.js`, `effects.js`).

Total 3D download: ~1.5 MB models + ~0.85 MB scripts, loaded only when the 3D view opens a mission (beast model only when a mission has a creature).

Only CC0 or other permissive licenses go in this folder, each listed here with author, link and license.
