#!/usr/bin/env node
// Exported Web build, real CSS-point HUD measurements, and touch-only battle flow.
const {chromium} = require('/home/jess/hive/node_modules/playwright-core');
const {spawn, execFileSync} = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const repo = path.resolve(__dirname, '../..');
const logs = process.argv.find(x => x.startsWith('--output-dir='))?.slice(13) || '/home/jess/projects/tw-logs/w28/phone-hud';
const baseline = process.argv.includes('--baseline');
const noBuild = process.argv.includes('--no-build');
const only = process.argv.find(x => x.startsWith('--case='))?.slice(7);
const port = Number(process.argv.find(x => x.startsWith('--port='))?.slice(7) || process.env.W28D_PORT || 18648);
fs.mkdirSync(logs, {recursive: true});
if (!baseline && !noBuild) execFileSync(path.join(repo, 'tools/web/export_web.sh'),
  {cwd: repo, stdio: 'inherit', timeout: 600000, env: {...process.env, TMPDIR: logs}});
const server = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1'],
  {cwd: path.join(repo, 'build/web'), stdio: 'ignore'});
const cache = path.join(process.env.HOME, '.cache/ms-playwright');
const chromeDir = fs.readdirSync(cache).filter(x => x.startsWith('chromium_headless_shell-')).sort().pop();
const chrome = path.join(cache, chromeDir, 'chrome-headless-shell-linux64/chrome-headless-shell');
const cases = [
  {name: '956x440', width: 956, height: 440},
  {name: '844x390', width: 844, height: 390},
  {name: '390x844', width: 390, height: 844},
  {name: '956x440-inset', width: 956, height: 440, safe: {left: 59, bottom: 34}}
];
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
function browserChildren() {
  return execFileSync('ps', ['-eo', 'pid=,ppid=,comm='], {encoding: 'utf8'}).split('\n')
    .map(line => line.trim().split(/\s+/))
    .filter(parts => Number(parts[1]) === process.pid && parts[2]?.startsWith('chrome-headless'))
    .map(parts => parts[0]);
}
async function closeBrowser(browser) {
  await Promise.race([browser.close().catch(() => {}), wait(5000)]);
  const children = browserChildren();
  if (children.length) execFileSync('python3', ['-c',
    'import psutil,sys\nfor pid in map(int,sys.argv[1:]):\n try:\n  p=psutil.Process(pid)\n  for child in reversed(p.children(recursive=True)): child.kill()\n  p.kill()\n except psutil.NoSuchProcess: pass', ...children]);
}
const intersects = (a,b) => Math.min(a.x+a.w,b.x+b.w)-Math.max(a.x,b.x) > 0.5 &&
  Math.min(a.y+a.h,b.y+b.h)-Math.max(a.y,b.y) > 0.5;
const gap = (a,b) => Math.hypot(
  Math.max(0, a.x-b.x-b.w, b.x-a.x-a.w),
  Math.max(0, a.y-b.y-b.h, b.y-a.y-a.h));
