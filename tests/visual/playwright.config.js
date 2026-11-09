const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: __dirname,
  testMatch: 'baseline.spec.js',
  fullyParallel: false,
  workers: 1,
  use: { baseURL: 'http://127.0.0.1:3000', screenshot: 'only-on-failure' },
  projects: [
    { name: 'iphone', use: { viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 } },
    { name: 'desktop', use: { viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 } },
  ],
  snapshotPathTemplate: '{testDir}/screenshots/baseline/{projectName}/{arg}{ext}',
  webServer: {
    command: 'python3 -m http.server 3000 --bind 127.0.0.1 --directory public',
    cwd: require('node:path').resolve(__dirname, '../..'),
    url: 'http://127.0.0.1:3000/',
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
