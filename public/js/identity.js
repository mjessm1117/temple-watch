/* Squad identity (bucket 1, Coordinator, 2026-10-19). Data: data-identity.js.
   - Voices: every unit gets a personality (r.voice) with its own lines; speech bubbles in 2D and 3D; the best line of the mission shows in the debrief.
   - Nicknames: deeds in battle (r.deeds) suggest names; you pick or type one at promotion, or rename in the identity editor.
   - Padawans: auto-paired with a free Knight/Master; in battle +aim near their Master, and a Padawan kill gives the Master Focus.
   Loaded after story.js/legacy.js/skills.js so its wrappers sit outermost. */

// --- voices ---
function ensureVoices(){if(!C)return;const used={};for(const r of C.roster)if(r.voice&&VOICES[r.voice])used[r.voice]=(used[r.voice]||0)+1;
 for(const r of C.roster){if(r.voice&&VOICES[r.voice])continue;const who=isJedi(r)?'jedi':'troop',pool=Object.keys(VOICES).filter(k=>VOICES[k].who===who);
  const min=Math.min(...pool.map(k=>used[k]||0)),pick=pickOne(pool.filter(k=>(used[k]||0)===min));r.voice=pick;used[pick]=(used[pick]||0)+1}}
const voiceOf=u=>{const r=C&&u.rid&&C.roster.find(r=>r.id===u.rid);return r&&VOICES[r.voice]};
// Replaces story.js bark(): named heroes keep their lines, then the unit's voice, then the trait/default barks.
let sayT={};
bark=function(u,ev){if(!u||u.side!=='p'||u.vip||!S||S.over)return;const k=u.rid+'|'+S.turn,must=ev==='down'||ev==='panic';
 if(!must&&(sayT[k]||!rnd(ev==='select'?25:ev==='hit'?40:60)))return;
 const r=C&&C.roster.find(r=>r.id===u.rid),dflt=u.jedi?BARKS.jedi:BARKS.troop,v=voiceOf(u),hero=HERO_BARKS[u.n];
 const L=(hero&&hero[ev])||(v&&v[ev])||(r&&r.trait&&BARKS[r.trait]&&BARKS[r.trait][ev])||dflt[ev];
 if(!L)return;sayT[k]=1;const txt=pickOne(L);log(`${u.n}: “${txt}”`,'bark');fx('bark',{u,txt,ev});
 // Remember the line for the debrief: kills and crits beat everything else.
 const rank={kill:3,crit:3,allyDown:2,down:2,hit:1,panic:1,select:0}[ev]||0;S.said=S.said||{};const o=S.said[u.rid];if(!o||rank>=o.rank)S.said[u.rid]={txt,rank}};
// 2D speech bubble (the 3D view draws its own from the same 'bark' event).
onFx((type,d)=>{if(type!=='bark'||!S)return;S.say=(S.say||[]).filter(b=>b.u!==d.u);const b={u:d.u,txt:d.txt};S.say.push(b);
 setTimeout(()=>{if(!S||!S.say)return;S.say=S.say.filter(x=>x!==b);if(typeof render==='function')render()},Math.min(4000,1800+d.txt.length*45))});
// Selecting a unit sometimes gets a word back; an ally going down makes the nearest friend shout.
const _selectI=select;select=function(u){const r=_selectI(u);if(u&&u.side==='p'&&S.phase==='player'&&S.selSaid!==S.turn){S.selSaid=S.turn;bark(u,'select')}return r};

