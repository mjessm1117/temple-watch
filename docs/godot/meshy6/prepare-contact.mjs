// Adapt 320 px Blender sheets to the existing contact-sheet tool's 512 px layout.
import fs from 'node:fs';
import sharp from 'sharp';
const root='docs/godot/meshy6';
const scores=JSON.parse(fs.readFileSync(`${root}/scores.json`));
fs.mkdirSync(`${root}/contact-source`,{recursive:true});
for(const [asset,letters] of Object.entries(scores)){
  for(const letter of Object.keys(letters)){
    await sharp(`${root}/${asset}.${letter}.preview.png`).resize(1024,1024).png()
      .toFile(`${root}/contact-source/${asset}.${letter}.preview.png`);
  }
}
