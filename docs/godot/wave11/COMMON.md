# Wave 11 — shared rules (read before your lane spec)

Owner feedback 2026-11-03: game is "a lot better". Graphics are PARKED (do not touch rendering, lighting, shaders, env_art, gfx_*, graphics_*, map_art_*). Wave 11 = battle feel, missions, campaign layer, story — four parallel lanes.

## Hard rules
- Godot 4.7.2 at /home/jess/projects/.tools/godot/godot. Plain GDScript. Every file < 600 lines (new or edited). Prefer NEW files over growing big ones.
- Web game frozen: never touch public/, functions/, tests/ (repo root), worker.js, wrangler.toml.
- Small updates must not drop existing features or on-screen info. Compare before/after.
- Stay inside YOUR file lease. If you truly need a file outside it, do NOT edit it — finish what you can and list the needed change in your final message.
- Do not delegate, spawn subagents or parallel workers. Do the work yourself.
- No Meshy calls, no git push, no Windows build, no network downloads.
- Add your one new test suite to the `for suite in ...` line in godot/test.sh (only that edit to test.sh).

## Verification (all required before commit)
1. `/home/jess/projects/.tools/godot/godot --headless --path godot --import`
2. `./godot/test.sh` → exit 0, zero "SCRIPT ERROR" lines, every suite 0 failures, "Normal rescue bot" stays 9-11/20 (currently 10/20).
3. Screenshots of what you changed (before AND after where it applies) into docs/godot/shots/wave11-<lane>-*.png using the existing capture pattern (see combat_capture.gd / night1_capture.gd for how).
4. `git diff --name-only HEAD~N..HEAD` lists only lease files.
5. Commit on your branch with a clear message. Final message: what changed (player-visible), test numbers, screenshot paths, any out-of-lease needs.
