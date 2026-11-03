# Night 1 — Story pass: consequences + Jedi personal arcs + Journal, 2026-11-02

## Goal
Make choices feel remembered and give the starting Jedi their own arcs. Builds on Wave 10 (docs/godot/wave10/STORY.md + STORY-REPORT.md — read both first).

## Context
- Godot 4.7.2: /home/jess/projects/.tools/godot/godot. Run `godot --headless --path godot --import` first.
- Story code: scripts/story/ (story_engine.gd, story_screen.gd, wave10_capture.gd), data-*.json story tables, legacy.gd, combat_bonds.gd, CampaignFlow. Wave 10 records choice flags in the save — use them.
- Original prose only. Star Wars setting/tone, but no film/game dialogue copied. Voice: grounded, short lines, Jedi under pressure guarding a Temple.

## Requirements
1. Callbacks: at least 20 places where a prior choice flag changes later text or options — briefing lines, Temple talks, debriefs, Council votes. Each callback names what you did ("You spared the smuggler on Ord Mantell; she sends coordinates"). At least 6 change a mechanical outcome (small resource, intel, mission modifier), never balance-breaking.
2. Personal arcs: each of the 6 starting roster Jedi gets a 3-step arc (unlock by missions completed / bond level / era): step 1 Temple talk, step 2 a mission briefing variant or mid-mission beat tied to them, step 3 resolution choice with a lasting perk or trait (small: +5 will, +1 crit vs Sith, etc.) or a darker cost (Darkness). Arcs must handle that Jedi dying (arc closes with a memorial line).
3. Journal / Archives screen: list story so far — key choices made (plain sentence each), active arcs and their next step hint, fallen Jedi memorial, current era. Reachable from the Temple. Add it inside the existing story/codex area if one exists; if a new tab is needed, add the hook in strat_ui.gd only (do NOT edit temple.gd/home_*.gd — another lane may later; record the hook point in the report).
4. Era transitions: a short interlude screen (3-5 lines + one choice) between eras 1→2 and 2→3 that recaps 2-3 of the player's biggest choices via flags.
5. Old saves load: missing arc/journal fields default safely.

## Boundaries
- Nothing removed; existing talks, beats, aftermaths, votes, bond rules unchanged except where a callback adds a variant. No big balance changes.
- Plain GDScript, every file < 600 lines; new code in new files (scripts/story/arc_*.gd, journal_*.gd, callbacks_*.gd); new data in new JSON tables.
- No downloads, no network, no Meshy. Do not touch public/, functions/, tests/ (web frozen), worker.js, wrangler.toml, HUD/graphics/fx files, campaign/temple*.gd, home_*.gd.
- Do not delegate or spawn subagents.

## File lease (only these)
godot/scripts/story/ (existing + new), godot data JSON for story/legacy (existing story tables + new tables), godot/scripts/legacy.gd (field defaults only), godot/scripts/campaign/strat_ui.gd (one hook for Journal if needed), CampaignFlow file (only to route era interludes), save/load migration file for new fields, new godot/tests/story_night1_test.gd, godot/tests/story_bonds_test.gd (only if a callback legitimately changes an expected string), godot/test.sh (add suite), docs/godot/night1/STORY-REPORT.md, docs/godot/shots/night1-story-*.png.

## Verification (all required before commit)
1. New suite story_night1_test.gd: every callback fires with its flag and not without; 6 arcs × 3 steps reachable via fixture saves; arc closes cleanly on death; Journal lists choices/arcs/fallen from a fixture save; era interludes show recap from flags; old save loads.
2. `./godot/test.sh` exit 0, 0 SCRIPT ERROR, every suite 0 failures (story_bonds still 0 fail), Normal rescue bot 10/20, campaign test 0 fail.
3. Shots 1920x1080: night1-story-{callback-briefing,arc-talk,arc-resolution,journal,interlude}.png.
4. docs/godot/night1/STORY-REPORT.md: list every callback (flag → effect), each arc's 3 steps in one line each, Journal location, shots, anything skipped.
5. Commit on current branch: "Night 1 story: choice callbacks, Jedi personal arcs, Journal, era interludes". Do not push.
