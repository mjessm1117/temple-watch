/* Temple logic: gear and crafting, wing assignments, recruiting, bonds, personal quests, promotions.
   UI lives in temple-ui.js. Hooks into campaign.js: battleUnit → templeMods, applyResults → templeAfterMission, advance → templeAdvance. */
const RANK_TITLE=['','Recruit','Private','Corporal','Sergeant','Lieutenant','Captain','Commander','Veteran Commander','Elite Commander','Legend'];
// Older saves: add the fields this file needs.
function ensureTemple(){if(!C)return;const w=C.wings;for(const k of Object.keys(WINGS))if(w[k]==null)w[k]=k==='barracks'?1:0;
 C.bonds=C.bonds||{};C.quests=C.quests||{};C.staff=C.staff||{};if(!C.cands)C.cands=genCands();
 for(const r of C.roster){r.gear=r.gear||{w:0,armor:'none',mods:[],saber:0,trait:null};r.bonus=r.bonus||{};r.picks=r.picks||[];
  if(r.age==null)r.age=ageFor(r);if(!C.treeV&&TREES[r.cls])r.picks=[TREES[r.cls].trunk[1][0],...r.picks];fixTree(r);if(r.trait===undefined)r.trait=null;if(r.fear==null)r.fear=0;r.pick=pendingRank(r)}
 C.treeV=2;ensureProg();ensureLife();if(typeof ensureLegacy==='function')ensureLegacy()}
const ri2=([a,b])=>a+Math.floor(Math.random()*(b-a+1));
const ageFor=r=>ri2(isJedi(r)?AGES[r.title==='Knight'?'Knight':'Padawan']:AGES.troop);
function addMod(u,m){for(const [k,v] of Object.entries(m||{})){
 if(k==='dmg'){u.dmg[0]+=v;u.dmg[1]+=v}else if(k==='dmgHi')u.dmg[1]+=v;else if(k==='kits'||k==='nades'){if(u[k]!=null)u[k]+=v}else u[k]=(u[k]||0)+v}}
// Called from battleUnit(): perks, gear, trait, quest bonuses, fear, bonds. Bond fields are for H to apply in combat.
function templeMods(u,r){if(!r.gear)return u;const g=r.gear;
 for(const k of picksOf(r))if(PERKS[k])addMod(u,PERKS[k].mod);
 if(isJedi(r)){for(let t=1;t<=g.saber;t++)addMod(u,SABERS[t].mod);if(g.trait)addMod(u,SABER_TRAITS[g.trait].mod)}
 else{for(let t=1;t<=g.w;t++)addMod(u,WEAPONS[t].mod);addMod(u,ARMOR[g.armor].mod)}
 if(isJedi(r))addMod(u,ARMOR[g.armor].mod);arsenalMods(u,r);   // modules on weapon / armor / saber, evolution (arsenal.js)
 if(r.trait)addMod(u,TRAITS[r.trait].mod);addMod(u,r.bonus);if(r.fear>0)u.aim-=10;
 u.mob=Math.max(2,u.mob);const bs=bondsOf(r);u.bonds=bs.map(b=>({rid:b.rid,lvl:bondTier(b.lvl)})).filter(b=>b.lvl);   // rules.js reads tiers 1–3
 u.bondAim=u.bonds.length?(bs.some(b=>b.lvl>=BOND.max)?BOND.maxAim:BOND.aim):0;u.bondReact=u.bonds.some(b=>b.lvl>=2)?1:0;if(typeof legacyMods==='function')legacyMods(u,r);progMods(u,r);treeMods(u,r);u.mob=Math.max(2,u.mob);return u}

