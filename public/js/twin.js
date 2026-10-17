/* Two fronts (round 2, spec docs/specs/second-squad.md): on the last TWIN.perEra crisis steps of an era, once unlocked, you may take
   a second crisis with a second squad. Front A plays as usual; time does NOT pass. Front B (4 units, 0–2 Jedi, squad A excluded) is
   played, auto-resolved, or stood down; then time passes once and every crisis nobody took is ignored.
   State: C.twin={stage:'a'|'b'|'b2',used:[ids],a:'name'}. Hooks (wrappers): launchMission, chooseOption, advance, squadRule, debrief. */
function twinSteps(){const L=[];PLAN.forEach((p,i)=>{if(p.crises&&p.crises.length>=2)L.push(i)});return L.slice(-TWIN.perEra)}
const twinUnlocked=()=>C.wings.barracks>=TWIN.unlock.barracks||(C.era||1)>=TWIN.unlock.era;
const twinB=()=>!!(C&&C.twin&&C.twin.stage==='b');
const twinFree=()=>C.roster.filter(r=>fit(r)&&!((C.twin&&C.twin.used)||[]).includes(r.id));
// This step can be fought on two fronts (checked before front A launches).
function twinOpen(){return!!C&&!C.twin&&twinUnlocked()&&twinSteps().includes(C.step)&&C.options.filter(o=>o.adv&&o.crisis).length>=2&&C.roster.filter(fit).length>=TWIN.minFit}

const _squadRuleT=squadRule;
squadRule=function(){if(twinB())return{max:TWIN.bMax,jmin:0,jmax:TWIN.bJedi,used:C.twin.used,note:`Front B: up to ${TWIN.bMax} units, 0–${TWIN.bJedi} Jedi. Front A's squad can't go.`};return _squadRuleT()};
const _launchT=launchMission;
launchMission=function(i,ids){const o=C.options[i];
 if(o&&o.adv&&o.crisis&&twinOpen())C.twin={stage:'a',used:[...ids],a:o.n||MISSIONS[o.mission].n};else if(twinB())C.twin.stage='b2';
 _launchT(i,ids)};
const _chooseT=chooseOption;
chooseOption=function(i){if(C.twin&&C.twin.stage==='a'){C.chosen=i;return}_chooseT(i)};   // front A: the other crises stay open
const _advanceT=advance;
advance=function(o){if(C.twin&&C.twin.stage==='a'&&o&&o.adv){const rest=C.options.filter(x=>x.adv&&x!==o);
  if(rest.length&&twinFree().length>=TWIN.minB){C.twin.stage='b';C.options=rest.map(x=>({...x,fewer:TWIN.fewer}));C.chosen=null;
   C.news=[`<b>Front B is open.</b> ${C.twin.a} is done; ${rest.length>1?rest.length+' crises still need':'one crisis still needs'} the Order. Send up to ${TWIN.bMax} units, auto-resolve, or stand down. Time passes once both fronts are done.`];saveGame();return}
  C.twin=null;_advanceT(o);for(const x of rest)ignoreCrisis(x);saveGame();return}
 if(o&&o.adv)C.twin=null;_advanceT(o)};
// Front B without a battle: stand down (ignore the rest) or auto-resolve one crisis with the 4 best free units.
function standDown(){if(!twinB())return;const L=[...C.options];C.twin=null;C.chosen=null;_advanceT({adv:1});for(const x of L)ignoreCrisis(x);saveGame()}
const autoOdds=ids=>Math.min(TWIN.autoMax,TWIN.autoBase+TWIN.autoPerRank*ids.map(unit).filter(Boolean).reduce((s,r)=>s+r.rank,0));
function autoFront(i){if(!twinB())return;const o=C.options[i];if(!o||o.hostages)return;const ids=defaultSquad(o),T=ids.map(unit),ch=autoOdds(ids),win=Math.random()*100<ch,M=MISSIONS[o.mission];
 const others=C.options.filter(x=>x!==o),lines=[];C.twin=null;C.chosen=null;_advanceT({adv:1});
 if(win){const res={};for(const [k,v] of Object.entries(M.reward||{}))res[k]=Math.round(k==='credits'?v*DIFF[C.diff].income*MISSION_CR:v);for(const [k,v] of Object.entries(res))gain(k,v);
  lines.push(`<b class="up">Front B won: ${o.n||M.n}</b> (auto-resolved, ${ch}%). ${fmtRes(res)||'No reward'}; +${TWIN.autoXp} XP each`);
  for(const r of T){r.xp+=TWIN.autoXp;r.missions++;if(promote(r))lines.push(`${r.n} reached Rank ${r.rank}`)}}
 else{gain('favor',TWIN.loseFavor);for(const r of T)if(typeof addStress==='function')addStress(r,TWIN.loseStress);const h=T.length?pickOne(T):null;
  if(h)h.wound=Math.max(h.wound||0,Math.ceil(TWIN.loseWound/healMult()));
  lines.push(`<span class="bad">Front B lost: ${o.n||M.n}</span> (auto-resolved, ${ch}%). Senate Favor ${TWIN.loseFavor}, stress +${TWIN.loseStress} each${h?`; ${h.n} wounded (${h.wound} days)`:''}`)}
 if(typeof addUnrest==='function')addUnrest(regionOf(M.where),win?UNREST.win:UNREST.lose,'front B');
 for(const x of others)ignoreCrisis(x);C.news.push(lines.join(' · ')+'.');saveGame()}
// Galaxy banner + panel buttons (galaxy.js calls these).
function twinBanner(){if(twinB())return `<div class="twin b"><b>Front B</b> · ${C.twin.a} is done. Pick a second crisis for up to ${TWIN.bMax} units, auto-resolve one, or <button type="button" data-act="standdown">Stand down</button> (the rest are ignored). Time passes after this.</div>`;
 if(C&&!C.twin&&twinSteps().includes(C.step)&&C.options.filter(o=>o.adv&&o.crisis).length>=2){
  if(twinOpen())return `<div class="twin"><b>Two fronts</b> · This month you can take two crises. Front A: up to 6 units. Front B: up to ${TWIN.bMax} more, or auto-resolve it. Time passes once.</div>`;
  if(!twinUnlocked())return `<div class="twin off">Two fronts locked: upgrade the Barracks to level ${TWIN.unlock.barracks} to send a second squad on steps like this.</div>`;
  return `<div class="twin off">Two fronts needs ${TWIN.minFit} units ready (you have ${C.roster.filter(fit).length}).</div>`}return ''}
function twinButtons(i,o){if(!twinB()||o.hostages)return '';const ids=defaultSquad(o);if(!ids.length)return '';
 return `<button type="button" data-act="tauto:${i}" title="${ids.map(id=>unit(id).n).join(', ')}">Auto-resolve · ${autoOdds(ids)}% <small class="muted">(${ids.map(id=>unit(id).n.split(' ').pop()).join(', ')})</small></button>`}
function twinClick(ev){const b=ev.target.closest('[data-act^="tauto:"],[data-act="standdown"]');if(!b||b.disabled)return false;
 if(b.dataset.act==='standdown')standDown();else autoFront(+b.dataset.act.split(':')[1]);baseScreen();return true}
const _debriefT=debrief;
debrief=function(win,msg,out){_debriefT(win,msg,out);if(twinB()){const t=$('#toBase');if(t)t.textContent='Return to the Temple · Front B next'}};
