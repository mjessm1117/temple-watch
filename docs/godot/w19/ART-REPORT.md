# W19 soldier armour pass

Seven class pairs are staged in `godot/assets/units/w19/`. Class wiring is unchanged. The [before/after sheet](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-art-before-after.jpg) compares W17 and W19 at 844×390 battle distance and armory close-up. The [lineup](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-lineup.jpg) shows all seven in the idle pose. The original sheets are preserved with `-v1.jpg` suffixes. These are Blender renders of staged assets, not live game captures.

## Head choices and gear

All six rebuilt heads use choice **(b)**: the Trooper rig with a complete Blender armour shell and class headgear. The exposed Meshy preview geometry is gone. Every helmet has a navy faceplate and dark visor; there is no visible face or skin colour. Scout keeps its existing enclosed helmet and rig. All new head pieces are attached to `Head`.

| Class | Helmet choice and class read | Gear and attachment |
| --- | --- | --- |
| Sniper | (b) Olive hood crown; visor and scope seated on helmet | Larger, dark olive shoulder drape on `spine_03` |
| Heavy | (b) Tan shell with orange cheek armour | Curved orange pauldrons on both clavicles, below helmet line; width 0.23 versus 0.30 previously |
| Tech | (b) Teal goggles and antenna on enclosed shell | Rounded teal tool pods and bevelled harness on `spine_03` |
| Officer | (b) Seated navy peaked cap with crimson band and brim; no crest or cross | Crimson cape and rank plate on `spine_03` |
| Medic | (b) Enclosed shell with small off-white forehead badge and red cross | Rounded off-white satchel with red cross on `pelvis`; strap on `spine_03` |
| Droid | (b) Elongated yellow dome with twin photoreceptors | Rounded chest and shoulder plates on `spine_03` and clavicles |
| Scout | Existing model and helmet | Existing model; no new parts |

Gear uses flat matte class colours. All added boxes have rounded bevels; helmets, pauldrons, pods, satchel, and Droid plates use curved geometry. The [idle/run/shoot sheet](/home/jess/projects/tw-logs/w19/art/w19-pose-review.jpg) shows the attachments in three animation poses. The Sniper cloak remains angular at its hem, but it is larger and darker than the first pass.

## Credits and budgets

The first W19 pass spent **120 Meshy credits** on six previews, 20 each. This pass spent **0** and made no Meshy calls. [credits.log](/home/jess/projects/tw-logs/w19/art/credits.log) is unchanged. The staged pack is **9,359,168 bytes** (9.36 MB), under 12 MB. Every LOD0 is under 15,000 triangles and every LOD1 under 2,500. Each GLB retains the eight clips `idle`, `gunIdle`, `run`, `shoot`, `hit`, `death`, `aim`, and `walk`.

| Class | LOD0 tris | LOD0 bytes | LOD1 tris | LOD1 bytes |
| --- | ---: | ---: | ---: | ---: |
| Sniper | 9,074 | 964,584 | 2,135 | 392,472 |
| Heavy | 9,346 | 981,456 | 2,059 | 399,052 |
| Tech | 8,674 | 964,504 | 2,492 | 405,732 |
| Officer | 7,998 | 951,712 | 1,879 | 380,484 |
| Medic | 7,978 | 973,756 | 1,859 | 378,636 |
| Droid | 9,050 | 997,408 | 2,403 | 409,632 |
| Scout | 4,925 | 763,228 | 1,969 | 396,512 |

## Validation

Godot 4.7.2 headless import exited 0. See [import log](/home/jess/projects/tw-logs/w19/art/art2-final-import.log). `./godot/test.sh` exited 0 after the final art build. Its [full log](/home/jess/projects/tw-logs/w19/art/art2-full-test.log) contains zero `SCRIPT ERROR`, parse error, `ERROR:`, or nonzero-failure lines. Every suite reports zero failures. Main results: 368 checks and Normal rescue **9/20**; W17 wire 139 checks; Core17 272; Phone17 663. `git diff --check` exited 0.
