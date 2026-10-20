/* Squad identity data (bucket 1, Jess 2026-10-18 feedback): voices, nickname deeds, Padawan bonus. [N] = invented for this game.
   Voices: one per unit (r.voice), spread so a squad doesn't share one. Lines ≤ 60 chars, spec C §9 voice: short, no jokes at death.
   Events: select, kill, crit, hit (took damage, still up), down, allyDown, panic. Missing events fall back to the trait barks (data-story.js). */
const VOICES={
 // Troopers
 veteran:{n:'Veteran',who:'troop',select:['Seen worse. Where to?','On it.'],kill:['Stay down, son.','That’s how it’s done.'],crit:['Thirty years of practice.'],hit:['Just a scratch. Keep moving.'],down:['Leave me. Finish it.'],allyDown:['Get them out of the open!','Cover them, now!'],panic:['Not again. Not again.']},
 joker:{n:'Joker',who:'troop',select:['Somebody call me?','Your favorite trooper, reporting.'],kill:['And stay out!','Ha! Didn’t see that coming.'],crit:['Tell me you saw that.'],hit:['Ow. Rude.'],down:['Okay… not funny anymore…'],allyDown:['Hey! Hey, stay with me!'],panic:['Nope. Nope. Nope.']},
 rookie:{n:'Rookie',who:'troop',select:['Y-yes, sir!','Ready. I think.'],kill:['I got one! I got one!','Did… did I do that?'],crit:['Just like the sims!'],hit:['They shot me! They actually shot me!'],down:['Tell my mom…'],allyDown:['Oh no. Oh no, they’re down!'],panic:['I can’t do this!']},
 stoic:{n:'Stoic',who:'troop',select:['Ready.','Moving.'],kill:['Down.','One.'],crit:['Clean.'],hit:['Hit. Still in it.'],down:['…'],allyDown:['Man down. Holding.'],panic:['Too much. Too much.']},
 hothead:{n:'Hothead',who:'troop',select:['Point me at them!','Finally!'],kill:['Who’s next?!','Come on, then!'],crit:['Feel that?!'],hit:['You’re gonna pay for that!'],down:['Lucky… shot…'],allyDown:['They’ll burn for that!'],panic:['Get them off me!']},
 believer:{n:'Believer',who:'troop',select:['For the Republic.','The Jedi lead, I follow.'],kill:['Light take you.','For the Temple.'],crit:['The Force was with that one.'],hit:['The Force… protects. Mostly.'],down:['I’m not afraid…'],allyDown:['Hold on! Help is coming!'],panic:['Where are the Jedi?!']},
 cynic:{n:'Cynic',who:'troop',select:['What now.','Great. Another plan.'],kill:['There. Happy?','One less.'],crit:['Even a broken clock.'],hit:['Of course.'],down:['Figures…'],allyDown:['Told you this was a bad idea. Medic!'],panic:['We’re all dead anyway!']},
 pro:{n:'Professional',who:'troop',select:['Awaiting orders.','Copy.'],kill:['Target neutralized.','Confirmed kill.'],crit:['Center mass.'],hit:['Taking fire. Operational.'],down:['Need extraction…'],allyDown:['Casualty! Priority evac!'],panic:['Losing it. Losing it.']},
 // Jedi
 serene:{n:'Serene',who:'jedi',select:['I am here.','As the Force wills.'],kill:['Be at peace.','It is done.'],crit:['There.'],hit:['Pain passes.'],down:['I am… one with…'],allyDown:['Hold on to me. Breathe.'],panic:['The calm… I can’t find it.']},
 fierce:{n:'Fierce',who:'jedi',select:['Let’s end this.','Lead on.'],kill:['You chose this.','Stand down or fall.'],crit:['Too slow.'],hit:['Is that all?'],down:['Not… finished…'],allyDown:['Get behind me!'],panic:['The anger… it’s too loud.']},
 scholar:{n:'Scholar',who:'jedi',select:['Fascinating ground. Yes?','Interesting.'],kill:['Regrettable.','The archives will note it.'],crit:['A known weakness.'],hit:['Hm. Miscalculated.'],down:['Record… what happened…'],allyDown:['No! Stabilize them, quickly!'],panic:['None of the texts said this.']},
 warm:{n:'Warm',who:'jedi',select:['With you.','I’ve got your back.'],kill:['I’m sorry it came to this.','Forgive me.'],crit:['Opening!'],hit:['I’m all right. Keep going.'],down:['Look after… each other…'],allyDown:['No, no, stay with me!'],panic:['I can’t lose anyone else.']},
 haunted:{n:'Haunted',who:'jedi',select:['…Yes.','I see it again.'],kill:['Another one for the vision.','The fire takes them all.'],crit:['I saw it before it came.'],hit:['I’ve felt worse in dreams.'],down:['The Temple… burning…'],allyDown:['Not them. Not like the vision.'],panic:['The fire! It’s here!']}};

// Nicknames earned by deeds (career totals on r.deeds). First pass that clears its bar suggests the name. [N]
// troop = nickname, jedi = epithet ("Kira Venn, the Merciful").
const DEEDS=[
 {k:'crit',at:3,troop:'Deadeye',jedi:'the Precise',why:'3+ critical hits'},
 {k:'multi',at:1,troop:'Havoc',jedi:'the Storm',why:'3+ kills in one mission'},
 {k:'clutch',at:1,troop:'Lucky',jedi:'the Fortunate',why:'finished a mission on 1 HP'},
 {k:'save',at:2,troop:'Angel',jedi:'the Healer',why:'saved 2+ downed allies'},
 {k:'downed',at:2,troop:'Iron',jedi:'the Unbroken',why:'went down twice and came back'},
 {k:'cap',at:3,troop:'Shackles',jedi:'the Merciful',why:'3+ captures'},
 {k:'melee',at:3,troop:'Knuckles',jedi:'the Blade',why:'3+ melee kills'},
 {k:'tank',at:25,troop:'Brick',jedi:'the Wall',why:'soaked 25+ damage'},
 {k:'kill',at:8,troop:'Reaper',jedi:'the Relentless',why:'8+ kills'},
 {k:'mission',at:6,troop:'Old Hand',jedi:'the Patient',why:'6+ missions'}];
// Fallback suggestions when deeds are thin.
const NICK_CLASS={Soldier:['Sarge','Trigger','Rook'],Scout:['Hawk','Ghost','Longshot'],Medic:['Patch','Stitches','Doc'],Heavy:['Boomer','Tank','Thunder'],Shieldbearer:['Bulwark','Gate','Anvil'],
 jedi:['the Steadfast','the Quiet','the Bright','the Wanderer']};
const NICK_MAX=16;

// Master–Padawan in battle: Padawan within PAD.r tiles of their Master gets +PAD.aim aim; a Padawan kill gives the Master +PAD.focus Focus.
const PAD={r:3,aim:10,focus:1};
