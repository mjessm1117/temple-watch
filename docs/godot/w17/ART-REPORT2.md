# W17 Tech, Droid and Officer art report

## Credit ledger

Five previews × 20, three refines × 10 and three rigs × 5 = **145/150 credits**. The balance moved from 14,175 to 14,030. Every call was logged before submission in `art/w17-2/ledger.json`; no drone or Sniper redo was purchased. No `SNIPER-REDO-MESHY` or `SNIPER-REDO-BLENDER` marker was present.

| Class | Previews | Selected | Refine task | Rig task | Spent |
|---|---|---|---|---|---:|
| Tech | A `01a1af5a-d51d-7474-82ec-3d80654b1faa`; B `01a1af5a-df25-73a9-b0cb-51e397b4f2ee` | A | `01a1af5d-c7d8-76de-a3d8-d48c48131725` | `01a1af60-1da4-730d-b610-bfc801a2acbd` | 55 |
| Droid | A `01a1af5a-ec4b-7159-9cbb-2f154d45bc0a`; B `01a1af5a-f964-759a-8455-dd115eb498cd` | B | `01a1af5d-d107-7682-8fe0-3aa8598f6675` | `01a1af60-2bdd-7372-8cc0-1582aad20ee7` | 55 |
| Officer | A `01a1af5b-088d-730d-b449-b6a25af5b85f` | A | `01a1af5d-dae9-77e1-bd02-b2ac2484d09b` | `01a1af60-706d-7477-8f2b-83873fe5ccbc` | 35 |

## Decisions and critique

The briefs reference the staged allied trooper/scout and lane 1 contact sheet. Untextured preview scores are in `art/w17-2/scores.json`. Tech A won for its compact engineer form; Tech B's tool looked detached. Droid B won for its mechanical joints and raised shoulder, while A looked like a human soldier. Officer had one preview within budget. The refined Tech and Droid textures were orange and mottled at 844×390, so their body polygons now carry broad matte tan, cream and deep blue materials. This sacrifices small texture detail but restores phone-scale clarity. Officer's texture was already clean enough.

| Class | Full triangles | Low triangles | Texture | Honest read at Low battle distance |
|---|---:|---:|---|---|
| Tech | 12,592 | 1,879 | 1024² embedded WebP; body uses flat material panels | Medium armored engineer, visible compact carbine and tool/battery pack. Wrist screen and hand tools are visible close up but tiny in battle. The helmet is plain. |
| Droid | 12,629 | 1,877 | 1024² embedded WebP; body uses flat material panels | Humanoid ally with shoulder module socket and dark visor. The uniform palette makes it resemble Tech at battle distance; the socket and visor carry the distinction. |
| Officer | 12,493 | 1,835 | 1024² embedded WebP | Lighter armor, sash, short cape, comlink and pistol distinguish a commander. Meshy omitted the sash/cape; local geometry provides them. Cape is rigid and should be evaluated before gameplay wiring. |

The small gold Jedi emblem does not resolve at battle distance on any new class. Meshy omitted all three weapons; local geometry supplies them. All weapons are children of `hand_r` with measured grip offsets, and follow the hand in idle, run and shoot. Shoot captures show the barrels raised close to vertical due to the shared retargeted pose, especially Tech and Droid. Aim direction needs an animation pass before game integration. The Droid visor is attached to `Head`; the module socket follows the left clavicle. The pack, sash and cape follow the spine.

## Lane 1 free fix

Sniper's rifle and Heavy's repeater were reparented from the spine to `hand_r` in both full and Low files. The Heavy repeater was scaled to 70% around its grip. Their LOD triangle counts stay 1,913 and 2,281; triangle counts do not change under a transform. The lane 1 contact sheet and battle views were reshot. Sniper texture was left alone because no conditional redo marker existed.

## Verification

- Final headless import after binary GLB repack: exit 0, zero `SCRIPT ERROR` and `ERROR:` lines; all ten files have the `glTF` binary header.
- Isolated animation smoke after binary repack: 10 GLBs × idle/run/shoot/hit/death = 50 successful checks; 29 clips in each GLB.
- The contact sheet `docs/godot/shots/w17-art-classes2.png` includes all seven front and 3/4 portraits and three 844×390 Low battle views. The five shoot poses were captured and inspected.
- Full `./godot/test.sh`: exit 0; zero `SCRIPT ERROR`, zero failures; Normal rescue 9/20.
- `git diff --check`: clean. Test-run Wave 16 screenshot side effects were restored.

