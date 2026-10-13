# Status

**v0.2a (2026-10-12, live).** Campaign slice: pick difficulty → Temple base → Relay Aurek-7 (story, defend) → pick 1 of 2 crises (Ord Mantell rescue / Dantooine shrine defend with a Terentatek) → The Envoy's Trail (story, investigate) → slice-end screen.
- Look (spec D): class-icon tokens, segmented HP, status badges, red/white odds tags, two-step aim with an odds breakdown + Confirm, tap-enemy intent line, turn banner, hover move path, new color tokens.
- Combat (spec A cut): bleed-out by difficulty (Story 6 / Normal 4 / Hard 3 / Legend 2), Stabilize, capture on loss → rescue crisis, hidden aim assist, crits, armor, barrels, doors, locked doors + console/Hack, clue terminals, evac zones, Threat clock (Rescue par 5, Investigate par 6), Guardian + Consular kits (rank 2/3 = pick 1 of 2), troop R1 abilities (Suppress, Hunker, Mark, Smoke, Hack, Shredder), Imperial Agent (hidden), Terentatek (hurts only Jedi; devours a Jedi left down and unstabilized for a turn).
- Campaign (spec B cut): 5 resources, 4 wings (Medical L1–2, Training, Forge, Comms), monthly stipend/upkeep/pay, hire troopers, XP ranks 1–3, wounds in days, emergency levy when <4 fit units, Archive of fallen names.
- Deviations: Rescue/Investigate end in a loss at Threat 6 (prevents endless stalemates); reinforcements capped at 3 groups; data from 2 scanned terminals reaches every comlink (anyone on evac extracts); relay map keeps v0.1's three "fortify" crates; Forge has no effect until crafting (v0.2b).
- Bot results (10 games each, Normal, weak passive bot): relay ~25–30%, shrine ~100%, rescue ~70–80%, envoy ~40–70%. Spec A's smart bot + 200-game tuning is still to do.

**Next (v0.2b):** Years pass (aging, Trials, retirement), saber/gear crafting, Docking Ring Nine boss vs Darth Malgus, era end. Also: smart bot and difficulty tuning to spec A §8 bands.


**v0.1 (2026-10-11, superseded).** One Old Republic mission: defend a relay for 8 turns against 3 Sith waves. 2 Jedi + 4 troops. Cover, hit %, overwatch, Guard, Focus, Push/Throw/Collapse/Choke/Stun, Darkness, surrender/subdue, bleed-out/revive, briefing choice, debrief. Local saves + cloud sync by code.

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
