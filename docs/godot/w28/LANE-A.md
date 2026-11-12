# W28 Lane A — Jedi tier promises (worktree tw-w28/jedi, branch w28/jedi)

Read docs/godot/w28/COMMON.md first and follow it exactly. Prefix `w28a_`.

## Lease
godot/data/classes/ranks.json, godot/data/campaign/core.json, godot/scripts/campaign/progression.gd, godot/scripts/campaign/battle_bridge.gd, godot/scripts/campaign/gear.gd, godot/scripts/combat_loadout.gd, new godot/tests/jedi_tiers28_test.gd, new w28a_* helpers.

## Goal
A Jedi promotion must change what the Jedi does, at the rank the game promises.
1. Rank 3 (Knight) grants the declared second Focus pip in battle and unlocks saber-form equip. Ranks 1–2 cannot equip advanced forms; the equip screen says why.
2. Keep intact: Master aura plus once-per-mission third action (rank 4–5), Council aura ×2 (rank 6–7), only one Grand Master (rank 8).
3. Padawan wording: the W17 design says strike/Deflect, but the game runs strike/guard. Test what guard actually does. If it fails the intended deflect effect (blaster bolts turned aside), fix the behavior. Otherwise fix the wording so the label matches the effect.

## Test
jedi_tiers28_test.gd: rank 2→3 gains the Focus pip in a live battle and can equip a form; rank 2 can't. Rank 4→5 Master effects fire, rank 6→7 Council multiplier applies, and a second rank-8 promotion is refused. Padawan guard/deflect matches its label.
