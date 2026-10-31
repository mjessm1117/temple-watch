# Wave 5 story lane report

## Player result

The Godot story layer now has three eras of mission briefs and results, Council events and votes, 21 Temple conversations, eight mid-mission squad beats, 15 aftermath decisions, named soldier trust and bonds, era transitions, and a browsable Codex. Briefing, dialogue, and Codex scenes use the Godot menu palette and are readable at 1920×1080. The web sources are frozen and unchanged.

The JSON exporter stores structured data tables, each JavaScript source's string literals, Markdown blocks, **and the exact full text of each source** with a SHA-256 digest. JavaScript function values in data tables are stored as `{"$js": "..."}`. This keeps conditions and prose that are not directly representable as JSON. The exporter also captures the era 3 Council and guest rows added by `story-era3.js` at runtime. `--check` regenerates and compares every JSON file byte for byte.

## Web source inventory

The count column gives principal structured entries, source string literals or Markdown blocks, and source lines. Each JSON file also has a `counts` object for every exported table. The exact source is in `text`.

| Frozen source | Godot JSON | Principal entries; source lines |
|---|---|---|
| `public/js/story.js` | `godot/data/story/story.json` | 201 literals; 196 lines |
| `public/js/data-story.js` | `godot/data/story/data-story.json` | 23 events, 14 plan steps, 13 added missions, 7 crises, 18 epilogues, 22 mission lore links, 9 event lore links, 7 base missions; 683 literals; 295 lines |
| `public/js/story-era2.js` | `godot/data/story/story-era2.json` | 71 literals; 100 lines |
| `public/js/data-era2.js` | `godot/data/story/data-era2.json` | 11 events, 14 plan steps, 13 missions, 7 crises, 6 roster members, 10 foes; 656 literals; 281 lines |
| `public/js/story-era3.js` | `godot/data/story/story-era3.json` | 2 Council seats, 5 planets, 2 guests, 1 redemption text; 162 literals; 157 lines |
| `public/js/data-era3.js` | `godot/data/story/data-era3.json` | 9 events, 14 plan steps, 13 missions, 7 crises, 6 roster members, 11 foes; 629 literals; 279 lines |
| `public/js/saga.js` | `godot/data/story/saga.json` | 191 literals; 171 lines |
| `public/js/data-saga.js` | `godot/data/story/data-saga.json` | 9 cast arcs, 21 talks, 7 approach groups, 8 squad beats, 15 aftermath scenes, 10 finale effects, 6 epilogue groups; 576 literals; 279 lines |
| `public/js/data-codex.js` | `godot/data/story/data-codex.json` | 11 categories, 327 lore entries; 336 literals; 353 lines |
| `public/js/ui-codex.js` | `godot/data/story/ui-codex.json` | 11 category names, 17 status, 16 stat, 29 modifier descriptions; 308 literals; 87 lines |
| `public/js/tutorial.js` | `godot/data/story/tutorial.json` | 7 tutorial cards; 23 literals; 25 lines |
| `public/js/data-life.js` | `godot/data/story/data-life.json` | 5 Council seats, 12 votes, 11 market items, pairing and loyalty rules; 167 literals; 74 lines |
| `public/js/temple-life.js` | `godot/data/story/temple-life.json` | 201 literals; 127 lines |
| `docs/specs/story.md` | `godot/data/story/spec-story.json` | 67 blocks; 267 lines |
| `docs/specs/saga.md` | `godot/data/story/spec-saga.json` | 10 blocks; 45 lines |
| `docs/specs/chains.md` | `godot/data/story/spec-chains.json` | 8 blocks; 32 lines |

The web's base mission and crisis records used by the story are also exported as `BASE_MISSIONS` and `BASE_CRISES` in `data-story.json`. This allows the first briefing to use Relay Aurek-7's actual web text.

## Public API

`const Story = preload("res://scripts/story/story_engine.gd")`; create `var story = Story.new(campaign_state)`. The constructor fills missing fields in the same `Dictionary`; the campaign shell serializes it. `story.state` is available when creating a new campaign. Scene dictionaries have `kind`, `title`, `text`, `choices`, and an optional speaker. The engine stores the current scene in `state.pending`.

| Call | Result |
|---|---|
| `story.start_briefing(mission_id)` | Returns a pre-mission scene with the web approach choices; stores mission and newly seen Codex entries. The selected approach's battle modifiers live in `state.approach`. The Malgus finale rows and their battle effects live in `state.finale_effects`. |
| `story.start_debrief(result)` | `result` is `{mission_id, won, squad, saved_by, clues, bane, boss_dead}` as applicable. Applies mission flags, bonds, approach win rewards and era boss consequences, then returns a debrief scene with aftermath choices. Squad entries and `saved_by` use roster IDs. |
| `story.next_temple_talk(state)` | Returns the next eligible forced or optional character talk, at most two forced talks and one optional talk per hub visit. Returns `{}` if none is ready. |
| `story.apply_choice(state, choice_id)` | Applies the current `state.pending` choice, including flags, resources, loyalty, trust, darkness, wounds, recruitment and mission unlocks. Returns `{ok, choice, state}` or `{ok:false, reason}`. |

