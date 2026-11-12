# W25 Menus & Temple deepening — shared rules for all 5 lanes

Jess picked focus "Menus & Temple deepening" (ask-918c20c0) and all 5 lanes (ask-3b676a96): A temple, B economy, C galaxy, D roster, E menus.
Goal of the wave: between missions, the Temple feels like XCOM 2's Avenger — people in rooms you can see, real resource/time trades, short paths, every menu reachable on a phone.
Sources of truth (read your gap rows first, plus the captures next to it):
- /home/jess/projects/tw-logs/w25/audit/AUDIT-REPORT.md (Top 15 gaps G1-G15 = table rows 1-15; lanes + contracts at the bottom)
- Audit captures: /home/jess/projects/tw-logs/w25/audit/ (sheet + after1-*.png)
- Jess playtest notes: /home/jess/projects/tw-logs/w25/2026-11-10-jess-playtest-notes.md (battle notes are NOT this wave; do not change battle)

## Setup
- Your worktree already exists: /home/jess/projects/tw-w25/<lane>, branch w25/<lane> off main 4f2e4c7. Untracked godot/assets + addons are already copied in.
- Run `godot --headless --import` (in godot/) before any test. Godot binary: /home/jess/projects/.tools/godot/godot.

## Leases (EXCLUSIVE; paths under godot/)
| Lane | Owns | Gaps |
|---|---|---|
| temple (A) | scripts/campaign/temple.gd, temple_view.gd, temple_geometry.gd, temple_rooms.gd, home_badges.gd, home_tabs.gd, scripts/home14_room_names.gd | G2, G7 room-stage side, G10 Medical room entry, G13 spatial pick side, G12 Memorial room button |
| economy (B) | scripts/campaign/state.gd, strat_base.gd, strat_ui.gd, research_queue.gd, research_screen.gd, strat_council.gd, home_resources.gd, data/campaign/core.json, research.json, temple.json | G3 time side, G5, G7 research panel side, G13 build preview side |
| galaxy (C) | scripts/campaign/galaxy.gd, galaxy_map.gd, galaxy_details.gd, galaxy_intel.gd, sith_screen.gd, sith_layer.gd, sith_operations.gd, data/campaign/galaxy.json | G3 scan sites, G4, G8, G9, G14 map side |
| roster (D) | scripts/campaign/strat_roster.gd, squad.gd, gear.gd, loadout_arsenal.gd, loadout_details.gd, promotion_screen.gd, training_room19.gd | G10 patient choices, G11, fatigue reserve |
| menus (E) | scripts/campaign_bridge.gd, menu.gd, save_load.gd, graphics_options.gd, w24_hud_controls_settings.gd, story/story_screen.gd, story/story_engine.gd, campaign/ui.gd, touch_scroll.gd, NEW data/story/room_story25.json | G1, G6, G12 story side, G14 bridge side, G15 |

## Rules
- Write ONLY your lease plus new `scripts/w25_<lane>_*.gd` helpers, ONE test `tests/<lane>25_test.gd`, and ONE added line in test.sh.
- project.godot, battle scripts, data/rules, data/maps, other lanes' files: read-only. Need a change there? List it under "Integrate asks" in RESULT.md.
- Every call into another lane's API is guarded (has_method / has_signal) with today's behavior as the fallback, so each lane passes alone.
- No battle changes. Battle rules, hit math, AI, mission maps untouched. Normal rescue must stay 9-11/20.
- Old saves must load: new state keys get defaults on load; never rename or drop a saved key.
- Legacy test assertion edits only with a one-line reason each in RESULT.md.
- Files stay under 600 lines (story_engine.gd is already 601: do NOT grow it; put new code in w25_menus_* helpers and only add hook lines if you also move lines out).
- Text is 14 px minimum on phone, WCAG AA contrast (4.5:1) on its fill, no tofu (missing-glyph boxes), no truncation ("GUAR", "12/").
- New art: free only (procedural shader/geometry, Blender headless, or CC0 with CREDITS.md entry). NO Meshy calls. Never print MESHY_KEY.
- Never copy XCOM 2 reference images into the repo (public). Compares live in tw-logs only.
- No commits to main, no push, no `git stash -u`, no `git clean`, never delete untracked files.
- Keep: 44 px minimum touch targets, iPhone drag scrolling via touch_scroll.gd, Back always one tap, the Temple return contract, story beats on entry.