All models remain staged in `godot/assets/units/w17/`. No roster, armory or battle wiring was changed.

## Fix 3 — free local repaint and shoot aim

The `HEAVY-REPAINT` marker was present when the Heavy repaint step ran. No Meshy calls or credits were used. Flat matte material regions replaced the mottled body texture on both Full and Low Sniper and Heavy models; their armor now uses broad cream and tan plates over deep navy cloth. Officer's near-black bodysuit and leg undersuit became deep navy, and its large yellow-gold armor regions became warm tan and cream. The blue sash and small accessory trim remain. Tech and Droid body palettes were unchanged.

| Class | Before | After at `shoot` frame |
|---|---|---|
| Sniper | Camo-blotch body; rifle barrel about 86° above level | Flat cream/tan/navy body; rifle about 5° below level |
| Heavy | Mottled body; repeater about 80° above level | Flat cream/tan/navy body; repeater about 1° below level |
| Tech | Flat body; carbine about 86° above level | Body unchanged; carbine about 1° below level |
| Droid | Flat body; blaster about 83° above level | Body unchanged; blaster about 3° below level |
| Officer | Near-black undersuit and bright gold armor; pistol about 77° above level | Navy undersuit, tan/cream armor, sash intact; pistol about 1° below level |

The aim correction changes only the `hand_r` rotation keys in each `shoot` clip, for Full and Low. Idle and run clips retain their previous grip and orientation. The new five-class shoot contact sheet is `docs/godot/shots/w17-art3-shoot-poses.png`; `docs/godot/shots/w17-art-classes2.png` was reshot with all seven classes, front and three-quarter. The staged models remain outside game data. Full and Low triangle counts remain 12,570/1,913 Sniper, 13,072/2,281 Heavy, 12,592/1,879 Tech, 12,629/1,877 Droid and 12,493/1,835 Officer. Each GLB retains 29 animation clips. Painted body materials use no image texture; retained texture images are at most 1024².

Low models use broad helmet/shoulder, torso, cloth and boot color bands. Their existing simplified geometry gives those boundaries coarse edges in close-up portraits; the armor and navy cloth remain distinct at battle distance.

Final gate: binary repack and headless import exited 0; `./godot/test.sh` exited 0 with zero `SCRIPT ERROR` lines and zero failures, including Normal rescue 9/20. The isolated animation smoke passed 50/50 checks, and the Full/Low shoot aim check passed 10/10 barrels within 15° of forward level. `git diff --check` was clean. Wave 16 camera screenshots changed by the test runner were restored.

## Fix 4 — class accents and clean panels

No Meshy calls or credits were used. `art/w17-2/fix4.mjs` replaces height-band painting with dominant skin-bone assignment. Compact disconnected armor pieces receive one color across the whole island. This removes the horizontal saw-tooth cuts through the chest and arms visible after Fix 3. All five classes now use the same tan `[.59,.46,.31]`, cream `[.83,.77,.65]`, navy `[.045,.105,.19]` and steel `[.16,.22,.28]` base. Accents are matte with roughness 0.8 and metallic 0. Existing blue/gold accessory trim was changed to the class accent, leaving one accent family per model.

| Class | Before Fix 4 | After Fix 4 |
|---|---|---|
| Sniper | Jagged cream/tan chest bands; torso could read as exposed skin | Olive `[.30,.38,.20]` shoulders, tan chest plate over navy midsection; no cream material on the torso front |
| Heavy | Tan/cream horizontal bands; rocket tubes floated above the helmet in shoot | Burnt orange `[.70,.33,.10]` shoulders; backpack and tubes lowered on the `spine_03` attachment, with their top below the head end bone in shoot |
| Tech | Same palette as Droid at phone size | Teal `[.10,.45,.48]` shoulder panels and former trim; clean tan/cream/navy bone regions |
| Droid | Same palette as Tech at phone size | Signal yellow `[.80,.66,.15]` shoulder panels and module trim; clean tan/cream/navy bone regions |
| Officer | Broad tan/cream bands and blue sash | Crimson `[.55,.10,.12]` shoulders and sash/cape trim; navy undersuit retained |

