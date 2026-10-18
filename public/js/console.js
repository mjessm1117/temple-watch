/* Command console look (Chat N, wave 5). LOOK ONLY: reads campaign state, never changes it.
   Wraps baseScreen (outermost, so load after story/galaxy/battle-ui/hazards) and adds: status lights on rooms and readouts,
   an alert bar, a galaxy feed (this session's Temple news, newest first) and a HoloNet ticker. Styles: css/console.css.
   Light meanings: good = nominal · holo = active/in progress · alert = needs attention · sith = hostile · off = offline. */
const CFEED=[];
const cLed=(c,t)=>`<i class="led ${c||''}"${t?` title="${t}"`:''}></i>`;
function cAlerts(){const A=[];try{
 for(const o of C.options){const T=o.twist&&TWISTS[o.twist],M=MISSIONS[o.mission];if(T)A.push(['alert',`<b class="ctag al">Twist</b>${M?M.n:''} · ${T.n}`,T.desc])}
 for(const o of (C.ops&&C.ops.list)||[])if(o.st==='open'){const S=SITH_OPS[o.k];A.push(['sith',`<b class="ctag si">Sith op</b>${S?S.n:'Unknown operation'}`,S&&S.desc||''])}
 const pend=C.roster.filter(r=>r.status==='active'&&pendingRank(r)).length;if(pend)A.push(['alert',`<b class="ctag al">Barracks</b>${pend} unit${pend>1?'s':''} can rank up`,'Open the Barracks to pick new skills.']);
 const w=C.roster.filter(r=>r.status==='active'&&r.wound).length;if(w)A.push(['holo',`<b class="ctag ho">Medical</b>${w} wounded`,'']);
 if(C.build&&WINGS[C.build])A.push(['holo',`<b class="ctag ho">Works</b>${WINGS[C.build].n} under construction`,'']);
 if(C.res.credits<100)A.push(['alert',`<b class="ctag al">Treasury</b>Credits low · ${C.res.credits}`,''])}catch(e){}
 if(!A.length)A.push(['',`<b class="ctag gd">Status</b>All systems nominal`,'']);
 return `<div class="calerts" role="status">${A.slice(0,5).map(([c,h,t])=>`<div class="ca ${c}"${t?` title="${String(t).replace(/"/g,'&quot;')}"`:''}>${cLed(c)}<span>${h}</span></div>`).join('')}</div>`}
function cFeed(){try{const st=`M${C.month} D${C.day}`;for(const n of C.news||[]){const k=st+'|'+n;if(!CFEED.some(f=>f.k===k))CFEED.unshift({k,st,n})}CFEED.length=Math.min(CFEED.length,30)}catch(e){}
 const kind=n=>/sith|imperial|captur|enem/i.test(n)?'si':/dark/i.test(n)?'dk':/ready|level|join|back|recover|escap/i.test(n)?'gd':'ho';
 return `<section class="cfeed" aria-label="Galaxy feed"><h3>Galaxy feed</h3>${CFEED.length?CFEED.slice(0,8).map(f=>`<div><time>${f.st}</time><span class="${kind(f.n)}">${f.n}</span></div>`).join(''):'<div><time>—</time><span class="dim">Quiet on all channels.</span></div>'}</section>`}
function cRoomLed(r){try{
 if(r.wing&&!C.wings[r.wing])return C.build===r.wing?['holo','Under construction']:['off','Not built'];
 if(r.wing&&C.build===r.wing)return ['holo','Upgrading'];
 if(r.id==='war')return C.options.length?['alert','Orders waiting']:['',''];
 if(r.id==='comms'&&C.ops&&C.ops.list.some(o=>o.st==='open'))return ['sith','Sith operation detected'];
 if(r.id==='barracks'&&C.roster.some(x=>x.status==='active'&&pendingRank(x)))return ['alert','Rank-ups waiting'];
 if(r.id==='medical'&&C.roster.some(x=>x.status==='active'&&x.wound))return ['holo','Treating wounded'];
 if(r.id==='archives'&&C.research&&C.research.cur)return ['holo','Research running']}catch(e){}return ['','Nominal']}
function cBar(v,max,c){return `<i class="cmeter" style="--c:var(--${c})"><i style="width:${Math.max(0,Math.min(100,v/max*100))}%"></i></i>`}
function cTicker(){let L=[];try{const E=eraLabel(),s=C.story;
 L=[`<b>HOLONET</b> ${E} · Month ${C.month}, Day ${C.day}`,`<b>SENATE</b> Favor toward the Order: ${C.res.favor}/100`,
  `<b>COUNCIL</b> The Vision burns ${s?SHADOW.word(s.shadow):'unclear'}`,`<b>TEMPLE</b> Roster ${rosterCount()}/${rosterCap()} · ${C.roster.filter(r=>r.status==='active'&&!r.wound&&!r.assign).length} ready to deploy`,
  `<b>FIELD</b> ${C.roster.filter(r=>String(r.assign||'').startsWith('field:')).length} on field operations`,`<b>WAR ROOM</b> ${C.options.length} mission${C.options.length===1?'':'s'} on the board`]}catch(e){}
 const t=L.map(x=>`<span>${x}</span>`).join('');return `<div class="cticker" aria-hidden="true"><div class="ctrack">${t}${t}</div></div>`}
function consoleDress(){const box=document.querySelector('#modal .box.base');if(!box||box.dataset.console)return;box.dataset.console=1;
 const bar=box.querySelector('.resbar');if(bar){bar.insertAdjacentHTML('afterbegin',`<span class="cbrand">${cLed('holo')}Temple command</span>`);
  const meter={'Senate Favor':[C.res.favor,100,'good'],'Order Darkness 0–100':[odark(),100,'dark']};
  bar.querySelectorAll(':scope>span[title]').forEach(s=>{const m=meter[s.title];if(m)s.insertAdjacentHTML('beforeend',cBar(...m))});
  const v=bar.querySelector('.vis:not(#memBtn)');if(v&&C.story)v.insertAdjacentHTML('beforeend',cBar(C.story.shadow,10,'holo'));
  bar.insertAdjacentHTML('afterend',cAlerts())}
 box.querySelectorAll('.tmap .room[data-room]').forEach(b=>{const r=ROOMS.find(x=>x.id===b.dataset.room);if(!r)return;const [c,t]=cRoomLed(r);b.classList.add('st-'+(c||'good'));b.insertAdjacentHTML('beforeend',`<i class="led rl ${c}" title="${t}"></i>`)});
 const tm=box.querySelector('.tmap');if(tm)tm.insertAdjacentHTML('beforeend',cFeed());
 box.insertAdjacentHTML('beforeend',cTicker())}
if(typeof baseScreen==='function'){const _cBase=baseScreen;baseScreen=function(){const r=_cBase.apply(this,arguments);try{consoleDress()}catch(e){}return r}}