// --- deeds (battle counters on u._dd, folded into r.deeds after the mission) ---
const dd=u=>u._dd=u._dd||{crit:0,melee:0,tank:0};
const _logI=log;log=function(t,c){if(S&&typeof t==='string'&&/critical hit/i.test(t))S._critI=1;return _logI(t,c)};
onFx((type,d)=>{if(!S)return;
 if(type==='shot')S._shotI=d;
 else if(type==='hit'){if(d.t&&d.t.side==='p'&&!d.t.vip){dd(d.t).tank+=d.d||0;if(d.t.status==='ok'&&!S._critI)bark(d.t,'hit')}
  if(S._critI&&d.src&&d.src.side==='p')dd(d.src).crit++;S._critI=0}
 else if(type==='kill'&&d.src&&d.src.side==='p'){const s=S._shotI;if(s&&s.a===d.src&&s.melee)dd(d.src).melee++;
  // Padawan kill → their Master gains Focus.
  if(d.src.master){const m=players().find(p=>p.rid===d.src.master&&p.status==='ok');if(m&&m.maxF){m.focus=Math.min(m.maxF,(m.focus||0)+PAD.focus);fx(m,'+'+PAD.focus+' FOCUS','heal');log(`${m.n} feels ${d.src.n}'s strike through the Force. +${PAD.focus} Focus.`,'good')}}}
 else if(type==='down'&&d.t&&d.t.side==='p'&&!d.t.vip){const near=players().filter(p=>p!==d.t&&p.status==='ok'&&!p.vip).sort((a,b)=>dist(a,d.t)-dist(b,d.t))[0];
  if(near&&dist(near,d.t)<=8){sayT[near.rid+'|'+S.turn]=0;bark(near,'allyDown')}}});
const _applyI=applyResults;applyResults=function(win){const said=S.said||{},snap=S.units.filter(u=>u.side==='p'&&u.rid&&!u.vip).map(u=>({rid:u.rid,u,saver:u.savedBy}));
 const out=_applyI(win);
 for(const {rid,u,saver} of snap){const r=C.roster.find(r=>r.id===rid);if(!r)continue;const D=r.deeds=r.deeds||{},x=u._dd||{};
  const add=(k,n)=>{if(n)D[k]=(D[k]||0)+n};add('crit',x.crit);add('melee',x.melee);add('tank',x.tank);add('kill',u.kills||0);add('cap',u.caps||0);
  if((u.kills||0)>=3)add('multi',1);if(u.downed&&u.status!=='dead')add('downed',1);if(win&&u.status==='ok'&&u.hp===1)add('clutch',1);
  if(saver&&saver!==rid){const s=C.roster.find(r=>r.id===saver);if(s){s.deeds=s.deeds||{};s.deeds.save=(s.deeds.save||0)+1}}
  D.mission=r.missions||0;
  if(said[rid]&&r.status!=='dead'){r.quotes=r.quotes||[];r.quotes.unshift({t:said[rid].txt,w:typeof stamp==='function'?stamp():''});r.quotes.length=Math.min(r.quotes.length,3)}}
 out.said=Object.entries(said).map(([rid,s])=>({rid,txt:s.txt,rank:s.rank})).sort((a,b)=>b.rank-a.rank).slice(0,2);return out};

// --- nicknames ---
const nickText=r=>r&&r.nick?(isJedi(r)?r.nick:`“${r.nick}”`):'';
const fullName=r=>r.nick?(isJedi(r)?`${r.n}, ${r.nick}`:`${r.n} “${r.nick}”`):r.n;
function nickOpts(r){const j=isJedi(r),taken=new Set(C.roster.filter(x=>x!==r&&x.nick).map(x=>x.nick)),D=r.deeds||{},out=[];
 for(const e of DEEDS)if((D[e.k]||0)>=e.at){const n=j?e.jedi:e.troop;if(n!==r.nick&&!taken.has(n)&&!out.some(o=>o.n===n))out.push({n,why:e.why})}
 for(const n of (j?NICK_CLASS.jedi:NICK_CLASS[r.cls]||NICK_CLASS.Soldier))if(out.length<3&&n!==r.nick&&!taken.has(n)&&!out.some(o=>o.n===n))out.push({n,why:'fits the role'});
 return out.slice(0,3)}
