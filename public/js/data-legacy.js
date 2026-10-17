/* Squad & Legacy data (Chat Q, wave 5). Logic: legacy.js. Bond numbers (levels, points): BOND in temple-data.js. Spec: docs/specs/legacy.md.
   Borrowed from Star Wars: Zero Company (2026): 8 bond levels earned as points; each level-up = pick 1 of 3 shared "cross trainings"
   (we call them drills, since "cross-training" already means multiclassing here); max bond = a pair passive. [Sourced, High]
   Hidden secret per recruit: ZC operatives each joined with "a dark secret or goal" [Sourced, Med]; the unlock-as-you-grow part is ours. */

// Bond drills. Each bond level-up offers 3 at random; you pick 1 and BOTH partners keep it. min = lowest bond level that can offer it.
const DRILLS={
 range:{n:'Range drills',desc:'+3 aim.',mod:{aim:3},min:1},
 fitness:{n:'Fitness work',desc:'+1 HP.',mod:{hp:1},min:1},
 trust:{n:'Trust exercises',desc:'+5 will (harder to panic).',mod:{will:5},min:1},
 talk:{n:'Conflict resolution',desc:'No stat. Moves the pair halfway to the next bond level.',pts:.5,min:1},
 timing:{n:'Timing exercises',desc:'+5 crit chance.',mod:{crit:5},min:3},
 hard:{n:'Hard-hitting drills',desc:'+1 max damage.',mod:{dmgHi:1},min:3},
 medic:{n:'Field medicine',desc:'+1 medkit (units that carry kits).',mod:{kits:1},min:3},
 cover:{n:'Cover drills',desc:'+5 will and +1 HP.',mod:{will:5,hp:1},min:5},
 footwork:{n:'Footwork',desc:'+1 move.',mod:{mob:1},min:5}};
// Bond 8 (max): automatic pair passive.
const BOND_MAX_PERK={n:'Unbreakable',desc:'+10 aim (instead of +5) near the partner, and +10 will.',will:10};

const LEGACY={
 retireRank:4,          // you can retire a unit yourself from the Roster at this rank or higher
 councilRank:3,         // a retiring Jedi of this rank or higher can take an open Council seat
 revealRank:4,          // a unit's secret comes out at this rank, even with hints missing
 genField:15,           // field ops in a General's region: +15 success
 genCap:2,              // Unrest in a General's region can't climb above this
 slots:{boss:3,story:1,any:1},   // Council support slots in battle (on top of the 6-unit squad)
 loyCost:10,            // asking a master along on a non-story mission costs that master's loyalty
 masterRank:6,          // Council masters who aren't your units fight at this rank
 rest:1,                // missions a master sits out after fighting
 fallLoy:-5};           // every other Council member's loyalty when a master falls in battle

// Backstory by origin. {n} = unit name. One is drawn at recruitment and shown from day one.
const BACKSTORY={
 'Temple-raised':['{n} came to the Temple before they could walk. The Archives were their playground.',
  '{n} was raised by the crèche masters and never knew another home. They are calm in a way that unsettles people.',
  '{n} grew up in the Temple’s lower halls, fixing droids for the Guard. They still talk to machines.'],
 'Late found':['{n} was found at nine, picking pockets in a spaceport. The Council argued for a week before taking them.',
  '{n} lived on a farm until a Jedi noticed the crops never failed. They miss the rain.',
  '{n} was found late, after a fire nobody else walked out of. They don’t talk about it.'],
 'Republic Army':['{n} enlisted at seventeen to get off a mining world. Three tours later, they asked for Temple duty.',
  '{n} comes from an army family. Their mother still writes, asking when they’ll come home.',
  '{n} served on the Outer Rim pickets. They know what Sith raiders leave behind.'],
 'Temple Guard':['{n} stood guard at the Temple doors for six years without seeing a fight. They volunteered for the field.',
  '{n} is the first of their clan to wear the Guard’s mask. They take it off for no one.',
  '{n} trained with the Guard but was never chosen for the inner halls. They mean to earn it.'],
 'Hired':['{n} was a mercenary until a Jedi paid them in mercy instead of credits. They stayed.',
  '{n} signed on for the pay. Nobody has asked them to leave, and they haven’t asked to.',
  '{n} drifted in from the Hutt worlds with a good rifle and no references.']};

