# Temple Watch — Story & Characters Spec (Chat C)

Written 2026-10-12. Owner: Chat C. Coordinator pastes JSON; numbers are placeholders that spec B (economy) tunes.

## 0. Decisions (lead with these)

| # | Decision | Why |
|---|---|---|
| D1 | **Era 1 moves to ~3,660 BBY.** Era boss = stop the Sith Empire's strike on Coruscant (canon: Temple sacked 3,653 BBY). | Legends puts the sacking 53 yrs before our old 3,600 date. Jess's call 2026-10-12. Sacking date: sourced, Legends, Med-High. |
| D2 | **Locked "no Temple sacking" holds:** the Era 1 boss is fought *off* the Temple (spaceport intercept). Losing it = "Temple scarred" (wing damage, Favor loss), never a sacked Temple. | Keeps the lock while making the canon event the stake. |
| D3 | **Canon: loose fan-fic.** Use Legends + Disney Canon names freely. Dates still get a confidence tag (lore is easy to misdate). | Jess's call. |
| D4 | **Finale = critical-mission chain.** Era 4 ends with 3 critical missions; their results + run variables pick the ending. Order 66 is never played; if it happens it's a text scene. | Jess's call. |
| D5 | **One master variable: `shadow` (0–10, start 6).** How strongly the vision is coming true. Era outcomes move it. Plus `orderDark` (existing) and a few flags. | One number Jess can read; easy to balance. |
| D6 | **Prototype text fixes for Coordinator:** briefing says "~3,600 BBY" → "~3,660 BBY"; "Imperial Sith troopers" fine (Great Galactic War, pre-treaty). | Matches D1. |

Confidence key used below: **H/M/L**. Source tags: **C** = Disney Canon, **L** = Legends. Lore checked 2026-10-12 against Wookieepedia mirrors (starwars.archivum.wiki); anything unchecked is marked "recall".

---

## 1. The vision arc

**Opening (3,660 BBY).** The Council meditates together. All of them see the same thing: the Temple burning, clone soldiers on its steps, a hooded figure in a red-lit office, a boy in black. Nobody knows when. It is "far". Grand Master Zym orders it recorded and sealed in the Archives. *That sealed record is the campaign.*

Each era reveals one more **shard** of the vision (shown as a 2–3 line text scene at era start) and offers one big way to bend it.

| Era | Shard revealed | Bend opportunity | shadow change |
|---|---|---|---|
| 1 Old Republic | Fire, a red blade, a treaty signed in smoke | Stop the strike on Coruscant (boss) | Win −1 · Lose +1 |
| 2 Ruusan | One Sith survives the dark; "always two" | Kill or capture Darth Bane after the thought bomb | Bane dead −3 · captured −2 · escapes +1 |
| 3 High Republic | A beacon falls; Jedi turn inward, afraid | Save Starlight Beacon and the Order's nerve | Saved −1 · Lost +1 |
| 4 Clone Wars | Chips in soldiers' heads; the office has a name | Finale chain (sec. 4) | Each critical win −1 / loss +1 |

**Rules**
- `shadow` 0–10, start 6. Clamp.
- `orderDark` ≥ 15 at any era end: shadow +1 (the Order is feeding the vision).
- Ignored crises (spec B) can add +1 shadow per era, capped at +2.
- Shown to player as the **Vision** meter: "The fire is faint / clear / certain." No raw number unless Info is on.

**Big swing: Bane dead at Ruusan.** No Rule of Two → no Sidious line. Era 4 still happens (the Republic still rots; Dooku still falls), but the hidden Sith Lord is replaced by **"The Hollow Throne"**: Separatist backers + a dark cult with no master. Finale mission 2 changes (sec. 4). This is the "rewrite history" payoff.

---

## 2. Eras

Text caps (phone): scene text ≤ 280 chars, choice label ≤ 32 chars, effect line auto-generated.

### Era 1 — The Cold Treaty (~3,660–3,653 BBY)

