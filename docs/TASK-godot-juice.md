# Godot wave 2: JUICE — make the rescue mission feel like a real game

## Goal
Jess played the Godot rescue mission (`godot/`, see `docs/godot/README.md`): "it loosely works but feels very early — juice it up." Rules are fine; the FEEL is missing. Make every action read, land and look good, XCOM-style. Bar: a stranger watching 30 seconds should think "that's a real tactics game", not "prototype".

## Context
- Godot 4.7.2: `/home/jess/projects/.tools/godot/godot`. Run `./godot/run.sh`, test `./godot/test.sh` (currently 60 checks, 0 failures — must stay green).
- The web game (`public/`, FROZEN — read only, never edit) already solved much of this. Port the ideas and numbers from `public/js/view3d/`: `board.js` (terrain, high-ground lips, fallen stones), `themes.js` (lighting/palettes), `rigged.js` + `units.js` + `figures.js` (animation clips, idle/run/shoot/hit/death), `camera.js` + `cine.js` (follow cam, action cam, enemy pans), `effects.js` + `forcefx.js` (blaster bolts, saber swings, Force Push wave, impacts, smoke), `labels.js` (floating damage/MISS/GRAZE text). Unit models in `godot/assets/models/` are rigged with animations — USE them.
- Read `docs/XCOM2-STUDY.md` sections 7–8 (camera blend 0.5–0.75 s, readable shot HUD, skippable cinematics).

## Output — in priority order, do as many as possible, all of 1–6 required
1. **Animated units:** play the models' idle/walk-run/shoot/hit/death clips; units walk tile-by-tile along the path (smooth, ~4 tiles/s) and turn to face their target. No teleporting. Diagonal movement (port from web `rules.js`) if it fits.
2. **Combat effects:** blaster bolts that travel (glowing tracers, red/blue by side), muzzle flash, impact sparks, misses that visibly fly past/hit cover with debris, saber strike swing + glow trail, Force Push shockwave + knockback slide, cover breaking into chunks, death fall/dissolve. Floating numbers: damage, MISS, GRAZE, CRIT (bigger, colored), armor shred.
3. **Camera:** smooth glide to the selected unit; brief over-the-shoulder action cam on shots (~0.6 s blend, skip with click/Space, toggle in a settings button); follow enemy moves during their turn; small screen shake on crits, explosions, deaths.
4. **Look:** proper lighting (key + fill + soft shadows, ambient occlusion/SSAO, light fog/glow via WorldEnvironment), textured/varied ground instead of flat colored blocks, high-ground with edges and rubble, cover props using `crate`/`terminal` models plus simple modeled barricades/pillars, a sky/backdrop, ambient particles (dust motes). Keep 60 fps on this laptop (RTX-class GPU).
5. **HUD polish:** clean bottom ability bar with icons + hotkeys (1–9), unit portrait/name/HP pips/AP pips/Focus, shot panel with hit % big and breakdown small, hover tile outline + path preview line with AP cost, cover shields shown on hover (half/full per side), enemy turn banner ("ENEMY ACTIVITY"), turn clock prominent, objective tracker. Readable at 1366×768. Font + color style matching the web game (`public/css/xcom.css`, `style.css` tokens).
6. **Sound:** generate simple procedural/synth SFX in GDScript (AudioStreamGenerator) or small self-made .wav files you synthesize — blaster shot, saber hum/swing, Force Push whoosh, hit, death, UI click, turn start sting. Volume slider + mute. No downloaded copyrighted audio.
7. Stretch: mission intro pan over the map with objective callout; victory/defeat screens with stats; enemy "alert!" reveal moment when a group spots you.

- Keep logic and presentation separate: rules stay in `mission.gd`/`shot.gd` (unchanged behavior); new presentation in new scripts (e.g. `fx.gd`, `camera_rig.gd`, `hud.gd`, `unit_view.gd`, `audio.gd`). Tests must not depend on animations finishing (headless bot path must still run fast).
- Add a test that loads the scene headless and runs a few turns with presentation on, zero script errors.
- **Screenshots:** capture 3+ to `docs/godot/shots/` with xvfb-run: (a) squad on map at start, (b) mid-shot with tracer/action cam, (c) Force Push or explosion moment. Replace the old screenshot. Update `docs/godot/README.md` (what changed, controls, test results with real numbers).

## Boundaries
- File lease: `godot/**`, `docs/godot/**` only. Never touch `public/`, `tests/`, `worker.js`, `package.json`.
- Files under 600 lines each. GDScript. Windows-safe (`res://`/`user://` only).
- Small local commits on `main` ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (if no git identity: `-c user.name="$(git log -1 --format=%an)" -c user.email="$(git log -1 --format=%ae)"`). Do NOT push.
- Do not spawn subagents. Keep tool output small. Don't open the editor GUI.
