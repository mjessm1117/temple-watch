#!/usr/bin/env node
// Count WebGL draw submissions in the same portrait browser for base and lane E.
const {chromium} = require('/home/jess/hive/node_modules/playwright-core');
const {spawn} = require('node:child_process');
const path = require('node:path');
const os = require('node:os');
const base = '/home/jess/projects/tw-w27/integrate/build/web';
const after = process.env.W28E_BUILD_DIR || path.resolve(__dirname, '../../build/web');
const chrome = path.join(os.homedir(), '.cache/ms-playwright/chromium_headless_shell-1254/chrome-headless-shell-linux64/chrome-headless-shell');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const probe = () => {
  window.w28eDraws = {count: 0, frames: []};
  for (const name of ['drawArrays', 'drawElements', 'drawArraysInstanced', 'drawElementsInstanced']) {
    const old = WebGL2RenderingContext.prototype[name];
    WebGL2RenderingContext.prototype[name] = function(...args) {
      window.w28eDraws.count++;
      return old.apply(this, args);
    };
  }
  const oldFrame = window.requestAnimationFrame;
  window.requestAnimationFrame = function(callback) {
    return oldFrame.call(window, time => {
      const draws = window.w28eDraws;
      draws.frames.push(draws.count);
      if (draws.frames.length > 500) draws.frames.shift();
      draws.count = 0;
      callback(time);
    });
  };
};

async function measure(browser, dir, port) {
  const server = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1'], {cwd: dir, stdio: 'ignore'});
  const context = await browser.newContext({viewport: {width: 390, height: 844}, isMobile: true, hasTouch: true, deviceScaleFactor: 3});
  try {
    await context.addInitScript(probe);
    const page = await context.newPage();
    await sleep(500);
    await page.goto(`http://127.0.0.1:${port}/`, {waitUntil: 'domcontentloaded'});
    await page.locator('#loading').waitFor({state: 'hidden', timeout: 240000});
    await page.touchscreen.tap(90, 360);
    await sleep(10000);
    const frames = await page.evaluate(() => window.w28eDraws.frames.slice(-100));
    if (frames.length < 20) throw new Error(`Only ${frames.length} frames from ${dir}`);
    return {peak: Math.max(...frames), median: frames.slice().sort((a,b)=>a-b)[Math.floor(frames.length/2)], frames: frames.length};
  } finally {await context.close(); server.kill();}
}

(async () => {
  const browser = await chromium.launch({executablePath: chrome});
  try {
    const before = await measure(browser, base, 18660);
    const final = await measure(browser, after, 18661);
    console.log(JSON.stringify({before, after: final, rise: final.peak - before.peak}));
    if (final.peak - before.peak > 5) process.exitCode = 1;
  } finally {await browser.close();}
})().catch(error => {console.error(error); process.exitCode = 1;});