**Premise.** The Great Galactic War is grinding toward peace talks on Alderaan. The Empire wants the treaty *and* a lesson. The Council's vision is fresh.
**Era boss.** Darth Malgus (L, H), leading the Coruscant strike team. Fights as a heavy dark-side unit (no duel).
**Factions.** Sith Empire troopers, Imperial agents, Mandalorian clans hired by the Empire (L, M), Hutt-backed pirates.

| # | Mission | Type | Hook | Outcome hooks |
|---|---|---|---|---|
| S1 | **Relay Aurek-7** (existing prototype) | Defend | Hold the frontier relay. Intel from prisoners mentions "the talks are a feint". | +intel per prisoner; flag `e1_feint_hint` if ≥2 prisoners |
| S2 | **The Envoy's Trail** | Investigate | A Republic envoy is leaking talk schedules. Track him across a lower-city district. | Capture envoy → flag `e1_strike_known` (boss gets +2 prep turns). Kill → no flag, Darkness +1 to killer |
| S3 | **Docking Ring Nine** (boss) | Assault | Malgus's shuttle lands at a Coruscant docking ring while the treaty is signed. Stop him before he reaches the Temple. | Win: Temple untouched, shadow −1, Favor +. Lose: "Temple scarred" — lose 1 built wing upgrade, Favor −, shadow +1 |

### Era 2 — The Army of Light (~1,003–1,000 BBY)

**Premise.** The Order is now an army. Lord Hoth's Army of Light fights Lord Kaan's Brotherhood of Darkness on Ruusan. Jedi wear "Lord" titles; Council worries the war is changing them.
**Era boss.** Lord Kaan (L, H — full name Skere Kaan) and his thought bomb. **Hidden target:** Darth Bane (L, H), who survives in canon.
**Factions.** Sith Lords of the Brotherhood, dark-side cultists, mercenaries, Force horror: **Sith spirits** in the caves.

| # | Mission | Type | Hook | Outcome hooks |
|---|---|---|---|---|
| S1 | **Ravine of the Wounded** | Rescue | Pull Army of Light wounded out before a Sith sweep. | Each rescued Jedi = +1 Recruit; Farfalla loyalty + |
| S2 | **Kaan's Caves** | Investigate | Prisoner says the Brotherhood is gathering in caves. Find out why. | Find the ritual tablet → flag `e2_bomb_known`; spot a lone Sith leaving → flag `e2_bane_seen` |
| S3 | **The Thought Bomb** (boss) | Assault | Break the ritual before it fires. With `e2_bane_seen`, a 2nd objective: catch Bane on the ridge. | Ritual broken: Hoth survives (Council seat). Bane killed / captured / escapes (sec. 1). |

Canon note: thought bomb killed Hoth and Kaan; Bane survived and founded the Rule of Two (L, H). Farfalla led the Jedi after (L, H).

### Era 3 — Light and Life (~232–230 BBY)

**Premise.** The High Republic. Outer Rim expansion, Starlight Beacon, a confident Order. Then the Great Hyperspace Disaster (C, H — 232 BBY), the Nihil, and things that eat the Force.
**Era boss.** Marchion Ro, Eye of the Nihil (C, H). With him: **the Leveler** (a Nameless) as a Force horror unit — only harms Force users; troops immune (design lock).
**Factions.** Nihil raiders, Drengir (carnivorous plant hive, C, recall-M), Nameless.

| # | Mission | Type | Hook | Outcome hooks |
|---|---|---|---|---|
| S1 | **Hetzal Fragments** | Rescue | Debris rains from hyperspace. Get civilians out of the impact zone. | Favor +; Avar Kriss notices your squad (rare-recruit unlock) |
| S2 | **The Fair at Valo** | Defend | Nihil hit the Republic Fair (C, M ~231 BBY). Protect VIPs and the Chancellor's stand. | Chancellor saved → Favor ++; captured Nihil → flag `e3_ro_identity` |
| S3 | **Starlight Beacon** (boss) | Defend → evacuate | The station is sabotaged; Nameless aboard. Hold sections, evacuate, survive. Troops carry the fight. | Beacon saved: shadow −1, Order morale +. Lost: shadow +1, every Jedi gains fear (−aim 1 mission). Fall date C, M ~230 BBY |

