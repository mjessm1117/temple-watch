# W20 lane E — less blocky, playful-but-nice battle look (lane name: art)
Read COMMON.md first. Worktree ../tw-w20/art.
## Jess wants
"Graphics can be more fun and playful but right now are feeling very weird and blocky. Doesn't have to be hyper real but should feel nice to play."
In his shot, Kira's close-up shows a shattered/glitchy mesh texture. Hangar = plain boxes. The audit's top-10 blocky list is in AUDIT-REPORT.md under "Blocky-look top ten".
## Do (0 Meshy credits; Blender headless, shaders and procedural work are free)
1. **Target style:** stylized, clean and friendly. Think readable toy-like tactics games, not realism.
   - Rounded or bevelled edges, soft gradients, a cohesive warm/cool palette.
   - Gentle rim light, soft shadows, less harsh contrast between floor and HUD.
2. **Terrain:**
   - Break the one-square plate look with blended tile transitions or variation, plus edge bevels/chamfers on raised slabs.
   - Make the grid highlight softer and only shown where it helps.
3. **Covers, walls, rocks:** rounder silhouettes (bevel modifier, more segments where cheap), with shared material language for props and objectives.
4. **Units:**
   - Fix Kira's shattered close-up texture: find the cause (UV/texture import, mipmaps, compression, or a broken LOD) and fix it for all 7 Jedi library models.
   - Smooth the abrupt LOD swaps.
   - Lightsaber blades get a soft glow/capsule rather than a raw cylinder.
5. **Lighting:** a softer key light, ambient fill and colour grade per theme in the Compatibility/Low tier.
6. **Phone budget holds:** units <= 15K tris, props <= 3K, 60 fps target, draw calls not above the fbc2447 level. Report tri/draw counts before vs after.
## File lease
- godot/scripts/map_art*.gd, godot/scripts/unit_view.gd, godot/scripts/combat_scene.gd (lighting/environment only)
- godot/assets/maps/**, godot/assets/models/**, godot/assets/units/**, godot/assets/characters/**, godot/assets/env/**
- new tests/art20_test.gd

Not yours: hud_phone*, game.gd, camera.
## Tests (art20)
- Tri and draw budgets.
- No unit texture uses a lossy setting that shatters at close range.
- The Low tier still loads.

Sheet: the same 3 maps at the normal phone camera distance before and after, plus the Kira close-up before and after.
