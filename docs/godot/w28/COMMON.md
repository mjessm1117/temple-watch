# W28 Common Context — Class system

Base SHA: c507f7b (main, last-good). Jess picked W28 = Class system (ask-96dfd386 default, ask-c8b6b623) and all 3 lanes (ask-601d204c).

## Read first
- /home/jess/projects/tw-logs/w28/audit/LANES.md and GAPS.md (audit at c507f7b). LANES.md's lease table is your file lease.
- tw-logs/w17/2026-11-06-class-roster.md (v2 design): Jedi Padawan→Knight→Master→Council Master→Grand Master; soldiers start stronger, Masters+ become OP; blend up to 3 same-side classes; every skill unique AND chains/enhances for the unit and squad.
- Existing class, blend, chain, mentor and promotion APIs are the baseline. Extend them; do not rebuild them.

## Setup (your lane)
1. `git -C /home/jess/projects/temple-watch worktree add /home/jess/projects/tw-w28/<lane> -b w28/<lane> c507f7b`. Never touch the main checkout at /home/jess/projects/temple-watch.
2. rsync the untracked `godot/assets/` and `godot/addons/` from /home/jess/projects/tw-w27/audit/ into your worktree, without --delete.
3. `/home/jess/projects/.tools/godot/godot --headless --path godot --import` before any test.
4. Logs, captures, scratch: /home/jess/projects/tw-logs/w28/<lane>/ (never /tmp).

## Locked rules
- XCOM rules: 2 actions per turn, firing ends the turn. Squad starts at 5.
- Phone first: Low/Compatibility, 844x390 and 390x844, every tap target ≥44 px, every scroll list smooth on touch.
- Keep the legacy rescue fixture and Normal rescue bot at 9–11/20. No general balance tuning. The Hard-over-Normal win-rate oddity in the audit is out of scope.
- Keep W27 opening27 behavior intact.

## Cross-lane contracts
- Lane 1 keeps `Classes.rank_data()` tier keys and `Progression.tree_options()` behavior stable.
- Lane 2 keeps ability fields compatible with `class_registry.gd` (`id`, `rank`, `effect`, optional `chain`/`effects`).
- Lane 3 reads those, tolerates missing optional tags.
- Any callback across a lease boundary only after `has_method()`, with a fallback.
- New helper files use your lane prefix: `w28a_`, `w28b_`, `w28c_`.

## Rules
- Write ONLY files in your lease plus your one test and `w28<x>_` helpers. Do NOT edit `godot/test.sh`; run your test directly the way test.sh does.
- If another area's test breaks from an intended change, you may update that assertion; list every such edit.
- Files under ~600 lines.
- Gate before commit: import exit 0; `./godot/test.sh` exit 0, 0 fail every suite, 0 `SCRIPT ERROR`, Normal rescue 9–11/20; your test passes when run directly; `roster25_test.gd` passes; `git diff --check` clean.
- Portrait Low gate draw calls must not rise versus c507f7b (184).
- Before/after PNGs at 844x390 and 390x844 Low of what you changed (Armory tree, promotion screen, ability use in battle) into tw-logs/w28/<lane>/.
- No Meshy, no new 3D assets. Commit on your branch with a player-facing message. No push, merge or tags.
- Codex can't spawn subagents; do the work yourself.
- Don't delete untracked files. No `git stash -u`, no `git clean`. Never print MESHY_KEY.

## Final message (≤25 lines)
Commit SHA; files changed; your test's pass count; gate numbers (suites, fails, SCRIPT ERRORs, Normal x/20); draw calls before→after; capture paths; integration asks; anything unverified.
