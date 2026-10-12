# Status

**v0.1 (2026-10-11).** One Old Republic mission: defend a relay for 8 turns against 3 Sith waves. 2 Jedi + 4 troops. Cover, hit %, overwatch, Guard, Focus, Push/Throw/Collapse/Choke/Stun, Darkness, surrender/subdue, bleed-out/revive, briefing choice, debrief. Local saves + cloud sync by code.

Tests: 40 bot games, 0 errors; a passive bot wins ~30–35%. The sync test passes.

Jess's verdict: concept OK, too basic. Gaps: only one mission, shallow combat, plain look, no progression.

## Infrastructure
- Cloudflare account: Ovation. KV namespace `temple-watch-saves` (id in `wrangler.toml`).
- Pages project: connect this GitHub repo; build output `public`, no build command.