Both Full and Low GLBs have matching panel assignments and accents. Body accent triangles are about 8–12% of the painted body, with accessory accents adding visible area. Triangle counts are unchanged: Full/Low 12,570/1,913 Sniper, 13,072/2,281 Heavy, 12,592/1,879 Tech, 12,629/1,877 Droid and 12,493/1,835 Officer. All 29 clips remain in each GLB. The Fix 3 hand-bound weapons and level shoot barrels remain intact.

Review images: `docs/godot/shots/w17-art4-classes.png` shows all seven soldiers front and three-quarter; `w17-art4-shoot.png` shows the five shoot frames; `w17-art4-small.png` compares all seven at 64 px portrait height. At that size, the five class accents remain distinct. The Heavy pack is seated against the upper back in the shoot portrait. The Officer's rigid cape, Sniper's flat chest silhouette and tiny emblems remain visual gaps; the new paint does not add geometry.

Final gate: headless import exited 0 with zero `SCRIPT ERROR` or `ERROR:` lines. The isolated Fix 3 aim test and Fix 4 accent/pack test passed all ten Full/Low models; Heavy pack top measured 1.371 versus head end 1.426–1.428 in shoot. `./godot/test.sh` exited 0 with zero script errors and zero failures; Normal rescue was 9/20. `git diff --check` was clean. Two Wave 16 camera screenshots changed by the test runner were restored.

## Fix 5 — paid Meshy retexture and armor read

Meshy balance: **14030 before → 13970 after; 60 credits spent of the 190-credit hard cap**. Five first retextures cost 10 each. The first Sniper result still read as bare limbs, so one permitted Sniper retry cost 10 more. The retry was also broad beige and omitted the requested olive accent; no other retries were submitted. The original first-result texture was retained for Sniper. Meshy task results are cached locally as ignored `art/w17-2/fix5-*-meshy.glb` files; `fix5-apply.mjs` can fetch them again from the task IDs in the committed `art/w17-2/fix5-ledger.json`.

| Class | Task ID | Credits | Exact prompt |
|---|---|---:|---|
| sniper | `01a1b18b-fe5a-760f-94a9-ea71613fdca7` | 10 | Star Wars Republic trooper armor, hard painted armor plates in warm tan and cream with worn edges, dark navy fabric undersuit visible at elbows knees neck and waist, olive shoulder pauldrons and helmet stripe, matte, hand-painted stylized game texture, no camouflage, no skin showing |
| heavy | `01a1b18e-6918-70f4-ba92-329c5cb6de96` | 10 | Star Wars Republic trooper armor, hard painted armor plates in warm tan and cream with worn edges, dark navy fabric undersuit visible at elbows knees neck and waist, burnt orange shoulder pauldrons and helmet stripe, matte, hand-painted stylized game texture, no camouflage, no skin showing |
| tech | `01a1b18f-d507-7537-aac3-89a7a347ae50` | 10 | Star Wars Republic trooper armor, hard painted armor plates in warm tan and cream with worn edges, dark navy fabric undersuit visible at elbows knees neck and waist, teal shoulder pauldrons and helmet stripe, matte, hand-painted stylized game texture, no camouflage, no skin showing |
| droid | `01a1b191-5f9e-74d2-a953-3ec9b1afb172` | 10 | Star Wars Republic battle droid plating, hard painted armor plates in warm tan and cream with worn edges, dark navy fabric undersuit visible at elbows knees neck and waist, signal yellow shoulder pauldrons and helmet stripe, matte, hand-painted stylized game texture, no camouflage, no skin showing |
| officer | `01a1b192-ea4a-77b2-8406-f2550b559dcf` | 10 | Star Wars Republic trooper armor, hard painted armor plates in warm tan and cream with worn edges, dark navy fabric undersuit visible at elbows knees neck and waist, crimson shoulder pauldrons and helmet stripe, matte, hand-painted stylized game texture, no camouflage, no skin showing |
| sniper retry | `01a1b19a-9982-711e-827a-93606c298dab` | 10 | Fully sealed Republic trooper, every arm and leg covered by opaque rigid ceramic armor plates, thick cream gauntlets and thigh guards, warm tan chest and shin plates, crisp dark seams and scraped pale edges, dark navy woven undersuit ONLY at elbow knee neck and waist gaps, bold olive shoulder pauldrons and helmet stripe, stylized hand-painted game texture, no exposed flesh, no beige fabric limbs, no camouflage or mottled pattern |

