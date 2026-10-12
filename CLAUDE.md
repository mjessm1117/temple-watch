# Temple Watch: rules for every Claude chat

This repo is the only source of truth for the game. Real code only.

## Hard rules
- **No artifacts as the deliverable.** Never publish the game, specs, or mockups as Claude artifacts. Edit files in this repo, commit, and push. The live site is a Cloudflare Worker (`temple-watch`) that builds and deploys on every push to `main`.
- **Specs live in the repo**, in `docs/specs/<area>.md`. Game data a spec defines goes in `public/js/data.js` (or a new `public/js/data-<area>.js`), not in prose.
- **One code owner at a time.** Spec chats edit only `docs/`. The Coordinator chat edits `public/`, `functions/`, and `tests/`. Before pushing, pull first; never force-push.
- **Run `npm test` before every push.** It must print no `FAIL` and `"err":0`. Fix failures; don't skip tests.
- Small, surgical edits. Plain JavaScript, no frameworks, no build step for the site. Keep files under ~600 lines; split by topic when one grows past that.
- Commit messages: one line on what changed for the player, e.g. `Add Sentinel path: Shadow Step + Mark Target`.

## Working with Jess
- He doesn't code. Anything he must do: numbered click-by-click steps, copy blocks for anything he pastes.
- Ask taste questions with the ask-user form (2–4 options, a one-line beginner gist each).
- Replies ≤800 characters, blunt, no flattery. Label lore claims with a confidence level.
- Token discipline: read only the files you need.

## Layout
```
public/            the game (served as-is by Cloudflare Pages)
  index.html       page shell; loads css + js in order
  css/style.css    look and feel (color tokens at top)
  js/data.js       numbers: map, waves, squad, enemies  ← tune here
  js/util.js       helpers, tile rules
  js/state.js      game state S, lookups, log
  js/rules.js      sight, cover, hit %, movement, damage
  js/abilities.js  every ability (AB table)
  js/turns.js      mission setup, turn flow, win/lose
  js/ai.js         enemy AI
  js/render.js     board + panels
  js/input.js      taps/clicks
  js/save.js       local + cloud saves
  js/screens.js    briefing/debrief; boots the game (load last)
worker.js               Worker entry: /api/save → backend, else static files from public/
functions/api/save.js   backend: GET/PUT /api/save (KV binding SAVES)
wrangler.toml           Worker config: assets dir, KV binding
tests/                  balance.test.js (40 bot games), sync.test.mjs (cross-device save)
tools/inline.js         builds dist/temple-watch.html (single file, for tests/offline)
docs/                   design, specs, chat briefs, changelog
```
Scripts are classic `<script>` tags sharing globals, loaded in the order in `index.html`. A new file must be added there, and before any file that calls it at load time.

## Commands
- `npm install` once, then `npm test`
- `npm run dev` runs a local server with the backend (needs Wrangler)
