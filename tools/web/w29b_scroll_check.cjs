#!/usr/bin/env node
const {chromium} = require('/home/jess/hive/node_modules/playwright-core');
const {spawn,execFileSync} = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const repo = path.resolve(__dirname, '../..');
const logs = '/home/jess/projects/tw-logs/w29/scroll29';
const port = 8292;
const cases = [
  {name:'956x440',width:956,height:440},
  {name:'844x390',width:844,height:390},
  {name:'390x844',width:390,height:844},
  {name:'956x440-inset',width:956,height:440,safe:{left:59,bottom:34}}
];
const screens = ['temple','galaxy','squad','settings','readiness','briefing'];
const onlyCase=process.argv.find(x=>x.startsWith('--case='))?.slice(7);
const onlyScreen=process.argv.find(x=>x.startsWith('--screen='))?.slice(9);
const wait = ms => new Promise(r => setTimeout(r,ms));
const server = spawn('python3',['-m','http.server',String(port),'--bind','127.0.0.1'],{cwd:path.join(repo,'build/web'),stdio:'ignore'});
const cache = path.join(process.env.HOME,'.cache/ms-playwright');
const chromeDir = fs.readdirSync(cache).filter(x=>x.startsWith('chromium_headless_shell-')).sort().pop();
const chrome = path.join(cache,chromeDir,'chrome-headless-shell-linux64/chrome-headless-shell');
async function closeBrowser(browser) {
 await Promise.race([browser.close().catch(()=>{}),wait(5000)]);
 const children=execFileSync('ps',['-eo','pid=,ppid=,comm='],{encoding:'utf8'}).split('\n')
   .map(line=>line.trim().split(/\s+/)).filter(p=>Number(p[1])===process.pid&&p[2]?.startsWith('chrome-headless')).map(p=>p[0]);
 if(children.length) execFileSync('python3',['-c','import psutil,sys\nfor pid in map(int,sys.argv[1:]):\n try:\n  p=psutil.Process(pid)\n  for child in reversed(p.children(recursive=True)): child.kill()\n  p.kill()\n except psutil.NoSuchProcess: pass',...children]);
}
function rect(row,scale) { const a=row.rect; return {x:a[0]*scale.x,y:a[1]*scale.y,w:a[2]*scale.x,h:a[3]*scale.y}; }
function inside(a,b) { return a.x>=b.x-0.5 && a.y>=b.y-0.5 && a.x+a.w<=b.x+b.w+0.5 && a.y+a.h<=b.y+b.h+0.5; }
async function snapshot(page) {
 const state=await page.evaluate(()=>window.w29b_state||null);
 if (!state) throw Error('W29b probe unavailable');
 const canvas=await page.locator('#canvas').boundingBox();
 const scale={x:canvas.width/state.root[0],y:canvas.height/state.root[1]};
 const convert=r=>{const a=rect(r,scale);const full=r.full?rect({rect:r.full},scale):a;return {...r,x:canvas.x+a.x,y:canvas.y+a.y,w:a.w,h:a.h,fullCSS:{x:canvas.x+full.x,y:canvas.y+full.y,w:full.w,h:full.h}};};
 return {...state,controls:state.controls.map(convert),labels:state.labels.map(convert),scrolls:state.scrolls.map(convert),canvas};
}
async function command(page,name) {
 console.log('COMMAND',name);
 const serial=await page.evaluate(()=>window.w29b_state?.serial||0);
 await page.evaluate(name=>{window.w29b_command=name;},name);
 const expected={temple:'Temple',galaxy:'Galaxy',squad:'Squad',settings:'Temple',readiness:'Readiness25',briefing:'Briefing'}[name];
 try {await page.waitForFunction(expected=>window.w29b_state?.scene===expected,expected,{timeout:45000});}
 catch(e) {console.error('COMMAND STATE',name,await page.evaluate(()=>({command:window.w29b_command,state:window.w29b_state?.scene,controls:window.w29b_state?.controls?.length})));throw e;}
 console.log('COMMAND scene ready',name);
 if(name==='settings') {
   try {await page.waitForFunction(()=>['SettingsBack','GraphicsTier','Sound','TextSize'].every(n=>window.w29b_state?.controls?.some(c=>c.name===n)),null,{timeout:15000});}
   catch(e) {console.error('SETTINGS STATE',JSON.stringify(await page.evaluate(()=>window.w29b_state)));throw e;}
 }
 await page.waitForFunction(serial=>(window.w29b_state?.serial||0)>=serial+2,serial,{timeout:60000});
 await wait(200);
 console.log('COMMAND settled',name);
 if(name==='temple') {
   const after=await page.evaluate(()=>window.w29b_state?.serial||0);
   await page.evaluate(()=>{window.w29b_command='rooms';});
   await page.waitForFunction(after=>(window.w29b_state?.serial||0)>=after+2,after,{timeout:60000});
   console.log('COMMAND rooms open');
 }
 if(name==='galaxy') {
   const after=await page.evaluate(()=>window.w29b_state?.serial||0);
   await page.evaluate(()=>{window.w29b_command='galaxy_detail';});
   await page.waitForFunction(after=>(window.w29b_state?.serial||0)>=after+2,after,{timeout:60000});
 }
 if(name==='squad' && page.viewportSize().width>500) {
   const after=await page.evaluate(()=>window.w29b_state?.serial||0);
   await page.evaluate(()=>{window.w29b_command='squad_inspect';});
   await page.waitForFunction(after=>(window.w29b_state?.serial||0)>=after+2,after,{timeout:60000});
 }
 return snapshot(page);
}
async function route(page) {
 console.log('ROUTE loading');
 await page.goto(`http://127.0.0.1:${port}/?w29b_probe=1`,{waitUntil:'domcontentloaded'});
 await page.locator('#loading').waitFor({state:'hidden',timeout:240000});
 await page.touchscreen.tap(52,130);
 await page.touchscreen.tap(53,190);
 await wait(3000);
 await page.touchscreen.tap(570,405);
 await wait(3000);
 await page.touchscreen.tap(775,180);
 await wait(3000);
 await page.waitForFunction(()=>Boolean(window.w29b_state),null,{timeout:30000});
 console.log('ROUTE probe ready');
}
async function drag(page,x,y,dx,dy,steps=8) {
 const c=await page.context().newCDPSession(page);
 await c.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,id:1}]});
 for(let i=1;i<=steps;i++) { await c.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x+dx*i/steps,y:y+dy*i/steps,id:1}]}); await wait(26); }
 await c.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 await c.detach();
}
async function checkScreen(page,screen,item) {
 if(screen==='settings'||screen==='readiness') await command(page,'temple');
 let before=await command(page,screen);
 if(screen==='squad') console.log('SQUAD FOOTER',JSON.stringify(before.footerDebug),JSON.stringify(before.controls.filter(c=>c.owner===''&&c.y>item.height*0.6).map(c=>[c.name,c.x,c.y,c.w,c.h])));
 const shot=path.join(logs,`after-${screen}-${item.name}.png`);
 await page.screenshot({path:shot,scale:'css',timeout:120000});
 const safe={x:before.canvas.x+(item.safe?.left||0),y:before.canvas.y+(item.safe?.top||0),w:before.canvas.width-(item.safe?.left||0)-(item.safe?.right||0),h:before.canvas.height-(item.safe?.top||0)-(item.safe?.bottom||0)};
 const failures=[];let minimum=Infinity;
 for(const c of before.controls) {
   minimum=Math.min(minimum,c.fullCSS.w,c.fullCSS.h);
   if(c.fullCSS.w<43.5||c.fullCSS.h<43.5) failures.push(`${c.name} ${c.fullCSS.w.toFixed(1)}x${c.fullCSS.h.toFixed(1)}`);
   if(!inside(c,safe) && !c.owner) failures.push(`${c.name} outside safe area`);
 }
 for(let i=0;i<before.controls.length;i++) for(let j=i+1;j<before.controls.length;j++) {
   const a=before.controls[i],b=before.controls[j];
   if(a.owner!==b.owner) continue;
   if(a.owner && (a.w<43.5||a.h<43.5||b.w<43.5||b.h<43.5)) continue;
   const dx=Math.max(0,a.x-b.x-b.w,b.x-a.x-a.w);
   const dy=Math.max(0,a.y-b.y-b.h,b.y-a.y-a.h);
   const overlap=a.x<b.x+b.w&&b.x<a.x+a.w&&a.y<b.y+b.h&&b.y<a.y+a.h;
   if(overlap) failures.push(a.name+'/'+b.name+' overlap '+JSON.stringify([a.rect,b.rect]));
   else if(Math.hypot(dx,dy)<7.5) failures.push(a.name+'/'+b.name+' gap <8');
 }
 for(const l of before.labels) if(!inside(l,safe)) failures.push(`${l.name} outside safe area`);
 const scrolling=before.scrolls.filter(s=>s.maxX>10||s.maxY>10).reverse();
 console.log('SCROLLS',screen,scrolling.map(s=>[s.name,s.scrollX,s.scrollY,s.maxX,s.maxY,s.dragEvents]));
 let gesture=null;
 for(const s of scrolling) {
   const horizontal=s.maxX>10 && s.maxX>=s.maxY;
   const candidates=before.controls.filter(c=>c.owner===s.name && inside({x:c.x+c.w/2,y:c.y+c.h/2,w:0,h:0},s) && c.w>=44 && c.h>=44);
   const hit=screen==='settings'?candidates.find(c=>c.name==='GraphicsTier')||candidates[0]:candidates[0];
   if(!hit) continue;
   const x=hit.x+hit.w/2,y=hit.y+hit.h/2;
   const prior=before.presses?.[hit.id]||0;
   const pos=horizontal?s.scrollX:s.scrollY;
   const maximum=horizontal?s.maxX:s.maxY;
   const travel=screen==='briefing'?18:screen==='galaxy'?25:screen==='readiness'?40:Math.min(90,Math.max(25,maximum-pos-20));
   const fingerDelta=pos>maximum-20?90:-travel;
   console.log('DRAG start',screen,s.name,hit.name,pos,maximum,fingerDelta,'hit',hit.rect,'scrollRect',s.rect);
   await drag(page,x,y,horizontal?fingerDelta:0,horizontal?0:fingerDelta);
   console.log('DRAG released',screen);
   const released=await snapshot(page);
   console.log('DRAG snapshot',screen);
   const releaseScroll=released.scrolls.find(v=>v.name===s.name);
   const moved=horizontal?releaseScroll?.scrollX:releaseScroll?.scrollY;
   await wait(300);
   const after=await snapshot(page);
   const coastScroll=after.scrolls.find(v=>v.name===s.name);
   const coast=horizontal?coastScroll?.scrollX:coastScroll?.scrollY;
   const pressed=after.presses?.[hit.id]||0;
   gesture={scroll:s.name,control:hit.name,from:pos,max:maximum,released:moved,coast,presses:pressed-prior,dragEvents:(coastScroll?.dragEvents||0)-(s.dragEvents||0),mouseDragEvents:(coastScroll?.mouseDragEvents||0)-(s.mouseDragEvents||0),touchEvents:(coastScroll?.touchEvents||0)-(s.touchEvents||0)};
   if(pressed>prior) failures.push('drag pressed '+hit.name);
   if(fingerDelta<0 ? moved<=pos : moved>=pos) failures.push('card drag did not scroll '+s.name);
   const coastMoved=fingerDelta<0 ? coast>moved : coast<moved;
   const edgeMoved=Math.abs((coastScroll?.edge?.[horizontal?0:1]||0)-(releaseScroll?.edge?.[horizontal?0:1]||0))>1;
   if(!coastMoved && !(maximum<=100 && edgeMoved)) failures.push('flick had no inertia '+s.name);
   await page.evaluate(name=>{window.w29b_command='edge:'+name;},s.name);
   await wait(350);
   console.log('EDGE positioned',screen);
   const atEdge=await snapshot(page);
   const edgeHit=atEdge.controls.find(c=>c.owner===s.name&&c.w>=44&&c.h>=44&&inside({x:c.x+c.w/2,y:c.y+c.h/2,w:0,h:0},s))||hit;
   if(edgeHit) {
     console.log('EDGE drag',screen,edgeHit.name);
     await drag(page,edgeHit.x+edgeHit.w/2,edgeHit.y+edgeHit.h/2,horizontal?-65:0,horizontal?0:-65,5);
     console.log('EDGE released',screen);
     const past=await snapshot(page);
     const edgeNow=Math.abs(past.scrolls.find(v=>v.name===s.name)?.edge?.[horizontal?0:1]||0);
     await wait(800);
     const sprung=await snapshot(page);
     const edgeAfter=Math.abs(sprung.scrolls.find(v=>v.name===s.name)?.edge?.[horizontal?0:1]||0);
     gesture.edgeStart=edgeNow;gesture.edgeAfter=edgeAfter;
     if(edgeNow<1) failures.push('no elastic edge '+s.name);
     else if(edgeAfter>=edgeNow) failures.push('edge did not spring back '+s.name);
   }
   break;
 }
 if(scrolling.length && !gesture) {
   console.log('SCROLL HIT DEBUG',screen,JSON.stringify(before.controls.map(c=>[c.name,c.owner,c.x,c.y,c.w,c.h])));
   failures.push('no button inside scrollable list');
 }
 const pageOffset=await page.evaluate(()=>({x:window.scrollX,y:window.scrollY}));
 if(pageOffset.x||pageOffset.y) failures.push('page moved');
 if(screen==='squad' && item.name==='390x844') {
   const card=before.controls.find(c=>c.name.startsWith('@Button')&&c.y>item.height*0.65&&c.y<item.height*0.9);
   if(card) {
     await page.touchscreen.tap(card.x+card.w/2,card.y+card.h/2);
     await wait(850);
     await page.screenshot({path:path.join(logs,'after-armory-390x844.png'),scale:'css',timeout:120000});
   }
 }
 const minLabel=before.labels.length?Math.min(...before.labels.map(l=>Math.min(l.w,l.h))):null;
 return {screen,scene:before.scene,size:item.name,shot,controls:before.controls.length,minimumPt:Number(minimum.toFixed(1)),rosterLabels:before.labels.length,minLabelPt:minLabel===null?null:Number(minLabel.toFixed(1)),gesture,failures};
}
(async()=>{
 fs.mkdirSync(logs,{recursive:true});
 await wait(600);
 const browser=await chromium.launch({executablePath:chrome,args:['--use-gl=angle','--use-angle=swiftshader']});
 const results=[];
 try {
  const context=await browser.newContext({viewport:{width:956,height:440},isMobile:true,hasTouch:true,deviceScaleFactor:3});
  const page=await context.newPage();
  page.on('pageerror',e=>console.error('PAGE ERROR',e.message));
  await route(page);
  for(const item of cases.filter(x=>!onlyCase||x.name===onlyCase)) {
   const priorSerial=await page.evaluate(()=>window.w29b_state?.serial||0);
   await page.setViewportSize({width:item.width,height:item.height});
   await page.evaluate(safe=>{window.templeTestSafeArea=safe||{};window.tw_refresh_viewport?.();},item.safe);
   await page.waitForFunction(prior=>(window.w29b_state?.serial||0)>=prior+2,priorSerial,{timeout:60000});
   for(const screen of screens.filter(x=>!onlyScreen||x===onlyScreen)) {
    try {const row=await checkScreen(page,screen,item);results.push(row);console.log(JSON.stringify(row));}
    catch(e) {const row={screen,size:item.name,failures:[String(e)]};results.push(row);console.error(JSON.stringify(row));}
   }
  }
 } finally {fs.writeFileSync(path.join(logs,'measurements.json'),JSON.stringify(results,null,2));server.kill();await closeBrowser(browser);}
 if(results.some(r=>r.failures.length)) process.exitCode=1;
})().catch(e=>{console.error(e);server.kill();process.exitCode=1;});
