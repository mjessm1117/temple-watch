# W16 lane `tw-w16-scroll`: smooth iPhone scrolling everywhere

Worktree: `/home/jess/projects/tw-w16/integrate`, branch `w16/integrate`. Start from the tw-w16-intfix result. Run headless import first.

## Goal
Jess tested on his iPhone. The armory list scrolls badly: it jumps, it fights his finger, and drags that start on a button don't scroll. Make every scrolling list in the game scroll smoothly with a finger on an iPhone. Jess wants a scroll fix only, so don't redesign the armory.

## Known cause (armory)
In `godot/scripts/campaign/loadout_arsenal.gd`, `_select_slot()` sets `scroll.scroll_vertical = target` and also moves the content with `position.y = -target`. Two things move the same list, so it jumps and then fights the touch. Remove the `position.y` hack. If an auto-scroll is still needed, scroll gently, or don't auto-scroll at all on phone. `_show_gear` and `_show_skills` snap to 0, so check that this doesn't fire while the user is dragging.

## Do
1. List every `ScrollContainer` in `godot/scripts/` and `godot/scenes/` (armory, roster, research, journal, story, debrief, galaxy panels, settings). Fix each one so it behaves the same way.
2. For touch drags, set `scroll_deadzone` to about 10 px so a drag that starts on a button scrolls instead of pressing it. Buttons and cards inside lists must pass the drag through: use `mouse_filter` PASS where needed, and a tap still selects the item.
3. Check that `input_devices/pointing/emulate_mouse_from_touch` is on. Fix any code that keeps the content position under its own control.
4. Phone page (web export HTML template and CSS in `tools/web/`): canvas `touch-action: none`, `overscroll-behavior: none` on html and body, and no Safari rubber-band or page scroll behind the game. Keep the viewport meta tag correct (`viewport-fit=cover`). **Also (Jess can't reach End Turn):** on iPhone Safari the game's bottom bar is cut off and there's an empty band at the top. Size the canvas to the *visible* viewport (`100dvh` / `visualViewport` resize, `env(safe-area-inset-*)`), no page offset, so the whole Godot window shows with the address bar both shown and hidden. Screenshot 390x844 + 844x390 before/after. The battle lane fixes the Godot-side HUD anchors; you own `tools/web/`.
5. Add a test: a simulated touch drag that starts on a button inside the armory list moves `scroll_vertical` and does NOT press the button. A short tap still presses it. Cover at least the armory and one other list.
6. If you can, run the web export locally in headless Chrome with iPhone touch emulation (390x844 portrait and 844x390 landscape), do a touch-drag on the armory, and screenshot before and after.

## Boundaries
- Scroll and touch behaviour only. No layout redesign, no art, no Meshy calls. No push, no tag, no publishing.
- Files stay under about 600 lines. Don't touch `public/`. Don't delegate or spawn subagents. Restore test-runner side-effect screenshots.

## Gate
Headless import exits 0. `./godot/test.sh` exits 0 with 0 `SCRIPT ERROR`, 0 failures in every suite, and Normal rescue 9–11/20. `git diff --check` is clean.

## Output
`docs/godot/w16/SCROLL-REPORT.md`: the list of ScrollContainers and what changed in each, the test results, and screenshot paths (`docs/godot/shots/w16-scroll-*.png`). Commit locally on `w16/integrate`.
