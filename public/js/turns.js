/* Mission setup, turn flow, threat clock, evac, win/lose checks. */
function mk(base,side,extra={}){const u={...base,...extra,side,status:'ok',ap:2,guard:false,ow:false,dark:base.dark||0,miss:0,uid:++S.uidN};
 if(u.abil){u.abil=[...u.abil];for(const k of u.abil)if(AB[k]&&AB[k].passive){u[k]=1;for(const [s,n] of Object.entries(AB[k].mod||{}))u[s]=(u[s]||0)+n}}
 if(u.pathfinder)u.mob++;
 u.max=u.hp;u.focus=u.maxF?(u.wildBond?u.maxF:2):0;u.dmg=[...u.dmg];if(side==='p'&&!u.vip)u.will=willOf(u);return u}
function mkFoe(t,x,y){const f=FOES[t],d=S.d;S.eCount[t]=(S.eCount[t]||0)+1;
 const cm=S.cm||{};return mk({...f,hp:Math.max(1,f.hp+(f.horror?0:d.enemyHp+(cm.enemyHp||0))),aim:f.aim+d.enemyAim+(cm.enemyAim||0)},'e',{type:t,n:f.envoy?f.n:`${f.n} ${S.eCount[t]}`,x,y})}
function spawn(list){list=[...list];for(let i=0;i<S.d.extra;i++)list.push('trooper');
 const spots=tilesWhere((c,x,y)=>y<2&&PASS(c)&&c!=='E'&&!unitAt(x,y)).sort(()=>Math.random()-.5);
 list.forEach((t,i)=>{const p=spots[i];if(p){const e=mkFoe(t,p.x,p.y);S.units.push(e);horrorSeen(e)}});
 log(`Contact: ${list.length} hostiles at the north edge.`,'bad')}

// squad: battle-ready unit stats (campaign.js battleUnit). o: {diff, hostage, crisis, map (variant index; random if unset)}
// A mission's layout is the base map or one of its `alts`; S.mapIx records which (the grid itself is saved in S.grid).
function startMission(id,squad,o={}){const B=MISSIONS[id],n=1+(B.alts||[]).length,mi=o.map!=null?o.map%n:ri(0,n-1),M=mi?{...B,...B.alts[mi-1]}:B;
 S={id,mapIx:mi,M,type:M.type,grid:M.map.map(r=>r.split('')),units:[],uidN:0,turn:1,phase:'player',sel:null,mode:'move',tg:[],pick:null,info:S?S.info:false,
    diff:o.diff||'normal',d:DIFF[o.diff||'normal'],cm:(typeof campaignMods==='function'&&campaignMods())||{},conc:!!M.stealth,alert:{},pat:{},theme:M.theme||THEME_OF[id]||'plains',obj:M.obj||0,threat:0,clues:0,smoke:[],bmed:null,log:[],fx:[],intel:0,kills:0,orderDark:0,eCount:{},over:false,peek:null,crisis:o.crisis||null};
 const cm=S.cm;squad.slice(0,6).forEach((r,i)=>{const p=M.start[i],u=mk(r,'p',{x:p[0],y:p[1]});
  // Campaign → battle (Chat P's campaignMods): squad-wide aim/HP/will from research and Sith ops.
  if(cm.squadAim)u.aim+=cm.squadAim;if(cm.squadHp){u.hp+=cm.squadHp;u.max+=cm.squadHp}if(cm.squadWill)u.will+=cm.squadWill;S.units.push(u)});
 // Mission field actions (e.g. Plant charge) go to the whole squad.
 if(M.field)for(const u of players())for(const k of M.field)if(!u.abil.includes(k))u.abil.push(k);
 if(S.d.bonusKit){const m=S.units.find(u=>u.kits!=null);if(m)m.kits++}
 if(M.hostage){const esc=S.type==='escort',h=esc?ESCORTS[M.vip]:o.hostage||VIP;S.units.push(mk({...h,vip:1,bound:esc?0:1},'p',{x:M.hostage[0],y:M.hostage[1]}))}
 if(S.type==='escort')hostage().ap=1;
 // Safety net (never lose): a squad under 4 faces one fewer trooper per missing unit, so a depleted roster can't death-spiral.
 let cut=Math.max(0,4-squad.length);const foes=(M.foes||[]).filter(f=>!(f[0]==='trooper'&&cut>0&&cut--));
 for(const [t,x,y,pod] of foes){const e=mkFoe(t,x,y);if(M.stealth)e.pod=pod??('g'+e.uid);S.units.push(e)}
 for(let i=0;i<(cm.extraEnemies||0);i++){const p=pickOne(tilesWhere((c,x,y)=>y<3&&PASS(c)&&c!=='E'&&!unitAt(x,y)));if(p){const e=mkFoe('trooper',p.x,p.y);if(M.stealth)e.pod='x';S.units.push(e)}}
 if(M.waves)spawn(M.waves[1]);
 if(S.conc)log('The squad is concealed. Red tiles are enemy sight: step into one and you are spotted. Attack first for an Ambush (+20 aim, overwatch fires at full aim).','good');
 for(const e of enemies())horrorSeen(e);
 log(M.goal);S.sel=players().find(canAct)||null;$('#modal').hidden=true;SCR=null;render();saveGame()}

