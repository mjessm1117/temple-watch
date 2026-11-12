// Optional harness preload: capture the live Godot canvas directly.
// This bypasses compositor screenshot waits when software WebGL is busy.
const fs = require('node:fs');
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
      page.screenshot = async options => {
        const data = await page.evaluate(() => document.getElementById('canvas').toDataURL('image/png'));
        if (!data?.startsWith('data:image/png;base64,')) throw Error('Godot canvas capture unavailable');
        const bytes = Buffer.from(data.slice('data:image/png;base64,'.length), 'base64');
        fs.writeFileSync(options.path, bytes);
        return bytes;
      };
      return page;
    };
    return context;
  };
  return browser;
};
