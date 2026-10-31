# Wave 5 lane: port the web game's story, saga and codex into Godot
Rules: docs/godot/wave4/WAVE4.md (web game public/ is FROZEN, READ-ONLY reference; GDScript files <600 lines; tests; local commits on your branch only; no push/merge; no subagents).
Branch wave5/story (git worktree). Three other lanes run at the same time (maps, skills, campaign shell). Do NOT edit their files.

FILE LEASE (new files only): godot/scripts/story/**, godot/data/story/**, godot/scenes/briefing*.tscn, godot/scenes/codex*.tscn, godot/scenes/dialogue*.tscn, godot/tests/story*_test.gd, docs/godot/wave5/story-REPORT.md, docs/godot/shots/wave5-story-*.png.
Hook-ups outside the lease (menu, campaign hub, mission start/end) go under "Integration requests" with the exact change.

Jess: "we had built out a good amount of the rest of the game, make sure we bring all that in." He wants story-first choices: briefing, mid-mission, debrief, Temple talks, bonds between soldiers.
1. Convert ALL story text and choice data to JSON under godot/data/story/, losing nothing: story.js, data-story.js, story-era2.js, data-era2.js, story-era3.js, data-era3.js, saga.js, data-saga.js, data-codex.js, ui-codex.js, tutorial.js, data-life.js (Temple talks/bonds), docs/specs/story.md, saga.md, chains.md. Write a converter or do it by hand, but add a test that counts entries per web source and matches the JSON.
2. Logic in godot/scripts/story/: story flags, choice consequences, era progression, saga chains, bond levels between named soldiers, codex unlocks — same rules as the web code.
3. Scenes: briefing.tscn (pre-mission briefing with choices), dialogue.tscn (Temple talk / debrief with portraits or name plates and 2-4 choices), codex.tscn (lore archive browser). Desktop-first, readable at 1920x1080, matching the existing Godot look.
4. Public API (document it in the report): start_briefing(mission_id), start_debrief(result), next_temple_talk(state), apply_choice(state, choice_id). State is a Dictionary the campaign lane will store.
5. Tests (headless): entry counts match web, a choice sets its flags, era 1→2→3 advances on the web trigger, bonds rise, codex entries unlock.
Done = your story tests pass headless with no SCRIPT ERROR and ./godot/test.sh still 0 failures; 2 screenshots (briefing with choices, codex) by launching the scene directly; story-REPORT.md lists every web source and its JSON file + counts; committed on wave5/story.
