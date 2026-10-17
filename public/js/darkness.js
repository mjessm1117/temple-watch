/* Darkness reduction (Chat I): four ways back from the dark side for a Jedi's personal Darkness (0–10, r.dark).
   1. Gardens: Jedi assigned to Meditate shed Darkness each month (L1 −1, L2 −2). Staffed Gardens: Order Darkness −1/month.
   2. Mercy in battle: captures, healing allies and sparing the surrendered add mercy; every 2 mercy = −1 Darkness (max −2 a mission).
   3. Redemption: a Jedi at Darkness ≥ 6 gets a personal mission on the galaxy map. Win: big drop. Lose: +1.
   4. Mentoring: a Padawan's Master, or a Counsel mentor for anyone else, pulls Darkness toward their own each month.
   Hooks (wrappers, no edits to owners' logic): templeMonth, optionsFor, templeAfterMission, assignOpts, AB[*].run. Spec: campaign.md §2 (Gardens), §6.4. */
const DARK={
 garden:[0,1,2],        // Darkness shed per month while meditating, by Gardens level (spec B §2) [Locked by Jess]
 gardenStaffOrder:1,    // Order Darkness −1/month while someone staffs the Gardens (spec B §2 staff bonus)
 mercyPer:2,mercyCap:2, // mercy points per −1 Darkness; max Darkness shed by mercy in one mission [Default]
 redeemAt:6,redeemWin:-4,redeemLose:1,redeemStress:-20,   // redemption mission trigger and results [Default]
 mentorMax:2,           // a mentor at Darkness ≤ this pulls their student down 1/month [Default]
 mentorDark:7,          // a mentor at Darkness ≥ this pulls their student UP 1/month (the dark rubs off) [Default]
 counselRank:4};        // Counsel mentors: a Knight or Master of at least this rank [Default]
const MERCY_ABS=['heal','stabilize','forceHeal','forceRevive','reviveStim','massHeal','medBeacon'];

// ── 2. Mercy in battle: wrap the healing abilities and Subdue. Only Jedi carry personal Darkness. ──
function mercy(u,n,why){if(!u||!u.jedi||!S)return;u.mercy=(u.mercy||0)+n;
 while(u.mercy>=DARK.mercyPer&&(u.mercyOff||0)<DARK.mercyCap&&u.dark>0){u.mercy-=DARK.mercyPer;u.mercyOff=(u.mercyOff||0)+1;addDark(u,-1);
  log(`${u.n} chose mercy (${why}). Darkness −1.`,'good');if(typeof fx==='function')fx('ability',{u,k:'mercy'})}}
function wrapMercy(){if(typeof AB==='undefined')return;
 for(const k of MERCY_ABS){const a=AB[k];if(!a||!a.run||a._mercy)continue;const run=a.run;a._mercy=1;
  a.run=function(u,g){const snap=S.units.filter(p=>p.side==='p'&&p!==u).map(p=>[p,p.hp,p.status,p.stable]),r=run.apply(this,arguments);
   if(snap.some(([p,hp,st,stb])=>p.hp>hp||(st==='down'&&p.status!=='down')||(!stb&&p.stable)))mercy(u,1,'tended the wounded');return r}}
 const s=AB.subdue;if(s&&s.run&&!s._mercy){const run=s.run;s._mercy=1;
  s.run=function(u,g){const was=g&&g.t&&g.t.status,r=run.apply(this,arguments);
   if(g&&g.t&&g.t.status==='captured')mercy(u,was==='surrender'?2:1,was==='surrender'?'spared a foe who surrendered':'took a foe alive');return r}}}
wrapMercy();

// ── 3. Redemption: one offer per Jedi at Darkness ≥ redeemAt, shown on the galaxy map with the crises. ──
const REDEEM_TXT={
 1:{n:'The way back',text:'{n} walks close to the dark. A Sith holdout has taken a pilgrim shrine. Go with {n}, and win it without cruelty.'},
 2:{n:'The way back',text:'{n} hears the Brotherhood in every silence. Their wounded are trapped behind the lines. Bring them out alive, with {n} leading.'}};
