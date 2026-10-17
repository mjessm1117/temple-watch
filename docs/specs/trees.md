# Skill Trees — branching specs + cross-training (Chat F · Skill Trees, 2026-10-16)

Data: `public/js/data-trees.js` (TREES, new PERKS, XTRAIN). Logic: `temple.js` (treeOpts, fixTree, cross-training). UI: Temple roster, Armory tree, debrief. Test: `tests/trees.test.js`.

## Decisions (Jess, 2026-10-16)
| Topic | Decision |
|---|---|
| Shape | Ranks 1–2 shared trunk (pick 1 of 2). **Rank 3 = choose 1 of 2 specializations** (permanent; its signature skill comes with it). Ranks 4–7 = pick 1 of 2 inside that spec. |
| Multiclass | **Cross-training.** Jedi can learn any class (incl. trooper skills). Troops cross-train only into other troop classes; troops can't use the Force. |
| Cost | **Free, gated by the Training Salle**: L1 → 1 borrowed skill from rank 4; L2 → a 2nd from rank 6. Borrowed skills come on top of normal picks. |
| Old saves | **Free respec**: trunk picks kept; anything past rank 2 that doesn't fit the new tree is dropped and re-picked. |

## Specializations
| Class | Spec A (signature) | Spec B (signature) |
|---|---|---|
| Guardian | Protector (Force Barrier) | Weapon Master (Saber Sweep) |
| Consular | Sage (Force Revive) | Shadow (Mind Trick) |
| Sentinel | Watchman (Executioner) | Blade Dancer (Saber Throw) |
| Wayseeker* | Beastwarden (Beast Calm) | Earthshaper (Force Pull) |
| Soldier | Sergeant (Rally) | Vanguard (Chain Shot) |
| Scout | Sniper (Spotter) | Infiltrator (Run & Gun) |
| Medic | Field Surgeon (Med Beacon) | Combat Tech (Shield Drone) |
| Heavy | Demolitionist (Rocket) | Bulwark (Hold the Line) |
*Wayseeker stays locked until Era 3.

Lore: Sage/Shadow and Vanguard are SWTOR advanced-class names [sourced, High]; Weapon Master and Watchman are KotOR II prestige classes [sourced, High]; the rest are invented [N].

## Cross-training rules
- Borrowable = the second class's trunk (ranks 1–2, 4 skills).
- Jedi borrowing troop skills can't take ones that need a blaster or medkits: Suppress, Rapid Fire, Deadeye, Long Shot, Eagle Eye, Bandolier, Revive Stim, Field Kit.
- Second class can be changed until the first skill is borrowed.

## Known limits / next
- Most rank 4–7 spec picks are stat perks (no new engine work). Next step: give each spec one new mechanic at rank 5 or 7 (needs engine work in `abilities.js`).
- No paid respec yet. Candidate: respec at the Training Salle for credits.
- Balance untested beyond the bot suite; R7 Jedi with a borrowed Hunker/Flak Vest may be strong. Watch Hard/Legend.
