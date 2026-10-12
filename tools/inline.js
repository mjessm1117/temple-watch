// Builds dist/temple-watch.html: the whole game in one file (for tests and offline play).
const fs = require('fs'), path = require('path');
const pub = path.join(__dirname, '..', 'public');
let html = fs.readFileSync(path.join(pub, 'index.html'), 'utf8');
html = html.replace(/<link rel="stylesheet" href="(css\/[^"]+)">/g, (_, f) => `<style>\n${fs.readFileSync(path.join(pub, f), 'utf8')}</style>`);
html = html.replace(/<script src="(js\/[^"]+)"><\/script>\n?/g, (_, f) => `<script>\n${fs.readFileSync(path.join(pub, f), 'utf8')}</script>\n`);
fs.mkdirSync(path.join(__dirname, '..', 'dist'), { recursive: true });
fs.writeFileSync(path.join(__dirname, '..', 'dist', 'temple-watch.html'), html);
console.log('Built dist/temple-watch.html');
