# Lane: art — make the Jedi Temple look good
Read WAVE4.md first; its rules apply. Branch: wave4/art.

FILE LEASE: `godot/scripts/env_art.gd`, `godot/scripts/env_capture.gd`, new files `godot/scripts/env_*.gd`, `godot/assets/env/**`, `godot/shaders/**`, `docs/godot/ART.md`. Do not edit game.gd: do your work inside the functions game.gd already calls (check how env_art is used) and list any extra hook in Integration requests.

Goal: a big visual step up while keeping tactics readable. Read docs/godot/ART.md for wave 3's state.
- Materials: temple stone/marble with procedural albedo + normal/roughness variation, worn edges, floor tiles with grout and inlay, metal and fabric for props.
- Architecture: walls with columns, arches, banners, statues, sun-shaft windows; high ground clearly readable as balconies/terraces.
- Lighting/post: warm sun shafts and soft volumetric fog, cool fill, ACES tonemap and mild color grade, contact shadows/SSAO tuned, glow restrained.
- Readability: cover (half/full) must remain obvious from the default camera; nothing may hide units or tiles. Grid/highlight visibility unchanged.
- Performance: hold 60 fps at 1366×768 on this machine; report frame timing. Before/after screenshots from the same camera.