const contained = (a,b) => a.x >= b.x && a.y >= b.y && a.x+a.w <= b.x+b.w && a.y+a.h <= b.y+b.h;
async function state(page) {
  return page.evaluate(() => {
    const data = window.tw_hud_rects?.();
    if (!data) return null;
    const canvas = document.getElementById('canvas').getBoundingClientRect();
    const sx = canvas.width / data.root[0], sy = canvas.height / data.root[1];
    const convert = row => ({...row, x: canvas.x + row.x*sx, y: canvas.y + row.y*sy, w: row.w*sx, h: row.h*sy});
    return {...data, controls: data.controls.map(convert), labels: (data.labels || []).map(convert),
      viewport: {x: canvas.x, y: canvas.y, w: canvas.width, h: canvas.height},
      safeCSS: data.safe.map((v,i) => v*(i%2 ? sy : sx))};
  });
}
function control(data, name) { return data.controls.find(item => item.name === name || item.ability === name); }
async function tap(page, item) {
  if (!item) throw Error('Missing control to tap');
  await page.touchscreen.tap(item.x + item.w/2, item.y + item.h/2);
  await wait(900);
}
async function waitHud(page, predicate, timeout = 2500, arg = null) {
  try {
    await page.waitForFunction(predicate, arg, {timeout});
    return true;
  } catch { return false; }
}
async function startMission1(page) {
  await page.goto(`http://127.0.0.1:${port}/`, {waitUntil: 'domcontentloaded'});
  await page.locator('#loading').waitFor({state: 'hidden', timeout: 240000});
  await page.screenshot({path: path.join(logs, 'after-title-956x440.png')});
  await page.touchscreen.tap(52, 130); // Story difficulty keeps all four turn checks alive.
  await page.touchscreen.tap(53, 190); // START.
  await wait(3000);
  await page.touchscreen.tap(570, 405); // SKIP STORY.
  await wait(3000);
  await page.touchscreen.tap(775, 180); // Briefing SKIP.
  await wait(3000);
  await page.touchscreen.tap(180, 235); // "As briefed" opening choice.
  await wait(4000);
  for (let attempt = 0; attempt < 3; attempt++) {
    await page.touchscreen.tap(880, 385); // DEPLOY squad into Temple Outer Gate.
    await wait(4000);
    if (await page.evaluate(() => Boolean(window.tw_hud_rects?.()))) break;
  }
  await page.waitForFunction(() => window.tw_hud_rects?.()?.controls?.some(c => c.name === 'PhoneEndTurn'), null, {timeout: 120000});
  await page.waitForFunction(() => {
    const hud = window.tw_hud_rects?.();
    return hud && hud.phase === 'player' && !hud.cinematic && !hud.attackPending &&
      !hud.playingEnemyEvents && !hud.inputBusy && !hud.phaseBannerVisible && !hud.phasePlateVisible;
  }, null, {timeout: 45000});
  // The opening turn notice can outlive the game-state banner by a frame.
  await wait(2000);
  const initial = await state(page);
  if (initial.missionFamily !== 'defend' || !initial.objective.includes('HOLD'))
    throw Error(`Mission 1 route failed: ${initial.missionFamily}, ${initial.objective}`);
}
async function runCase(page, item, errors) {
  console.log(`CHECK ${item.name}: geometry`);
  const current = page.viewportSize();
  if (current.width !== item.width || current.height !== item.height) await page.setViewportSize({width: item.width, height: item.height});
  if (item.safe) await page.evaluate(safe => {window.templeTestSafeArea = safe; window.tw_refresh_viewport?.();}, item.safe);
  await wait(item.safe || current.width !== item.width || current.height !== item.height ? 2000 : 500);
  const shot = path.join(logs, `${baseline ? 'before' : 'after'}-${item.name}.png`);
  await page.screenshot({path: shot, scale: 'css', timeout: 120000});
  if (baseline) return {name: item.name, shot, errors};
  let data = await state(page);
  if (!data) throw Error(`${item.name}: no Godot HUD data`);
  const measuredControls = data.controls.length;
  console.log(`RECTS ${item.name} ${JSON.stringify(data.controls.map(c => [c.name, c.ability, c.x, c.y, c.w, c.h]))}`);
  const failures = [];
  const safe = {x: data.viewport.x + data.safeCSS[0], y: data.viewport.y + data.safeCSS[1],
    w: data.viewport.w - data.safeCSS[0] - data.safeCSS[2],
    h: data.viewport.h - data.safeCSS[1] - data.safeCSS[3]};
  let minimum = Infinity;
  for (const c of data.controls) {
    minimum = Math.min(minimum, c.w, c.h);
    if (c.w < 43.5 || c.h < 43.5) failures.push(`${c.name} ${c.w.toFixed(1)}×${c.h.toFixed(1)}pt`);
    if (c.clipped) failures.push(`${c.name} clipped by scroll area`);
    if (!contained(c, safe)) failures.push(`${c.name} outside safe area`);
  }
  for (let i=0; i<data.controls.length; i++) for (let j=i+1; j<data.controls.length; j++) {
    const a = data.controls[i], b = data.controls[j];
    if (intersects(a,b)) failures.push(`${a.name}/${b.name} overlap`);
    else if (gap(a,b) < 7.5) failures.push(`${a.name}/${b.name} gap ${gap(a,b).toFixed(1)}pt`);
  }
  for (const label of data.labels) {
    if (!contained(label, safe)) failures.push(`${label.name} outside safe area`);
    for (const c of data.controls) if (intersects(label,c)) failures.push(`${label.name}/${c.name} overlap`);
  }
  for (let i=0; i<data.labels.length; i++) for (let j=i+1; j<data.labels.length; j++) {
    if (intersects(data.labels[i], data.labels[j])) failures.push(`${data.labels[i].name}/${data.labels[j].name} overlap`);
  }
  const selected = data.selected;
  console.log(`CHECK ${item.name}: select ${selected}`);
  for (let attempt = 0; attempt < 3; attempt++) {
    await tap(page, control(data, 'UnitNext'));
    if (await waitHud(page, old => window.tw_hud_rects?.()?.selected !== old, 1800, selected)) break;
    data = await state(page);
  }
  data = await state(page);
  console.log(`SELECT ${item.name} ${selected}->${data.selected}`);
  if (data.selected === selected) failures.push('select unit did not respond');
  console.log(`CHECK ${item.name}: move`);
  const moveTouches = data.moveTouches;
  await tap(page, control(data, 'move'));
  await waitHud(page, prior => window.tw_hud_rects?.()?.moveTouches > prior, 1800, moveTouches);
  data = await state(page);
  console.log(`MOVE ${item.name} ${data.action} touches ${moveTouches}->${data.moveTouches}`);
  if (data.action !== 'move' || data.moveTouches <= moveTouches) failures.push('Move did not respond');
  const turn = data.turn;
  console.log(`CHECK ${item.name}: end turn ${turn}`);
  for (let attempt = 0; attempt < 3; attempt++) {
    await tap(page, control(data, 'PhoneEndTurn'));
    const responded = await waitHud(page, oldTurn => {
      const s = window.tw_hud_rects?.();
      return s && (s.endConfirm || s.endTurnArmed || s.playingEnemyEvents || s.phase !== 'player' || s.turn > oldTurn);
    }, 1800, turn);
    data = await state(page);
    console.log(`END ${item.name} attempt ${attempt+1} ${JSON.stringify({confirm:data.endConfirm,armed:data.endTurnArmed,phase:data.phase,turn:data.turn})}`);
    if (responded || data.endConfirm || data.endTurnArmed || data.playingEnemyEvents || data.phase !== 'player' || data.turn > turn) break;
  }
  const confirm = data.endConfirm || data.endTurnArmed;
  const firstResponded = confirm || data.playingEnemyEvents || data.phase !== 'player' || data.turn > turn;
  if (!firstResponded) failures.push('End Turn first tap did not respond');
  if (confirm && data.turn === turn && data.phase === 'player') {
    await tap(page, control(data, 'PhoneEndTurn'));
  }
  await page.waitForFunction(oldTurn => {
    const current = window.tw_hud_rects?.();
    return current && (current.playingEnemyEvents || current.phase !== 'player' || current.turn > oldTurn);
  }, turn, {timeout: 15000}).catch(() => {});
  data = await state(page);
  const endResponded = data.playingEnemyEvents || data.phase !== 'player' || data.turn > turn;
  console.log(`CHECK ${item.name}: done ${data.phase}/${data.turn}`);
  if (!endResponded) failures.push('End Turn did not start enemy phase');
  failures.push(...errors.map(e => `page: ${e}`));
  return {name: item.name, shot, controls: measuredControls, minimumPt: Number(minimum.toFixed(1)),
    safe, selectedChanged: data.selected !== selected, moveAction: data.action, turnBefore: turn, turnAfter: data.turn, phaseAfter: data.phase, confirm, endResponded, failures};
}
(async () => {
  await wait(600);
  const results = [];
  for (const item of cases.filter(x => !only || x.name === only).slice(0, baseline && !only ? 1 : undefined)) {
    const browser = await chromium.launch({executablePath: chrome, args: ['--use-gl=angle', '--use-angle=swiftshader']});
    try {
      const context = await browser.newContext({viewport: {width: 956, height: 440},
        isMobile: true, hasTouch: true, deviceScaleFactor: 3});
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', error => errors.push(error.message));
      page.on('console', message => {if (message.type() === 'error') errors.push(message.text());});
      await startMission1(page);
      const result = await runCase(page, item, errors);
      results.push(result);
      console.log(JSON.stringify(result));
    } catch (error) {
      const result = {name: item.name, failures: [String(error)]};
      results.push(result);
      console.error(JSON.stringify(result));
    } finally {
      fs.writeFileSync(path.join(logs, `${baseline ? 'before' : 'after'}-measurements.json`), JSON.stringify(results, null, 2));
      await closeBrowser(browser);
    }
  }
  if (results.some(r => r.failures?.length)) process.exitCode = 1;
})().catch(error => {console.error(error); process.exitCode = 1;}).finally(() => server.kill());
