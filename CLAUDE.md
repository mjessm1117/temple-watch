# Temple Watch: working rules

This repo is the source of truth for the Godot game. Make small, surgical edits and keep files under ~600 lines.

## Project and release
- Godot 4.7.2 project: `godot/`. Binary: `/home/jess/projects/.tools/godot/godot`.
- Phone first: test at 844x390 with Compatibility/Low, target 60 fps. Keep units at or below 15K triangles and props at or below 3K; use LODs where they apply. Also check desktop at 1366x768.
- Gate: run headless import first, then `./godot/test.sh`. It must exit 0 with 0 `SCRIPT ERROR`, 0 failures in every suite, and Normal rescue 9–11/20. Then run `git diff --check`.
- Web export: `tools/web/export_web.sh` publishes to the GitHub Pages site `temple-watch-play`.
- Ship once per wave and tag the release `last-good`. Do not deploy on every push.
- The old web game in `public/` is frozen. `npm test` still guards it before a push.
- Never commit XCOM 2 reference images. This repo is public.
- Specs live in `docs/specs/`; commit messages describe the player-facing change.

## Working with Jess
- He doesn't code. Anything he must do: numbered click-by-click steps, copy blocks for anything he pastes.
- Ask taste questions with the ask-user form (2–4 options, a one-line beginner gist each).
- Replies ≤800 characters, blunt, no flattery. Label lore claims with a confidence level.
- Token discipline: read only the files you need.
