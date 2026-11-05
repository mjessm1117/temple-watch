# Wave 15 armory review fix

## Review items

| Item | Result | Evidence |
| --- | --- | --- |
| 1. Phone gear grid | **PASS** | Four columns fit all eight phone slots in two rows. Labels sit above the icons. The selected preview art remains **120 × 120 px**. The armory test checks label and icon rectangles for every slot. |
| 2. Armor plates | **PASS** | Thin chamfered chest and shoulder plates follow the imported `spine_03` and upper arm bones. The armored Jedi and heavy trooper shots show plates seated on the model. The test checks all three Mk tiers of every Jedi and trooper armor type, including no armor. |
| 3. Hangar | **PASS** | Brighter wall ribs, side weapon racks, detailed cargo crates and a floor pool show the room on phone and desktop. `HANGAR 07` is visible above the stage and clear of the preview. Low uses emissive geometry, with no new post effect or spotlights. |
| 4. Desktop Upgrade | **PASS** | Shorter desktop slot cards leave the first Upgrade card and button fully inside the drawer, above DEPLOY. The test checks its bottom edge. |

## Captures and performance

All four after shots were reopened and inspected at native size. Draws and triangles come from the rendered `Performance` monitors. The phone is 844 × 390 Compatibility/Low; desktop is 1366 × 768 Forward+/High.

| View | Before draws / triangles | After draws / triangles | Shot |
| --- | ---: | ---: | --- |
| Phone Low | 113 / 24,611 | **110 / 26,187** | [phone](../../shots/wave15-armory-after-phone-low.png) |
| Desktop High | 190 / 44,618 | **147 / 47,556** | [desktop](../../shots/wave15-armory-after-desktop-high.png) |
| Different loadout, High | 153 / 47,250 | **155 / 47,754** | [armored Jedi](../../shots/wave15-armory-after-desktop-high-different.png) |
| Trooper heavy armor Mk II, High | — | **154 / 44,446** | [armored trooper](../../shots/wave15-armory-after-desktop-high-trooper.png) |

Low draw ceiling: **130**; observed **110**. The screenshot FPS sample varies with host load and is not a sustained phone benchmark. Original [phone before](../../shots/wave15-armory-before-phone-low.png) and [desktop before](../../shots/wave15-armory-before-desktop-high.png) captures remain available.

## Gate

- Final headless import: exit 0; [log](import.log).
- Full `./godot/test.sh`: exit 0; 56 zero-failure result lines, 0 `SCRIPT ERROR`, 0 error/failure matches, Normal rescue 9/20. `armory13_test`: 253 checks; `armory15_test`: 50 checks. [Log](test.log).
- `git diff --check`: clean.
