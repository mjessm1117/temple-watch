/* Battle variety (Chat H, wave 4): battle twists, mid-battle story beats, signature objectives for story missions.
   Data only; the engine is battle.js. Loads after data-era2.js.
   Lore: every named speaker is a Legends character (Gnost-Dural, Satele Shan, Jace Malcom, Malgus, Zym, Adraas: SWTOR era;
   Hoth, Farfalla, Kaan, Johun Othone: Darth Bane trilogy) [High on who they are]. All dialogue is invented for this game [N]. */

// ---- 1. Twists: every mission rolls one. themes = mission themes it can roll on (null = any). w = weight.
// range: ranged weapons lose this much reach (min 3) · vision: no sight or shots past this many tiles (Sense units +3)
// droids/ionStun: war droids added, % each droid shorts out per turn · cracks: tiles cracked per turn · guest: an extra fighter.
const TWISTS={
 sandstorm:{n:'Sandstorm',ic:'smoke',themes:['plains','ruins','dock','jungle'],w:3,range:-3,hud:'Ranges −3',
  desc:'Grit fills the air. Every ranged weapon reaches 3 tiles less (minimum 3), yours and theirs. Snipers suffer most. Close the distance.'},
 blizzard:{n:'Blizzard',ic:'smoke',themes:['snow'],w:4,range:-3,hud:'Ranges −3',
  desc:'A whiteout. Every ranged weapon reaches 3 tiles less (minimum 3), yours and theirs. Close the distance.'},
 blackout:{n:'Blackout',ic:'conceal',themes:['city','dock','temple','caves','ruins'],w:3,vision:4,hud:'Sight 4',
  desc:'The lights are out. Nobody sees or shoots past 4 tiles (Sense: 7). Overwatch and long rifles lose their edge; ambushes are easy.'},
 ionstorm:{n:'Ion storm',ic:'ion',themes:['plains','snow','dock','ruins','jungle','city'],w:2,droids:2,ionStun:35,hud:'Droids short out',
  desc:'Ion clouds roll in. Two war droids join the enemy, and every droid has a 35% chance to short out (stunned) each turn. Personal shields fail.'},
 collapse:{n:'Unstable ground',ic:'tremor',themes:['city','dock','caves','ruins','temple'],w:3,cracks:2,hud:'Cracks fall next turn',
  desc:'The floor is failing. Each turn 2 tiles near your squad crack; next turn they fall away: 3 damage to anyone standing there, and the tile becomes a chasm.'},
 ally:{n:'Unexpected ally',ic:'soldier',themes:null,w:3,guest:1,hud:'+1 guest fighter',
  desc:'A friendly fighter joins the squad for this mission. You control them; they are not part of your roster and earn nothing.'}};
// Guests: built with battleUnit() like a roster unit, but with no roster id (the campaign ignores them). By era.
const GUESTS={
 rennick:{era:1,n:'Cpl. Dace Rennick',cls:'Soldier',rank:2,col:'#e0bd78',line:'Rennick, Republic Army. Got separated from my unit. Point me at something.'},
 tessa:{era:1,n:'Varn Tessa',cls:'Scout',rank:2,col:'#e0bd78',line:'Freelance scout. The Empire burned my homeworld. I work for free today.'},
 ossa:{era:2,n:'Kell Ossa',cls:'Soldier',rank:2,col:'#e0bd78',line:'Army of Light, third company. Lord Hoth sent me. Where do you want me?'},
 wynn:{era:2,n:'Lord Tarel Wynn',cls:'Guardian',rank:2,col:'#ffd166',line:'Army of Light. I felt the fight from the ridge. I am with you.'},
 aol_trooper:{era:2,n:'Army of Light trooper',cls:'Soldier',rank:1,col:'#e0bd78'},
 rep_trooper:{era:1,n:'Republic trooper',cls:'Soldier',rank:1,col:'#e0bd78'}};
