# Wave 5 integrate: one playable game — menu → Temple → galaxy → briefing → battle → debrief → Temple
Rules: docs/godot/wave4/WAVE4.md (web game public/, functions/, tests/, worker.js FROZEN; GDScript files <600 lines; local commits on branch wave5/integrate only; no push; no subagents).

State: this branch already merges wave5/skills (class kits, medpacs, revive, ability bar), wave5/campaign (godot/scripts/campaign/**, temple.tscn, galaxy.tscn, save/load) and wave5/story (godot/scripts/story/**, briefing/dialogue/codex scenes, all story JSON). Read docs/godot/wave5/{skills,campaign,story}-REPORT.md first — their "Integration requests" sections are your to-do list.
The maps lane is STILL RUNNING and owns godot/data/rescue.json, godot/scripts/map*.gd, godot/tests/map_test.gd. Do NOT edit those. Where you need a roster change in rescue.json (adding the Medic), make the battle take its squad from the campaign roster instead, so rescue.json's squad is only the fallback for direct-launch mode.

Goal: Jess double-clicks the desktop shortcut (godot/run.sh → menu) and can play the whole loop without a dead end.
1. Menu: New Campaign (difficulty pick → Temple), Continue Campaign (loads user://campaign.json; greyed out if none), keep the direct Rescue mission button.
2. Temple hub: roster, research, build, arsenal, teams, legacy all reachable; a Temple talk (story next_temple_talk) shows when one is due; a Codex button opens codex.tscn and returns.
3. Galaxy → pick mission → briefing.tscn (story start_briefing, choices applied to story state) → squad select (4 soldiers from roster, Medic class selectable) → battle. Battle uses the chosen soldiers' class, rank stats and kits; any campaign mission without its own map uses the rescue map for now (list which in the report).
4. Battle end → debrief (story start_debrief) → apply_mission_result (XP, kills, Wounded → recovery days, deaths only if the web rules say so — downed = Wounded) → save → Temple. Guard against applying twice.
5. Story state lives inside the campaign save; era progression and bonds update from results.
6. Ability bar: show only the selected soldier's kit (remove "Not in kit" rows); unusable kit actions stay greyed with their reason.
7. game.gd is 565 lines: move campaign/battle bridging into new scripts (e.g. campaign_bridge.gd); every .gd stays <600.
8. godot/test.sh: register campaign_test.gd and story_port_test.gd; remove any dependency on `rg` (not installed — use grep). Fails on any failure or SCRIPT ERROR.
9. New headless end-to-end test (tests/loop_test.gd): new campaign → galaxy launch → briefing choice → bot plays the battle → debrief → result applied → back in Temple → save/load round trip → wounded soldier recovers after days pass.
10. Visual pass on the new screens so they match the battle's look (same fonts, colors, panel style, readable at 1366×768 and 1920×1080; no overlapping text, no placeholder "stub" text visible to the player).

Done = ./godot/test.sh 0 failures, no SCRIPT ERROR, bot bands still Story ≥14 / Normal 9–12 / Hard 4–7 / Legend 1–3 (report numbers); screenshots docs/godot/shots/wave5-loop-{menu,temple,galaxy,briefing,battle,debrief}.png captured by driving the real flow (direct-scene capture only if the flow stalls, say so); docs/godot/wave5/integrate-REPORT.md with what a player can now do, what is still placeholder, and the exact steps to test; committed on wave5/integrate.
