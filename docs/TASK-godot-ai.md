# Godot wave 3B: SMARTER ENEMIES + DIFFICULTY LEVELS

## Goal
Enemies in the Godot rescue mission are simple greedy movers. Make them play like XCOM 2 enemies and add difficulty levels Jess picks before the mission.

## Context
- Godot 4.7.2 `/home/jess/projects/.tools/godot/godot`; `./godot/test.sh` (65 checks, 0 failures; rescue bot 8/20).
- Read `docs/XCOM2-STUDY.md` section 4 + recs 4, 10 (verified: engaged-enemy cap 4/6/6/99 by difficulty; cover/flank/ideal-range destination scoring; pods scamper to cover on reveal; reinforcements announced a turn ahead).
- Port intent and numbers from the frozen web game (read only): `public/js/ai.js`, `DIFF` table in `public/js/data.js` (+ `TUNE` in data-battle.js), enemy roles in data files.
- Rules live in `godot/scripts/mission.gd` / `shot.gd`; shot math must stay the single shared path.

## Output
1. New `godot/scripts/ai.gd` (move enemy decision code out of mission.gd into it): role-based AI — troopers take cover and pin lanes / overwatch, Sith warriors hunt Jedi and close to melee, heavies/snipers seek height and range, all score destinations by cover vs every visible squad member, flank opportunity, ideal range, height, danger (overwatch zones); no repetitive focus-fire stacking beyond sense; scamper to cover on reveal (free move, no shot); use abilities they have; fall back when hurt.
2. Engagement throttle: max simultaneously active attackers per difficulty; unengaged groups hold back while cap is full.
3. `godot/data/difficulty.json`: Story / Normal / Hard / Legend — enemy aim, enemy HP, extra enemies per group, active-attacker cap, turn clock, reinforcement size, player aim bonus. Port values from web DIFF where they exist.
4. Difficulty picker: new start screen `godot/scenes/menu.tscn` + `godot/scripts/menu.gd` (title "Temple Watch", difficulty buttons with one-line descriptions, Start). Make it the main scene in `project.godot`; it loads the rescue scene with the chosen difficulty (pass via an autoload or static var in a new `godot/scripts/settings.gd`). Restart in-mission keeps difficulty.
5. Tests in `godot/tests/run.gd` (+ new test files if needed, wired into `test.sh`): AI picks cover over open ground on a fixture, flanks when possible, Sith targets Jedi, throttle holds back a group, each difficulty loads; bot 20 games per difficulty, 0 script errors — print win rates. Target bands (bot is weak, so tune by eye): Story ≥70%, Normal ~45–60%, Hard ~25–40%, Legend ≥5%. Tune via difficulty.json only.
6. Write `docs/godot/AI.md`: behaviors, difficulty table, real test numbers.

## Boundaries — PARALLEL LANE, another Codex is editing other files right now
- File lease: `godot/scripts/ai.gd`, `godot/scripts/mission.gd`, `godot/scripts/menu.gd`, `godot/scripts/settings.gd`, `godot/scenes/menu.tscn`, `godot/data/**`, `godot/tests/**`, `godot/test.sh`, `godot/project.godot`, `docs/godot/AI.md`. Do NOT touch `game.gd`, `env_*.gd`, `godot/assets/**`, `fx.gd`, `unit_view.gd`, `README.md`, `public/`. If game.gd needs a hook (e.g. reading difficulty), expose it from mission.gd/settings.gd instead and note the needed one-liner in AI.md.
- Files <600 lines. Commit only your own paths: `git add <your paths> && git commit` (if `index.lock` exists, wait 5 s, retry). Message ends `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; if no identity use `-c user.name="$(git log -1 --format=%an)" -c user.email="$(git log -1 --format=%ae)"`. Never push, stash or reset.
- No subagents. Small tool output. No editor GUI.
