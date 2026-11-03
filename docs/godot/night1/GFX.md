# Night 1 — Graphics pass (battle look), 2026-11-02

## Goal
Make battles look clearly better at High/Medium while Low stays phone-safe. No new models, no Meshy, no credits.

## Context
- Godot 4.7.2: /home/jess/projects/.tools/godot/godot. Run `godot --headless --path godot --import` first.
- Tiers exist: scripts/graphics_settings.gd, graphics_options.gd, graphics_resources.gd, graphics_batch.gd, graphics_damage.gd (Low = Compatibility renderer on restart). Env/light: scripts/env_art.gd, assets/env/*.gdshader. FX: scripts/fx.gd, attack_presentation.gd. 8 battle themes (see map_catalog.gd / map_art_*.gd). Read docs/godot/RENDER-UPGRADE.md and docs/godot/tiers/ first.
- Mobile rule (Jess): Low must run on Compatibility/GLES3, phone budget <=300K tris and <=150 draw calls, no SSAO/SSR/SDFGI/volumetrics on Low. Fancier effects only on High (Medium in between).
- Before any change: capture all 8 themes at High and Low into docs/godot/shots/night1-gfx-before-<theme>-<tier>.png (reuse the existing capture tooling, e.g. tools/graphics-render.sh / env_capture.gd).

## Requirements
1. Per-theme lighting mood: each of the 8 themes gets its own WorldEnvironment preset (sun angle/colour, ambient, fog colour/density, tonemap ACES/AgX, exposure, glow). Data-driven table (new file), not hard-coded in many places. Example moods: temple = warm gold dusk; snow = cold blue; jungle = humid green haze; city = sodium night; desert = harsh noon. Pick per theme from what exists.
2. High tier extras: SSAO, soft shadows, glow/bloom on lightsabers + blaster bolts + objective beacons, subtle volumetric fog or height fog where it suits the theme. Medium: shadows + glow, no SSAO. Low: none of these, baked-looking ambient only.
3. Unit readability on every tier: Jedi and enemies stand out from terrain (rim light or cheap fresnel outline shader that works in Compatibility), selected-unit ring, faction tint (Jedi blue/gold, Sith/enemy red). Must not hide cover icons.
4. Combat FX polish: saber swing trail, blaster bolt glow + impact sparks, scorch decals on hits to terrain/cover (fade after N turns, capped count), Force push ripple. Low gets simplified versions (fewer particles, no lights).
5. Camera feel: gentle depth-of-field ONLY on ability cinematic shots at High (skip if no such camera exists — don't invent a cinematic system).
6. Graphics menu: if a toggle for a new effect makes sense, add it to the existing graphics options under the right tier. Keep defaults auto by tier.

## Boundaries
- Nothing removed; tier switching and Compatibility restart still work. No balance or rule changes.
- Plain GDScript, every file < 600 lines; new code in new files (scripts/gfx_*.gd, assets/env/*.gdshader).
- No downloads, no Meshy, no network. Do not touch public/, functions/, tests/ (web frozen), worker.js, wrangler.toml, HUD/UI files, story files.
- Do not delegate or spawn subagents.

## File lease (only these)
godot/scripts/env_art.gd, env_capture.gd, fx.gd, fx_capture.gd, attack_presentation.gd, graphics_*.gd, new godot/scripts/gfx_*.gd, godot/assets/env/ (new/edited shaders + materials only), godot/tools/ capture scripts, new godot/tests/gfx_night1_test.gd, existing godot/tests/graphics*_test.gd, godot/test.sh (add new suite), docs/godot/night1/GFX-REPORT.md, docs/godot/shots/night1-gfx-*.png.

## Verification (all required before commit)
1. New suite gfx_night1_test.gd: every theme has a preset; Low has SSAO/glow/volumetrics off and uses only Compatibility-safe features; High has them on; outline/rim applied to all units; decal count capped; tier switch round-trips.
2. Perf: per theme, Low tris + draw calls within phone budget (report the numbers); High fps not worse than >15% vs before on this machine with the same harness (machine is slow today for all builds — compare A/B same session).
3. `./godot/test.sh` exit 0, 0 SCRIPT ERROR, every suite 0 failures, Normal rescue bot 10/20.
4. After shots: docs/godot/shots/night1-gfx-after-<theme>-<tier>.png (High + Low for 8 themes) + night1-gfx-fx.png (mid-attack with saber trail + bolts) at 1920x1080.
5. docs/godot/night1/GFX-REPORT.md: per theme mood, tier matrix (what is on where), perf table, before/after shot list, anything skipped and why.
6. Commit on current branch: "Night 1 graphics: per-theme lighting, tier effects, unit readability, FX polish". Do not push.
