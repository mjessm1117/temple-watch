# W28 Lane C — Full Armory class tree (worktree tw-w28/tree, branch w28/tree)

Read docs/godot/w28/COMMON.md first and follow it exactly. Prefix `w28c_`.

## Lease
godot/scripts/campaign/loadout_skill_tree.gd, new godot/tests/class_tree28_test.gd, new w28c_* helpers (split here if the tree file nears 600 lines).

## Goal
The Armory hides ranks 4–8 behind a placeholder. Show the whole build so the player can plan it, like XCOM 2's soldier promotion tree (refs tw-reference/, private).
1. Data-driven rows through soldier rank 7 and Jedi rank 8, using `Classes.ability_catalog()` and `Progression.tree_options()`. No hard-coded ability lists.
2. Each row shows tier name (Padawan/Knight/Master… for Jedi), branch, current pick, lock reason ("Reach Knight"), a one-line ability description, and its chain tags as small chips. Tolerate missing optional tags.
3. Phone first: fits 390x844 and 844x390, scrolls smoothly on touch (vertical drag that starts on a card must still scroll), tap targets ≥44 px. Promotion choice rules stay in progression.gd (lane A); you only render them.

## Test
class_tree28_test.gd at a phone viewport: a rank-1 recruit sees rank 1 open and later ranks locked with reasons. A high-rank soldier sees the picks it has made. A rank-8 Jedi sees all 8 tiers with the Jedi tier names. No placeholder text, every row ≥44 px, and the scroll container moves on a drag that starts on a row.
