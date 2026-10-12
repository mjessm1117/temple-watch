/* Opening vision + new campaign / continue. Boot runs last. */
function briefing(noPull){SCR=briefing;const m=$('#modal');m.hidden=false;
 if(!noPull&&syncCode())pullRemote().then(ch=>{if(ch&&SCR===briefing)briefing(true)});
 const sv=loadSave();
 m.innerHTML=`<div class="box"><div class="eyebrow">Jedi Council · Coruscant · ~3,660 BBY</div><h2>A vision of fire</h2>
 <p>In meditation, the whole Council saw the same thing: the Temple burning, clone soldiers on its steps, a hooded figure in a red-lit office. Nobody knows when. Grand Master Zym orders it sealed in the Archives.</p>
 <p>That sealed record is your campaign. The Sith Empire is pushing toward peace talks it doesn't mean. Run the Temple, send squads where they matter, and bend what's coming.</p>
 ${sv?`<button class="choice" type="button" id="cont"><b>Continue campaign</b><span>${sv.S?`Resume ${MISSIONS[sv.S.id].n}, turn ${sv.S.turn}.`:`Month ${sv.C.month}, back at the Temple.`}</span></button>`:''}
 <p class="eyebrow">${sv?'Or start a new campaign. Difficulty:':'New campaign. Difficulty:'}</p>
 <button class="choice" type="button" data-d="story"><b>Story</b><span>Weaker enemies, 6 turns to bleed out, an extra medkit, more Senate money.</span></button>
 <button class="choice" type="button" data-d="normal"><b>Normal</b><span>The intended fight. 4 turns to bleed out. Misses in a row get a hidden aim boost.</span></button>
 <button class="choice" type="button" data-d="hard"><b>Hard</b><span>Sharper enemies, an extra trooper per wave, 3 turns to bleed out, no aim help.</span></button>
 <button class="choice" type="button" data-d="legend"><b>Legend</b><span>Tougher, sharper enemies and 2 turns to bleed out. Expect losses.</span></button></div>`;
 m.onclick=null;m.querySelectorAll('[data-d]').forEach(b=>b.onclick=()=>newCampaign(b.dataset.d));
 const c=m.querySelector('#cont');if(c)c.onclick=()=>continueGame(loadSave())}

briefing();
