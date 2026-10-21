/* Saga data (story-first layer, Era 1 ~3,660–3,653 BBY). Engine: saga.js. Spec: docs/specs/saga.md.
   The starting squad are characters with arcs. Story reaches the player in 4 places:
   1. Temple talks (TALKS): one optional conversation per hub visit; arc climaxes are forced scenes.
   2. Approach (APPROACH): pick a plan on the squad screen before launch; it changes the battle.
   3. Squad beats (SQUAD_BEATS): a squad member speaks mid-mission with a 2-way choice (comm box).
   4. Aftermath (AFTER): a decision scene back at the Temple after the mission.
   Arc results set flags; FINALE turns them into help (or trouble) at Docking Ring Nine.
   All characters except Satele Shan, Jace Malcom, Gnost-Dural, Zym, Darach, Malgus are invented [N].
   Text rules (spec C §9): short sentences, present tense, scene text ≤280 chars, choice labels ≤32 chars.

   Choice effects (fx), on the speaker unless noted:
   t (trust ±) · trust:{castKey:n} · dark · stress · flag (string or list) · retire:'role text' · teach:1 (next recruit of their class starts rank 2)
   away:days (out wounded/away) · personal:'missionId' (unlocks a personal side mission, stays until played)
   chance:0–1 + fail:{…} · anything story.js applyFx knows: credits intel kyber favor recruits orderDark shadow loyalty{seat,n} recruit mission
   Conditions (when): done (missions finished ≥) · act (≥) · flag · notFlag · anyFlag:[…] · need:[castKeys active] · minT/maxT (speaker trust) */

// Cast: roster name → arc. Matched to the roster by name the first time they appear, then by id (renames are safe).
const CAST={
 kira:{n:'Kira Venn',arc:'What Kira dreams'},
 tor:{n:'Tor Saalen',arc:'The boy from Kessra'},
 rhal:{n:'Sgt. Rhal Dax',arc:'One last tour'},
 ilsa:{n:'Ilsa Myr',arc:'The second report'},
 bren:{n:'Doc Bren',arc:'Wounded is wounded'},
 grak:{n:'Grak Ordo',arc:'Clan Ordo'},
 satele:{n:'Satele Shan',arc:'The Code and the heart'},
 jace:{n:'Jace Malcom',arc:'Form letters'},
 varra:{n:'Varra Ordo',arc:'Clan debts'}};
// Trust −3…+3. At ≥2 the unit fights +5 aim; at ≤−2, −5 aim. Words shown on the Temple strip.
const TRUST={min:-3,max:3,aim:5,word:t=>t>=2?'trusts you':t===1?'warm':t===0?'steady':t===-1?'wary':'distant'};

