#!/usr/bin/env node
// Local, subpath, phone-sized first and repeat visit measurement.
const { chromium } = require('/home/jess/hive/node_modules/playwright-core');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const repo = path.resolve(__dirname, '../..');
const baseline = process.argv.includes('--baseline');
const buildDir = baseline ? '/tmp/web3-baseline-export' : path.join(repo, 'build/web');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'temple-web-measure-'));
fs.symlinkSync(buildDir, path.join(temp, 'temple-watch-play'), 'dir');
const port = 18647;
const url = `http://127.0.0.1:${port}/temple-watch-play/`;
const server = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1'], {cwd: temp, stdio: 'ignore'});
const chrome = path.join(os.homedir(), '.cache/ms-playwright/chromium_headless_shell-1248/chrome-headless-shell-linux64/chrome-headless-shell');
const shots = path.join(repo, 'docs/godot/shots');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
(async () => {
  await sleep(500);
  const browser = await chromium.launch({executablePath: chrome});
  const context = await browser.newContext({viewport: {width: 844, height: 390}, hasTouch: true, isMobile: true, deviceScaleFactor: 1});
  const page = await context.newPage();
  const errors = [];
  const responses = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('response', response => {
    const name = response.url().split('/').pop();
    if (['index.pck', 'index.wasm', 'index.js'].includes(name)) responses.push({name, serviceWorker: response.fromServiceWorker(), status: response.status()});
  });
  const start = Date.now();
  await page.goto(url, {waitUntil: 'domcontentloaded'});
  if (!baseline) {
    await page.waitForFunction(() => Number.parseInt(document.querySelector('#percent')?.textContent || '0') >= 10, null, {timeout: 30000}).catch(() => {});
    if (await page.locator('#loading').isVisible()) await page.screenshot({path: path.join(shots, 'mobile-web3-loading.png')});
  }
  await page.locator(baseline ? '#status' : '#loading').waitFor({state: baseline ? 'detached' : 'hidden', timeout: 240000});
  await page.waitForTimeout(1500);
  await page.screenshot({path: baseline ? '/tmp/web3-baseline-title.png' : path.join(shots, 'mobile-web3-title.png')});
  const titleMs = Date.now() - start;
  const resources = await page.evaluate(() => performance.getEntriesByType('resource').filter(e => /index\.(pck|wasm|js)$/.test(e.name)).map(e => ({name: e.name.split('/').pop(), startMs: Math.round(e.startTime), endMs: Math.round(e.responseEnd), transferBytes: e.transferSize, encodedBytes: e.encodedBodySize})));
  const cache = await page.evaluate(async () => {
    const keys = await caches.keys();
    return Promise.all(keys.map(async name => ({name, pck: Boolean(await (await caches.open(name)).match('index.pck'))})));
  });
  const first = {titleMs, responses: responses.slice(), resources, cache, errors: errors.slice()};
  if (process.argv.includes('--visual') && !baseline) {
    await page.mouse.click(310, 184); // Direct Rescue on the title screen.
    await page.waitForTimeout(5000);
    await page.screenshot({path: '/tmp/web3-battle.png'});
  }
  if (process.argv.includes('--home') && !baseline) {
    await page.mouse.click(50, 184); // Start the campaign.
    await page.waitForTimeout(4000);
    await page.mouse.click(770, 34); // Close the opening intelligence overlay.
    await page.waitForTimeout(1000);
    await page.mouse.click(420, 290); // Reveal the opening Council transmission.
    await page.mouse.move(600, 250);
    await page.mouse.wheel(0, 520);
    await page.waitForTimeout(1000);
    await page.screenshot({path: '/tmp/web3-story-choices.png'});
    await page.mouse.click(200, 185); // Record the first opening decision.
    await page.waitForTimeout(500);
    for (let i = 0; i < 4; i++) {
      await page.mouse.click(420, 290);
      await page.mouse.move(600, 250);
      await page.mouse.wheel(0, 520);
      await page.waitForTimeout(500);
      await page.mouse.click(200, 185);
      await page.waitForTimeout(700);
    }
    await page.screenshot({path: '/tmp/web3-home-check.png'});
  }
  if (baseline) {
    console.log(JSON.stringify({first, url}, null, 2));
    await browser.close();
    if (errors.length) process.exitCode = 1;
    return;
  }
  responses.length = 0;
  const repeatPck = page.waitForResponse(response => response.url().endsWith('/index.pck'), {timeout: 30000}).catch(() => {});
  await page.goto(url, {waitUntil: 'domcontentloaded'});
  await repeatPck;
  await page.waitForTimeout(1000);
  const repeat = {responses: responses.slice(), errors: errors.slice()};
  console.log(JSON.stringify({first, repeat, url}, null, 2));
  await browser.close();
  if (errors.length) process.exitCode = 1;
})().catch(error => {console.error(error); process.exitCode = 1;}).finally(() => server.kill());
