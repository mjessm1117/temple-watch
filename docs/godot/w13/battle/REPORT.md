# Wave 13 battle report

## Player change

Selecting a target now moves the camera behind the shooter in 0.28 seconds. A tap finishes the transition immediately. Cancel and fire restore the tactical camera. On the phone, the camera sits far enough behind the shooter to keep the selected unit fully visible between the top header and bottom HUD, including at the near map edge. Aim uses one slim target card with HP, hit chance, damage, FIRE, odds, and cancel. The tall squad and targeting panels fold away during aim.

At both supported sizes, the bottom action bar shows up to five usable actions with large drawn icons. Other usable actions are in More. The phone bar has no keyboard hints. The desktop command row now fits, including CAM and END TURN.

## Captures

The before captures are copies of the Wave 12 aim captures made before this lane's changes, retained under Wave 13 names for direct comparison. The after captures use the same staged rescue shot on Compatibility/Low.

| Size | Before | After |
| --- | --- | --- |
| 844×390 | [phone before](../../shots/wave13-battle-before-phone.png) | [phone after](../../shots/wave13-battle-after-phone.png) |
| 1366×768 | [desktop before](../../shots/wave13-battle-before-desktop.png) | [desktop after](../../shots/wave13-battle-after-desktop.png) |

## Low-tier performance

Compatibility/GLES3 Low keeps its existing graphics settings: no new post effect, SSAO off, dynamic shadows off. No new mesh or GLB was added. The 40-frame process-frame samples below are estimates on this machine, not a phone benchmark. Counts are from the staged rescue aim view.

| Size | Draw calls | Triangles | Frame estimate |
| --- | ---: | ---: | ---: |
| 844×390 | 103 | 155,983 | 67.40 ms / 14.8 fps |
| 1366×768 | 108 | 177,353 | 114.50 ms / 8.7 fps |

These 40-frame wall-clock samples ran while several other Godot suites used the same CPU. Earlier captures on this machine measured about 31 fps at both sizes. The resulting frame estimates are not controlled performance comparisons or phone benchmarks. The Wave 12 captures did not record per-frame render counts, so there is no like-for-like baseline measurement. This lane changes UI and camera position only; it adds no world geometry or Low-tier visual effects.

## Remaining gap against XCOM 2

The aim composition is closer, but unit firing poses, reticle treatment, and target isolation remain simpler than the reference. Nearby allies can still appear between the shooter and target at very short range. Those presentation changes would need work outside this lane's leased files or more animation assets; no such files were edited here.

## Gate

Import: pass. `battle12_test`: 21 checks, 0 failures. `battle13_test`: 52 checks, 0 failures at both sizes, including selected-unit visibility at 844×390 and cancel and fire return. `loop_test`: 357 checks, 0 failures. `hud_night1_test`: 401 checks, 0 failures. Full `godot/test.sh`: exit 0, zero script errors, every suite at zero failures, Normal rescue 9/20 wins. `git diff --check`: pass.
