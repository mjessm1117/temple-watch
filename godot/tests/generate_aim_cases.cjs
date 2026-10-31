// Generate Godot parity fixtures by executing the frozen web rules.js in a minimal VM.
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = path.resolve(__dirname, '../..');
const source = fs.readFileSync(path.join(root, 'public/js/rules.js'), 'utf8');
let rows = Array.from({length: 12}, () => '.'.repeat(12));
const context = {
  tile: (x, y) => rows[y]?.[x] || '#',
  TILES: {'.': {}, '^': {elev: 1}, M: {elev: 2}, c: {}, h: {}, '#': {h: 2}},
  N4: [[1,0],[-1,0],[0,1],[0,-1]],
  FULL: c => c === '#', HALF: c => c === 'c' || c === 'h',
  inb: (x,y) => x >= 0 && y >= 0 && x < 12 && y < 12,
  dist: (a,b) => Math.hypot(a.x-b.x,a.y-b.y),
  cheb: (a,b) => Math.max(Math.abs(a.x-b.x),Math.abs(a.y-b.y)),
  S: {smoke: [], units: [], bmed: null, conc: false},
  players: () => [], enemies: () => [], byId: () => null, console
};
vm.createContext(context);
vm.runInContext(source, context);
const cases = [];
function add(name, ax, ay, tx, ty, range=8, aim=70, tiles=[], melee=false, defense=0) {
  rows = Array.from({length: 12}, () => '.'.repeat(12));
  for (const [x,y,c] of tiles) rows[y] = rows[y].slice(0,x) + c + rows[y].slice(x+1);
  context.a = {x:ax,y:ay,aim,range,side:'neutral'};
  context.t = {x:tx,y:ty,side:'neutral',buffDef:defense};
  context.melee = melee;
  const actual = vm.runInContext('odds(a,t,{melee})', context);
  cases.push({name,attacker:context.a,target:context.t,melee,defense,tiles,expected:actual.total,lines:actual.lines});
}
add('clear near',2,2,5,2);
add('clear far',1,1,9,1);
add('half front',2,2,5,2,8,70,[[4,2,'c']]);
add('full front',2,2,5,2,8,70,[[4,2,'#']]);
add('flank half',5,5,5,8,8,70,[[4,8,'c']]);
add('higher shooter',2,2,5,2,8,70,[[2,2,'^']]);
add('higher target',2,2,5,2,8,70,[[5,2,'^']]);
add('high above cover',2,2,5,2,8,70,[[2,2,'M'],[4,2,'c']]);
add('long range clamp',1,1,10,10,4,5);
add('high aim clamp',2,2,3,2,8,120);
add('melee',2,2,3,2,1.5,75,[],true);
add('defense',2,2,5,2,8,70,[],false,15);
fs.writeFileSync(path.join(__dirname, 'aim_cases.json'), JSON.stringify(cases,null,2)+'\n');
