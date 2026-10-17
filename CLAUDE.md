# Temple Watch: rules for every Claude chat

This repo is the only source of truth for the game. Real code only.

## Hard rules
- **No artifacts as the deliverable.** Never publish the game, specs, or mockups as Claude artifacts. Edit files in this repo, commit, and push. The live site is a Cloudflare Worker (`temple-watch`) that builds and deploys on every push to `main`.
- **Specs live in the repo**, in `docs/specs/<area>.md`. Game data a spec defines goes in `public/js/data.js` (or a new `public/js/data-<area>.js`), not in prose.
- **One code owner at a time.** Spec chats edit only `docs/`. The Coordinator chat edits `public/`, `functions/`, and `tests/`. Before pushing, pull first; never force-push.
- **While iterating, run `npm run test:quick` (~3 min). Run the full `npm test` (~15+ min) once before every push.** It must print no `FAIL` and `"err":0`. Fix failures; don't skip tests.
- **Desktop first.** Design and test for a laptop window (~1366×768 and up, mouse). Keep phone working but don't optimize it yet.
- Small, surgical edits. Plain JavaScript, no frameworks, no build step for the site. Keep files under ~600 lines; split by topic when one grows past that.
- Commit messages: one line on what changed for the player, e.g. `Add Sentinel path: Shadow Step + Mark Target`.

## Working with Jess
- He doesn't code. Anything he must do: numbered click-by-click steps, copy blocks for anything he pastes.
- Ask taste questions with the ask-user form (2–4 options, a one-line beginner gist each).
- Replies ≤800 characters, blunt, no flattery. Label lore claims with a confidence level.
- Token discipline: read only the files you need.

## Layout
```
public/            the game (static files served by the Worker; _headers = no-cache so the newest build always loads)
  index.html       page shell; loads css + js in order
  css/style.css    look and feel (color tokens at top)
  js/data.js       combat numbers: difficulty, enemies, missions (maps, waves, rewards)  ← tune here
  js/data-campaign.js  classes, ranks, kits, wings, economy, crises, mission plan  ← tune here
  js/icons.js      stroke icons (spec D) + icon() helper
  js/util.js       helpers, tile rules
  js/state.js      game state S, lookups, log
  js/rules.js      sight, cover, hit %, movement, damage
  js/abilities.js  every ability (AB table)
  js/turns.js      mission setup, turn flow, win/lose
  js/ai.js         enemy AI
  js/render.js     board + panels
  js/input.js      taps/clicks
  js/save.js       local + cloud saves (campaign C + live mission S)
  js/campaign.js   campaign state C: XP, wounds, calendar, economy, results
  js/base.js       Temple base, squad select, debrief, slice-end screens
  js/temple-map.js Temple floor plan: rooms → tabs (left rail of the Temple screen)
  css/ui.css       desktop HUD layout (bottom battle bar, Temple rail); loaded last
  js/data-galaxy.js  planets, regions, risk bands, field-op templates  ← tune here
  js/darkness.js   Darkness reduction: Gardens, mercy, redemption, mentors
  js/fieldops.js   off-screen field ops (2–3 units, resolve on a roll)
  js/galaxy.js     galaxy map + briefing panel (replaces the mission list)
  js/screens.js    opening vision + difficulty; boots the game (load last)
worker.js               Worker entry: /api/save → backend, else static files from public/
functions/api/save.js   backend: GET/PUT /api/save (KV binding SAVES)
wrangler.toml           Worker config: assets dir, KV binding
tests/                  bot.js (test bot), layer.test.js (Darkness/field ops/map), balance.test.js (bot games per mission), campaign.test.js (full slice), sync.test.mjs (cross-device save)
assets/temple-watch.ico  desktop icon used by the launcher on Jess's laptop
tools/inline.js         builds dist/temple-watch.html (single file, for tests/offline)
docs/                   design, specs, chat briefs, changelog
```
Scripts are classic `<script>` tags sharing globals, loaded in the order in `index.html`. A new file must be added there, and before any file that calls it at load time.

## Commands
- `npm install` once, then `npm run test:quick` while working and `npm test` before pushing
- `npm run dev` runs a local server with the backend (needs Wrangler)
