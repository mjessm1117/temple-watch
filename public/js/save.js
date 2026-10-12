/* Saves: local + cloud sync via /api/save. */
const SKEY='templewatch-save-v1';
/* Saves: always local; also synced to the Cloudflare backend when a sync code is set. */
const SYNCK='templewatch-sync';
const syncCode=()=>{try{return localStorage.getItem(SYNCK)||''}catch(e){return ''}};
function setSync(t){const el=$('#sSync');if(el)el.textContent=t}
// Returns the server's JSON (null = no save yet), or undefined when sync is off or unreachable.
async function remote(method,body){const k=syncCode();if(!k)return undefined;
 try{const r=await fetch('/api/save',{method,headers:{'x-sync':k,'content-type':'application/json'},body,cache:'no-store'});if(!r.ok)throw 0;setSync('synced');return await r.json()}
 catch(e){setSync('offline');return undefined}}
function saveGame(){const data=S.over?{over:true,at:Date.now()}:{...S,fx:[],peek:null,sel:S.units.indexOf(S.sel),at:Date.now()};
 try{S.over?localStorage.removeItem(SKEY):localStorage.setItem(SKEY,JSON.stringify(data))}catch(e){}
 remote('PUT',JSON.stringify(data))}
function loadSave(){try{const s=JSON.parse(localStorage.getItem(SKEY)||'null');return s&&!s.over?s:null}catch(e){return null}}
async function pullRemote(){const r=await remote('GET');const l=loadSave();
 if(r&&r.at&&(!l||r.at>(l.at||0))){try{r.over?localStorage.removeItem(SKEY):localStorage.setItem(SKEY,JSON.stringify(r))}catch(e){}return true}return false}
function syncDialog(){const m=$('#modal');const back=m.hidden?null:m.innerHTML;m.hidden=false;
 m.innerHTML=`<div class="box"><div class="eyebrow">Cross-device saves</div><h2>Sync code</h2>
 <p>Type the same code on your phone and your laptop. Your save follows you. Use 6+ characters; anyone with the code can load your save.</p>
 <input id="syncIn" type="text" autocomplete="off" autocapitalize="off" spellcheck="false" value="${syncCode().replace(/"/g,'')}" style="font:500 16px var(--mono);padding:10px;border-radius:6px;border:1px solid var(--line);background:var(--raise);color:var(--fg)">
 <p class="muted" id="syncMsg"></p><div class="endrow"><button type="button" id="syncCancel">Cancel</button><button type="button" class="primary" id="syncOk">Save code</button></div></div>`;
 const close=()=>{if(back!=null)briefing(true);else m.hidden=true};
 $('#syncCancel').onclick=close;
 $('#syncOk').onclick=async()=>{const v=$('#syncIn').value.trim();if(v&&v.length<6){$('#syncMsg').textContent='Use at least 6 characters.';return}
  try{v?localStorage.setItem(SYNCK,v):localStorage.removeItem(SYNCK)}catch(e){}
  if(!v){setSync('off');return close()}
  $('#syncMsg').textContent='Checking…';const ok=await remote('GET');
  if(ok===undefined){$('#syncMsg').textContent='Could not reach the save server. Sync works only on the Cloudflare site.';return}
  await pullRemote();if(back!=null)briefing(true);else{m.hidden=true;saveGame()}}}
function continueGame(d){S={...d,fx:[],peek:null,phase:'player',mode:'move',tg:[]};S.sel=S.units[d.sel]||null;$('#modal').hidden=true;log('Save loaded.');render()}
