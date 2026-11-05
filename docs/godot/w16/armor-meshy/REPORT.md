# W16 staged Meshy armor review

The [before/after sheet](../../shots/w16-armor-meshy-before-after.jpg) compares the current Blender icons, the staged icons, and large three-quarter renders. Nothing is wired into the game. The icons are 256 px with 128 px tile companions. All six GLBs are under their triangle limits; 1024 px textures for Mk II and III are embedded in the GLBs and Godot also extracted them into this lane's model folder.

| Piece | Meshy source and local work | Main tris | Low tris | Honest read |
|---|---|---:|---:|---|
| Mk I padded | Preview A; crop long robe and neck stump, matte tan cloth, dark belt coloring and projected stitch lines | 2,870 | 1,431 | Clear cloth silhouette and earthy color. The stitch lines suggest quilting, but a distinct padded chest panel is not legible. Needs another art pass before shipping. |
| Mk II plated | Refine A; crop generated neck stump | 2,880 | 1,440 | Steel chest and tan lower tabard read apart from Mk I. Shoulder silhouette is somewhat symmetric despite the single-pauldron prompt; bracer straps are subtle. |
| Mk III ornate | Refine A | 2,880 | 1,440 | Strong wide shoulders, deep blue and gold engraved chest. Best match to the brief. |

The Meshy account spent **100 lane credits** of the 120 hard cap. Mk I's first preview produced a full robe; its allowed retry produced a body and arms. Both failed the chest-only brief and were not refined. See [ledger.md](ledger.md) for task IDs and read-only balances. The initial account balance was 14,375; the final observed balance was 14,265, including a 10-credit change outside this lane's submitted tasks.

## Later icon wiring

In `godot/scripts/campaign/armory16_art.gd`, keep `ROOT` for existing assets and add `const MESHY_ROOT := "res://assets/ui/armory16/meshy/"`. In both `texture_for` and `tile_for`, use `MESHY_ROOT` only when `slot == "armor" and jedi`; the path suffixes remain `key + ".png"` and `"tiles/" + key + ".png"`. This switches the three Jedi armor icons and tiles without changing trooper or other gear paths. No code change has been applied.

These are display pieces, not fitted skeleton parts. `armory16_armor.gd` currently loads `res://assets/armor16/armor_mk%d_%s.glb`, searches named `Chest`/`Pauldron`/`Bracer`/`Greave` meshes, and overrides their material. Pointing that constant at these single-mesh GLBs would not display the armor correctly; a later fitted attachment pass is required for any in-world swap.

## Validation

Blender 5.2 exported all six GLBs and rendered the icons from the final staged models. Triangle counts above were remeasured by importing the exported GLBs. The final Godot headless import exited **0**; [import.log](import.log) contains no `SCRIPT ERROR` or `ERROR`. `./godot/test.sh` exited **0**; [test.log](test.log) has 62 reported zero-failure results and no `SCRIPT ERROR`, `ERROR:`, or nonzero-failure lines. `git diff --check` passed. The auto-generated import metadata and extracted textures are included beside the staged assets.