function setNick(id,n){const r=unit(id);if(!r)return;n=clean(n,NICK_MAX);r.nick=n||null;if(n&&typeof lifeLog==='function')lifeLog(r,`Earned the name ${nickText(r)}`);saveGame()}
const _promoI=promoHTML;promoHTML=function(out){let h=_promoI(out);if(!out||!out.promo.length)return h;
 const rows=out.promo.map(id=>{const r=unit(id);if(!r||r.status!=='active')return '';const done=out.nicked&&out.nicked[id];
  if(done)return `<div class="nickrow"><b>${fullName(r)}</b> <small class="up">${done}</small></div>`;
  return `<div class="nickrow"><b>${r.n}</b> <small class="muted">${isJedi(r)?'Earn an epithet':'Earn a nickname'}${r.nick?` (now ${nickText(r)})`:''}:</small>
   ${nickOpts(r).map(o=>`<button type="button" data-nick="${id}" data-v="${o.n}" title="${o.why}">${isJedi(r)?o.n:`“${o.n}”`} <small>${o.why}</small></button>`).join('')}
   <input type="text" maxlength="${NICK_MAX}" id="nk-${id}" placeholder="Your own" aria-label="Your own nickname" style="max-width:120px"><button type="button" data-nick="${id}" data-own="1">Set</button>
   <button type="button" data-nick="${id}" data-v="">${r.nick?'Keep':'Skip'}</button></div>`}).join('');
 const said=(out.said||[]).map(s=>{const r=unit(s.rid);return r?`<p class="flag">“${s.txt}” <small class="muted">— ${fullName(r)}</small></p>`:''}).join('');
 return h+(rows.trim()?`<section><h3>Names</h3>${rows}</section>`:'')+said};
document.addEventListener('click',ev=>{const b=ev.target.closest&&ev.target.closest('[data-nick]');if(!b||!lastDeb||!lastDeb[2])return;const id=b.dataset.nick,r=unit(id),out=lastDeb[2];
 if(b.dataset.own){const i=document.getElementById('nk-'+id),v=i&&clean(i.value,NICK_MAX);if(!v)return;setNick(id,v)}
 else if(b.dataset.v)setNick(id,b.dataset.v);
 out.nicked=out.nicked||{};out.nicked[id]=r.nick?`Now known as ${nickText(r)}.`:'No nickname.';debrief(...lastDeb)});
// Identity editor: nickname + voice next to name/species/look.
const _identI=identHTML;identHTML=function(r){const vs=Object.entries(VOICES).filter(([,v])=>v.who===(isJedi(r)?'jedi':'troop'));
 return _identI(r).replace('<button type="button" data-act="ident:',`<input id="idk" type="text" maxlength="${NICK_MAX}" value="${r.nick||''}" placeholder="${isJedi(r)?'Epithet':'Nickname'}" aria-label="Nickname" style="max-width:120px">
 <select id="idv" aria-label="Voice">${vs.map(([k,v])=>`<option value="${k}" ${r.voice===k?'selected':''}>Voice: ${v.n}</option>`).join('')}</select><button type="button" data-act="ident:`)};
const _setIdentI=setIdent;setIdent=function(id,f){_setIdentI(id,f);const r=unit(id),k=document.getElementById('idk'),v=document.getElementById('idv');if(!r)return;
 if(k)r.nick=clean(k.value,NICK_MAX)||null;if(v&&VOICES[v.value])r.voice=v.value;saveGame()};

// --- Padawans ---
function autoPair(){if(!C||!C.pairs)return;C.pairNo=C.pairNo||{};
 for(const p of C.roster.filter(r=>isJedi(r)&&r.title==='Padawan'&&r.status==='active'&&!C.pairs[r.id]&&!C.pairNo[r.id])){const m=mentors(p).sort((a,b)=>b.rank-a.rank)[0];if(m)setPair(p.id,m.id)}}
const _setPairI=setPair;setPair=function(p,m){if(C){C.pairNo=C.pairNo||{};if(m)delete C.pairNo[p];else C.pairNo[p]=1}return _setPairI(p,m)};
const _ensureI=ensureTemple;ensureTemple=function(){const r=_ensureI.apply(this,arguments);if(C&&C.roster){ensureVoices();if(C.pairs&&typeof mentors==='function')autoPair()}return r};

// --- battle unit: nickname, voice, Master link ---
const _buI=battleUnit;battleUnit=function(r){const u=_buI(r),R=C&&r&&r.id&&C.roster.find(x=>x.id===r.id);
 if(R){u.nick=nickText(R);const g=R.gear||{};u.kit={armor:g.armor,w:g.w,mods:g.mods||[],look:R.look,cls:R.cls,species:R.species};const m=C.pairs&&C.pairs[R.id];if(m&&R.title==='Padawan'){u.master=m;const M=unit(m);u.masterN=M&&M.n}}return u};
// rules.js asks this for the Padawan aim bonus (shown in the odds panel as "Master near").
function masterNear(a){return a.master&&a.side==='p'&&players().some(p=>p.rid===a.master&&p.status==='ok'&&dist(a,p)<=PAD.r)?PAD.aim:0}
