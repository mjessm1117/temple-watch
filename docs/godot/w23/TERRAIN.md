# W23 Lane 1 — terrain + props (lane id: terrain)
Read COMMON.md first. Gaps 1, 5, 6, 10 in the audit report.
Lease: scripts/map_art_geometry.gd, map_art_batch.gd, map_art_grid.gd, map_art_edges.gd, map14_detail.gd, meshy_theme_models.gd; assets/maps/**; assets/env/terrain.gdshader, stone.gdshader. Test: terrain23_test.gd.
Goal: the battle floor stops reading as a square grid of tan slabs.
1. Break plate seams and exposed slab sides; per-biome color/roughness variation and edge dirt/AO in terrain + stone shaders (512² CC0 atlas inputs from ambientCG/Poly Haven).
2. Grid shows only while moving/aiming (keep W22 move-tile readability: lit squares must still show on Move).
3. Cover: 2-3 rounded/beveled silhouette families per biome, varied heights, small ground clutter (Blender + Quaternius/Kenney CC0). Same collision footprint; no gameplay change.
4. Per-theme set dressing for shrine/grove/gate so themes differ in shape, not just color.
5. Batch/merge static props so gate Low <=150 draw calls (audit shows it over).
