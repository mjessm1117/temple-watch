# Wave 7: port as much as possible from XCOM 2 and the old web game
Jess (11-01): "Stay in Godot but port as much over from XCOM as possible as well as our old game."

Sources (read before coding):
- XCOM 2 WotC design study: docs/XCOM2-STUDY.md (ranked recs) and docs/godot/wave4/FEEL-GAP.md. The game itself is installed at /home/jess/snap/steam/common/.local/share/Steam/steamapps/common/XCOM 2 (configs in XComGame/Config and the WotC DLC Config folders). Use it for mechanics and numbers only.
- Web game (FROZEN, read-only): public/js/**, coverage table docs/godot/wave5/PORT-INVENTORY.md. Wave 6 covered the Temple/galaxy/loadout/menu visuals. Everything still listed as "deferred" there is in scope.

Legal line: port XCOM *mechanics, systems, rules and tuning ideas*. NEVER copy XCOM assets, code, text, names, UI art, audio or models. Everything is Star Wars / Temple Watch themed with our own names.

Common rules (every lane):
- Web game public/, functions/, tests/, worker.js are frozen. Godot 4.7.2 at /home/jess/projects/.tools/godot/godot. GDScript files <600 lines (split by topic). Local commit on your own branch only; no push; no subagents.
- Stay inside your lease. Anything you need in a file another lane owns goes under "Integration requests" in your report as exact function signatures and call sites. An integrate pass wires them afterwards.
- Shared contract for objectives: the combat lane adds a generic **Interact** action (1 action, adjacent tile) that calls `Mission.interact(unit, tile) -> Dictionary` and `Mission.interactables() -> Array[Vector2i]`. The missions lane implements both in mission.gd. Until the other side exists, stub defensively.
- Never break what works: ./godot/test.sh exits 0 with no failures and no SCRIPT ERROR. Bot win bands per 20 games stay Story ≥14, Normal 9–12, Hard 4–7, Legend 1–3. Add headless tests for everything new.
- Report docs/godot/wave7/<lane>-REPORT.md with:
  - a table of every XCOM feature and web feature in your scope, each marked ported / adapted / skipped (with a one-line reason),
  - player-visible changes,
  - real-window screenshots docs/godot/shots/wave7-<lane>-*.png,
  - integration requests.
  Then commit.