// ── 1. Temple talks ──
const TALKS=[
 // Kira Venn: she has the Council's vision too, and never sat in the room.
 {id:'k1',who:'kira',when:{done:1},t:'Dawn on the balcony',
  text:'Kira finds you on the east balcony before dawn. “I have the Council’s vision. Every night. I never sat in that room.” She watches the traffic lanes, not you.',
  ch:[{l:'Tell me everything',fx:{t:1,flag:'kira_told'},say:'She talks until the sun is up. Fire. A red blade. A ring of docks she can’t name.'},
   {l:'Take it to Grand Master Zym',fx:{t:-1,flag:'kira_reported',loyalty:{seat:'zym',n:5}},say:'She goes. She doesn’t look at you on the way out.'},
   {l:'Dreams are only dreams',fx:{t:-1,stress:10},say:'“Of course.” She stops coming to the balcony.'}]},
 {id:'k2',who:'kira',when:{done:4,flag:'kira_told'},t:'The ring',
  text:'Kira has drawn the docking ring from her dream. Ninety berths. One is circled twice. “If I could find this place, I’d know where he lands.”',
  ch:[{l:'Have Comms match it',fx:{intel:-1,t:1,flag:'kira_ring'},say:'Comms matches the drawing in an hour. Coruscant. Docking Ring Nine.'},
   {l:'Meditate on it with her',fx:{t:1,stress:-15},say:'Nothing comes. But she sleeps that night, for the first time in weeks.'},
   {l:'Let it go, Kira',fx:{t:-1},say:'She folds the drawing into her robe. She keeps it.'}]},
 {id:'k2b',who:'kira',when:{done:5,notFlag:'kira_told'},t:'Collapse in the salle',
  text:'Kira collapsed in the Training Salle. Doc Bren says she hasn’t slept in a week. She says it’s nothing. Her hands say otherwise.',
  ch:[{l:'Ask her straight',fx:{t:1,flag:'kira_told'},say:'“The vision. I see it every night.” Now you know.'},
   {l:'Order her to Medical',fx:{t:-1,away:10,stress:-20},say:'She goes. Ten days of sleep and silence.'}]},
 {id:'k3',who:'kira',force:1,when:{act:3,anyFlag:['kira_told','kira_reported']},t:'A packed bag',
  text:'Kira waits in the hangar with a packed bag. “It’s this year. I can feel it. Give me leave and I’ll watch the docks myself, Council or no Council.”',
  ch:[{l:'Go, with my blessing',fx:{t:1,flag:'kira_watch',loyalty:{seat:'zym',n:-5}},say:'She bows once and is gone by nightfall. Her reports come every dawn.'},
   {l:'Stay. We go together',fx:{t:1,flag:'kira_foresight'},say:'“Together, then.” She unpacks the bag. Her hands are steady for the first time in months.'},
   {l:'Stand down, Knight',fx:{t:-2,stress:15},say:'She stands down. Something in her face closes and does not open again.'}]},

 // Tor Saalen: a Padawan whose homeworld the Empire burned.
 {id:'t1',who:'tor',when:{done:2},t:'What the Code asks',
  text:'Tor asks why the Code forbids hate. “They burned Kessra Minor. I was nine. I watched from the evac ship. Am I supposed to forget that?”',
  ch:[{l:'Remember it. Don’t hate it',fx:{t:1,dark:-1,flag:'tor_counsel'},say:'He nods slowly. It is not the answer he wanted. It is one he keeps.'},
   {l:'Use the anger, carefully',fx:{t:1,dark:1,flag:'tor_anger'},say:'His eyes light up. That should worry you more than it does.'},
   {l:'Ask Kira. She’s his master',need:['kira'],fx:{trust:{kira:1},flag:'tor_kira'},say:'Kira takes him to the Gardens. They come back quiet, and a little closer.'}]},
 {id:'t2',who:'tor',force:1,when:{act:3},t:'The eve of the Trials',
  text:'Tor comes to you, not to his master. “Am I ready? The truth. I can take the truth.” Behind the question is another one: Kessra.',
  ch:[{l:'You are ready',fx:{t:1,flag:'tor_ready'},say:'He breathes out. “Thank you. I won’t let you down.”'},
   {l:'Not while Kessra owns you',fx:{stress:10,dark:-2,flag:'tor_light'},say:'He is angry for a day. Then he goes to the Gardens every morning, alone.'},
   {l:'Ready to fight, at least',fx:{t:1,dark:1,flag:'tor_shadow'},say:'He grins. “That’s all I need.” You hope that is true.'}]},

 // Sgt. Rhal Dax: 47, near the end of his service; his daughter flies for the Navy.
 {id:'r1',who:'rhal',when:{done:1},t:'A holo from home',
  text:'Rhal shows you a holo: a young woman in Navy flight gear. “My daughter, Lina. Flies a gunship now. Says I’m too old for this.” He laughs. He doesn’t sound sure.',
  ch:[{l:'Is she right?',fx:{t:1,flag:'rhal_lina'},say:'“Probably. Don’t tell her I said so.”'},
   {l:'We need you, Sergeant',fx:{stress:5,flag:'rhal_lina'},say:'“Then you’ve got me.” He puts the holo away.'}]},
 {id:'r2',who:'rhal',when:{done:4},t:'The shake',
  text:'Rhal’s hands shook on the last mission. He thinks nobody saw. Doc Bren saw, and told you.',
  ch:[{l:'A quiet word. Keep him',fx:{t:1,stress:-10,flag:'rhal_kept'},say:'“Just tired, that’s all.” He shows up early to every drill after that.'},
   {l:'Send him to train recruits',fx:{retire:'Trains the Temple’s recruits',teach:1,flag:'rhal_home'},say:'He argues for an hour. Then he goes. The next troopers will be better for it.'},
   {l:'Pretend you didn’t see',fx:{t:-1,stress:15},say:'He sees you not seeing. That is worse.'}]},
 {id:'r3',who:'rhal',force:1,when:{act:3,flag:'rhal_lina'},t:'Missing over Alderaan',
  text:'Navy lists come in. Lt. Lina Dax’s gunship is missing over Alderaan. Rhal reads it twice. “Let me look for her. Two weeks. That’s all I ask.”',
  ch:[{l:'Go. Find her',fx:{away:14,chance:0.65,t:2,flag:'lina_found',fail:{stress:30,flag:'lina_lost'}},
    say:'Rhal comes back with Lina leaning on his shoulder. Neither of them can stop smiling.',sayFail:'Rhal comes back alone. He hands you her flight patch and goes to his bunk.'},
   {l:'I need you here',fx:{t:-2,stress:20,flag:'rhal_stayed'},say:'He doesn’t argue. He doesn’t talk at all for a week.'}]},

 // Ilsa Myr: a scout who reports on the Jedi to Republic Intelligence (the SIS, Legends, High).
 {id:'i1',who:'ilsa',force:1,when:{done:2},t:'A burst from the barracks',
  text:'The Comms Hub logs a coded burst from Ilsa Myr’s bunk at 0300. Republic Intelligence cipher. Someone in your squad reports on the Jedi.',
  ch:[{l:'Confront her',fx:{flag:'ilsa_caught'},say:'She doesn’t run. She asks for ten minutes to explain.'},
   {l:'Watch her quietly',fx:{intel:1,flag:'ilsa_watched'},say:'You read her next three bursts. Squad movements. Nothing else. Yet.'},
   {l:'Leave it alone',fx:{flag:'ilsa_free'},say:'The bursts keep coming. Comms stops logging them.'}]},
 {id:'i2',who:'ilsa',when:{done:3,anyFlag:['ilsa_caught','ilsa_watched']},t:'Ilsa’s side',
  text:'Ilsa doesn’t deny it. “The SIS pays for my mother’s care on Corellia. I tell them where you go and who you fight. Nothing that gets anyone killed.”',
  ch:[{l:'Report to us too',fx:{t:1,intel:2,flag:'ilsa_double',personal:'ilsaDrop'},say:'“A double agent. Mother would laugh.” Her next drop is on Nar Shaddaa.'},
   {l:'We’ll pay. Cut them off',fx:{credits:-60,t:2,flag:'ilsa_loyal'},say:'She stares at the credit chit a long time. “Nobody has ever just paid.”'},
   {l:'Pack your things',fx:{retire:'Dismissed from the Order’s service',flag:'ilsa_gone'},say:'She is gone by morning. Her bunk is made, corners tight.'}]},
 {id:'i3',who:'ilsa',force:1,when:{act:3,anyFlag:['ilsa_double','ilsa_loyal']},t:'A name from the SIS',
  text:'Ilsa’s old handler sends one last message, free. A shuttle filed false papers for Coruscant this year. Its owner travels with a Sith Lord.',
  ch:[{l:'Thank her and listen',fx:{t:1,flag:['ilsa_sis','e1_strike_known']},say:'“Thank him, not me.” She is smiling anyway.'},
   {l:'Sell it to the Senate',fx:{favor:4,flag:'ilsa_sis'},say:'The Senate is grateful, briefly. Ilsa says nothing.'}]},
 {id:'i3x',who:'ilsa',force:1,when:{act:3,flag:'ilsa_free'},t:'The leak',
  text:'An SIS audit lands on your desk. A year of your squad’s movements sat in their files, and someone in the SIS sold them on. The Empire knows how you fight.',
  ch:[{l:'Confront Ilsa now',fx:{t:-2,stress:20,flag:'ilsa_leak'},say:'“I never sold anything.” She is telling the truth. It doesn’t help.'},
   {l:'Rewrite every protocol',fx:{intel:-2,flag:'ilsa_patched'},say:'Two weeks of new codes and new routes. Whatever they sold is old now.'}]},

 // Doc Bren: a medic who treats everyone, enemy included.
 {id:'b1',who:'bren',when:{done:2},t:'Wounded is wounded',
  text:'Doc Bren patched a Sith trooper mid-firefight. Grak wants him off the squad. “Wounded is wounded,” Bren says. “That’s the job. That was always the job.”',
  ch:[{l:'Back him',fx:{t:1,trust:{grak:-1},orderDark:-4,flag:'bren_oath'},say:'Bren nods once. Grak spits, but he stays.'},
   {l:'Our people come first',fx:{t:-1,trust:{grak:1}},say:'“Yes, Master.” Bren packs his kit a little slower than usual.'}]},
 {id:'b2',who:'bren',when:{done:5},t:'The clinic',
  text:'Bren wants to run a free clinic in the lower city on his rest days. Refugees, dockworkers, anyone. “People remember who stitched them up.”',
  ch:[{l:'Fund it',fx:{credits:-60,favor:2,t:1,flag:'bren_clinic',personal:'brenClinic'},say:'The clinic opens in a week. The line is out the door by noon.'},
   {l:'No rest days in a war',fx:{t:-1},say:'He doesn’t argue. He spends his rest days in Medical instead.'}]},
 {id:'b3',who:'bren',force:1,when:{act:3,flag:'bren_clinic'},t:'Patients talk',
  text:'A dockworker at Bren’s clinic wants to repay him. Ring Nine’s night crew was paid to look away from one berth this year. He can hide a squad in the service tunnels.',
  ch:[{l:'Take the offer',fx:{t:1,flag:'bren_tunnels'},say:'Bren shakes the man’s hand. “Wounded is wounded,” the man says back.'},
   {l:'Too risky for him',fx:{favor:1},say:'The dockworker goes home safe. Bren is quietly relieved.'}]},

 // Grak Ordo: exiled from Clan Ordo (Legends, High); the clans fight for the Empire in this war (Legends, Med).
 {id:'g1',who:'grak',when:{done:1},t:'The helmet',
  text:'Grak polishes a Mandalorian helmet he never wears. “Clan Ordo cast me out for fighting a Jedi’s war. Now they take Imperial credits. Funny old galaxy.”',
  ch:[{l:'Why fight for us?',fx:{t:1,flag:'grak_why'},say:'“You don’t sell your word. My clan used to be like that.”'},
   {l:'Will you fight them?',fx:{flag:'grak_asked'},say:'He sets the helmet down. “If I have to. Don’t make me have to.”'}]},
 {id:'g2',who:'grak',force:1,when:{act:2,anyFlag:['grak_parley','grak_why','e1_mando_honor']},t:'The clan calls',
  text:'A Mandalorian courier waits at the Temple gate. Clan Ordo will take Grak back, with honor, if he leaves the Jedi. Grak asks what you think.',
  ch:[{l:'It’s your choice, Grak',fx:{chance:0.7,t:2,flag:'grak_stays',fail:{retire:'Went home to Clan Ordo',flag:'grak_left'}},
    say:'“My choice? Then I stay. Someone has to watch your backs.”',sayFail:'He takes the helmet and goes. At the gate he puts it on. He does not look back.'},
   {l:'Answer the clan, as my envoy',fx:{t:1,personal:'grakClan'},say:'Clan Ordo answers with a test: hold their proving ground against their best. Then they will listen.'},
   {l:'We need you here',fx:{t:-1,stress:10},say:'He sends the courier away himself. It costs him.'}]},

 // Canon recruits who join through events (story.js STORY_RECRUITS).
 {id:'s1',who:'satele',when:{},t:'The Code and the heart',
  text:'Satele Shan asks what Masters don’t ask out loud. “Is attachment the danger? Or is it losing what we are attached to?”',
  ch:[{l:'Attachment is the danger',fx:{orderDark:-4,flag:'satele_code'},say:'“Then I know what I have to watch in myself.” She doesn’t say who.'},
   {l:'Losing it is the danger',fx:{t:1,flag:'satele_heart'},say:'She is quiet a long time. “Thank you for not reciting the Code at me.”'}]},
 {id:'j1',who:'jace',when:{},t:'Form letters',
  text:'Jace Malcom is writing letters for the four he lost on Ilum. “You Jedi light candles. Their families get a form letter. Not mine. Not this time.”',
  ch:[{l:'Help him write them',fx:{t:1,favor:1,stress:-10},say:'You write until the candles burn down. He reads each one twice.'},
   {l:'That’s war, Sergeant',fx:{t:-1},say:'“Yes, sir.” He finishes them alone.'}]},
 {id:'v1',who:'varra',when:{need:['grak']},t:'Clan debts',
  text:'Varra Ordo checks her rifle twice before she speaks. “My brother Grak fights in your squad. I am not here to bring him home. I am here to pay a debt.”',
  ch:[{l:'Fight beside him, then',fx:{t:1,trust:{grak:1}},say:'Grak and Varra don’t speak for a week. Then they won’t stop arguing. It is a good sign.'},
   {l:'Keep the clan out of it',fx:{},say:'“As you say, Jedi.” She keeps her distance from Grak.'}]}];

