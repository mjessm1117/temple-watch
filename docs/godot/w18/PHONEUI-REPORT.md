# Wave 18 phone battle UI

## What moved

- The battle objective, turn and END TURN now share one top strip with a 44 px visible background at 844 × 390 with a menu button. The rendered map viewport remains full screen beneath the HUD. The selected soldier's portrait, name, segmented HP, action pips and combo glyphs are in a bottom-left plate. Plate arrows and a horizontal swipe cycle the existing squad selection.
- Ability buttons now use round drawn icons with short labels, AP/cooldown badges and the existing apply/consume combo marks. A selected-ability effect line and the three chain Momentum pips sit in the bottom action tray. Momentum Strike sits beside abilities, lights at three pips, and still reads `chain_momentum` with the once-per-turn claim path. MORE retains the existing popup scroll position across refreshes.
- Combo badges sit above the projected head with a gap and a bottom limit above the action tray. The consumed-tag callout starts above the badge row. Camera rotate and center controls moved from the header to a right-edge rail; touch drags from actions, badges and the plate pan the camera.
- Aim has two target icons and visible Momentum pips in a top-right row, a large hit/crit/damage readout, and bottom-right CONFIRM and CANCEL. The old world-space hit/crit chips are hidden on phone, removing the ghost text behind aim.

## Reference and evidence

The phone reference folder was empty immediately before layout work. I used the supplied XCOM 2 PC battle/aim captures (`app268500-05.jpg`, `-15.jpg`) as read-only references, plus the requested phone problem list. No reference image was added to this repo.

| Check | Result |
| --- | --- |
| Headless import | Exit 0, no script errors |
| `phoneui18_test` | 486 checks, 0 failures at 844 × 390 and 667 × 375 |
| Focused `phone17`, `hud18`, `battle12`, `battle13`, `cine15` | 0 failures; Low tactical capture 84 draws (ceiling 85) |
| Full `godot/test.sh` | Exit 0; every suite 0 failures; 0 `SCRIPT ERROR`; Normal rescue 9/20 |
| `git diff --check` | Clean |

Battle, aim and desktop captures are in [phoneui/](phoneui/). The eight other-screen captures and ranked follow-up issues are in [PHONEUI-AUDIT.md](PHONEUI-AUDIT.md). The before/after sheet is outside the public repo at `/home/jess/projects/tw-logs/w18/phoneui/2026-11-07-phoneui-before-after.jpg`.

## Existing assertion changes

- `godot/tests/hud18_test.gd`: the four `meter visible at <pips>` checks at each phone size now assert the always-visible Momentum plate is enclosed by the action tray. The pip-count, availability, once-per-turn and drag assertions remain.

- `godot/tests/battle13_test.gd`: the primary-action count now expects three visible buttons because overflow holds the rest under the Low draw ceiling. Two aim-framing checks now verify that shooter and target bounds clear the right-side confirm panel in two dimensions. The old vertical-only checks assumed a full-width bottom panel. Header clearance and viewport bounds remain checked.

- `godot/tests/tap16_test.gd`: END TURN now uses a 44 px minimum in the thin header; the compact UnitCard has an 11-unit label; sibling controls inside the new button groups may share a compact gap; and the plate surface is allowed to contain its own buttons. All controls still require 44 × 44 hit rects, unrelated controls may not overlap, and unrelated groups keep the 8 px gap check.

No other existing assertion changed.

## Lease note

The required `cine15_test` capture rewrote two tracked `docs/godot/shots/wave16-cam-after-phone-low-temple-{aim,tactical}.png` files outside this lane's write lease. They remain unstaged and are excluded from the commit; the owner of that path should restore or review them. The import also generated untracked `.uid`/import files, which were not moved or staged. The pre-existing untracked `PHONEUI.md` was left untouched.
