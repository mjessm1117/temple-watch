# Galaxy assets

- `shuttle.glb`: reused from the repository's `public/models/props/shuttle.glb` (Temple Watch original game asset). Original attribution: `public/models/CREDITS.md` (Meshy-generated Temple Watch prop). Converted with `@gltf-transform/cli` 4.5.1 `dequantize` to decode meshopt compression and remove quantization for Godot. The imported `shuttle_0.webp` is its existing embedded texture. No new external model download.
- Planet surfaces, atmosphere, spiral nebula, Darkness haze and starfield shaders: original procedural artwork for this lane. No third party textures.

- `intel.json`: read-only `FOES` and `TUNE` tables exported from the built, frozen web game. Used only for briefing enemy counts and the risk estimate; never mutates combat or mission selection.