Phase II (~382 BBY, Path of the Open Hand, "the Mother") (C, M) → **optional side-arc events only**, not a full era.

### Era 4 — The Clone Wars (~22–19 BBY)

**Premise.** War with the Separatists. Jedi are generals. The Senate keeps granting the Chancellor more power. The vision is now *clear*.
**Era boss.** Count Dooku (C, H) for the story missions; the finale chain decides the real ending.
**Factions.** Separatist droids, bounty hunters, Dooku's assassins, clones (as allies; enemies only in the bad ending text).

| # | Mission | Type | Hook | Outcome hooks |
|---|---|---|---|---|
| S1 | **Geonosis Ridge** | Assault | The war's first day (C, H — 22 BBY). Break an artillery line. | Rex unlocks as rare recruit (C, H) |
| S2 | **Fives' Warning** | Investigate | A clone trooper says something is wrong inside his own head (C, H — inhibitor-chip arc). Protect him and get the scan. | Fives lives + scan → flag `e4_chip_proof` |
| S3 | **Dooku's Retreat** | Assault | Corner Dooku's flagship landing site. | Dooku captured → intel ++ (big clue for finale 2). Killed → orderDark +2 if a Jedi lands the blow |

---

## 3. Random events (JSON)

Effect keys (Coordinator: use exactly these; B tunes amounts):
`credits, intel, kyber, favor, recruits` (resources) · `orderDark` · `shadow` · `unitDark:{who,n}` (who = `jedi_random`, `jedi_highestDark`, `squad_leader`) · `loyalty:{seat,n}` · `flag` (string) · `recruit` (character id) · `wound:{who,turns}` · `mission` (unlock id) · `chance` (0–1; else-branch in `fail`).
Trigger types: `era_start`, `month`, `after_mission:{type?}`, `flag:<name>`, `stat:{key,op,val}`.

