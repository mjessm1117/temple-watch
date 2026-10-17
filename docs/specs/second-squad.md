# Second playable squad — Chat I, designed 2026-10-16, **built 2026-10-17** (`public/js/twin.js`, numbers in `TWIN`, data-galaxy.js)

Built as designed with one change: unlock is **Barracks L2** (there is no Hangar wing yet) or Era 2+. Front B's mission has 1 fewer rank-and-file foe (4 units vs a map tuned for 6). Rescue-with-captives crises can't be auto-resolved.

Goal: late game, the Order fights on two fronts at once. You command two full squads; each one is a real battle you play.

## Decisions (defaults; change freely)
| # | Decision | Status |
|---|---|---|
| 1 | Unlocks with **Hangar L2** (spec B §2: "2 builds at once") or Era 2 Act II, whichever comes first | [Default] |
| 2 | Squad B is **smaller: 4 units, 0–2 Jedi**. Squad A stays 6 / 1–3 Jedi | [Default] |
| 3 | A unit belongs to one squad per plan step. Field ops (2–3 units, off-screen) still exist alongside | [Default] |
| 4 | Two-front steps only: a plan step marked `twin:1` offers two crises you can **both** take | [Default] |
| 5 | Play order: A then B, one after the other. No real-time switching mid-battle | [Default] |
| 6 | Squad B can **auto-resolve** instead (field-op roll using its ranks, 70% max) if you'd rather not play it | [Default] |

## Flow
1. Galaxy map on a twin step shows 2+ crises with a gold "Two fronts" banner.
2. Pick crisis A → squad screen (6 slots). Pick crisis B → squad screen (4 slots, units in A greyed out).
3. Launch: battle A plays. Its debrief has "Next: front B" instead of "Return to the Temple".
4. Battle B plays (or auto-resolves). One combined debrief, then **one** `advance()` (time passes once: 15 days).
5. Ignored-crisis penalties only hit crises neither squad took.

## Why this shape
- Two battles back-to-back keep the engine single-mission (`S` stays one battle); only the campaign layer changes.
- Smaller B forces a real split of veterans, which is the point (XCOM 2: Long War's multiple squads [I, Med]).
- Auto-resolve keeps it optional for players who only want one fight per step.

## Code impact (estimate, Med confidence)
- `C.twin={a:{opt,squad},b:{opt,squad},stage}` in campaign state; `chooseOption` skips ignore penalties for the second pick.
- `applyResults` gains `{noAdvance:1}` for battle A; `advance()` runs after B. ~80 lines in campaign.js + base.js.
- Squad screen: a slot count argument (6 or 4) and greyed units already in A. ~20 lines.
- Galaxy: twin banner + two "chosen" pin states. ~30 lines in galaxy.js.
- Save: `S` for battle B is created after A's results are applied, so a reload never repeats A.
- Tests: campaign bot takes both fronts on twin steps; check time advances once and both squads earn XP.

## Open questions for Jess
1. Two battles per step doubles session length. OK, or only on 2–3 marked steps per era? (default: 2 per era)
2. Should a lost front B have a bigger penalty than an ignored one? (default: same as a normal loss)
