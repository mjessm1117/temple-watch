# Wave 15 integration fix

Godot 4.7.2. Captures inspected at their native dimensions: phone 844×390 Compatibility/Low; desktop 1366×768 Forward+/High, except tactical snow at Forward+/Medium. Render counts come from the captured frame, not a physical phone FPS run.

| # | Result | Finding and verification |
| --- | --- | --- |
| 1 | **PASS** | Sith territory haze now has a filled, clouded center and feathered perimeter. Visible in the selected [phone](../shots/wave15-intfix-galaxy-selected-phone.png) and [desktop](../shots/wave15-intfix-galaxy-selected-desktop.png) views. |
| 2 | **PASS** | Low phone planets are 35% larger and 28% brighter. [Overview](../shots/wave15-intfix-galaxy-after-phone.png); draws 103→103. |
| 3 | **PASS** | Compact briefing uses less vertical spacing and a smaller mission title. “Outpost Aurek-7 · Sith frontier” is fully visible above the MISSION BRIEFING button in the [selected phone capture](../shots/wave15-intfix-galaxy-selected-phone.png). |
| 4 | **PASS** | The selected holo card now uses the same `galaxy_intel.risk()` level and name as the briefing: “RISK 3/4 · HIGH”. Regional event threat is still used for unrelated map indicators. |
| 5 | **PASS** | Phone aim shooter is fully visible within the gameplay area; target and hit readout stay clear in the [aim capture](../shots/wave15-intfix-after-phone-low-temple-aim.png). |
| 6 | **PASS** | Medium/High battle scenes now apply the theme mood environment directly. Snow has a cool fill, stronger key, and distinct shadow contrast in [before](../shots/wave15-intfix-before-desktop-medium-snow-tactical.png) and [after](../shots/wave15-intfix-after-desktop-medium-snow-tactical.png). Low path is unchanged. |
| 7 | **PASS** | Aim and desktop HUD controls read “Cinematics: On/Off”; widths and phone font size were adjusted. The [phone aim](../shots/wave15-intfix-after-phone-low-temple-aim.png) and [Medium tactical](../shots/wave15-intfix-after-desktop-medium-snow-tactical.png) captures show the On state. |
| 8 | **PASS** | Sava, Tem, and Ressa play non-bind idle poses on the [phone](../shots/wave15-intfix-battle-after-phone.png) and [desktop](../shots/wave15-intfix-battle-after-desktop.png) battle fields. `jedi15_test` now checks idle bone transforms against bind pose for all seven Jedi; 154 checks, 0 failures. No Sava retarget change was needed. |
| 9 | **PASS** | Kira’s two chest pieces became one shallow chamfered plate, with muted tier tint and no pale emission. [Armored Kira](../shots/wave15-intfix-armory-kira-desktop-high.png). |
| 10 | **PASS** | Wider roster cards, smaller portrait, and 11 px name font keep “Sgt. Rhal Dax” clear of the portrait on the [selected desktop card](../shots/wave15-intfix-armory-dax-desktop-high.png). |

## Low render counts

| View | Draws before→after | Triangles after | Budget |
| --- | ---: | ---: | --- |
| Galaxy phone | 103→103 | 43,831 | ≤118 (+15%) |
| Aim phone | 96→96 | 63,889 | ≤110 (+15%) |
| Battle phone, Sava/Tem/Ressa | 87→87 | 100,397 | ≤100 (+15%) |

The battle before and after captures use the same named Jedi fixture: [before](../shots/wave15-intfix-battle-before-phone.png), [after](../shots/wave15-intfix-battle-after-phone.png). The reviewed changes do not alter Low battle lighting or character geometry. The original Wave 15 phone aim capture supplies the 96-draw before value.

## Gate

Fresh and final headless imports exited 0 ([final log](INTFIX-import.log)). [`./godot/test.sh`](INTFIX-test.log) exited 0 across 61 Godot invocations, with 0 `SCRIPT ERROR`, 0 parse errors, and 0 suite failures. Normal rescue won 9/20. `git diff --check` was clean.