```json
[
 {"id":"e1_mando_blockade","era":1,"trigger":{"type":"month","min":2},"text":"Mandalorian clans in Imperial pay are choking a Republic supply lane. The Navy asks for Jedi. The Senate asks you to stay out.","choices":[{"label":"Send a squad","effects":{"mission":"side_mando_lane","favor":-1}},{"label":"Pay the clans off","effects":{"credits":-60,"favor":1}},{"label":"Ignore it","effects":{"credits":-30,"shadow":0}}]},
 {"id":"e1_gnost_archive","era":1,"trigger":{"type":"era_start"},"text":"Master Gnost-Dural asks to copy the Archives to a hidden colony, in case the Temple falls.","choices":[{"label":"Approve the copy","effects":{"credits":-40,"flag":"archive_backup"}},{"label":"The Temple won't fall","effects":{"loyalty":{"seat":"gnost","n":-1}}}]},
 {"id":"e1_prisoner_offer","era":1,"trigger":{"type":"stat","key":"intel","op":">=","val":3},"text":"A captured Imperial officer offers names of Republic traitors in exchange for a ship.","choices":[{"label":"Deal","effects":{"intel":2,"favor":-1,"flag":"e1_traitors"}},{"label":"Hand him to the Navy","effects":{"favor":1}},{"label":"Make him talk","effects":{"intel":3,"unitDark":{"who":"jedi_random","n":2}}}]},
 {"id":"e1_satele","era":1,"trigger":{"type":"after_mission","min":3},"text":"A young Knight, Satele Shan, asks to join your strike teams. Her master disagrees.","choices":[{"label":"Take her","effects":{"recruit":"satele_shan","loyalty":{"seat":"darach","n":-1}}},{"label":"Respect her master","effects":{"loyalty":{"seat":"darach","n":1}}}]},
 {"id":"e1_treaty_vote","era":1,"trigger":{"type":"flag","flag":"e1_strike_known"},"text":"You know the strike is coming. Warn the Senate (and maybe the Empire's spies), or keep it inside the Order?","choices":[{"label":"Warn the Senate","effects":{"favor":2,"intel":-1}},{"label":"Keep it secret","effects":{"flag":"e1_ambush_ready","favor":-1}}]},
 {"id":"e1_kyber_trade","era":1,"trigger":{"type":"month","min":1},"text":"A Hutt broker has Ilum-grade crystals. Price: look away from his spice run.","choices":[{"label":"Buy, look away","effects":{"kyber":2,"orderDark":1}},{"label":"Refuse","effects":{}},{"label":"Seize them","effects":{"kyber":2,"mission":"side_hutt_raid","favor":-1}}]},

 {"id":"e2_lord_titles","era":2,"trigger":{"type":"era_start"},"text":"Army of Light Jedi call themselves Lords and give orders like generals. Some Masters hate it.","choices":[{"label":"Keep the titles","effects":{"recruits":2,"orderDark":1}},{"label":"Drop them","effects":{"loyalty":{"seat":"hoth","n":-1},"orderDark":-1}}]},
 {"id":"e2_deserter","era":2,"trigger":{"type":"month","min":1},"text":"A Brotherhood apprentice walks into camp, unarmed, asking for mercy.","choices":[{"label":"Accept him","effects":{"recruit":"redeemed_apprentice","chance":0.7,"fail":{"wound":{"who":"squad_leader","turns":2}}}},{"label":"Imprison him","effects":{"intel":2}},{"label":"Turn him away","effects":{}}]},
 {"id":"e2_child_soldiers","era":2,"trigger":{"type":"after_mission","min":2},"text":"Villages are sending their teenagers to fight for the Army of Light. You need the numbers.","choices":[{"label":"Send them home","effects":{"recruits":-1,"favor":1}},{"label":"Rear duties only","effects":{"recruits":1}}]},
 {"id":"e2_cave_whispers","era":2,"trigger":{"type":"after_mission","type_is":"investigate"},"text":"A Jedi from the caves can't stop hearing a voice. It promises strength.","choices":[{"label":"Halls of Healing","effects":{"wound":{"who":"jedi_highestDark","turns":2},"unitDark":{"who":"jedi_highestDark","n":-2}}},{"label":"Listen to it","effects":{"unitDark":{"who":"jedi_highestDark","n":2},"intel":2}}]},
 {"id":"e2_farfalla","era":2,"trigger":{"type":"month","min":2},"text":"Lord Farfalla wants to pull the army back to save lives. Lord Hoth wants one last push.","choices":[{"label":"Back Hoth","effects":{"loyalty":{"seat":"hoth","n":1},"loyalty_2":{"seat":"farfalla","n":-1},"flag":"e2_push"}},{"label":"Back Farfalla","effects":{"loyalty":{"seat":"farfalla","n":1},"recruits":1}}]},
 {"id":"e2_bane_rumor","era":2,"trigger":{"type":"flag","flag":"e2_bane_seen"},"text":"Scouts saw a Sith walk away from Kaan's camp before the end. Nobody else cares.","choices":[{"label":"Assign trackers","effects":{"intel":-1,"flag":"e2_bane_tracked"}},{"label":"Focus on Kaan","effects":{}}]},

 {"id":"e3_pathfinders","era":3,"trigger":{"type":"era_start"},"text":"Republic pathfinders want Jedi escorts to map new hyperlanes. Glory, risk, and Senate goodwill.","choices":[{"label":"Send escorts","effects":{"favor":2,"mission":"side_pathfinder"}},{"label":"Temple first","effects":{"credits":30}}]},
 {"id":"e3_drengir","era":3,"trigger":{"type":"month","min":2},"text":"A farm world reports plants that hunt. The Drengir are waking.","choices":[{"label":"Burn it out","effects":{"mission":"side_drengir"}},{"label":"Quarantine","effects":{"favor":-1,"credits":-20}}]},
 {"id":"e3_nameless_sense","era":3,"trigger":{"type":"after_mission","min":2},"text":"A Wayseeker felt something empty on the last mission. Like the Force had a hole in it.","choices":[{"label":"Study it","effects":{"intel":1,"flag":"e3_nameless_known"}},{"label":"Bury the report","effects":{"shadow":1}}]},
 {"id":"e3_yoda_seat","era":3,"trigger":{"type":"era_start"},"text":"Master Yoda, one of three Grand Masters, offers to sit your Council for a time.","choices":[{"label":"Welcome him","effects":{"recruit":"yoda_council","loyalty":{"seat":"veter","n":1}}},{"label":"Let him travel","effects":{"kyber":1}}]},
 {"id":"e3_nihil_storm","era":3,"trigger":{"type":"flag","flag":"e3_ro_identity"},"text":"A captured Nihil names Marchion Ro as their Eye. The Senate wants proof before acting.","choices":[{"label":"Share the prisoner","effects":{"favor":2,"intel":-1}},{"label":"Hunt Ro quietly","effects":{"mission":"side_ro_hunt","favor":-1}}]},
 {"id":"e3_open_hand","era":3,"trigger":{"type":"month","min":4},"text":"Old records: 150 years ago a cult called the Path of the Open Hand fought the Jedi. Some of its seeds still grow.","choices":[{"label":"Read the record","effects":{"intel":1,"mission":"side_open_hand"}},{"label":"Ignore","effects":{}}]},

 {"id":"e4_generals","era":4,"trigger":{"type":"era_start"},"text":"The Senate names every Jedi a general. Refusing looks like treason. Accepting changes who you are.","choices":[{"label":"Accept command","effects":{"recruits":3,"orderDark":2}},{"label":"Advisers only","effects":{"favor":-2,"orderDark":-1}}]},
 {"id":"e4_chancellor_power","era":4,"trigger":{"type":"month","min":3},"text":"Another emergency power for the Chancellor. Your Council seat can speak against it.","choices":[{"label":"Speak against it","effects":{"favor":-2,"flag":"e4_opposed_power","shadow":-1}},{"label":"Stay silent","effects":{"favor":1}}]},
 {"id":"e4_anakin","era":4,"trigger":{"type":"after_mission","min":3},"text":"Anakin Skywalker wants a mission without oversight. He's brilliant. He's also angry.","choices":[{"label":"Give him trust","effects":{"recruit":"anakin","loyalty":{"seat":"kenobi","n":1},"flag":"e4_anakin_trusted"}},{"label":"Keep him close","effects":{"loyalty":{"seat":"kenobi","n":-1}}}]},
 {"id":"e4_clone_rights","era":4,"trigger":{"type":"after_mission","min":2},"text":"A clone sergeant asks why his brothers can't refuse an order. Nobody has a good answer.","choices":[{"label":"Hear him out","effects":{"intel":1,"flag":"e4_clones_trust"}},{"label":"Not our business","effects":{}}]},
 {"id":"e4_ventress","era":4,"trigger":{"type":"month","min":4},"text":"Asajj Ventress, cut loose by Dooku, offers what she knows. For a price.","choices":[{"label":"Pay her","effects":{"credits":-80,"intel":3}},{"label":"Arrest her","effects":{"mission":"side_ventress"}}]},
 {"id":"e4_kamino_audit","era":4,"trigger":{"type":"flag","flag":"e4_chip_proof"},"text":"The chip scan is real. Remove chips army-wide (slow, loud) or quietly in your units only?","choices":[{"label":"Army-wide","effects":{"favor":-3,"flag":"chips_all"}},{"label":"Our units only","effects":{"flag":"chips_partial"}}]}
]
```

