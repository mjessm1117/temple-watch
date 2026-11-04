# Wave 11 — Combined-branch balance fix

## Goal
`./godot/test.sh` on branch `w11/integrate` exits 0. It currently fails 2 checks in `missions11_test`:
- `FAIL: r_caves campaign Normal 35–80% band` (holocron recovery)
- `FAIL: r_seventh campaign Normal 35–80% band` (Sith lord duel)

The band is 7–16 wins out of 20 (`missions11_test.gd` line ~57).

## Context
- This branch merges 4 lanes: battle feel, missions, campaign layer, story. Each passed its tests alone.
- Missions lane alone: holocron 15/20, evacuation 15/20, duel 16/20 (top edge of band).
- After merging, holocron and duel leave the band. Most likely a campaign-lane change (Temple upgrades / galaxy events now give the squad real bonuses) or a battle-lane change pushes wins above 16. Confirm; don't assume.

## Steps
1. Run `godot --headless --import` in `godot/` first (fresh worktree).
2. Make the test print the actual win count per family (e.g. `print(id, " wins ", wins, "/20")`). Keep the band at 7–16. Do NOT loosen it.
3. Find which merged change shifted the result. Write the cause in 2–3 lines at the bottom of this file.
4. Tune the two missions so Normal lands about 10–13/20: enemy count, enemy HP/damage, reinforcement timing, or objective timer. Keep the map layouts.
5. If the cause is a real bug (e.g. a campaign bonus applied twice), fix the bug, not the mission numbers.
6. Run the full `./godot/test.sh`. Required: exit 0, 0 `SCRIPT ERROR`, every suite 0 failures, Normal rescue bot still 10/20, evacuation still in band.

## File lease
- `godot/data/campaign/missions.json` (r_caves, r_seventh entries only)
- `godot/data/maps/w11_holocron.json`, `godot/data/maps/w11_duel.json` (spawns/reinforcements only)
- `godot/data/units.json` (Wave 11 enemies only)
- `godot/scripts/mission11_families.gd`, `godot/scripts/enemy11_tactics.gd`
- `godot/tests/missions11_test.gd` (print lines only)
- Any other file only for a confirmed bug fix, smallest edit, and name it in the commit message.

## Boundaries
- Plain GDScript, files under 600 lines. No new art or assets.
- Commit on `w11/integrate`. No push. No merge to main.
- Do the work yourself; do not delegate or spawn subagents.

## Cause
The campaign merge applies starting Medical Halls and Barracks bonuses once each, giving every squad member +2 HP; fresh campaigns have no galaxy event modifier.
The battle merge changed presentation and turn UI, not headless bot rules. The extra survivability shifted holocron from 15 to 17 wins and duel from 16 to 20.
