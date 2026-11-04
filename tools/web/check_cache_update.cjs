#!/usr/bin/env node
const { chromium } = require('/home/jess/hive/node_modules/playwright-core');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const repo = path.resolve(__dirname, '../..');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'temple-web-update-'));
const site = path.join(root, 'temple-watch-play');
fs.cpSync(path.join(repo, 'build/web'), site, {recursive: true});
const server = spawn('python3', ['-m', 'http.server', '18648', '--bind', '127.0.0.1'], {cwd: root});
let requests = '';
server.stderr.on('data', data => requests += data.toString());
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
let browser;
(async () => {
  await sleep(500);
  const chrome = path.join(os.homedir(), '.cache/ms-playwright/chromium_headless_shell-1248/chrome-headless-shell-linux64/chrome-headless-shell');
  browser = await chromium.launch({executablePath: chrome});
  const context = await browser.newContext({viewport: {width: 844, height: 390}, hasTouch: true, isMobile: true});
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  const url = 'http://127.0.0.1:18648/temple-watch-play/';
  await page.goto(url, {waitUntil: 'domcontentloaded'});
  await page.locator('#loading').waitFor({state: 'hidden', timeout: 60000});
  const before = await page.evaluate(async () => (await caches.keys()).find(name => name.includes('web3-')));
  if (!before) throw new Error('Initial cache missing');
  const initialPckNetworkRequests = (requests.match(/GET \/temple-watch-play\/index\.pck /g) || []).length;
  const workerPath = path.join(site, 'index.service.worker.js');
  const htmlPath = path.join(site, 'index.html');
  const pckPath = path.join(site, 'index.pck');
  const updatedPckBytes = fs.statSync(pckPath).size + 1;
  fs.appendFileSync(pckPath, Buffer.from([0])); // Simulate a changed pack.
  fs.appendFileSync(htmlPath, '\n<!-- cache update test -->\n');
  const worker = fs.readFileSync(workerPath, 'utf8').replace(/const CACHE_VERSION = '[^']+';/, "const CACHE_VERSION = 'web3-update-test';");
  fs.writeFileSync(workerPath, worker);
  await page.reload({waitUntil: 'domcontentloaded'}).catch(() => {});
  await page.waitForFunction(async () => (await caches.keys()).some(name => name.endsWith('web3-update-test')), null, {timeout: 60000});
  await page.waitForFunction(async (expectedBytes) => {
    const name = (await caches.keys()).find(name => name.endsWith('web3-update-test'));
    if (!name) return false;
    const response = await (await caches.open(name)).match('index.pck');
    return response && Number(response.headers.get('content-length')) === expectedBytes;
  }, updatedPckBytes, {timeout: 60000});
  await sleep(2000);
  let after;
  for (let attempt = 0; attempt < 20; attempt++) {
    try {
      after = await page.evaluate(async () => await caches.keys());
      if (after.some(name => name.endsWith('web3-update-test'))) break;
    } catch (_) { /* The old page reloads when the new worker claims it. */ }
    await sleep(500);
  }
  const cachedPckBytes = await page.evaluate(async () => {
    const name = (await caches.keys()).find(name => name.endsWith('web3-update-test'));
    const response = await (await caches.open(name)).match('index.pck');
    return Number(response.headers.get('content-length'));
  });
  for (let attempt = 0; attempt < 20 && (requests.match(/GET \/temple-watch-play\/index\.pck /g) || []).length < 2; attempt++) await sleep(100);
  const pckNetworkRequests = (requests.match(/GET \/temple-watch-play\/index\.pck /g) || []).length;
  console.log(JSON.stringify({before, after, updatedPckBytes, cachedPckBytes, initialPckNetworkRequests, pckNetworkRequests,
    pckServerLines: requests.split('\n').filter(line => line.includes('index.pck')), errors}, null, 2));
  if (errors.length || cachedPckBytes !== updatedPckBytes || pckNetworkRequests < 2) process.exitCode = 1;
})().catch(error => {console.error(error); process.exitCode = 1;}).finally(async () => {if (browser) await browser.close(); server.kill();});
