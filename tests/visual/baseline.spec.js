const { test, expect } = require('@playwright/test');

test.beforeEach(async ({ page }) => {
  await page.addInitScript(() => {
    let seed = 7919;
    Math.random = () => ((seed = (seed * 48271) % 2147483647) / 2147483647);
    localStorage.setItem('tw_view', '2d');
  });
  await page.goto('/');
  await expect(page.locator('#modal .box')).toBeVisible();
  await page.evaluate(() => document.fonts.ready);
});

async function shot(page, name) {
  await expect(page).toHaveScreenshot(`${name}.png`, {
    animations: 'disabled',
    caret: 'hide',
    maxDiffPixelRatio: 0.02,
    timeout: 20_000,
  });
}

test('title screen', async ({ page }) => {
  await shot(page, 'title');
});

test('temple map screen', async ({ page }) => {
  await page.locator('[data-d="normal"]').click();
  await page.evaluate(() => _baseScreen());
  await expect(page.locator('.tmap')).toBeVisible();
  await shot(page, 'map');
});

test('battle screen', async ({ page }) => {
  await page.locator('[data-d="normal"]').click();
  await page.evaluate(() => {
    const squad = C.roster.slice(0, 4).map(battleUnit);
    startMission(C.options[0].mission, squad, { map: 0, diff: 'normal' });
    document.querySelector('#modal').hidden = true;
    document.body.classList.remove('v3d');
    document.body.classList.add('rotok');
    render();
  });
  await expect(page.locator('#board')).toBeVisible();
  await shot(page, 'battle');
});

test('armory screen', async ({ page }) => {
  await page.locator('[data-d="normal"]').click();
  await page.evaluate(() => { setRoom('armory'); _baseScreen(); });
  await expect(page.locator('.gear')).toBeVisible();
  await shot(page, 'armory');
});

test('campaign squad screen', async ({ page }) => {
  await page.locator('[data-d="normal"]').click();
  await page.evaluate(() => _baseScreen());
  await page.locator('[data-act="squad:0"]').click();
  await expect(page.locator('.sqbox')).toBeVisible();
  await shot(page, 'campaign');
});
