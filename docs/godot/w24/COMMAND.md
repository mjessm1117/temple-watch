# W24 lane: command

Read /home/jess/projects/temple-watch/docs/godot/w24/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w24/command, branch w24/command off aa19dd0. Test: godot/tests/command24_test.gd. Proof: /home/jess/projects/tw-logs/w24/command/.

Goal: commands are fast, forgiving and consistent on touch and PC.
- K4: R = Reload (if the unit has the action), never restart. Restart moves to the pause menu only (input_controls.gd:189).
- K10: add Y Overwatch, End/Backspace End Turn (with the existing confirm when AP remains), 8/9/0 for abilities 8-10, keep 1-7/Tab/Enter/Esc/Q/E/WASD. Contract 7 bindings24() and honor keymap overrides from controls24.cfg.
- K7: phone/touch keeps tap -> preview -> tap again (or Confirm) to move; add a clear Cancel. PC: right-click on a valid tile moves in one click; left-click keeps preview. Respect confirm_move setting.
- K8: destination magnetism - a tap snaps to the nearest valid move tile within ~28 screen px (input_controls.gd:136-142); larger preview marker.
- K6: horizontal swipe in the aim panel cycles targets; keep arrows (battle12_aim.gd:535-539); swipe never fires.
- B2: route preview draws overwatch tiles and reveal markers from threat's route_threat24 (guarded) along the path (map_art_grid.gd for the visuals), not just at the destination; may call preview_route24.
- B12: contract 7 decision_details24 returns every modifier (aim, cover, height, flank, ability, range).
- Respect is_input_busy24: while busy, queue only unit selection; drop moves/fire with no error.
- Tap-count table before/after for move, shoot, ability, overwatch, end turn (phone + PC).

Do not delegate or spawn subagents; do the work yourself.
