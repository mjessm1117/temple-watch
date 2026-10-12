# Status

**v0.1 (2026-10-11).** One Old Republic mission: defend a relay for 8 turns against 3 Sith waves. 2 Jedi + 4 troops. Cover, hit %, overwatch, Guard, Focus, Push/Throw/Collapse/Choke/Stun, Darkness, surrender/subdue, bleed-out/revive, briefing choice, debrief. Local saves + cloud sync by code.

Tests: 40 bot games, 0 errors; a passive bot wins ~30–35%. The sync test passes.

Jess's verdict: concept OK, too basic. Gaps: only one mission, shallow combat, plain look, no progression.

## v0.2 decisions (Jess, 2026-10-12)
- **Split build.** v0.2a: spec D look, spec A combat cut (bleed 4 + Stabilize, difficulty knobs, barrel/door/console/evac, Rescue/Investigate + Threat bar, Guardian/Consular kits, troop R1 abilities, Imperial Agent + Terentatek), base screen (4 wings, 5 resources), crisis list, XP/ranks 1–3, 3-mission loop. v0.2b: Years pass/aging, crafting, Malgus boss, era end.
- **Order Darkness = 0–100** everywhere. Story thresholds rescale ×4: Dark Council ending at ≥80; era-end shadow +1 at ≥60.
- **Era 1 = ~3,660 BBY, boss Darth Malgus** (story spec wins over campaign placeholder).
- Slice story missions: S1 Relay Aurek-7 (defend), S2 Envoy's Trail (investigate), boss Docking Ring Nine (assault, v0.2b).

## Infrastructure
- **Live game:** https://temple-watch.mjessm1117.workers.dev/ (Cloudflare Worker `temple-watch`, auto-deploys on push to `main`).
- Jess's desktop icon: `Temple Watch (latest).url` → live link; icon at `C:\Users\jmolasky\Projects\temple-watch\temple-watch.ico`.
- Cloudflare account: Ovation. KV namespace `temple-watch-saves` (id in `wrangler.toml`).
