# Status

**v0.2a (2026-10-12, live).** Campaign slice: pick difficulty → Temple base → Relay Aurek-7 (story, defend) → pick 1 of 2 crises (Ord Mantell rescue / Dantooine shrine defend with a Terentatek) → The Envoy's Trail (story, investigate) → slice-end screen.
- Look (spec D): class-icon tokens, segmented HP, status badges, red/white odds tags, two-step aim with an odds breakdown + Confirm, tap-enemy intent line, turn banner, hover move path, new color tokens.
- Combat (spec A cut): bleed-out by difficulty (Story 6 / Normal 4 / Hard 3 / Legend 2), Stabilize, capture on loss → rescue crisis, hidden aim assist, crits, armor, barrels, doors, locked doors + console/Hack, clue terminals, evac zones, Threat clock (Rescue par 5, Investigate par 6), Guardian + Consular kits (rank 2/3 = pick 1 of 2), troop R1 abilities (Suppress, Hunker, Mark, Smoke, Hack, Shredder), Imperial Agent (hidden), Terentatek (hurts only Jedi; devours a Jedi left down and unstabilized for a turn).
- Campaign (spec B cut): 5 resources, 4 wings (Medical L1–2, Training, Forge, Comms), monthly stipend/upkeep/pay, hire troopers, XP ranks 1–3, wounds in days, emergency levy when <4 fit units, Archive of fallen names.
- Deviations: Rescue/Investigate end in a loss at Threat 6 (prevents endless stalemates); reinforcements capped at 3 groups; data from 2 scanned terminals reaches every comlink (anyone on evac extracts); relay map keeps v0.1's three "fortify" crates; Forge has no effect until crafting (v0.2b).
- Bot results (10 games each, Normal, weak passive bot): relay ~25–30%, shrine ~100%, rescue ~70–80%, envoy ~40–70%. Spec A's smart bot + 200-game tuning is still to do.

**v0.2b story (Chat S, 2026-10-12):** vision shard scene, 6 Era-1 Council events, Vision meter (`C.story.shadow`), Years pass (+5 yrs: aging, Trials, retirement → staff/teach/relic), 3 new crises (Hydian blockade, listening post, Hutt ledger; mirrored maps), Darth Malgus at Docking Ring Nine (assault), era-end screen with history recap, Archive of Legends (local, cap 30).

**Next (v0.2b):** Years pass (aging, Trials, retirement), saber/gear crafting, Docking Ring Nine boss vs Darth Malgus, era end. Also: smart bot and difficulty tuning to spec A §8 bands.


**v0.1 (2026-10-11, superseded).** One Old Republic mission: defend a relay for 8 turns against 3 Sith waves. 2 Jedi + 4 troops. Cover, hit %, overwatch, Guard, Focus, Push/Throw/Collapse/Choke/Stun, Darkness, surrender/subdue, bleed-out/revive, briefing choice, debrief. Local saves + cloud sync by code.

Tests: 40 bot games, 0 errors; a passive bot wins ~30–35%. The sync test passes.

Jess's verdict: concept OK, too basic. Gaps: only one mission, shallow combat, plain look, no progression.

## v0.2 decisions (Jess, 2026-10-12)
- **Split build.** v0.2a: spec D look, spec A combat cut (bleed 4 + Stabilize, difficulty knobs, barrel/door/console/evac, Rescue/Investigate + Threat bar, Guardian/Consular kits, troop R1 abilities, Imperial Agent + Terentatek), base screen (4 wings, 5 resources), crisis list, XP/ranks 1–3, 3-mission loop. v0.2b: Years pass/aging, crafting, Malgus boss, era end.
- **Order Darkness = 0–100** everywhere. Story thresholds rescale ×4: Dark Council ending at ≥80; era-end shadow +1 at ≥60.
- **Era 1 = ~3,660 BBY, boss Darth Malgus** (story spec wins over campaign placeholder).
- Slice story missions: S1 Relay Aurek-7 (defend), S2 Envoy's Trail (investigate), boss Docking Ring Nine (assault, v0.2b).