Coordinator notes: `loyalty_2` = second loyalty change (rename if you prefer an array). `type_is` in a trigger filters by mission type.

---

## 4. Finale: the critical chain (Era 4, ~19 BBY)

Unlocks after Era 4 S3. Three missions in a row. **Can't skip. No retries.** Units lost here are lost for the ending.

| # | Mission | Type | Win needs | Win effect | Lose effect |
|---|---|---|---|---|---|
| F1 | **The Chips** | Assault (Kamino lab) | Hold the lab 6 turns, destroy the chip records | flag `chips_all` (if not already); shadow −1 | shadow +1 |
| F2 | **The Name** | Investigate (Coruscant underworks) | Reach 3 data caches. Needs intel ≥ 6 to show the 3rd cache. With Bane dead: target is the Hollow Throne cult, not Sidious | flag `sith_named`; shadow −1 | shadow +1 |
| F3 | **The Office** | Assault (Senate district) | Squad vs Red Guards + droids; reach the Chancellor's office with `sith_named`. Without `sith_named` → becomes **Exodus**: protect a starport while Jedi flee | flag `sith_arrested` | shadow +2 |

Text only, never playable: Knightfall/Order 66, the Temple burning.

---

## 5. Endings

Decided at finale end, top to bottom; first match wins.

