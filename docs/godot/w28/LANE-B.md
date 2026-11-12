# W28 Lane B — Soldier chain completion (worktree tw-w28/soldier, branch w28/soldier)

Read docs/godot/w28/COMMON.md first and follow it exactly. Prefix `w28b_`.

## Lease
godot/data/classes/soldier/trooper.json, godot/data/classes/soldier/scout.json, godot/data/classes/soldier/medic.json, godot/scripts/ability_chains.gd, godot/scripts/effects_soldier.gd, godot/scripts/abilities_engine.gd, new godot/tests/soldier_chains28_test.gd, new w28b_* helpers.

## Goal
Trooper, Scout and Medic have 26 ranked slots that reuse old abilities with no chain tags. Make every ranked pick a real, distinct choice that combos.
1. Audit all 26 repeated entries against W17's rule that no two ranked abilities share an effect signature. Replace or specialize each one that fails.
2. Keep 13 ranked choices per class, the existing branch intent, same-side blending, and the apply/consume chain-tag behavior.
3. Prefer declarative `chain`/`effects` data. Add a handler in effects_soldier.gd/abilities_engine.gd only when data can't express it.
4. Each class gets at least one cross-unit squad combo (one soldier applies a tag, another consumes it).
5. Don't touch Droid's modules.
Write a short table (old → new, the effect, its chain tags) to tw-logs/w28/soldier/CHANGES.md.

## Test
soldier_chains28_test.gd: the schema is valid, and ranked IDs and effect signatures are unique within each class. No ability chains with itself. One cross-unit combo fires in battle for each of Trooper, Scout and Medic. Droid's modules are unchanged.
