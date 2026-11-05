# Wave 15 Jedi library report

Seven named Jedi have distinct textured Meshy meshes. Each animated GLB has the shared battle bone names and ten playable clip names; each folder also has a static 1,400-triangle Low LOD and preview. The original source motion curves from `tools/meshy/retarget.mjs` deformed Meshy's imported skin in Godot, so the final clips use compact motion authored on the correctly named Meshy skeleton. This limits motion fidelity, especially attacks, but keeps idle, movement, and attack readable in battle. The armory hero hook remains for the integrate step because its file is leased to the armory lane.

| Jedi | Phone distinct? | Main tris | GLB bytes | LOD tris | Credits | Visual cue |
|---|---|---:|---:|---:|---:|---|
| Kira | PASS | 3,000 | 365,532 | 1,400 | 35 | Amber tabard, wide indigo cape |
| Tor | PASS | 3,000 | 355,256 | 1,400 | 35 | Auburn hair, cream diagonal sash |
| Satele | PASS | 3,000 | 358,772 | 1,400 | 35 | Narrow navy and white robe |
| Ressa | PASS | 3,000 | 368,820 | 1,400 | 55 | Silver hair, gold plate and maroon |
| Kell | PASS | 3,000 | 350,100 | 1,400 | 55 | Short blue jacket and large satchel |
| Sava | PASS | 3,000 | 327,772 | 1,400 | 65 | White armor, blue stripe, topknot |
| Tem | PASS | 3,000 | 342,316 | 1,400 | 35 | Green skin and long green coat |

The prior slim Jedi unit is 4,925 triangles and 3,319,788 bytes. Each new main model stays below 5,910 triangles and 3,983,745 bytes. All seven main files have distinct MD5 hashes. The 844-pixel lineup was viewed at native size; all seven can be separated by silhouette and color. The first three were also viewed together in an actual 844×390 Low battle shot.

| Gate metric | Before | After | Delta / limit |
|---|---:|---:|---|
| Web `index.pck` bytes | 68,355,756 | 71,872,572 | +3,516,816 / +4,194,304 max |
| Low phone battle draw calls | 85 | 85 | +0 / +15% max |
| Low phone visible triangles | 111,929 | 94,265 | −17,664 |
| Desktop battle draw calls | 106 | 106 | +0 |
| Desktop visible triangles | 106,267 | 94,717 | −11,550 |

Meshy balance: **14,710 → 14,395**. Lane spend: **315/500**, leaving **185** credits under the cap. `CREDITS.md` lists every preview, refine, and rig attempt, including Sava's zero-cost 422 rejection.

Evidence: [full lineup](../../shots/wave15-jedi-lineup.png), [844-pixel lineup](../../shots/wave15-jedi-lineup-phone.png), [phone before](../../shots/wave15-jedi-before-phone.png), [phone after](../../shots/wave15-jedi-after-phone.png), [desktop before](../../shots/wave15-jedi-before-desktop.png), [desktop after](../../shots/wave15-jedi-after-desktop.png). All six images were inspected at native size. The phone and desktop battle captures contain Kira, Tor, and Satele.

Headless import: 0 script errors, 0 parse errors, 0 import errors. `jedi15_test.gd`: 147 checks, 0 failures. Exported Web PCK runtime: 16 checks, 0 failures, with all seven scenes loading from the PCK. Full `godot/test.sh`: exit 0 across 56 suites, 0 `SCRIPT ERROR`, 0 `ERROR:`, 0 suite failures; Normal rescue 9/20. `git diff --check`: 0 errors. The Web export reported 0 script, parse, or export errors.
