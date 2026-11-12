# W23 Lane 4 — Temple + galaxy set (lane id: spaces)
Read COMMON.md first. Gaps 11, 12, 13 (3D side).
Lease: scripts/campaign/temple_view.gd, temple_geometry.gd, galaxy_art.gd, galaxy_map.gd, galaxy_details.gd; assets/temple/**, assets/galaxy/**, assets/ui/galaxy15/**, assets/ui/planet.gdshader. Test: spaces23_test.gd.
Goal: Temple feels like a lived-in cutaway (Avenger bar); galaxy map fills the phone.
1. Each Temple room: one light + one focal prop + depth (foreground/background cutaway), break the repeated box construction; one shared atlas.
2. Review Temple human.glb (13.7K tris): add LOD or slimmer copy.
3. Phone Temple: reframe around the active room so side wings aren't cut; implement set_ui_safe_rect (contract 1).
4. Galaxy phone: bigger focused planet/mission scale, separated signal labels; implement set_ui_safe_rect on galaxy_map (contract 1). Selected-mission card UI is lane 5's.
