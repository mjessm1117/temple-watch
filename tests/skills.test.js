// Chat Q skills overhaul: 3 options per rank, skill points, extra skills, fx effects, chain kills, bonds panel + techniques in the tree.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
const story=()=>{for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else if(q('[data-role]'))q('[data-role]').click();else return}};
d.querySelector('[data-d="normal"]').click();story();
// Data: every rank has 3 options, all ids resolve, no duplicates inside a class tree, every icon exists
check(E("Object.values(TREES).every(T=>[1,2].every(k=>T.trunk[k].length===3)&&Object.values(T.specs).every(s=>[4,5,6,7].every(k=>s[k].length===3)))"),'3 choices on every trunk and spec rank');
check(E("Object.values(TREES).every(T=>{const ids=[...T.trunk[1],...T.trunk[2],...Object.values(T.specs).flatMap(s=>[s.sig,...[4,5,6,7].flatMap(k=>s[k])])];return ids.every(k=>PERKS[k]||AB[k])})"),'every tree id is a perk or ability');
check(E("Object.entries(TREES).every(([c,T])=>Object.values(T.specs).every(s=>{const ids=[...T.trunk[1],...T.trunk[2],s.sig,...[4,5,6,7].flatMap(k=>s[k])];return new Set(ids).size===ids.length}))"),'no skill appears twice in one path');
check(E("Object.values(PERKS).filter(p=>p.fx||p.aimVs).every(p=>ICONS[p.ic])"),'every new skill icon exists: '+E("Object.values(PERKS).filter(p=>(p.fx||p.aimVs)&&!ICONS[p.ic]).map(p=>p.ic).join()"));
check(E("Object.values(PERKS).filter(p=>p.fx).every(p=>Object.keys(p.fx).every(f=>FX_N[f]))"),'every fx key is named');
check(E("RANKS.length")===10,'veteran ranks 8–10 exist');
// Skill points
E("var A=C.roster.find(r=>r.cls==='Guardian')||C.roster.find(r=>TREES[r.cls]);A.xp=0;A.sp=null;A.extra=[];spSync(A)");check(E('A.sp')===E('SKILL.start'),'units start with a skill point');
E("A.xp=SKILL.xpPer*2+1;promote(A)");check(E('A.sp')===E('SKILL.start')+2,'1 skill point per SKILL.xpPer XP');
E("var k2=TREES[A.cls].trunk[1].find(k=>k!==A.picks[0])");check(E("canBuy(A,k2)"),'a skipped rank-1 option is buyable');
E("var s0=A.sp;buySkill(A.id,k2)");check(E("A.extra.includes(k2)&&A.sp===s0-1&&picksOf(A).includes(k2)"),'buying spends a point and the skill is learned');
check(E("!canBuy(A,TREES[A.cls].trunk[2][0])||A.picks.length>=2"),'cannot buy ahead of your rank picks');
E("A.xp=RANKS[9].xp;var sv=A.sp;promote(A)");check(E('A.rank')===10&&E('A.sp')>=E('sv')+3,'veteran ranks pay skill points');
// Tree screen: buy state, sp banner, bonds panel
E("var B=C.roster.find(r=>r!==A&&r.status==='active');C.bonds={};bondPts(A.id,B.id,200,'t');treeScreen(A.id)");
check(!!d.querySelector('.tt-sp')&&!!d.querySelector('.tt-bonds'),'skill tree shows skill points and a Bonds section');
check(!!d.querySelector('.tt-bonds [data-act^="drill:"]'),'drill picks offered in the tree');
check(!!d.querySelector('.tt-bonds [data-act^="btech:"]'),'bond technique offered at bond 5+');
d.querySelector('.tt-bonds [data-act^="btech:"]').click();check(!!E("C.bonds[bkey(A.id,B.id)].tech"),'technique picked from the tree');
check(E("A.sp")>0&&E("B.sp")>0,'bond 4/8 paid skill points to both');
// fx in battle: perks feed u.fx; chain refunds an action on a kill
E("A.extra=[];A.picks=A.picks.slice(0,2);var pk=Object.keys(PERKS).find(k=>PERKS[k].fx&&PERKS[k].fx.chainMelee);PERKS.__t={name:'t',fx:{chain:2,killHeal:1}};A.extra=['__t']");
E("nodeRank=(o=>(r,k)=>k==='__t'?1:o(r,k))(nodeRank)");
check(E("battleUnit(A).fx.chain")===2,'perk fx reach the battle unit');
E("C.options=optionsFor(C.step);var oi=C.options.findIndex(o=>o.mission);launchMission(oi,[A.id,B.id])");
E("var U=S.units.find(u=>u.rid===A.id);var F=S.units.find(u=>u.side==='e'&&u.status==='ok');F.hp=1;F.armor=0;U.ap=1;S.phase='player';var g={t:F,chance:100};var k0=U.abil.includes('strike')?'strike':'shoot'");
E("AB.__k={name:'t',run:(u,g)=>damage(g.t,99,u)};U.ap=1;exec(U,'__k',{t:F,chance:100})");
check(E("F.status")==='dead'&&E("U.ap")===1&&E("U.chainUsed")===1,'kill with chain: ending action refunded');
// last stand
E("U.fx.lastStand=1;U.lsUsed=0;U.hp=3;U.armor=0;damage(U,9,F)");check(E("U.hp")===1&&E("U.status")==='ok','last stand keeps a unit at 1 HP');
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({fail,err:errs.length}));process.exit(fail||errs.length?1:0);
