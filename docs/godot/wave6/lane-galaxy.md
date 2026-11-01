# Wave 6 lane: galaxy map with depth (read docs/godot/wave6/WAVE6.md first)
Branch wave6/galaxy. LEASE: godot/scripts/campaign/galaxy.gd, godot/scripts/campaign/galaxy_map.gd, godot/scenes/galaxy.tscn, new godot/scripts/campaign/galaxy_*.gd, new godot/assets/galaxy/**, new godot/tests/galaxy_view_test.gd, docs/godot/wave6/galaxy-REPORT.md, docs/godot/wave6/ref-galaxy-*, docs/godot/shots/wave6-galaxy-*.png.
Goal: a 3D galaxy (spiral arms, nebula, starfield) with every planet/region in godot/data/campaign/galaxy.json as a rendered planet (distinct color/texture per biome, atmosphere glow, slow spin). Match the web galaxy screen's information (public/js/galaxy.js: regions, risk bands, threat/Darkness, mission offers, field ops) — nothing it showed may be missing.
- Mission offers are pulsing markers in risk color; Darkness is a creeping red/black haze per region; field ops are small ships traveling.
- Click planet → camera flies there → briefing panel slides in (existing briefing/launch flow unchanged). Back → camera returns.
- Life: orbit drift, twinkling stars, hover glow + name plate, smooth zoom/pan (mouse wheel, drag, WASD).
- Test: scene loads, every planet gets a node, selecting an offer still launches the same mission id as before.
