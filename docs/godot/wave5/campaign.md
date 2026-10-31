# Wave 5 lane: port the web game's campaign shell into Godot
Rules: docs/godot/wave4/WAVE4.md (web game public/ is FROZEN, READ-ONLY reference; GDScript files <600 lines; tests; local commits on your branch only; no push/merge; no subagents).
Branch wave5/campaign (git worktree). Two other lanes run at the same time: maps (rescue.json, map*.gd) and skills (units.json, abilities.json, mission/shot/ai/game/hud/input scripts). Do NOT edit their files.

FILE LEASE (new files only): godot/scripts/campaign/**, godot/data/campaign/**, godot/scenes/temple*.tscn, godot/scenes/galaxy*.tscn, godot/scenes/campaign*.tscn, godot/tests/campaign*_test.gd, docs/godot/wave5/campaign-REPORT.md, docs/godot/wave5/PORT-INVENTORY.md, docs/godot/shots/wave5-campaign-*.png.
Anything needing a change outside the lease (menu.gd "New Campaign" button, mission result → campaign hook, run.gd test registration, which mission a node launches) goes under "Integration requests" in your report with the exact change.

Jess: "we had built out a good amount of the rest of the game, make sure we bring all that in." Godot currently has only one mission (rescue). The web game has the whole campaign around it.

1. PORT-INVENTORY.md first: every file in public/js/ → which system it is, its web line count, and the Godot status (ported in this lane / story lane / skills lane / maps lane / deferred to wave 6, with reason). Nothing may be left unlisted.
2. Port these systems from the web source (same names, numbers, costs, unlock rules), data in JSON under godot/data/campaign/, logic in godot/scripts/campaign/:
   - Campaign state + save/load (state.js, save.js, campaign.js, data-campaign.js): roster with class, rank, XP, wounds/recovery days, kills; resources; day/week clock.
   - Temple home / command console (temple*.js, data-modules.js, data-wings.js, temple-data.js, temple-kits.js, temple-life.js): wings/modules to build, upkeep, kits/loadouts, recovery of Wounded soldiers.
   - Research + trees (data-trees.js, temple-prog.js, power.js, skills.js, data-skills.js): research projects and soldier promotion choices.
   - Arsenal / gear Mk tiers (arsenal.js, data-arsenal.js).
   - Galaxy / mission select (galaxy.js, data-galaxy.js, fieldops.js, teams.js, data-teams.js, darkness.js): planets, threat/darkness, choose missions, second squad.
   - Legacy / identity (legacy.js, data-legacy.js, identity.js, data-identity.js).
3. Scenes: temple.tscn (console hub: roster, research, build, arsenal, launch) and galaxy.tscn (mission picker), desktop-first, keyboard + mouse, readable at 1920x1080, matching the existing Godot look. Launching a mission: emit a signal / call a stub that integration will wire to the battle; record mission results (casualties, Wounded flags, kills, XP) back into campaign state via a documented function apply_mission_result(result: Dictionary).
4. Tests (headless): save/load round trip, research completes after N days, building a module spends resources, wounded soldier recovers, promotion grants rank stats per web RANK_GAIN, galaxy offers missions per web rules, apply_mission_result updates roster.
Done = your campaign tests pass headless with no SCRIPT ERROR and ./godot/test.sh still 0 failures; 2 screenshots (temple hub, galaxy) captured by launching your scene directly; campaign-REPORT.md lists what's ported vs deferred; committed on wave5/campaign.
