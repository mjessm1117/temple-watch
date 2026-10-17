/* Saves: campaign C + live mission S, always local; also synced to the Cloudflare backend when a sync code is set. */
const SKEY='templewatch-save-v2',SYNCK='templewatch-sync';
let SCR=null;   // the screen function currently shown in the modal (to redraw after the sync dialog)
const syncCode=()=>{try{return localStorage.getItem(SYNCK)||''}catch(e){return ''}};
function setSync(t){const el=$('#sSync');if(el)el.textContent=t}
// Returns the server's JSON (null = no save yet), or undefined when sync is off or unreachable.
async function remote(method,body){const k=syncCode();if(!k)return undefined;
 try{const r=await fetch('/api/save',{method,headers:{'x-sync':k,'content-type':'application/json'},body,cache:'no-store'});if(!r.ok)throw 0;setSync('synced');return await r.json()}
 catch(e){setSync('offline');return undefined}}
function packS(){if(!S||S.over)return null;const{M,d,fx,peek,pick,hpath,...rest}=S;return{...rest,fx:[],sel:S.units.indexOf(S.sel)}}
function saveData(){return{v:2,C,S:packS(),at:Date.now()}}
function saveGame(){if(!C&&!S)return;const data=saveData(),txt=JSON.stringify(data);
 try{localStorage.setItem(SKEY,txt)}catch(e){}
 remote('PUT',txt)}
function loadSave(){try{const s=JSON.parse(localStorage.getItem(SKEY)||'null');return s&&s.v===2&&s.C?s:null}catch(e){return null}}
async function pullRemote(){const r=await remote('GET');const l=loadSave();
 if(r&&r.v===2&&r.at&&(!l||r.at>(l.at||0))){try{localStorage.setItem(SKEY,JSON.stringify(r))}catch(e){}return true}return false}
function syncDialog(){const m=$('#modal');const wasOpen=!m.hidden;m.hidden=false;
 m.innerHTML=`<div class="box"><div class="eyebrow">Cross-device saves</div><h2>Sync code</h2>
 <p>Type the same code on your phone and your laptop. Your save follows you. Use 6+ characters; anyone with the code can load your save.</p>
 <input id="syncIn" type="text" autocomplete="off" autocapitalize="off" spellcheck="false" value="${syncCode().replace(/"/g,'')}">
 <p class="muted" id="syncMsg"></p><div class="endrow"><button type="button" id="syncCancel">Cancel</button><button type="button" class="primary" id="syncOk">Save code</button></div></div>`;
 const close=()=>{if(wasOpen&&SCR)SCR(true);else m.hidden=true};
 $('#syncCancel').onclick=close;
 $('#syncOk').onclick=async()=>{const v=$('#syncIn').value.trim();if(v&&v.length<6){$('#syncMsg').textContent='Use at least 6 characters.';return}
  try{v?localStorage.setItem(SYNCK,v):localStorage.removeItem(SYNCK)}catch(e){}
  if(!v){setSync('off');return close()}
  $('#syncMsg').textContent='Checking…';const ok=await remote('GET');
  if(ok===undefined){$('#syncMsg').textContent='Could not reach the save server. Sync works only on the Cloudflare site.';return}
  const pulled=await pullRemote();if(!pulled&&(C||S))saveGame();close()}}
function continueGame(d){C=d.C;
 if(d.S){S={...d.S,M:(B=>d.S.mapIx&&B.alts&&B.alts[d.S.mapIx-1]?{...B,...B.alts[d.S.mapIx-1]}:B)(MISSIONS[d.S.id]),d:DIFF[d.S.diff],fx:[],peek:null,pick:null,phase:'player',mode:'move',tg:[]};S.sel=S.units[d.S.sel]||null;$('#modal').hidden=true;SCR=null;log('Save loaded.');render()}
 else{S=null;baseScreen()}}
