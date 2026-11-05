# Wave 13 integration fix

## Changes

- Phone tactical camera now uses a wider selected-unit zoom and can move behind the board edge to keep the selected unit between the header and action tray. The same framing applies after selecting another unit. The default view spans more than seven tiles across.
- Aim preview uses a lateral shoulder position. Shooter and target body bounds no longer overlap at 844×390 or 1366×768; the selected shooter remains clear of the phone HUD.
- Phone mission text reads `T1 · Rescue Mira → evac · 24 left` in full. The phone action tray fills unused primary slots with other usable actions, up to five. Kira now shows Move, Guard, Force Leap, Saber Sweep, and Collapse at turn start.
- Phone armory moves the focused hero camera back so the full hero clears the roster. Narrower slot art and repositioned headings leave at least 4 px of heading padding in every tile.
- `battle13_test` now checks tactical framing at start and after selection, seven-tile width, aim body separation at both sizes, mission text width, and usable action count. `armory13_test` checks hero feet against roster top and heading padding. These additions failed on the merged build before the fixes (8 battle checks and 4 armory checks).

The one edit outside the file lease is `godot/scripts/campaign/loadout_stage.gd`: its focused phone camera distance needed to change to fit the full hero above the roster.

## Gate

| Check | Result |
| --- | --- |
| Headless import | exit 0 |
| `./godot/test.sh` | exit 0 |
| `SCRIPT ERROR` lines | 0 |
| Suite failures | 0 in every suite |
| Normal rescue | 9/20 |
| `git diff --check` | clean |

## Captures inspected

All four were overwritten in `/home/jess/projects/tw-logs/w13/shots/` and inspected: `int-battle-tactical-phone.png` (844×390), `int-battle-aim-phone.png` (844×390), `int-battle-aim-desktop.png` (1366×768), and `int-armory-phone.png` (844×390).

## Aim framing follow-up

- Moved only the phone preview camera closer and lower (side offset 14 → 10, height 2.7 → 2.0) and raised its look point to 0.58. The desktop branch is unchanged.
- `battle13_test` now checks both phone bodies are at least 55 px tall, both full unit bounds clear the header and action panel by 8 px, and the hit-chance badge covers neither body. The tighter body-height checks fail on 8c32bb5 (48 px each); after the fix they measure about 67 px each. The existing separation and desktop checks remain green.
- Headless import and `./godot/test.sh` exited 0. Every suite reported 0 failures, there were 0 `SCRIPT ERROR` lines, Normal rescue was 9/20, and `git diff --check` was clean.
- Recaptured and inspected `int-battle-aim-phone.png` (844×390, Compatibility/Low) and `int-battle-aim-desktop.png` (1366×768, Forward+/Medium) in `/home/jess/projects/tw-logs/w13/shots/` with `battle13_capture.gd` under Xvfb.
