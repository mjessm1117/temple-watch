import sharp from 'sharp';

const names = ['trooper', 'scout', 'sniper', 'heavy', 'tech', 'droid', 'officer'];
const accent = {sniper: '#4c6133', heavy: '#b3541a', tech: '#1a737a', droid: '#cca826', officer: '#8c1a1f'};
const portraits = 'art/w17-2/portrait-';
const shots = 'docs/godot/shots/';
const label = (value, width, height, size = 22) => Buffer.from(`<svg width="${width}" height="${height}"><text x="4" y="${size + 3}" font-family="sans-serif" font-size="${size}" font-weight="bold" fill="#f2e9d7">${value}</text></svg>`);
const background = '#182330';

{
  const parts = [{input: label('TEMPLE WATCH / W17 ART FIX 5', 1600, 46, 30), left: 20, top: 8}];
  for (let i = 0; i < names.length; i++) {
    const name = names[i], x = 15 + 300 * i;
    parts.push({input: label(name.toUpperCase(), 280, 38), left: x, top: 53});
    if (accent[name]) parts.push({input: Buffer.from(`<svg width="278" height="9"><rect width="278" height="9" fill="${accent[name]}"/></svg>`), left: x, top: 88});
    for (const [view, y] of [['front', 105], ['three-quarter', 430]]) {
      const image = await sharp(`${portraits}${name}-${view}.png`).extract({left: 0, top: 45, width: 384, height: 420}).resize(285, 312, {fit: 'contain', background}).png().toBuffer();
      parts.push({input: image, left: x, top: y});
    }
  }
  await sharp({create: {width: 2115, height: 755, channels: 4, background}}).composite(parts).png().toFile(`${shots}w17-art5-classes.png`);
}

{
  const kinds = names.slice(2), parts = [];
  for (let i = 0; i < kinds.length; i++) {
    const name = kinds[i], x = 12 + 390 * i;
    parts.push({input: label(`${name.toUpperCase()} / SHOOT`, 370, 38, 23), left: x, top: 12});
    parts.push({input: await sharp(`${portraits}${name}-three-quarter-shoot.png`).png().toBuffer(), left: x, top: 52});
  }
  await sharp({create: {width: 1960, height: 545, channels: 4, background}}).composite(parts).png().toFile(`${shots}w17-art5-shoot.png`);
}

{
  const parts = [];
  for (let i = 0; i < names.length; i++) {
    const name = names[i], x = 9 + i * 112;
    const top = name === 'heavy' ? 58 : 112;
    const height = name === 'heavy' ? 322 : 268;
    const image = await sharp(`${portraits}${name}-front.png`).extract({left: 87, top, width: 210, height}).resize({height: 64}).png().toBuffer();
    parts.push({input: image, left: x + 29, top: 9});
    parts.push({input: label(name.toUpperCase(), 108, 20, 13), left: x, top: 82});
    if (accent[name]) parts.push({input: Buffer.from(`<svg width="103" height="5"><rect width="103" height="5" fill="${accent[name]}"/></svg>`), left: x, top: 76});
  }
  await sharp({create: {width: 795, height: 105, channels: 4, background}}).composite(parts).png().toFile(`${shots}w17-art5-small.png`);
}
