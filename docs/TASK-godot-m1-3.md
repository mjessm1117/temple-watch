# Godot rebuild — Milestones 1–3 (first playable rescue mission)

## Goal
Start rebuilding Temple Watch as a desktop game in Godot 4.7.2, reusing what the web game already has. Deliver milestones 1–3 of `docs/XCOM2-STUDY.md` ("Build order suggestion"), and push further into milestone 4 if 1–3 are solid. End state: a desktop window where Jess can play one complete rescue mission.

## Context
- Godot binary: `/home/jess/projects/.tools/godot/godot` (4.7.2). Reference for project layout, run script and headless tests: `/home/jess/projects/sots-remake/game` and `sots-remake/docs/GODOT.md` (READ ONLY, do not edit that repo).
- The web game (`public/`) is FROZEN: read it for rules, numbers, names and assets; never edit it.
- Read first: `docs/XCOM2-STUDY.md` (sections 1–3, recommendations 1–5, 7, 9), `docs/design.md`, `CLAUDE.md`.
- Port, don't reinvent: the hit-chance/cover/graze/flank/height math (`public/js/rules.js`), 3 AP system and class kits (see latest CHANGELOG entry and `data.js`, `data-skills.js`, `abilities.js`), unit stats and names, enemy types. Use the existing 3D models in `public/models/` (`.glb`, incl. `units/`, `props/`) — copy the ones you use into `godot/assets/models/` and keep `CREDITS.md` with them.
- Windows export later: no Linux-only paths, tools or plugins in game code; paths via `res://`/`user://`.

## Output (all in a new `godot/` folder)
1. **M1 arena:** Godot project `godot/project.godot`, `godot/run.sh` (one-command launch). Grid board, 3D camera (orbit/pan/zoom), select unit, move with range preview (1 AP / 2 AP shading), shoot with the ported aim formula, end turn, simple enemy AI turn, combat log. 3 AP per unit as in the web game.
2. **M2 cover & sight:** directional half/full cover, 2+ height levels (height = aim bonus), line of sight with corner peeks, ONE shared shot-calculation service used by preview, execution and AI. Shot panel shows the breakdown (base + height + range − cover − defense = hit %, plus crit/graze).
3. **M3 rescue mission:** a bigger map (≥ 24×24) with two routes and high/low ground; squad of 4 (2 Jedi, 2 troopers using ported classes/abilities incl. at least Force Push and a saber strike); 2–3 enemy groups that wake when seen, staged at different angles; prisoner beyond first contact → free them → reach evac; visible turn clock (start with 10 turns); one reinforcement drop announced one turn ahead from a new direction; win/lose screen; restart button.
4. **Stretch (M4) if time remains:** overwatch, destructible cover (Force Push can knock cover/units), armor.
- Data in plain data files (`godot/data/*.json` or `.tres`), not hard-coded in scenes, so balance can change without code edits.
- **Headless tests** in `godot/tests/` runnable with one command (document it): aim formula matches web `rules.js` on ≥10 cases, cover/LOS on a known test layout, AP spending, mission win and lose paths via a scripted bot playing the rescue mission ≥ 20 times with zero script errors (report win rate).
- **Screenshot:** capture at least one in-game screenshot of the rescue mission to `docs/godot/shots/` (use xvfb-run or Godot's movie/viewport capture; if impossible headless, say so).
- `docs/godot/README.md`: how to run, how to test, what's done, what's not, test results (copy actual numbers).

## Boundaries
- File lease: `godot/**`, `docs/godot/**`. Nothing else in the repo. Do not touch `public/`, `worker.js`, `tests/`, `package.json`.
- Files under 600 lines each (repo rule). GDScript, typed where practical.
- Commit locally on `main` in small logical commits (message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; if git has no identity, use `-c user.name="$(git log -1 --format=%an)" -c user.email="$(git log -1 --format=%ae)"`). Do NOT push.
- Do not spawn subagents. Keep tool output small. Don't run the Godot editor GUI interactively.
