# W16 phone tap report

## Screen audit

`tap16_test` walks visible enabled `BaseButton` controls and custom `MOUSE_FILTER_STOP` controls with a `gui_input` handler. It checks 44×44 hit rects, 56 px primary height, 14 px overridden button fonts, overlap, and 8 px gaps. It clips lists to their visible scroll viewport and prints failures by node path.

| Screen | 844×390 | 390×844 | Result |
|---|---:|---:|---|
| Battle action bar, End Turn, abilities, top HUD | PASS | PASS | 56 px primary actions; 8 px spacing |
| Aim confirm, cancel, target cycle | PASS | PASS | Confirm and Cancel 56 px |
| Temple home, tabs, ROOMS list | PASS | PASS | Cutaway room plates remain visual on phone; ROOMS is the touch path |
| Galaxy map and nodes | PASS | PASS | Closest planet, offer, ship or operation inside 28 px wins |
| Armory slots and cards | PASS | PASS | 8 px slot spacing; scroll remains draggable |
| Roster cards | PASS | PASS | 14 px names; 8 px gaps |
| Story choice buttons | PASS | PASS | Choice and advance buttons enlarged |
| Pause, settings, dialogs | PASS | PASS | Phone pause content scrolls; controls at least 44 px |

The baseline audit reported 177 failures. The final 844×390 audit passed 95 checks with 0 failures; the 390×844 Xvfb audit passed 93 checks with 0 failures. A real iPhone tap pass remains useful because automated geometry cannot measure thumb accuracy or Safari safe area behavior.

## Controls changed

Dimensions are Godot logical px or explicit minimums; layout can give a control more space.

| Control | Before | After |
|---|---:|---:|
| Battle End Turn | 110×42 | 110×56 |
| Battle unit card | 155×42 | 155×44 |
| Battle ability buttons | 83×55; 3 gap | 83×56; 8 gap |
| Aim Fire/Cancel | 44 tall | 56 tall |
| Temple ROOMS | 44 tall | 56 tall |
| Temple command tabs | 48 tall; 4 gap | 56 tall; 8 gap |
| Temple cutaway room plates | 36–51×38, crowded | visual; 44 tall ROOMS entries at 8 gap |
| Galaxy tab arrows | 27×52 | 44×52 |
| Galaxy MORE | 52×40 | 52×44 |
| Galaxy Temple / intelligence / briefing | 40–44 tall | 56 tall |
| Armory base buttons | 36 tall | 44 tall on phone |
| Armory slots | 87×68; 5×4 gaps | 84×68; 8×8 gaps |
| Armory slot headings | 9 px | 14 px, shortened where needed |
| Roster Deploy | 100×44 | 100×56 |
| Story Skip / Advance | 64×34 / 30 tall | 64×44 / 56 tall |
| Story choice | 44 tall | 56 tall |
| Pause/settings rows | 38 tall | 44 tall, scrollable |

Phone labels on resized controls are at least 14 px. Battle ability glyph buttons now draw a brighter pressed fill and border. The shared scroll container owns all four battle lists as well as the existing roster and armory lists. `scroll16_test` includes a battle ability drag and confirms that it scrolls without activating the ability.

The battle header uses a 108 px phone height with 8 px between its rows. The phone aim camera widens its field of view so both units stay between that header and the 56 px action strip; `battle13_test` checks the resulting fit.

## Screenshots

| Screen | Before | After |
|---|---|---|
| Battle bar | [before](../shots/w16-tap-before-battle-bar.png) | [after](../shots/w16-tap-after-battle-bar.png) |
| Armory | [before](../shots/w16-tap-before-armory.png) | [after](../shots/w16-tap-after-armory.png) |
| Temple home | [before](../shots/w16-tap-before-temple-home.png) | [after](../shots/w16-tap-after-temple-home.png) |

All six screenshots are 844×390 Xvfb captures. The before images use the unchanged branch version of `godot/scripts`; the after images use this lane.

## Gate

Headless import: PASS, exit 0. `tap16_test`: PASS at both phone orientations. `scroll16_test`: PASS, 11 checks. Full `./godot/test.sh`: PASS, exit 0, 0 `SCRIPT ERROR`, 0 failures, Normal rescue 9/20. `git diff --check`: PASS. Runner side-effect camera screenshots restored.
