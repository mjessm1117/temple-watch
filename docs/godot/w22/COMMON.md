# W22 COMMON rules (all six lanes): Battle feel + Story

Jess chose **Battle feel** (ask-bc527bfc), then added **Story** in chat. He picked all 6 lanes (ask-de9acc8f). The evidence:
- Battle audit: /home/jess/projects/tw-logs/w22/audit/AUDIT-REPORT.md and sheet 2026-11-10-audit-sheet.jpg in the same folder.
- Story audit: /home/jess/projects/tw-logs/w22/story-audit/AUDIT-REPORT.md and sheet 2026-11-10-story-audit-sheet.jpg in the same folder.

Read your lane's problem rows, the XCOM notes, and the CROSS-LANE CONTRACTS section below.

## Setup (do this first, exactly)
```
cd /home/jess/projects/temple-watch
git worktree add -b w22/<lane> /home/jess/projects/tw-w22/<lane> 81c7644
rsync -a --ignore-existing /home/jess/projects/temple-watch/godot/assets/ /home/jess/projects/tw-w22/<lane>/godot/assets/
cd /home/jess/projects/tw-w22/<lane>/godot && /home/jess/projects/.tools/godot/godot --headless --import
```
The rsync copies untracked textures that the import needs. If you skip it or the import, you get false SCRIPT ERRORs.

## Rules
- Write ONLY the files in your lane's lease. Everything else is read-only. New files you create inside `godot/scripts/` with your lane prefix (e.g. `feelcam22_*.gd`) are also yours.
- Exception 1: add one line to `godot/test.sh` to register your new suite. Change nothing else there.
- Exception 2: you may update assertions in an existing `godot/tests/*.gd` file, but only when your intended change makes the old assertion wrong. Never weaken a test to hide a bug. List every such edit in your report, with the reason.
- Need a change in a file another lane owns? Do NOT edit it. Write it under "Integrate asks": the file, the function, and the one-line change.
- Code against the CROSS-LANE CONTRACTS. Guard every call into another lane's API with `has_method` / `has_signal`, so your branch works alone and lights up once integrate merges everything.
- Phone first. Test at 844x390 and 390x844, Compatibility/Low; also check 1366x768.
  - Tappable controls must be at least 44 px, at least 12 px from the screen edge, and must not overlap.
  - Text must be at least 14 px and meet WCAG AA contrast.
  - Use the W21 style tokens in `ui.gd` and the Noto fonts. Read them; do not edit `ui.gd`.
- Performance budget at Low:
  - No new per-frame allocation in hot loops.
  - Particles stay within the existing Low caps.
  - New camera moves are 0.5 s or less, unless they are a once-per-mission beat.
  - Any new pause or hit-stop is 0.12 s or less for normal hits and 0.3 s or less for kills and crits.
  - Everything must stay skippable by tap.
- XCOM rules stay: 2 actions per turn, and firing ends the turn. Do not change balance numbers. Normal rescue must stay at 9-11/20.
- Keep files under ~600 lines. `game.gd` is already 553 lines, so put new code in new helper files.
- No subagents. No Meshy spending. Never print MESHY_KEY. Never commit XCOM images or text. Port mechanics only.
- Do not merge, push or tag. Commit only on your branch `w22/<lane>`. Do not delete untracked files.

## CROSS-LANE CONTRACTS (exact names, so integrate can wire them)
1. **Lane A (`game.gd`).** Add `signal battle_event(kind: String, actor_id: String, target_id: String, context: Dictionary)` and emit it in true event order.
   - Kinds: `hit`, `miss`, `crit`, `kill`, `hurt`, `flank`, `reveal`, `villain_reveal`, `villain_retreat`, `objective_hit`, `reinforce`, `player_turn_start`, `enemy_turn_start`, `enemy_turn_end`.
   - `context` carries at least `damage` (where relevant), `world_pos: Vector3`, `turn: int`, `objective_hp` (for `objective_hit`) and `group` (for reveal).
2. **Lane A.** Add `func cue_story(kind: String, world_pos: Vector3) -> void` on `game.gd` or an A-owned helper that game.gd exposes. It does a short camera focus (0.6 s or less) that never locks input for more than 1.0 s. Kinds: `focus`, `villain`, `reveal`.
3. **Lane B (`audio.gd`).** Keep `play(kind)`. Add `func cue(kind: String) -> void` and `func set_music_state(state: String) -> void`.
   - Cue kinds: `hit`, `crit`, `kill`, `blast`, `saber_clash`, `alert`, `villain`, `radio`, `objective_hit`, `victory`, `defeat`.
   - Music states: `calm`, `contact`, `enemy`, `victory`, `off`.
   - Respect the existing mute and volume settings.
   - Your report must state the exact way other scripts reach the audio node.
4. **Lane D (`mission_pressure.gd`).** Add `static func threat_summary(m: RefCounted) -> Dictionary` returning:
   - `exposed_units: Array` (unit ids that known enemies can see/flank)
   - `objective_risk: int` (expected objective damage next enemy turn; 0 if none)
   - `pending_groups: Array` of `{label, count, turns, entry_pos}`
   - `villain: Dictionary` (`{}` if none, else `{name, status, line}`)

   Also add `static func reveal_info(m: RefCounted, group: Array) -> Dictionary` returning `{title, count, types: Array, threat_line}`.
5. **Lane C (HUD).** Renders `threat_summary` beside End Turn, and the reveal title. C reads D's API and never edits D's files.
6. **Lane E (`story/story14_beats.gd`).** Add `static func pick_bark(kind: String, actor_id: String, target_id: String, context: Dictionary) -> Dictionary`. It returns `{speaker, portrait_key, text, priority}`, or `{}` when nothing should fire. Rate limiting is F's job, not E's.
7. **Lane F (`story14_comms.gd`).** Add `func show_radio(speaker: String, portrait_key: String, text: String, priority: int) -> void`. It shows a NON-BLOCKING radio card (portrait, name, at most 2 lines). The card auto-dismisses after about 3 s, can be tapped away, and never pauses input or covers the selected unit or the action bar.
   - F subscribes to `battle_event` through `campaign_bridge.gd`, calls E's `pick_bark`, rate-limits (at most 1 bark per 4 s, and at most 1 per actor per turn), and keeps a bounded transcript.

## Gate (must pass in your worktree before you finish)
1. `godot --headless --import` exits 0.
2. `./godot/test.sh` exits 0, with 0 `SCRIPT ERROR` and 0 failures in every suite, including your new one. Normal rescue lands at 9-11/20.
3. `git diff --check` is clean.

## Proof
Make a before/after sheet at /home/jess/projects/tw-logs/w22/<lane>/2026-11-10-<lane>-sheet.jpg. It has at most 6 panels at 844x390 (add 390x844 where layout matters). "Before" comes from 81c7644. For timing work, add a before/after timing table in your report.

## Final message
- the commit SHA
- files changed
- new suite pass count, plus total suites and failures
- the Normal score
- the sheet path
- before/after numbers (timings, word counts, sizes)
- legacy-test edits, with reasons
- the contract calls you implemented or consumed
- Integrate asks
- anything left undone
