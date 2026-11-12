# W29 Audit (READ-ONLY) — deeper battles, difficulty + first 3 missions, story & characters, phone polish 2

Owner: temple-watch. Jess picked all 4 areas for W29 and "start overnight" (ask-f8078e4b).
W28 (class system + phone HUD/move rescue) is still integrating; W29 lanes will branch off the NEW main after W28 ships. Your job: measure, rank gaps, and propose lanes whose leases avoid each other AND say which files W28 changed (see docs/godot/w28/LANE-A..E.md leases) so we don't fight them.

## Setup
- Worktree /home/jess/projects/tw-w29/audit, new branch w29/audit off c507f7b (`git worktree add`). Never touch the main checkout /home/jess/projects/temple-watch.
- rsync untracked godot/assets + godot/addons from /home/jess/projects/tw-w27/audit (no --delete), then `/home/jess/projects/.tools/godot/godot --headless --path godot --import`.
- Outputs ONLY to /home/jess/projects/tw-logs/w29/audit/. Scratch tools there too. No repo edits, no commits.

## Read first
- tw-logs/w25/2026-11-10-jess-playtest-notes.md ("gameplay weak, far from XCOM", first battle too hard) and tw-logs/w28/phone-ui/ (Jess's iPhone shots: "UI not playable").
- tw-logs/w27/audit/AUDIT-REPORT.md and tw-logs/w28/audit/LANES.md + GAPS.md (Hard bot beats Normal: relay/rescue/envoy Story 20/9/20, Normal 15/6/17, Hard 20/12/18).
- XCOM 2 refs (private, never copy into repo): /home/jess/projects/tw-reference/ and tw-reference/phone/.

## Measure
1. Deeper battles: per turn on missions 1-3, count real decisions (flank route vs safe, destroy cover, take height, set overwatch trap, use ability combo). Name what XCOM 2 offers that we lack: destructible cover, height aim bonus, flanking crits, overwatch ambush, explosives on cover, enemy pod activation. Cite file:line for each existing system or say "missing".
2. Difficulty: why Hard wins more than Normal (bot behavior vs enemy stats vs spawn). Propose a fix with expected bot win bands (Story > Normal > Hard, Normal rescue stays 9-11/20).
3. First 3 missions: objectives, map, enemies, turns-to-win. How samey are they? Mission 1 rules are LOCKED: Temple outer-gate defense, open fight, all enemies in front, reinforcements later, no concealment/ambush.
4. Story & characters: story beats per mission in/around battle, character barks, Jedi personality, villain presence. What's missing vs XCOM 2 (Central/Bradford/Shen chatter, soldier bonds). Voice = written lines + optional CC0/free SFX only; no paid TTS.
5. Phone polish 2 (light pass; W28 is fixing battle HUD): list every NON-battle screen (title, Temple home, armory, galaxy, briefing, rank-up, settings) and flag text/tap-size/cut-off risks at 956x440, 844x390 and 390x844. Portrait Low draw calls on the gate map (184 now, target ≤150): name the top 10 draw sources and a cut plan.

## Output
- AUDIT-REPORT.md (<200 lines): top gaps per area ranked by player impact, with file:line and fix idea.
- Proposed 4-5 lanes (one per area, phone may be 1-2), each with exact file lease (no overlaps), one test `<lane>29_test.gd`, cross-lane `has_method` contracts, and conflicts with W28 leases flagged.
- No art needed beyond free sources; flag anything that would need Meshy with a credit quote. NEVER call Meshy. Never print MESHY_KEY.
- Final message ≤25 lines: top 3 gaps per area, the lane split, any Meshy quote, report path.

## Boundaries
Read-only repo. No `git stash -u`, no `git clean`, no deleting untracked files. Codex can't spawn subagents; do it yourself.
