// Optional preload for diagnosing slow Web harness transitions; no game changes.
const {chromium} = require('/home/jess/hive/node_modules/playwright-core');
const launch = chromium.launch.bind(chromium);
chromium.launch = async (...args) => {
  const browser = await launch(...args);
  const newContext = browser.newContext.bind(browser);
  browser.newContext = async (...contextArgs) => {
    const context = await newContext(...contextArgs);
    const newPage = context.newPage.bind(context);
    context.newPage = async (...pageArgs) => {
      const page = await newPage(...pageArgs);
      let last = '';
      const timer = setInterval(async () => {
        if (page.isClosed()) return;
        try {
          const hud = await page.evaluate(() => window.tw_hud_rects?.());
          if (hud) {
            const now = JSON.stringify({phase: hud.phase, turn: hud.turn,
            cinematic: hud.cinematic, busy: hud.inputBusy, attack: hud.attackPending,
            enemy: hud.playingEnemyEvents, banner: hud.phaseBannerVisible,
            plate: hud.phasePlateVisible, confirm: hud.endConfirm,
            armed: hud.endTurnArmed, moveTouches: hud.moveTouches,
            controls: hud.controls?.length});
            if (now !== last) console.log('W29A HUD TRACE', now);
            last = now;
          }
        } catch {}
      }, 250);
      timer.unref();
      return page;
    };
    return context;
  };
  return browser;
};
