# Wave 6 lane: shared look + life for every other screen (read docs/godot/wave6/WAVE6.md first)
Branch wave6/screens. LEASE: godot/scripts/campaign/ui.gd (shared theme — keep its public functions working for the other lanes), godot/scripts/menu.gd, godot/scenes/menu.tscn, godot/scripts/story/story_screen.gd, godot/scenes/briefing.tscn, dialogue.tscn, codex.tscn, new godot/scripts/ui_*.gd, new godot/assets/ui/**, new godot/tests/screens_test.gd, docs/godot/wave6/screens-REPORT.md, docs/godot/wave6/ref-screens-*, docs/godot/shots/wave6-screens-*.png.
Goal: menu, briefing, dialogue/Temple talks, debrief and codex look like the web game, but alive.
- Theme in ui.gd: web palette + fonts (public/css/style.css tokens, ui.css), panel frames with Jedi-archive trim, icons from public/js/icons.js redrawn as Godot vectors, hover glow + soft UI sounds, tab/panel slide transitions. The other lanes' screens pick it up automatically.
- Menu: 3D Temple at dusk with moving clouds/ships and the title.
- Briefing/debrief: holo-projector backdrop of the target planet, speaker portrait (3D bust or framed render of the unit model), typed-out text, choices as framed cards.
- Dialogue/Temple talks: two portraits facing each other, bond meter animating on change.
- Codex: archive-shelves backdrop, entries as glowing holocrons, locked vs unlocked.
- Test: each scene loads, choices still apply, codex opens and returns.