// Ion storm droids. [N] a generic battle droid, no named canon model.
const WAR_DROID={n:'War droid',ic:'e_droid',tags:['droid'],droid:1,hp:5,aim:60,mob:4,dmg:[2,4],range:7,armor:1,noCap:1,init:5,
 desc:'A heavy battle droid: 5 HP, 1 armor, range 7. Ion storms and ion grenades short it out.'};

// New tiles for twists and signature objectives (2D borrows `as`; 3D borrows `as3d`).
const BV_TILES={
 z:{n:'Cracked floor',desc:'This floor falls away next turn: 3 damage to anyone on it, and it becomes a chasm.',cover:0,h:0,walk:1,as:'crk',as3d:'r'},
 V:{n:'Chasm',desc:'A hole in the floor. Nothing crosses it; sight passes over it.',cover:0,h:0,walk:0,as:'pit'},
 U:{n:'Control pad',desc:'Stand here at the start of your turn to hold it.',cover:0,h:0,walk:1,as:'pad',as3d:'E'},
 G:{n:'Getaway speeder',desc:'The target\'s way out. If he reaches it, he is gone.',cover:1,h:1,walk:1,as:'pad',as3d:'k'},
 H:{n:'Holocron',desc:'Step on it to pick it up. The carrier moves 1 less. Get it to an evac zone.',cover:0,h:0,walk:1,as:'relic',as3d:'q'},
 T:{n:'Sapper charge',desc:'An enemy charge. Defuse it (adjacent, 1 action) before its timer runs out.',cover:1,h:1,as:'bomb',as3d:'X'},
 P:{n:'Pylon',desc:'Full cover. Shoot it, blast it, or wreck it up close (adjacent, 1 action, 3 damage).',cover:2,h:2,as:'pyl',as3d:'O'},
 L:{n:'Signal brazier',desc:'Half cover. Light it (adjacent, 1 action).',cover:1,h:1,as:'k',as3d:'k'},
 J:{n:'Lit brazier',desc:'Half cover. Burning bright.',cover:1,h:1,as:'qd',as3d:'Q'},
 Y:{n:'Dark ground',desc:'Spreading dark-side rot. Start your turn on it: troops take 1 damage, Jedi gain 1 Darkness.',cover:0,h:0,walk:1,as:'drk'}};
const PYLON_HP=6;

