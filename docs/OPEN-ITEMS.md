# Open items — Wave 7 (2026-10-22)

Every open request, bug and "not done" note from STATUS/CHANGELOG/FEEDBACK, one owner each. Tick `[x]` and add the commit hash when shipped. E2 (Coordinator) keeps this file current and closes the wave when all boxes are ticked or explicitly dropped by Jess.

Already closed this week (don't redo): armor pips, Padawans (bond 2 start), voices, nicknames, 3D camera + aim view, XCOM HUD, phone landscape, Temple ziggurat/spires/undercroft/wing actions, hack rewards, graze, flank preview, melee charge, Mind Trick turns foes, shield prop, vault hop arc, loot/flare markers, loot credits banked, new Sith schemes, Era 3.

## E2 · Coordinator (integration, tests, Temple, HUD)
- [x] Campaign test flake: rescue chain can loop past 24 missions (~1–2 in 8 runs). Cause: a lost personal quest (adv:0) stayed on offer, so the bot could re-pick it forever on one step (losses fed rescues). Fix: one try per quest per step. `935de8d`
- [x] campaign.test.js should spend like a player: bot now queues wings, crafts sabers, upgrades blasters, hires (keeps 100 Cr spare). 2 runs: ~1,000 Cr spent, 243 Cr left at era end (spec B band 0–300; old bot hoarded ~1,130). `a5f36c1`
- [x] Temple roster cards: show Tired (`isTired(r)`) and team name (`teamOf(r.id)?.n`) badges. `a5f36c1`
- [x] Fold adjacency (`adjSum`): checked, wouldn't simplify (6 call sites, all in temple-build.js with their own news lines). Left as is.
- [x] Front A squad gets benched-stress relief at the shared time step: fixed with `r.fought`/`C.tick` (anyone who fought since the last time step counts as deployed). `a5f36c1`
- [x] Forge: confirmed real. Gates T2/T3 saber crafting (+1 dmg each tier, test-checked), Attune Sabers action, staff Kyber discount, adjacency. `a5f36c1` (test)
- [x] Clean stale notes at the top of STATUS.md: v0.2a/v0.2b/"Next" block replaced with a pointer to CHANGELOG + OPEN-ITEMS.
- [x] ~~Optional cleanup: rename `fx(p,txt,cls)` → `floatText`~~ **Deferred by Jess (2026-10-22) to after wave 7** (~120 call sites in 14 files other chats are editing).
- [ ] Merge, run full `npm test`, push; close this file.

## B2 · Balance
- [ ] Balance recheck after the stat rework + this week's changes: armor pips (tanks much weaker), melee charge, graze, hack, wing-action buffs, spires. Measure with the bot; numbers in `CLASS`, `ARMOR`, `MELEE`, `GRAZE`, `MOD_ACTS`, `SPIRES`.
- [ ] Strike-team auto-resolve odds (first-pass 62–70%): measure and tune `TAUTO`/`FATIGUE`.
- [ ] Malgus win rate (old: Normal ~27%, Story ~67% weak bot) and Ossus Vault (~50–60%, Threat-limited): re-measure, tune to spec A bands.
- [ ] With M3: once layouts are validated, re-run full balance and turn off `map-open.js` auto-breaches (`OPEN.off=true`) if bands hold.

## M3 · Maps
- [x] Add a sightline / blind-spot metric to `tests/mapcheck.test.js` (no long stretch of open ground with no cover and no line of sight to an objective; flag tiles that can't see or be seen from anywhere useful). ✓ 255b533
- [x] Era 2 (Ruusan) versions of the wave-6 maps via `ruusanOf` (Frozen Watchpost, Smuggler Grotto, Overgrown Relay, Deepway Tunnels, etc.). ✓ 255b533
- [x] Hand-fix any layouts that still need `map-open.js` breaches, so B2 can turn it off. ✓ 255b533 (h_husks waits on E3, see STATUS)
- [x] Drop the `ROW_FIX` patches by moving fixes into the owning map data. ✓ 255b533

## V2 · Visuals (3D)
- [x] Shell-zone and sapper-timer warnings are 2D-only: show them on the 3D board (zones + countdown labels). — cff9c89
- [x] Map marks: soft glow on mark planes; red beacon prop at enemy entry points (M→G). — cff9c89
- [x] Recruit looks on models: use `u.kit.look` and `u.kit.species` (skin tone / head shape / lekku / horns where cheap) on 3D figures and portraits. — cff9c89
- [x] Meshy coverage: Defender and Shieldbearer still use default models; check every class and enemy kind has a model; generate missing ones with the Meshy account (Jess pays for it). — b1b1256
- [x] Cinematics pass (feedback item 6): kill cam, ability cams, mission intro; respect reduced motion. — cff9c89

## K2 · Kits & AI
- [x] (5caeee7) Tree abilities still living in `PROG_AB` (flurry, shadowStep, mightyBlow, …): move them into the real ability engine; add the wishlist ones (Hold the Line, …) from STATUS P→X.
- [x] (5caeee7) Test bot uses the corner-peek rule (M→K) so balance numbers match real play.
- [x] (5caeee7) "Lost"-style swarms / free-action chains for Force horrors (feedback item 7) — design with Jess first via the form.

## A2 · App & onboarding (ask Jess first)
- [x] Install as an app: proper manifest, service worker, offline shell, home-screen icon, full-screen; saves kept. (4078e69)
- [x] Easier start: a guided first mission / tutorial for a new campaign. (4078e69; Jess chose minimal: Show tips? on the new-campaign screen + one controls card)
