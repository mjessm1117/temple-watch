# Shared screen assets

- `jedi.glb`, `scout.glb`: Jess's existing Meshy 6 unit models, copied from `godot/assets/models/units/`; private paid Meshy plan. Original attribution: `public/models/CREDITS.md`, https://www.meshy.ai . Their embedded textures are extracted by Godot during import.
- `airtaxi.glb`: Jess's existing Meshy Temple air taxi, from `public/models/props/airtaxi.glb`; same license. Decoded and dequantized with `@gltf-transform/cli` 4.5.1, matching the existing Godot model pipeline.
- `planet.gdshader`, Temple geometry, archive shelving, hologram geometry, dust, and UI tones: original procedural work for Temple Watch. No downloaded art.
- Native stroke icons are redrawn from `public/js/icons.js` (guardian, relay, kyber); holocron and lock use the same 24-unit stroke convention.
- Fonts request the existing web families (Chakra Petch, IBM Plex Sans, IBM Plex Mono) through Godot SystemFont. DejaVu system fallbacks are used when absent. No font binaries are redistributed: the web's Google Fonts are OFL rather than CC0, and this lane permits CC0 downloads only.
