# W16 scroll lane report (`tw-w16-scroll` + resume `tw-w16-scroll2`)

## Root causes
1. **Armory jump/fight**: `loadout_arsenal.gd` `_select_slot()` set `scroll_vertical` *and* moved the content with `position.y = -target`. Two owners of one list: when the target was past the scroll range, the hack overshot and the container snapped it back (the jump). Removed `position.y`. The phone auto-scroll stays, because `armory12` requires that tapping a slot brings its upgrade cards into view. It now waits one frame for layout, sets `scroll_vertical` only, and has the container lay out its children right away. `_show_gear`/`_show_skills` still reset to 0, but all three only run from a tap, and a drag now cancels taps, so none of them fire mid-drag.
2. **Drags that start on a button pressed it**: buttons used `MOUSE_FILTER_STOP`, so the ScrollContainer never saw the drag. New `godot/scripts/touch_scroll.gd` (a ScrollContainer subclass) sets `scroll_deadzone = 10` and switches every STOP descendant (including ones added later) to PASS. A tap still selects the item.
3. **Fallback touch path (headless, and web devices that send touch but report no touchscreen)**: Godot's built-in touch scroll only runs when `DisplayServer.is_touchscreen_available()`. `touch_scroll.gd` handles ScreenTouch/ScreenDrag itself in that case. **Resume fix:** it never sent `NOTIFICATION_SCROLL_BEGIN`, so the button under the finger still fired on release. It now sends SCROLL_BEGIN/END like Godot's native path, and buttons cancel their press.
4. **Failing `roster card drag scrolls`**: the test fixture was wrong, not the code. With 4 squad cards, the strip at 844x390 is 682 px wide with a 682 px page, so there's nothing to scroll. The test now narrows the strip to 300 px (portrait width) so it overflows. That exposed bug 3. The test has more checks now, none weaker.

`input_devices/pointing/emulate_mouse_from_touch=true` is confirmed in `project.godot`.

## ScrollContainers (18 total)
| File | List | Change |
|---|---|---|
| campaign/squad.gd:54 | roster card strip (horizontal) | touch_scroll |
| campaign/squad.gd:204 | inspector drawer / armory list | touch_scroll; arsenal `position.y` hack removed |
| campaign/temple.gd:163, :175 | temple panels | touch_scroll |
| campaign/home12_room_grid.gd:19 | room grid | touch_scroll |
| campaign/galaxy.gd:77, :92, :103 | tab strip, offers, detail | touch_scroll |
| campaign/sith_screen.gd:67 | Sith pages | touch_scroll |
| story/story_screen.gd:152, :376 | story / journal | touch_scroll |
| menu.gd:45, :108 | main menu, difficulty list | touch_scroll |
| graphics_settings.gd:128 | phone settings tabs | touch_scroll |
| hud_controls.gd:193 | battle desktop abilities | **not changed, handed to the battle lane** |
| hud_phone.gd:53, :71 | battle phone abilities, details | **not changed, handed to the battle lane** |
| battle13_bar.gd:42 | battle ability popup | **not changed, handed to the battle lane** |

Battle HUD handoff: the first run had swapped these too. I reverted them because `w16/battle` has its own edits to `hud_phone.gd`/`hud_controls.gd`. To apply, change `ScrollContainer.new()` to `preload("res://scripts/touch_scroll.gd").new()` on those 4 lines.

## Phone page (`godot/web/shell.html`)
- `viewport-fit=cover`, `overscroll-behavior: none` on html/body, body `position: fixed` at `100dvh`, canvas `touch-action: none`.
- Godot's resize policy 2 writes `innerWidth/innerHeight` into the canvas inline style, which overrode the safe-area CSS and offset the canvas. The shell now sets `canvasResizePolicy = 0` and sizes the canvas itself. Its CSS box is the visible viewport (`visualViewport.height`) minus `env(safe-area-inset-*)`, and its backing pixels are box × devicePixelRatio, the same as before. It refits on visualViewport resize/scroll, window resize and orientation change, and calls `scrollTo(0,0)` to clear any page offset.
- `document` `touchmove` `preventDefault` (non-passive): Godot attaches its touch listeners to the canvas (`GodotEventListeners.add(canvas,"touchmove",…)`, checked in the 4.7.2 template). Those run in target phase before the document listener, and `preventDefault` doesn't stop propagation, so in-game drags still arrive. It only blocks Safari page scroll and rubber-band.

## Screenshots (headless Chrome, iPhone UA, touch, DPR 3; W15 game build with old vs new shell, no new export)
- `docs/godot/shots/w16-scroll-before-390x844.png`, `w16-scroll-after-390x844.png`
- `docs/godot/shots/w16-scroll-before-844x390.png`, `w16-scroll-after-844x390.png`
- Both shells: canvas exactly fills the viewport, `scrollY` 0 after a page swipe, no page errors. The new shell boots and renders the game.
- Limits: Chrome can't emulate Safari's toolbars or notch insets, so the cut-off bottom bar can't be reproduced here. Before and after look the same. I didn't do an armory drag in the browser: no new web export was made (lane boundary), and the W15 build doesn't have `touch_scroll.gd`. **A real iPhone test after the wave export is still needed.**

## Tests
- `godot/tests/scroll16_test.gd` (added to `test.sh`), 8/8:
  - Armory: button passes the drag to a 10 px deadzone; the drag scrolls; the drag doesn't select; a short tap selects.
  - Roster: same four checks; a short tap opens the inspector.
- Gate: see below.
- Headless import: exit 0.
- `./godot/test.sh`: **exit 0**, 0 `SCRIPT ERROR`, 0 failures in every suite, Normal rescue **9/20**. `git diff --check` clean.
- Two earlier gate runs failed and were investigated:
  - `temple_view_test`: one timing failure while headless Chrome was running at the same time. It passed 2/2 on quiet reruns.
  - `armory12`: deterministic. It needed the phone slot auto-scroll, which is now restored without the `position.y` hack.
- Runner side-effect screenshots (`wave16-cam-after-phone-low-temple-*.png`) were restored.
