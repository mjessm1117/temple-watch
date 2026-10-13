/* Mission setup, turn flow, threat clock, evac, win/lose checks. */
function mk(base,side,extra={}){const u={...base,...extra,side,status:'ok',ap:2,guard:false,ow:false,dark:base.dark||0,miss:0,uid:++S.uidN};
 u.max=u.hp;u.focus=u.maxF?2:0;u.dmg=[...u.dmg];if(u.abil){u.abil=[...u.abil];for(const k of u.abil)if(AB[k]&&AB[k].passive)u[k]=1}return u}
function mkFoe(t,x,y){const f=FOES[t],d=S.d;S.eCount[t]=(S.eCount[t]||0)+1;
 return mk({...f,hp:Math.max(1,f.hp+(f.horror?0:d.enemyHp)),aim:f.aim+d.enemyAim},'e',{type:t,n:f.envoy?f.n:`${f.n} ${S.eCount[t]}`,x,y})}
function spawn(list){list=[...list];for(let i=0;i<S.d.extra;i++)list.push('trooper');
 const spots=tilesWhere((c,x,y)=>y<2&&PASS(c)&&!unitAt(x,y)).sort(()=>Math.random()-.5);
 list.forEach((t,i)=>{const p=spots[i];if(p)S.units.push(mkFoe(t,p.x,p.y))});
 log(`Contact: ${list.length} hostiles at the north edge.`,'bad')}

// squad: battle-ready unit stats (campaign.js battleUnit). o: {diff, hostage, crisis}
function startMission(id,squad,o={}){const M=MISSIONS[id];
 S={id,M,type:M.type,grid:M.map.map(r=>r.split('')),units:[],uidN:0,turn:1,phase:'player',sel:null,mode:'move',tg:[],pick:null,info:S?S.info:false,
    diff:o.diff||'normal',d:DIFF[o.diff||'normal'],obj:M.obj||0,threat:0,clues:0,smoke:[],bmed:null,log:[],fx:[],intel:0,kills:0,orderDark:0,eCount:{},over:false,peek:null,crisis:o.crisis||null};
 squad.slice(0,6).forEach((r,i)=>{const p=M.start[i];S.units.push(mk(r,'p',{x:p[0],y:p[1]}))});
 if(S.d.bonusKit){const m=S.units.find(u=>u.kits!=null);if(m)m.kits++}
 if(M.hostage){const h=o.hostage||VIP;S.units.push(mk({...h,vip:1,bound:1},'p',{x:M.hostage[0],y:M.hostage[1]}))}
 for(const [t,x,y] of M.foes||[])S.units.push(mkFoe(t,x,y));
 if(M.waves)spawn(M.waves[1]);
 log(M.goal);S.sel=players().find(canAct)||null;$('#modal').hidden=true;SCR=null;render();saveGame()}

function select(u){S.sel=u;S.peek=null;S.mode='move';S.tg=[];S.pick=null;render()}
function canAct(u){return !!u&&u.side==='p'&&u.status==='ok'&&!u.bound&&u.ap>0&&S.phase==='player'&&!S.over}
function targetsFor(u,k){const ab=AB[k];return(ab.tg?ab.tg(u):[]).map(g=>({...g,x:g.x??g.t.x,y:g.y??g.t.y}))}
function exec(u,k,g){const ab=AB[k];if(ab.f)u.focus-=ab.f;ab.run(u,g);if(ab.ap===1)u.ap=Math.max(0,u.ap-1);else u.ap=0;after()}
function after(){S.mode='move';S.tg=[];S.pick=null;checkEnd();if(!canAct(S.sel)){const n=players().find(canAct);if(n)S.sel=n}render()}

