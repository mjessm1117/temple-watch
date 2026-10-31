# Wave 4 — make it feel like XCOM 2 (shared rules for every lane)

## Why
Jess played the Godot build (godot/) after wave 3. Verdict: "the gameplay still doesn't feel good." Graphics are better but can improve. Go back to XCOM 2: War of the Chosen and close the gap. Five lanes run in parallel, each in its own git worktree and branch.

## Reference
- XCOM 2 WotC is installed (native Linux): `/home/jess/snap/steam/common/.local/share/Steam/steamapps/common/XCOM 2`. Config .ini files there are readable text (e.g. XComGame/Config, WotC DLC Config). Read them for real numbers/timings. Do not copy XCOM assets, art, audio or text into the repo.
- Prior study: `docs/XCOM2-STUDY.md`. Godot overview: `docs/godot/README.md`, `docs/godot/AI.md`, `docs/godot/ART.md`.
- Godot binary: `/home/jess/projects/.tools/godot/godot` (4.7.2). Tests: `./godot/test.sh`.

## Rules (all lanes)
- Work only inside `godot/` and `docs/godot/`. The web game (`public/`, `functions/`, `tests/`, `worker.js`) is FROZEN: no edits.
- Plain GDScript. Keep every file under ~600 lines; split by topic into new files when needed. `game.gd` is already 562 lines.
- Obey your lane's FILE LEASE exactly. You may create new files inside your lease. If you need a change outside it, do not make it: list it under "Integration requests" in your report (file, function, exact change).
- Add or update tests for any rule you change. `./godot/test.sh` must finish with 0 failures and no script errors before every commit.
- Commit locally on your branch with one-line player-facing messages. Do NOT push, merge, or rebase. Do not delegate or spawn subagents.
- Finish by writing `docs/godot/wave4/<lane>-REPORT.md`: what changed for the player, how to see it in game, test result line (N passed / M failed), screenshots (save under `docs/godot/shots/wave4-<lane>-*.png` using the repo's existing capture scripts), integration requests, and open problems. Be honest about anything unfinished.
