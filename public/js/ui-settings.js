/* Settings (Chat U): animation speed, cinematics, reduced motion, show numbers. Saved per browser.
   Other files read window.SETTINGS: speed (1 = normal; divide waits by it), cine (cinematics on), numbers (Info default),
   and reducedMotion() (setting or the OS preference). Loads right after util.js. */
const SET_KEY='tw.settings';
window.SETTINGS=Object.assign({speed:1,cine:true,motion:'auto',numbers:false},(()=>{try{return JSON.parse(localStorage.getItem(SET_KEY))||{}}catch{return {}}})());
SETTINGS.reducedMotion=()=>SETTINGS.motion==='on'||(SETTINGS.motion==='auto'&&!!window.matchMedia&&matchMedia('(prefers-reduced-motion: reduce)').matches);
function saveSettings(){const {reducedMotion,...o}=SETTINGS;try{localStorage.setItem(SET_KEY,JSON.stringify(o))}catch{}applySettings()}
function applySettings(){document.documentElement.classList.toggle('rm',SETTINGS.reducedMotion());
 document.documentElement.style.setProperty('--spd',String(SETTINGS.speed))}
const SET_OPTS=[
 ['speed','Animation speed','How fast enemy turns and effects play.',[[.5,'Slow'],[1,'Normal'],[2,'Fast'],[4,'Instant']]],
 ['cine','Cinematics','Kill cams, Force-power camera and enemy-reveal pans (3D view).',[[true,'On'],[false,'Off']]],
 ['motion','Reduced motion','Stops sweeps, pulses and floating numbers. Auto follows your device setting.',[['auto','Auto'],['on','On'],['off','Off']]],
 ['numbers','Show numbers','Start each mission with Info on: HP numbers and full stat grids.',[[true,'On'],[false,'Off']]]];
function settingsOpen(){const o=uiLayer('settings');
 o.innerHTML=`<div class="ui-card" role="dialog" aria-label="Settings"><div class="ui-head"><h2>Settings</h2><button type="button" data-ui="close" aria-label="Close">✕</button></div>
 ${SET_OPTS.map(([k,n,d,v])=>`<div class="setrow"><div><b>${n}</b><small>${d}</small></div><div class="seg">${v.map(([val,l])=>`<button type="button" class="${SETTINGS[k]===val?'on':''}" data-set="${k}" data-v='${JSON.stringify(val)}'>${l}</button>`).join('')}</div></div>`).join('')}
 <p class="muted small">Saved on this device.</p></div>`}
// Shared overlay layer for Settings / Codex / Keys (sits above #modal).
function uiLayer(id){let o=document.getElementById('ui-'+id);
 if(!o){o=document.createElement('div');o.id='ui-'+id;o.className='uilayer';document.body.appendChild(o);
  o.addEventListener('click',ev=>{if(ev.target===o||ev.target.closest('[data-ui="close"]'))return uiClose();const b=ev.target.closest('[data-set]');
   if(b){SETTINGS[b.dataset.set]=JSON.parse(b.dataset.v);if(b.dataset.set==="numbers"&&typeof S!=="undefined"&&S)S.info=SETTINGS.numbers;saveSettings();settingsOpen();if(typeof S!=="undefined"&&S)render()}})}
 for(const l of document.querySelectorAll('.uilayer'))l.hidden=l!==o;o.hidden=false;return o}
const uiOpen=()=>[...document.querySelectorAll('.uilayer')].some(l=>!l.hidden);
function uiClose(){for(const l of document.querySelectorAll('.uilayer'))l.hidden=true}
applySettings();
if(window.matchMedia)matchMedia('(prefers-reduced-motion: reduce)').addEventListener?.('change',applySettings);
