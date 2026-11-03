# Night 1 battle UI report

## Changes

- Rebuilt the action strip as a centered, horizontally scrollable row of drawn Godot glyph buttons. Each button reads its visibility, AP cost, cooldown and disabled reason from the selected unit and the existing ability definitions. The active action has a brighter border. Existing numbered and function hotkeys remain available.
- Added a selected-unit plate with the existing live portrait, class, HP and AP pips, Will when the unit supplies it, status icons with tooltips, and a bond partner name when present.
- Added large target hit odds, crit odds beside the target, small hit chips for visible enemies, and an expandable breakdown. The breakdown uses `Shot.calculate` through `combat_targeting.gd`; a displayed cap adjustment makes its aim rows sum to the final hit chance. Tab and Q/E cycle legal targets while aiming.
- Kept the existing reachable-tile and path data, with blue one-action and yellow dash borders. Destination shields show half/full cover. The flank warning now checks an enemy's shot *toward* the proposed destination.
- Added animated Jedi/enemy turn plates and a two-second, backed enemy action line. Added an Esc pause panel with battle Settings and the shared Graphics selector. The existing End Turn action still asks for confirmation when squad members have AP.

## Captures

All images are real Godot window captures. The before set was first taken before repository edits, using an out-of-tree copy of `combat_capture.gd` to expose idle, selected and enemy-turn fixture states. The exact 1920×1080 before renders were then repeated from the original commit in an isolated checkout. The after set uses the updated in-tree capture helper. Godot's default aspect scaling cut the 1080p viewport one pixel short, so the helper uses a fill aspect during capture. All 18 PNGs were checked for their requested dimensions. The fixture holds units and camera in the same positions across comparable states.

| State | Before 1366×768 | Before 1920×1080 | After 1920×1080 |
|---|---|---|---|
| Idle | [before](../shots/night1-ui-before-idle-1366.png) | [before](../shots/night1-ui-before-idle-1920.png) | [after](../shots/night1-ui-after-idle.png) |
| Unit selected | [before](../shots/night1-ui-before-selected-1366.png) | [before](../shots/night1-ui-before-selected-1920.png) | [after](../shots/night1-ui-after-selected.png) |
| Targeting | [before](../shots/night1-ui-before-targeting-1366.png) | [before](../shots/night1-ui-before-targeting-1920.png) | [after](../shots/night1-ui-after-targeting.png) |
| Enemy turn | [before](../shots/night1-ui-before-enemy-turn-1366.png) | [before](../shots/night1-ui-before-enemy-turn-1920.png) | [after](../shots/night1-ui-after-enemy-turn.png) |

Additional 1920×1080 after states: [odds breakdown](../shots/night1-ui-after-breakdown.png), [move preview](../shots/night1-ui-after-move.png), [pause and Settings](../shots/night1-ui-after-pause.png). Additional 1366×768 after states: [idle](../shots/night1-ui-after-idle-1366.png), [targeting](../shots/night1-ui-after-targeting-1366.png), [expanded breakdown](../shots/night1-ui-after-breakdown-1366.png).

## Verification and limits

`hud_night1_test.gd` checks ability visibility/cost/cooldown/reason, real shot parity for open/cover/flank/height fixtures, aim-row totals, target order, movement colors, destination flank warning and cover, both turn labels, status tooltip, End Turn confirmation and pause behavior: **45 checks, 0 failures**.

`./godot/test.sh` exited 0 on the final code: every suite reported 0 failures, there were 0 `SCRIPT ERROR` lines, and the Normal rescue bot won **10/20**.

The legacy rescue fixture has no Will attribute, so its plate shows `WILL —`; deployed campaign units display their numeric Will. No battle rule, balance, action or asset was skipped.