// ---- 2. Beats: short lines that fire on triggers. Generic beats (max 3 per mission) plus every signature beat.
// on: turn (n) · threat (n) · down (first squad unit down) · vipHit (first hit on the VIP) · bossHalf (boss at ≤50%) · objHalf (defend
//     objective at ≤50%) · twist (turn 1 intro) · sig events: padDone, switchesDone, pylonsDown, relic, bomb, runner, runnerGone, keyTaken, spotterDown, rouse, cleansed
// Filters: types, eras, crisis (1 = crisis missions only), twist. who/txt placeholders: {unit} {vip} {boss} {jedi} {guest} {cmd}.
// do: effects (battle.js bvDo). choice: {a:{label,txt,do}, b:{…}}: the player picks; the fight pauses until then.
const BEATS=[
 {id:'g_down',on:'down',who:'{cmd}',txt:'{unit} is down!',choice:{
  a:{label:'Get them up',txt:'A medic talks the squad through it over comms. {unit} stops bleeding, but everyone else is distracted (−10 aim this turn).',do:{stabDown:1,aim:-10}},
  b:{label:'Make them pay',txt:'Anger sharpens every shot: +15 aim this turn. {unit} keeps bleeding.',do:{aim:15}}}},
 {id:'g_vip',on:'vipHit',who:'{vip}',txt:'I\'m hit! I can\'t take another one of those!',choice:{
  a:{label:'Shield them',txt:'You strap a shield pack on {vip} (soaks 3). Fumbling with it costs time: Threat +1.',do:{shieldVip:3,threat:1}},
  b:{label:'Patch them up',txt:'A quick field dressing: {vip} heals 2.',do:{healVip:2}}}},
 {id:'g_boss',on:'bossHalf',who:'{boss}',txt:'You will not leave this place alive.',choice:{
  a:{label:'Press the attack',txt:'Everyone goes for the kill: +15 aim this turn. A Jedi feels the anger in it (Darkness +1).',do:{aim:15,dark:1}},
  b:{label:'Hold formation',txt:'You tighten up and catch your breath: the squad heals 2.',do:{heal:2}}}},
 {id:'g_comms',on:'turn',n:4,crisis:1,who:'{cmd}',txt:'We cracked their comm channel. Jam it, or listen in?',choice:{
  a:{label:'Jam them',txt:'Their coordination falls apart: enemies −5 aim for the rest of the fight.',do:{foeAim:-5}},
  b:{label:'Listen in',txt:'You learn plenty (+1 Intel), but they hear you on the line: enemies +5 aim.',do:{intel:1,foeAim:5}}}},
 {id:'g_d2',on:'turn',n:2,types:['defend'],who:'{cmd}',txt:'Steady. Make them come to you. Every turn you hold, help gets closer.'},
 {id:'g_r2',on:'turn',n:2,types:['rescue'],who:'{cmd}',txt:'The prisoner is alive. We can hear them hammering on the cell door.'},
 {id:'g_i2',on:'turn',n:2,types:['investigate'],who:'{cmd}',txt:'Their slicers know you\'re here. Copy those terminals before they wipe them.'},
 {id:'g_e2',on:'turn',n:2,types:['escort'],who:'{vip}',txt:'Just tell me where to run. I\'ll run.'},
 {id:'g_s2',on:'turn',n:2,types:['sabotage'],who:'{cmd}',txt:'Charges first, then everyone out. Nobody gets left on that depot.'},
 {id:'g_a2',on:'turn',n:2,types:['assault'],who:'{boss}',txt:'Come, then. Let us see what the Jedi send to die.'},
 {id:'g_thr4',on:'threat',n:4,who:'{cmd}',txt:'The window is closing. Two more turns, then it\'s over. Finish it.'},
 // Twist intros (turn 1, always).
 {id:'t_sand',on:'twist',twist:'sandstorm',who:'{cmd}',txt:'Sandstorm rolling in. Visibility is dropping: get close or you\'ll be shooting at grit.'},
 {id:'t_bliz',on:'twist',twist:'blizzard',who:'{cmd}',txt:'Whiteout. You won\'t see their snipers, and they won\'t see you. Close in.'},
 {id:'t_dark',on:'twist',twist:'blackout',who:'{cmd}',txt:'Power\'s cut. It\'s pitch black past a few meters. Stay close and check every corner.'},
 {id:'t_ion',on:'twist',twist:'ionstorm',who:'{cmd}',txt:'Ion front overhead. Their droids will twitch, and our shield packs are dead weight.'},
 {id:'t_floor',on:'twist',twist:'collapse',who:'{cmd}',txt:'This floor won\'t take much more. Watch for cracks and don\'t stand on them.'},
 {id:'t_ally',on:'twist',twist:'ally',who:'{guest}',txt:'{gline}'}];

