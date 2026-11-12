# W24 lane: hud

Read /home/jess/projects/temple-watch/docs/godot/w24/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w24/hud, branch w24/hud off aa19dd0. Test: godot/tests/hud24_test.gd. Proof: /home/jess/projects/tw-logs/w24/hud/.

Goal: the battle HUD never blocks the fight, explains itself, and offers XCOM-style control settings.
- K3: portrait unit arrows and ability buttons never share hit area (hud_phone_layout.gd:17-25); Overwatch visible without MORE in portrait (3 primary actions if they fit at 44 px).
- B15: End Turn separated from tile/unit tap zones (hud_phone.gd:85-88,344-351), with spacing and the existing confirm when AP remains.
- B1: portrait aim shows one compact odds card; call set_battle_safe_rect24 (guarded) with its rect so shooter + target stay visible (hud_phone.gd:293-300). No duplicated odds.
- B12: full reasons from decision_details24 (guarded) in the odds card, expandable in place, no extra screen.
- B13: persistent reinforcement cue (count + turns + entry) from mission_pressure (guarded), lower priority than the aim card.
- K9: tapping a disabled ability shows its reason + cost/cooldown (hud_ability_button.gd:40-50, hud_phone.gd:435-439).
- K11: small busy cue on input_busy_changed24 (guarded).
- K12: Controls section in settings (graphics_options.gd:29-33, hud_phone.gd:517-530): camera sensitivity, invert pan, invert rotate, edge pan, confirm move, and key remap list via bindings24 (guarded; show read-only list if absent). Write contract 8 controls24.cfg; scrollable with iPhone drag.
- Check every control >=44 px and no overlaps at 390x844, 844x390, 1366x768 (rect test).

Do not delegate or spawn subagents; do the work yourself.
