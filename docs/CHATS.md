# Chat plan

Every chat: read `CLAUDE.md` first, then this file. Output = commits to this repo, never artifacts.

**Specs are done (2026-10-12)** and live in the claude.ai project "Star Wars Game": `claude/spec-combat.md` (A), `claude/spec-campaign.md` (B), `claude/spec-story.md` (C), `claude/spec-ui.md` (D). GitHub is the only code source; the project holds specs only.

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

---

# Wave 2 (2026-10-12): from Jess's v0.2a notes

Jess's notes: battle mechanics are good. He wants cover to read more clearly, **real 3D (low-poly, animated, not realistic)**, and kills that feel impactful. After a battle there must be a way to **upgrade troops**. The Temple hub needs **real team management**: loadouts & gear, training & assignments, recruiting choices, bonds & personal quests.

Every wave-2 chat: `git pull` before you start and before every push. `npm test` must stay green (no `FAIL`, `"err":0`). Edit **only the files you own**. If you need a change in someone else's file, add a line under "Requests" in `docs/STATUS.md` and don't make the edit yourself.

| Chat | Owns (edit only these) | Goal |
| --- | --- | --- |
| F 3D Battle | `public/js/view3d/*` (new), `public/vendor/*` (new), `public/models/*` (new), `render.js`, `input.js`, `css/style.css`, `index.html` | 3D board, animation, kill impact, clear cover |
| G Temple & Progression | `base.js`, `campaign.js`, `data-campaign.js`, new `public/js/temple-*.js` | Post-battle upgrades + deep hub management |
| H Maps & Missions | `data.js`, `rules.js`, `abilities.js`, `turns.js`, `ai.js`, `icons.js` | More maps, destructible cover, new objectives and enemies |
| S Story (start **after G pushes**) | new `public/js/story.js`, `public/js/data-story.js` | v0.2b: vision scenes, events, Years pass, Malgus boss, era end |
| E Coordinator | `tests/`, `docs/STATUS.md`, `docs/CHANGELOG.md`; merges and fixes anything | Integrate, play-test, tune, report to Jess |

**Shared contract (all chats):** game logic never depends on the view. Logic files call `fx(type, data)` for anything visual (`move`, `shot`, `hit`, `miss`, `kill`, `down`, `ability`, `explode`, `coverBreak`, `turn`). F defines `fx` in `public/js/fx.js` (loaded right after `util.js`), with a no-op default. F may add one-line `fx(...)` calls to H's files, and H pulls before editing.

## F. 3D Battle
1. Three.js r160+, vendored into `public/vendor/` (no CDN, no build step). Load it as a module that exposes `window.View3D`. **If WebGL is missing (as in the jsdom tests), fall back to the current 2D board.** Tests must still pass.
2. Camera: XCOM-style tilt with 90° rotate (Q/E or buttons), zoom on the mouse wheel, click-to-select through raycast. Laptop first.
3. Low-poly look: CC0 models (Quaternius/Kenney via GitHub) or primitives. Jedi need glowing sabers in the unit color, troops wear Republic colors, Sith are red/black. Credit the asset sources in `public/models/CREDITS.md`.
4. **Cover clarity:** half cover as waist-high crates and walls, full cover as tall pillars and walls. When moving, show shield icons on the tile edges (half = outline, full = solid). The hit-% panel names the cover.
5. **Kill impact:** blaster bolts travel the shot, then hit flash + knockback; kills get a slow-mo beat (≈250 ms), a ragdoll-style fall, a sparks/smoke burst, and a camera nudge. A big `KILL` popup. Saber strikes swing. Force powers get distinct effects (push wave, lightning, choke lift).
6. Respect `prefers-reduced-motion`. Target 60 fps on a mid laptop. Keep each file under ~600 lines.

## G. Temple & Progression
1. **Post-battle upgrades:** the debrief offers a promotion pick for every promoted unit, **troops included**. Use spec A troop kits: Soldier, Scout, Medic, Heavy, choosing 1 of 2 at R2 and at R3. Show what changed.
2. **Loadouts & gear:** a per-unit equipment screen. Troops get a weapon tier, armor, and 1 mod (spec B §5.4). Jedi get saber tiers T2 and crystal color (spec B §5.3), using the Kyber Forge and the Armory wing. Stats flow into the battle through `battleUnit()`.
3. **Training & assignments:** bench units into wings to train (XP), heal faster, or staff the wing for its bonus (spec B §2). Every assignment costs that unit's availability.
4. **Recruiting:** each month, choose from 3 candidates showing class, trait, origin and age. Name the recruit and set the color (spec B §5.5). Cap the roster by Barracks.
5. **Bonds & personal quests** (spec C §7): bond levels grow from shared missions and revives. Expose the in-battle bonus as numbers on `battleUnit()` (e.g. `u.bondAim`) and file a Request for H to apply them. Personal quest offers become missions in the crisis list, using existing mission types.
6. The hub needs a clear Temple screen with tabs: Roster · Armory · Wings · Recruit · Council (seats are display only).

## H. Maps & Missions
1. Give each mission type at least 2 hand-made maps, 6+ in total, and pick one at random per crisis. Mark the tile height for F: half = 1, full = 2.
2. Destructible cover: explosions and Heavy shots degrade full → half → rubble (spec A §1, §4). Add barrels, doors, consoles, beacons and evac if any are missing.
3. Enemies: Imperial Agent (concealed sniper) and Terentatek (a horror that only hurts Force users), from spec A §3.
4. New objectives: sabotage (plant charges, then extract) and a VIP escort. Both use soft pressure (Threat bar), not hard timers.
5. Apply G's bond numbers when they land. Keep the Normal smart-bot win rate at 55–70% (spec A §8), and update `tests/balance.test.js` to cover every map.

## S. Story (after G)
Use spec C §10 and spec B §8 v0.2b, from the "Years pass" step through the Malgus boss: the vision opening scene, the 6 Era-1 events in the hub, the `shadow` meter, the Years pass jump (aging, Trials, retirement), Darth Malgus at Docking Ring Nine (put the map in `data-story.js`), the era-end screen with Legends, and an Archive entry on death. Order Darkness runs 0–100 (Dark Council ending at ≥80).