// ---- 3. Signature objectives (one per story mission). Primitives (battle.js): pads, runner, relic, bombs, pylons, switches,
// wounded, spread, keyholder, barrage. Tile coordinates are preferred spots; the engine moves to the nearest free floor if needed.
// res = campaign rewards on a win; flag = C.flags entry.
const SIG={
 relay:{n:'Boost the signal',desc:'Hold the uplink pad (U) at the start of 3 of your turns: the fleet jumps in a turn early (+30 Credits).',
  pads:{at:[[4,4]],need:3,done:{turns:-1,res:{credits:30},flag:'sig_relay_boost'}},
  beats:[{on:'turn',n:1,who:'Fleet Ops',txt:'Aurek-7, your signal is faint. Hold the uplink pad and we can jump sooner.'},
   {on:'turn',n:4,who:'Fleet Ops',txt:'A Sith jammer is drowning your uplink. We can burn through it, but they\'ll hear us.',choice:{
    a:{label:'Burn through',txt:'The uplink surges (+1 hold). So does Sith comm traffic: a dropship is coming.',do:{pad:1,reinforce:['trooper','trooper']}},
    b:{label:'Go quiet',txt:'You kill the signal and listen. You learn where their push is aimed: +10 aim this turn, +1 Intel.',do:{intel:1,aim:10}}}},
   {on:'padDone',who:'Fleet Ops',txt:'Signal locked! The fleet jumps a turn early. Hold on, Aurek-7.'},
   {on:'objHalf',who:'Fleet Ops',txt:'Relay integrity at half. Don\'t let it go dark now.'}]},
 envoy:{n:'The envoy runs',desc:'From turn 3 (or once you get within 4) Saresh runs for his speeder (G). Stun, subdue or block him before he reaches it.',
  runner:{type:'envoy',to:[9,6],start:3,mob:3},
  beats:[{on:'turn',n:1,who:'Senate Security',txt:'Saresh has a speeder waiting on the east landing. If he reaches it, we lose him for good.'},
   {on:'runner',who:'Envoy Saresh',txt:'You think the Council can stop what\'s coming? I\'m leaving, Jedi.'},
   {on:'turn',n:4,when:'runner',who:'Senate Security',txt:'He\'s making for the speeder!',choice:{
    a:{label:'Shoot the speeder',txt:'The speeder burns: Saresh has to run on foot (2 tiles a turn). The blast brings the garrison: Threat +1.',do:{runnerSlow:1,threat:1}},
    b:{label:'Cut him off',txt:'Your squad sprints the rooftops: +2 move this turn.',do:{mob:2}}}},
   {on:'runnerGone',who:'Senate Security',txt:'He\'s gone. Whatever he knew left with him.'}]},
 vault:{n:'The holocron',desc:'Gnost-Dural\'s holocron (H) sits in the inner vault. Step on it to pick it up; whoever carries it must still be standing when you win: +2 Intel, +1 Kyber.',
  relic:{at:[5,0],res:{intel:2,kyber:1},flag:'sig_vault_holocron'},
  beats:[{on:'turn',n:1,who:'Master Gnost-Dural',txt:'The terminals are copies. The holocron in the inner vault is the real archive. Bring it home.'},
   {on:'relic',who:'Master Gnost-Dural',txt:'Careful with that. It is older than the Temple you are fighting for.'},
   {on:'turn',n:3,who:'Master Gnost-Dural',txt:'The vault wards are waking. I can guide you through them, or you can break them.',choice:{
    a:{label:'Follow his lead',txt:'Gnost-Dural talks you through the wards, one breath at a time: every Jedi +2 Focus.',do:{focus:2}},
    b:{label:'Break the wards',txt:'The wards shatter: two enemies reel, stunned. Something in the dark answers (Darkness +1).',do:{foeStun:2,dark:1}}}}]},
 ilum:{n:'Sapper charges',desc:'Imperial sappers plant charges (T) near the cave mouth on turns 3, 5 and 7. Defuse each (adjacent, 1 action) within 2 turns or it blows: 3 damage around it, 5 to the cave mouth.',
  bombs:{plant:{3:2,5:2,7:1},timer:2,near:[4,10],r:4,objDmg:5},
  beats:[{on:'turn',n:1,who:'Sgt. Jace Malcom',txt:'The Imps brought sappers. If they get charges on the cave mouth, defuse them fast.'},
   {on:'bomb',who:'Sgt. Jace Malcom',txt:'Charges down by the cave mouth! Two turns on the timers. Move!'},
   {on:'turn',n:6,who:'Sgt. Jace Malcom',txt:'I can bring the outer roof down on their approach. Costs us the outer cave, but it\'ll slow them.',choice:{
    a:{label:'Bring it down',txt:'The outer cave roars shut (cave mouth −3). Two attackers are buried in the fall: stunned.',do:{obj:-3,foeStun:2}},
    b:{label:'Hold the line',txt:'Malcom grins. "Thought you\'d say that." +10 aim this turn.',do:{aim:10}}}}]},
 adraasHunt:{n:'Shield pylons',desc:'Two pylons (P) shield Lord Adraas: nothing hurts him while one stands. Shoot, blast or wreck them (6 HP each).',
  pylons:{at:[[1,1],[8,1]],shieldBoss:1,doneEv:'pylonsDown'},
  beats:[{on:'turn',n:1,who:'Satele Shan',txt:'Adraas is hiding behind generator pylons. Bring them down or nothing will touch him.'},
   {on:'pylonsDown',who:'Satele Shan',txt:'His shield is down. Now!',do:{aim:10}},
   {on:'bossHalf',who:'Lord Adraas',txt:'You fight well for Republic dogs. Walk away and I let you live.',choice:{
    a:{label:'Press the attack',txt:'Everyone goes for him: +15 aim this turn. Satele\'s calm doesn\'t reach everyone (Darkness +1).',do:{aim:15,dark:1}},
    b:{label:'Talk to his men',txt:'Satele speaks to his troopers, not to him. One of them lowers his rifle and surrenders.',do:{surrender:1}}}}]},
 dock:{n:'Lock the lifts',desc:'Malgus wants the Temple lifts. Each turn you start with someone on a lift control (U) banks a lock; a lock cancels one Threat rise.',
  pads:{at:[[1,5],[8,5]],each:{lock:1}},
  beats:[{on:'turn',n:1,who:'Grand Master Zym',txt:'Malgus is going for the Temple lifts. Hold the lift controls and he cannot rise.'},
   {on:'turn',n:3,who:'Darth Malgus',txt:'Your Temple walls will not save you. Nothing will.'},
   {on:'bossHalf',who:'Darth Malgus',txt:'Is this all the Order has left?',choice:{
    a:{label:'Press him',txt:'Every blade and rifle turns on Malgus: +15 aim this turn (Darkness +1).',do:{aim:15,dark:1}},
    b:{label:'Box him in',txt:'You pin him against the ring: Malgus can\'t move on his next turn.',do:{rootBoss:1}}}}]},
 r_muster:{n:'Light the braziers',desc:'Light both signal braziers (L, adjacent, 1 action): Hoth\'s vanguard (2 troopers) joins you and the beacon gets +4.',
  switches:{at:[[0,4],[9,4]],done:{ally:['aol_trooper','aol_trooper'],obj:4},doneEv:'switchesDone'},
  beats:[{on:'turn',n:1,who:'Lord Hoth',txt:'Light the signal braziers on both flanks. My vanguard will see them and come to you.'},
   {on:'switchesDone',who:'Lord Hoth',txt:'I see your fires! Vanguard, go!'},
   {on:'turn',n:4,who:'Lord Hoth',txt:'Kaan\'s raiders are circling. I can spare a gunship run, or I can send you medics.',choice:{
    a:{label:'Gunship run',txt:'Fire walks across the field: 2 damage to up to 3 enemies.',do:{strafe:2}},
    b:{label:'Send medics',txt:'Two medics slide in behind your line: the squad heals 3.',do:{heal:3}}}}]},
 r_ravine:{n:'Leave no one',desc:'Two wounded Jedi lie in the ravine. Get them on their feet (adjacent, 1 action) and keep them alive: +1 Recruit each on a win.',
  wounded:{at:[[1,4],[8,6]],res:{recruits:1}},
  beats:[{on:'turn',n:1,who:'Johun Othone',txt:'Two of ours are down in the ravine. Get them on their feet. We don\'t leave anyone.'},
   {on:'rouse',who:'Johun Othone',txt:'That\'s it. Lean on me. We walk out together.'},
   {on:'turn',n:4,who:'Johun Othone',txt:'I can keep moving, or I can stop and help the wounded.',choice:{
    a:{label:'Keep moving',txt:'Johun sets his jaw: +1 move for him from now on.',do:{vipMob:1}},
    b:{label:'Help the wounded',txt:'Johun lays hands on the wounded. The Force flows: the squad heals 2.',do:{heal:2}}}}]},
 r_caves:{n:'The rot',desc:'Dark ground (Y) spreads 2 tiles a turn from a Sith shrine (P). Start a turn on it: troops take 1, Jedi gain 1 Darkness. Break the shrine (6 HP) and the rot dies.',
  spread:{src:[5,2],per:2,start:3},pylons:{at:[[5,2]],doneEv:'cleansed'},
  beats:[{on:'turn',n:1,who:'Lord Farfalla',txt:'The dark in those caves spreads like rot. Its source is a Sith shrine. Break it and the rot dies.'},
   {on:'turn',n:3,who:'A whisper',txt:'Stand in the dark, little Jedi. Drink it. It will make you strong.',choice:{
    a:{label:'Shut it out',txt:'It hurts, but the squad steadies: every Jedi +1 Focus.',do:{focus:1}},
    b:{label:'Listen',txt:'Power floods in (+15 aim this turn). So does something else: Darkness +2.',do:{aim:15,dark:2}}}},
   {on:'cleansed',who:'Lord Farfalla',txt:'The rot is breaking apart. Well done.'}]},
 r_sixth:{n:'The jailer\'s key',desc:'The jailer carries the cell key. Kill or subdue him and the cell opens (Threat −1).',
  keyholder:{type:'bh_trooper',near:[2,4],name:'Jailer Drask'},
  beats:[{on:'turn',n:1,who:'Lord Farfalla',txt:'The jailer carries the cell key. Take him down, or take him alive, and the cell opens.'},
   {on:'keyTaken',who:'Lord Farfalla',txt:'The key! Get our man out of there.'},
   {on:'turn',n:3,who:'Lord Farfalla',txt:'I can make them think we\'re hitting their supply tents instead.',choice:{
    a:{label:'Feint',txt:'One guard runs for the supply tents and leaves the fight. The rest dig in: Threat +1.',do:{remove:1,threat:1}},
    b:{label:'All in',txt:'No tricks. Everyone hits the cell block: +10 aim this turn.',do:{aim:10}}}}]},
 r_seventh:{n:'Shellfire',desc:'Vorr\'s spotter calls artillery: red zones get shelled next turn (3 damage, cover cracks). Kill the spotter and the guns go blind.',
  barrage:{spotter:'bh_sniper',per:2,start:2,dmg:3},
  beats:[{on:'turn',n:1,who:'Lord Hoth',txt:'Vorr has guns and a spotter on the ridge. Red zones are shells landing next turn. Kill the spotter.'},
   {on:'spotterDown',who:'Lord Hoth',txt:'Their guns are blind! Push!',do:{aim:10}},
   {on:'bossHalf',who:'Lord Vorr',txt:'Hoth sends children to die for him.',choice:{
    a:{label:'Press the attack',txt:'+15 aim this turn. The anger is real (Darkness +1).',do:{aim:15,dark:1}},
    b:{label:'Call the guns on him',txt:'Hoth\'s own artillery answers: Vorr takes 3. Anyone of yours beside him takes 2.',do:{hurtBoss:3,splash:2}}}}]},
 r_bomb:{n:'The ritual stones',desc:'Kaan\'s ritual draws on three stones (P, 6 HP). Each one broken lowers Threat by 1. Break all three and Kaan is stunned.',
  pylons:{at:[[1,0],[8,0],[4,6]],each:{threat:-1},done:{stunBoss:1},doneEv:'pylonsDown'},
  beats:[{on:'turn',n:1,who:'Lord Hoth',txt:'Kaan\'s ritual draws on three stones. Every stone you break buys us time.'},
   {on:'pylonsDown',who:'Lord Hoth',txt:'The ritual falters! Kaan is exposed!'},
   {on:'bossHalf',who:'Lord Kaan',txt:'Join us. In the Brotherhood we are all equals in darkness.',choice:{
    a:{label:'Strike him down',txt:'+15 aim this turn. It feels good. Too good (Darkness +1).',do:{aim:15,dark:1}},
    b:{label:'Hold the light',txt:'Hoth\'s Jedi link minds against him: every Jedi +2 Focus and the squad heals 2.',do:{focus:2,heal:2}}}}]}};
