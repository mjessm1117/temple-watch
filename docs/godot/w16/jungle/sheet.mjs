import sharp from 'sharp';
const root='docs/godot/shots/';
const rows=[
 {path:root+'w16-jungle-844x390.png',title:'844×390  ·  Compatibility / Low',c:[[307,166],[421,185],[540,202]],crop:150},
 {path:root+'w16-jungle-1366x768.png',title:'1366×768  ·  Compatibility / Low',c:[[458,325],[684,365],[919,390]],crop:220}
];
const W=1260,H=870,panelW=420,panelH=400,items=[];
const bg='#172026';
for(let r=0;r<2;r++){
 const row=rows[r];
 for(let c=0;c<3;c++){
  const [x,y]=row.c[c],side=row.crop;
  const img=await sharp(row.path).extract({left:x-Math.floor(side/2),top:y-Math.floor(side/2),width:side,height:side}).resize(378,320,{fit:'contain',background:bg}).jpeg({quality:95}).toBuffer();
  items.push({input:img,left:c*panelW+21,top:r*panelH+90});
 }
}
const cols=['OLD  ·  procedural','V6  ·  sandbags','V7  ·  stone + trunk'];
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><style>text{font-family:DejaVu Sans,Arial,sans-serif;fill:#ecf0ed}</style><text x="22" y="38" font-size="27" font-weight="700">JUNGLE HALF COVER   ·   STAGED REVIEW</text>${rows.map((row,r)=>`<text x="22" y="${r*panelH+69}" font-size="16" fill="#a7b7ad">${row.title}</text>`).join('')}${cols.map((s,c)=>`<text x="${c*panelW+22}" y="${H-44}" font-size="21" font-weight="700">${s}</text>`).join('')}<line x1="0" y1="435" x2="1260" y2="435" stroke="#536058" stroke-width="2"/></svg>`;
await sharp({create:{width:W,height:H,channels:3,background:bg}}).composite([...items,{input:Buffer.from(svg),left:0,top:0}]).jpeg({quality:94}).toFile(root+'w16-jungle-before-after.jpg');
