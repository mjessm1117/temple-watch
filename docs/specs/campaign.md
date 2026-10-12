# Spec B — Campaign & Base (Temple Watch)

Author: Chat B · 2026-10-12 · For: Coordinator (E). Numbers are first-pass; tune after play.
Labels: **[Locked]** = Jess decided · **[Default]** = my call, change freely · **[Lore]** = canon claim + confidence.

## 0. Decisions (read this first)
| # | Decision | Status |
|---|---|---|
| 1 | Time = **calendar months** on galaxy map; crises spawn with expiry; you can't answer all | [Locked 10-12] |
| 2 | **~12 missions per era**, 4 eras → ~48 missions + 4 bosses ≈ 12–14 h | [Locked 10-12] |
| 3 | **Never lose.** No game over. Bad play bends toward darker endings + harder next era | [Locked 10-12] |
| 4 | v0.2 = **mini-era: 5 missions + boss** (Old Republic) | [Locked 10-12] |
| 5 | Each era = 3 **Acts** of ~4 missions; between Acts a **"Years pass" jump (+5 yrs)** → this is where aging/promotion happens | [Default] |
| 6 | Between eras: centuries pass. Living heroes become **Legends** (Archive); Temple, research, reputation carry with decay | [Default] |
| 7 | Retirees are the glue: they **staff wings, take Council seats, or teach** a student | [Default] |
| 8 | Council = **7 seats** (canon has 12; cut for phone UI) | [Default] |
| 9 | "Never lose" floor: if roster < 4 fit units, Council grants emergency recruits (costs Favor) | [Default] |

---

## 1. Run structure

### 1.1 Shape of one era
| Phase | Months (game) | Missions | Ends with |
|---|---|---|---|
| Act I | 1–3 | 4 (1 story + 3 crises) | Years pass +5 yrs |
| Act II | 4–6 | 4 (1 story + 3 crises) | Years pass +5 yrs |
| Act III | 7–9 | 3–4 + **Boss** | Era jump |

Pace target: ~1.3 missions per game-month. One op in the field at a time (v1). Real time ≈ 12 min/mission + 3 min base.

### 1.2 Era Threat clock (boss trigger)
| Event | Threat |
|---|---|
| Each game-month | +8 |
| Each ignored/expired crisis | +5 |
| Story mission won / lost | −10 / +5 |
| Intel spent on "Disrupt" (3 Intel) | −6 |

- Boss **unlocks** at Threat ≥100 AND ≥9 missions done.
- Boss **forced** at Threat 130 or after mission 12.
- Lose boss → era still ends; history flag `boss_<era>_won=false` (darker branch, see 1.4).

### 1.3 Eras [Lore — confidence noted]
| Era | Year | Boss (placeholder for spec C) | Confidence |
|---|---|---|---|
| Old Republic | ~3,600 BBY (post-Sacking, Cold War) | Sith Inquisitor-type warlord | Med — exact Cold War dates vary by source |
| Ruusan | ~1,000 BBY | Brotherhood of Darkness lord | Med — Legends dating; canon only hints |
| High Republic | ~382–230 BBY | Nihil / Force-horror (Nameless) | High for 382 BBY Great Disaster; Med for range |
| Clone Wars | 22–19 BBY | Separatist/Sith master plan | High |

Yoda: born ~896 BBY [Lore, High] → **not alive at Ruusan**; first joinable in High Republic (~500 yrs old). README says "Yoda appears once his era arrives" — consistent.

### 1.4 Time jump between eras
| Carries | Rule |
|---|---|
| Temple wings | Each wing drops 1 level unless staffed at jump (staffed = keeps level). Min level 1. |
| Research | 100% kept (Archives are permanent). |
| Senate Favor | Moves halfway back to 50. |
| Order Darkness | Keeps 50%. |
| Credits / Intel / Kyber | Credits → 30% kept; Intel → 0; Kyber kept. |
| Units | All become **Legends** (rank ≥3) or forgotten (rank <3). Long-lived species (≥1 Yoda-type) may survive — rare recruit only. |
| History flags | All kept; next era reads them (spec C writes content). |
| Era difficulty mod | +1 enemy tier per lost boss (cap +2). |

