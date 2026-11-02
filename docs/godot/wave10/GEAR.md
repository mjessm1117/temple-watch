# Wave 10 lane C — gear Mk I→III + research tree (Jess approved 2026-11-02)

## Goal
1. **Gear ladder:** every weapon, armor and lightsaber line has Mk I → Mk II → Mk III. Higher marks unlock through research and cost resources at the Forge. Upgrading shows a clear before/after (aim, damage, HP, armor, slots). Enemies scale up across the campaign so Mk III feels earned, not mandatory.
2. **Research tree (~35 projects):** a readable tree screen in the Temple (Archives room): branches (e.g. Forge/arms, Armor, Force studies, Saber forms, Intel/ops, Medical), prerequisite lines, days + cost, one active project, a queue, and an "unlocked" toast. Finishing a project changes something the player can see (new gear mark, ability, room upgrade, intel).

## Context — audit first
Much exists already. Read and list in REPORT.md what exists vs what the player can actually see/use today:
- godot/data/campaign/research.json (36 RESEARCH, RES_TREE, TREES), gear.json (WEAPONS, ARMOR, SABERS, MODS, MK_RES, MK_COST, MK_N, EVO)
- godot/scripts/campaign/gear.gd, progression.gd, loadout_*.gd, strat_base.gd, temple_rooms.gd, temple_view.gd
- docs/godot/wave7/strategy-REPORT.md, docs/XCOM2-STUDY.md (WotC tech tree + proving ground pacing)
- Old web game public/js/data-campaign.js, base.js (read only)
Reuse existing projects/marks; fill gaps and make it visible. XCOM mechanics only, no copyrighted assets or text.

## Requirements
- Data-driven in gear.json / research.json. ~35 projects total, every one with a visible payoff, no dead ends, every gear Mk reachable.
- Pacing: Mk II reachable around mid-campaign, Mk III late; document the day/cost curve in the report.
- Research screen + Forge upgrade UI fit the existing Temple style (desktop 1366×768 first).
- Save/load + old-save migration.
- Balance: Normal rescue bot stays 9–11/20; campaign-test families stay in their current bands. If Mk III makes late missions trivial, scale enemies, don't nerf the ladder.

## Verification
- New suite godot/tests/gear_research_test.gd (registered in godot/test.sh): every project completes, prerequisites hold, every Mk unlock applies stats, save/load, migration.
- `./godot/test.sh` exit 0, 0 SCRIPT ERROR, all suites 0 failures, Normal 10/20 ±1.
- Screenshots docs/godot/shots/wave10-gear-*.png: research tree, a project finishing, Forge upgrade before/after, loadout with Mk III gear.
- docs/godot/wave10/GEAR-REPORT.md: audit table, project list by branch, pacing table, balance numbers.
- Commit on branch wave10/gear. Don't push. Files < 600 lines.

## File lease
May write: godot/data/campaign/gear.json, research.json, godot/scripts/campaign/gear.gd, progression.gd, loadout_*.gd, temple_rooms.gd, temple_view.gd, strat_base.gd, strat_ops.gd, new godot/scripts/campaign/research_*.gd / forge_*.gd, godot/data/units.json + difficulty.json (enemy scaling only), godot/tests/gear_research_test.gd, docs/godot/wave10/GEAR*, docs/godot/shots/wave10-gear-*.png.
Shared files (another lane edits them too — keep each change a small hook inside a block marked `# --- wave10 gear ---`): godot/scripts/campaign/state.gd, strat_ui.gd, battle_bridge.gd, godot/scripts/game.gd, godot/test.sh.
Do NOT touch: godot/scripts/story/**, godot/data/story/**, legacy.json, legacy.gd, combat_bonds.gd, props.json, art/, assets/maps/, public/, functions/, tests/ (web).
