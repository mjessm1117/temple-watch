// Chat Q systems: bonds 1–8 + drills, lore secrets, retirement to Council/General, Council masters in battle. Fast jsdom checks.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
const story=()=>{for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else if(q('[data-role]'))q('[data-role]').click();else return}};
(async()=>{
d.querySelector('[data-d="normal"]').click();story();
E("var A=C.roster[0],B=C.roster[1],X=C.roster[2]");
// Lore
check(E("C.roster.every(r=>r.lore&&SECRETS[r.lore.sec]&&bgText(r).includes(r.n))"),'every unit has a backstory and a secret');
// Bonds: points → levels → drill offers
E("C.bonds={};bondPts(A.id,B.id,BOND.need[0],'test')");var k=E("bkey(A.id,B.id)");
check(E(`C.bonds['${k}'].lvl`)===1&&E(`C.bonds['${k}'].offer.length`)===3,'enough points → bond 1 with 3 drill choices');
E(`C.bonds['${k}'].offer=['range'];pickDrill('${k}','range')`);
check(E(`C.bonds['${k}'].dr.includes('range')`),'drill stored on the bond');
E(`C.bonds['${k}'].dr=[];var a0=battleUnit(A).aim;C.bonds['${k}'].dr=['range']`);check(E('battleUnit(A).aim-a0')===3&&E('battleUnit(B).aim')>0,'range drill: +3 aim for the partner too');
E(`bondPts(A.id,B.id,1000,'test')`);check(E(`C.bonds['${k}'].lvl`)===8,'bond caps at 8');
check(E('battleUnit(A).bondAim')===10&&E('battleUnit(A).bonds[0].lvl')===3,'Unbreakable: +10 bond aim, combat tier 3');
// Old save migration: levels 1–3 → 2/4/6
E("C.bondV=1;C.bonds={};C.bonds[bkey(A.id,X.id)]={lvl:3,n:2};ensureLegacy()");check(E("C.bonds[bkey(A.id,X.id)].lvl")===6,'old bond 3 → new bond 6');
// Lore hints and reveal → personal mission
E("C.quests={};A.lore.t=[];A.lore.rev=0;A.missions=3;A.rank=3;loreTick(A,'m3');loreTick(A,'r3');loreTick(A,'m3')");check(E('A.lore.t.length')===2,'hints unlock once per trigger');
E("loreTick(A,'down')");check(E('A.lore.rev')===1&&E('C.quests[A.id]&&C.quests[A.id].sec')===E('A.lore.sec'),'3 hints reveal the secret and queue its mission');
E("var st=PLAN.findIndex(p=>p.crises);A.rank=Math.max(A.rank,2);var qo=optionsFor(st).find(o=>o.quest===A.id)");check(E('!!qo&&qo.kind')==='Secret','secret mission shows on the board');
// Retirement: General guards a region
E("var G=C.roster.find(r=>!isJedi(r));G.rank=4;G.status='active';G.assign=null;retireUnit(G.id,'general','outer')");
check(E("G.status")==='retired'&&E("C.gen[G.id]")==='outer','troop retires as General of the Outer Rim');
E("addUnrest('outer',5,'test')");check(E("unrestOf('outer')")===LEGACY_CAP(),'Unrest capped in a General\'s region');
function LEGACY_CAP(){return E('LEGACY.genCap')}
E("ensureField();var fo=C.field.list[0]||{k:Object.keys(FIELD_OPS)[0]};var pl=Object.keys(PLANETS).find(p=>PLANETS[p].reg==='outer');var fr=C.roster.filter(fit).slice(0,2).map(r=>r.id)");
check(E("fieldOdds(fo.k,fr,pl).why.some(w=>/General/.test(w[0]))"),'field op in the General\'s region gets the bonus');
// Retirement: Jedi to the Council
E("var J=C.roster.find(r=>isJedi(r)&&r.status==='active');J.rank=4;J.assign=null;var n0=members().length;retireUnit(J.id,'council')");
check(E("members().length")===E('n0')+1&&E("members().some(m=>m.id===J.id)"),'Jedi retires into a Council seat');
// Years pass offers Council / General to retirees
E("var Y=C.roster.find(r=>isJedi(r)&&r.status==='active');Y.rank=3;Y.status='retired';C.story.yrs={rows:[],ret:[{id:Y.id,role:null}]};C.step=Math.max(C.step,1);yearsScreen()");
check(!!d.querySelector(`[data-role="${E('Y.id')}:council"]`)&&!!d.querySelector(`[data-role="${E('Y.id')}:general:core"]`),'Years pass: Council seat and General buttons');
d.querySelector(`[data-role="${E('Y.id')}:general:core"]`).click();check(E("C.gen[Y.id]")==='core','Years pass: retiree becomes General of the Core');
E("C.story.yrs=null;baseScreen()");
// Council support in battle
E("C.options=optionsFor(C.step);var oi=C.options.findIndex(o=>o.mission);var o=C.options[oi];var P=legPool(o)");
check(E("P.some(p=>p.kind==='npc')&&P.some(p=>p.id===J.id)"),'Council masters and your retired Master are offered');
E("squadScreen(oi)");check(!!d.querySelector('[data-cm]'),'squad screen shows Council support');
E("var npc=P.find(p=>p.kind==='npc');LEG_PICK=[npc.id];var l0=loyOf(npc.id);launchMission(oi,defaultSquad(o))");
check(E("S.units.some(u=>u.cm===npc.id&&u.side==='p'&&u.x!=null)"),'master joins the battle on a free tile');
check(E("legKind(o)==='any'?loyOf(npc.id)===l0-LEGACY.loyCost:true"),'non-story mission costs the master loyalty');
w.eval(bot);for(let t=0;t<3&&!E('S.over');t++){E('AI()');await E('endTurn()')}
check(!errs.length,'3 battle turns with a master: no errors');
E("var hu=S.units.find(u=>u.side==='p'&&u.rid&&!u.cm);hu.savedBy='cm_'+npc.id");
E("S.units.find(u=>u.cm===npc.id).status='dead';var out=applyResults(false)");
check(E("!members().some(m=>m.id===npc.id)"),'fallen master: seat is empty');
check(E("legPool(C.options[0]||o).every(p=>p.id!==npc.id)"),'fallen master is not offered again');
// Roster UI renders
E("TAB='roster';C.roster.filter(r=>r.status==='active').forEach(r=>recordHTML(r));baseScreen()");
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({fail,err:errs.length}));process.exit(fail||errs.length?1:0)})();
