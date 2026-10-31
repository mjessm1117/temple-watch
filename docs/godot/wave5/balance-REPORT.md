# Wave 5 combined-build balance

Normal enemies now withstand the combined wide-route map and squad medical skills: `enemy_aim` increases from +5 to +15 and `enemy_hp` from +0 to +3. Select Normal and deploy the rescue mission to play the change. Its 13-turn clock, patrol sizes, reinforcements, player stats, medpacs and abilities are unchanged. Story, Hard and Legend data are unchanged.

Enemy aim remains within ±10 of the frozen web DIFF table: Story −10 (difference 0), Normal +15 (difference +10), Hard +10 (difference 0), Legend +15 (difference 0). No web files, map geometry or enemy placements changed. All three routes, skills and revive remain available.

## Bot policy correction

`godot/tests/loop_bot.gd` previously treated allies before considering the objective and could spend all actions on medicine. It also retained the rescue destination after freeing the prisoner, and survivors headed straight to evac when the escort went down, abandoning the civilian. A traced Normal loss left the prisoner at (9, 10) while all three survivors waited near (5, 23).

The bot now prioritizes freeing an adjacent prisoner, re-evaluates its destination each action, limits treatment to once per actor per turn with an action reserved for movement, and advances after treatment. It regroups to take over a downed escort or reconnect a separated escort with the civilian. These are test-bot decisions, not restrictions on player actions. Existing revive/heal checks still pass; five new checks cover treatment followed by movement, immediate evacuation after rescue, and replacement escort recovery.

## Fixed-seed results

Both runs use the existing seeds 1–20 and unchanged win bands. Before uses the original bot; after includes the policy correction and Normal tuning. These measure the automated policy, not a predicted human win rate.

| Difficulty | Required wins | Before wins | After wins | Freed before → after | Clock losses before → after | Medical uses before → after |
| --- | --- | --- | --- | --- | --- | --- |
| Story | 14–20 | 17/20 | 20/20 | 20 → 20 | 3 → 0 | 19 → 11 |
| Normal | 9–12 | 15/20 | 10/20 | 20 → 20 | 5 → 0 | 70 → 40 |
| Hard | 4–7 | 6/20 | 4/20 | 14 → 18 | 3 → 0 | 129 → 46 |
| Legend | 1–3 | 2/20 | 1/20 | 10 → 10 | 14 → 1 | 232 → 38 |

Normal lands at the requested 10–11 midpoint. Legend's reduced clock losses reflect fixing medical/action priorities and escort abandonment; losses can now resolve through squad defeat rather than waiting at evac.

Numeric trials with the corrected bot: Normal +15 aim and +1 HP yielded 15 wins; +2 HP also yielded 15; +3 HP yielded 10. A preliminary extra timer turn did not fix abandonment and was reverted. No map edits were needed.

## Validation

`./godot/test.sh` exited 0. All four suites passed, including the loop test:

- Tactical/map/skills/presentation: 367 checks, 0 failures.
- Campaign: 45 checks, 0 failures.
- Story port: 225 checks, 0 failures.
- Campaign loop: 179 checks, 0 failures; campaign bot win.
- Total: 816 passed / 0 failed. No `SCRIPT ERROR`, `Parse Error` or `ERROR:` in the final log.

The baseline full command exited 1 at the tactical suite: 362 checks, 1 failure (Normal's win band). Both baseline and final tactical runs emitted an ObjectDB leak warning at exit (10 instances before, 9 after); this warning remains outside this balance fix.

Map checks pass: three routes at least three tiles wide, cover gaps at most four steps, shortest approach 21 steps (limit 22), and two high-ground ramps. Changed GDScript files are below 600 lines. No screenshots were taken: this change affects numeric balance and headless bot policy, with no presentation changes.

Integration requests: none. Open problems: Hard and Legend pass at their lower band boundaries; these results are for the specified 20 seeds only.
