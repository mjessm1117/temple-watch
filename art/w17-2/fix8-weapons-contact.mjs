import sharp from 'sharp';
const out='docs/godot/shots/w17-art8-weapons.png';
const cells=[['SNIPER RIFLE','sniper','weapon'],['HEAVY REPEATER','heavy','weapon'],['TECH CARBINE','tech','weapon'],['DROID BLASTER','droid','weapon'],['OFFICER PISTOL','officer','weapon'],['ROCKET PACK','heavy','pack'],['BATTERY PACK','tech','pack']];
const width=2240,height=555,bg='#263342';
const label=(s,w,h,size=20,color='#f2e9d7')=>Buffer.from(`<svg width="${w}" height="${h}"><text x="4" y="${size+3}" font-family="sans-serif" font-size="${size}" font-weight="bold" fill="${color}">${s}</text></svg>`);
const parts=[{input:label('W17 / FIX 8 GEAR / OLD ABOVE NEW',width,36,28),left:12,top:3}];
for(let i=0;i<cells.length;i++){
  const [title,kind,part]=cells[i],x=8+i*320;
  parts.push({input:label(title,310,30,17),left:x+4,top:36});
  for(const [row,y] of [['old',72],['new',315]]){
    parts.push({input:await sharp(`/tmp/w17-fix8-${row}-${kind}-${part}.png`).resize(310,223).png().toBuffer(),left:x,top:y});
    parts.push({input:label(row.toUpperCase(),70,24,16,row==='new'?'#8de3bd':'#e8b18f'),left:x+8,top:y+6});
  }
}
await sharp({create:{width,height,channels:4,background:bg}}).composite(parts).png().toFile(out);
