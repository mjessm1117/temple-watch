import sharp from 'sharp';
const base='art/w17-2/',shot='docs/godot/shots/';
const names=['trooper','scout','sniper','heavy','tech','droid','officer'];
const W=2100,H=1150,parts=[];
const label=(s,x,y,size=20)=>parts.push({input:Buffer.from(`<svg width="285" height="38"><text x="0" y="27" font-family="sans-serif" font-weight="bold" font-size="${size}" fill="#f2e9d7">${s}</text></svg>`),left:x,top:y});
parts.push({input:Buffer.from('<svg width="1800" height="42"><text x="0" y="30" font-family="sans-serif" font-weight="bold" font-size="30" fill="#f2e9d7">TEMPLE WATCH / W17 ART FIX 3</text></svg>'),left:24,top:5});
for(let i=0;i<names.length;i++){
 const name=names[i],x=12+i*298;label(name.toUpperCase(),x,47);
 for(const [view,y] of [['front',82],['three-quarter',402]]){
  const b=await sharp(base+`portrait-${name}-${view}.png`).extract({left:0,top:45,width:384,height:420}).resize(290,310,{fit:'contain',background:'#263342'}).png().toBuffer();
  parts.push({input:b,left:x,top:y});
 }
}
for(let i=0;i<3;i++){
 const k=['tech','droid','officer'][i],x=10+i*697;
 label(k.toUpperCase()+' / LOW 844×390',x,735);
 const b=await sharp(shot+`w17-art2-${k}-battle-low.png`).resize(680,314).png().toBuffer();
 parts.push({input:b,left:x,top:777});
}
await sharp({create:{width:W,height:H,channels:4,background:'#182330'}}).composite(parts).png().toFile(shot+'w17-art-classes2.png');
