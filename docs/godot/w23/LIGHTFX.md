# W23 Lane 3 — light + VFX + tiers (lane id: lightfx)
Read COMMON.md first. Gaps 2, 9, 10 (ambient life) + saber halo tier.
Lease: scripts/combat_scene.gd, env_art.gd, gfx_theme_presets.gd, graphics_settings.gd, graphics_resources.gd, fx.gd; assets/vfx/** (new). Test: lightfx23_test.gd.
Goal: Low-tier phone battle gets depth and mood; impacts read layered like XCOM 2.
1. Low tier: one bounded shadow key if budget allows, else baked/contact darkening + cheap height haze; per-theme color grade so foreground, actor and target separate.
2. VFX: layer flash/core/debris/smoke for blaster, saber, Force and blast with pooled billboards and short-lived decals; Low keeps particle caps.
3. Ambient life per theme: haze, drifting dust/embers, pooled, Low-capped. (Foliage/banner wind shaders belong to lane 1 assets; ask if needed.)
4. Tier hooks: saber halo on for all tiers via guarded unit_view.set_saber_halo; Medium/High extras auto-fallback.
5. With lane 1, help bring gate Low <=150 draws (your side: VFX/light draw cost).
