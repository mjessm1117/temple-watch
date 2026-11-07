"""Compose the required JPG review sheets from the 844x390 Blender captures."""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path

root=Path('/home/jess/projects/tw-logs/w19')
src=root/'art'
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
title=ImageFont.truetype(font,25);small=ImageFont.truetype(font,18)
names=('SNIPER','HEAVY','TECH','OFFICER','MEDIC','DROID','SCOUT')
bg=(22,29,39);white=(235,239,245);muted=(170,185,202)

def label_lineup(im):
    d=ImageDraw.Draw(im)
    for i,name in enumerate(names):
        x=146+i*91.5
        bbox=d.textbbox((0,0),name,font=small);w=bbox[2]-bbox[0]
        d.text((x-w/2,237),name,font=small,fill=white,stroke_width=2,stroke_fill=(20,25,33))
    return im

lineup=label_lineup(Image.open(src/'w19-battle.jpg').convert('RGB'))
lineup.save(root/'2026-11-07-soldier-lineup.jpg',quality=93,subsampling=0)

sheet=Image.new('RGB',(2100,1750),bg);d=ImageDraw.Draw(sheet)
d.text((26,12),'TEMPLE WATCH  •  SOLDIER SILHOUETTES',font=title,fill=white)
d.text((26,55),'844 × 390 battle camera  •  W17 → W19',font=small,fill=muted)
for x,version in ((180,'w17'),(1076,'w19')):
    d.text((x,87),version.upper()+'  /  BATTLE',font=small,fill=white)
    im=Image.open(src/f'{version}-battle.jpg').convert('RGB')
    sheet.paste(label_lineup(im),(x,115))
d.text((26,536),'ARMORY CLOSE-UP  /  W17',font=title,fill=white)
sheet.paste(Image.open(src/'w17-armory.jpg').convert('RGB'),(0,574))
d.text((26,989),'ARMORY CLOSE-UP  /  W19',font=title,fill=white)
sheet.paste(Image.open(src/'w19-armory.jpg').convert('RGB'),(0,1027))
for y in (965,1418):
    for i,name in enumerate(names):
        x=225+i*280
        bbox=d.textbbox((0,0),name,font=small);w=bbox[2]-bbox[0]
        d.text((x-w/2,y),name,font=small,fill=white)
d.text((26,1470),'Medic W17 baseline uses the shared Trooper; Scout keeps its existing model.',font=small,fill=muted)
d.text((26,1503),'New heads: Meshy previews.  Gear: Blender.  Assets staged only; class wiring unchanged.',font=small,fill=muted)
sheet=sheet.crop((0,0,2100,1545))
sheet.save(root/'2026-11-07-soldier-art-before-after.jpg',quality=92,subsampling=0)
print(root/'2026-11-07-soldier-art-before-after.jpg')
print(root/'2026-11-07-soldier-lineup.jpg')
