# W20 lane B — squad loadout + skill tree to tier 3 (lane name: loadout)
Read COMMON.md first. Worktree ../tw-w20/loadout.
## Jess wants
"Equip your soldiers as well as equip their skills up to level 3 of the skill tree. There should be noticeable differentiation and benefits. The skill tree and how this works is key."
His shot of the SKILLS tab (jess-shots/): a greyed R1/R2 list, "Next choices unlock when this soldier earns a rank". He can't pick anything, there is no tree, and he sees no benefit. Also: Kira is hidden behind the SELECTED card, the Jedi weapon card says "Military blaster" with a saber icon, and EVOLUTION/PATH show placeholder blob icons.
## Do
1. **Squad loadout is the pre-mission hub, including before mission 1.** It shows the full squad as a lineup with portraits/models. Tap a unit to open its loadout, with two tabs: GEAR and SKILLS. DEPLOY must be visible and never clipped.
2. **Skill tree screen (the key piece), XCOM style.**
   - A visible tree with columns = ranks 1, 2, 3 (show ranks 4+ locked and greyed beyond).
   - Paired choices per rank are side by side.
   - Each node shows icon, name, a one-line plain effect, and BIG numbers. Every choice shows what it changes in battle in concrete terms (damage, hit %, range, cooldown, heals, buffs) and a "vs other choice" comparison.
   - Chains/combos are shown as links to other skills or squadmates.
   - Tap a node to select it, tap again (or Confirm) to lock it in.
3. **Starting squad gets tiers 1–3 now.** New campaigns start each unit with enough rank to pick tiers 1, 2 AND 3 (rank 3 specialization) before mission 1. Picks can be changed freely until the first deploy, then they lock.
   - Keep Normal rescue 9–11/20. If balance moves, tune enemy or squad numbers in your lease until it holds.
4. **Noticeable differences.**
   - Audit each class's rank 1–3 choices. Where two paired choices differ by less than ~20% in their main number, or read as the same thing, rework one so each pick has a distinct role and an obvious benefit. Example flagged: Sage sage_lift 68% vs sage_insight_mark 70%.
   - Write the before/after table to tw-logs/w20/loadout/2026-11-10-skill-diff.md.
5. **Gear.** Every slot shows the item picture and its stat deltas (+HP, +aim, +dmg) when you swap. Fix the Jedi weapon card (sabers for Jedi), the placeholder icons, and the model hidden behind the SELECTED card. Gear and skill effects must carry into battle (verify via battle_bridge).
6. Layout must work at 956x440@3, 844x390 and 1366x768, with smooth iPhone touch scrolling.
## File lease
- squad.tscn, campaign/squad.gd, campaign/loadout_*.gd, campaign/armory*.gd
- campaign/promotion_screen.gd, campaign/progression.gd, campaign/gear.gd, campaign/battle_bridge.gd, campaign/state.gd (starting roster only)
- scripts/class_registry.gd, data/classes/**, data/abilities.json, data/campaign/core.json, data/campaign/gear.json
- new tests/loadout20_test.gd
## Tests (loadout20)
- A fresh campaign squad can pick tiers 1–3 for every unit.
- The picked skill is present in battle state.
- Gear swap changes battle stats.
- Every rank 1–3 pair differs by >= 20% in its main number OR has a different effect type, listed in a table.
- No placeholder icon IDs.
- Jedi weapon slots never show blasters.
- The tree fits at 956x440 with no clipped nodes.

Sheet: squad lineup, GEAR tab, skill tree with a selection, the comparison close-up.
