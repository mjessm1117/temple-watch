# W26 Lane A — Gate Pacing
Read COMMON.md first: docs/godot/w26/COMMON.md
Read audit: /home/jess/projects/tw-logs/w26/audit/AUDIT-REPORT.md

## Goal
Fix first-mission difficulty: fewer enemies at T1, reinforcements arrive later. Target 13–16/20 bot wins (up from 12/20).

## Jess's exact words (ask-43f7daeb)
"Fewer enemies, same open defense fight, none behind, reinforcements later." No concealment. No flanking/behind at start.

## Changes
1. **Delay east pod**: do NOT remove it. Instead, make the east pod (heavy + 2 troopers at ~(20,13),(18,11),(19,12)) start INACTIVE. Activate them when: the player fires a shot OR the player unit crosses into enemy sight range on T1, OR T2 begins — whichever comes first. Announce activation with a "ENEMY REINFORCEMENT APPROACHING" marker/text.
2. **Push opening wave**: the T2 reinforcement wave → push to T3; T3 wave → T4; T5 wave unchanged. Announcement text must say the correct turn.
3. **Tune zone contest**: adjust `mission_objectives.gd:131-140` gate overrun grace slightly to allow one more turn of contest before loss. Only for the opening defend mission (check family=="defend" and mission index == 0 or flag first_mission).
4. **Expose APIs**: `opening_contact26(m)` returns dict with `{pod: "east", status: "inactive"|"active", activation_trigger}`. `next_wave26(m)` returns `{turn, count, entry_tile}`.

## File lease (exclusive)
- godot/data/maps/relay.json
- godot/scripts/mission_objectives.gd
- godot/scripts/mission_pressure.gd
- godot/scripts/mission.gd
- godot/tests/gate26_pacing_test.gd (create new)

## Test (gate26_pacing_test.gd)
- Run bot seeds 1–20 Normal on first defend mission: assert ≥13 wins.
- Assert legacy rescue still 9–11/20.
- Assert east pod starts inactive in mission data.
- Assert first extra wave turn ≥ 3.

## Boundaries
- Do NOT touch unit_view, hud_*, map_art, any other script.
- Do NOT change balance of missions other than the opening defend mission.
- Do NOT add concealment mechanics (Jess said no).
- If bot sits at 12/20 after delay-east alone, reduce west pod by 1 trooper (the lowest HP one) as a secondary knob.

## Output
Commit on branch w26/gate. Leave w26/gate checked out. Screenshot captures at 852×393 initial state showing only west pod active. Gate passes (exit 0, 0 fail, 0 SCRIPT ERROR).