Additional calls: `next_story_event(state)`, `next_council_vote(state)`, `next_squad_beat(state, mission_id, turn, squad_names)`, `advance_era(state)`, `bond_points(state, id_a, id_b, points)`, `set_pair(state, padawan_id, mentor_id)`, `unlock_codex(state, kind, id)`, `codex_entries(state, kind)`, `finale_battle_effects(state)`, and `era_epilogues(state)`. Web bond thresholds are 8, 10, 12, 14, 16, 18, 20, 22 points; deployment grants six points plus three on a win, a rescue grants 15, and a paired Padawan gains eight XP.

Scenes accept `set_campaign_state(state)` and `show_scene(scene_dictionary)` before being added to the tree. Opening them directly gives representative sample content for inspection.

## How to view

Launch `res://scenes/briefing.tscn`, `res://scenes/dialogue.tscn`, or `res://scenes/codex.tscn` directly. Screenshots captured from direct scene launches:

- [Briefing with choices](../shots/wave5-story-briefing.png)
- [Codex archive](../shots/wave5-story-codex.png)

## Verification

- `node godot/scripts/story/convert_story.cjs --check`: all 16 sources match their JSON exports.
- `godot --headless --path godot -s tests/story_port_test.gd`: **225 checks, 0 failures**, no script errors. Checks every source's exact text, hash, line count and table entry counts, then checks a flag choice, trust, Council votes, era 1→2→3 boss triggers, bonds, a mid-mission choice, Codex unlocks and all scenes.
- `./godot/test.sh`: **203 checks, 0 failures**, no script errors; Normal rescue bot 11/20 wins.
- Both screenshots captured at 1920×1080 using `story_capture.gd` through Xvfb.

## Integration requests

These edits belong to the campaign or mission lanes and are outside this file lease:

1. **Campaign shell mission launch:** where the hub currently starts a mission, call `story.start_briefing(mission_id)` and display `res://scenes/briefing.tscn` with the campaign `Dictionary` and returned scene. On choice, save the state, read `state.approach` and `state.finale_effects`, apply those modifiers to the mission rules, and then launch the mission. For the current prototype, the routing entry is `godot/scripts/menu.gd::_start` (which currently calls `change_scene_to_file("res://scenes/rescue.tscn")`); the campaign shell should replace that direct transition.
2. **Campaign hub:** after returning to the Temple, call `next_story_event(state)`, then `next_council_vote(state)` when a monthly vote is due, and `next_temple_talk(state)` for character conversations; display nonempty scenes through `dialogue.tscn`, then call `apply_choice` and save the state. When the era boss debrief finishes, offer `advance_era(state)` and use the new roster/plan. Add a Codex button that opens `codex.tscn` with the saved state.
3. **Mission battle:** in `godot/scripts/game.gd::_end_turn`, after `mission.end_turn()` and at turns 2 or 3, call `next_squad_beat(state, mission_id, mission.turn, active_squad_names)`. Present the returned scene as a dialogue overlay, then apply its `state.battle_choice` battle effect before resuming. Battle encounters should call `unlock_codex(state, "enemy", enemy_id)` and likewise for newly used abilities, matching `ui-codex.js`'s encounter unlocks.
4. **Mission result:** when `godot/scripts/hud_controls.gd::_refresh` first sees `g.mission.result != ""`, call `story.start_debrief({"mission_id": mission_id, "won": g.mission.result == "win", "squad": surviving_roster_ids, "saved_by": rescue_pairs, "clues": clue_count, "bane": bane_outcome, "boss_dead": boss_is_dead})` exactly once. Save the resulting state and display `dialogue.tscn` with that scene. The campaign shell should pass actual roster IDs and mission evidence.
5. **Test runner:** add `const StoryPortTest = preload("res://tests/story_port_test.gd")` and a callable shared check method, or invoke `godot --headless --path godot -s tests/story_port_test.gd` from `godot/test.sh`, so the story test runs in the standard suite. This lane did not edit either file.

## Open problems

The current Godot prototype has no persistent campaign hub or mission ID handoff yet, so these scenes are directly launchable and testable but not reachable through its menu. The engine returns battle modifiers for approaches, saga finales and squad beats; the mission lane must apply them to combat units. The JSON files preserve all UI-only web prose verbatim, while Godot currently renders the story-first scenes and Codex; secondary web pages such as the market and full service record remain campaign-shell work.
