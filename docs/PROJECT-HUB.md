# Temple Watch: project hub (copied from the claude.ai project, 2026-10-31)

Any agent with repo access can start here. Then read `CLAUDE.md` (rules + file map) and `docs/CHATS.md` (your brief).

## Rule #1: real code, no artifacts
The game is a real code repo. Never publish the game, specs, or mockups as Claude artifacts or Docs. Every chat's output is commits to this repo.

## Rule #2: desktop first
Design and test for a laptop window with a mouse. Keep phone working, but don't optimize it yet.

## Where things live
- **Code:** GitHub `mjessm1117/temple-watch`, branch `main`. Clone, work, `npm test`, commit, pull, push. Never force-push.
- **Live game:** https://temple-watch.mjessm1117.workers.dev/ (Cloudflare Worker; every push to `main` auto-deploys in ~1 min, no-cache headers).
- **Specs:** `docs/specs/` (combat, campaign, story, ui + later specs). These are the current versions.
- Spec D's mockup artifact (https://claude.ai/artifact/SRkgNQRXHFiAF5QK7bETVK) is reference only; its CSS/render helpers are ported into `public/`.

## Ownership
Spec chats edit only `docs/`. Only the Coordinator (Chat E) edits `public/`, `functions/`, `tests/`, `worker.js`.

## Infrastructure
- Cloudflare account: Ovation. Worker `temple-watch`, built from GitHub (build `npm run build`, deploy `npx wrangler deploy`).
- KV `temple-watch-saves` (id `b30feee759994c939882baa7451d171e`) bound as `SAVES` in `wrangler.toml`.

## Jess's preferences
Replies ≤800 characters, blunt, no flattery. Questions through the ask-user form with beginner-friendly option gists. Copy blocks for anything he pastes. Click-by-click steps. Token discipline. Not a coder.