// --- promotions: one pick per rank (1–7); a unit can owe picks for several ranks. An unpicked rank 1 fights with its first option. ---
// Trees (data-trees.js): trunk ranks 1–2, rank 3 = pick a spec (its signature skill), ranks 4–7 inside the spec. Borrowed skills ride along.
const picksOf=r=>[...(r.picks.length||!TREES[r.cls]?r.picks:[TREES[r.cls].trunk[1][0]]),...(r.borrow||[]),...(r.extra||[])];   // extra = bought with skill points (skills.js)
const specOf=r=>{const T=TREES[r.cls];return T&&r.spec?T.specs[r.spec]:null};
function treeOpts(r,k){const T=TREES[r.cls];if(!T)return[];if(k<=2)return T.trunk[k]||[];if(k===3)return Object.values(T.specs).map(s=>s.sig);const s=specOf(r);return s&&s[k]||[]}
function pendingRank(r){const k=r.picks.length+1;return k<=r.rank&&treeOpts(r,k).length?k:0}
// Old saves / preset units: a bad trunk pick becomes option 1; a bad spec pick drops it and everything after (free respec).
function fixTree(r){const T=TREES[r.cls];if(!T)return;r.picks=r.picks.slice(0,7);r.spec=null;
 for(let i=0;i<r.picks.length;i++){const k=i+1,o=treeOpts(r,k);if(k<=2){if(!o.includes(r.picks[i]))r.picks[i]=o[0];continue}
  if(!o.includes(r.picks[i])){r.picks.length=i;break}if(k===3)r.spec=Object.keys(T.specs).find(n=>T.specs[n].sig===r.picks[i])}
 r.borrow=(r.borrow||[]).filter(k=>xtrainPool(r,1).includes(k)).slice(0,xtrainSlots(r));if(typeof fixExtra==='function')fixExtra(r)}
// A pick button's label: rank 3 shows the spec name with its signature skill.
function pickCard(r,p,k){const a=pickInfo(k);if(p!==3)return{name:a.name,ic:a.ic,desc:a.desc||a.tip||''};
 const s=Object.values(TREES[r.cls].specs).find(s=>s.sig===k);const T=SPEC_TRAITS[Object.keys(TREES[r.cls].specs).find(n=>TREES[r.cls].specs[n]===s)];
 return{name:`${s.n} · ${a.name}`,ic:s.ic,desc:`${s.desc} Comes with ${a.name} (Power II): ${a.desc||a.tip||''}${T?` Trait, ${T.n}: ${T.desc}`:''}`}}
// --- cross-training (multiclass): free, gated by the Training Salle. XTRAIN in data-trees.js.
const xtrainSlots=r=>XTRAIN.minRank.filter((m,i)=>(C.wings.training||0)>i&&r.rank>=m).length;
const xtrainClasses=r=>Object.keys(TREES).filter(c=>c!==r.cls&&(CLASS[c].lockEra||0)<=(C.era||1)&&(isJedi(r)||!CLASS[c].jedi));
function xtrainPool(r,keep){if(!r.alt||!TREES[r.alt])return[];const T=TREES[r.alt].trunk,own=keep?r.picks:[...r.picks,...(r.borrow||[])];
 return[...T[1],...T[2]].filter(k=>!own.includes(k)&&!(isJedi(r)&&!CLASS[r.alt].jedi&&XTRAIN.noGun.includes(k)))}
function setAlt(id,c){const r=unit(id);if(!r||(r.borrow||[]).length||!xtrainClasses(r).includes(c))return;r.alt=c;saveGame()}
function borrowSkill(id,k){const r=unit(id);if(!r)return;r.borrow=r.borrow||[];if(r.borrow.length>=xtrainSlots(r)||!xtrainPool(r).includes(k))return;r.borrow.push(k);saveGame()}
function promote(r){const b=r.rank;while(r.rank<RANKS.length&&r.xp>=RANKS[r.rank].xp)r.rank++;
 if(r.rank>b&&!isJedi(r))r.title=RANK_TITLE[r.rank];r.pick=pendingRank(r);return r.rank>b}