Meshy repacked its output geometry but kept every source UV coordinate. `fix5-apply.mjs` transfers the paid paint atlas to the original rigged Full mesh and its Low counterpart, normalizes its illumination to the shared matte tan/cream/navy palette, and embeds a 1024² PNG. It preserves the source skin, all 29 clips and the hand-bound weapons. Meshy alone did not create enough armor contrast on the limbs. `fix5-plates.mjs` adds small cream hard-plate faces with dark worn borders, weighted to the existing limb bones; `fix5-undersuit.mjs` paints the exposed arm mesh navy. These local additions make the cloth/plate boundary visible without changing the rig. The top of Tech's pack was lowered and the loose pack battery was attached to `spine_03`. Officer's rigid cape and diagonal sash slabs were removed because the sash stood above the helmet in shoot; crimson pauldrons retain its accent.

| Class | Final Full/Low triangles | Result at battle distance | Remaining gap |
|---|---:|---|---|
| Sniper | 12,602 / 1,945 | Olive shoulders, pale arm and thigh shells, navy joints; level rifle | Chest silhouette still plain; painted wear is subtle at 64 px. |
| Heavy | 13,104 / 2,313 | Burnt-orange shoulders, plated limbs, seated pack; level repeater | Arm plates are blocky close up. |
| Tech | 12,624 / 1,905 | Teal shoulders, plated limbs, pack on spine below the head in shoot | Pack is rigid. |
| Droid | 12,661 / 1,909 | Yellow shoulders/module, dark suit and cream shell plates | Shares a humanoid silhouette with Tech. |
| Officer | 12,525 / 1,867 | Crimson shoulders, plated limbs, no back slab in shoot | Cape and sash are absent; the command silhouette is simpler. |

The five new accents are distinct in `w17-art5-small.png` at 64 px. `w17-art5-classes.png` compares all seven soldiers front and three-quarter; `w17-art5-shoot.png` shows the five shoot poses. The added face count is 26–32 triangles per GLB, within the ±5% limit. The arm undersuit pass repartitions existing triangles without adding any. The plate borders are visibly angular in close-up because these remain phone-scale models.

Final gate: headless import and `./godot/test.sh` exited 0, with zero `SCRIPT ERROR`, `ERROR:` or nonzero failure lines. Normal rescue was 9/20. The isolated Fix 4 aim/pack test passed all ten Full/Low models; shoot barrel elevations were within 5.4° of level. Heavy pack top measured 1.371 below head end 1.424–1.426; Tech pack top measured 1.243 below head end 1.286. `git diff --check` was clean. Two Wave 16 camera screenshots changed by the test runner were restored.

## Fix 6 — Trooper body and original armor texture

No Meshy API call or credit was used. All five classes now copy the battle Trooper body from `godot/assets/models/units/trooper.glb`, its skin and its 29 animation clips. Body paint replaces red pixels on the Trooper texture's existing armor UV islands and paints a narrow helmet stripe on the original helmet UVs. Each class atlas is embedded as a lossless 1024×1024 PNG, preserving decoded source pixels outside those accent zones, including the white shell, black undersuit, and texture shading. The copied material is matte (roughness 0.8, metallic 0). Fix 4 contributes only hand weapons and the Heavy/Tech spine packs. No Fix 5 body, texture, plate, or undersuit code is used; there are no floating plates. LOD1 decimates the Trooper body while retaining its UVs and class texture.