// When a cast member dies, the living one who trusts you most grieves. {dead} = the fallen.
const GRIEF={t:'An empty bunk',
 text:'{n} sits on {dead}’s empty bunk with {dead}’s kit across their knees. “Someone should send this home. I don’t even know where home was.”',
 ch:[{l:'Sit with them a while',fx:{t:1,stress:-15},say:'You don’t talk. You don’t need to.'},
  {l:'Find out where home was',fx:{intel:-1,t:1,stress:-5},say:'Comms finds a sister on a Mid Rim world. The kit goes home with a letter.'},
  {l:'Give them work to do',fx:{stress:5},say:'They go. Work helps. Not as much as it should.'}]};

// ── 2. Approach: picked on the squad screen. Option 0 is always the plan as briefed (free, no change).
// cost: paid at launch (credits intel kyber favor; orderDark too). fx (battle, whole mission):
// aim · jediAim · clsAim{cls:n} · mob · hp · focus · foeAim · foeHp · cutFoe · foeStun · threat · ally:guestKey (+ allyName) · win:{res} on a win.
const AP_BRIEF={l:'As briefed',d:'Stick to the Council’s plan. No cost, no surprises.'};
const APPROACH={
 relay:[{l:'Dig in',d:'Sandbags and pre-set lanes: +5 aim for the squad, but −1 move all mission.',fx:{aim:5,mob:-1}},
  {l:'Call the Navy',d:'A Republic trooper fights with you. Costs 3 Senate Favor.',cost:{favor:3},fx:{ally:'rep_trooper'}}],
 envoy:[{l:'Plain clothes',d:'Blend into the crowd: enemies −5 aim, but your squad has −1 HP (no armor).',fx:{foeAim:-5,hp:-1}},
  {l:'Pay the dockworkers',d:'30 Credits: one guard post is empty when you arrive.',cost:{credits:30},fx:{cutFoe:1}}],
 vault:[{l:'Gnost-Dural’s map',d:'Jedi start with +2 Focus. Costs 1 Intel.',cost:{intel:1},fx:{focus:2}},
  {l:'Breaching charges',d:'Every enemy starts with −1 HP, but the noise starts Threat at 1.',fx:{foeHp:-1,threat:1}}],
 ilum:[{l:'Fight with the platoon',d:'One of Malcom’s troopers fights with you. Costs 2 Senate Favor.',cost:{favor:2},fx:{ally:'rep_trooper',allyName:'Pvt. Ilum Platoon'}},
  {l:'Attune your blades',d:'Spend 1 Kyber in the caves: Jedi +10 aim all mission.',cost:{kyber:1},fx:{jediAim:10}}],
 adraasHunt:[{l:'Satele’s signal',d:'Strike on her signal: one guard starts stunned.',fx:{foeStun:1}},
  {l:'Snipers on the catwalks',d:'Scouts +15 aim all mission. Costs 1 Intel.',cost:{intel:1},fx:{clsAim:{Scout:15}}}],
 dock:[{l:'Temple Guard escort',d:'A Temple Guard fights at your side. Costs 5 Senate Favor.',cost:{favor:5},fx:{ally:'rep_trooper',allyName:'Temple Guard'}},
  {l:'The Council’s blessing',d:'Every Jedi +2 Focus and +5 aim. The Order leans on war: Order Darkness +4.',cost:{orderDark:4},fx:{focus:2,jediAim:5}}],
 // Crises and personal missions.
 _:[{l:'Move fast',d:'+1 move all mission, but −5 aim.',fx:{mob:1,aim:-5}},
  {l:'Scout it first',d:'Spend 1 Intel: enemies −5 aim.',cost:{intel:1},fx:{foeAim:-5}},
  {l:'Hire local help',d:'Spend 30 Credits: a local fighter joins you.',cost:{credits:30},fx:{ally:'rep_trooper',allyName:'Local fighter'}}]};

