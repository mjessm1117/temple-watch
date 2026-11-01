# Wave 7 lane: XCOM combat feel (read docs/godot/wave7/WAVE7.md first)
Branch wave7/combat. LEASE:
- godot/scripts/game.gd
- godot/scripts/shot.gd
- godot/scripts/ai.gd
- godot/scripts/abilities_engine.gd
- godot/scripts/attack_presentation.gd
- godot/scripts/enemy_presentation.gd
- godot/scripts/hud_controls.gd
- godot/scripts/input_controls.gd
- godot/scripts/unit_view.gd
- godot/scripts/fx.gd
- godot/scripts/reinforcement_marker.gd
- godot/data/abilities.json, godot/data/units.json, godot/data/difficulty.json
- new godot/scripts/combat_*.gd and cam_*.gd
- new godot/assets/combat/**
- new godot/tests/combat7_test.gd
- docs/godot/wave7/combat-REPORT.md and docs/godot/shots/wave7-combat-*

game.gd is at 567 lines. Split it first (move whole topics into combat_*.gd) so it has room.

Goal: battles play and feel like XCOM 2.
- XCOM port (study recs #1 #5 #6 #9 #10 #14, FEEL-GAP #1 and #4, plus anything else in the gap list that is still open):
  - Action cam: brief, skippable, 0.5–0.75 s blend. The camera must arrive BEFORE the shot result.
  - Enemy turns play in true sequence, each with its own camera beat.
  - Overwatch reaction-fire cam.
  - Shot breakdown in the targeting view: aim, cover, height, flank, range, crit, graze; damage after armor.
  - In-world blocked-line trace.
  - Graze / crit / armor shred.
  - Destructible cover as a Jedi tool: Push, Pull and saber breach.
  - Concealment and ambush: a squad starts concealed when the mission says so; enemy detection tiles are shown; breaking concealment triggers an ambush overwatch.
  - Enemy roles: Sith hunt Jedi, troopers pin lanes, no repetitive focus fire.
  - Pod activation scamper.
  - Bond abilities in battle, using the web legacy bonds, XCOM-style.
  - Hunker, reload and ammo, if missing.
  - The generic Interact action (see the contract in WAVE7.md).
- Web port:
  - view3d/cine.js (cinematics);
  - forcefx.js (Force effects);
  - effects.js;
  - figures.js poses;
  - portraits.js in the HUD;
  - labels.js;
  - fx.js;
  - any web ability or status effect not yet in Godot (check abilities.js against godot/data/abilities.json).
- Keep the balance bands. Retune via difficulty.json if needed and report the numbers.
