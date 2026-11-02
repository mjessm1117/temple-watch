// Assemble inspected renders with scores. No image generation or paid calls.
import fs from 'fs';
import sharp from 'sharp';
const batch1b=process.argv.includes('--batch1b');
const winner=process.argv[process.argv.indexOf('--winner')+1];
const batch=batch1b?'meshy1b':'meshy1';
const scores=JSON.parse(fs.readFileSync(`art/briefs/${batch}-scores.json`));
const composites=[];let row=0;
for(const [asset,variants] of Object.entries(scores)){
 let col=0;
 for(const [letter,score] of Object.entries(variants)){
  const input=`art/${batch}/${asset}.${letter}.preview.png`,left=col*480,top=row*620;
  const close=await sharp(input).extract({left:0,top:60,width:640,height:640}).resize(480,480).png().toBuffer();
  composites.push({input:close,left,top:top+80});
  const far=await sharp(input).extract({left:900,top:300,width:120,height:120}).png().toBuffer();
  composites.push({input:far,left:left+350,top:top+440});
  const title=`${asset} / ${letter}`;
  const text=`S ${score[0]} / Style ${score[1]} / Clean ${score[2]} / Poly ${score[3]}`;
  const label=Buffer.from(`<svg width="480" height="620"><style>text{font-family:sans-serif;fill:white;font-size:20px}</style><text x="16" y="35">${title}</text><text x="16" y="65">${text}</text><text x="16" y="590">${batch1b?(letter===winner?'WINNER':'Retained alternate'):asset==='obj_terminal'&&letter==='B'?'WINNER':asset==='cover_half_temple'&&letter==='D'?'KITBASH SOURCE WINNER':'Retained alternate'}</text><text x="355" y="580" style="font-size:13px">25u, 1:1 pixels</text></svg>`);
  composites.push({input:label,left,top});col++;
 }row++;
}
await sharp({create:{width:batch1b?1440:1920,height:batch1b?620:1240,channels:4,background:'#28323c'}}).composite(composites).png().toFile(`docs/godot/shots/${batch}-previews.png`);