| Ending | Condition | Gist |
|---|---|---|
| **The Dark Council** | orderDark ≥ 20 | The Jedi win and take the Republic. The vision didn't come true; something worse did. |
| **Dawn Unbroken** | `sith_arrested` and `chips_all` and shadow ≤ 3 | Sith exposed and arrested, clones freed. The vision is sealed back in the Archive, unfulfilled. Best ending. |
| **The Vision Fades** (Bane-dead run) | Bane killed in Era 2 and shadow ≤ 4 | No Sith line ever came. The war ends in a messy peace. Quietest win. |
| **The Long Exile** | `sith_arrested` false, shadow ≤ 6 | The Order escapes before the order comes. Temple stands, empty. The Jedi rebuild far away. |
| **Grey Peace** | `sith_arrested` true but chips not all removed | The Sith fall, but some clones still carry the chips. Peace with a loaded weapon in the room. |
| **The Fire** | otherwise | The vision comes true. Text only. Your fallen heroes enter the Archive of Legends. |

---

## 6. Canon cameos per era

Roles: **Council** (seat with perk + vote), **NPC** (scenes, quest giver), **Rare** (recruitable, rare). Dates: H/M/L.

| Era | Name | Role | Tag | Date conf | Note |
|---|---|---|---|---|---|
| 1 | Grand Master Zym | Council | L | M | Died in the canon sacking; survives if you win |
| 1 | Gnost-Dural | Council (Archives) | L | H | Kel Dor historian, active ~3,685–3,628 BBY |
| 1 | Kao Cen Darach | Council | L | M | Satele's master (recall) |
| 1 | Satele Shan | Rare (Jedi) | L | H | Grand Master by ~3,645 BBY; young Knight here |
| 1 | Jace Malcom | Rare (troop) | L | M | Republic soldier hero (recall) |
| 1 | Darth Malgus | Boss | L | H | Led the sacking with Lord Adraas |
| 2 | Lord Hoth | Council | L | H | Leads Army of Light; dies in bomb in canon |
| 2 | Valenthyne Farfalla | Council | L | H | Leads Jedi after Ruusan |
| 2 | Johun Othone | Rare (Jedi) | L | H | Built the Ruusan memorial |
| 2 | Lord Kaan | Boss | L | H | Thought bomb |
| 2 | Darth Bane | Hidden target | L | H | Rule of Two founder |
| 3 | Pra-Tre Veter | Council | C | M | One of three Grand Masters in 232 BBY |
| 3 | Yoda | Council (event) | C | M | Also a Grand Master then; **born 896 BBY (C/L, M)** — first era he can appear |
| 3 | Stellan Gios | Council (mid-era) | C | M | Joins Council ~231 BBY |
| 3 | Avar Kriss | Rare (Jedi) | C | H | Marshal of Starlight Beacon |
| 3 | Elzar Mann | NPC | C | H | Kriss's friend; Darkness-flavored quests |
| 3 | Marchion Ro | Boss | C | H | Eye of the Nihil |
| 4 | Yoda, Mace Windu, Ki-Adi-Mundi, Plo Koon, Shaak Ti, Obi-Wan Kenobi | Council | C | H | Kenobi's seat timing: M |
| 4 | Anakin Skywalker | Rare (Jedi), high Darkness risk | C | H | Starts at Darkness 3 |
| 4 | Ahsoka Tano | Rare (Jedi) | C | H | Padawan; bond with Anakin |
| 4 | Captain Rex | Rare (troop) | C | H | From Era 4 S1 |
| 4 | Fives | NPC | C | H | Chip arc |
| 4 | Count Dooku | Boss | C | H | |
| 4 | Palpatine | NPC (hidden) | C | H | Never shown as a fight unless F3 |

