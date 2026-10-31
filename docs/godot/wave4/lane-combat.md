# Lane: combat — rules, AI and difficulty that create XCOM tension
Read WAVE4.md first; its rules apply. Branch: wave4/combat.

FILE LEASE: `godot/scripts/mission.gd`, `godot/scripts/shot.gd`, `godot/scripts/ai.gd`, `godot/data/**`, `godot/tests/run.gd`, `godot/tests/aim_cases.json`, `godot/tests/generate_aim_cases.cjs`, new files `godot/scripts/rules*.gd`, `godot/scripts/ai_*.gd`, `godot/scripts/map*.gd`. Keep public function names/signatures game.gd calls working (another lane is rewriting game.gd); add new ones freely and list them in your report.

Goal: decisions that matter every turn. Pull real numbers from the XCOM 2 configs.
- Flanking: a target with no cover from the shooter's side is flanked: big crit bonus, shown in the breakdown. Directional half/full cover verified by tests.
- Height advantage (aim bonus, cover negation where XCOM does it). Hunker Down action.
- Destructible cover: cover pieces have HP; explosions/Push/heavy hits degrade full → half → none.
- Pods: enemies in groups; on first sight they scamper to cover (free move, no shot). Engagement cap per difficulty (XCOM MaxEngagedEnemies style). Reinforcements announced one turn ahead with a visible entry marker, from a different direction than the first contact. Enemies enter from 2+ directions.
- AI by role: troopers seek cover and flanks, avoid open ground, don't all shoot the same target repeatedly; Sith close on Jedi. Make Hard/Legend hard through tactics and composition, not aim cheats: wave 3 tuned difficulty mostly via big enemy-aim cuts/player-aim buffs — reverse most of that (stay within ±10 aim of the web DIFF table in public/js/data.js, read-only).
- Map: give the rescue map two real routes to the objective and a high-ground flank. Keep bot win bands over 20 games: Story ≥14, Normal 9–12, Hard 4–7, Legend 1–3. Report the actual numbers.