function select(u){S.sel=u;S.peek=null;S.mode='move';S.tg=[];S.pick=null;render()}
function canAct(u){return !!u&&u.side==='p'&&u.status==='ok'&&!u.bound&&u.ap>0&&S.phase==='player'&&!S.over}
function targetsFor(u,k){const ab=AB[k];return(ab.tg?ab.tg(u):[]).map(g=>({...g,x:g.x??g.t.x,y:g.y??g.t.y}))}
// Attacking from concealment springs an ambush. ap:1 costs one action, ap:0 is free, anything else ends the turn.
const hostile=(k,g)=>!!AB[k].loud||!!g&&(!!(g.t&&g.t.side==='e')||!!g.barrel||!!g.beacon||(!!g.area&&!g.ally));
function exec(u,k,g){const ab=AB[k],amb=(S.conc||u.conc)&&hostile(k,g);if(ab.f)u.focus-=ab.f;S.amb=amb?1:0;ab.run(u,g);S.amb=0;
 if(ab.ap===1)u.ap=Math.max(0,u.ap-1);else if(ab.ap!==0)u.ap=0;
 if(amb){if(S.conc)breakConceal(`${u.n} opens fire. Ambush!`,g&&g.t,true);else u.conc=0}after()}
function after(){S.mode='move';S.tg=[];S.pick=null;checkEnd();if(!canAct(S.sel)){const n=players().find(canAct);if(n)S.sel=n}render()}

function startPlayerTurn(){const M=S.M;
 S.phase='player';
 if(M.waves&&S.turn>1&&M.waves[S.turn])spawn(M.waves[S.turn]);
 if(M.par&&S.turn>M.par){S.threat++;threatStep();if(S.over)return}
 if(S.beacon&&S.turn>=S.beacon.turn){S.beacon=null;log('The beacon\'s call is answered.','bad');spawn(M.reinforce||['trooper','trooper'])}
 S.smoke=S.smoke.filter(s=>--s.t>0);S.bmed=null;
 for(const u of S.units){u.supp=0;u.marked=0;u.skip=0;if(u.side==='p'){u.supT=null;u.hunker=0;u.barrier=0;u.leapAim=0;u.buffAim=0;u.buffDef=0;u.owHit=null}}
 for(const u of players()){u.guard=false;u.guardStruck=false;u.ow=false;
  if(u.status==='down'){u.ap=0;if(u.stable)continue;u.bleed--;if(u.bleed<=0){u.status='dead';log(`${u.n} has become one with the Force.`,'bad');if(!u.vip)allyFell(u,30,`${u.n}'s death`)}else log(`${u.n} is bleeding out: ${u.bleed} turn${u.bleed>1?'s':''} left.`,'bad')}
  else u.ap=u.vip&&S.type==='escort'?1:2}
 for(const u of players())if(u.panic&&u.status==='ok')doPanic(u);
 S.sel=players().find(canAct)||null;S.mode='move';S.tg=[];S.pick=null;checkEnd();saveGame();render()}
// Soft pressure: past the par turn, each turn raises Threat by 1 and the mission gets worse.
const THREAT_LOSE={rescue:'The Sith fly the prisoner out.',investigate:'The district locks down.',sabotage:'The garrison locks the depot down.',escort:'Hunters seal every route out.'};
function threatStep(){log(`Threat rises to ${S.threat}.`,'bad');
 if(S.type==='sabotage'&&enemies().some(e=>e.status==='ok')){const x=tilesWhere(c=>c==='X');if(x.length){const c=pickOne(x);S.grid[c.y][c.x]='C';fx(c,'DEFUSED','dmg');log('An Imperial tech defuses a charge.','bad')}}
 if(S.type==='escort')log('More hunters are on the way. They shoot the VIP on sight.','bad');
 if(S.type==='investigate'){const q=tilesWhere(c=>c==='q');if(q.length){const c=pickOne(q);S.grid[c.y][c.x]='r';fx(c,'WIPED','dmg');log('Imperial slicers wipe a data terminal.','bad')}}
 if(S.type==='rescue')log(S.threat>=5?'The Sith are prepping a shuttle. Next turn the prisoner is gone.':'The guards are getting nervous. One may fire on the prisoner.','bad');
 if(S.type!=='rescue'&&S.threat>=5)log('Last warning: next turn the window closes.','bad');
 if(S.threat>=6)return finish(false,`${THREAT_LOSE[S.type]||''} ${S.M.lose}`.trim());
 // Reinforcements every 2 Threat, at most 3 groups, so a stalled fight can't snowball forever.
 if(S.threat%2===0&&S.threat<=6&&S.M.reinforce)spawn(S.M.reinforce)}
