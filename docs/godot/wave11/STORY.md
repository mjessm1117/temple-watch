# Wave 11 — STORY lane
Read docs/godot/wave11/COMMON.md first; its rules apply.

## Goal
A main villain arc running through all eras, plus more squad scenes, so the campaign feels like one story.

## Context
The saga already names the antagonists (data/story/*.json, data/campaign/sith.json): Lord Kaan and the Brotherhood of Darkness, with Darth Bane rising. Use THESE characters. Do not invent a new lead villain. Night 1 added 6 personal arcs, callbacks, Journal and era interludes (scripts/story/arc_night1.gd, night1-*.json).

## Requirements
1. Villain arc: 8-12 beats across eras 1-3 (Kaan's rise, Bane watching and doubting, the turn toward the Rule of Two). Beats fire on campaign milestones (mission count, era, Darkness level, key mission wins/losses), shown as short intercepted transmissions/visions with the villain's portrait/name. At least 3 beats react to player choices (Darkness level, who died, arc choices).
2. Recurring rival in battle: at 2-3 points the arc sets a battle flag "villain_present" with a line of bark at battle start and end (the Missions lane owns battle logic; you only set the flag and the lines, through the existing story → battle data path).
3. Squad scenes: 12+ new Temple scenes between squad members (pairs and trios), unlocked by bonds/missions/era, 3-6 lines each, at least half with a choice that shifts bond or Darkness. Show in the Journal after viewing.
4. Finale setup: the era-3 ending text varies by Darkness and by how many villain beats the player answered in the light/dark.
5. Keep all Night 1 content working (arcs, callbacks, Journal, interludes, unique rewards).

## File lease (only these)
godot/scripts/story/* (story_engine.gd hook lines only, stays <600), godot/scripts/campaign_bridge.gd, godot/scripts/campaign/bond_story.gd, bond_overlay.gd, sith_rivals.gd, sith_screen.gd, new files godot/scripts/story/villain11_*.gd and scenes11_*.gd, new godot/data/story/wave11-*.json, godot/tests/story11_test.gd, godot/test.sh (suite line only), docs/godot/shots/wave11-story-*.png.
Do NOT edit state.gd, temple*, strat_*, galaxy*, mission*, hud_*.

## Tests (story11_test.gd)
Every villain beat reachable in a scripted campaign; choice-reactive beats branch; squad scenes unlock and log to Journal; finale variants differ by Darkness; Night 1 story suite still green.
