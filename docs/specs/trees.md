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

## Power (2026-10-16, "scale with level and power level")
| Thing | Rule |
|---|---|
| Skill power I–IV | Every tree/borrowed skill starts at **I**, +1 level every 2 ranks after it's learned (max **III**). The spec's signature skill gets +1 (max **IV**). |
| Per level above I | +1 damage on enemies, +1 healing, +5% hit chance on ability targets (cap 95%). Shown as a roman badge on battle buttons and in the tree; odds panel shows a "Power" line. |
| Unit Power | Weighted sum, weights in `POWER_W` (data-trees.js): HP×2, (aim−50)×.5, avg dmg×3, armor×5, crit×.2, Focus×1.5, move×1, deflect×.2, range×1.5 (cap 12), medkit×3, grenade×3, skill power×2, active ability×4, spec +4. Shown on roster, Armory, squad select, tree screen. |
Engine: `public/js/power.js` wraps `odds`, `damage`, `exec`, `targetsFor`, `startPlayerTurn` (keep those names and signatures).

## Balance pass (2026-10-17)
Problem: R7 Guardian 152 vs R7 Soldier 108. About half the gap was the meter: it ignored range, medkits, grenades and active abilities, so troops and ability-heavy builds read low. Fixed the meter, then trimmed stats.
- Meter: added range, medkits, grenades, active abilities; Focus 2→1.5.
- Nerfs: Iron Body +2 HP → +1 HP +10 will; Unbreakable +3 HP → +2 HP (+1 armor); Master Blade +2 dmg/+10 crit → +1 dmg/+15 crit; Titan loses +1 armor; Fortress +2 armor → +1.
- Buffs: Commander +1 HP and +1 armor; Calm Hands +1 HP; Vessel of the Force +2 HP; Field Surgeon trait +1 medkit.
- Result: all 32 R7 builds (16 specs × 2 pick paths) land at 146–158 Power (median 151, ±5%). Before: 122–155 on the fixed meter. `tests/trees.test.js` fails if any build leaves ±8% of the median.
- Caveat: Power is a stat estimate, not a win rate. It can't see trait or ability strength in play. Bot games at R7 still win everything.

## Tree screen (ui-tree.js)
Open from the Roster (**Skill tree** button) or Armory (**Open full tree**). Top: core ranks 1–2. Below: the two specs side by side, each with its trait and ranks 3–7. Every node shows its icon, chips for what it unlocks (+2 HP, +10 Aim, New ability · 2 Focus), and its state: taken (lit), pick now (glowing gold, click it), locked (shows the XP needed), not taken (struck out), closed (other branch). Rank 3 asks for a confirm because it's permanent. Cross-training sits at the bottom.

## Spec traits (passive from rank 3)
| Spec | Trait | Effect |
|---|---|---|
| Protector | Shield Wall | Adjacent allies take −1 damage from enemy hits (min 1) |
| Weapon Master | Momentum | +1 damage per kill this mission (max +3) |
| Sage | Life Bond | Heals +1 HP and refund 1 Focus |
| Shadow | Mind's Edge | Force powers +1 damage, +2 vs stunned |
| Watchman | Judgment | +10 aim vs elites/bosses; kills restore 1 Focus |
| Blade Dancer | Flow | +1 move per kill this mission (max +2) |
| Beastwarden | Beast Lore | +15 aim, +2 damage vs creatures/horrors |
| Earthshaper | Bedrock | Force powers ignore armor |
| Sergeant | Steady Line | Self + allies within 3: +5 aim |
| Vanguard | Close Assault | +15 aim, +1 damage within 4 tiles |
| Sniper | Patience | +10 aim, +1 damage at 7+ tiles |
| Infiltrator | Opening Strike | First hit each mission +20 aim, +2 damage |
| Field Surgeon | Triage | Heals +2 HP; +1 medkit |
| Combat Tech | Field Repairs | Turn start: self + adjacent allies +1 HP |
| Demolitionist | Blast Radius | Grenade/Ion/Rocket +1 damage |
| Bulwark | Iron Wall | +1 armor; enemies −10 aim vs allies next to it |

## Icons
Each spec has its own icon (`sp_<spec>` in icons.js). Tree stat picks show an icon for their main stat (`st_hp st_armor st_aim st_crit st_dmg st_mob st_focus st_will st_range`); `st_power` marks unit Power.

## Cross-training rules
- Borrowable = the second class's trunk (ranks 1–2, 4 skills).
- Jedi borrowing troop skills can't take ones that need a blaster or medkits: Suppress, Rapid Fire, Deadeye, Long Shot, Eagle Eye, Bandolier, Revive Stim, Field Kit.
- Second class can be changed until the first skill is borrowed.

## Known limits / next
- Rank 4–7 picks are still mostly stat perks; depth comes from traits + power. Next: an R7 active capstone per spec.
- Balance: bot squads at R7 win everything (expected). Tune trait numbers after Jess plays a mid-rank campaign.
- No paid respec yet. Candidate: respec at the Training Salle for credits.
- Balance untested beyond the bot suite; R7 Jedi with a borrowed Hunker/Flak Vest may be strong. Watch Hard/Legend.