## Requests (wave 2: chat → owner: ask)
- ✅ done by H — G → H: apply bonds in combat. `battleUnit()` now sets `u.bonds=[{rid,lvl}]`, `u.bondAim` (+5 aim while within 3 tiles of any bonded partner, lvl ≥1) and `u.bondReact` (lvl ≥2: one free reaction shot/strike per mission when a bonded partner is hit). Partner match: `p.rid===b.rid`.
- ✅ done by H — G → H: in `heal`, `stabilize`, `forceRevive`, set `t.savedBy=u.rid` (bonds grow from revives; G's Revive Stim and Rally already do).
- G → H: troop R2/R3 abilities Rapid Fire, Deadeye, Rally, Revive Stim, Rocket live in `temple-kits.js` and only load if `AB` lacks them. Move/replace them in `abilities.js` whenever you like; yours win. Player `armor` (Flak Vest, Juggernaut) uses the existing `damage()` armor rule.
- G → E: `tests/campaign.test.js` clicks `[data-act="hire"]`, which no longer exists: hiring is now `[data-act^="hire:"]` (one button per candidate). Test still passes (it just never hires). A Temple scratch test (gear, saber, assignments, recruiting, debrief picks, troop abilities, bonds, quests) passed; happy to hand it over as `tests/temple.test.js`.
- G → F: G added 4 script tags to `index.html` (temple-data, temple-kits, temple, temple-ui, after campaign.js). `temple-ui.js` injects a small `<style>` block for tabs/armory/recruit cards; fold it into `style.css` if you prefer.
- G → S: hooks for v0.2b: `ensureTemple()` migrates saves; units carry `age`, `trait`, `origin`; retirees can staff a wing via `C.staff[wing]=id` + `r.assign='staff:'+wing`; Jedi titles stay yours (Trials). Personal quests show only on crisis steps of `PLAN`.
- ✅ done by H — F → H (`turns.js`): in `endTurn`'s enemy loop, after `await eAct(e)`, add `await View3D?.idle?.()` (one line: `if(window.View3D)await View3D.idle();`). Lets each enemy's animation finish before the next acts. Resolves at once in 2D/tests; capped at 4 s.
- F → H/E (fx contract): `public/js/fx.js` (loaded after `ai.js`) emits `move`, `shot`, `miss`, `hit`, `kill`, `down`, `explode`, `ability` by wrapping `moveAlong`, `resolve`, `damage`, `blast`, `exec`. Keep those names and signatures. New effects: call `fx('coverBreak',{x,y})` when cover degrades (the view also diffs the grid, so it's optional). If you add your own `fx('shot'…)` calls, delete the matching wrapper in `fx.js`.
- ✅ done by E — H → G (`campaign.js` + `data-campaign.js`): (1) bonus line → `const bonus=missionBonus();` (turns.js; covers sabotage/escort). (2) New crisis missions are ready but not in `PLAN` yet. Paste into `CRISES` and add the ids to a `crises:[…]` step:
  `archive:{n:'Imperial listening post',kind:'Investigate',src:'Navy request',mission:'archive',text:'An Imperial post is reading our fleet traffic. Copy its data and get out.',ignore:{favor:-5}},`
  `sabotage:{n:'Strike the fuel depot',kind:'Sabotage',src:'Senate request',mission:'sabotage',text:'Blow the depot fuelling the Balmorra fleet. Plant 2 charges, then extract.',ignore:{favor:-8}},`
  `escort:{n:'Get the senator out',kind:'Escort',src:'Senate request',mission:'escort',text:'A senator marked for death must reach a shuttle across hostile ground.',ignore:{favor:-8}},`
  Each crisis mission picks one of its 2 maps at random (`startMission` option `map` forces one; `S.mapIx` records it).
- ✅ done by E — H → F (2D `render.js`): new tiles `B` blast wall, `h` broken wall, `b` alarm beacon, `C` charge site, `X` armed charge. `TILES[c]` (data.js) has name, cover, walk and `as` (an old 2D class to borrow): use `TILE_CLS[c]||TILE_CLS[TILES[c].as]`. Tile icons: `b`→`beacon`, `C`/`X`→`charge`. HUD objective: replace the `sObjL/sObj` if-chain with `const o=objStat();set('#sObjL',o.label);set('#sObj',o.val)` (turns.js; knows sabotage/escort).
- ✅ done by E — H → F (3D `view3d/board.js`): read heights from `TILES[c].h` (full 2, half 1, rubble .5) instead of the hard-coded `tileH` lists, and give `B`/`h`/`b`/`C`/`X` a model (blast wall = cracked wall, broken wall = half-height wall, beacon = mast with a red light, charge = crate with a blinking light). `degrade()` in rules.js calls `fx('coverBreak',{x,y,from,to})`.
- H → E: `util.js` FULL/HALF/PASS now read `TILES` (data.js). Side effect: rubble now counts as half cover (matches the legend). `tests/bot.js` learned doors, Plant charge, beacons and full-squad extraction; `balance.test.js` validates every map (tiles, starts, evac reachable) and plays every variant.
- F → E: optional cleanup: rename state.js's floating-text `fx(p,txt,cls)` to `floatText`; `fx.js` keeps the old 3-arg form working until then.
- S → F: S added 2 script tags to `index.html`: `data-story.js` after data-campaign.js, `story.js` after base.js. Keep them in that order.
- ✅ done by E — S → G: story.js wraps `baseScreen`, `endScreen`, `applyResults`, `addRecruit`; keep those names or ping S. Retirees get `status:'retired'`; please show them as Retired in the roster (staff retirees already read "Staffing …"). Retiree staffing uses your `C.staff[wing]=id` + `r.assign`.
- S → H: mission type `assault` (Malgus, `dock` in data-story.js) is implemented in story.js by wrapping `checkEnd`/`threatStep`/`startMission`: win = unit with `boss` dead, Threat 6 = loss. Fold it into turns.js whenever you like. render.js could show the boss HP as the objective.
- S → E: S made surgical test edits so npm stays green: campaign.test.js clears story screens and expects `PLAN.length` steps; sync.test.mjs clears the opening scenes; balance.test.js adds blockade/cache/hutt/dock. Weak-bot Malgus win (30 games): Story ~67%, Normal ~27%.

## Infrastructure
- **Live game:** https://temple-watch.mjessm1117.workers.dev/ (Cloudflare Worker `temple-watch`, auto-deploys on push to `main`).
- Jess's desktop icon: `Temple Watch (latest).url` → live link; icon at `C:\Users\jmolasky\Projects\temple-watch\temple-watch.ico`.
- Cloudflare account: Ovation. KV namespace `temple-watch-saves` (id in `wrangler.toml`).
