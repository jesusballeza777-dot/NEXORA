// Renders del escultor con Playwright (Chromium sin interfaz, GPU por software).
//   node tools/sculpt/render.cjs <jobs.json>
// jobs.json: { "three": "<ruta a three/package>", "jobs": [ { "model": "...glb", "out": "...png",
//              "w": 900, "h": 900, "params": "view=34&zoom=1.1" } ] }
// three.js 0.160.0 se sirve desde una copia local (no hay red a la CDN en las pruebas).
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  const spec = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const viewer = path.resolve(__dirname, 'viewer.html');
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--allow-file-access-from-files'] });
  const errors = [];
  for (const job of spec.jobs) {
    const ctx = await browser.newContext({ viewport: { width: job.w || 900, height: job.h || 900 } });
    const page = await ctx.newPage();
    page.on('pageerror', (e) => errors.push(job.out + ': ' + e.message));
    page.on('console', (m) => { if (m.type() === 'error') errors.push(job.out + ': ' + m.text()); });
    await page.route(/cdn\.jsdelivr\.net\/npm\/three@0\.160\.0\/(.*)$/, (r) => {
      const rel = r.request().url().split('three@0.160.0/')[1];
      r.fulfill({ path: path.join(spec.three, rel), contentType: 'text/javascript' });
    });
    const url = 'file://' + viewer + '?model=' + encodeURIComponent('file://' + path.resolve(job.model)) + '&' + (job.params || '');
    await page.goto(url);
    await page.waitForSelector('body[data-ready="1"]', { timeout: 120000 });
    const err = await page.evaluate(() => document.body.dataset.error);
    if (err) errors.push(job.out + ': ' + err);
    fs.mkdirSync(path.dirname(job.out), { recursive: true });
    await page.screenshot({ path: job.out });
    await ctx.close();
  }
  await browser.close();
  console.log(JSON.stringify({ rendered: spec.jobs.length, errors }));
  process.exit(errors.length ? 1 : 0);
})();