async function endTurn(){
 if(S.phase!=='player'||S.over)return;
 evacCheck();if(S.over)return;
 S.phase='enemy';S.mode='move';S.tg=[];S.pick=null;S.peek=null;S.hostShot=0;render();await sleep(250);
 for(const e of enemies()){if(S.over)break;await eAct(e);if(window.View3D)await View3D.idle();checkEnd();render()}
 if(S.over)return;S.peek=null;
 if(S.type==='defend'&&S.turn>=S.M.turns)return finish(true,S.M.win);
 S.turn++;startPlayerTurn()}
// Evac zones extract the whole squad once the objective is in hand (prisoner on E, or anyone on E after 2 scans: the data is on every comlink).
function evacCheck(){if(S.type==='defend')return;
 for(const u of players().filter(u=>u.status==='ok'&&tile(u.x,u.y)==='E')){
  if(u.vip)return finish(true,S.M.win);
  if(S.type==='investigate'&&S.clues>=2)return finish(true,S.M.win);
}
 // Sabotage is a full extraction: every squad member still standing must be on an evac tile.
 if(S.type==='sabotage'&&armed()>=S.M.need){const up=players().filter(u=>!u.vip&&u.status==='ok');if(up.length&&up.every(u=>tile(u.x,u.y)==='E'))return finish(true,S.M.win)}}
const armed=()=>tilesWhere(c=>c==='X').length;
function checkEnd(){if(S.over)return;const M=S.M,sq=players().filter(u=>!u.vip);
 const foes=enemies().some(e=>e.status==='ok'||e.status==='stunned');
 if(S.type==='defend'&&S.obj<=0)return finish(false,M.lose);
 if(!sq.some(u=>u.status==='ok'))return finish(false,'The squad is overwhelmed.');
 if(S.type==='defend'&&S.turn>=M.lastWave&&!foes)return finish(true,`The last attackers are broken. ${M.win}`);
 if(S.type==='rescue'||S.type==='escort'){const h=hostage();if(!alive(h))return finish(false,`${h.n} is dead. ${M.lose}`);
  if(!foes)return finish(true,`${S.type==='escort'?'The route is clear.':'The depot is secured.'} ${M.win}`)}
 if(S.type==='investigate'){if(S.clues+tilesWhere(c=>c==='q').length<2)return finish(false,`Too much data was wiped. ${M.lose}`);
  if(!foes&&S.clues>=2)return finish(true,`The district is clear. ${M.win}`)}
 if(S.type==='sabotage'&&!foes&&armed()>=M.need)return finish(true,`The garrison is down. ${M.win}`)}
// For the HUD and the debrief: the objective readout and whether the mission bonus was earned.
function objStat(){const M=S.M,h=hostage();
 if(S.type==='assault'){const b=S.units.find(u=>u.boss);return{label:b?b.n:'Target',val:!b||b.hp<=0?'down':`${b.hp}/${b.max} HP`}}
 if(S.type==='defend')return{label:M.objName,val:`${S.obj}/${M.obj}`};
 if(S.type==='rescue')return{label:'Prisoner',val:h.status==='dead'?'dead':h.bound?'locked in':`${h.hp}/${h.max} HP`};
 if(S.type==='escort')return{label:'VIP',val:h.status==='dead'?'dead':`${h.hp}/${h.max} HP`};
 if(S.type==='sabotage')return{label:'Charges',val:`${armed()}/${M.need} armed`};
 return{label:'Clues',val:`${S.clues}/3 (need 2)`}}
function missionBonus(){const M=S.M;return S.type==='defend'?S.obj*4>=M.obj*3:S.type==='investigate'?S.clues>=3:S.turn<=M.par}
// Mission over: campaign.js applies results; base.js shows the debrief.
function finish(win,msg){S.over=true;S.phase='over';S.win=win;S.msg=msg;render();missionOver(win,msg)}