function redeemMission(step){const P=PLAN[step]||{},era=(C.era||1);
 const pool=(P.crises||[]).map(k=>CRISES[k]).filter(c=>c&&MISSIONS[c.mission]&&['defend','rescue','escort'].includes(MISSIONS[c.mission].type));
 return pool.length?pool[0].mission:era===2&&MISSIONS.r_hospital?'r_hospital':'shrine'}
function redeemOptions(step){C.redeem=C.redeem||{};const o=[];
 for(const r of C.roster){if(!isJedi(r)||r.status!=='active'||(r.dark||0)<DARK.redeemAt)continue;
  const R=C.redeem[r.id];if(R&&R.era===(C.era||1))continue;   // one try per Jedi per era
  const T=REDEEM_TXT[C.era||1]||REDEEM_TXT[1];
  o.push({n:`${T.n} · ${r.n}`,kind:'Redemption',src:'Personal',mission:redeemMission(step),quest:r.id,redeem:r.id,text:T.text.replace(/\{n\}/g,r.n),ignore:{},adv:0,
   questTxt:`${r.n}: Darkness ${DARK.redeemWin}, stress ${DARK.redeemStress}. Lose: Darkness +${DARK.redeemLose}`})}
 return o.slice(0,1)}
const _optionsForD=optionsFor;
optionsFor=function(step){const o=_optionsForD(step);if(C&&PLAN[step]&&PLAN[step].crises)o.push(...redeemOptions(step));return o};
function redeemResult(o,win,out){const r=unit(o.redeem);if(!r)return;C.redeem=C.redeem||{};C.redeem[r.id]={era:C.era||1,won:win?1:0};
 if(win){r.dark=Math.max(0,r.dark+DARK.redeemWin);if(typeof addStress==='function')addStress(r,DARK.redeemStress);
  out.quest=`<b class="up">${r.n} found the way back.</b> Darkness ${DARK.redeemWin} (now ${r.dark}), stress ${DARK.redeemStress}.`;if(typeof lifeLog==='function')lifeLog(r,'Walked back from the dark')}
 else{r.dark=Math.min(10,r.dark+DARK.redeemLose);out.quest=`<span class="bad">${r.n} could not find the way back.</span> Darkness +${DARK.redeemLose} (now ${r.dark}).`}}
const _templeAfterD=templeAfterMission;
templeAfterMission=function(dep,win,o,out){_templeAfterD(dep,win,o,out);if(o&&o.redeem)redeemResult(o,win,out);
 for(const {r,u} of dep)if(u&&u.mercyOff)out.prog.push(`${r.n}: mercy in battle, Darkness −${u.mercyOff}.`)};

// ── 4. Counsel: any non-Padawan Jedi may sit with a mentor (Knight/Master, rank ≥ counselRank). Padawans use their Master (C.pairs). ──
const counselors=r=>C.roster.filter(m=>isJedi(m)&&m.status==='active'&&m.id!==r.id&&(m.title==='Knight'||m.title==='Master')&&m.rank>=DARK.counselRank);
function mentorOf(r){if(!r||!isJedi(r))return null;const id=r.title==='Padawan'?(C.pairs||{})[r.id]:(C.counsel||{})[r.id],m=id&&unit(id);return m&&m.status==='active'?m:null}
function setCounsel(id,m){const r=unit(id);if(!r||!isJedi(r)||r.title==='Padawan')return;C.counsel=C.counsel||{};
 if(!m)delete C.counsel[id];else if(counselors(r).some(x=>x.id===m)){C.counsel[id]=m;C.news.push(`${unit(m).n} agrees to counsel ${r.n}.`)}saveGame()}
