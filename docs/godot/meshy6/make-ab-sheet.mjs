// One sheet, seven themes, desktop and phone, old row above v6 row.
import sharp from 'sharp';
const themes=['temple','dock','plains','city','ruins','caves','jungle'];
const root='docs/godot/shots';
const width=350, height=225, header=35, gap=8;
const outWidth=themes.length*(width+gap)+gap;
const outHeight=header+4*(height+gap)+gap;
const cells=[];
for(let col=0;col<themes.length;col++){
  const theme=themes[col];
  const label=Buffer.from(`<svg width="${width}" height="${header}"><style>text{fill:white;font:20px sans-serif}</style><text x="8" y="25">${theme.toUpperCase()}</text></svg>`);
  cells.push({input:label,left:gap+col*(width+gap),top:0});
  for(const [size,firstRow] of [['1366x768',0],['844x390',2]]){
    const path=`${root}/meshy6-${theme}-${size}.png`;
    const [w,h]=size.split('x').map(Number);
    for(let side=0;side<2;side++){
      const photo=await sharp(path).extract({left:side*w/2,top:0,width:w/2,height:h})
        .resize(width,height,{fit:'cover',position:'centre'}).jpeg({quality:86}).toBuffer();
      const row=firstRow+side;
      cells.push({input:photo,left:gap+col*(width+gap),top:header+gap+row*(height+gap)});
      const caption=Buffer.from(`<svg width="${width}" height="25"><rect width="${width}" height="25" fill="#17212b" fill-opacity=".8"/><text x="8" y="18" fill="white" font-family="sans-serif" font-size="16">${size}  ${side===0?'OLD':'V6'}</text></svg>`);
      cells.push({input:caption,left:gap+col*(width+gap),top:header+gap+row*(height+gap)+height-25});
    }
  }
}
await sharp({create:{width:outWidth,height:outHeight,channels:3,background:'#1d2530'}})
  .composite(cells).jpeg({quality:88}).toFile(`${root}/meshy6-before-after.jpg`);
