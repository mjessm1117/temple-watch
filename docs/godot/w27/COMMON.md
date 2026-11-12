# W27 Common Context — More battle feel

Base SHA: d676da7 (main, last-good). Jess picked W27 = More battle feel (ask-e2d1f7fd) and all 4 lanes (ask-39d98a57).

## Read first
- /home/jess/projects/tw-logs/w27/audit/AUDIT-REPORT.md (77 lines). Gap numbers below refer to its "Top 15" table. Its lane table is your file lease.
- /home/jess/projects/tw-logs/w25/2026-11-10-jess-playtest-notes.md — Jess: "Gameplay needs improvement", "Still far from xcom", first battle too hard.
- XCOM refs (private, never copy into repo): /home/jess/projects/tw-reference/ and tw-reference/phone/.

## Setup (your lane)
1. `git -C /home/jess/projects/temple-watch worktree add /home/jess/projects/tw-w27/<lane> -b w27/<lane> d676da7`. Never touch the main checkout at /home/jess/projects/temple-watch (it has uncommitted files on another branch).
2. rsync the untracked `godot/assets/` and `godot/addons/` from /home/jess/projects/tw-w27/audit/ (already set up at d676da7) into your worktree, without --delete.
3. `/home/jess/projects/.tools/godot/godot --headless --path godot --import` before any test.
4. Logs, captures and scratch scripts: /home/jess/projects/tw-logs/w27/<lane>/ (never /tmp).

## Jess's locked rules (do not break)
- Mission 1 stays the Temple outer-gate DEFENSE, open fight, all enemies in front, reinforcements come later (ask-23a35e0c, ask-43f7daeb). No concealment mechanic, no ambush start, no enemies behind the squad. Better ally starting positions behind cover are fine.
- XCOM rules: 2 actions per turn, firing ends the turn.
- Phone first: Low/Compatibility, 844x390 and 390x844. Every tap target ≥44 px. Port XCOM mechanics only, never assets.
- Keep the legacy rescue fixture and Normal rescue bot at 9–11/20.

## Cross-lane contracts (guarded `has_method` only; never edit another lane's file)
- A exposes `opening_choices27(m)` and `wave_entry27(m)` (read-only dicts).
- B exposes `decision_preview27(actor_id, tile)` (ordered route triggers: reveal, overwatch source tile, cover, height, flank deltas) and `intent_explain27(event)` (one-line enemy reason).
- D exposes `impact_budget27()` (draw/particle budget it uses per beat).
- C consumes A/B/D APIs to render them; C owns the draw-call and tap-size gate.
- New helper files use your lane prefix: `w27a_`, `w27b_`, `w27c_`, `w27d_`.

## Rules
- Write ONLY files in your lease plus your one test and any new `w27<x>_` helpers. Do NOT edit `godot/test.sh` (integration registers tests). Run your test directly with the same godot command test.sh uses.
- If an existing test in another area breaks because of an intended behavior change, you may update that assertion; list every such edit in your report.
- Files stay under ~600 lines; split into a `w27<x>_` helper rather than grow one.
- Gate before commit: headless import exit 0; `./godot/test.sh` exit 0, 0 fail in every suite, 0 `SCRIPT ERROR`, Normal rescue 9–11/20; your test passes when run directly; `git diff --check` clean.
- Portrait Low draw calls on the gate map must not go UP versus d676da7 (183) unless you are lane C bringing them down.
- Capture before/after PNGs at 844x390 and 390x844 Low for what you changed, into tw-logs/w27/<lane>/.
- No Meshy, no paid assets. Free sources only (Godot shaders/geometry, original Blender, CC0 audio with attribution in a credits file).
- Commit on your branch with a player-facing message. No push, no merge, no tags.
- Codex can't spawn subagents; do the work yourself.
- Don't delete untracked files. No `git stash -u`, no `git clean`. Never print MESHY_KEY.

## Final message (≤25 lines)
Commit SHA; files changed; your test's pass count; gate numbers (suites, fails, SCRIPT ERRORs, Normal x/20); portrait gate draw calls before→after; capture paths; integration asks for other lanes; anything unverified.
