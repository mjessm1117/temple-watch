# REA study: XCOM 2 (War of the Chosen) → design input for Temple Watch's Godot rebuild

## Goal
Jess is rebuilding Temple Watch (XCOM-style Jedi Temple tactics game) in Godot 4.7.2. He wants to borrow DESIGN IDEAS and NUMBERS (not code, art, audio or text) from XCOM 2: War of the Chosen. Document HOW its systems work, with real numbers wherever the data shows them.

Install (READ ONLY, never write into it, never copy files out of it into the repo):
`/home/jess/snap/steam/common/.local/share/Steam/steamapps/common/XCOM 2`
It is the native Linux port (~70 GB). Base game + `XCOM2WotC`. Config is likely lowercase `.ini` files under `share/data/.../config` or similar — search case-insensitively (`find -iname "*.ini"`, `Default*.ini`, `XComGameData*.ini`, `XComGameCore`, `XComAI`). Use REA tools if available to you; plain config/data inspection is fine and preferred where the numbers live in text.

## Read first (Temple Watch context)
`docs/design.md`, `docs/CHANGELOG.md` (skim), `docs/FEEDBACK-2026-10-18.md`. Jess's open complaints: maps feel flat; wants enemies from several directions, bigger maps with objectives that keep you moving, stronger cover/line of sight, Temple base as a "command console".

## Cover these (plain English, numbers where found)
1. Combat core: action points, move ranges (blue/yellow), aim formula (base aim, cover −20/−40, height bonus, range table per weapon, flanking crit), dodge/graze, crit, overwatch/reaction fire penalties, ammo/reload, armor and shred, damage spread.
2. Cover & terrain: half/full cover, destructible cover, height advantage, line-of-sight rules (peeking/stepping out), flanking, fog/concealment.
3. Maps & mission flow: map sizes, plot/parcel procedural map system, objective types, timers, pod activation (enemy groups waking up), reinforcement drops (frequency, direction), evac, how missions push the player forward.
4. Enemy AI: pod behavior, scamper on reveal, target choice, ability use, difficulty scaling (per-difficulty aim/HP/pod counts).
5. Soldiers & classes: class trees, promotion ranks, abilities, will/fatigue, bonds (WotC), wounds/recovery.
6. Strategy layer: Avenger base rooms/staff/power, research and proving grounds, economy (supplies, intel), Avatar Project doom clock, Dark Events, Resistance Orders, Chosen (nemesis enemies), covert actions, time pressure.
7. Pacing & feel: camera, action cam, mission length targets, turns per mission, timer design.
8. UI/UX: shot HUD (hit %, crit %, breakdown), ability bar, base screens, what makes decisions readable.

## Output
`docs/XCOM2-STUDY.md` (plain English, under ~600 lines):
- Sections 1–8 above. Tag every claim: **verified-in-data** (name the config file + key) / **inferred** / **from-general-knowledge**.
- "Temple Watch today vs XCOM 2": short table per section, using what docs/design.md says Temple Watch does now.
- "Recommended for the Godot rebuild": ranked list (top 15), each with what to adopt, how to adapt it to Jedi/Star Wars, and which of Jess's complaints it fixes.
- "Build order suggestion": the 5–8 milestones you'd build in Godot, in order, smallest playable first.

## Boundaries
- Legal line: NO copied code, decompiled script source, assets, or game text beyond short names of mechanics/keys and numbers. Nothing from the install is committed or copied into the repo.
- File lease: `docs/XCOM2-STUDY.md` ONLY. Do not edit any other repo file. Do NOT commit or push — the lead reviews and commits.
- Do not launch the game. Do not spawn subagents. Keep tool output small (head/grep, not full dumps).
