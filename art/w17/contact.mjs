import sharp from 'sharp';
const base='art/w17/',shot='docs/godot/shots/';
const width=1600,height=1220,parts=[];
const names=['trooper','scout','sniper','heavy'];
const esc=s=>s.replace(/&/g,'&amp;');
const label=(s,x,y,size=23)=>parts.push({input:Buffer.from(`<svg width="380" height="42"><text x="0" y="29" font-family="sans-serif" font-weight="bold" font-size="${size}" fill="#f2e9d7">${esc(s)}</text></svg>`),left:x,top:y});
parts.push({input:Buffer.from('<svg width="1500" height="42"><text x="0" y="29" font-family="sans-serif" font-weight="bold" font-size="29" fill="#f2e9d7">TEMPLE WATCH / W17 SOLDIER CLASSES</text></svg>'),left:30,top:3});
for(let c=0;c<4;c++){
 const name=names[c],x=20+c*395;
 label(name.toUpperCase()+' / FRONT',x,48,20);
 label(name.toUpperCase()+' / 3/4',x,446,20);
 for(const [view,y] of [['front',84],['three-quarter',482]]){
  const buf=await sharp(base+`portrait-${name}-${view}.png`).extract({left:0,top:55,width:384,height:405}).resize(380,360,{fit:'contain',background:'#263342'}).png().toBuffer();
  parts.push({input:buf,left:x,top:y});
 }
}
label('SNIPER / LOW / 844 x 390',30,854,20);label('HEAVY / LOW / 844 x 390',822,854,20);
for(const [name,x] of [['sniper',20],['heavy',810]]){
 const buf=await sharp(shot+`w17-art-${name}-battle-low.png`).resize(770,356).png().toBuffer();
 parts.push({input:buf,left:x,top:896});
}
await sharp({create:{width,height:1260,channels:4,background:'#182330'}}).composite(parts).png().toFile(shot+'w17-art-classes.png');
console.log('contact',width,1260);
