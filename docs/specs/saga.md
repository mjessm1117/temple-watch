# Saga: story-first layer (Era 1)

Owner: Chat Saga · 2026-10-21 · Files: `public/js/data-saga.js` (content), `public/js/saga.js` (engine), `public/css/saga.css`, `tests/saga.test.js`.

## Decisions (Jess, 2026-10-21)
| # | Decision |
|---|---|
| D1 | **Story-first.** The squad are characters with arcs; their choices change later missions and the finale. |
| D2 | Choices in **4 places**: Temple talks, mission approach (briefing), mid-mission squad beats, aftermath (debrief). |
| D3 | **Era 1 deep first.** Prove it's fun before writing Eras 2–4. The layer switches off when `C.era>1`. |

## The four touch points
| Where | What the player sees | Rules |
|---|---|---|
| **Temple talks** | "Your people" strip on the Temple screen: each squad member, how they feel about you, and who "wants a word". | One optional talk per hub visit (choosing who to hear is the choice). Arc climaxes are **forced scenes** before the Temple (max 2 per visit). Each choice shows its effect, then a reply screen with the character's answer. |
| **Approach** | On the squad screen, under the squad: "As briefed" plus 2–3 plans. | Story missions have their own plans (`APPROACH[id]`); crises and personal missions share 3 generic ones. Costs paid at launch. Default "As briefed" = no change (keeps bot balance stable). |
| **Squad beats** | On turn 2 or 3, a squad member speaks in the comm box with a 2-way choice. | One per mission; each beat once per era; needs that character in the squad. Battle effect now (`do`), campaign effect after the mission (`saga`). |
| **Aftermath** | A decision scene back at the Temple: prisoners, blame, rewards. | Every story mission (win and lose). Won crises 50%, each type once per era. A cast death queues a grief scene from the survivor who trusts you most. |

## Trust
Per character, −3…+3, shown as words (distant · wary · steady · warm · trusts you). ≥2: +5 aim in battle. ≤−2: −5 aim. Talks, beats and aftermath move it.

## Cast arcs (Era 1) [N] unless noted
| Character | Arc | Payoff at Docking Ring Nine |
|---|---|---|
| Kira Venn (Knight) | Has the Council's vision herself. Tell / report / dismiss → draws the ring → hangar climax. | Foresight: +1 lift lock. Watching the docks alone: Malgus starts −2 HP. |
| Tor Saalen (Padawan) | Homeworld burned. Counsel or stoke the anger; a mid-mission revenge beat; the eve of the Trials. | Light: Jedi +1 Focus. Shadow: Tor +10 aim. |
| Sgt. Rhal Dax | 47, last tour, daughter flies gunships. Keep him, send him to teach, or ignore the shake; daughter missing over Alderaan. | Daughter found (65%): gunship strafes. Sent home: one of his recruits joins. |
| Ilsa Myr (Scout) | Reports to the SIS (Republic Intelligence, Legends High). Confront / watch / ignore → double agent, pay her debt, or dismiss. Ignoring it leaks your tactics. | SIS tip: enemies −5 aim. Leak: enemies +5 aim (fixable for 2 Intel). |
| Doc Bren (Medic) | "Wounded is wounded." Treats enemies; funds a free clinic; patients repay him. | Tunnels: one enemy squad never arrives. |
| Grak Ordo (Heavy) | Exiled from Clan Ordo (Legends High), who fight for the Empire. Parley beat vs Mandalorians; the clan calls him home. | Clan stays out: one enemy squad never arrives. |
| Satele Shan, Jace Malcom, Varra Ordo | One talk + one beat each when they join. | Epilogue only. |

Personal missions (unlocked by talks; stay on the galaxy list, never expire other options, never advance the plan): **The Dead Drop** (Ilsa), **The Clinic Raid** (Bren), **Clan Ordo's Proving Ground** (Grak). Mirrored layouts of existing maps.

## Data shapes
See the header of `data-saga.js`. Effects reuse story.js `applyFx` keys plus `t`, `trust`, `dark`, `stress`, `retire`, `teach`, `away`, `personal`, `chance/fail`. Conditions: `done`, `act`, `flag`, `notFlag`, `anyFlag`, `need`, `minT/maxT`.

## Hooks (no edits to other chats' files)
Wraps `baseScreen`, `squadScreen`, `launchMission`, `startMission`, `bvFire`, `bvPick`, `applyResults`, `optionsFor`, `battleUnit`; prepends to `EPILOGUE`. Squad beats ride battle.js's comm box queue (`S.bv.q`), so the test bot answers them like any beat.

## Next (not done)
- Eras 2–4 cast arcs (Ruusan Army of Light squad, etc.) once Jess has played Era 1.
- Bonds: arcs could feed `C.bonds` (temple.js) — e.g. Tor↔Kira on `tor_kira`.
- Voice: cast lines could replace generic barks (`HERO_BARKS`) per arc state.
