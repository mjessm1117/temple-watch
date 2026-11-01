# Wave 7 lane: the Sith strategy layer (read docs/godot/wave7/WAVE7.md first)
Branch wave7/sith. LEASE:
- new godot/scripts/campaign/sith_*.gd
- new godot/data/campaign/sith.json
- new godot/scenes/sith*.tscn
- new godot/assets/sith/**
- new godot/tests/sith_test.gd
- docs/godot/wave7/sith-REPORT.md and docs/godot/shots/wave7-sith-*

Other files (state.gd, galaxy*.gd, game.gd) are read-only. Request hooks under "Integration requests".

Goal: the enemy plays a strategic game against you, the way ADVENT and the Chosen do in XCOM 2.
- XCOM port (study recs #12 #13):
  - Recurring Sith rivals, Chosen-style: 2–3 named Sith with strengths and weaknesses, knowledge that grows, ambush and kidnap events, a stronghold mission, and a final pursuit. Each defeat reveals one countermeasure.
  - Dark Events: monthly Sith operations, some hidden, that can be countered by a chosen mission.
  - Avatar-style project as visible Darkness segments: reversible by risky objectives, with the next escalation date shown.
  - Retaliation triggers.
  - Month-end council report (resistance report style).
- Web port:
  - Sith ops from temple-ops.js;
  - mercy, mentors and redemption remainder from darkness.js;
  - crises from data-campaign.js not yet in Godot.
- Deliver:
  - pure logic with a clean API, e.g. `SithLayer.new(state)` with `advance_day()`, `month_end()`, `pending_events()`, `counter(op_id, mission_id)`, `rival_for_mission(mission_id) -> Dictionary` (for spawning);
  - a standalone report/rival screen scene;
  - tests for the whole year cycle.
