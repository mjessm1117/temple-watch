/* Era 2 (Ruusan) versions of the wave-5/6 maps (Chat M3, wave 7). Loads after data-maps.js.
   Each row copies an Era 1 layout (found by name in that mission's alts), swaps foes to the Brotherhood (RU_FOES, data-era2.js),
   retitles it for Ruusan and adds it as a random layout (`alts`) of the Era 2 crisis. Layouts are not mirrored, so mapcheck results carry over.
   Per-map balance: TUNE rows "<era2 id>:<n>" at the bottom (first pass = the Era 1 row for the same layout; B2 owns retuning). */
const RU_MAPS=[
 // ---- r_hospital (defend) ----
 {to:'r_hospital',from:'shrine',name:'Dantooine Crossroads',n:'The Burned Crossroads',where:'Crossroads aid station · Ruusan plains',theme:'plains',
  brief:'An aid station sits where four farm roads meet. Brotherhood raiders come down every road at once. No single wall to hide behind.',
  goal:'Hold the aid station for 7 turns. Watch the red marks: that is where the next group comes in.'},
 {to:'r_hospital',from:'shrine',name:'Frozen Watchpost',n:'Hilltop Aid Post',where:'Hilltop aid post · Ruusan highlands',theme:'plains',
  brief:'The wounded are laid out on a bare hilltop. Four rock ledges see the whole slope; whoever holds them holds the post.',
  goal:'Hold the post for 7 turns. Raiders climb in from all four corners. Take the ledges before they do.'},
 // ---- r_supply (defend) ----
 {to:'r_supply',from:'shrine',name:'Shrine Terraces',n:'The Terraced Granary',where:'Terraced farm depot · Ruusan',theme:'plains',
  brief:'The Army\'s grain sits in a farm depot cut into the hillside. High terraces look down on every approach.',
  goal:'Hold the depot for 7 turns. Take the high ground first.'},
 {to:'r_supply',from:'shrine',name:'Hold the Ford',n:'The Ruusan Ford',where:'River ford · Ruusan woods',theme:'jungle',
  brief:'The supply wagons must cross a river ford two tiles wide. Take the far bank, hold it while they cross, then fall back.',
  goal:'Take the far bank, hold it 2 turns, then fall back across the ford. Raiders come down both banks.',
  win:'The last wagon is across. The front eats.',lose:'The ford is cut. The wagons turn back.',
  ph:['Cross and take the far bank','Hold the far bank while the wagons cross','Fall back across the ford to the evac']},
 // ---- r_prisoners (rescue) ----
 {to:'r_prisoners',from:'rescue',name:'Detention Level 5',n:'The Hulk\'s Brig',where:'Brig of a grounded prison hulk · Ruusan',theme:'dock',
  brief:'The healer is locked in a cell deep in the hulk\'s brig. Narrow corridors, doors everywhere, guards at both ends.',
  goal:'Open the cell (hack the door or use the console), then walk the prisoner to an evac zone (E).'},
 {to:'r_prisoners',from:'rescue',name:'Smuggler Grotto',n:'The Cave Pens',where:'Brotherhood cave pens · Ruusan',theme:'caves',
  brief:'The Brotherhood keeps prisoners in a rock pen at the back of a cave. Two tunnels feed it; guards come through both.',
  goal:'Open the cell (hack the door or use the console), then walk the prisoner to an evac zone (E).'},
 // ---- r_codes (investigate) ----
 {to:'r_codes',from:'archive',name:'Antenna Ridge',n:'Signal Ridge',where:'Brotherhood signal mast · Ruusan ridge',theme:'plains',
  brief:'Kaan\'s orders go out from a mast on a bare ridge. Take the ridge, hold it while the codes copy, then get down.',
  goal:'Three steps: take the ridge, hold it 2 turns, then get everyone to an evac zone.',
  win:'Kaan\'s orders are ours for a month.',lose:'The camp burns its codes before the copy finishes.'},
 {to:'r_codes',from:'archive',name:'Listening Post Interior',n:'The Signal Bunker',where:'Brotherhood signal bunker · Ruusan',theme:'ruins',
  brief:'The signal camp is dug in: a warren of rooms. Three code terminals, guards in most rooms.',
  goal:'Copy 2 of the 3 terminals (q), then get to an evac zone.'},
 {to:'r_codes',from:'archive',name:'Overgrown Relay',n:'The Forest Relay',where:'Old relay in the Ruusan woods',theme:'jungle',
  brief:'The Brotherhood hid a relay in an old ruin the forest took back. Three terminals, thick cover, patrols on the paths.',
  goal:'Scan 2 of 3 terminals (q), then reach an evac zone.'},
 // ---- r_dump (sabotage) ----
 {to:'r_dump',from:'sabotage',name:'Balmorra Fuel Farm',n:'The Fuel Farm',where:'Brotherhood fuel farm · Ruusan plains',theme:'plains',
  brief:'Kaan\'s walkers drink from this tank farm. Catwalks and pipe runs split it into lanes.',
  goal:'Plant charges on 2 of the 3 sites (C), then everyone to the evac zone.'},
 {to:'r_dump',from:'sabotage',name:'Refinery Stacks',n:'The Quarry Magazines',where:'Quarry powder magazines · Ruusan',theme:'ruins',
  brief:'The Brotherhood stores its munitions in an old quarry cut in tiers. Every ledge is a sniper nest.',
  goal:'Plant charges on 2 of the 3 sites (C), then everyone to the evac zone.'},
 // ---- r_snipers (escort) ----
 {to:'r_snipers',from:'escort',name:'Canyon Run',n:'The Dry Gorge',where:'Dry gorge below the ridge · Ruusan',theme:'plains',
  brief:'The courier must run the length of a dry gorge to the shuttle. Snipers hold the rim.',
  goal:'Get the courier to the evac zone at the far end of the gorge.'},
 {to:'r_snipers',from:'escort',name:'Deepway Tunnels',n:'Under the Ridge',where:'Old mine under the ridge · Ruusan',theme:'caves',vip:'courier',
  brief:'The ridge is crawling with snipers, so the courier goes under it, through an old mine. The west gallery is long and exposed.',
  goal:'Get the courier to the evac lift in the far corner. Watch the ledges.'}];

