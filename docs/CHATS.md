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

---

# Wave 3 (2026-10-13): "take everything another step deeper"

Jess's picks: animated 3D characters + mission themes · deeper UI/controls · XCOM: **research + Sith ops**, **ambush + high ground**, **stress & scars** · class **trees to rank 7** (2 choices per rank) · deeper gear · lore: **deepen Era 1 to a full era + codex, AND build Era 2 Ruusan** · details & descriptions everywhere.

Same rules as wave 2: `git pull` before you start and before every push · edit only files you own · cross-file needs go under "Requests" in `docs/STATUS.md` · iterate with `npm run test:quick`, run full `npm test` once before each push.

| Chat | Owns | Goal |
| --- | --- | --- |
| F 3D & Feel | `public/js/view3d/*`, `public/js/fx.js`, `public/vendor/*`, `public/models/*` | Animated characters, themed environments, cinematic moments |
| U UI & Controls | `render.js`, `input.js`, `css/style.css`, `index.html`, new `public/js/ui-*.js` | Faster, clearer controls; tooltips/codex viewer everywhere |
| X XCOM Tactics | `data.js`, `rules.js`, `abilities.js`, `turns.js`, `ai.js`, `icons.js`, `state.js` | Ambush, high ground, panic/will in battle, engine for new abilities |
| P Progression & Gear | `campaign.js`, `data-campaign.js`, `base.js`, `temple*.js` | Rank 1–7 trees, deeper gear, research, Sith ops, stress/scars between missions |
| L Era 1 + Codex | `story.js`, `data-story.js`, new `public/js/data-codex.js` | Era 1 becomes a full ~12-mission era; lore text for everything |
| R Era 2 Ruusan | new `public/js/data-era2.js`, `public/js/story-era2.js` | Playable Ruusan era after Era 1 ends |
| E Coordinator | `tests/`, `docs/STATUS.md`, `docs/CHANGELOG.md`, `package.json`, `tools/` | Merge, fix, tune, report |

## Shared contracts (all chats)
- **Descriptions:** every new ability, enemy, gear item, wing, tile, research and status gets a one-sentence mechanical `desc` field in its owner's data table. L writes the flavor text in `CODEX[kind][id] = {lore}` (`data-codex.js`). U builds `describe(kind,id)` and shows `desc` + `lore` in tooltips and a Codex screen. kinds: `ability enemy gear wing tile research status class planet character mission`.
- **Mission themes:** every mission has `theme` (`dock` `city` `jungle` `snow` `temple` `ruins` `plains` `caves`). X sets it on existing missions; L/R set it on theirs; F renders it.
- **Elevation:** X adds walkable raised tiles with `TILES[c].elev` (0–2). F renders the heights; units standing higher get X's bonuses.
- **Campaign → battle modifiers:** P exposes `campaignMods()` → `{enemyAim, enemyHp, extraEnemies, squadAim, …}` (from Sith ops, research). X reads it in `startMission` if it exists. Unit-level numbers (gear, scars, stress, will, research perks) go through `battleUnit()` as plain fields; X applies them.
- **New abilities:** P defines tree abilities as data. If an ability needs a mechanic the engine lacks, P files a Request to X; X implements it in `abilities.js`. Keep ids stable.
- **Era hand-off:** L owns the Era 1 ending; it calls `startEra(2)` if defined (R defines it). R wraps L's functions the same way S did, and doesn't edit `story.js`.

## F. 3D & Feel
1. Replace the block figures with rigged CC0 low-poly characters (e.g. Quaternius animated characters, via GitHub/jsDelivr). Add animations for idle, walk, aim/shoot, saber swing, Force cast, hit, death, and crouch-in-cover. Jedi need robes and a glowing saber in their crystal color; troopers get Republic armor tints; Sith get dark armor; Terentatek and other beasts get creature models. Credit everything in `public/models/CREDITS.md`. Keep the total download under ~8 MB and lazy-load per mission.
2. Mission themes (see contract): floor, walls, props, lighting, sky/fog per theme. Raised tiles get ramps and edges.
3. Cinematic beats: an optional kill cam on lethal shots, a Force-power camera, an enemy-reveal pan when a pod is spotted, and a mission-start flyover. Make each one skippable, with a setting to turn them off.
4. 60 fps on a mid laptop and playable on iPhone Safari. Fall back to 2D without WebGL.

## U. UI & Controls
1. Hotkeys: `1–9` abilities, `Tab` next unit, `Space`/`Enter` confirm, `Esc` cancel, `End` end turn, `C` codex. Add a key legend.
2. Hover/tap tooltips on every ability, status, enemy, tile and stat, using `describe()`. The hit-% panel breaks out every modifier (cover, height, flank, ambush, will).
3. Show a move preview with path cost, plus a dashed second-move zone (XCOM blue/yellow). Preview the AP cost on abilities. Add an undo for the last move when nothing was revealed.
4. A Codex screen (Temple tab + `C` key) that grows as you meet things. Add a Settings panel: animation speed, cinematics on/off, reduced motion, show numbers.
5. Phone pass: a bottom-sheet unit panel and big tap targets. Test at 390×844.

