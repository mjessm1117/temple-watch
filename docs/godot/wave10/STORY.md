# Wave 10 lane B — story choices + bonds (Jess approved 2026-11-02)

## Goal
The player should feel the story and the squad's relationships in every campaign loop:
1. **Story choices at 4 moments:** mission briefing (pick an approach), mid-mission (one event with 2–3 options on some missions), debrief (how to handle the outcome), and Temple talks between missions (a short conversation with a Jedi or Council member). Each choice has a visible consequence: resources, Darkness, a bond change, a unit trait, or a later story beat that references it.
2. **Bonds you can see and grow:** pairs of Jedi build a bond by fighting near each other, saving each other, and through Temple talks. Bond levels 1–3 unlock battle perks (build on the existing Teamwork/Crossfire). Bonds show on the roster, in loadout and in battle (a line or icon between bonded units). A bonded partner dying or falling to the Dark matters (will loss, a story beat).

## Context — audit first
A lot already exists. Before building, read and list in REPORT.md what is already there and what the player actually sees today:
- godot/scripts/story/story_engine.gd + story_screen.gd, godot/data/story/* (story, saga, era2/3, temple-life, chains)
- godot/data/campaign/legacy.json (DRILLS, LEGACY bonds, BACKSTORY, SECRETS, VOICES, DEEDS), godot/scripts/campaign/legacy.gd, godot/scripts/combat_bonds.gd
- docs/godot/wave5/story-REPORT.md, docs/godot/wave7/combat-REPORT.md, docs/XCOM2-STUDY.md (WotC bonds: cohesion → bond level, bond abilities)
- Old web game: public/js/darkness.js, base.js, campaign.js, data-campaign.js (read only; port content, never edit)
Reuse existing story text first. New writing: short, Star Wars Old Republic/Jedi tone, consistent with existing data. No copyrighted text from games or films.

## Requirements
- Data-driven: new choices/talks live in godot/data/story/*.json (new files OK), not hard-coded.
- At least: briefing choice on every mission family, 8 mid-mission events, debrief choice after every mission, 12 Temple talks, 10 bonded-pair talks unlocking with bond level.
- Bonds: cohesion points from adjacency, assists, saves, talks; levels at clear thresholds; shown in roster, loadout, battle HUD. Saves/loads correctly (migrate old saves).
- Choices never soft-lock the campaign; balance band holds (Normal rescue bot stays 9–11/20).

## Verification
- New test suite (godot/tests/story_bonds_test.gd, registered in godot/test.sh): every choice resolves, every consequence applies, bonds level up and persist through save/load, old saves migrate.
- `./godot/test.sh` exit 0, 0 SCRIPT ERROR, all suites 0 failures, Normal 10/20 ±1, campaign-test families unchanged.
- Screenshots docs/godot/shots/wave10-story-*.png: a briefing choice, a mid-mission event, a debrief, a Temple talk, the roster with bonds, a battle with a bond line.
- docs/godot/wave10/STORY-REPORT.md: audit table (existed / new / skipped), what the player sees, numbers.
- Commit on branch wave10/story. Don't push. Files < 600 lines.

## File lease
May write: godot/scripts/story/**, godot/data/story/**, godot/data/campaign/legacy.json, godot/scripts/campaign/legacy.gd, godot/scripts/combat_bonds.gd, new godot/scripts/campaign/story_*.gd / bond_*.gd, godot/tests/story_bonds_test.gd, docs/godot/wave10/STORY*, docs/godot/shots/wave10-story-*.png.
Shared files (another lane edits them too — keep each change a small hook inside a block marked `# --- wave10 story ---`): godot/scripts/campaign/state.gd, strat_ui.gd, strat_roster.gd, battle_bridge.gd, godot/scripts/game.gd, hud_controls.gd, godot/test.sh.
Do NOT touch: gear.json, research.json, gear.gd, loadout_* (except a bond badge hook in loadout_details.gd, marked), props.json, art/, assets/maps/, public/, functions/, tests/ (web).