// Swap every foe name in a layout for its Brotherhood version.
function ruusanFoes(M){const f=t=>typeof t==='string'?(RU_FOES[t]||t):t,L=a=>a&&a.map(f);
 if(M.foes)M.foes=M.foes.map(([t,...r])=>[f(t),...r]);if(M.reinforce)M.reinforce=L(M.reinforce);
 if(M.waves){const w={};for(const k in M.waves)w[k]=L(M.waves[k]);M.waves=w}
 if(M.phases)M.phases=M.phases.map(p=>({...p,wave:L(p.wave),foe:p.foe&&[f(p.foe[0]),...p.foe.slice(1)]}));return M}

const RU_TUNE={};
for(const r of RU_MAPS){const S0=MISSIONS[r.from],B=MISSIONS[r.to];if(!S0||!B)continue;const ix=(S0.alts||[]).findIndex(a=>a.n===r.name);if(ix<0)continue;
 const src=JSON.parse(JSON.stringify(S0.alts[ix])),{to,from,name,ph,...over}=r;
 const M=ruusanFoes({...src,...over,era:2,quote:undefined});if(ph&&M.phases)M.phases.forEach((p,i)=>{if(ph[i])p.n=ph[i]});
 (B.alts=B.alts||[]).push(M);const t=TUNE[from+':'+(ix+1)];if(t)RU_TUNE[to+':'+B.alts.length]={...t}}
// Measured 8 bot games each (Normal, 2026-10-22): the Era 1 rows were too hard with Brotherhood foes on these two.
Object.assign(RU_TUNE,{'r_hospital:2':{aim:-15,hp:-1},'r_prisoners:2':{aim:-5}});
Object.assign(TUNE,RU_TUNE);