### 1.5 Aging & retirement (per "Years pass" jump, +5 yrs)
Start ages: Padawan 14–19 · Knight 22–40 · troops 20–35.

| Unit | Rule at each jump |
|---|---|
| Padawan rank ≥2 | Takes Trials → Knight (auto unless Darkness ≥7: 50% fails, stays Padawan) |
| Knight rank ≥4, age ≥35 | May be named Master (Council vote, see §3) |
| Troop age 40–49 | Retire chance 25% |
| Troop age ≥50 | Retire 60%; ≥55 forced |
| Jedi (human) age 65–74 | Retire chance 20% |
| Jedi age ≥75 | Retire 50%; ≥85 forced |
| Any unit with wound "Grave" | Retire chance +20% |

Retiree chooses 1 (player picks): **Council seat** (if open) · **Wing staff** (+effect) · **Teacher** (next recruit of that class starts rank 2) · **Relic** (leaves gear item to Archive).
Per era: ~2 jumps × 6 roster = expect 1–3 retirements/era. That's the point.

---

## 2. Temple wings

Rules: build takes days (calendar). 1 build at a time (Hangar L2 → 2). Each wing has 1–2 **staff slots** (retirees or Council members). Staffed = bonus listed.

| Wing | Build ₡ | Days | Upkeep/mo | L1 effect | L2 (+₡) | L3 (+₡) | Staff bonus |
|---|---|---|---|---|---|---|---|
| Medical Halls | 150 | 10 | 10 | Wound heal ×1.5 | ×2, revive Grave (200) | bacta: Grave→Light (350) | +25% heal |
| Training Salle | 150 | 10 | 10 | +10% XP | Retrain abilities (200) | Train 1 unit while on bench (350) | +10% XP |
| Kyber Forge | 200 | 14 | 15 | Saber tier 2 | Saber tier 3 (300) | Legendary hilts (450) | −1 Kyber per craft |
| Armory | 200 | 14 | 15 | Troop weapon tier 2 | Tier 3 + mods slot 2 (300) | Heavy gear (450) | −20% gear cost |
| Archives | 250 | 14 | 10 | Research unlocked | 2 projects at once (300) | Legend relics usable (400) | +25% research speed |
| Comms Hub | 150 | 7 | 10 | See crisis rewards | +1 crisis option/month (250) | See enemy roster pre-mission (350) | +1 Intel/mo |
| Barracks | 100 | 7 | 5 | Roster cap 10 | Cap 14 (200) | Cap 18 + Temple Guard troops (300) | +1 recruit/mo |
| Meditation Gardens | 150 | 10 | 5 | −1 personal Darkness/month to benched Jedi | −2 (250) | Redemption quests (350) | Order Darkness −1/mo |
| Hangar | 250 | 14 | 20 | Reach Outer Rim | 2 builds at once (300) | Rapid response: answer a crisis +3 days late (400) | −5 days transit |

Start: Council Chamber (fixed) + Barracks L1 + Medical L1 free. v0.2 uses only Medical, Training, Kyber Forge, Comms Hub.

---

## 3. Economy (5 resources) [Locked list]

| Resource | Start | Income | Main sinks |
|---|---|---|---|
| Credits ₡ | 300 | Senate stipend `100 + 2×Favor`/mo; mission 40–120 | Wings, upkeep, troop gear, troop pay |
| Intel | 0 | Mission 1–3; capture +1; Comms staff +1/mo | Reveal crisis details (1), extend expiry +5 days (2), Disrupt Threat (3), research (varies) |
| Kyber | 1 | Story missions 1; "Kyber pilgrimage" crises 1–2; rare loot | Saber craft (T2: 2, T3: 4, Legendary: 6) |
| Senate Favor | 50 (0–100) | Answer Senate crises +5–10 | Ignore Senate crisis −8; dark acts −5; emergency recruits −10 |
| Recruits | 2 troops | Levy `1 + Favor/40` troops/mo; Jedi: 1 Padawan per 2 mo (+1 w/ Training Salle L2) | Hiring: troop 30₡, Padawan free |

Troop pay: 5₡/mo each. Jedi: 0.

