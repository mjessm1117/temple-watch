# W23 Lane 2 — units + motion (lane id: units)
Read COMMON.md first. Gap 7 + the animation/LOD note in the audit report.
Lease: scripts/unit_view.gd, gfx_unit_readability.gd; assets/models/units/**, assets/units/**, assets/characters/**; assets/env/unit_rim.gdshader. Test: units23_test.gd.
Goal: Jedi, soldiers and Sith read clearly at play-camera distance on a phone.
1. Rebalance armor value blocks, team accents, capes/helmets/weapons so silhouettes separate at real camera pixels (Blender texture/mesh pass; no Meshy).
2. Cheap saber halo (camera-facing additive quad or shell, works on Low with glow off); expose set_saber_halo (contract 4).
3. Author LOD1/LOD2 where missing (LOD2 <=800 tris guide); check swap distance so no visible pop; record per-model tris.
4. Inspect adjacent frames of idle/run/shoot clips; fix obvious foot slide/snap in clip selection or blend times (unit_view only).
5. Flag (do not deploy) W19 library heavy/medic >8K tris; produce slimmer versions if cheap.
6. W22 known issue: a kill can play a second kill audio cue. If the duplicate originates in unit_view.gd, fix it there; otherwise name the file/line under Integrate asks.