// Hidden secrets. who: jedi | troop | any. quest = QUESTS key (temple-data.js) that the reveal unlocks as a personal mission.
// hints unlock one at a time (see HINT_TRIGGERS); 3 hints, or reaching LEGACY.revealRank, reveals the secret. {p} = a bonded partner.
const SECRETS={
 brother:{who:'troop',quest:'family',n:'The brother',
  hints:['{n} sends half their pay to a Mid Rim address every month.','{n} keeps a holo of two kids, face down, in their footlocker.','{n} told {p}: “My brother picked the wrong side.”'],
  reveal:'{n}’s brother rides with Sith raiders. {n} wants him back, alive.',
  ask:'{n}’s brother was seen with a raider crew. {n} asks to go, and asks you not to shoot him.'},
 debt:{who:'troop',quest:'debt',n:'The debt',
  hints:['A Hutt courier asked for {n} by name at the Temple gate.','{n} flinches at the sound of Huttese.','{n} admitted to {p} that they owe more than they’ll ever earn.'],
  reveal:'{n} owes a Hutt broker a fortune from their merc days. The broker has started collecting.',
  ask:'The broker holds a hostage against {n}’s debt. Free the hostage and the debt dies with the deal.'},
 deserter:{who:'troop',quest:'home',n:'The desertion',
  hints:['{n} won’t talk about their first unit.','{n} wakes up shouting a village name.','{n} told {p}: “I ran once. Never again.”'],
  reveal:'{n} deserted a picket under fire years ago. The village it guarded burned.',
  ask:'Raiders are back at the village {n} once abandoned. {n} wants to hold the line this time.'},
 song:{who:'jedi',quest:'crystal',n:'The song',
  hints:['{n} hums a tune nobody taught them.','{n} stops mid-step sometimes, listening.','{n} told {p} a crystal has been singing to them since childhood.'],
  reveal:'A kyber crystal has called to {n} all their life. Now they know where it is.',
  ask:'{n} finally knows where the singing crystal lies, and so do the Sith.'},
 voice:{who:'jedi',quest:'whisper',n:'The voice',
  hints:['{n} meditates alone, at night, more than anyone.','{n}’s eyes went yellow for a heartbeat. Maybe a trick of the light.','{n} told {p} about a voice that promises them strength.'],
  reveal:'A dark voice has whispered to {n} since an old shrine visit. It is getting louder.',
  ask:'{n} wants to face the voice at its source: the old shrine.'},
 master:{who:'jedi',quest:'master',n:'The first master',
  hints:['{n} keeps a broken saber hilt that isn’t theirs.','{n} asks the Archives about one mission, over and over.','{n} told {p}: “My first master didn’t die the way the records say.”'],
  reveal:'{n}’s first master was betrayed, and their relics were sold to raiders.',
  ask:'Raiders are selling {n}’s first master’s relics. {n} wants them back.'},
 bloodline:{who:'jedi',quest:'whisper',n:'The bloodline',
  hints:['{n} reads Old Sith script without trying.','{n} avoids the Archive wing on the Sith wars.','{n} told {p} their grandmother was a Sith Lord.'],
  reveal:'{n} descends from a Sith family. They fear what that means.',
  ask:'A Sith shrine of {n}’s bloodline is waking. {n} must face it, or be claimed by it.'},
 survivor:{who:'any',quest:'home',n:'The survivor',
  hints:['{n} counts the exits in every room.','{n} keeps a list of names. It is long.','{n} told {p} they were the only one who walked out of their village.'],
  reveal:'{n} is the only survivor of a Sith raid on their home. They saw who led it.',
  ask:'The raiders who burned {n}’s home are back in the same valley.'},
 oath:{who:'any',quest:'home',n:'The oath',
  hints:['{n} sends a message home every month. It always says the same thing.','{n} keeps a farmer’s token on their belt.','{n} told {p} about a promise to a dying man.'],
  reveal:'{n} swore to protect a dying farmer’s village. They joined to keep that oath.',
  ask:'The village {n} swore to protect is under attack. An oath is an oath.'}};
// Order the hints unlock in is fixed (hint 1, 2, 3); these are the moments that unlock the next one (each counts once).
const HINT_TRIGGERS={m3:'3 missions served',r3:'reached rank 3',down:'survived being downed',bond:'bond level 4 with someone',field:'came back from a field op'};
