# Wave 7 lane: Temple and roster strategy (read docs/godot/wave7/WAVE7.md first)
Branch wave7/strategy. LEASE:
- godot/scripts/campaign/state.gd (split into new campaign/state_*.gd when needed), temple.gd, temple_*.gd, modules.gd, progression.gd, legacy.gd, gear.gd, squad.gd, loadout_*.gd, galaxy_details.gd (field ops panel only)
- godot/data/campaign/core.json, temple.json, research.json, gear.json, legacy.json
- new godot/scripts/campaign/strat_*.gd
- new godot/tests/strategy_test.gd
- docs/godot/wave7/strategy-REPORT.md and docs/godot/shots/wave7-strategy-*

Goal: the Temple and roster carry real XCOM-style strategic weight.
- XCOM port (study recs #8 #11):
  - Avenger-style build grid: excavation, room power, staff slots, adjacency bonuses.
  - Engineer/scientist analog: Temple staff (archivists, artisans, healers).
  - Infirmary and fatigue (Tired soldiers).
  - Training center: retrain and extra ability slots.
  - Proving-ground-style projects.
  - Covert ops: send 2–3 soldiers with risks such as ambush, wound or capture, and rewards.
  - Resistance-order-style policy cards (Council edicts).
  - Recruit pool.
  - Squad size upgrades.
  - Each wing shows staff, production, power and readiness.
- Web port (all remaining deferred items in PORT-INVENTORY.md):
  - temple-build.js placement and adjacency;
  - temple-modules.js undercroft and spires;
  - temple.js recruiting and quests;
  - temple-ui.js Council and recruit UI;
  - teams.js fatigue and detailed risk;
  - fieldops.js spawning and expiry;
  - identity.js voices and Padawan proximity;
  - legacy.js secrets and Council support;
  - base.js and console.js remainder;
  - ui-settings.js.
- Keep the wave 6 3D Temple cutaway, and add the new rooms and staff to it.
- Keep save compatibility: old saves load with defaults.
- Expose state hooks the sith lane will need, e.g. Darkness segments, month tick and mission results, and document them.