function startPlayerTurn(){const M=S.M;
 S.phase='player';
 if(M.waves&&S.turn>1&&M.waves[S.turn])spawn(M.waves[S.turn]);
 if(M.par&&S.turn>M.par){S.threat++;threatStep();if(S.over)return}
 S.smoke=S.smoke.filter(s=>--s.t>0);S.bmed=null;
 for(const u of S.units){u.supp=0;u.marked=0;if(u.side==='p'){u.supT=null;u.hunker=0;u.barrier=0;u.leapAim=0}}
 for(const u of players()){u.guard=false;u.guardStruck=false;u.ow=false;
  if(u.status==='down'){u.ap=0;if(u.stable)continue;u.bleed--;if(u.bleed<=0){u.status='dead';log(`${u.n} has become one with the Force.`,'bad')}else log(`${u.n} is bleeding out: ${u.bleed} turn${u.bleed>1?'s':''} left.`,'bad')}
  else u.ap=2}
 S.sel=players().find(canAct)||null;S.mode='move';S.tg=[];S.pick=null;checkEnd();saveGame();render()}
// Soft pressure: past the par turn, each turn raises Threat by 1 and the mission gets worse.
function threatStep(){log(`Threat rises to ${S.threat}.`,'bad');
 if(S.type==='investigate'){const q=tilesWhere(c=>c==='q');if(q.length){const c=pickOne(q);S.grid[c.y][c.x]='r';fx(c,'WIPED','dmg');log('Imperial slicers wipe a data terminal.','bad')}}
 if(S.type==='rescue')log(S.threat>=5?'The Sith are prepping a shuttle. Next turn the prisoner is gone.':'The guards are getting nervous. One may fire on the prisoner.','bad');
 if(S.type==='investigate'&&S.threat>=5)log('The district is locking down. Next turn the trail goes cold.','bad');
 if(S.threat>=6)return finish(false,S.type==='rescue'?`The Sith fly the prisoner out. ${S.M.lose}`:`The district locks down. ${S.M.lose}`);
 // Reinforcements every 2 Threat, at most 3 groups, so a stalled fight can't snowball forever.
 if(S.threat%2===0&&S.threat<=6&&S.M.reinforce)spawn(S.M.reinforce)}
async function endTurn(){
 if(S.phase!=='player'||S.over)return;
 evacCheck();if(S.over)return;
 S.phase='enemy';S.mode='move';S.tg=[];S.pick=null;S.peek=null;S.hostShot=0;render();await sleep(250);
 for(const e of enemies()){if(S.over)break;await eAct(e);checkEnd();render()}
 if(S.over)return;S.peek=null;
 if(S.type==='defend'&&S.turn>=S.M.turns)return finish(true,S.M.win);
 S.turn++;startPlayerTurn()}
// Evac zones extract the whole squad once the objective is in hand (prisoner on E, or anyone on E after 2 scans: the data is on every comlink).
function evacCheck(){if(S.type==='defend')return;
 for(const u of players().filter(u=>u.status==='ok'&&tile(u.x,u.y)==='E')){
  if(u.vip)return finish(true,S.M.win);
  if(S.type==='investigate'&&S.clues>=2)return finish(true,S.M.win)}}
function checkEnd(){if(S.over)return;const M=S.M,sq=players().filter(u=>!u.vip);
 const foes=enemies().some(e=>e.status==='ok'||e.status==='stunned');
 if(S.type==='defend'&&S.obj<=0)return finish(false,M.lose);
 if(!sq.some(u=>u.status==='ok'))return finish(false,'The squad is overwhelmed.');
 if(S.type==='defend'&&S.turn>=M.lastWave&&!foes)return finish(true,`The last attackers are broken. ${M.win}`);
 if(S.type==='rescue'){const h=hostage();if(!alive(h))return finish(false,`${h.n} is dead. ${M.lose}`);
  if(!foes)return finish(true,`The depot is secured. ${M.win}`)}
 if(S.type==='investigate'){if(S.clues+tilesWhere(c=>c==='q').length<2)return finish(false,`Too much data was wiped. ${M.lose}`);
  if(!foes&&S.clues>=2)return finish(true,`The district is clear. ${M.win}`)}}
// Mission over: campaign.js applies results; base.js shows the debrief.
function finish(win,msg){S.over=true;S.phase='over';S.win=win;S.msg=msg;render();missionOver(win,msg)}
