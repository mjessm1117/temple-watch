// Lossless web story export. Run from the repository root with node godot/scripts/story/convert_story.cjs.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');
const root = path.resolve(__dirname, '../../..');
const out = path.join(root, 'godot/data/story');
const sources = [
  'public/js/story.js', 'public/js/data-story.js',
  'public/js/story-era2.js', 'public/js/data-era2.js',
  'public/js/story-era3.js', 'public/js/data-era3.js',
  'public/js/saga.js', 'public/js/data-saga.js',
  'public/js/data-codex.js', 'public/js/ui-codex.js',
  'public/js/tutorial.js', 'public/js/data-life.js',
  'public/js/temple-life.js',
  'docs/specs/story.md', 'docs/specs/saga.md', 'docs/specs/chains.md'
];
const tables = ['FOES','MISSIONS','CRISES','ESCORTS','EVENTS','PLAN','CODEX','COUNCIL_SEATS','STORY_RECRUITS','FLAG_LINES','EPI','MISSION_LORE','EVENT_LORE','ARMOR','TUNE'];
const ctx = vm.createContext({console});
ctx.window = ctx;
ctx.ARMOR = {};
ctx.ESCORTS = {};
ctx.TUNE = {};
function run(file) { vm.runInContext(fs.readFileSync(path.join(root,file),'utf8'),ctx,{filename:file}); }
function val(name) {
  try { return JSON.parse(JSON.stringify(vm.runInContext(name,ctx),(_key,value)=>typeof value==='function'?{$js:value.toString()}:value)); }
  catch { return null; }
}
function snap() { return Object.fromEntries(tables.map(t=>[t,val(t)])); }
function delta(a,b) {
  const result={};
  for (const t of tables) {
    const old=a[t], now=b[t];
    if (Array.isArray(now)) {
      const prior=Array.isArray(old)?old.length:0;
      if(now.length>prior) result[t]=now.slice(prior);
    } else if(now && typeof now==='object') {
      const changed={};
      for(const [k,v] of Object.entries(now)) if(JSON.stringify(v)!==JSON.stringify(old?.[k])) changed[k]=v;
      if(Object.keys(changed).length)result[t]=changed;
    }
  }
  return result;
}
run('public/js/data.js');
run('public/js/data-campaign.js');
const base_missions=val('MISSIONS');
const base_crises=val('CRISES');
const order=['public/js/data-story.js','public/js/data-codex.js','public/js/data-era2.js','public/js/data-era3.js','public/js/data-saga.js','public/js/data-life.js'];
const captured={};
for(const file of order) {
  const before=snap();
  run(file);
  const records=delta(before,snap());
  const names={
    'data-story':['ERA1','SHADOW','YEARS','ACTS','SHARDS','STORY_TEXT','QUOTES','BRIEF_IF','DEBRIEF_IF','BARKS','HERO_BARKS','EPILOGUE'],
    'data-era2':['ERA2','ACTS2','SHARDS2','PLAN2','ERA2_ROSTER','BANE','STORY_TEXT2','ERA2_LORE'],
    'data-era3':['ERA3','ACTS3','SHARDS3','PLAN3','ERA3_ROSTER','STORY_TEXT3','ERA3_LORE'],
    'data-saga':['CAST','TRUST','TALKS','GRIEF','AP_BRIEF','APPROACH','SQUAD_BEATS','AFTER','FINALE','SAGA_EPI'],
    'data-life':['SEATS','STANCE_PERK','COUNCIL_RULES','VOTES','MARKET','MARKET_ITEMS','SAY_LINES','LOOKS','PAIR','BIO_MAX','PRESET_MAX'],
    'ui-codex':['KINDS','STATUS_INFO','STAT_INFO','MOD_INFO']
  }[path.basename(file,'.js')]||[];
  for(const name of names) { const v=val(name); if(v!==null) records[name]=v; }
  if(file==='public/js/data-story.js') {
    records.PLAN=val('PLAN');
    records.BASE_MISSIONS=base_missions;
    records.BASE_CRISES=base_crises;
  }
  captured[file]=records;
}
// ui-codex.js has DOM side effects; its static tables are evaluated from their declarations only.
const ui=fs.readFileSync(path.join(root,'public/js/ui-codex.js'),'utf8');
for(const name of ['KINDS','STATUS_INFO','STAT_INFO','MOD_INFO']) {
  const start=ui.indexOf('const '+name+'=');
  if(start<0)continue;
  const end=ui.indexOf(name==='KINDS'?'];\n':'};\n',start)+2;
  vm.runInContext(ui.slice(start,end),ctx);
  captured['public/js/ui-codex.js']??={};
  captured['public/js/ui-codex.js'][name]=val(name);
}
const tut=fs.readFileSync(path.join(root,'public/js/tutorial.js'),'utf8');
vm.runInContext(tut.slice(tut.indexOf('const TUT_CARD='),tut.indexOf('];\n',tut.indexOf('const TUT_CARD='))+2),ctx);
captured['public/js/tutorial.js']={TUT_CARD:val('TUT_CARD')};
// Era 3's module adds a few data rows at load time, after data-life.js.
ctx.PLANETS={}; ctx.FIELD_PLANETS={}; ctx.REDEEM_TXT={}; ctx.GUESTS={};
const era3Logic=fs.readFileSync(path.join(root,'public/js/story-era3.js'),'utf8');
vm.runInContext(era3Logic.slice(0,era3Logic.indexOf('// ── Era swap')),ctx);
captured['public/js/story-era3.js']={
  SEATS:Object.fromEntries(Object.entries(val('SEATS')).filter(([,v])=>v.era===3)),
  PLANETS:val('PLANETS'),FIELD_PLANETS:val('FIELD_PLANETS'),
  REDEEM_TXT:val('REDEEM_TXT'),GUESTS:val('GUESTS')
};
function sourceLiterals(source) {
  const items=[];
  let line=1;
  for(let i=0;i<source.length;) {
    const c=source[i], n=source[i+1];
    if(c==='/'&&n==='/') { while(i<source.length&&source[i]!=='\n')i++; continue; }
    if(c==='/'&&n==='*') {
      i+=2;
      while(i<source.length&&!(source[i]==='*'&&source[i+1]==='/')) {if(source[i]==='\n')line++;i++;}
      i+=2; continue;
    }
    if(c==='\''||c==='"'||c==='`') {
      const start=i, startLine=line, quote=c;
      i++;
      while(i<source.length) {
        if(source[i]==='\\') {i+=2;continue;}
        if(source[i]==='\n')line++;
        if(source[i++]===quote)break;
      }
      items.push({line:startLine,raw:source.slice(start,i)});
      continue;
    }
    if(c==='\n')line++;
    i++;
  }
  return items;
}
const check=process.argv.includes('--check');
fs.mkdirSync(out,{recursive:true});
let failed=0;
for(const file of sources) {
  const source=fs.readFileSync(path.join(root,file),'utf8');
  const records=captured[file]||{};
  if(file.endsWith('.js')) records.SOURCE_LITERALS=sourceLiterals(source);
  else records.MARKDOWN_BLOCKS=source.split(/\n\s*\n/).filter(Boolean);
  const counts={};
  for(const [k,v] of Object.entries(records)) counts[k]=Array.isArray(v)?v.length:(v&&typeof v==='object'?Object.keys(v).length:1);
  const item={source:file,sha256:crypto.createHash('sha256').update(source).digest('hex'),lines:source.split('\n').length-1,counts,records,text:source};
  const dest=path.join(out,(file.startsWith('docs/')?'spec-':'')+path.basename(file).replace(/\.(js|md)$/,'.json'));
  const body=JSON.stringify(item,null,2)+'\n';
  if(check) { if(!fs.existsSync(dest)||fs.readFileSync(dest,'utf8')!==body) {console.error('Mismatch: '+file);failed++;} }
  else fs.writeFileSync(dest,body);
  console.log(`${file} -> ${path.relative(root,dest)} ${JSON.stringify(counts)}`);
}
if(failed)process.exit(1);
