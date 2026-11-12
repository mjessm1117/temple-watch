# W27 Lane B — Tactical preview + AI legibility (worktree tw-w27/preview, branch w27/preview)

Read docs/godot/w27/COMMON.md first and follow it exactly. Lane prefix `w27b_`.

## Lease
godot/scripts/combat_mission.gd, ai.gd, input_controls.gd, hud_controls.gd, map_art_grid.gd, combat_targeting.gd, w24_threat_route.gd (all under godot/scripts/), new godot/tests/tactics27_test.gd, new w27b_* helpers.

## Goal (audit gaps 3, 4, 6, 11, 12)
Before the player commits, they should see what will happen, like XCOM 2's move preview (ref tw-reference/phone/2026-11-10-xcom2-ios-05.png).
1. Gap 3: the move preview floods brown terrain. Show ONE path line and a clear move-range perimeter (blue 1-action, yellow dash), and mark the FIRST danger tile on the route with its overwatch source.
2. Gap 4: route safety is a boolean. Return ordered route events (reveal at tile X, overwatch from enemy Y at tile Z, enters flanked position) and show where each fires.
3. Gap 11: cover shield (none/half/full), height and flank delta shown in one persistent preview at the destination, not just percent/seen.
4. Gap 6 (AI side): one enemy action = one reason line ("Flanking Kira", "Overwatch on gate") via `intent_explain27(event)`. Lane C owns the phone card that shows it; you own the reason text and its priority. Add an AI grenade decision only if small and safe; otherwise list it as a gap.
5. Gap 12 hook: if lane A's `wave_entry27` exists (has_method), include the entry tiles as route danger.
Expose `decision_preview27(actor_id, tile)` → {path, events:[{kind,tile,source}], cover, height, flank, odds_delta}.

## Test
tactics27_test.gd: single path + perimeter present, first danger tile matches overwatch source, ordered events correct on a staged map, cover/height/flank fields populated, intent_explain27 returns a reason for move/shoot/overwatch/flank. Tap-to-preview time on the 844x390 proxy must not regress past 100 ms (W24 was 84 ms).
