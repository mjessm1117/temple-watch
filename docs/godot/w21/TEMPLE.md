# W21 Lane A — Temple hub and rooms (lane tw-w21-temple, branch w21/temple, worktree /home/jess/projects/tw-w21/temple)

FIRST read /home/jess/projects/temple-watch/docs/godot/w21/COMMON.md and follow it exactly (setup, rules, gate, proof, final message). Use `<lane>` = `temple`.

## Goal
Audit problems #1, #4, #5, #6, #7, #13:
1. **Portrait Temple:** make it fit at 390x844. Add a portrait camera composition (or make an accessible room list the primary view in portrait). The footer wraps or paginates inside a safe width. No room plate goes off screen.
2. **One dominant decision:** at 844x390, the current task or most urgent room is the clear focal point. Group sealed or late-game rooms. Cut down how many plate labels show at once, with full labels shown only on focus or selection.
3. **XCOM-style drill-in:** tapping a room tweens the camera to that room in about 0.4-0.6 s, then shows a narrower panel beside it (not an opaque full panel over the same view). Back restores the camera with a tween.
4. **Room alerts on the rooms:** badges plus one action verb ("Research ready", "Recruit", "Promote") sit on the room plate, and the footer counts match them.
5. **Research first fold:** inside the research room, the active project and the first study/queue button show without scrolling at 844x390. Collapse the prerequisite prose.
6. **Recruit cue:** when there is a squad vacancy or new recruits, the hub shows a Recruit badge/action.
7. Keep the W20 size win: the Temple still fills at least 65% of the landscape screen.

## File lease (writable)
godot/scripts/campaign/temple.gd, temple_view.gd, temple_geometry.gd, temple_rooms.gd, home_badges.gd, home_tabs.gd, research_screen.gd (all under godot/scripts/campaign/), godot/scripts/home14_room_names.gd, godot/scripts/phone_layout.gd, the temple .tscn scene(s), new files under godot/scripts/campaign/temple21_*.gd, godot/tests/temple21_test.gd.
Do NOT change the Arsenal routing in temple.gd (around lines 386-435). Lane D is building a unified loadout entry, and integrate will wire it.

## New test: godot/tests/temple21_test.gd
Tests: portrait + landscape fit (no plate/footer off screen), drill-in camera tween + Back restore, badges match footer counts, research button visible on the first fold, recruit badge, Temple at least 65% landscape.

## Done
The gate in COMMON.md passes, the proof sheet is saved, everything is committed on w21/temple, and you send the final message.