// ── 3. Squad beats: a squad member speaks on turn 2 or 3 (at most one per mission, each once per era).
// when: as talks · foe: an enemy type present · types: mission types. a/b: do = battle effect (battle.js bvDo), saga = campaign effect (fx above).
const SQUAD_BEATS=[
 {id:'kb',who:'kira',when:{done:2},txt:'I’ve seen this place. In the dream. Something is behind that wall, waiting for us.',
  a:{label:'Trust her',txt:'The squad turns as one. They were waiting: +10 aim this turn.',do:{aim:10},saga:{t:1}},
  b:{label:'Stick to the plan',txt:'Kira bites her lip and follows orders. Every Jedi +1 Focus.',do:{focus:1},saga:{t:-1}}},
 {id:'tb',who:'tor',when:{done:2},txt:'One of them wears the Kessra campaign stripe. I know it. Let me take him.',
  a:{label:'Stop him',txt:'Tor lowers his blade. A Sith trooper surrenders to him instead. Tor +1 Focus.',do:{surrender:1,focus:1},saga:{dark:-1,flag:'tor_mercy'}},
  b:{label:'Look away',txt:'You don’t see it. The squad does. Tor fights like fire: +10 aim this turn.',do:{aim:10},saga:{t:1,dark:2,flag:'tor_blood'}}},
 {id:'gb',who:'grak',foe:'mando',when:{},txt:'That’s Clan Ordo paint. My cousins. Let me talk to them before this gets ugly.',
  a:{label:'Let him talk',txt:'Grak walks out with his hands open. One fighter lowers his blaster and leaves the field.',do:{remove:1},saga:{t:1,flag:'grak_parley'}},
  b:{label:'No time',txt:'Grak says nothing. He fights harder than ever: +10 aim this turn.',do:{aim:10},saga:{t:-1}}},
 {id:'rb',who:'rhal',when:{done:3},txt:'My knee’s gone stiff. I can hold this corner, or I can push with you. Not both.',
  a:{label:'Hold the corner',txt:'Rhal plants himself. Nothing gets past him: squad +1 HP.',do:{heal:1},saga:{t:1}},
  b:{label:'Push with us',txt:'He pushes. It costs him, but the line moves: +1 move this turn.',do:{mob:1},saga:{stress:10}}},
 {id:'ib',who:'ilsa',when:{done:3},txt:'I can slip ahead and mark their positions. If they spot me, I’m on my own.',
  a:{label:'Go, Ilsa',txt:'She ghosts ahead. Enemy positions light up: +10 aim this turn.',do:{aim:10},saga:{t:1}},
  b:{label:'Stay with the squad',txt:'She stays. Better safe. Every Jedi +1 Focus while the squad regroups.',do:{focus:1},saga:{}}},
 {id:'bb',who:'bren',when:{done:3},txt:'Their wounded are bleeding out in the open. I can reach them. Cover me.',
  a:{label:'Cover him',txt:'Bren works under fire. One enemy, hands raised, surrenders to the medic.',do:{surrender:1},saga:{t:1,orderDark:-4}},
  b:{label:'Our people first',txt:'Bren turns back to the squad: everyone heals 2.',do:{heal:2},saga:{t:-1}}},
 {id:'sb',who:'satele',when:{},txt:'I can reach their minds. Some of them don’t want to be here. Give me a moment.',
  a:{label:'Take the moment',txt:'Satele speaks softly. A trooper lays down his rifle.',do:{surrender:1},saga:{t:1}},
  b:{label:'No time to talk',txt:'She nods and draws. +10 aim this turn.',do:{aim:10},saga:{}}},
 {id:'jb',who:'jace',when:{},txt:'I know this kind of push. Give me the flank and I’ll show you how the Army does it.',
  a:{label:'Your flank, Malcom',txt:'Jace takes the flank. Two enemies are caught in the open, stunned by the shock.',do:{foeStun:2},saga:{t:1}},
  b:{label:'Hold formation',txt:'He grumbles, and holds. Squad +5 aim this turn.',do:{aim:5},saga:{t:-1}}}];