## X. XCOM Tactics
1. **Ambush:** missions marked `stealth:true` start concealed. Patrol pods wander. Show red vision tiles for enemies. Breaking concealment with an attack gives the first shot bonus aim, and overwatch ambushes trigger together. Spec A §1.
2. **High ground:** add raised tiles (`elev`). Higher ground gives +15 aim against lower targets, and the lower side loses 10 defense against the higher one. Line of sight is blocked by taller walls. Add 1–2 raised areas to most maps.
3. **Will & panic:** units have `will`. Ally deaths, horror sightings and heavy damage roll panic: the unit freezes, flees or shoots wildly (Jedi may gain Darkness instead). Read `u.will`/`u.stress` from `battleUnit()`.
4. Implement new ability mechanics that P requests. Give every mission a `theme`. Keep the Normal smart-bot win rate at 55–70% per mission.

## P. Progression & Gear
1. **Trees, ranks 1–7, all 8 classes** (Guardian, Consular, Sentinel, Wayseeker*, Soldier, Scout, Medic, Heavy): each rank offers 2 abilities and you pick 1, so 14 per class. Use spec A kits as the base. Jedi titles go Padawan → Knight (Trials) → Master (Council). XP curve from spec B §5.1. *Wayseeker unlocks from Era 3 per spec A, so build it but lock it.
2. **Gear:** T1–T3 weapons, armor sets, 2 mod slots, a utility slot (grenades, stims, shields), and saber crystals with stats plus a lightsaber form stance (Shii-Cho, Soresu, Ataru, Makashi…: one passive each). Every item gets `desc`.
3. **Research (Archives wing):** a tree of ~15 projects that unlock gear, abilities and wing upgrades, each taking days.
4. **Sith ops:** each month the Empire runs 1–2 ops (spec B Threat). You can counter one by sending a squad or spending Intel; ignored ops apply `campaignMods()` penalties.
5. **Stress & scars:** missions add stress, and resting in the Gardens or Medical removes it. Grave wounds and big losses can leave a scar or trauma (e.g. "fears horrors": −10 aim vs `horror`). Expose these via `battleUnit()`.

## L. Era 1 + Codex
1. Grow Era 1 to ~12 missions in 3 Acts (spec B §1.1). Add 3 more story missions with maps (`data-story.js`), cast arcs for Satele Shan, Jace Malcom and Gnost-Dural (spec C §6), and 10+ more events.
2. Write `data-codex.js` lore for every existing id across all kinds (≤280 chars each, voice per spec C §9), plus planets and characters. Tag lore claims with confidence in a code comment.
3. Write the debrief and briefing lines per mission (spec C §9 sample style).
4. At era end, hand off to `startEra(2)`.

## R. Era 2 Ruusan
1. Spec C §2 Era 2: premise, the 3 story missions (Ravine of the Wounded, Kaan's Caves, The Thought Bomb) plus crisis pool, and 6 events from spec C §3. Include Bane killed/captured/escaped → `shadow` and flags.
2. Roster from spec A §3: Brotherhood Trooper, Sith Marauder, Sith Lord, Mercenary Sniper, Sith Spawn + nexus. Put the data in `data-era2.js` (append to `FOES`); engine needs go to X as Requests.
3. Era jump rules from spec B §1.4: Legends, wing decay, resource carry-over, and the time-skip scene. Add Council cameos (Hoth, Farfalla). Use `theme` values (plains/caves).
4. Era 2 ends in a stub screen: "To be continued: High Republic".

---

# Wave 4 (2026-10-16/17): file owners

Same rules: `git pull` first, edit only files you own, cross-file needs go under "Requests" in `docs/STATUS.md`, `npm test` green before push. **Chat K is the Coordinator from here** (E's job: merge, test, tune, report).

| Chat | Status | Owns (edit only these) |
| --- | --- | --- |
| F Skill trees + Power | shipped | `data-trees.js`, `power.js`, `docs/specs/trees.md`, `tests/trees*.test.js` |
| G Graphics (Meshy) | shipped | `view3d/*`, `public/models/*`, `public/vendor/*`, `tools/meshy/*`. **Hands `css/holo.css` to J.** |
| H Battle variety | merged by K 2026-10-17 | `data-battle.js`, `battle.js`, `battle-ui.js`, `tests/variety.test.js` |
| I Campaign layer | shipped | `darkness.js`, `fieldops.js`, `galaxy.js`, `data-galaxy.js`, `css/galaxy.css`, `tests/layer.test.js`, `docs/specs/second-squad.md` |
| J UI polish | designing | `css/style.css`, `css/holo.css`, `render.js`, `input.js`, `ui-*.js`, `index.html`; screen markup in `base.js`/`temple-ui.js` (look only, no logic). Galaxy map look: ask I. |
| K Coordinator | active | `tests/bot.js` + other tests, `package.json`, `tools/inline.js`, `docs/STATUS.md`, `docs/CHATS.md`, `docs/CHANGELOG.md`; merge fixes anywhere |

Economy numbers (`STIPEND`, `MISSION_CR`, wing costs, Council vote costs) stay with the campaign data owner (`data-campaign.js`, `data-life.js`); field-op and side-objective payouts stay with I (`data-galaxy.js`) and H (`data-battle.js`). One retune pass at a time: K measures, owners change numbers.
