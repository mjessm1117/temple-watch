# W21 Lane D — Armory, controls and shared style (lane tw-w21-armory, branch w21/armory, worktree /home/jess/projects/tw-w21/armory)

FIRST read /home/jess/projects/temple-watch/docs/godot/w21/COMMON.md and follow it exactly (setup, rules, gate, proof, final message). Use `<lane>` = `armory`.

## Goal
Audit problems #8 (squad side), #12 (shared panel), #14, #15 (tokens), plus the promotion and hiring layout:
1. **One loadout experience:** make the W20 squad character-stage + gear drawer usable outside a mission. Add a public entry point in squad.gd, `static func open_from_temple(tree: SceneTree, soldier_id := "")`, which opens with no Deploy button, keeps the selected soldier, and returns to the Temple with Done/Back. Test it directly. Integrate will point the Temple Arsenal at it.
2. **Shared settings panel:** build one reusable settings panel (graphics tier, sound, text size, camera options already present) in graphics_options.gd. Expose it as `static func build_settings_panel() -> Control`. Lane C will call it.
3. **Shared style tokens in ui.gd:**
   - fonts: bundle an OFL-licensed font set into godot/assets/fonts/ with its licence file (run fc-list to find OFL fonts such as Noto or Inter already on the machine), or adopt one tested fallback
   - one type scale with a phone minimum of 14 px
   - panel/button/header styles
   - disabled-state contrast at or above AA
   - press feedback (scale or tint, about 0.1 s)

   Apply them to squad, promotion, hiring/roster (strat_ui), and loadout details/arsenal.
4. **Promotion and hiring at phone size:** promotion choices sit side by side with their numbers visible without scrolling at 844x390. The roster shows recruit candidates and capacity at the top.
5. Keep the W20 skill-tree and loadout behaviour working (loadout20_test must still pass). research_screen.gd is NOT yours (Lane A owns it).

## File lease (writable)
godot/scripts/campaign/ui.gd, squad.gd, promotion_screen.gd, strat_ui.gd, loadout_details.gd, loadout_arsenal.gd, loadout_skill_tree.gd (all under godot/scripts/campaign/), godot/scripts/graphics_options.gd, godot/assets/fonts/** (new), the squad/promotion .tscn scenes, new files godot/scripts/campaign/style21_*.gd, godot/tests/armory21_test.gd.

## New test: godot/tests/armory21_test.gd
Tests: open_from_temple opens without Deploy and returns to Temple with the soldier kept, build_settings_panel returns a working panel, every themed button passes AA contrast, fonts at least 14 px at phone size, promotion numbers visible without scroll, loadout20 still green.

## Done
The gate in COMMON.md passes, the proof sheet is saved, everything is committed on w21/armory, and you send the final message.
