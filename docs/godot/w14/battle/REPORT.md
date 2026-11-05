# Wave 14 battle report

## Player change

Aim now frames the fight from behind and beside the shooter at character height. On phone, a camera-attached view of the shooter's back, shoulder, and raised weapon fills the left side while the target stays near the centre. The shooter turns toward the target and leans into a ready pose. Other squad models clear the aim view so the target remains readable. A cyan sightline and gold reticle connect the two units. The existing blaster bolt or saber trail, impact flash or miss whiff, and damage text remain the shot read; a kill or critical hit now adds a 0.38 second camera punch that a tap can skip.

The phone action tray folds away during aim, leaving FIRE, hit chance, damage, target HP, odds, and cancel in one card. The desktop action tray also folds away, leaving a target card and the mission header. Cancel and shot completion restore the tactical HUD and squad models. Tactical camera context and Low graphics settings stay intact.

## Captures

All captures are the same staged Low/Compatibility rescue state. The before shots were taken from the starting branch before edits. I inspected each of the eight captures at full or high resolution.

| View | Before | After |
| --- | --- | --- |
| 844×390 aim | [phone aim before](../../shots/wave14-battle-before-aim-phone.png) | [phone aim after](../../shots/wave14-battle-after-aim-phone.png) |
| 1366×768 aim | [desktop aim before](../../shots/wave14-battle-before-aim-desktop.png) | [desktop aim after](../../shots/wave14-battle-after-aim-desktop.png) |
| 844×390 tactical | [phone tactical before](../../shots/wave14-battle-before-tactical-phone.png) | [phone tactical after](../../shots/wave14-battle-after-tactical-phone.png) |
| 1366×768 tactical | [desktop tactical before](../../shots/wave14-battle-before-tactical-desktop.png) | [desktop tactical after](../../shots/wave14-battle-after-tactical-desktop.png) |

## Low-tier render counts

Counts are one rendered frame per staged capture on this machine, not phone benchmarks. The aim view has fewer draws and triangles because nonessential squad models are hidden for that view. Tactical view geometry and render counts are unchanged. FX add only short-lived objects during a shot; no post effect or persistent world mesh was added.

| View | Draw calls before → after | Triangles before → after |
| --- | ---: | ---: |
| Phone aim | 103 → 87 | 106,634 → 74,675 |
| Desktop aim | 104 → 76 | 106,822 → 74,373 |
| Phone tactical | 73 → 73 | 110,630 → 110,630 |
| Desktop tactical | 102 → 102 | 106,446 → 106,446 |

## Remaining gap against XCOM 2

The foreground shoulder and weapon-ready pose remain simpler than XCOM's authored animations. The map also remains less detailed and dramatically lit than the reference. The tactical phone shot shows nearby cover; longer-range enemy visibility depends on mission placement.

## Cross-lane requests

None.

## Gate

Import passed. `./godot/test.sh` exited 0 with zero `SCRIPT ERROR` lines and zero failures in every suite. `battle13_test`: 69 checks, 0 failures. `battle14_test`: 46 checks, 0 failures. Normal rescue: 9/20. W11 families: holocron recovery 8/20, evacuation 16/20, Sith lord duel 16/20, all with zero suite failures. `git diff --check` passed. Full log: [full-test.log](full-test.log).
