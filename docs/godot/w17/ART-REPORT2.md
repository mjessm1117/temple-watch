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