### Sample month (Normal, mid-Act I, Favor 50)
| Line | ₡ |
|---|---|
| Stipend 100+2×50 | +200 |
| 1.3 missions × ~80 | +104 |
| Upkeep: 3 wings (10+10+5) | −25 |
| Troop pay 6 × 5 | −30 |
| **Net to spend** | **≈ +249** |
Target: affords ~1 new wing every 1–1.5 months; can't build everything in an era (9 wings × ~200 + upgrades ≈ 4,000₡ vs ≈ 2,200₡ earned/era). **Choosing is the game.**

Difficulty multipliers on income: Story ×1.3 · Normal ×1.0 · Hard ×0.85 · Legend ×0.7.

---

## 4. Council

7 seats: Master of the Order + 6. Start: 4 NPC masters + 3 empty (filled by your retirees or canon cameos from spec C).

### 4.1 Members
Each member: `stance` (Guardian / Consular / Sentinel / Wayseeker), `loyalty` 0–100 (start 60), one **seat perk** while seated.

| Stance | Votes for | Votes against | Example perk |
|---|---|---|---|
| Guardian | Assault, defend, military aid | Secret ops, retreat | +5 aim for Jedi in assault missions |
| Consular | Diplomacy, rescue, mercy | Assault, captures killed | +5 Favor on Senate crises |
| Sentinel | Investigate, intel, pragmatic deals | Open war | +1 Intel per mission |
| Wayseeker | Visions, independence, Force mysteries | Senate demands | −1 Order Darkness / 2 mo |

### 4.2 Votes
- Council matters (1–2/month; content from spec C) list options. Each member votes by stance; tie → Master of the Order.
- Player picks. If player overrides majority: every dissenter −15 loyalty.
- Agree with a member's vote: +5 loyalty.
- Loyalty <25 → member resigns at month end (seat opens). Loyalty ≥80 → perk doubled.
- Appoint: open seat → choose from Masters (your units, rank ≥5 or retired), or canon cameo. Replace: spend 10 Favor to remove a member (others −5 loyalty).

---

## 5. Progression

### 5.1 XP & ranks (all units)
| Rank | XP to reach | Jedi title | Troop title | Unlocks (spec A defines abilities) |
|---|---|---|---|---|
| 1 | 0 | Padawan | Recruit | Class kit base |
| 2 | 30 | Padawan | Private | Ability pick 1 |
| 3 | 80 | Knight* | Corporal | Ability pick 2; Legend-eligible |
| 4 | 160 | Knight | Sergeant | +1 HP, +5 aim |
| 5 | 280 | Master* | Lieutenant | Ability pick 3; Council-eligible |
| 6 | 450 | Master | Captain | +1 HP, signature ability |
| 7 | 700 | Grand Master | Commander | Capstone |
*Jedi title advances only via Trials/Council vote (§1.5), not XP alone. v0.2 = ranks 1–3 only.

XP sources: mission survived 10 · kill 5 · capture 8 · revive ally 5 · story mission +10 · boss +25. Benched in Training Salle L3: 5/mo.
Expected: a unit in every mission hits rank 3 by ~mission 6, rank 5 by end of era 1. [Estimate]

### 5.2 Wounds
| Wound | Trigger | Base days out |
|---|---|---|
| Light | Took ≥1 dmg | 3 |
| Serious | Ended ≤ half HP | 10 |
| Grave | Was downed, revived | 20 (needs Medical L2 or slow 40) |

### 5.3 Saber crafting
Saber = crystal + emitter + grip. Color = crystal (cosmetic + lore).
| Tier | Kyber | ₡ | Needs | Effect |
|---|---|---|---|---|
| T1 Training | — | — | — | Base dmg |
| T2 Attuned | 2 | 60 | Forge L1 | +1 dmg, +5 deflect |
| T3 Master-forged | 4 | 120 | Forge L2 | +1 dmg, +10 deflect, 1 trait slot |
| Legendary | 6 | 200 | Forge L3 + relic | Unique trait (from Legend) |
Traits (pick 1): Focused (+1 Focus), Swift (+1 move on strike), Guardian (+10 Guard deflect), Piercing (ignore 1 armor).