Rare-recruit rule: max 1 canon rare per era, appears via event or mission unlock, dies like anyone else. A dead canon character can't return except as an Archive ghost.

---

## 7. Bonds, rivalries, personal quests

**Bonds** (pair of units, level 0–3)
| Gain | +1 |
|---|---|
| Revive or carry the other out | yes |
| 3 missions together, both survive | yes |
| Master + Padawan | starts at 2 |

| Level | Effect (in mission) |
|---|---|
| 1 | +5 aim when within 3 tiles |
| 2 | Free reaction shot/strike when partner is hit (1×/mission) |
| 3 | Partner death: other gains Fear (−10 aim 2 missions) **or** Darkness +2 (Jedi, player picks in a text scene) |

**Rivalries** (level 0–2): triggered by a promotion one got over the other, opposite Darkness (gap ≥ 5), or a kill-vs-capture argument (text event). Rival within 3 tiles: both +5 crit, −5 aim. Resolved by a personal quest or one saving the other.

**Personal quests** (one active per unit; offered at rank 2; text event → side mission)
| Template | Who | Reward |
|---|---|---|
| Crystal calling | Jedi | Unique kyber (saber perk) |
| Lost family | Troop | Free recruit + stat bump |
| Fallen master | Jedi whose master died | Relic from master; or Darkness +2 if they choose revenge |
| Old debt | Troop | Credits or a Hutt contact |
| Dark whisper | Jedi with Darkness ≥ 5 | Cleanse (Darkness −4) or embrace (+power, +3 Darkness) |
| Homeworld burns | Any | Favor + local intel source |

---

## 8. Archive of Legends

- **Who enters:** any unit that dies or retires at rank ≥ 2, plus every canon character who dies. Saved in the save file, shared across runs.
- **What it holds per entry:** name, class, era, cause, top kill/capture stat, one-line epitaph (auto from template).
- **Next run:** the game draws 3 entries at random at campaign start.
  - **Relic** (troop or Jedi): a gear item with their name (+1 stat).
  - **Ghost** (Jedi only, Darkness < 5 at death): once per run, a mission-start text scene + free Focus refill for one Jedi.
  - **Lore** (anyone): unlocks one event mentioning them.
- Cap 30 entries; oldest drops off. Jess can pin up to 5.

---

## 9. Voice

- Hopeful but costly. Wins have a price shown in the same breath.
- Short sentences. Present tense in scenes. No speeches.
- Named characters get one verbal habit max (Gnost-Dural: dry historian asides; Hoth: blunt soldier).
- No modern slang, no jokes at death.
- Debrief lines: one sentence of result + one of cost.

Sample lines:
- "The relay held. Three of them didn't come home."
- "You stopped the shuttle. The treaty was still signed in smoke."
- "He surrendered. You let him. The Order will remember both."

---

## 10. Handoff to Coordinator

1. Fix prototype dates (D6).
2. v0.2 story minimum: vision opening scene, Era 1 S1–S3, 6 Era-1 events, `shadow` meter, Archive entry on death.
3. Era 2–4 content can ship in later slices; JSON is ready.
