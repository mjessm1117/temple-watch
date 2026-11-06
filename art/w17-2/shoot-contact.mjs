import sharp from 'sharp';

const kinds = ['sniper', 'heavy', 'tech', 'droid', 'officer'];
const parts = [];
for (let i = 0; i < kinds.length; i++) {
  const name = kinds[i], x = 20 + i * 390;
  parts.push({input: Buffer.from(`<svg width="370" height="36"><text x="0" y="27" font-family="sans-serif" font-weight="bold" font-size="24" fill="#f2e9d7">${name.toUpperCase()} / SHOOT</text></svg>`), left: x, top: 20});
  parts.push({input: await sharp(`art/w17-2/portrait-${name}-three-quarter-shoot.png`).png().toBuffer(), left: x, top: 65});
}
await sharp({create: {width: 1970, height: 560, channels: 4, background: '#182330'}})
  .composite(parts).png().toFile('docs/godot/shots/w17-art3-shoot-poses.png');
