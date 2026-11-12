# W21 Lane C — Menus, saves and campaign flow (lane tw-w21-menus, branch w21/menus, worktree /home/jess/projects/tw-w21/menus)

FIRST read /home/jess/projects/temple-watch/docs/godot/w21/COMMON.md and follow it exactly (setup, rules, gate, proof, final message). Use `<lane>` = `menus`.

## Goal
Audit problems #9, #11, #12 (entry points), #15 (transitions):
1. **Faster launch:** from mission select to Deploy, merge mission facts and squad readiness into one reversible flow, at 3 taps or fewer after picking a mission. Keep the story briefing as a visible step when the mission has one (W20 story must still play). Back must return to the screen the player came from at every step.
2. **Save overview:** title Continue shows the campaign's metadata (date in game, mission count, squad size, last played). Add a save screen from the title and the pause menu with at least 3 slots plus the autosave. Loading or overwriting needs a confirm, and old single-autosave saves must still load (migration test).
3. **Settings entry:** the title, Temple and pause menu all show the same "Settings" label in the same position and call ONE function, `open_settings()`, in menu.gd/campaign_bridge.gd. Lane D builds the shared panel; for now point open_settings() at the existing graphics options and list it as an Integrate ask.
4. **Transitions:** use a short fade (about 0.2-0.3 s) on scene changes through campaign_bridge instead of hard cuts. Battle pause menu buttons use the same construction and contrast as other menus.
5. Opening/story screens: text at least 14 px on phone, and the Skip and Next buttons are at least 44 px.

## File lease (writable)
godot/scripts/menu.gd, godot/scripts/campaign_bridge.gd, godot/scripts/campaign/state.gd (save/slot code only), godot/scenes/save_load.tscn + godot/scripts/save_load.gd + godot/scripts/campaign/save_slots.gd (new), godot/scripts/story/opening.gd, godot/scripts/story/story_screen.gd, godot/scripts/hud_phone.gd (pause menu part only), the menu/briefing .tscn scenes, godot/tests/menus21_test.gd.

## New test: godot/tests/menus21_test.gd
Tests: launch path tap count, Back at every step, save slots write/load/confirm + old-save migration, same Settings entry in all 3 places, fade on scene change, story text/buttons sizes, the W20 opening still plays on a fresh save.

## Done
The gate in COMMON.md passes, the proof sheet is saved, everything is committed on w21/menus, and you send the final message.
