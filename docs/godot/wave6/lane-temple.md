# Wave 6 lane: Temple with real shape (read docs/godot/wave6/WAVE6.md first)
Branch wave6/temple. LEASE: godot/scripts/campaign/temple.gd, godot/scenes/temple.tscn, new godot/scripts/campaign/temple_*.gd, new godot/assets/temple/**, new godot/tests/temple_view_test.gd, docs/godot/wave6/temple-REPORT.md, docs/godot/wave6/ref-temple-*, docs/godot/shots/wave6-temple-*.png.
Goal: the Temple hub is a 3D cut-away of the Jedi Temple (XCOM Avenger "ant farm" style): five spires on the ziggurat silhouette, rooms/wings as lit, labeled cells you click. Behind and below it a slowly turning galaxy (nebula, stars, the planets from godot/data/campaign/galaxy.json glowing faintly) — the Temple floats above the galaxy.
- Every web Temple room (public/js/temple-map.js, data-wings.js, data-modules.js) is a cell. Built wings show their module; unbuilt ones are dark scaffolding with build cost. Clicking a cell opens the existing tab (roster, research, build, arsenal, teams, legacy, codex, galaxy) — same panels as now, sliding in over the 3D view.
- Life: small Jedi/clone figures (human.glb) walking or standing in rooms, holo-table glow in research, forge sparks, pulsing lights, gentle camera drift; hover highlights a room with name + status.
- Council events and Temple talks still pop as they do now.
- Test: scene loads, every room maps to a reachable tab, built vs unbuilt state matches a save.
