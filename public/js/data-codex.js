/* Codex lore (flavor) for every id. U’s describe(kind,id) shows CODEX[kind][id].lore next to the owner’s mechanical desc. ≤280 chars each. Voice: docs/specs/story.md §9.
   Confidence tags in comments: [C]=Disney canon, [L]=Legends, [N]=invented for this game; H/M/L = confidence. */
const CODEX={
 ability:{
  shoot:{lore:'Patient hands, steady breath. A trooper learns that one clean shot saves more lives than ten loud ones.'}, // [N]
  strike:{lore:'The blade moves before the thought finishes. Every Padawan is taught that the strike is the last answer, not the first.'}, // [N]
  guard:{lore:'To stand between a blow and a friend is the oldest Jedi lesson. The Guardian does not ask who deserves it.'}, // [L H] Guardian ideal; [N] phrasing
  overwatch:{lore:'Waiting is a kind of fighting. The soldier who holds still and watches the door decides who walks through it.'}, // [N]
  push:{lore:'A breath of the Force, shaped into a shove. It carries no malice, only a firm request to be elsewhere.'}, // [N]
  collapse:{lore:'The Force gathers, then falls on one place at once. Masters warn that power taken this wide leaves a mark on the one who takes it.'}, // [N]
  choke:{lore:'The Council forbids it. A hand closes on a throat from across the room, and the one who holds it feels the dark answer back.'}, // [N]
  stun:{lore:'A pulse that quiets the body without breaking it. Mercy is a discipline, and it is harder than the alternative.'}, // [N]
  subdue:{lore:'The Jedi prefer a prisoner who can talk to a corpse who cannot. Many a captive has surprised them with what they knew.'}, // [N]
  meditate:{lore:'Stillness is not rest. The Jedi sits inside the storm and listens for what the Force is trying to say.'}, // [N]
  heal:{lore:'The Force knits what the blade has opened. It does not take away the fear, and the Jedi never claims that it does.'}, // [N]
  grenade:{lore:'A small sphere, a short fuse, a loud decision. Troopers throw them at cover, and cover rarely argues.'}, // [N]
  stabilize:{lore:'A field medic’s first rule: keep them here. Everything else can be solved once the bleeding stops.'}, // [N]
  door:{lore:'Every door in the Temple was built to open to a hand that is welcome. Out in the field, doors are less polite.'}, // [N]
  console:{lore:'Old machines hold new secrets. A steady hand and a patient tech can still coax the truth out of them.'}, // [N]
  scan:{lore:'The Force reaches out and returns with shapes, heartbeats, and the cold spots where something is hiding.'}, // [N]
  plant:{lore:'Set the charge, count the steps, leave. Sabotage is quiet work done by people who would rather not be thanked.'}, // [N]
  saberThrow:{lore:'A lightsaber thrown is a lightsaber risked. The Force brings it back, but the Jedi learns the length of a moment without it.'}, // [N]
  defLine:{lore:'The blade turns the bolt. Another Jedi stands at the shoulder, and together they make a wall no blaster wants to test.'}, // [N]
  leap:{lore:'A Jedi’s jump is not strength but trust. The Force holds the air for the length of a heartbeat, and that is enough.'}, // [N]
  reflectM:{lore:'The Force shows the bolt before it leaves the barrel. The blade is only there to finish the thought.'}, // [N]
  sweep:{lore:'One wide arc, and the room is a different place. The Guardian’s answer to being surrounded is to become the center.'}, // [N]
  forceHeal:{lore:'The deeper art. A Consular gives of their own strength to restore another’s, and rests afterward without complaint.'}, // [N]
  barrier:{lore:'A shell of will, thin as breath and hard as durasteel while it holds. Consulars say it is easier to build for others than for oneself.'}, // [N]
  battleMed:{lore:'Bacta, a steady voice, and a Force touch when the bacta runs short. The Temple’s healers learned to work under fire.'}, // [N]
  mindTrick:{lore:'A suggestion, offered so gently that the listener believes it was their own idea. The Consulars say it is not a trick but a courtesy.'}, // [N]
  forceRevive:{lore:'The Force can call back a life that has barely left. It asks a great deal, and the Jedi who answers is never quite the same.'}, // [N]
  suppress:{lore:'Fire that does not seek to hit, only to keep heads down. A soldier’s way of buying others a few seconds of safe ground.'}, // [N]
  hunker:{lore:'Get low, get small, let the world pass over. Surviving a bad moment is also a victory.'}, // [N]
  mark:{lore:'A spotter calls the target and everyone’s aim improves. Calm voices win more battles than brave ones.'}, // [N]
  smoke:{lore:'A cloud to move behind. The enemy fires at where you were, and you are somewhere else.'}, // [N]
  hack:{lore:'Slicers say every lock is a conversation. Patience and a little cleverness will make most systems say yes.'}, // [N]
  shredder:{lore:'Armor is a promise that a shot will not matter. The shredder round exists to break that promise.'}, // [N]
  rapidFire:{lore:'All the weapon’s patience spent at once. The heavy trooper trades accuracy for the certainty that something will land.'}, // [N]
  deadeye:{lore:'One shot, taken after the long wait. A scout learns to hold their breath until the world holds still with them.'}, // [N]
  rally:{lore:'A word at the right moment. Veterans know that courage is mostly borrowed, passed hand to hand along the line.'}, // [N]
  reviveStim:{lore:'A sharp sting and a gasp. Medics carry the stim for the worst day, and hope never to need it.'}, // [N]
  rocket:{lore:'It is loud, and it is meant to be. The heavy trooper fires one when quiet has already failed.'}, // [N]
  flurry:{lore:'The Form takes over. Cut follows cut so quickly that the opponent has no time to be afraid of the next one.'}, // [N]
  shadowStep:{lore:'A Sentinel moves where eyes do not rest. They are there, and then they are behind you.'}, // [N]
  executioner:{lore:'Some blows end a fight before it begins. Jedi who learn this also learn how heavy it is to use.'}, // [N]
  sense:{lore:'The Force whispers before the danger arrives. Sentinels trust that whisper and have been alive longer for it.'}, // [N]
  disarm:{lore:'A flick of the wrist and the weapon is somewhere else. The Jedi way is to end the fight without ending the foe.'}, // [N]
  pathfinder:{lore:'Where others see rubble, a scout sees a road. The best ones leave no tracks for anyone to follow.'}, // [N]
  beastCalm:{lore:'Even a hungry thing can be soothed by a patient mind. It is slow work, and a gentle one.'}, // [N]
  pull:{lore:'The Force draws what you need into your hand, or an enemy into your reach. Take care, because it works both directions.'}, // [N]
  tremor:{lore:'The ground itself remembers the Jedi’s step. A tremor rolls outward and knocks the unready off their feet.'}, // [N]
  wildBond:{lore:'Some Jedi feel the creatures of the wild more clearly than they feel people. The bond is quiet, and it is real.'}, // [N]
  runGun:{lore:'A good soldier fires while moving, and a great one forgets the difference. Practice, bruises, and more practice.'}, // [N]
  spotter:{lore:'A second pair of eyes behind the first. The shot is the shooter’s, but the war is won by the one who sees the whole field.'}, // [N]
  ghost:{lore:'Gone before the alarm sounds. A scout who is never noticed is a scout whose reports always arrive.'}, // [N]
  protocol:{lore:'Orders, drilled until they are habit. In the dark and the noise, protocol is what remains when thinking is too slow.'}, // [N]
  shieldDrone:{lore:'A small hovering disc that does one thing well. Soldiers name them anyway, and are not embarrassed to.'}, // [N]
  ionNade:{lore:'It does not harm flesh, only wires. Machines go quiet and the battle changes shape.'}, // [N]
  holdLine:{lore:'Not one step back. The line holds because each person on it decides, separately, that it will.'}, // [N]
  flakVest:{lore:'Layered plating, scuffed and patched. Every trooper has a story about the bolt it stopped.'}, // [N]
  veteran:{lore:'Experience is a kind of armor. The veteran has seen this before, and the calm they carry spreads along the line.'}, // [N]
  longshot:{lore:'Distance is only a matter of patience. The long barrel, the steady breath, the shot that nobody heard coming.'}, // [N]
  killshot:{lore:'A trained eye finds the gap in the armor. It is not cruelty, only competence at a hard trade.'}, // [N]
  fieldcraft:{lore:'Cover, concealment, silence. The things that are not in the manual but have kept every old scout alive.'}, // [N]
  fieldKit:{lore:'Bandages, a stim, and one clean cloth. Small things that matter most when everything else has gone wrong.'}, // [N]
  combatMedic:{lore:'The medic fights because the line breaks without them. Carrying a rifle and a kit takes a particular kind of courage.'}, // [N]
  traumaBag:{lore:'Heavy and worn, it never leaves the medic’s shoulder. What is inside has stopped more wounds than any speech.'}, // [N]
  bandolier:{lore:'Spare cells across the chest, clipped and counted. A soldier who runs dry is a soldier who is no longer useful to the people next to them.'}, // [N]
  juggernaut:{lore:'The heavy trooper walks into the fire because the others cannot. Armor, mass, and the stubbornness to keep walking.'} // [N]
 },
 enemy:{
  trooper:{lore:'Sith Empire infantry, trained hard and ordered harder. Most of them believe in the Empire because they have never been offered another future.'}, // [L H] Imperial trooper; [N] characterization
  heavy:{lore:'A walking wall in Imperial plate, with a gun that wants to be heard. It is slow to turn and quick to punish those who stand still.'}, // [N]
  agent:{lore:'Imperial Intelligence does not announce itself. A cold hide, a long rifle, and a patience the Temple’s own scouts would respect.'}, // [L H] Imperial Intelligence; [N] sniper role
  acolyte:{lore:'A student of the Sith, hungry to be noticed by someone with more power. Lightning crackles in the fingers, and mercy has not yet been taught.'}, // [L H] Sith acolytes; [N] characterization
  terentatek:{lore:'A beast bred, it is said, to hunt those who touch the Force. The Jedi who survive an encounter rarely describe it, but the nightmares do.'}, // [L H] Terentatek hunts Force users
  envoy:{lore:'A Republic envoy with the right smile and the wrong friends. Whispers say that someone close to the talks is selling the schedule.'}, // [N]
  malgus:{lore:'A Sith Lord who believes the Republic is a lie and means to prove it with fire. He fights like a man with nothing left to lose.'}, // [L H] Darth Malgus; [N] phrasing
  mando:{lore:'Mandalorian clans, hired by the Empire for the oldest reason there is. They fight with honor and are paid in credits.'}, // [L H] Mandalorians in Imperial pay; [N] phrasing
  adraas:{lore:'Lord Adraas fought beside Malgus in the strike on Coruscant. Those who faced him remember how little he seemed to care about the cost.'} // [L H] Adraas with Malgus; [N] phrasing
 },
 gear:{
  t1:{lore:'A standard-issue Republic blaster, worn smooth by many hands. It is not elegant, but it fires every time.'}, // [N]
  t2:{lore:'A military-grade piece, better balanced and kept clean. Quartermasters hand them out with a nod and a warning.'}, // [N]
  t3:{lore:'Elite work, tuned by someone who cared. Troopers who are issued one tend to take better care of it than of themselves.'}, // [N]
  none:{lore:'No armor at all. Quick, light, and a little reckless. The Jedi have always trusted the Force over plating.'}, // [N]
  light:{lore:'Flexible plates under a Republic jacket. It turns a glancing bolt and weighs almost nothing.'}, // [N]
  heavy:{lore:'Layered ceramic and alloy, built to take hits that would drop anyone else. It makes a trooper slow and very hard to move.'}, // [N]
  scope:{lore:'A narrow window on a far place. Scouts say the world looks calmer through glass, which is a lie worth believing.'}, // [N]
  barrel:{lore:'A longer barrel, a tighter bolt. Gunsmiths on Coruscant argue about the exact length, and nobody wins.'}, // [N]
  cell:{lore:'A power cell with a little more kick. It runs hot, and troopers learn to count their shots.'}, // [N]
  saber1:{lore:'Padawans build their first blade under a Master’s eye. The training blade is simple, and it teaches by being forgiving.'}, // [N]
  saber2:{lore:'Attuned to its owner. The crystal hums at a pitch only they can feel, and the blade answers their intent.'}, // [N]
  saber3:{lore:'Forged by a Master’s hand. It is not a weapon so much as a conversation between a Jedi and the Force.'}, // [N]
  focused:{lore:'A tightly bound beam that cuts where it is aimed and nowhere else. Some Jedi prefer clarity to power.'}, // [N]
  swift:{lore:'A lighter hilt and a quicker blade. It rewards those who prefer to finish a motion before the other side begins.'}, // [N]
  warden:{lore:'A blade made to protect. It turns away what it can, and the Jedi who carries it takes pride in what never gets through.'}, // [N]
  blue:{lore:'The blue crystal is the Guardian’s companion. It carries a calm, steady light and a reputation for defending first.'}, // [L H] blue common among Guardians; [N] phrasing
  green:{lore:'The green blade is associated with the Consular, a Jedi of insight and negotiation. It is the color of patient hands.'}, // [L H] green and Consulars; [N] phrasing
  yellow:{lore:'The yellow crystal is often chosen by Sentinels, who walk between study and duty. It burns bright, and it burns honestly.'}, // [L H] yellow and Sentinels; [N] phrasing
  violet:{lore:'A rare hue, said to come when a Jedi’s heart is torn two ways. Those who carry it speak little of why.'}, // [N]
  white:{lore:'A white blade is the mark of a crystal that was cleansed or purified. Jedi treat it as a quiet sign of a hard road walked.'}, // [C M] white/purified crystals; [N] phrasing
  shiiCho:{lore:'Form I, the Way of the Sarlacc. The first form: broad, forgiving, and the foundation on which every other Jedi is built.'}, // [L H] Shii-Cho Form I
  makashi:{lore:'Form II, the Way of the Ysalamiri. The duelist’s Form: precise footwork, elegant strokes, built for facing another blade.'}, // [L H] Makashi Form II
  soresu:{lore:'Form III, the Way of the Mynock. Efficient and patient, it asks the Jedi to endure and to wait for the other side to tire.'}, // [L H] Soresu Form III
  ataru:{lore:'Form IV, the Way of the Hawk-Bat. Acrobatic and fast, it uses the Force to leap and strike, and tires its user quickly.'}, // [L H] Ataru Form IV
  shien:{lore:'Form V, the Way of the Krayt Dragon. It blends strong defense with strong offense, and it prizes the deflected bolt returned.'}, // [L H] Shien/Djem So Form V
  niman:{lore:'Form VI, the Way of the Rancor. A moderate Form, balancing blade and Force, favored by those who see the Jedi as scholars first.'}, // [L H] Niman Form VI
  juyo:{lore:'Form VII, the Way of the Vornskr. Ferocious, almost too intense, it is taught with caution because of what it can do to a Jedi’s mind.'} // [L H] Juyo Form VII
 },
 wing:{
  medical:{lore:'Quiet beds and quiet voices. The Halls smell of bacta and clean linen, and everyone who passes through remembers them gently.'}, // [N]
  training:{lore:'The Salle echoes with practice blades and patient correction. Every Jedi has lost their first bout here and learned from it.'}, // [N]
  forge:{lore:'The crystal hums in the dark. Here a Jedi builds the blade they will carry, and learns something about themselves in the doing.'}, // [N]
  armory:{lore:'Racks of blasters and plates for the Republic soldiers who share the Temple’s halls. Not every defender carries a lightsaber.'}, // [N]
  comms:{lore:'Holos, relays, and a watch that never sleeps. In the Hub, news from the war arrives a little late and a little changed.'}, // [N]
  barracks:{lore:'Bunks, boots, and a card table nobody admits to owning. The troopers make a home out of whatever space they are given.'}, // [N]
  archives:{lore:'Millennia of memory, shelved and catalogued. The Archives hold the answer to many questions, and some questions the answer may not welcome.'}, // [N]
  gardens:{lore:'Moss, water, and a quiet that is carefully maintained. A good place to sit with a troubled thought until it loosens.'}, // [N]
  hangar:{lore:'The Temple’s ships rest here between sorties. Pilots swear the engines can feel when something is wrong.'}, // [N]
  council:{lore:'Twelve seats, and every decision made here travels farther than the room. The Council deliberates slowly because it must.'} // [L H] Jedi Council; [N] phrasing
 },
 tile:{
  '.':{lore:'Open floor. Plain, scuffed, and honest. Most battles are decided on ground like this.'}, // [N]
  '_':{lore:'A door left open. It invites movement, for friend and foe alike.'}, // [N]
  E:{lore:'The evacuation zone. A gunship waits, engines warm. Getting everyone to it is the whole point.'}, // [N]
  r:{lore:'Broken stone and twisted metal. Rubble slows the careless and shelters the careful.'}, // [N]
  c:{lore:'Stacked crates, supplies for someone’s better day. Good cover, and sometimes something useful inside.'}, // [N]
  h:{lore:'A wall torn open by force, leaving a ragged window. Sightlines appear where none were meant to.'}, // [N]
  x:{lore:'A drum of volatile fuel. Everyone nearby thinks about it at the same time.'}, // [N]
  k:{lore:'A control console, blinking patiently. Whoever sits at it learns what the building knows.'}, // [N]
  q:{lore:'A data terminal with unread files. Someone will want what it holds, and someone else will want it gone.'}, // [N]
  Q:{lore:'A terminal already copied. Its secrets now travel with the squad, and the building does not know.'}, // [N]
  b:{lore:'An alarm beacon, dark for now. If it lights, the room fills with more guests than were invited.'}, // [N]
  C:{lore:'A place for a charge. Whoever planted the last one here is long gone, and whoever plants this one should be too.'}, // [N]
  X:{lore:'A charge, armed and counting. No one stands near it on purpose.'}, // [N]
  '#':{lore:'A solid wall. It keeps the dark outside and the light in, or the other way around.'}, // [N]
  B:{lore:'A reinforced blast wall, thick and sealed. Whoever built it expected a bad day.'}, // [N]
  O:{lore:'The objective. A relay, a shrine, a cave mouth. Something that matters more than the people who have come for it.'}, // [N]
  d:{lore:'A closed door. It opens to a hand, a will, or a well-aimed charge.'}, // [N]
  D:{lore:'A locked door, sealed against casual visitors. Locks are only questions, and some people are good at answers.'}, // [N]
  n:{lore:'A nexus of the dark side. The air feels wrong, and a Jedi’s anger grows heavier simply for standing there.'} // [N]
 },
 status:{
  ok:{lore:'On their feet and in good order. Small mercies matter in a long fight.'}, // [N]
  guard:{lore:'Standing at a friend’s shoulder, blade ready. Guarding is an act of faith in the one beside you.'}, // [N]
  overwatch:{lore:'Silent, still, and watching the door. Whoever steps through will be met.'}, // [N]
  down:{lore:'Fallen, but not gone. Someone is already moving to reach them.'}, // [N]
  bleed:{lore:'A wound that will not close by itself. Every second counts, and everyone present knows it.'}, // [N]
  stunned:{lore:'The world has gone soft and distant. A moment’s vulnerability is all the enemy needs.'}, // [N]
  surrender:{lore:'Hands up, weapon down. The Jedi accept the offer, because they were never here to kill anyone they did not have to.'}, // [N]
  captured:{lore:'Held, not harmed. A prisoner is a promise that someone will need to be answered later.'}, // [N]
  disarmed:{lore:'Empty hands in a fight that does not care. Resourcefulness fills in where equipment ends.'}, // [N]
  marked:{lore:'Singled out and called by name. Every weapon on the field now knows who to watch.'}, // [N]
  concealed:{lore:'Unseen, and counting on it. Stillness is a weapon too.'}, // [N]
  suppressed:{lore:'Pinned under steady fire. Raising a head is possible, but costly.'}, // [N]
  hunkered:{lore:'Low and tucked behind cover. Not brave, perhaps, but very much alive.'}, // [N]
  darkness:{lore:'The dark side whispers that the cost of a thing is a reason to do more of it. Jedi who listen find the voice grows louder.'}, // [L H] dark side temptation; [N] phrasing
  stress:{lore:'Fatigue gathers in the shoulders and behind the eyes. A Jedi’s calm is a resource, and it can run low.'}, // [N]
  scar:{lore:'A mark that does not fade. The Jedi wears it, and tries to find some use for what it teaches.'}, // [N]
  panic:{lore:'Fear breaks free of its leash. Training says to breathe, and training is very far away.'}, // [N]
  shaken:{lore:'Hands trembling, voice thin. It passes, usually, and the ones who feel it are not weak for having done so.'}, // [N]
  highground:{lore:'The advantage of height. Seen from above, even an ugly battle makes a certain sense.'} // [N]
 },
 class:{
  Guardian:{lore:'The Guardian stands between harm and the people who cannot defend themselves. Strength, discipline, and a blade that serves protection first.'}, // [L H] Jedi Guardian branch
  Consular:{lore:'The Consular seeks understanding before conflict. Diplomats, healers, and scholars of the Force, they would rather solve a problem than win it.'}, // [L H] Jedi Consular branch
  Sentinel:{lore:'The Sentinel walks between the two paths, balancing combat and insight. Cautious, adaptable, and never quite where the enemy expects.'}, // [L H] Jedi Sentinel branch
  Wayseeker:{lore:'A name from a much later age. In this era the term is unknown, and no Jedi here will answer to it.'}, // [C H] Wayseeker is a High Republic-era term; unavailable in this era
  Soldier:{lore:'The Republic’s trooper: disciplined, loyal, and trained to follow a plan through its worst hour.'}, // [N]
  Scout:{lore:'The scout goes ahead and returns with what the squad needs to know. Quiet, quick, and rarely thanked.'}, // [N]
  Medic:{lore:'The medic runs toward the wounded when everyone else runs away. A kit, a steady voice, and a lot of nerve.'}, // [N]
  Heavy:{lore:'The heavy carries what the others cannot. A big weapon, a big pack, and a stubbornness to match.'}, // [N]
  VIP:{lore:'Someone whose survival matters more than their own preferences. They did not choose the role, and many of them handle it with grace.'} // [N]
 },
 planet:{
  coruscant:{lore:'The capital of the Republic, a world of endless towers and the Jedi Temple above the noise. For centuries it has felt untouchable.'}, // [C/L H] Coruscant, Republic capital and Jedi Temple
  alderaan:{lore:'A world of mountains and old noble houses. In this age it hosts the peace talks that the galaxy has been waiting for.'}, // [L H] Alderaan hosts talks leading to the Treaty of Coruscant
  balmorra:{lore:'A world of foundries and weapon yards, fought over by both sides. Little of it has been left unscarred.'}, // [L H] Balmorra, weapons world contested in the war
  ordMantell:{lore:'A rough Mid Rim world of depots, smugglers, and Republic outposts. Easy to reach, hard to hold.'}, // [L M] Ord Mantell as Mid Rim hub; [N] phrasing
  dantooine:{lore:'Open plains and quiet ruins, once home to a Jedi enclave. Rumor says the grassland hides things that hunt by night.'}, // [L H] Dantooine; [N] rumor phrasing
  narShaddaa:{lore:'The Smuggler’s Moon, a glittering stack of neon and debt. Anything can be bought here, at a price someone else usually pays.'}, // [L H] Nar Shaddaa; [N] phrasing
  ossus:{lore:'A world of ruined Jedi archives, scoured by old wars. The shelves are empty in places, and the silence is not entirely empty.'}, // [L H] Ossus as ruined Jedi archive world
  ilum:{lore:'The ice world where Jedi come to find their kyber. The caves hum with something older than the Order.'}, // [C/L H] Ilum, kyber crystal world
  taris:{lore:'A city world that has been burned and rebuilt more than once. The old towers still stand above the ruins of what they were.'}, // [L M] Taris history; [N] phrasing
  tython:{lore:'The birthplace of the Jedi Order, far from the noise of the core. After the treaty, the Order turns toward it again.'}, // [L M-H] Tython; Order resettles after the treaty
  korriban:{lore:'The tomb world of the ancient Sith. Dust and stone, and a presence that waits.'}, // [L H] Korriban, Sith tomb world
  dromundKaas:{lore:'A jungle world of storms and predators, the seat of the Sith Empire. Its capital rises out of the rain like a threat.'}, // [L H] Dromund Kaas, Sith Empire capital; [N] phrasing
  hydianWay:{lore:'A hyperspace road that carries trade and troops alike. Whoever holds it holds the pulse of the Outer Rim.'}, // [C/L H] Hydian Way trade route
  ruusan:{lore:'A world scarred by a war that burned a thousand years later in memory. Its forests remember the cost of certainty.'} // [L M] Ruusan, Sith/Jedi war; ~1,000 BBY
 },
 character:{
  zym:{lore:'Grand Master of the Order, tired and unyielding. He carries a Council’s worth of doubt, and does not let it show.'}, // [L M] Zym as Master of the Order; [N] characterization
  gnost:{lore:'A Kel Dor Jedi historian, breath-masked and unhurried. He believes that the past is the only teacher that cannot be bribed.'}, // [L H] Gnost-Dural, Kel Dor archivist; [N] phrasing
  darach:{lore:'A Zabrak Jedi Master with a patient smile and a hard-earned scar. He teaches best by letting others make their own mistakes.'}, // [L M] Kao Cen Darach, Zabrak Master; [N] phrasing
  satele:{lore:'A young Knight with a famous name and an unfinished story. She carries the weight of a lineage she did not choose.'}, // [L H] Satele Shan, descendant of Bastila; [N] phrasing
  jace:{lore:'A Republic soldier who has seen too much and complained about it too little. His platoon would follow him anywhere sensible.'}, // [L H] Jace Malcom; [N] characterization
  malgus:{lore:'A Sith Lord of terrible resolve, who struck at the heart of the Republic and meant it. His pain is not hidden, and neither is his power.'}, // [L H] Malgus; [N] phrasing
  adraas:{lore:'A Sith Lord who commanded beside Malgus. He is cold, capable, and he regards the Temple as a trophy waiting to be taken.'}, // [L H] Adraas; [N] characterization
  eleena:{lore:'A Twi’lek who stands at Malgus’s side by choice. She sees more of him than anyone else does, and she is not afraid.'}, // [L H] Eleena Daru; [N] phrasing
  kira:{lore:'A Guardian Knight who leads from the front. She says little about the people she has lost, and carries every name.'}, // [N]
  tor:{lore:'A Consular Padawan with a mind quicker than his nerve. He is learning that courage is just fear that keeps walking.'}, // [N]
  dax:{lore:'A sergeant with twenty years of mud on his boots. He does not believe in luck, and keeps his squad alive anyway.'}, // [N]
  ilsa:{lore:'A scout who moves like a rumor. She prefers to be forgotten, and rarely is.'}, // [N]
  bren:{lore:'A medic with tired hands and a steady voice. He has lost patients, and has never stopped trying for the next one.'}, // [N]
  grak:{lore:'A heavy trooper built like a doorframe. Gentle in the barracks, immovable on the line.'}, // [N]
  saresh:{lore:'A Republic envoy with an easy manner and a careful vocabulary. Whatever he says, there seems to be something else behind it.'}, // [N]
  ondo:{lore:'A Senator with a loyal voice and a long list of enemies. He wants the treaty badly, and the Temple wants him alive to sign it.'}, // [N]
  corin:{lore:'An Imperial officer who changed sides at some personal cost. He is trusted a little less than he deserves, and a little more than he expects.'}, // [N]
  mira:{lore:'An aide who knows where every document is and who has read most of them. Quiet, observant, and indispensable.'}, // [N]
  thulHeir:{lore:'Lady Venna Thul, heir to an old Alderaanian house. She is young, careful, and aware that her name weighs more than she does.'} // [L H] House Thul of Alderaan; [N] Venna Thul
 },
 mission:{
  relay:{lore:'A lonely relay on the frontier, keeping the lanes open for ships that never learn its name. The Sith want it silent, and they are coming in waves.'}, // [N]
  shrine:{lore:'Pilgrims have long come to a kyber shrine on Dantooine. Tonight something else has found it, and it has an appetite for the Force.'}, // [N]
  rescue:{lore:'A supply depot on Ord Mantell holds prisoners who matter to someone. The plan is simple, which means it will not go simply.'}, // [N]
  envoy:{lore:'Schedules leaked, secrets traded, and a trail that winds through the lower city. Someone near the talks is selling the Republic.'}, // [N]
  archive:{lore:'An Imperial listening post on Balmorra, tucked between foundries. What it hears could hurt the Republic, and what it holds could help.'}, // [N]
  sabotage:{lore:'An Imperial fuel depot on Balmorra, vast and poorly lit. A well-placed charge here could stall an advance for weeks.'}, // [N]
  escort:{lore:'A Senator must walk the length of Coruscant’s lower streets to reach the talks. The Temple walks with him.'}, // [N]
  blockade:{lore:'Mandalorians in Imperial pay have closed a stretch of the Hydian Way. A convoy is counting on the squad to open it.'}, // [N]
  cache:{lore:'A listening post on the Inner Rim has gone quiet. The squad is sent to find out why before anyone else does.'}, // [N]
  hutt:{lore:'A Hutt warehouse on Nar Shaddaa holds a ledger of debts and deals. In the right hands it could change the war.'}, // [N]
  dock:{lore:'Docking Ring Nine. Malgus is coming for the Temple, and the Jedi have one chance to stop him at the door.'}, // [L H] Malgus’s strike on the Temple; [N] mission framing
  vault:{lore:'Beneath the ruins of Ossus lie old records of the Sith wars. Gnost-Dural wants them saved, and the Empire wants them first.'}, // [L H] Ossus ruins, Gnost-Dural; [N] vault mission
  ilum:{lore:'A cave mouth on Ilum, cold and humming. Sergeant Malcom’s platoon holds it, and the Jedi arrive in time to share the watch.'}, // [N]
  adraasHunt:{lore:'During the talks on Alderaan, Satele Shan leads a strike on Lord Adraas at an embassy hangar. It is a gamble with the treaty as the stake.'}, // [L H] Adraas, Satele Shan; [N] mission framing
  taris:{lore:'A reclamation camp on Taris, where captives were put to work. The Jedi come to open the gates, and to see who is still inside.'}, // [N]
  thul:{lore:'The heir to House Thul must cross Alderaan unseen. The Jedi go with her, because some journeys are not safe alone.'}, // [L H] House Thul of Alderaan; [N] mission framing
  depot:{lore:'Forward Depot Cresh keeps the enemy fed and armed. Take away the depot and the front shifts.'}, // [N]
  fort:{lore:'Fort Garnik on Ord Mantell is old, battered, and still standing. The Republic means to keep it that way.'} // [N]
 },
 research:{}
};
