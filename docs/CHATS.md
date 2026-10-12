# Chat plan

Every chat: read `CLAUDE.md` first, then this file. Output = commits to this repo, never artifacts.

| Chat | Writes | Goal |
| --- | --- | --- |
| A Combat | `docs/specs/combat.md` + proposed data in `docs/specs/combat-data.js` | Make each turn a real decision |
| B Campaign & base | `docs/specs/campaign.md` + `docs/specs/campaign-data.js` | Give a reason to play the next mission |
| C Story | `docs/specs/story.md` + `docs/specs/story-data.js` | Make it feel like Star Wars; choices matter |
| D Look & feel | `docs/specs/ui.md` + optional `docs/mockups/*.html` (real files, not artifacts) | Readable at a glance, then good-looking |
| E Coordinator | `public/`, `functions/`, `tests/` | Ship v0.2 from the specs |

Spec chats (A–D) may run at the same time; each touches only its own files. E runs after them.

## A. Combat
1. Ability kits: 4–6 per Jedi path (Guardian, Consular, Sentinel, Wayseeker) and per troop class (Soldier, Scout, Medic, Heavy), with 3 rank unlocks. Costs, ranges, numbers.
2. Enemy rosters for all 4 eras, ~3–5 units each (stats + one signature behavior). Force horrors hurt only Force users.
3. Map interactables/events (barrels, doors, consoles, reinforcements, hazards), plus rules for rescue / investigate / assault / defend missions.
4. Balance targets per difficulty and how `tests/balance.test.js` should measure them.
5. Capture → rescue rules. A design for switching to initiative turn order later.

## B. Campaign & base
1. Run structure: missions per era, boss trigger, time jumps, aging/retirement math.
2. Temple wings (build/upgrade/staff/unlocks); the 5-resource economy (Credits, Intel, Kyber, Senate Favor, Recruits) with income and sinks.
3. Council: seats, perks, votes, loyalty, appointments.
4. Progression: XP curve, ranks, gear and saber crafting tiers, recruiting, customization fields.
5. Galaxy map: crisis generation, penalties for ignoring crises, Order Darkness effects.
6. **v0.2 vertical slice**: the smallest loop (≈3 missions + a base screen) that proves the campaign is fun.

## C. Story & characters
1. The vision arc and how each era bends it.
2. Per era: premise, boss, 3 story missions, 5–8 random events with choices (as data: id, era, trigger, text, choices[{label, effects}]).
3. Canon cameos per era (Council, NPC, rare recruit), with date confidence.
4. At least 4 endings and the variables that decide them.
5. Bonds, rivalries, and personal quests; Archive of Legends rules. Short text that fits a phone screen.

## D. Look & feel
1. Visual direction (clean icons; evolve from the current holo war-table).
2. Token/icon system as SVG in `public/img/` specs: classes, enemies, cover, status, abilities.
3. Phone-first wireframes as static HTML files in `docs/mockups/`: base, galaxy/list, squad select, mission, debrief, recruit editor.
4. Combat feedback: move paths, hit preview, shot lines, damage numbers, enemy intent, turn banner. CSS-only animation list. Accessibility: contrast, ≥40px taps, reduced motion.

## E. Coordinator
1. Read `CLAUDE.md`, `docs/design.md`, every `docs/specs/*`, and the code.
2. Propose the v0.2 scope to Jess via the ask-user form (default: B's slice + A's top abilities/enemies + D's tokens + C's Old Republic arc).
3. Build it in `public/` and `functions/`. Keep `npm test` green; add tests for new systems.
4. Push to `main` (Cloudflare deploys it). Tell Jess what changed in ≤5 lines.
5. Update `docs/STATUS.md` and add a dated line to `docs/CHANGELOG.md`.
