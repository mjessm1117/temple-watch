# Wave 11 — CAMPAIGN LAYER lane
Read docs/godot/wave11/COMMON.md first; its rules apply.

## Goal
Between-mission decisions matter: Temple upgrades change battles, and the galaxy throws events and crises at the player.

## Requirements
1. Temple upgrades with real battle effects: audit every Temple room/upgrade in data/campaign/temple.json. Each must have a concrete, visible effect (e.g. Training Hall +aim for rookies, Med Bay faster recovery + 1 medpac in battle, Archives +1 intel/briefing reveal of enemy types, Forge discount, Watchtower early warning = see reinforcement direction 1 turn earlier). Effects show on the room plate AND on the pre-mission loadout/briefing ("Temple bonuses active: ..."). Remove or merge any upgrade with no effect.
2. Galaxy events: a deck of 15+ events firing between missions (every ~2-3 missions), each a short card with 2-3 choices and costs/rewards (resources, a planet's threat, a Jedi wounded/bonus, a mission modifier). Events depend on era and planet state.
3. Crises: 3 multi-step crises (e.g. a planet about to fall, a supply blockade, a traitor in the Temple) that open with a deadline in days, show on the galaxy map, and resolve as win or loss with lasting effects.
4. A "This month" summary card after each mission: what changed (resources, threat, events pending, crisis deadlines).
5. Keep existing Temple home polish (plates, tab icons, badges, red POWER) and galaxy features.

## File lease (only these)
godot/scripts/campaign/temple.gd, temple_rooms.gd, temple_view.gd, strat_base.gd, strat_ops.gd, strat_council.gd, strat_ui.gd, galaxy.gd, galaxy_map.gd, galaxy_details.gd, galaxy_intel.gd, home_badges.gd, battle_bridge.gd, loadout_details.gd, new files godot/scripts/campaign/events11_*.gd and crisis11_*.gd, godot/data/campaign/temple.json, galaxy.json, new godot/data/campaign/events11.json, godot/tests/campaign11_test.gd, godot/test.sh (suite line only), docs/godot/shots/wave11-campaign-*.png.
state.gd (528 lines): hook/save-key lines only, must stay <600. Do NOT edit story/*, campaign_bridge.gd, sith_*, mission*, hud_*.

## Tests (campaign11_test.gd)
Every temple upgrade has a non-zero effect that reaches battle setup; event deck fires at the intended cadence; crises tick down and resolve both ways; save/load round-trips events and crises.
