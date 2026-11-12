# W21 Lane B — Galaxy and Shadow War (lane tw-w21-galaxy, branch w21/galaxy, worktree /home/jess/projects/tw-w21/galaxy)

FIRST read /home/jess/projects/temple-watch/docs/godot/w21/COMMON.md and follow it exactly (setup, rules, gate, proof, final message). Use `<lane>` = `galaxy`.

## Goal
Audit problems #2, #3, #10:
1. **Portrait Galaxy:** at 390x844 the detail drawer becomes a full-screen detail state (or a bottom sheet) with a compact header. No text stacks one character per line. Map-only view comes back with a clear Back button. Landscape keeps the W20 slide-in drawer and the map stays at least 70% of the screen.
2. **Shadow War portrait:** the tabs fit 390 px (stacked, or scrolling sideways with a visible cue). The date/header reflows. No empty-list panels.
3. **Marker context:** every mission marker shows a short label on the map (mission type, urgency/turns left, reward icon) before it is selected. The active or most urgent choice stands out. Labels must not overlap: declutter or offset them, and test that.
4. Galaxy and Shadow War fonts are at least 14 px on phone (W20 overrides went down to 11-12 px).

## File lease (writable)
godot/scripts/campaign/galaxy.gd, galaxy_map.gd, galaxy_details.gd, galaxy_art.gd, sith_screen.gd, sith_art.gd (all under godot/scripts/campaign/), the galaxy/sith .tscn scenes, new files under godot/scripts/campaign/galaxy21_*.gd, godot/tests/galaxy21_test.gd.
Keep the drawer's Launch button calling the same bridge function it calls today. Lane C owns the launch flow.

## New test: godot/tests/galaxy21_test.gd
Tests: portrait drawer fits and keeps no 1-char lines, Shadow War tabs fit at 390, marker labels present + non-overlapping, galaxy at least 70% landscape, fonts at least 14 px.

## Done
The gate in COMMON.md passes, the proof sheet is saved, everything is committed on w21/galaxy, and you send the final message.
