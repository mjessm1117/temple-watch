# Temple home screen polish (Jess chose "all three", 2026-11-02)

## Goal
Make the Temple home screen (scenes/temple.tscn: temple drawing + tab rail + top bar) read clearly at a glance. Three parts, one lane.

## Context
- Current look: run `tests/temple_view_test.gd -- --capture-temple` (see test file) → wave6-temple-*.png. Copy these to docs/godot/shots/home-before-*.png FIRST, before any code change, at 1366x768 and `--large` 1920x1080.
- Code: scripts/campaign/temple.gd (screen shell, title bar, resources row, tabs), temple_view.gd (drawing + room buttons), temple_rooms.gd (room info), temple_geometry.gd (shapes), strat_ui.gd (tab pages). Data via scripts/campaign/data.gd.
- Godot 4.7.2 at /home/jess/projects/.tools/godot/godot. Run `godot --headless --path godot --import` once before testing.

## Requirements
A. Temple drawing
1. Every room has a readable name plate (not only the 4 built ones). Built rooms: name + short status (level / module / "idle"). Empty or sealed slots: dashed/outlined "Build here" or "Sealed · excavate" look, clearly different from built rooms, not plain gray boxes.
2. Hover and click behaviour stays exactly as now (room_selected / room_hovered signals, tab it opens).
3. Remove the small planet-name labels that overlap the bottom of the temple drawing on the home screen (find their source; hide them on this screen only, don't break the galaxy view).
B. Tabs
4. Each tab gets a small icon (drawn with Godot shapes/Unicode-free vector, or an existing icon in assets/; no new image downloads) and its name.
5. The open tab is clearly highlighted (gold edge / brighter fill); others stay muted.
6. Alert badges, computed from real state, at least: missions available (galaxy/ops tab), research idle (no active project), build or module ready / build slot free, soldiers wounded or exhausted, council vote pending. Badge = small count or dot; tooltip says why. No badge when nothing is pending.
C. Top bar + side panel
7. Resources show full names (Credits, Intel, Kyber, Supplies/whatever SF and Rc actually are — read the data, don't guess) with the value; hover tooltip says what it's for and how you get more.
8. Find what "POWER x / y" means in code. If used > capacity (or any other over-limit/negative state), show it in red with a tooltip explaining the effect. Same red treatment for any warning already computed (e.g. low credits for upkeep), only if the data exists.
9. Side panel (status/notice area): keep content, tidy spacing so nothing overlaps at 1366x768.

## Boundaries
- Nothing removed: every tab, page, button and room still reachable; compare before/after.
- Desktop first: 1366x768 and 1920x1080 must both look right, no overlap or clipping.
- Plain GDScript, files < 600 lines: put new code in new files (e.g. scripts/campaign/home_tabs.gd, home_badges.gd, home_resources.gd) rather than growing temple.gd (384 lines).
- No balance/rule changes. No new assets downloads, no Meshy, no network.
- Do not touch public/, functions/, tests/ (web game frozen), worker.js, wrangler.toml.
- Do not delegate or spawn subagents.

## File lease (only these)
godot/scripts/campaign/temple.gd, temple_view.gd, temple_rooms.gd, temple_geometry.gd, strat_ui.gd (only for tab-page hooks), new godot/scripts/campaign/home_*.gd, godot/tests/temple_view_test.gd, new godot/tests/home_ui_test.gd, godot/test.sh (add the new suite to the loop), docs/godot/home/, docs/godot/shots/home-*.png.
Do not commit regenerated wave6-temple-*.png (restore them with git checkout if the capture rewrites them).

## Verification (all required before commit)
1. New suite home_ui_test.gd: every room has a plate; every tab has icon + badge logic; badges appear/disappear with state (fixture saves for each); resource labels use full names; over-limit power turns red; active-tab highlight follows the open page.
2. `./godot/test.sh` exit 0, 0 SCRIPT ERROR, every suite 0 failures, Normal rescue bot still 10/20.
3. Screenshots docs/godot/shots/home-after-{arrival,built,hover,research}.png at 1366x768 plus -1920 versions; and home-badges.png showing at least 2 badges live.
4. Write docs/godot/home/REPORT.md: what each part changed, what SF/Rc/POWER actually mean, before/after shot list, anything not done and why.
5. Commit on the current branch with message "Polish Temple home: room plates, tab icons + badges, clear resources". Do not push.
