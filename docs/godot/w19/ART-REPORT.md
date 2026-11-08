# W19 soldier armour pass: true-scale helmets

Seven class pairs are staged in `godot/assets/units/w19/`; class wiring is unchanged. The [before/after sheet](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-art-before-after.jpg) compares W17 and W19 at 844×390 battle distance and armory close-up. The [lineup](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-lineup.jpg) shows seven idle poses. The [pose sheet](/home/jess/projects/tw-logs/w19/art/w19-pose-review.jpg) shows idle, run, and shoot. The preceding sheets are preserved with `-v2.jpg` suffixes. These are Blender renders of staged assets, not live game captures.

## Head choices and gear

The five human classes retain their original W17 white Trooper helmet mesh, texture, visor, scale, and rigging. No tan replacement shell or exposed skin remains. Droid alone replaces the helmet with a true-scale yellow head. All new head pieces attach to `Head`.

| Class | Helmet choice and class read | Gear and attachment |
| --- | --- | --- |
| Sniper | Low dark-olive hood draped over helmet back and sides; scope beside the original visor | Curved dark-olive shoulder/back cloak on `spine_03`, 0.56 maximum width, shaped in five cross sections |
| Heavy | Small orange cheek plates on original helmet | Curved orange pauldrons on both clavicles, below helmet line |
| Tech | Teal brow goggles and slim antenna | Rounded teal tool pods and harness on `spine_03` |
| Officer | Navy peaked cap seated on helmet, with crimson band; no crest or cross | Crimson cape and rank plate on `spine_03` |
| Medic | Off-white forehead panel with red cross on original helmet | Bevelled, rounded-box off-white pouch and red cross flush to `pelvis`; strap on `spine_03` |
| Droid | Yellow elongated head at helmet scale with navy faceplate and twin photoreceptors | Rounded yellow chest and shoulder plates on `spine_03` and clavicles |
| Scout | Existing model and helmet | Existing model; no new parts |

The Sniper cloak follows the shoulders and back in idle, run, and shoot. The Medic pouch stays seated at the hip in those poses. LOD0 gear remains bevelled; LOD1 uses simpler geometry to meet the phone budget.

## Credits and budgets

The first W19 pass spent **120 Meshy credits** on six previews, 20 each. This pass spent **0** and made no Meshy calls. [credits.log](/home/jess/projects/tw-logs/w19/art/credits.log) is unchanged (SHA-256 `fe2945bbe515a159b25c7f9dcd78cb15cf2fff698f01ee386320b77ff82fac11`). The seven-class GLB pack is **9,198,044 bytes** (9.20 MB), below 12 MB. Every LOD0 is below 15,000 triangles and every LOD1 below 2,500. Each rebuilt GLB retains eight clips: `idle`, `gunIdle`, `run`, `shoot`, `hit`, `death`, `aim`, and `walk`.

| Class | LOD0 tris | LOD0 bytes | LOD1 tris | LOD1 bytes |
| --- | ---: | ---: | ---: | ---: |
| Sniper | 7,773 | 946,224 | 2,178 | 425,712 |
| Heavy | 8,409 | 932,896 | 1,834 | 403,740 |
| Tech | 7,737 | 924,804 | 2,490 | 431,448 |
| Officer | 7,061 | 909,056 | 1,590 | 394,532 |
| Medic | 6,789 | 906,116 | 1,558 | 392,628 |
| Droid | 7,982 | 972,376 | 2,079 | 398,772 |
| Scout | 4,925 | 763,228 | 1,969 | 396,512 |

## Validation

Godot 4.7.2 [headless import](/home/jess/projects/tw-logs/w19/art/art3-final-import.log) exited 0 with no script errors. `./godot/test.sh` exited 0; its [full log](/home/jess/projects/tw-logs/w19/art/art3-full-test.log) has 71 zero-failure suite results, zero `SCRIPT ERROR`, zero `ERROR:`, and Normal rescue **9/20**. `git diff --check` exited 0.