const pickInfo=k=>PERKS[k]||AB[k]||{name:k,tip:''};
// What a pick changed, as text ("HP 7→8 · Aim 70→80 · new: Rapid Fire").
function statDiff(a,b){const L=[['hp','HP'],['aim','Aim'],['mob','Move'],['range','Range'],['crit','Crit'],['armor','Armor'],['kits','Medkits'],['nades','Grenades'],['maxF','Focus'],['deflect','Deflect'],['guardDef','Guard']],o=[];
 for(const [k,n] of L)if((a[k]||0)!==(b[k]||0))o.push(`${n} ${a[k]||0}→${b[k]||0}`);
 if(a.dmg.join()!==b.dmg.join())o.push(`Damage ${a.dmg.join('–')}→${b.dmg.join('–')}`);
 for(const k of b.abil.filter(k=>!a.abil.includes(k)))o.push('new: '+(AB[k]?AB[k].name:k));return o.join(' · ')}

// --- costs ---
const priceOf=c=>Math.round(c*(C.staff.armory?.8:1)*(researched('supply')?.85:1));
const kyberOf=k=>Math.max(1,k-(C.staff.forge?1:0)-(researched('kyberLore')?1:0));
const hasWing=n=>!n||C.wings[n[0]]>=n[1];
const unit=id=>C.roster.find(r=>r.id===id);
function pay(cr,ky=0){if(C.res.credits<cr||C.res.kyber<ky)return false;C.res.credits-=cr;C.res.kyber-=ky;return true}
function buyWeapon(id){const r=unit(id),t=WEAPONS[r.gear.w+1];if(!t||!hasWing(t.need)||!pay(priceOf(t.cost)))return;r.gear.w++;saveGame()}
function buyArmor(id,k){const r=unit(id),a=ARMOR[k];if(!a||r.gear.armor===k||!okGear(a)||(a.who!=='any'&&a.who!==(isJedi(r)?'jedi':'troop'))||!pay(priceOf(a.cost)))return;r.gear.armor=k;saveGame()}
function buyMod(id,k){const r=unit(id),m=MODS[k];if(!m||!researched(m.res)||r.gear.mods.includes(k)||r.gear.mods.length>=WEAPONS[r.gear.w].slots||!pay(priceOf(m.cost)))return;r.gear.mods.push(k);saveGame()}
function dropMod(id,k){const r=unit(id);r.gear.mods=r.gear.mods.filter(m=>m!==k);saveGame()}
function craftSaber(id){const r=unit(id),t=SABERS[r.gear.saber+1];if(!t||!hasWing(t.need)||!pay(t.cost,kyberOf(t.kyber)))return;r.gear.saber++;saveGame()}
function setTrait(id,k){const r=unit(id);if(SABERS[r.gear.saber].trait&&SABER_TRAITS[k]){r.gear.trait=k;saveGame()}}
function setColor(id,c){const r=unit(id);if(r&&/^#[0-9a-f]{6}$/i.test(c)){r.col=c;saveGame()}}

// --- assignments (spec B §2): train, recover, or staff one slot per wing. Assigned units can't deploy. ---
function assignOpts(r){const o=[['','On call']];
 if(C.wings.training)o.push(['train','Train in the Training Salle (+'+TRAIN_XP+' XP per mission)']);
 if((r.wound||r.stress||r.scars.length)&&C.wings.medical)o.push(['rest','Recover in the Medical Halls (heals 2× faster, −'+STRESS.rest+' more stress)']);
 if(C.wings.gardens)o.push(['calm',`Meditate in the Gardens (−${STRESS.calm} more stress${C.wings.gardens>=2?', may heal a trauma':''})`]);
 for(const [k,w] of Object.entries(WINGS))if(C.wings[k]&&(!C.staff[k]||C.staff[k]===r.id))o.push(['staff:'+k,`Staff ${w.n} (${w.staff})`]);return o}
function assign(id,v){const r=unit(id);if(!r||r.status!=='active')return;
 for(const k in C.staff)if(C.staff[k]===id)delete C.staff[k];r.assign=null;
 if(v.startsWith('staff:')){const k=v.slice(6);if(C.wings[k]&&!C.staff[k]){C.staff[k]=id;r.assign=v}}
 else if(v==='train'&&C.wings.training)r.assign='train';else if(v==='rest'&&C.wings.medical)r.assign='rest';else if(v==='calm'&&C.wings.gardens)r.assign='calm';saveGame()}
const assignName=r=>!r.assign?'':r.assign==='train'?'Training':r.assign==='rest'?'Recovering':r.assign==='calm'?'Meditating':r.assign.startsWith('op:')?'On a Sith op':r.assign.startsWith('field:')?'On a field op':'Staffing '+WINGS[r.assign.slice(6)].n;

// --- recruiting (spec B §5.5): 3 candidates a month; a Padawan in odd months. Barracks caps the roster. ---
const rosterCap=()=>WINGS.barracks.cap[C.wings.barracks]||10;
const rosterCount=()=>C.roster.filter(r=>r.status==='active'||r.status==='captured').length;
function genCands(){const out=[],keys=Object.keys(TRAITS);
 for(let i=0;i<3;i++){const jedi=i===0&&(C.month%2===1),cls=jedi?pickOne(Object.keys(CLASS).filter(k=>CLASS[k].jedi&&(CLASS[k].lockEra||0)<=(C.era||1))):pickOne(troopClasses());
  out.push({cls,jedi:jedi?1:0,trait:pickOne(keys),origin:pickOne(ORIGINS[jedi?'jedi':'troop']),species:pickOne(SPECIES),age:ri2(jedi?AGES.Padawan:AGES.troop)})}
 return out}
const candCost=c=>c.jedi?{credits:0,recruits:0}:{credits:HIRE_COST,recruits:1};
function freeName(jedi){const used=new Set(C.roster.map(r=>r.n));return(jedi?JEDI_NAMES:RECRUIT_NAMES).find(x=>!used.has(x))||'Recruit '+C.nid}
function hireCand(i,name,col){const c=C.cands[i],k=c&&candCost(c);if(!c||rosterCount()>=rosterCap()||C.res.recruits<k.recruits||C.res.credits<k.credits)return;
 C.res.credits-=k.credits;C.res.recruits-=k.recruits;C.cands.splice(i,1);addRecruit(c,name,col);saveGame()}
function addRecruit(c,name,col){const n=(name||'').replace(/[<>&"]/g,'').trim().slice(0,24)||freeName(c.jedi);
 C.roster.push({id:'u'+C.nid++,n,cls:c.cls,title:c.jedi?'Padawan':RANK_TITLE[1],col:/^#[0-9a-f]{6}$/i.test(col||'')?col:(c.jedi?CRYSTALS.blue:TROOP_COLS[0]),
  rank:1,xp:0,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0,trait:c.trait,origin:c.origin,species:c.species,age:c.age,look:c.look||null,bio:c.bio||'',
  gear:{w:0,armor:'none',mods:[],saber:0,trait:null},bonus:{},fear:0})}

// --- bonds (spec C §7) ---
const bkey=(a,b)=>a<b?a+'|'+b:b+'|'+a;
function bondsOf(r){const o=[];for(const [k,v] of Object.entries(C.bonds||{})){const [a,b]=k.split('|');if(a!==r.id&&b!==r.id)continue;
 const p=unit(a===r.id?b:a);if(p&&p.status!=='dead')o.push({rid:p.id,n:p.n,lvl:v.lvl,n3:v.n})}return o.sort((x,y)=>y.lvl-x.lvl)}
const bondTier=l=>l>=BOND.griefAt?3:l>=BOND.reactAt?2:l>=BOND.aimAt?1:0;
// One level up (Trials, pairing). Points: bondPts in legacy.js. keep = keep leftover points.
function bondUp(a,b,why,out,keep){if(!a||!b||a===b)return;const k=bkey(a,b),v=C.bonds[k]=C.bonds[k]||{lvl:0,n:0};if(v.lvl>=BOND.max)return;v.lvl++;if(!keep)v.n=0;if(typeof bondOffer==='function')bondOffer(v,a,b);
 if(out)out.bonds.push(`${unit(a).n} & ${unit(b).n}: bond level ${v.lvl} (${why})`)}

// --- personal quests: one per unit, offered at rank 2+, shown with the month's crises ---
function questFor(r){const pool=Object.entries(QUESTS).filter(([,q])=>q.who==='any'||(q.who==='dark'?isJedi(r)&&r.dark>=5:q.who==='jedi'?isJedi(r):!isJedi(r))
 &&(!q.needLegend||C.legends.some(l=>CLASS[l.cls]&&CLASS[l.cls].jedi)));return pool.length?pickOne(pool)[0]:null}
function questOptions(){const o=[];
 for(const r of C.roster){if(r.status!=='active'||r.rank<2)continue;if(!C.quests[r.id]){const q=questFor(r);if(q)C.quests[r.id]={q,st:'offer'}}
  const Q=C.quests[r.id];if(!Q||Q.st!=='offer'||o.length>=2)continue;const q=QUESTS[Q.q];
  o.push({n:`${q.n} · ${r.n}`,kind:'Personal quest',src:'Personal quest',mission:q.mission,quest:r.id,text:q.text.replace(/\{n\}/g,r.n),ignore:{},adv:0,questTxt:q.txt.replace(/\{n\}/g,r.n)})}
 return o}
function questReward(o,out){const r=unit(o.quest),Q=C.quests[o.quest];if(!r||!Q)return;const q=QUESTS[Q.q];Q.st='done';
 for(const [k,v] of Object.entries(q.res||{}))gain(k,v,out.res);if(q.mod)for(const [k,v] of Object.entries(q.mod))r.bonus[k]=(r.bonus[k]||0)+v;
 if(q.dark)r.dark=Math.max(0,r.dark+q.dark);if(q.recruit)addRecruit(genCands().find(c=>!c.jedi)||genCands()[1])
 out.quest=`${q.n} complete: ${o.questTxt}.`}

// After every mission (called from applyResults). `dep` = deployed roster entries with their battle units.
function templeAfterMission(dep,win,o,out){out.bonds=[];
 for(const {r,u} of dep){if(r.fear>0&&!u.vip)r.fear--;if(u.savedBy&&u.savedBy!==r.id)bondPts(r.id,u.savedBy,BOND.saved,'saved in battle',out)}
 const live=dep.filter(d=>!d.u.vip&&d.r.status==='active');
 for(let i=0;i<live.length;i++)for(let j=i+1;j<live.length;j++)bondPts(live[i].r.id,live[j].r.id,BOND.together+(win?BOND.win:0),'fought together',out);
 for(const {r} of dep.filter(d=>d.r.status==='dead'))for(const b of bondsOf(r).filter(b=>b.lvl>=BOND.griefAt)){const p=unit(b.rid);p.fear=BOND.fear;
  out.bonds.push(`${p.n} lost ${r.n}. Fear: −10 aim for ${BOND.fear} missions.`);if(isJedi(p))p.grief=r.n}
 if(win&&o.quest&&!o.redeem)questReward(o,out);progAfterMission(dep,win,out);lifeAfterMission(dep,win,o,out)}
// Jedi choice after a bonded partner dies (spec C §7): grieve (keep the fear) or use the anger (Darkness +2, no fear).
function griefChoice(id,dark){const r=unit(id);if(!r||!r.grief)return;if(dark){r.dark=Math.min(10,r.dark+2);r.fear=0}r.grief=null;saveGame()}

// Time passes (called from advance): training XP, recovery, staff bonuses.
function templeAdvance(){progAdvance();for(const r of C.roster.filter(r=>r.assign)){
 if(r.assign==='train'){r.xp+=TRAIN_XP*(C.wings.training>=2?2:1);if(promote(r))C.news.push(`${r.n} reached Rank ${r.rank} in training. Choose a new skill in the Roster.`)}
 if(r.assign==='rest'){r.wound=Math.max(0,r.wound-DAYS);if(!r.wound&&!r.stress&&!(C.wings.medical>=3&&r.scars.some(k=>SCARS[k].kind==='wound'))){r.assign=null;C.news.push(`${r.n} is fit again and back on call.`)}}}}
function templeMonth(){if(C.staff.comms){C.res.intel++;C.news.push('Comms staff: +1 Intel.')}
 if(C.staff.barracks){C.res.recruits++;C.news.push('Barracks staff: +1 Recruit.')}C.cands=genCands();progMonth()}
