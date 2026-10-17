/* Galaxy map + field ops data (Chat I). Logic: galaxy.js (map, briefing panel) and fieldops.js (off-screen teams).
   Map is stylized: a 600×380 disc, regions as rings around the Deep Core. Planet spots follow the canon grid roughly (north = up).
   Lore confidence per planet in comments: H/M/L. Regions checked 2026-10-16 (Ruusan: starwars.archivum.wiki, Teraab sector, Mid Rim). */
const GAL_C={x:300,y:190,ry:.6};
// Rings, inner to outer: [id, name, outer radius (x), one-line note]. Unknown Regions is drawn separately (west).
const REGIONS=[
 ['deep','Deep Core',30,'Old, crowded stars. Few lanes reach in.'],
 ['core','Core Worlds',62,'Coruscant and the oldest Republic worlds. The Senate listens to them first.'],
 ['colonies','Colonies',95,'The first worlds settled from the Core. Rich, loyal, nervous.'],
 ['inner','Inner Rim',130,'Settled frontier of an older age. Trade lanes, shipyards, refugees.'],
 ['mid','Mid Rim',185,'Thinly policed worlds between Republic and lawless space.'],
 ['outer','Outer Rim',255,'The edge. Hutts, pirates, Sith raiders, and worlds the Senate forgets.'],
 ['unknown','Unknown Regions',0,'Unmapped space beyond the western rim. Ilum hides here.']];
const REG_N=Object.fromEntries(REGIONS.map(r=>[r[0],r[1]]));
// Planet → spot + region. The `where` field of a mission ("Hill fort · Ord Mantell") is matched on the part after the dot.
const PLANETS={
 'Coruscant':{x:300,y:182,reg:'core'},            // H: Core, grid L-9
 'Alderaan':{x:335,y:200,reg:'core'},             // H: Core, grid M-10
 'Balmorra':{x:360,y:165,reg:'colonies'},         // L: Colonies (recall; SWTOR planet)
 'Inner Rim':{x:200,y:225,reg:'inner'},
 'Ord Mantell':{x:290,y:85,reg:'mid'},            // H: Mid Rim, grid L-7
 'Mid Rim':{x:185,y:265,reg:'mid'},
 'Hydian Way':{x:455,y:205,reg:'mid'},            // M: the Hydian Way runs north–south through the eastern Mid/Outer Rim
 'Ruusan':{x:395,y:272,reg:'mid'},                // M: Teraab sector, Mid Rim (Legends)
 'Dantooine':{x:280,y:50,reg:'outer'},            // H: Outer Rim, grid L-4
 'Taris':{x:430,y:80,reg:'outer'},                // M: Outer Rim (Legends, KOTOR)
 'Sith frontier':{x:500,y:110,reg:'outer'},       // M: Sith space lies out past the north-east rim (Korriban grid R-5)
 'Nar Shaddaa':{x:515,y:250,reg:'outer'},         // M: Y'Toub system, Hutt Space, Outer Rim
 'Ossus':{x:470,y:300,reg:'outer'},               // L-M: Outer Rim (Legends)
 'Ilum':{x:72,y:160,reg:'unknown'}};              // H: Unknown Regions (canon + Legends)
// Pin look by mission type / option kind. ic = icons.js key.
const PIN={story:{c:'var(--holo)',ic:'relay'},crisis:{c:'var(--troop)',ic:'strike'},rescue:{c:'var(--sith)',ic:'captured'},quest:{c:'var(--good)',ic:'kyber'},
 redeem:{c:'var(--dark)',ic:'darkness'},field:{c:'#a7c7cc',ic:'scan'}};
const TYPE_IC={defend:'guard',rescue:'captured',investigate:'scan',assault:'strike',sabotage:'charge',escort:'evac'};
// Risk bands from the enemy-power estimate in galaxy.js (riskOf). Tuned so the opening relay reads Moderate on Normal.
const RISK=[[0,'Low',1],[46,'Moderate',2],[64,'High',3],[86,'Severe',4]];

// ── Field ops: 2–3 units leave for X days, resolve on a roll, never die (spec B §7 never lose). ──
// want = classes that fit the job ('jedi' = any Jedi). stars = difficulty 1–3. days = time away (1 mission = DAYS = 15 days).
const FIELD_OPS={
 convoy:{n:'Relief convoy',want:['Medic','Consular'],days:15,stars:1,res:{favor:5},desc:'Escort bacta and grain to a world the war forgot.'},
 smugglers:{n:'Smuggler route',want:['Scout','Sentinel'],days:15,stars:1,res:{intel:2},desc:'Trace the spice route the Empire uses to move its agents.'},
 pirates:{n:'Pirate cell',want:['Soldier','Heavy','Guardian'],days:15,stars:2,res:{credits:90},desc:'Break a pirate crew preying on Republic freighters. Their hold pays.'},
 pilgrimage:{n:'Kyber pilgrimage',want:['jedi'],days:30,stars:2,res:{kyber:1},desc:'A cave sings in the Force. A Jedi must go and listen.'},
 militia:{n:'Train a militia',want:['Soldier','Guardian'],days:30,stars:1,res:{favor:6,recruits:1},desc:'Drill farmers into a militia. One of them may follow you home.'},
 shadow:{n:'Shadow an agent',want:['Scout','Sentinel'],days:15,stars:3,res:{intel:3},desc:'An Imperial agent is meeting a senator\'s aide. Watch, record, stay unseen.'},
 broker:{n:'Talk to a broker',want:['Consular'],days:15,stars:2,res:{credits:110},desc:'A Hutt broker owes the Republic. Collect, politely.'},
 ruins:{n:'Survey the ruins',want:['jedi','Scout'],days:30,stars:2,res:{intel:2,kyber:1},desc:'Old Jedi ruins, half buried. Something in them still hums.'},
 pilots:{n:'Downed pilots',want:['Medic','Scout'],days:15,stars:2,res:{favor:4,intel:1},desc:'A Republic flight went down behind the lines. Find them first.'},
 mines:{n:'Clear the lanes',want:['Heavy','Soldier'],days:15,stars:2,res:{credits:60,favor:3},desc:'Sith mines choke a trade lane. Clear them, convoy by convoy.'}};
const FIELD={base:45,perRank:5,match:10,matchMax:2,three:8,star:12,min:10,max:92,   // odds = base + 5×Σrank + 10×fits (max 2) + 8 if 3 go − 12×(stars−1)
 xp:15,expire:30,perMonth:[1,2],team:[2,3],failStress:15,failWound:10,badRoll:12,badWound:20,log:6};   // badRoll: the top 12% of rolls is a bad fail (one serious wound)
// Field op planets per era (no Coruscant: ops leave the Temple).
const FIELD_PLANETS={1:['Balmorra','Ord Mantell','Dantooine','Taris','Nar Shaddaa','Ossus','Alderaan','Hydian Way'],
 2:['Ruusan','Ord Mantell','Dantooine','Nar Shaddaa','Ossus','Hydian Way','Balmorra']};
