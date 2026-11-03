# Wave 11 — MISSIONS lane
Read docs/godot/wave11/COMMON.md first; its rules apply.

## Goal
Battles stop feeling the same: new mission types and enemies that demand different tactics.

## Context
Existing families in data/campaign/missions.json: ambush, defend, destroy_relay, hack_terminal, rescue, retaliation, sabotage, vip_extract. Setting is the Ruusan era (Army of Light vs Brotherhood of Darkness).

## Requirements
1. Three NEW mission families, each with its own objective logic, briefing text, win/lose, and at least 3 missions using them spread across the campaign:
   - Holocron Recovery: grab an item, carrier moves slower, reach extraction while enemies converge.
   - Evacuation: escort 4+ civilians to an exit zone under timed reinforcement waves; score by how many survive.
   - Sith Lord Duel: a boss with high HP and 2 phases (phase 2 at 50%: new ability + adds), must be defeated.
2. Four NEW enemy types with distinct AI, reusing existing models (tint/scale/silhouette variants; no new art):
   - Sith Assassin: stealthed until adjacent or revealed, flanks.
   - Shield Droid: frontal shield, damage only from flank/rear or after shield broken.
   - Sith Alchemist: buffs/heals allies, stays back; priority target.
   - Beast (e.g. terentatek-style): fast melee charger, ignores half cover.
   Each shows a one-line tooltip/plate description so the player knows the trick.
3. Mix new enemies into existing missions by era (not all at once in era 1).
4. Balance: Normal rescue bot stays 9-11/20; add campaign-family win-rate lines for the 3 new families in your test (target 35-80% for the bot).

## File lease (only these)
godot/scripts/mission_objectives.gd, mission_pressure.gd, mission_fronts.gd, mission_hack.gd, mission_metrics.gd, ai.gd, enemy_presentation.gd, abilities_engine.gd, map_catalog.gd, reinforcement_marker.gd, new files godot/scripts/mission11_*.gd and godot/scripts/enemy11_*.gd, godot/data/units.json, godot/data/abilities.json, godot/data/campaign/missions.json, new map files godot/data/maps/w11_*.json (+ manifest.json entry), godot/tests/missions11_test.gd, godot/test.sh (suite line only), docs/godot/shots/wave11-missions-*.png.
mission.gd (589 lines): hook lines only, must stay <600. Do NOT edit hud_*, cam_combat, unit_view, input_controls, story or campaign scripts.
