# Wave 16 `anim` report

## Goals

| Goal | Result | Evidence |
|---|---|---|
| Retarget original unit clips onto all seven Meshy skeletons | PASS | All seven GLBs have 15 sampled original clips (24 animated bone/hip tracks each), including idle, run, walk, swing, hit, death, cast, channel, throw, block, and aim. Rest-world rotation deltas are conjugated through the source/target body frames, then solved parent-first into target local rotations. The bind pose is unchanged. |
| Smooth battle states and saber follow-through | PASS | Idle, run, walk, and guard loop; named Jedi receive nonzero state blends. The full original 1.53-second swing, including recovery, is sampled into the battle's 0.50-second action window. Original idle breathing is retained; guard mixes its upper-body motion over grounded idle legs. |
| Grounded movement | PASS | Pelvis translation is kept in place horizontally because battle travel already supplies world movement. Per-frame pelvis height corrects the lower foot to its rest contact height. The planted foot's vertical range over the run loop is 2.6–3.8 cm across seven Jedi (5 cm test limit); the six-frame move strip was inspected. |
| Phone budget | PASS | Low draws 87 → 87 (+0%; limit +15%). Low visible triangles 94,269 → 97,325 (+3.2%; limit +20%). No lights, materials, or post-process were added. The exported Web PCK is 72,819,848 bytes, +947,276 against Wave 15's 71,872,572-byte pack (+3 MB limit). |

## Captures

The four battle captures were rendered at native 844×390 Low and 1366×768 High and opened at native size. Kira, Tor, and Satele appear in each. The frame strips show six poses each for Kira (top row), Tor (middle), and Satele (bottom).

- [Phone before](../../shots/wave16-anim-before-phone-low.png) · [phone after](../../shots/wave16-anim-after-phone-low.png)
- [Desktop before](../../shots/wave16-anim-before-desktop-high.png) · [desktop after](../../shots/wave16-anim-after-desktop-high.png)
- [Idle strip](../../shots/wave16-anim-strip-idle.png) · [move strip](../../shots/wave16-anim-strip-run.png) · [attack strip](../../shots/wave16-anim-strip-swing.png) · [guard strip](../../shots/wave16-anim-strip-saberIdle.png)

## Gate

- Headless import: exit 0, 0 script/parse/import errors.
- `anim16_test.gd`: 329 checks, 0 failures (15 clips and full bone tracks per Jedi, pose changes, blends, loops, planted-foot height). `jedi15_test.gd`: 154 checks, 0 failures.
- Web `--export-pack Web`: exit 0; 72,819,848 bytes.
- Full `./godot/test.sh`: exit 0 across 62 Godot launches; 0 `SCRIPT ERROR`, 0 `Parse Error`, 0 `ERROR:`, and 0 failures in every suite.
- Normal rescue: 9/20 wins, inside the required 9–11/20 band.
- `git diff --check`: clean.

No Meshy calls or external assets were used. The `jedi_models.gd` lookup functions remain unchanged.
