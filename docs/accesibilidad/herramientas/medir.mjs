import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { chromium } from 'playwright-core';

const [base, salida, chrome, completo = 'no'] = process.argv.slice(2);
if (!base || !salida || !chrome) {
  console.log('uso: node medir.mjs <urlBase> <carpetaSalida> <rutaChrome> [completo]');
  process.exit(1);
}
process.env.CHROME_PATH = chrome;
mkdirSync(salida, { recursive: true });

const rutas = [
  ['inicio', '/'],
  ['iniciar-sesion', '/iniciar-sesion'],
  ['registro', '/registro'],
  ['recuperar-contrasena', '/recuperar-contrasena'],
];
const modos = [
  ['escritorio', ['--preset=desktop']],
  ['movil', []],
];

function url(ruta) {
  return `${base}/#${ruta}`;
}

function correrLighthouse(nombre, ruta, banderas, categorias) {
  if (existsSync(join(salida, nombre + '.report.json'))) return;
  const destino = join(salida, nombre);
  const args = [
    'lighthouse', url(ruta),
    '--output=json', '--output=html', `--output-path=${destino}`,
    '--max-wait-for-load=60000', '--quiet',
    '--chrome-flags=--headless=new --no-sandbox',
    ...banderas,
  ];
  if (categorias) args.push(`--only-categories=${categorias}`);
  const r = spawnSync('npx', args, { shell: true, stdio: 'inherit' });
  if (r.status !== 0) throw new Error(`falló lighthouse en ${nombre}`);
}

async function capturarInforme(navegador, nombre) {
  const pagina = await navegador.newPage({
    viewport: { width: 1280, height: 900 },
    deviceScaleFactor: 2,
  });
  await pagina.goto(pathToFileURL(resolve(salida, `${nombre}.report.html`)).href);
  await pagina.waitForSelector('.lh-category');
  await pagina.waitForTimeout(800);
  await pagina.screenshot({ path: join(salida, `${nombre}-1-puntaje.png`) });
  await pagina.evaluate(() => {
    document.querySelectorAll('.lh-category[id="accessibility"] details.lh-audit').forEach((d) => {
      if (d.closest('.lh-clump--failed, .lh-audit-group--unlabeled') || d.closest('.lh-clump--failed')) d.open = true;
    });
    document.querySelectorAll('.lh-clump--failed details.lh-audit').forEach((d) => (d.open = true));
  });
  await pagina.waitForTimeout(500);
  await pagina.screenshot({ path: join(salida, `${nombre}-2-fallas.png`), fullPage: true });
  const clumps = await pagina.$$('.lh-category .lh-clump');
  const manual = await pagina.$('.lh-clump--manual, .lh-clump--passed');
  if (manual) {
    await manual.scrollIntoViewIfNeeded();
    await pagina.evaluate(() => {
      const el = document.querySelector('.lh-clump--manual, .lh-clump--passed');
      window.scrollTo(0, el.getBoundingClientRect().top + window.scrollY - 180);
    });
  }
  await pagina.waitForTimeout(400);
  await pagina.screenshot({ path: join(salida, `${nombre}-3-secciones.png`) });
  await pagina.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await pagina.waitForTimeout(400);
  await pagina.screenshot({ path: join(salida, `${nombre}-4-pie.png`) });
  await pagina.close();
}

async function evidenciaApp(navegador, nombre, ruta, ancho, alto) {
  const pagina = await navegador.newPage({ viewport: { width: ancho, height: alto }, deviceScaleFactor: 1 });
  await pagina.goto(url(ruta), { waitUntil: 'networkidle' });
  await pagina.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
  await pagina.waitForTimeout(4000);
  const dom = await pagina.evaluate(() => ({
    nodosSemantica: document.querySelectorAll('flt-semantics').length,
    contenedorSemantica: document.querySelectorAll('flt-semantics-host').length,
    marcadorAccesibilidad: document.querySelectorAll('flt-semantics-placeholder').length,
    lang: document.documentElement.lang,
    titulo: document.title,
    botones: document.querySelectorAll('flt-semantics[role="button"]').length,
    camposTexto: document.querySelectorAll('flt-semantics input, flt-semantics textarea').length,
    encabezados: document.querySelectorAll('flt-semantics[role="heading"]').length,
  }));
  await pagina.screenshot({ path: join(salida, `${nombre}-app.png`) });
  await pagina.close();
  return dom;
}

const evidencia = {};
const navegador = await chromium.launch({ executablePath: chrome, headless: true });
for (const [nombreRuta, ruta] of rutas) {
  for (const [nombreModo, banderas] of modos) {
    const nombre = `${nombreRuta}-${nombreModo}`;
    correrLighthouse(nombre, ruta, banderas, 'accessibility');
    await capturarInforme(navegador, nombre);
    const [ancho, alto] = nombreModo === 'movil' ? [390, 844] : [1280, 800];
    evidencia[nombre] = await evidenciaApp(navegador, nombre, ruta, ancho, alto);
  }
}
if (completo === 'completo') {
  correrLighthouse('inicio-completo-escritorio', '/', ['--preset=desktop'], null);
  await capturarInforme(navegador, 'inicio-completo-escritorio');
}
await navegador.close();
writeFileSync(join(salida, 'evidencia-dom.json'), JSON.stringify(evidencia, null, 2));
console.log('listo', salida);