// Next month's Darkness change for one Jedi, with reasons (shown in the Roster).
function darkDrift(r){if(!isJedi(r)||r.status!=='active')return{n:0,why:[]};let n=0;const why=[];
 if(r.assign==='calm'&&C.wings.gardens){const g=DARK.garden[Math.min(2,C.wings.gardens)]||0;if(g){n-=g;why.push(`Gardens −${g}`)}}
 const m=mentorOf(r);if(m){if((m.dark||0)<=DARK.mentorMax&&(r.dark||0)>(m.dark||0)){n--;why.push(`${m.n}'s counsel −1`)}
  else if((m.dark||0)>=DARK.mentorDark&&(r.dark||0)<(m.dark||0)){n++;why.push(`${m.n}'s shadow +1`)}}
 return{n,why}}

// ── 1 + 4 at the month turn ──
function darkMonth(){const lines=[];
 for(const r of C.roster){const d=darkDrift(r);if(!d.n)continue;const b=r.dark||0;r.dark=Math.max(0,Math.min(10,b+d.n));if(r.dark!==b)lines.push(`${r.n} ${r.dark-b>0?'+':''}${r.dark-b} (${d.why.join(', ')})`)}
 if(lines.length)C.news.push(`Darkness this month: ${lines.join(' · ')}.`);
 if(C.staff.gardens&&C.orderDark>0){gain('orderDark',-DARK.gardenStaffOrder);C.news.push(`Gardens staff keep the Order calm: Order Darkness −${DARK.gardenStaffOrder}.`)}}
const _templeMonthD=templeMonth;
templeMonth=function(){_templeMonthD();darkMonth()};
// A meditating Jedi stays in the Gardens while any Darkness is left (P's code sends calm units home at zero stress).
const _assignOptsD=assignOpts;
assignOpts=function(r){const o=_assignOptsD(r),i=o.findIndex(x=>x[0]==='calm');
 if(i>=0&&isJedi(r)){const g=DARK.garden[Math.min(2,C.wings.gardens)]||0;o[i]=['calm',o[i][1].replace(/\)$/,`, Darkness −${g}/month)`)]}return o};

// Roster line for a Jedi: drift preview + Counsel picker. Called from rosterProg via darkHTML(r).
function darkHTML(r){if(!isJedi(r)||r.status!=='active')return '';const d=darkDrift(r),cs=r.title==='Padawan'?[]:counselors(r),cur=(C.counsel||{})[r.id];
 const tip=`${d.n?`Next month: Darkness ${d.n>0?'+':''}${d.n} (${d.why.join(', ')}).`:(r.dark?'No Darkness change next month.':'')}`;
 const sel=cs.length&&(r.dark||cur)?`<label class="muted">Counsel: <select data-counsel="${r.id}" aria-label="Counsel mentor for ${r.n}"><option value="">None</option>${cs.map(m=>`<option value="${m.id}" ${cur===m.id?'selected':''}>${m.n} (Darkness ${m.dark||0})</option>`).join('')}</select></label>`:'';
 const help=r.dark?` <small class="muted">Ways back: Meditate in the Gardens · mercy in battle (capture, heal, spare) · a mentor at Darkness ≤${DARK.mentorMax}${r.dark>=DARK.redeemAt?' · redemption mission on the galaxy map':''}.</small>`:'';
 return tip||sel||help?`<div class="dkline">${tip?`<small class="dkt">${tip}</small> `:''}${sel}${help}</div>`:''}
// Counsel select lives in the Roster; the hub's change handler only knows assignments and pairs, so listen here.
document.addEventListener('change',ev=>{const s=ev.target.closest&&ev.target.closest('[data-counsel]');if(!s||!C)return;setCounsel(s.dataset.counsel,s.value);if($('#modal .base'))baseScreen()});
const _rosterProgD=rosterProg;
rosterProg=function(r){return _rosterProgD(r)+darkHTML(r)};
