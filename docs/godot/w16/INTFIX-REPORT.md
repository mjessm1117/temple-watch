# W16 integration fixes

| Item | Result | Evidence |
| --- | --- | --- |
| 1. Kill-cam | **PASS**. The victim stays in shot until the strike finishes. The blade is attached to `hand_r`, Kira plays `swing`, and the victim gets a hit flash/pose before the normal fall. The camera starts behind Kira's shoulder. Damage text appears after the close-up, so the stray `-1` is absent from its frames. All three frames show different poses. | [Phone strip](../../shots/w16-intfix-phone-low-kill-strip.png) · [desktop strip](../../shots/w16-intfix-desktop-high-kill-strip.png) |
| 2. Armor icons | **PASS**. Jedi armor tiles and large icons use the approved `meshy/` folder; trooper and other gear paths remain unchanged. | [Phone armory](../../shots/w16-intfix-phone-low-deploy-roster.png) · [desktop armory](../../shots/w16-intfix-desktop-high-armory-u1-mk3.png) |
| 3. Mk I redo | **PASS**. Free Blender procedural tan cloth tunic with a raised quilted chest pad and dark belt, rendered in the same transparent studio setup as Mk II/III at 256 and 128 px. | [Three-icon contact sheet](../../shots/w16-intfix-armor-mk1-mk2-mk3.png) |
| 4. Armory label | **PASS**. The equipped armor is the first detail card; the Mk III capture reads “Armored robes / Mk III” beside the matching equipped slot. | [Desktop detail](../../shots/w16-intfix-desktop-high-armory-u1-mk3.png) |
| 5. Phone portraits | **PASS**. Story and comms use a head-and-shoulders crop for all seven distinct Jedi. Faces occupy roughly 60% of the small portrait. | [Phone story](../../shots/w16-intfix-phone-low-story.png) · [seven faces at phone size](../../shots/w16-intfix-phone-jedi-portraits.png) |
| 6. Deploy roster | **PASS**. Jedi cards and swap rows use each named portrait; other soldiers retain their rendered actor portraits. | [Phone deployment](../../shots/w16-intfix-phone-low-deploy-roster.png) |
| 7. Desktop Temple | **PASS**. Room Jedi scale rises from 1.05 to 1.50; the view remains at 431 draws. | [Desktop Temple](../../shots/w16-intfix-desktop-high-temple.png) |
| 8. Phone tactical | **PASS**. The narrower phone tactical FOV makes the squad larger while preserving the tested HUD clearance after selection. The Low aim rim is brighter and wider; the overhead zoom-out still works. | [Tactical](../../shots/w16-intfix-phone-low-tactical.png) · [aim](../../shots/w16-intfix-phone-low-aim.png) · [overhead](../../shots/w16-intfix-phone-low-overhead.png) |
| 9. Battle motion | **PASS**. Three different run poses and three swing poses were captured in battle at 844×390; the hand-held saber changes position through the swing. | [Run strip](../../shots/w16-intfix-phone-low-run-strip.png) · [swing strip](../../shots/w16-intfix-phone-low-swing-strip.png) |

## Low render budget

| Screen | Before draws | After draws | Source |
| --- | ---: | ---: | --- |
| Phone battle tactical | 75 | 81 | W16 cam baseline → integration capture |
| Phone aim | 96 | 96 | W16 cam baseline → integration capture |
| Phone armory, Jedi | 113 | 117 | W16 armory baseline → integration capture |

The staged armor meshes remain at or below 2,880 triangles each, under the 3K prop cap. GLB accessor counts show each named Jedi at 3,000 triangles and each Low LOD at 1,400, under the 15K unit cap. The battle saber adds only two simple cylinders. All edited source files remain under 600 lines. Low counts are desktop Compatibility renderer measurements under Xvfb, not physical phone FPS measurements.

## Jungle

**SKIPPED**. Neither `JUNGLE-YES` nor `JUNGLE-LIGHTEN` exists in the W16 log folder. No jungle branch or prop change was applied.

## Ship gate

- Headless import: **PASS**, exit 0. [Log](INTFIX-import.log).
- Full tests: **PASS**, exit 0; 66 zero-failure result lines, 0 `SCRIPT ERROR`, 0 `ERROR:`, and Normal rescue **9/20**. The W16 suites include show 36/36, animation 329/329, camera Low 24/24 and Medium 13/13, and armory 155/155. [Log](INTFIX-test.log).
- `git diff --check`: **PASS**.