## Phone budget (hard)
- Temple home + Galaxy at 390x844 and 844x390 on Low: no lane raises draw calls or triangles more than 5% vs 4f2e4c7. Measure in a real rendered state, not a headless 0-draw read.
- Pack growth caps vs 46.36 MB: temple 0.6 MB, every other lane 0.3 MB.
- Tap -> visible response <=100 ms on Low.

## Cross-lane contracts (implement yours; call others guarded)
1. economy exposes on the campaign state `strategic_snapshot25() -> Dictionary` {credits, intel, kyber, favor, recruits, power_used, power_cap, day, month, next_threat_days, forecast_month_credits, top_priority: {room_id, label, reason}}. temple shows `top_priority` as its one task rail card; economy's home_resources shows the forecast.
2. economy exposes `advance_strategy_day25(days: int, reason: String) -> Dictionary` {days_advanced, events: Array}. It ticks builds, research, healing, threats and upkeep exactly like the existing day advance, and saves. galaxy calls it ONLY when the player commits a scan. economy owns time and saves.
3. menus (campaign_bridge.gd) keeps/exposes `CampaignFlow.open_intelligence()` (opens galaxy's intel/Sith view) and `CampaignFlow.open_room_story25(room_id: String) -> bool` (plays a room beat from room_story25.json if one is due; false if none). temple calls both. galaxy exposes `open_intel_view25()` on its screen script for menus to route to.
4. roster exposes on Squad/Roster `open_from_temple(focus: String = "")` (focus: "loadout", "medical", "") keeping the existing Temple return, and `patient_actions25(soldier_id) -> Array` of {id, label, days, effect}. temple's Medical room and economy's strat_ui call them.
5. roster exposes `loadout_delta25(soldier_id, item_id) -> Array` of {stat, before, after}; used inside its own loadout screen.
6. menus owns the launch path: after a mission is picked on Galaxy, ONE readiness page (story line, squad, readiness, Deploy). galaxy calls `CampaignFlow.launch_ready25(mission_id)` if present, else today's Briefing path. Deploy needs one confirm; Back returns to the map with the selection kept.
7. Saved keys added this wave are prefixed `w25_` and owned by the lane that writes them; list them in RESULT.md.

## Gate (each lane, in its worktree)
- `godot --headless --import` exit 0; `./godot/test.sh` exit 0; 0 "SCRIPT ERROR"; 0 failures; Normal rescue 9-11/20; `git diff --check` clean.
- Your <lane>25_test.gd checks each gap you own with yes/no asserts (simulated taps/drags, rects inside the viewport, tap counts, saved values, contract fallbacks).
- Rect check: every control you add or move is >=44 px and inside the viewport, no overlaps, at 390x844, 844x390 and 1366x768.

## Proof (under /home/jess/projects/tw-logs/w25/<lane>/)
- 2026-11-11-<lane>-sheet.jpg: before/after at 390x844 and 844x390 Low (plus 1366x768 where layout differs) for each fixed gap. 4-8 panels, ONE JPG.
- RESULT.md: commit sha, files changed, gate numbers, before/after table (taps, draws, tris, pack delta), gaps fixed vs not, contract methods added, w25_ save keys, legacy test edits + reasons, Integrate asks.

## Finish
- Commit on w25/<lane> (message ends with: Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>). Do not merge or push.
- Final message: commit sha, gate numbers, before/after, sheet path, integrate asks.
