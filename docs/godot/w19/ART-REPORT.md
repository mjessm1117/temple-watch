# W19 soldier silhouette art

Seven class pairs are staged in `godot/assets/units/w19/`; no class data or unit wiring changed. The [before/after sheet](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-art-before-after.jpg) compares W17 and W19 in 844×390 phone battle framing and in an armory close-up. The [844×390 lineup](/home/jess/projects/tw-logs/w19/2026-11-07-soldier-lineup.jpg) is the phone-distance silhouette check. These are Blender captures at the game's phone camera scale and pitch, not live battle screenshots, because the staged GLBs are not wired into the game. Medic had no W17 class GLB, so its baseline uses the shared Trooper. Scout retains its existing model.

## Credits and construction

The account balance and cost of every paid submission are in [credits.log](/home/jess/projects/tw-logs/w19/art/credits.log). The six heads were submitted as separate previews, and each thumbnail was inspected before the next submission. No refinement or rigging call was made. Meshy preview geometry is untextured; Blender assigns flat armor colors and adds readable class marks. The Droid preview contained a small torso and legs, which were removed before fitting the head.

| Piece | Before | After | Credits | Source |
| --- | ---: | ---: | ---: | --- |
| Sniper hooded head | 13,970 | 13,950 | 20 | Meshy preview |
| Heavy full-face head | 13,950 | 13,930 | 20 | Meshy preview |
| Tech goggle head | 13,930 | 13,910 | 20 | Meshy preview |
| Officer peaked head | 13,910 | 13,890 | 20 | Meshy preview |
| Medic head | 13,890 | 13,870 | 20 | Meshy preview |
| Droid head | 13,870 | 13,850 | 20 | Meshy preview |
| **Total** | | | **120** | Hard cap met |

The six signature gear pieces use free Blender geometry because the preview sequence exhausted the cap: Sniper olive shoulder cloak on `spine_03`; Heavy orange pauldrons on both clavicles; Tech teal tool harness on `spine_03`; Officer crimson cape and rank plate on `spine_03`; Medic off-white satchel on `pelvis` and strap on `spine_03`; Droid yellow chest and shoulder plating on `spine_03` and clavicles. All six new heads are parented to `Head`. Existing weapons remain on `hand_r`. Scout uses its existing full-body mesh, with no new hood.

The W17 tan/cream/navy Trooper base and each class accent remain. The Medic uses a red cross on an off-white raised helmet panel. The Meshy previews' grey paint was discarded; the visible head and gear parts use flat matte materials. The Scout retains its existing paint. Source body textures are embedded WebP at 1024² for LOD0 and 512² for LOD1; new head and gear parts use solid materials.

## Phone budgets

All 14 staged GLBs total **9,390,296 bytes** (9.39 MB decimal), below the 12 MB pack allowance. LOD0 stays below 15,000 triangles and LOD1 below 2,500. The existing rig animations were retained for the eight soldier actions used for this stage: `idle`, `gunIdle`, `run`, `shoot`, `hit`, `death`, `aim`, and `walk`. Less relevant Trooper clips were removed to meet the phone pack size; any future swap needing those clips must restore them or accept the game loader's idle fallback.

| Class | LOD0 tris | LOD0 bytes | LOD1 tris | LOD1 bytes |
| --- | ---: | ---: | ---: | ---: |
| Sniper | 5,908 | 887,344 | 2,333 | 485,672 |
| Heavy | 6,292 | 906,436 | 2,340 | 464,436 |
| Tech | 6,092 | 900,920 | 2,396 | 470,368 |
| Officer | 5,652 | 880,612 | 2,281 | 484,012 |
| Medic | 5,660 | 882,072 | 2,289 | 486,280 |
| Droid | 5,896 | 895,580 | 2,349 | 486,824 |
| Scout | 4,925 | 763,228 | 1,969 | 396,512 |

The [idle/run/shoot pose sheet](/home/jess/projects/tw-logs/w19/art/w19-pose-review.jpg) shows all six new attachments following the correct bone in each pose. The heavy shoulders remain below the helmet, and the cloak, satchel, harness, cape, and plating stay with the torso or pelvis. No floating pack or head clipping was visible in these three reviewed poses. The source Trooper idle animation itself holds one leg forward; this is present in the W17 source, not caused by W19 attachments.

## Saved Meshy prompts

The exact submitted prompt files are [Sniper](/home/jess/projects/tw-logs/w19/art/sniper-prompt.txt), [Heavy](/home/jess/projects/tw-logs/w19/art/heavy-prompt.txt), [Tech](/home/jess/projects/tw-logs/w19/art/tech-prompt.txt), [Officer](/home/jess/projects/tw-logs/w19/art/officer-prompt.txt), [Medic](/home/jess/projects/tw-logs/w19/art/medic-prompt.txt), and [Droid](/home/jess/projects/tw-logs/w19/art/droid-prompt.txt). Task IDs and preview GLBs/thumbnails are saved alongside them in `/home/jess/projects/tw-logs/w19/art/`.

## Validation

Godot 4.7.2 headless import exited 0 after staging, with no `SCRIPT ERROR`, `ERROR:`, or parse error in [final-import.log](/home/jess/projects/tw-logs/w19/art/final-import.log). The final `./godot/test.sh` run exited 0. Its [full log](/home/jess/projects/tw-logs/w19/art/full-test-final.log) has zero `SCRIPT ERROR`, parse-error, or nonzero-failure lines; every reported suite has zero failures. Main results: 368 checks, Normal rescue **9/20**; W17 wire 139 checks; Core17 272; Phone17 663. The first attached test run was interrupted by signal 143 after the rescue section, so the detached clean run is the gate record. The two requested JPGs are saved under `/home/jess/projects/tw-logs/w19/`.
