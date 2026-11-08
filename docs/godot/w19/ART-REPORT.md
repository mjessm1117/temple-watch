# W19 soldier armour pass 5: fitted Meshy gear

Seven class pairs are staged in `godot/assets/units/w19/`; class wiring is unchanged. The [pass 3/5 sheet](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-art-pass5.jpg) compares flat grey and colour silhouettes at 844×390 battle distance plus armory close-ups. The [lineup](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-lineup.jpg) shows seven idle poses. The [pose sheet](/home/jess/projects/tw-logs/w19/art/w19-pose-review.jpg) shows idle, run, and shoot. The preceding sheets and source captures are preserved with `-v3` suffixes. These are Blender renders of staged assets, not live game captures.

## Head choices and gear

The five human classes retain their original W17 white Trooper helmet mesh, texture, visor, scale, and rigging. No tan replacement shell or exposed skin remains. Droid alone replaces the helmet with a true-scale yellow head. All new head pieces attach to `Head`.

| Class | Helmet choice and class read | Gear and attachment |
| --- | --- | --- |
| Sniper | Meshy hood trimmed from the preview jacket, widened and seated over the helmet on `Head`; visor and scope remain visible | Meshy rear shoulder/upper-back cloak trimmed from the same preview, bound to `spine_03`; sleeves and torso front removed |
| Heavy | Small orange cheek plates on original helmet | Curved orange pauldrons on both clavicles, below helmet line |
| Tech | Teal brow goggles and slim antenna | Rounded teal tool pods and harness on `spine_03` |
| Officer | Navy peaked cap seated on helmet, with crimson band; no crest or cross | Crimson cape and rank plate on `spine_03` |
| Medic | Off-white forehead panel with red cross on original helmet | Meshy hip kit scaled and seated on `pelvis`, matte off-white with a bold red cross; existing strap remains on `spine_03` |
| Droid | Yellow elongated head at helmet scale with navy faceplate and twin photoreceptors | Rounded yellow chest and shoulder plates on `spine_03` and clavicles |
| Scout | Existing model and helmet | Existing model; no new parts |

The paid previews were inspected in Blender before fitting: Sniper 2,525 triangles, bounds (-0.692,-0.405,-0.948) to (0.689,0.406,0.947), with two connected parts after position welding; Medic 2,368 triangles, bounds (-0.950,-0.665,-0.647) to (0.947,0.666,0.653), with one connected part. The Sniper source was a full sleeved jacket; source-space face cuts retain 637 hood and 556 rear cloak triangles at LOD0, with no sleeves or front torso. The Medic source was a pack with small tabs; all 2,368 source triangles remain at LOD0. LOD1 decimates the fitted pieces to 254/222 Sniper triangles and 947 Medic triangles. Both pieces use flat, matte paint. The hood and cloak follow `Head` and `spine_03`; the hip kit follows `pelvis` in idle, run, and shoot. The other five classes are byte-identical to pass 3.

## Credits and budgets

Pass 5 spent **0 Meshy credits** and made no Meshy API calls. [credits.log](/home/jess/projects/tw-logs/w19/art/credits.log) is unchanged (SHA-256 `b45ff3a805bbe2c8af4c6022f2794b46add6154cf15f6779b079ece5d88ad6bb`). The seven-class GLB pack is **10,817,228 bytes** (10.82 MB), below 12 MB. Every LOD0 is below 15,000 triangles and every LOD1 below 2,500. Each rebuilt GLB retains eight clips: `idle`, `gunIdle`, `run`, `shoot`, `hit`, `death`, `aim`, and `walk`.

| Class | LOD0 tris | LOD0 bytes | LOD1 tris | LOD1 bytes |
| --- | ---: | ---: | ---: | ---: |
| Sniper | 7,110 | 1,302,804 | 2,247 | 797,872 |
| Heavy | 8,409 | 932,896 | 1,834 | 403,740 |
| Tech | 7,737 | 924,804 | 2,490 | 431,448 |
| Officer | 7,061 | 909,056 | 1,590 | 394,532 |
| Medic | 8,969 | 1,395,056 | 2,066 | 794,132 |
| Droid | 7,982 | 972,376 | 2,079 | 398,772 |
| Scout | 4,925 | 763,228 | 1,969 | 396,512 |

## Validation

Godot 4.7.2 [headless import](/home/jess/projects/tw-logs/w19/art/art5-import.log) exited 0 with no script errors. `./godot/test.sh` exited 0; its [full log](/home/jess/projects/tw-logs/w19/art/art5-full-test.log) has 71 zero-failure suite results, zero `SCRIPT ERROR`, zero `ERROR:`, zero parse errors, and Normal rescue **9/20**. Two tracked screenshots outside the file lease rewritten by the test runner were restored. `git diff --check` exited 0.