// ── 4. Aftermath: a decision back at the Temple. Story missions always; won crises 50% (each variant once per era).
// who = cast member who speaks if they are on the roster (any status but dead), else the scene is narrated.
const AFTER={
 'relay:win':{who:'bren',t:'Three prisoners',text:'Three Sith troopers surrendered at the relay. The Navy wants them now. Doc Bren wants to treat their burns first. Grak wants to know what they know.',
  ch:[{l:'The Navy takes them',fx:{favor:3}},{l:'Treat them first',fx:{orderDark:-4,trust:{bren:1}}},{l:'Question them ourselves',fx:{intel:2,orderDark:4,trust:{grak:1,bren:-1}}}]},
 'relay:lose':{who:'rhal',t:'Whose call',text:'The relay is slag. Rhal says it was his call to hold the east side. It wasn’t. He wants it on his record anyway.',
  ch:[{l:'It’s on me',fx:{favor:-2,trust:{rhal:1}}},{l:'Then it’s on him',fx:{trust:{rhal:-1}}}]},
 'envoy:win':{who:'ilsa',t:'Saresh wants a deal',text:'Saresh, in binders, wants a deal. One more name in the Senate, for a cell anywhere but Belsavis.',
  ch:[{l:'Take the deal',fx:{intel:2,favor:-2,flag:'saresh_deal'}},{l:'A public trial',fx:{favor:4}}]},
 'envoy:lose':{who:'ilsa',t:'What the SIS knew',text:'Saresh is gone. Ilsa says the SIS watched him for months and told no one. “They wanted him running. Not caught.”',
  ch:[{l:'Demand their files',fx:{favor:-2,intel:2}},{l:'Let it go',fx:{}}]},
 'vault:win':{who:'kira',t:'Who reads first',text:'Gnost-Dural asks who reads the Ossus records first: the full Council, or only the two of you. Kira asks to sit in. “I’ve seen some of it already.”',
  ch:[{l:'The full Council',fx:{orderDark:-4,loyalty:{seat:'gnost',n:5}}},{l:'Us, and Kira',need:['kira'],fx:{intel:2,trust:{kira:1}}},{l:'Only us two',fx:{intel:2}}]},
 'vault:lose':{who:'kira',t:'Ash',text:'Gnost-Dural sifts the ash from Ossus with his fingers. “Some of this was eight thousand years old.” Kira can’t look at him.',
  ch:[{l:'Rebuild what we can',fx:{credits:-40,intel:1}},{l:'Leave him to grieve',fx:{loyalty:{seat:'gnost',n:5}}}]},
 'ilum:win':{who:'jace',t:'Buried in the snow',text:'Malcom’s platoon wants Republic rites for the dead on Ilum. The Council says Ilum is a Jedi world, with Jedi rites.',
  ch:[{l:'Their rites, their dead',fx:{favor:2,trust:{jace:1}}},{l:'Ship them home',fx:{credits:-30,favor:3,trust:{jace:1}}},{l:'Jedi world, Jedi rites',fx:{trust:{jace:-1},orderDark:-4}}]},
 'ilum:lose':{who:'grak',t:'Dark caves',text:'The raiders took crystals. Grak says the Hutts will sell them back within a month. “Pay, or go get them.”',
  ch:[{l:'Pay the Hutts',fx:{credits:-60,kyber:2}},{l:'Let them go',fx:{shadow:1}}]},
 'adraasHunt:win':{who:'satele',t:'A Sith holocron',text:'Adraas left a holocron in his shuttle. Sith teachings, still warm with the dark. Satele won’t touch it.',
  ch:[{l:'Destroy it',fx:{orderDark:-4,trust:{satele:1}}},{l:'Study it',fx:{intel:3,unitDark:{who:'jedi_random',n:2},flag:'adraas_holo'}},{l:'Give it to Gnost-Dural',fx:{intel:1,loyalty:{seat:'gnost',n:5}}}]},
 'adraasHunt:lose':{who:'satele',t:'Blame',text:'Satele blames herself for the hangar. Master Darach blames you, loudly, in front of the Council.',
  ch:[{l:'Stand by Satele',fx:{trust:{satele:1},loyalty:{seat:'darach',n:-5}}},{l:'Agree with Darach',fx:{trust:{satele:-1},loyalty:{seat:'darach',n:5}}}]},
 // Won crises, by mission type.
 'rescue:a':{who:'kira',t:'Tell my family',text:'The woman you pulled out asks one thing: that a Jedi tell her family she’s alive. In person.',
  ch:[{l:'Send a Jedi',fx:{favor:2,stress:-10}},{l:'Send a message',fx:{}}]},
 'defend:a':{who:'rhal',t:'Bread at dawn',text:'Locals bring bread to the squad at dawn. The garrison captain says feeding Jedi isn’t in his budget. He wants it stopped.',
  ch:[{l:'Accept it with thanks',fx:{favor:2}},{l:'Pay them for it',fx:{credits:-20,favor:4}}]},
 'sabotage:a':{who:'bren',t:'Smoke over the village',text:'Smoke from the depot drifted over a farm village. Two families lost their homes. Nobody will blame you out loud.',
  ch:[{l:'Pay to rebuild',fx:{credits:-40,orderDark:-4,favor:2}},{l:'War is war',fx:{orderDark:4}}]},
 'investigate:a':{who:'ilsa',t:'A senator’s name',text:'The stolen data names a Republic senator on the Imperial payroll. Ilsa says the SIS would pay well for it.',
  ch:[{l:'Hand it to the Senate',fx:{favor:4}},{l:'Keep it as leverage',fx:{intel:2,orderDark:4}},{l:'Sell it to the SIS',fx:{credits:60}}]},
 'escort:a':{who:'grak',t:'A favor owed',text:'The person you saved offers a favor: a word in the Chancellor’s ear, or a bag of credits. Grak votes credits.',
  ch:[{l:'A word for the Order',fx:{favor:5}},{l:'The credits',fx:{credits:60,trust:{grak:1}}}]}};

