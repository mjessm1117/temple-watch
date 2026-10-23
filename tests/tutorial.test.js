// Wave 7 (A2 flow, E2 test): "Show tips?" choice on a new campaign, controls card on the first mission only, Turn off works.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0,errs=[];const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const run=tips=>{const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,E=s=>w.eval(s);w.addEventListener('error',e=>errs.push(e.message));
 E(`SETTINGS.tips=${tips};newCampaign('normal')`);const card=()=>{const l=w.document.getElementById('ui-tut');return !!l&&!l.hidden};
 check(E('C.tut')===(tips?1:0),`tips ${tips?'on':'off'}: campaign remembers the choice`);
 E("launchMission(0,C.roster.filter(fit).slice(0,6).map(r=>r.id))");check(card()===tips,`tips ${tips?'on: card shows':'off: no card'} on the first mission`);
 if(tips){w.document.querySelector('#tutOff').click();check(E('SETTINGS.tips')===false,'Turn off tips works');
  E("launchMission(0,C.roster.filter(fit).slice(0,6).map(r=>r.id))");check(!card(),'card shows only once')}
 w.close()};
run(true);run(false);
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({fail,err:errs.length}));process.exit(fail||errs.length?1:0);
