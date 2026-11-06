import sharp from 'sharp';

const names=['trooper','scout','sniper','heavy','tech','droid','officer'];
const colors={sniper:'#4c6133',heavy:'#b3541a',tech:'#1a737a',droid:'#cca826',officer:'#8c1a1f'};
const out='docs/godot/shots/';
const bg='#263342';
const label=(s,w,h,size=22)=>Buffer.from(`<svg width="${w}" height="${h}"><text x="4" y="${size+3}" font-family="sans-serif" font-size="${size}" font-weight="bold" fill="#f2e9d7">${s}</text></svg>`);
const pic=(name,view)=>`/tmp/w17-fix6-${name}-${view}.png`;
{
  const parts=[{input:label('TEMPLE WATCH / W17 ART FIX 6',2100,48,30),left:20,top:6}];
  for(let i=0;i<names.length;i++){
    const name=names[i],x=15+300*i;
    parts.push({input:label(name.toUpperCase(),280,38),left:x,top:53});
    if(colors[name])parts.push({input:Buffer.from(`<svg width="278" height="9"><rect width="278" height="9" fill="${colors[name]}"/></svg>`),left:x,top:88});
    for(const [view,y] of [['front',105],['three-quarter',430]]){
      parts.push({input:await sharp(pic(name,view)).resize(285,312,{fit:'contain',background:bg}).png().toBuffer(),left:x,top:y});
    }
  }
  await sharp({create:{width:2115,height:755,channels:4,background:bg}}).composite(parts).png().toFile(`${out}w17-art6-classes.png`);
}
{
  const parts=[];
  for(let i=0;i<5;i++){
    const name=names[i+2],x=12+390*i;
    parts.push({input:label(`${name.toUpperCase()} / SHOOT`,370,38,23),left:x,top:12});
    parts.push({input:await sharp(pic(name,'shoot')).png().toBuffer(),left:x,top:52});
  }
  await sharp({create:{width:1960,height:545,channels:4,background:bg}}).composite(parts).png().toFile(`${out}w17-art6-shoot.png`);
}
{
  const parts=[];
  for(let i=0;i<names.length;i++){
    const name=names[i],x=9+i*112;
    const image=await sharp(pic(name,'front')).extract({left:87,top:105,width:210,height:300}).resize({height:64}).png().toBuffer();
    parts.push({input:image,left:x+29,top:9});
    parts.push({input:label(name.toUpperCase(),108,20,13),left:x,top:82});
    if(colors[name])parts.push({input:Buffer.from(`<svg width="103" height="5"><rect width="103" height="5" fill="${colors[name]}"/></svg>`),left:x,top:76});
  }
  await sharp({create:{width:795,height:105,channels:4,background:bg}}).composite(parts).png().toFile(`${out}w17-art6-small.png`);
}