// ── Personal missions (unlocked by talks; they stay on the galaxy list until played, and never expire other options).
Object.assign(MISSIONS,{
 ilsaDrop:mirrorMission(MISSIONS.archive,{n:'The Dead Drop',where:'SIS dead drop · Nar Shaddaa',theme:'city',
  brief:'Ilsa’s SIS contact left a data drop in a Nar Shaddaa listening post. Imperial agents are working the same building. Scan the terminals, then reach evac.',
  win:'The drop comes home. Ilsa reads it first, then hands it to you without a word.',lose:'The drop burns. Ilsa’s contact goes quiet for good.',
  reward:{credits:40,intel:3},winFlag:'ilsa_drop'}),
 brenClinic:mirrorMission(MISSIONS.rescue,{n:'The Clinic Raid',where:'Lower-city clinic · Coruscant',theme:'city',
  brief:'Swoop gangers in Imperial pay grabbed a volunteer from Doc Bren’s clinic. Open the cell (Hack or console), then walk her to an evac zone (E).',
  win:'The volunteer is home. The clinic opens again the next morning.',lose:'The clinic stays shut. Bren sits on its steps all night.',
  reward:{credits:40,favor:4},winFlag:'bren_defended'}),
 grakClan:mirrorMission(MISSIONS.fort,{n:'Clan Ordo’s Proving Ground',where:'Proving ground · Ord Mantell',theme:'plains',
  brief:'Clan Ordo will hear Grak only if his allies hold their proving ground against the clan’s best. Six turns. They are not playing.',
  goal:'Hold the proving ground for 6 turns. Mandalorians are armored and hit hard.',
  win:'Clan Ordo hears Grak out. They will not take Malgus’s credits this year.',lose:'Clan Ordo laughs Grak off the field.',
  reward:{credits:50,favor:2},winFlag:'grak_envoy'})});
