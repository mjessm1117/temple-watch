/* Mission setup, turn flow, win/lose checks. */
function mk(base,side,extra){const u={...base,...extra,side,max:base.hp,status:'ok',ap:2,guard:false,ow:false,dark:0,focus:base.maxF?2:0};u.dmg=[...base.dmg];return u}
function spawn(list){
 const spots=[];for(let y=0;y<2;y++)for(let x=0;x<W;x++)if(PASS(tile(x,y))&&!unitAt(x,y))spots.push({x,y});
 spots.sort(()=>Math.random()-.5);
 list.forEach((t,i)=>{const p=spots[i];if(!p)return;S.eCount[t]=(S.eCount[t]||0)+1;const f=FOES[t];
  S.units.push(mk(f,'e',{type:t,n:`${f.n} ${S.eCount[t]}`,x:p.x,y:p.y}))});
 log(`Contact: ${list.length} hostiles at the north perimeter.`,'bad')}

function newGame(choice){
 S={grid:MAP.map(r=>r.split('')),units:ROSTER.map(r=>mk(r,'p',{abil:[...r.abil]})),turn:1,phase:'player',sel:null,mode:'move',tg:[],info:S?S.info:false,
    cons:CONS,log:[],fx:[],intel:0,kills:0,orderDark:0,eCount:{},over:false,peek:null};
 if(choice==='fort')[[3,10],[6,10],[2,9]].forEach(([x,y])=>S.grid[y][x]='c');
 if(choice==='supply'){S.units.find(u=>u.cls==='Medic').kits++;S.units.find(u=>u.cls==='Heavy').nades++}
 if(choice==='calm')S.units.filter(u=>u.jedi).forEach(u=>u.focus=u.maxF);
 spawn(WAVES[1]);log('Hold the relay for 8 turns. The fleet is coming.');
 S.sel=S.units[0];$('#modal').hidden=true;if(choice!=='none')saveGame();render()}

function select(u){S.sel=u;S.peek=null;S.mode='move';S.tg=[];render()}
function canAct(u){return u&&u.side==='p'&&u.status==='ok'&&u.ap>0&&S.phase==='player'&&!S.over}
function targetsFor(u,k){const ab=AB[k];return(ab.tg?ab.tg(u):[]).map(g=>({...g,x:g.x??g.t.x,y:g.y??g.t.y}))}
function exec(u,k,g){const ab=AB[k];if(ab.f)u.focus-=ab.f;ab.run(u,g);if(ab.ap===1)u.ap=Math.max(0,u.ap-1);else u.ap=0;after()}
function after(){S.mode='move';S.tg=[];checkEnd();if(!canAct(S.sel)){const n=players().find(canAct);if(n)S.sel=n}render()}

function startPlayerTurn(){
 S.phase='player';
 if(S.turn>1&&WAVES[S.turn])spawn(WAVES[S.turn]);
 for(const u of players()){u.guard=false;u.guardStruck=false;u.ow=false;
  if(u.status==='down'){u.bleed--;u.ap=0;if(u.bleed<=0){u.status='dead';log(`${u.n} has become one with the Force.`,'bad')}else log(`${u.n} is bleeding out: ${u.bleed} turn${u.bleed>1?'s':''} left.`,'bad')}
  else u.ap=2}
 S.sel=players().find(canAct)||null;S.mode='move';S.tg=[];checkEnd();saveGame();render()}
async function endTurn(){
 if(S.phase!=='player'||S.over)return;
 S.phase='enemy';S.mode='move';S.tg=[];S.peek=null;render();await sleep(250);
 for(const e of enemies()){if(S.over)break;await eAct(e);checkEnd();render()}
 if(S.over)return;
 if(S.turn>=TURNS)return finish(true,'The Republic fleet drops out of hyperspace. The relay held.');
 S.turn++;startPlayerTurn()}
function checkEnd(){if(S.over)return;
 if(S.cons<=0)return finish(false,'The relay fell. The Sith now hold the hyperlane toward the Core.');
 if(!players().some(u=>u.status==='ok'))return finish(false,'The outpost is overrun.');
 if(S.turn>=LAST_WAVE&&!enemies().some(e=>e.status==='ok'||e.status==='stunned'))finish(true,'The last Sith squad is broken. The relay held.')}
