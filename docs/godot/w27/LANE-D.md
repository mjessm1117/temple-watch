# W27 Lane D — Impact + motion (worktree tw-w27/impact, branch w27/impact)

Read docs/godot/w27/COMMON.md first and follow it exactly. Lane prefix `w27d_`.

## Lease
godot/scripts/game.gd, cam_combat.gd, enemy_presentation.gd, fx.gd, audio.gd, unit_view.gd, w24_feelcam_beats.gd, effects_jedi.gd, effects_soldier.gd (all under godot/scripts/), new godot/tests/impact27_test.gd, new w27d_* helpers, new free art/audio under godot/assets/w27d/ with a CREDITS.md.

## Goal (audit gaps 7, 9, 10, 15)
1. Gap 7: blaster contact reads as a small layer at board scale. Scale the contact flash, spark silhouette and ground scorch with camera distance so a hit reads on a phone at tactical zoom. Ref app268500-12.jpg.
2. Gap 9: Rapid Fire and Suppress look like ordinary bolts; several Force/support skills share one ring. Give these high-use abilities a unique timing + shape + sound each: Rapid Fire, Suppress, Push, Pull, Force Heal, Barrier, Saber Throw, Grenade. Synth or CC0 audio.
3. Gap 10: movement is a straight tile tween + generic run. Visible vault/climb/door beats (contact + landing) and dash acceleration, using route types already returned by w24_threat_route.
4. Gap 15: force a miss and a kill in a test capture. A miss must read as a miss (bolt passes, whiz, dodge); kills need varied falls readable at tactical zoom.
5. Keep XCOM rhythm: fire→impact under ~0.8 s, enemy turn not slower than 4.2 s on the gate driver.
6. Expose `impact_budget27()` → {draws_per_beat, particles_max} for lane C. Portrait gate draw calls must not rise (C is cutting them).
Consume B's intent_explain27 only behind has_method if you need it for enemy beats.

## Test
impact27_test.gd: distinct VFX family + sound id per listed ability (8 distinct), contact scale grows with camera distance, vault/climb/door beat events fire on a staged route, forced miss + kill captures produce MISS + fall events. Captures for blaster, saber, Force, blast at 844x390 and 390x844 into tw-logs/w27/impact/.