Object.assign(CRISES,{
 ilsaDrop:{n:'Ilsa’s dead drop',kind:'Investigate',src:'Personal: Ilsa Myr',mission:'ilsaDrop',text:'Ilsa’s SIS contact left a drop on Nar Shaddaa. Imperial agents are close.',ignore:{}},
 brenClinic:{n:'The clinic raid',kind:'Rescue',src:'Personal: Doc Bren',mission:'brenClinic',text:'Gangers took a volunteer from Bren’s clinic. Bren is already packing his kit.',ignore:{}},
 grakClan:{n:'Clan Ordo’s test',kind:'Defend',src:'Personal: Grak Ordo',mission:'grakClan',text:'Hold Clan Ordo’s proving ground so the clan will hear Grak out.',ignore:{}}});
Object.assign(FLAG_LINES,{kira_foresight:'Kira Venn dreamed the docking ring, and you believed her.',kira_watch:'Kira Venn watched the docks alone.',
 tor_light:'Tor Saalen let Kessra go.',tor_blood:'Tor Saalen took his revenge, and you looked away.',lina_found:'Rhal Dax found his daughter alive over Alderaan.',
 ilsa_loyal:'You paid Ilsa Myr’s debts, and she stopped spying.',ilsa_double:'Ilsa Myr reported to the SIS and to you.',ilsa_leak:'An SIS leak gave your tactics to the Empire.',
 bren_clinic:'Doc Bren ran a free clinic in the lower city.',grak_envoy:'Clan Ordo stayed out of the strike on Coruscant.',grak_left:'Grak Ordo went home to Clan Ordo.'});

