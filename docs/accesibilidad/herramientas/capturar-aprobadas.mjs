import { readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { chromium } from 'playwright-core';

const [carpeta, chrome] = process.argv.slice(2);
if (!carpeta || !chrome) {
  console.log('uso: node capturar-aprobadas.mjs <carpeta> <rutaChrome>');
  process.exit(1);
}

const navegador = await chromium.launch({ executablePath: chrome, headless: true });
for (const archivo of readdirSync(carpeta).filter((a) => a.endsWith('.report.html'))) {
  const nombre = archivo.replace('.report.html', '');
  const pagina = await navegador.newPage({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 2 });
  await pagina.goto(pathToFileURL(resolve(carpeta, archivo)).href);
  await pagina.waitForSelector('.lh-category');
  await pagina.evaluate(() => {
    document.querySelectorAll('details.lh-clump').forEach((d) => (d.open = true));
  });
  await pagina.waitForTimeout(600);
  await pagina.screenshot({ path: join(carpeta, `${nombre}-5-aprobadas.png`), fullPage: true });
  await pagina.close();
}
await navegador.close();
console.log('listo', carpeta);
