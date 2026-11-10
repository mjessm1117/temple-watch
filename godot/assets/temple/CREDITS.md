# Temple assets

- `human.glb`: Quaternius, Universal Animation Library 1 & 2, CC0 1.0. Copied from `public/models/human.glb` and decoded/dequantized to standard glTF with `@gltf-transform/cli` 4.5.1 for Godot import; geometry, rig and animation clips are retained. Source: https://quaternius.com/packs/universalanimationlibrary.html (CC0 mirror: https://github.com/tilakpatell/tilakverse-assets). Existing game clip names are retained.
- `nebula.gdshader`, Temple architecture, furnishings, sparks and star field: original procedural artwork for Temple Watch. No external textures or downloads.
- `human_lod.glb`: decimated 2,487-triangle phone copy of the Quaternius CC0 `human.glb` above, exported with Blender 5.3. Only the `idle` and `walk` clips are retained for Temple actors.
- `surface_atlas.png`: original generated 512² grayscale stone, metal, light and worn surface atlas shared by Temple materials. No external source.
