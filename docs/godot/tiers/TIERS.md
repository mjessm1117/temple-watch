# Graphics quality tiers — Low / Medium / High (Jess approved 2026-11-01)

## Goal
Add a player-facing Graphics setting with Low, Medium, High. Low must be the phone-class path. The game must look the same as today on High (today's look is the ceiling, don't drop features).

## Context (read first)
- docs/godot/RENDER-UPGRADE.md (v2): Low = Compatibility renderer (GLES3/WebGL2-class), Med/High = Forward+. Phone budget ≤150 draw calls, ≤300K tris, textures ≤1024, target 60fps, min smooth 30.
- godot/project.godot already has rendering_method="forward_plus" and rendering_method.mobile="gl_compatibility".
- Battle map lighting/sky/fog lives in the map renderer (`_configure_lighting()` etc., see docs/godot/ART.md). Meshy models already have LOD1 meshes (props.json).

## Requirements
1. Settings: Graphics Low/Medium/High in the existing settings/options UI (add one to the title/pause screen if none exists). Saved to user:// config, loaded at boot. Default: High on desktop, Low on mobile OS.
2. Renderer: rendering method cannot change at runtime in Godot. Low switches to gl_compatibility on next launch (write user://override.cfg or equivalent, show "applies on restart"). Medium/High use Forward+. Keep Godot's automatic fallback to OpenGL3 when Vulkan/D3D12 is unavailable enabled, and make the game treat that case as Low.
3. Per tier (apply live where possible): shadows (High: soft, larger atlas; Med: hard/smaller; Low: off or one cheap directional), SSAO/SSIL/glow/volumetric fog (High on, Med reduced, Low off), MSAA/FXAA, LOD bias (Low prefers LOD1 meshes sooner), particle counts (dust/braziers), render scale (Low may use 0.75 on mobile only).
4. No gameplay difference between tiers. No SCRIPT ERROR on any tier.
5. Low under gl_compatibility must render every battle theme, temple home and galaxy screen without missing materials. Any shader that fails under Compatibility needs a fallback.

## Verification
- New test suite that boots each tier (Low run headless-capable with --rendering-method gl_compatibility) and loads all 8 battle themes + temple + galaxy; 0 errors.
- Measure per tier on the largest map: fps avg/p95, draw calls, tris. Low must be ≤150 draws, ≤300K tris.
- Screenshots: same battle view at Low/Med/High, docs/godot/shots/tiers-{low,med,high}.png, plus the settings UI.
- Write docs/godot/tiers/REPORT.md: what each tier changes, numbers table, known gaps.
- `./godot/test.sh` exits 0, all suites 0 failures, Normal band unchanged. Make sure test.sh runs the new suite.
- Commit on branch gfx/tiers. Do not push.

## File lease
May write: godot/project.godot, new godot/scripts/graphics_*.gd, settings/options UI scripts+scenes, map renderer lighting/environment/particle code, shaders under godot/assets (Compatibility fallbacks only, keep High look identical), godot/tests/** (new suite), godot/test.sh (add suite), docs/godot/tiers/**, docs/godot/shots/tiers-*.png.
Do NOT touch: godot/data/maps/props.json, godot/assets/maps/meshy*/**, art/**, tools/meshy/** (another lane is remaking models), maps/layouts, balance data, web game files.
