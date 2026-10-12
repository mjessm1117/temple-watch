/* Small helpers and map rules (tiles, distance, cover types). Legend in data.js. */
const $=s=>document.querySelector(s);
const rnd=n=>Math.random()*100<n;
const ri=(a,b)=>a+Math.floor(Math.random()*(b-a+1));
const pickOne=a=>a[Math.floor(Math.random()*a.length)];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const cheb=(a,b)=>Math.max(Math.abs(a.x-b.x),Math.abs(a.y-b.y));
const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const inb=(x,y)=>x>=0&&y>=0&&x<W&&y<H;
const FULL=c=>'#OdD'.includes(c),HALF=c=>'crxkqQ'.includes(c),PASS=c=>c==='.'||c==='r'||c==='_'||c==='E';
const N4=[[1,0],[-1,0],[0,1],[0,-1]];
