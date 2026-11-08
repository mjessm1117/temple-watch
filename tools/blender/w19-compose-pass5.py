"""Compose pass 3/5 fit review and recaptured lineup/pose sheets."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

root=Path('/home/jess/projects/tw-logs/w19')
src=root/'art'
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
title=ImageFont.truetype(font,25);small=ImageFont.truetype(font,18)
bg=(22,29,39);white=(235,239,245);muted=(170,185,202)
names=('SNIPER','HEAVY','TECH','OFFICER','MEDIC','DROID','SCOUT')

def labels(im):
    d=ImageDraw.Draw(im)
    for i,name in enumerate(names):
        x=146+i*91.5
        w=d.textbbox((0,0),name,font=small)[2]
        d.text((x-w/2,237),name,font=small,fill=white,stroke_width=2,stroke_fill=(20,25,33))
    return im

labels(Image.open(src/'w19-battle.jpg').convert('RGB')).save(root/'2026-11-07-soldier-lineup.jpg',quality=93,subsampling=0)
poses=Image.new('RGB',(1800,1260),bg);d=ImageDraw.Draw(poses)
for i,clip in enumerate(('idle','run','shoot')):
    y=i*420;d.text((20,y+3),clip.upper(),font=title,fill=white)
    poses.paste(Image.open(src/f'w19-pose-{clip}.jpg').convert('RGB'),(0,y+30))
poses.save(src/'w19-pose-review.jpg',quality=92,subsampling=0)

sheet=Image.new('RGB',(1688,1750),bg);d=ImageDraw.Draw(sheet)
d.text((24,10),'W19 SOLDIER ART PASS 5  /  SNIPER + MEDIC',font=title,fill=white)
for i,(tag,suffix) in enumerate((('PASS 3','-v3'),('PASS 5',''))):
    x=i*844
    d.text((x+24,54),tag+'  •  844 × 390 BATTLE DISTANCE',font=small,fill=white)
    grey=Image.open(src/f'w19-grey-battle{suffix}.jpg').convert('RGB')
    sheet.paste(grey,(x,82))
    d.text((x+24,477),'COLOUR  /  IDLE',font=small,fill=white)
    colour=labels(Image.open(src/f'w19-battle{suffix}.jpg').convert('RGB'))
    sheet.paste(colour,(x,505))
    d.text((x+24,900),'ARMORY  /  SNIPER                         MEDIC',font=small,fill=white)
    armory=Image.open(src/f'w19-armory{suffix}.jpg').convert('RGB')
    for j,left in enumerate((0,1200)):
        crop=armory.crop((left,0,left+300,390)).resize((400,520),Image.Resampling.LANCZOS)
        sheet.paste(crop,(x+j*420,935))
    d.text((x+85,1464),'SNIPER',font=small,fill=white)
    d.text((x+520,1464),'MEDIC',font=small,fill=white)
d.text((24,1520),'Grey silhouette uses flat materials. Sniper hood/cloak and Medic hip kit are the only changed classes.',font=small,fill=muted)
sheet=sheet.crop((0,0,1688,1560))
sheet.save(root/'2026-11-07-soldier-art-pass5.jpg',quality=93,subsampling=0)