### 5.4 Troop gear
| Tier | ₡ | Needs | Slots |
|---|---|---|---|
| T1 Standard | — | — | 0 mods |
| T2 Military | 50 | Armory L1 | 1 mod |
| T3 Elite | 120 | Armory L2 | 2 mods |
Mods: scope (+10 aim), extended mag (+1 overwatch), stock (+5 aim close), hair trigger (overwatch no −15 once/mission). Armor: light (+1 HP), heavy (+2 HP, −1 move).

### 5.5 Recruit customization fields
```json
{
  "recruit": {
    "name": "string",
    "species": ["Human","Twi'lek","Mirialan","Zabrak","Togruta","Kel Dor","Rodian"],
    "age": "number (class-bound range)",
    "class": "Jedi:Guardian|Consular|Sentinel|Wayseeker  or  Troop:Soldier|Scout|Medic|Heavy",
    "origin": ["Temple-raised","Late found","Republic Army","Temple Guard","Hired"],
    "trait": ["Steady","Reckless","Compassionate","Ambitious","Curious"],
    "crystalColor": ["blue","green","yellow","purple","white"],
    "tokenColor": "hex",
    "bio": "string <=140 chars"
  }
}
```
Trait = small stat nudge + bond hooks for spec C (e.g., Ambitious +5% XP, Darkness gains +1 on choke).

---

## 6. Galaxy map

### 6.1 Regions (per era; names from spec C)
5 regions: Core · Colonies · Inner Rim · Mid Rim · Outer Rim. Each has **Unrest 0–5**.
- Unrest 5 → region "falls": no crises spawn there that pay ₡, Favor −2/mo, Threat +3/mo. Win a story or liberation mission there to reset to 3.

### 6.2 Crisis generation (each month start)
- Spawn 2–3 crises (+1 with Comms L2). Weights: region Unrest × era enemy table.
- Each crisis: type (rescue/protect · investigate · assault/defend), region, reward bundle, expiry 6–14 days, difficulty 1–3 stars.
- Story mission: 1 per Act, never expires, but Threat ticks while you wait.

```json
{"crisisTemplate":{
  "id":"or_raid_supply","era":"old_republic","type":"defend","region":"Mid Rim",
  "expiryDays":[6,10],"stars":2,
  "reward":{"credits":[60,90],"intel":1,"favor":5},
  "ignore":{"favor":-8,"unrest":1,"threat":5},
  "source":"senate"
}}
```

### 6.3 Ignored-crisis penalties
| Source | Favor | Unrest | Threat | Other |
|---|---|---|---|---|
| Senate request | −8 | +1 | +5 | — |
| Civilian | −3 | +2 | +5 | Order Darkness +1 (Jedi failed the helpless) |
| Jedi/Force | 0 | +1 | +8 | Lose possible Kyber/recruit |
| Captured unit (rescue) | 0 | 0 | +5 | Unit lost after expiry; may return as dark enemy (spec A/C) |

### 6.4 Order Darkness (0–100)
Feed: `sum(personal Darkness of active Jedi) + orderDark events` → mapped 0–100 (cap). Decays −1/mo (−more with Gardens).

| Order Darkness | Effects |
|---|---|
| 0–24 | Normal. Wayseeker members +5 loyalty/mo |
| 25–49 | Consular members −5 loyalty/mo; Choke/dark abilities −1 Focus cost |
| 50–74 | Favor −2/mo (Senate fears the Order); Padawan recruitment −50%; dark-side "Fallen" events possible |
| 75–99 | A Council member may defect; a Jedi with Darkness 10 may fall → becomes enemy unit next mission |
| 100 | Locks ending branch "The Order became the Sith it feared" (spec C); game continues (never lose) |

---

## 7. "Never lose" safety net [Locked rule, default numbers]
| Situation | Response |
|---|---|
| Mission lost | Era continues; losses + penalties stand; Threat +5 |
| < 4 fit units | Emergency levy: 3 rank-1 troops, Favor −10 |
| ₡ < 0 | Wings stop upkeep effects until paid; no debt beyond −200 |
| Squad wiped | Same as above + "Dark days" event (spec C) |
Endings read: Order Darkness, Favor, bosses won count, Temple total level, history flags, Legends count.

---

## 8. v0.2 vertical slice — "Mini-era: Aurek Campaign"

**Goal:** prove "I want to play the next mission." Old Republic only. 5 missions + boss = 6 fights, ~75–90 min.