Source audit: 4,925 triangles; one material, `BakedMaterial.003`; one embedded 1024×1024 WebP base-color texture, `texture_0`; 66 skin bones; 29 clips. Bone names: `pelvis`, `spine_01`, `spine_02`, `spine_03`, `clavicle_l`, `upperarm_l`, `lowerarm_l`, `hand_l`, `LeftHandIndex1`, `LeftHandIndex2`, `LeftHandIndex3`, `LeftHandIndex4`, `LeftHandMiddle1`, `LeftHandMiddle2`, `LeftHandMiddle3`, `LeftHandMiddle4`, `LeftHandPinky1`, `LeftHandPinky2`, `LeftHandPinky3`, `LeftHandPinky4`, `LeftHandRing1`, `LeftHandRing2`, `LeftHandRing3`, `LeftHandRing4`, `LeftHandThumb1`, `LeftHandThumb2`, `LeftHandThumb3`, `LeftHandThumb4`, `clavicle_r`, `upperarm_r`, `lowerarm_r`, `hand_r`, `RightHandIndex1`, `RightHandIndex2`, `RightHandIndex3`, `RightHandIndex4`, `RightHandMiddle1`, `RightHandMiddle2`, `RightHandMiddle3`, `RightHandMiddle4`, `RightHandPinky1`, `RightHandPinky2`, `RightHandPinky3`, `RightHandPinky4`, `RightHandRing1`, `RightHandRing2`, `RightHandRing3`, `RightHandRing4`, `RightHandThumb1`, `RightHandThumb2`, `RightHandThumb3`, `RightHandThumb4`, `neck_01`, `Head`, `headfront`, `HeadTop_End`, `thigh_l`, `calf_l`, `foot_l`, `ball_l`, `LeftToe_End`, `thigh_r`, `calf_r`, `foot_r`, `ball_r`, `RightToe_End`. The rig retains `hand_r` and `spine_03`; its head end is `HeadTop_End` instead of Fix 4's `head_end`. All 29 expected clip names, including `idle`, `run`, `aim`, and `shoot`, already exist; no clip mapping gap remains.

The separate `godot/assets/loadout/models/trooper.glb` is 10,305 triangles. The armory's `loadout_actor.gd` loads from `assets/loadout/models/`, selecting its Trooper for default non-Jedi classes, its Heavy for Heavy, and its Scout for Sniper. These staged W17 files do not alter that selection.

| Class | Matte accent RGB | Fix 4 gear transferred | LOD0 / LOD1 triangles |
|---|---|---|---:|
| Sniper | Olive `[.30,.38,.20]` | Precision rifle and scope | 5,129 / 2,272 |
| Heavy | Burnt orange `[.70,.33,.10]` | Rotary repeater and rocket backpack/tubes on `spine_03` | 5,561 / 2,704 |
| Tech | Teal `[.10,.45,.48]` | Carbine and battery backpack on `spine_03` | 5,037 / 2,180 |
| Droid | Signal yellow `[.80,.66,.15]` | Droid blaster | 4,977 / 2,120 |
| Officer | Crimson `[.55,.10,.12]` | Pistol; no cape or back slab | 4,977 / 2,120 |

Remaining gaps: the Droid deliberately shares the Trooper humanoid silhouette; its color and blaster carry the distinction. The W17 files remain staged and are not wired into the roster or armory. The rigid packs do not deform with the torso.

Review sheets: `docs/godot/shots/w17-art6-classes.png` (seven soldiers, front and three-quarter), `w17-art6-shoot.png` (five shoot poses), and `w17-art6-small.png` (seven soldiers at 64 px). All ten Full/Low models passed the isolated accent, aim and pack assertions. The largest measured barrel elevation was 2.09°; Heavy pack top was 1.285 below `HeadTop_End` 1.610, and Tech pack top was 1.525 below `HeadTop_End` 1.610 in the shoot pose. The final headless import exited 0 with no script errors.

Final gate: `./godot/test.sh` exited 0 with zero `SCRIPT ERROR` lines and zero failures across all suites; its main `run.gd` segment reported 368 checks and Normal rescue 9/20. `git diff --check` was clean. Two Wave 16 camera screenshots changed by the test runner were restored.

## Fix 7 — phone GLB size

No Meshy call or credit was used. The Fix 6 atlas is now embedded as `EXT_texture_webp` at quality 90: 1024×1024 for LOD0 and 512×512 for LOD1. The generator also removes animation channels whose values equal the node's bind pose and compacts the unreferenced accessor data. These channels had no effect on the pose. Mesh triangles, skin, the 29 named clips, hand weapons, spine packs, material settings, and accent zones remain the same. The gear brings no additional image textures.

