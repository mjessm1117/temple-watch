# Squad & Legacy (Chat Q, wave 5, 2026-10-17)

Goal (Jess): get attached to your people. Bonds like Zero Company, lore that grows, retire to the Council or as a General, bring Council masters into battle.
Extends what existed (bonds 0–3, Years-pass retirement, Council appointment, service records). Code: `public/js/legacy.js`, data: `public/js/data-legacy.js`, bond numbers: `BOND` in `temple-data.js`, test: `tests/legacy.test.js`.

## Research: Star Wars: Zero Company (Bit Reactor / Respawn / Lucasfilm, released Aug 27 2026)
| Feature | What it does | Confidence | Source |
|---|---|---|---|
| Bonds | Every pair has a level 1–8, earned as points (missions, Call for Backup, heals, Den time, story choices). Start neutral or negative | High (3 sources agree) | EA Help "Build and customize your squad"; powerupgaming.co.uk; allthings.how |
| Cross Training | Each bond level-up: pick 1 of 3 random perks, applies to both, locked. Examples +1 ranged dmg, +4 max HP, +5% crit, +2 Focus Points, "Conflict Resolution" pushes toward next level | High | allthings.how, powerupgaming.co.uk |
| Max bond | Unlocks a special Cross Training with a passive ability (not named in sources) | Med | same |
| Fracture | Dilemma choices and dialogue can lower bonds; death severs them | Med | powerupgaming.co.uk, EA Help |
| Classes | 8 specializations (Assault, Gunslinger, Heavy, Medic, Scoundrel, Scout, Sharpshooter, Soldier) + locked "exotic" hero classes (Jedi Padawan Tel-Rea Vokoss, Mandalorian Cly Kullervo, Astromech). Second spec mid-campaign | High | EA Help; allthings.how |
| Operator story | Each operative joined with a dark secret or goal; Personality affects dialogue only | Med (one review) | space.com review |
| Death | 2 injuries survivable, 3rd kills | Med (one review) | space.com review |
| Squad | 4 in battle, roster up to 20 | High | space.com; EA Help |

## What we took, what we changed
| System | Ours |
|---|---|
| Bonds 1–8 | Points to level up: `BOND.need` = 8,10,12,14,16,18,20,22. Sources: fought together and both lived +6 (+3 on a win), one saved the other +15, field op success together +5, same Temple assignment +2 per mission. Combat tiers kept: Bond 2+ aim near partner, 4+ answer shot, 6+ a death causes fear/grief. Old saves: 1/2/3 → 2/4/6 |
| Drills (= ZC Cross Training) | Each level-up offers 3 random `DRILLS`; pick 1 in the Roster; both partners keep it. Bond 8 = **Unbreakable** (+10 aim near partner instead of +5, +10 will). Named "drills" because "cross-training" already means multiclassing in this game |
| Not taken | Negative bonds / fractures (no dialogue system yet). Possible later: Council vote choices move squad bonds |
| Lore | Each unit: a backstory (by origin, shown from day one) + a hidden `SECRETS` entry. Hints unlock at 3 missions, rank 3, surviving a downing, bond 4, a field op win. 3 hints or rank 4 reveals the secret, which offers a personal mission (existing `QUESTS`) with its own text |
| Retirement | Years pass and voluntary (rank 4+, Roster → "Retire…"): **Council seat** (Jedi rank 3+, open seat) or **General** of a region. General: field ops there +15%, Unrest there can't rise above 2. Re-post Generals from the Council tab |
| Council support | Squad screen offers extra slots on top of the squad: boss 3 free, story 1 free, other missions 1 at −10 loyalty. NPC masters fight as their stance class at rank 6; your retired Masters fight as themselves; Generals can fight once each (story/boss). A master rests 1 mission after. A fallen master's seat empties and every member loses 5 loyalty |

## Tuning knobs
All in `LEGACY` and `DRILLS` (data-legacy.js) and `BOND` (temple-data.js). Bots never pick Council support, so balance tests are unchanged; watch real play for masters making story missions too easy.