### 8.1 Flow
```
Briefing (vision) → Base → Galaxy list → Mission → Debrief → Base … 
M1 (fixed: current relay defense) → M2 (crisis pick 1 of 2) → M3 (story)
→ YEARS PASS +5 (aging, Trials, 1 retirement roll) →
M4 (crisis pick 1 of 2) → M5 (crisis pick 1 of 2) → Boss
→ Era-end screen (Legends, flags, "To be continued: Ruusan")
```
Compressed Threat for slice: +20/month, boss unlocks after M5.

### 8.2 Must have (ship v0.2)
| Feature | Scope |
|---|---|
| Base screen | Resource bar (₡, Intel, Kyber, Favor, Recruits) + 4 wings: Medical, Training, Kyber Forge, Comms Hub |
| Galaxy | **List view only** (map later); 2 crises/month with expiry + ignore penalties |
| Calendar | Month counter, days pass per mission/build |
| Mission types | Defend (exists) + Rescue + Assault (spec A rules); maps can reuse grid with new layouts |
| Progression | XP, ranks 1–3, 1 ability pick at rank 2 and 3 (spec A list) |
| Wounds | Light/Serious/Grave days out |
| Crafting | Saber T2 + troop gear T2 (1 mod) |
| Years pass | +5 age, Padawan Trials, retirement roll, retiree → wing staff |
| Boss | One handmade map + Sith boss (spec A/C) |
| Era end | Legends list, Order Darkness, Favor, "next era" stub |
| Save | Whole campaign state in existing save/sync (size check: <500 KB) |

### 8.3 Cut from v0.2 (later)
Council votes (show seats only, static perks) · Archives/research · Hangar/Barracks/Gardens · galaxy map visuals · recruit editor (auto-generate recruits; editor in v0.3) · T3 gear · ranks 4–7 · era jump to Ruusan.

### 8.4 Slice economy (tuned so you can't buy everything)
| Item | Value |
|---|---|
| Start | 300₡, 0 Intel, 1 Kyber, 50 Favor |
| Income | ~250₡/month × ~4 months ≈ 1,000₡ + mission ≈ 500₡ |
| Wants | 4 wings L1 (650) + upgrades (≈900) + gear (≈300) ≈ 1,850₡ |
| Target | Player affords ~70% → must skip something [Estimate] |
Kyber: 1 start + 1 (M3 story) + 1 crisis = 3 → one T2 saber, not two. Deliberate.

### 8.5 Test targets (for Coordinator's sim)
| Check | Pass band |
|---|---|
| 40 sim campaigns, 0 errors | required |
| Bot reaches boss | 100% (never lose) |
| Bot wins boss on Normal | 40–60% |
| ₡ at boss | 0–300 (not hoarding, not broke) |
| Units at rank 3 by boss | 2–4 |
| Save size at boss | < 100 KB |

### 8.6 State shape (proposal for Coordinator)
```json
{
  "campaign": {
    "v": 2, "era": "old_republic", "act": 1, "month": 1, "day": 1,
    "threat": 0, "difficulty": "normal",
    "res": {"credits": 300, "intel": 0, "kyber": 1, "favor": 50, "recruits": 2},
    "orderDark": 0,
    "wings": {"medical": {"lvl": 1, "staff": []}, "training": {"lvl": 0, "staff": []}},
    "build": null,
    "roster": [{"id": "u1", "name": "Kira Venn", "cls": "Guardian", "jedi": true, "age": 28,
      "rank": 1, "xp": 0, "dark": 0, "wound": null, "woundDays": 0,
      "gear": {"saber": "T1"}, "abil": [], "status": "active"}],
    "council": [{"id": "c1", "name": "TBD", "stance": "Consular", "loyalty": 60, "perk": "favorSenate"}],
    "crises": [], "missionsDone": 0, "flags": {}, "legends": [], "battle": null
  }
}
```
Existing battle state `S` nests under `campaign.battle` while a mission is live.

---

## 9. Open questions for Jess (ask via form when relevant)
1. Galaxy **map vs list** priority after v0.2? (default: list until v0.4)
2. Should Council votes ever **block** you outright, or always overridable at loyalty cost? (default: always overridable)
3. Era-end: show a **"what history changed"** recap screen? (default: yes, from spec C flags)