| File | Before (bytes) | After (bytes) | Texture format |
|---|---:|---:|---|
| `sniper.glb` | 6,232,500 | 1,345,872 | WebP |
| `sniper_lod1.glb` | 5,954,988 | 907,360 | WebP |
| `heavy.glb` | 6,269,120 | 1,355,500 | WebP |
| `heavy_lod1.glb` | 5,991,656 | 914,836 | WebP |
| `tech.glb` | 6,230,740 | 1,344,472 | WebP |
| `tech_lod1.glb` | 5,953,432 | 903,672 | WebP |
| `droid.glb` | 6,223,876 | 1,341,180 | WebP |
| `droid_lod1.glb` | 5,946,548 | 900,112 | WebP |
| `officer.glb` | 6,215,376 | 1,337,376 | WebP |
| `officer_lod1.glb` | 5,938,040 | 899,288 | WebP |

The three `w17-art6-*.png` review sheets were recaptured at the original camera settings. Mean absolute RGB difference from Fix 6 is 0.056 for classes, 0.043 for shoot, and 0.032 for small on a 0–255 scale; they retain the approved review appearance. Godot 4.7.2 headless import exited 0 with no import error.

The direct `w17_art4_test` passed all ten Full/Low models after the size change, including accent, aim, and pack placement assertions.

Final gate: `./godot/test.sh` exited 0 with zero `SCRIPT ERROR` lines and zero failures; Normal rescue was 9/20. `git diff --check` was clean. Two Wave 16 camera screenshots changed by the test runner were restored.

## Fix 8 — original low-poly weapons and packs

Blender 5.2 generated five class weapons and two spine packs from beveled primitives. They replace the transferred 6798e64 gear; the Trooper body, UVs, class texture bytes, skin and all 29 clips are unchanged. Each piece uses matte gunmetal, lighter metal edges, a single small stripe matching the Fix 6 RGB, and limited emitter/indicator light. `fix6.mjs` generates the gear via `fix8_gear.py`, binds the weapon parts to `hand_r` and the two packs to `spine_03`; `fix7-compact.py` repacks the result. No Meshy API call or credit was used.

| Piece | LOD0 tris | LOD1 tris |
|---|---:|---:|
| Sniper long rifle, scope, folded bipod | 552 | 228 |
| Heavy repeater, shroud vents, box magazine, carry handle | 532 | 204 |
| Heavy twin rocket pack, frame and straps | 312 | 168 |
| Tech carbine, tool emitter | 376 | 144 |
| Tech cell pack, indicator and cable loop | 224 | 176 |
| Droid coil blaster | 500 | 172 |
| Officer long-barrel pistol | 296 | 144 |

| Class | Unit LOD0 / LOD1 tris | LOD0 GLB bytes | LOD1 GLB bytes |
|---|---:|---:|---:|
| Sniper | 5,477 / 2,296 | 1,274,496 | 909,744 |
| Heavy | 5,769 / 2,440 | 1,286,220 | 916,896 |
| Tech | 5,525 / 2,388 | 1,281,728 | 916,312 |
| Droid | 5,425 / 2,240 | 1,271,508 | 906,668 |
| Officer | 5,221 / 2,212 | 1,263,360 | 905,356 |

`w17-art8-weapons.png` compares the seven old pieces above the new ones. `w17-art8-classes.png` retains the Fix 6 front and three-quarter framing; `w17-art8-shoot.png` shows the five firing poses; `w17-art8-small.png` shows all seven soldiers at 64 px. The direct Full/Low aim and pack check passed all ten models. Largest measured barrel elevation: 11.19° (Tech LOD0). Heavy pack top: 1.533 below head end 1.610; Tech pack top: 1.428 below head end 1.611. The body attribute and texture bytes match Fix 7 across all ten LOD0/LOD1 files. LOD0 animation sampler data hashes also match exactly; all files retain 29 clips.

Remaining gaps: the Droid still shares the Trooper body silhouette. The Tech pack cable is a short molded loop toward the weapon side, so it does not stretch with the animated hand. W17 assets remain staged for later armory/battle wiring.

Final gate: headless import exited 0; the direct `w17_art4_test` passed all ten Full/Low models; the full `./godot/test.sh` retry exited 0 with zero `SCRIPT ERROR` lines, zero failures, 368 main checks, and Normal rescue 9/20. The first full attempt hit a transient phone HUD position assertion in `battle13_test`; that suite passed 69/69 both in isolation and in the full retry. `git diff --check` was clean. Two Wave 16 camera screenshots changed by the runner were restored.
