#!/usr/bin/env node
// Touch the exported game through Chromium at phone sizes and require a live move.
const { chromium } = require('/home/jess/hive/node_modules/playwright-core');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const repo = path.resolve(__dirname, '../..');
const output = '/home/jess/projects/tw-logs/w28/phone-move';
const buildDir = process.env.W28E_BUILD_DIR || path.join(repo, 'build/web');
const port = 18659;
const server = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1'], {
  cwd: buildDir, stdio: 'ignore'
});
const executablePath = path.join(os.homedir(), '.cache/ms-playwright/chromium_headless_shell-1254/chrome-headless-shell-linux64/chrome-headless-shell');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function runCase(browser, width, height, menuPoint) {
  const context = await browser.newContext({viewport: {width, height}, isMobile: true, hasTouch: true, deviceScaleFactor: 3});
  const page = await context.newPage();
  page.setDefaultTimeout(120000);
  const messages = [];
  const errors = [];
  page.on('console', message => messages.push(message.text()));
  page.on('pageerror', error => errors.push(error.message));
  await page.goto(`http://127.0.0.1:${port}/`, {waitUntil: 'domcontentloaded'});
  await page.locator('#loading').waitFor({state: 'hidden', timeout: 240000});
  await sleep(1200);
  await page.screenshot({path: path.join(output, `w28e-title-${width}x${height}.png`)});
  await page.touchscreen.tap(menuPoint.x, menuPoint.y);
  await sleep(2000);
  await page.screenshot({path: path.join(output, `w28e-open-${width}x${height}.png`)});
  const previewPoints = [];
  for (const y of [Math.round(height * 0.38), Math.round(height * 0.46), Math.round(height * 0.54), Math.round(height * 0.62)]) {
    for (const x of [0.28, 0.38, 0.48, 0.58, 0.68].map(f => Math.round(width * f))) previewPoints.push({x, y});
  }
  let point = null;
  for (const candidate of previewPoints) {
    const before = messages.length;
    await page.touchscreen.tap(candidate.x, candidate.y);
    await sleep(160);
    if (messages.slice(before).some(line => line.includes('W28E_MOVE_PREVIEW'))) {point = candidate; break;}
  }
  if (!point) throw new Error(`${width}x${height}: no touch preview; logs=${messages.slice(-15).join(' | ')}`);
  await sleep(500);
  const previewPath = path.join(output, `w28e-preview-${width}x${height}.png`);
  await page.screenshot({path: previewPath});
  const beforeMove = messages.length;
  await page.touchscreen.tap(point.x, point.y);
  await sleep(2200);
  const move = messages.slice(beforeMove).find(line => line.includes('W28E_MOVE_COMMITTED'));
  if (!move) throw new Error(`${width}x${height}: second touch did not move; point=${JSON.stringify(point)} logs=${messages.slice(-15).join(' | ')}`);
  const afterPath = path.join(output, `w28e-after-${width}x${height}.png`);
  await page.screenshot({path: afterPath});
  if (errors.length) throw new Error(`${width}x${height}: page errors: ${errors.join(' | ')}`);
  console.log(JSON.stringify({size: `${width}x${height}`, touch: point, move, previewPath, afterPath}));
  await context.close();
}

(async () => {
  fs.mkdirSync(output, {recursive: true});
  await sleep(600);
  const browser = await chromium.launch({executablePath});
  try {
    await runCase(browser, 956, 440, {x: 450, y: 184});
    await runCase(browser, 844, 390, {x: 450, y: 184});
    await runCase(browser, 390, 844, {x: 90, y: 360});
  } finally { await browser.close(); }
})().catch(error => {console.error(error); process.exitCode = 1;}).finally(() => server.kill());
