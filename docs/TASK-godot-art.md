# Godot wave 3A: ENVIRONMENT ART — Jedi Temple, not grey blocks

## Goal
Jess played the juiced rescue mission: units/HUD good, but the level is grey blocks. Make the battlefield look like a Star Wars place: worn Jedi Temple / Coruscant-ruin stone, pillars, statues, ruins, overgrowth, lit braziers, holo-terminals. A stranger should read "Jedi Temple ruins under attack" in one glance.

## Context
- Godot 4.7.2 `/home/jess/projects/.tools/godot/godot`; run `./godot/run.sh`; tests `./godot/test.sh` (65 checks, 0 failures — keep green; run it, don't edit it).
- Web game (`public/`, FROZEN, read only) did a graphics pass: port ideas/palettes from `public/js/view3d/board.js`, `themes.js`, `props.js`, `diorama.js`.
- Map data `godot/data/rescue.json` defines tiles/height/cover — art must match it exactly (a full-cover tile must look like full cover, half like half, high ground clearly raised). Rules must not change.
- Build geometry procedurally in GDScript (CSG/ArrayMesh/MultiMesh) + procedural or self-made textures/shader materials (stone with noise, edge wear, moss, floor tiles with grout, triplanar). Existing models in `godot/assets/models/props/` may be reused. No downloaded third-party assets.

## Output
1. New `godot/scripts/env_art.gd` (+ split files if >600 lines, e.g. `env_props.gd`, `env_materials.gd`, shaders in `godot/assets/env/`): builds the whole level look from mission data — tiled stone floor with variation, raised terraces with steps/edges, walls as carved stone with trim, half cover = low walls/crates/fallen column segments, full cover = pillars/statues/wall chunks, rubble, vines/planters, braziers with flickering light, a backdrop (Temple spires/Coruscant skyline silhouette + sky).
2. Lighting/mood: golden-hour key light, cool fill, warm point lights from braziers, fog depth; keep cover/height readable (cover silhouettes clear from the default camera).
3. Destructible cover from Force Push must still visibly break (hook into whatever `game.gd`/`fx.gd` does now).
4. Performance: MultiMesh for repeated pieces; aim 60 fps on an RTX laptop.
5. Screenshots (xvfb-run, as in docs/godot/README.md) to `docs/godot/shots/`: `art-overview.png` (whole map), `art-closeup.png` (squad in cover). Write `docs/godot/ART.md`: what was built, how to tweak, real test result line.

## Boundaries — PARALLEL LANE, another Codex is editing other files right now
- File lease: `godot/scripts/env_*.gd`, `godot/assets/env/**`, `docs/godot/ART.md`, `docs/godot/shots/art-*.png`. In `godot/scripts/game.gd` you may ONLY replace the existing board/terrain-building code with calls into env_art (keep the diff small, ≤40 lines changed, game.gd must stay <600 lines). Do NOT touch `mission.gd`, `shot.gd`, `godot/data/**`, `godot/tests/**`, `test.sh`, `project.godot`, `README.md`, `public/`.
- Commit only your own paths: `git add <your paths> && git commit` (if `index.lock` exists, wait 5 s and retry). Message ends `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; if no identity use `-c user.name="$(git log -1 --format=%an)" -c user.email="$(git log -1 --format=%ae)"`. Never push, never stash, never reset.
- No subagents. Small tool output. No editor GUI.