// ── Finale: what the cast's arcs bring to Docking Ring Nine. First matching row per key; all keys apply.
// fx (battle): lock (lift lock) · hurtBoss · focus · foeAim · cutFoe · strafe · ally · unitAim{castKey:n}
const FINALE=[
 {k:'kira',if:f=>f.kira_watch,who:'Kira Venn',txt:'He’s here. I slowed him at the berth. He’s bleeding.',fx:{hurtBoss:2}},
 {k:'kira',if:f=>f.kira_foresight||f.kira_ring,who:'Kira Venn',txt:'I know this berth. Lock the lifts from the north side.',fx:{lock:1}},
 {k:'tor',if:f=>f.tor_light,who:'Tor Saalen',txt:'I’m calm. I’m ready.',fx:{focus:1}},
 {k:'tor',if:f=>f.tor_shadow||f.tor_blood,who:'Tor Saalen',txt:'Let him come.',fx:{unitAim:{tor:10}}},
 {k:'rhal',if:f=>f.lina_found,who:'Lt. Lina Dax',txt:'Gunship Dax on station. One pass, Dad. Keep your head down.',fx:{strafe:2}},
 {k:'rhal',if:f=>f.rhal_home,who:'Temple Guard',txt:'Sergeant Dax’s recruits, reporting for duty.',fx:{ally:'rep_trooper',allyName:'Dax’s recruit'}},
 {k:'ilsa',if:f=>f.ilsa_sis,who:'Ilsa Myr',txt:'SIS jammers are up. They’re shooting half-blind.',fx:{foeAim:-5}},
 {k:'ilsa',if:f=>f.ilsa_leak&&!f.ilsa_patched,who:'Comms',txt:'They know our protocols. They saw us coming.',fx:{foeAim:5}},
 {k:'bren',if:f=>f.bren_tunnels,who:'Doc Bren',txt:'The night crew sealed a berth door behind them. One squad fewer.',fx:{cutFoe:1}},
 {k:'grak',if:f=>f.grak_envoy||f.grak_left,who:'Clan Ordo',txt:'Clan Ordo turned down Malgus’s credits. His Mandalorians never came.',fx:{cutFoe:1}}];

// Era-end lines for the cast (checked before story.js EPILOGUE). [N]
const SAGA_EPI={
 kira:[[f=>f.kira_foresight||f.kira_watch,'Never dreams of fire again. She dreams of Tython, and wakes smiling.'],[(f,t)=>t<=-2,'Leaves the Order a year after the treaty. She never says why.']],
 tor:[[f=>f.tor_light,'Passes the Trials. Can say “Kessra” now without his hands shaking.'],[f=>f.tor_blood||f.tor_shadow,'Fights like fire. The Council writes one word in his file: watch.']],
 rhal:[[f=>f.lina_found,'Retires to Corellia. His daughter visits every leave, and they argue about gunships.'],[f=>f.rhal_home,'Trains three generations of Temple troopers. They all call him Sarge.']],
 ilsa:[[f=>f.ilsa_loyal,'Never sends another coded burst. Her mother sends the Temple a thank-you note.'],[f=>f.ilsa_double,'Keeps two masters for ten more years. Both think she is theirs.']],
 bren:[[f=>f.bren_clinic,'His clinic is still open in the lower city. The sign says: wounded is wounded.']],
 grak:[[f=>f.grak_left,'Went home to Clan Ordo. Some nights he still watches the Jedi news.'],[f=>f.grak_stays,'Finally wears the helmet. He painted the Order’s crest on it.']]};
