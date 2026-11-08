# Wave 18 final integration report

## Phone battle HUD and aim

- The aim card uses a large HIT value and one compact CRIT/DMG line. Both labels fit inside the panel at 844×390 and 667×375. CONFIRM FIRE has one short `HIT · DMG` sub-line without duplicating the numbers.
- AP/cooldown pills sit at the ring's upper right, with 11 px text in UI coordinates (about 13 physical pixels on the phone captures). The icon and short label have their own vertical space.
- The unit plate uses an existing portrait image selected by unit name when available, a fixed portrait fallback otherwise. It shows the name, segmented HP and number, the AP fraction and two pips, and combo glyphs. Portraits render at least 48×48 physical pixels, arrows have at least 44 px physical hit areas, and plates stay within 260×76 at 844 and 230×70 at 667.
- The bottom plate and tray occupy at most 22% of either phone height. Both captures show four ability buttons plus STRIKE and MORE. Each action is at least 48 physical pixels tall. Camera controls share a narrow dark backing rail with light gold icons; the icon color has 12.6:1 contrast against it.
- The four ability rings and the camera icons now draw in shared canvas items. The rendered Low tactical view measures 85 draw calls, meeting the existing 85-draw ceiling while preserving the phone controls.
- The desktop HUD remains in its existing layout. The [phone captures](phoneui/) include recaptured 844 and 667 battles, 844 aim, and 1366 desktop. The four-panel report sheet is outside the repo at `/home/jess/projects/tw-logs/w18/final/2026-11-07-w18-final-sheet.jpg`.

| Phone window | Bottom band | Plate | Visible abilities | Fixed actions |
| --- | ---: | ---: | ---: | --- |
| 844×390 | 19.7% | 260×76 px | 4 | STRIKE, MORE |
| 667×375 | 18.9% | 230×70 px | 4 | STRIKE, MORE |

## Balance audit

The audit scores each ranked promotion ability with one formula: 12 action points + expected damage (mean damage × chance × shots, plus direct damage riders) + 0.8 × healing + 0.65 × shields + 2 × control effects. The class rank score is its JSON rank power plus the mean score of its ranked promotion abilities unlocked through that rank. The same weights and rank-band median rule apply to all 15 classes. Scores below are after tuning; soldiers have seven ranks. Unranked base-kit abilities are excluded; ranked legacy choices are included.

| Class | R1 | R2 | R3 | R4 | R5 | R6 | R7 | R8 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Guardian | 63.3 | 84.7 | 105.1 | 155.8 | 276.4 | 317.4 | 357.9 | 438.3 |
| Knight | 62.0 | 83.5 | 105.0 | 156.0 | 276.2 | 316.7 | 356.6 | 436.4 |
| Duelist | 63.5 | 85.5 | 105.6 | 157.4 | 278.0 | 318.2 | 359.1 | 439.0 |
| Sage | 65.5 | 87.2 | 106.3 | 156.4 | 277.2 | 318.4 | 358.8 | 440.1 |
| Consular | 62.0 | 82.8 | 104.2 | 155.0 | 275.3 | 316.2 | 356.4 | 437.9 |
| Sentinel | 62.0 | 84.4 | 106.2 | 157.3 | 278.1 | 318.2 | 359.5 | 439.8 |
| Wayseeker | 67.5 | 86.9 | 108.1 | 158.4 | 279.2 | 318.9 | 359.6 | 440.9 |
| Trooper | 120.5 | 136.2 | 155.4 | 174.9 | 195.2 | 215.2 | 236.4 | — |
| Heavy | 120.0 | 137.5 | 157.6 | 177.4 | 197.8 | 218.3 | 238.7 | — |
| Sniper | 114.0 | 133.9 | 154.1 | 174.5 | 194.6 | 215.2 | 236.1 | — |
| Scout | 112.7 | 133.6 | 153.5 | 173.1 | 193.1 | 212.9 | 234.0 | — |
| Medic | 115.2 | 134.1 | 154.7 | 174.3 | 194.1 | 213.7 | 234.3 | — |
| Tech | 115.0 | 136.7 | 156.4 | 176.6 | 196.6 | 216.6 | 237.1 | — |
| Droid | 118.0 | 135.0 | 155.2 | 176.6 | 196.8 | 216.6 | 237.7 | — |
| Officer | 114.0 | 134.5 | 155.1 | 175.1 | 195.4 | 215.6 | 235.3 | — |

| Numeric tune | Ability score before → after | Class rank score before → after |
| --- | ---: | ---: |
| Duelist Aerial Flurry: 3 → 2 shots | 30.4 → 24.9 | R4 158.2 → 157.4 |
| Duelist Falling Star: 2 → 1 shot | 30.5 → 23.8 | R6 319.4 → 318.2 |
| Knight Balanced Assault: 2 → 1 shot | 30.1 → 23.4 | R6 317.3 → 316.7 |
| Wayseeker Living Mountain: area damage rider 6 → 3 | 40.8 → 37.8 | R8 441.1 → 440.9 |
| Medic Med Beacon: duplicate heal rider 4 → 0; legacy 2 HP heal stays | 18.8 → 15.6 | R7 234.5 → 234.3 |

In class JSON, only numeric values and the matching numerals in their descriptions changed. The Med Beacon adjustment removes a duplicate heal while retaining its legacy 2 HP heal and squad shield. The audit enforces soldier R1 over every Padawan I, soldier R3 over every Knight I, every Master I over soldier R5, and every Grand Master over every soldier rank-7 capstone. Every class score rises or holds by rank. The largest ability-to-median ratio is 1.57, under the 1.6 limit.

The full JSON structural check removes names, descriptions, and tag labels, then replaces all numbers with `N`. Result: **176/176 distinct class-prefixed abilities, zero duplicate groups**. Every ability applies or consumes a chain tag, including Adaptive Mastery's `adaptive_consume` rider.

## Test and gate

- `phoneui18_test`: 561 checks, 0 failures without capture; 565 checks, 0 failures in the rendered recapture.
- `balance18_audit`: 202 ranked abilities scored; 176 unique class-prefixed abilities, all chaining, 0 failures.
- Final headless import: exit 0, no script errors. `./godot/test.sh`: exit 0 across 76 suite launches, every suite at 0 failures, 0 `SCRIPT ERROR`, Normal rescue 9/20. `git diff --check`: clean. The two tracked `wave16-cam-after-phone-low-temple` captures rewritten by `test.sh` were restored before commit.

Existing assertion updates: `godot/tests/battle13_test.gd` now expects four visible primary phone actions at turn start and checks their 48 physical pixel height. `godot/tests/hud18_test.gd` checks the STRIKE button's 48 physical pixel height. `godot/tests/phone17_test.gd` now measures hit areas in physical pixels and checks the compact AP pips. `godot/tests/phoneui18_test.gd` retains its previous checks and adds physical-pixel band, plate, portrait, ability-count, badge, and aim containment checks. `godot/tests/tap16_test.gd` now measures phone hit targets and the tray gap in physical pixels and accepts 48 px ability buttons. No other existing assertion was changed.
