# W25 lane: roster (D)

Read /home/jess/projects/temple-watch/docs/godot/w25/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w25/roster, branch w25/roster off 4f2e4c7. Test: godot/tests/roster25_test.gd. Proof: /home/jess/projects/tw-logs/w25/roster/.

Goal: your people matter between missions. You can see who is hurt or tired, make care choices, and gear up a soldier who fills the screen, like XCOM's Armory.
- Fatigue reserve: the audit's mid save has its front-line three at 80 fatigue and unable to deploy. The squad screen shows Ready / Tired / Wounded groups with return ETA, and offers a one-tap "best ready squad" fill. Do not change fatigue rules, only how they are shown and chosen.
- G10 patient choices: implement `open_from_temple(focus)` and `patient_actions25(soldier_id)` (contract 4). The Medical focus lists the wounded with ETA and 2-3 real choices from existing systems: full rest, light duty (staff a room while recovering, if the rules allow it), or a healer assignment that speeds recovery at a cost. Effects must go through existing state calls; any new rule goes in Integrate asks to economy.
- G11 loadout: the selected soldier is large (at least 45% of the screen height at 390x844 and on the left half at 844x390) using the existing rig and portrait. Secondary slots collapse behind one toggle. Choosing an item shows a stat delta from `loadout_delta25` (contract 5), green up and red down, in a single row. Slot targets stay >=44 px.
- Equip path: from Temple, Equip takes <=3 taps (today 4: More -> Arsenal -> slot -> item).
- Promotion screen: no regressions. Lift any 9-12 px text to 14 px.
- Test: groups and ETA from a fixture save, best-ready fill skips tired/wounded, the patient action effect saved, delta values correct, the 3-tap equip path, rect checks.

Do not delegate or spawn subagents; do the work yourself.
