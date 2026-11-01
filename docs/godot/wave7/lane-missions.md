# Wave 7 lane: missions and maps (read docs/godot/wave7/WAVE7.md first)
Branch wave7/missions. LEASE: godot/scripts/mission.gd, godot/scripts/campaign/battle_bridge.gd, godot/data/rescue.json, godot/data/campaign/missions.json, new godot/data/maps/**, new godot/scripts/map_*.gd and mission_*.gd, new godot/assets/maps/**, new godot/tests/missions_test.gd, docs/godot/wave7/missions-REPORT.md, docs/godot/shots/wave7-missions-*.
Problem today: every campaign mission plays on the one rescue map.
Goal: every campaign mission gets its own map and mission family, so missions feel different.
- Web port:
  - all maps in public/js/data-maps.js and the rules in maps.js: any board size, entry points, operation steps reach/hold/chase/extract, and overwatch zones;
  - map themes and props from view3d/themes.js and props.js, plus props.glb assets;
  - swarm.js;
  - twin.js (two fronts / a second squad on late crisis steps);
  - hack objectives from hack.js. Implement the Interact contract.
- XCOM port (study recs #2 #3 #4 #7 #15): mission families with their own clocks and fail rules:
  - rescue/VIP extract;
  - hack terminal;
  - destroy relay;
  - defend (escalating waves, no timer);
  - retaliation (save civilians);
  - sabotage;
  - ambush.

  Also:
  - Main objective beyond first contact, with a second phase leading to evac.
  - Concealment start flag per mission.
  - Pods staged at different angles, with reinforcement lanes announced one turn ahead.
  - Plot + parcel style map assembly: hand-authored chunks with validated routes. Every map must have at least 2 validated routes and no chokepoints, as in wave 5.
- Map validation test: every map is reachable, route count ≥2, cover/sightline spread, and every campaign mission id resolves to a map + family.
- Battle code (game.gd, shot.gd, ai.gd) belongs to the combat lane. Request hooks there; don't edit them.
