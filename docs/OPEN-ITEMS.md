# Open items — Wave 7 (2026-10-22)

Every open request, bug and "not done" note from STATUS/CHANGELOG/FEEDBACK, one owner each. Tick `[x]` and add the commit hash when shipped. E2 (Coordinator) keeps this file current and closes the wave when all boxes are ticked or explicitly dropped by Jess.

Already closed this week (don't redo): armor pips, Padawans (bond 2 start), voices, nicknames, 3D camera + aim view, XCOM HUD, phone landscape, Temple ziggurat/spires/undercroft/wing actions, hack rewards, graze, flank preview, melee charge, Mind Trick turns foes, shield prop, vault hop arc, loot/flare markers, loot credits banked, new Sith schemes, Era 3.

## E2 · Coordinator (integration, tests, Temple, HUD)
- [ ] Campaign test flake: rescue chain can loop past 24 missions (~1–2 in 8 runs). Find the cause, fix it.
- [ ] campaign.test.js should spend like a player (it still clicks the dead `[data-act="hire"]`); bot buys gear/wings so the economy is really measured.
- [ ] Temple roster cards: show Tired (`isTired(r)`) and team name (`teamOf(r.id)?.n`) badges.
- [ ] Fold adjacency (`adjSum`) into campaign.js/temple.js instead of additive hooks (low priority; only if it simplifies).
- [ ] Front A squad gets benched-stress relief at the shared time step (Chat I known gap).
- [ ] Forge: confirm it has a real effect (old note "no effect until crafting"); fix if not.
- [ ] Clean stale notes at the top of STATUS.md ("Next (v0.2b)" etc.); keep STATUS short.
- [ ] Optional cleanup: rename the floating-text `fx(p,txt,cls)` path to `floatText` (F→E).
- [ ] Merge, run full `npm test`, push; close this file.

## B2 · Balance
- [ ] Balance recheck after the stat rework + this week's changes: armor pips (tanks much weaker), melee charge, graze, hack, wing-action buffs, spires. Measure with the bot; numbers in `CLASS`, `ARMOR`, `MELEE`, `GRAZE`, `MOD_ACTS`, `SPIRES`.
- [ ] Strike-team auto-resolve odds (first-pass 62–70%): measure and tune `TAUTO`/`FATIGUE`.
- [ ] Malgus win rate (old: Normal ~27%, Story ~67% weak bot) and Ossus Vault (~50–60%, Threat-limited): re-measure, tune to spec A bands.
- [ ] With M3: once layouts are validated, re-run full balance and turn off `map-open.js` auto-breaches (`OPEN.off=true`) if bands hold.

## M3 · Maps
- [ ] Add a sightline / blind-spot metric to `tests/mapcheck.test.js` (no long stretch of open ground with no cover and no line of sight to an objective; flag tiles that can't see or be seen from anywhere useful).
- [ ] Era 2 (Ruusan) versions of the wave-6 maps via `ruusanOf` (Frozen Watchpost, Smuggler Grotto, Overgrown Relay, Deepway Tunnels, etc.).
- [ ] Hand-fix any layouts that still need `map-open.js` breaches, so B2 can turn it off.
- [ ] Drop the `ROW_FIX` patches by moving fixes into the owning map data.

## V2 · Visuals (3D)
- [ ] Shell-zone and sapper-timer warnings are 2D-only: show them on the 3D board (zones + countdown labels).
- [ ] Map marks: soft glow on mark planes; red beacon prop at enemy entry points (M→G).
- [ ] Recruit looks on models: use `u.kit.look` and `u.kit.species` (skin tone / head shape / lekku / horns where cheap) on 3D figures and portraits.
- [ ] Meshy coverage: Defender and Shieldbearer still use default models; check every class and enemy kind has a model; generate missing ones with the Meshy account (Jess pays for it).
- [ ] Cinematics pass (feedback item 6): kill cam, ability cams, mission intro; respect reduced motion.

## K2 · Kits & AI
- [x] (5caeee7) Tree abilities still living in `PROG_AB` (flurry, shadowStep, mightyBlow, …): move them into the real ability engine; add the wishlist ones (Hold the Line, …) from STATUS P→X.
- [x] (5caeee7) Test bot uses the corner-peek rule (M→K) so balance numbers match real play.
- [x] (5caeee7) "Lost"-style swarms / free-action chains for Force horrors (feedback item 7) — design with Jess first via the form.

## A2 · App & onboarding (ask Jess first)
- [x] Install as an app: proper manifest, service worker, offline shell, home-screen icon, full-screen; saves kept. (4078e69)
- [x] Easier start: a guided first mission / tutorial for a new campaign. (4078e69; Jess chose minimal: Show tips? on the new-campaign screen + one controls card)
