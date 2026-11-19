import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync, readFileSync, existsSync, cpSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { chromium } from 'playwright-core';
import lighthouse from 'lighthouse';
import desktopConfig from 'lighthouse/core/config/desktop-config.js';
import * as lanzadorChrome from 'chrome-launcher';
import { iniciarSesionEnPerfil, leerCredenciales } from './sesion.mjs';

const [base, salida, chrome, ...opciones] = process.argv.slice(2);
if (!base || !salida || !chrome) {
  console.log('uso: node medir.mjs <urlBase> <carpetaSalida> <rutaChrome> [completo] [sesion=<archivoCredenciales>]');
  process.exit(1);
}
const completo = opciones.includes('completo');
const archivoCredenciales = opciones.find((o) => o.startsWith('sesion='))?.slice(7);
const conSesion = Boolean(archivoCredenciales);
let perfilSesion = null;

function copiarPerfil() {
  const copia = mkdtempSync(join(tmpdir(), 'copia-perfil-'));
  cpSync(perfilSesion, copia, { recursive: true, filter: (origen) => !/(lockfile|Singleton)/.test(origen) });
  return copia;
}

process.env.CHROME_PATH = chrome;
mkdirSync(salida, { recursive: true });

const rutasPublicas = [
  ['inicio', '/'],
  ['iniciar-sesion', '/iniciar-sesion'],
  ['registro', '/registro'],
  ['recuperar-contrasena', '/recuperar-contrasena'],
];
const rutasPrivadas = [
  ['feed', '/feed'],
  ['mis-publicaciones', '/mis-publicaciones'],
  ['ofertas', '/ofertas'],
  ['perfil', '/perfil'],
  ['mis-datos', '/mis-datos'],
  ['intercambios', '/intercambios'],
  ['historial', '/historial'],
  ['avisos', '/avisos'],
  ['publicacion', '/publicacion'],
  ['cambiar-contrasena', '/cambiar-contrasena'],
];
const rutas = conSesion ? rutasPrivadas : rutasPublicas;
const modos = [
  ['escritorio', ['--preset=desktop']],
  ['movil', []],
];

function url(ruta) {
  return `${base}/#${ruta}`;
}

async function correrLighthouseConSesion(nombre, ruta, escritorio) {
  if (existsSync(join(salida, nombre + '.report.json'))) return;
  await new Promise((r) => setTimeout(r, 3000));
  const lanzado = await lanzadorChrome.launch({
    chromePath: chrome,
    userDataDir: copiarPerfil(),
    chromeFlags: ['--headless=new', '--no-sandbox'],
  });
  try {
    const resultado = await lighthouse(
      url(ruta),
      {
        port: lanzado.port,
        output: ['json', 'html'],
        onlyCategories: ['accessibility'],
        maxWaitForLoad: 60000,
        disableStorageReset: true,
        logLevel: 'error',
      },
      escritorio ? desktopConfig : undefined,
    );
    writeFileSync(join(salida, nombre + '.report.json'), resultado.report[0]);
    writeFileSync(join(salida, nombre + '.report.html'), resultado.report[1]);
  } finally {
    await lanzado.kill();
  }
}

function correrLighthouse(nombre, ruta, banderas, categorias) {
  if (existsSync(join(salida, nombre + '.report.json'))) return;
  const destino = join(salida, nombre);
  const args = [
    'lighthouse', url(ruta),
    '--output=json', '--output=html', `--output-path=${destino}`,
    '--max-wait-for-load=60000', '--quiet',
    ...banderas,
  ];
  args.push('--chrome-flags=--headless=new --no-sandbox');
  if (categorias) args.push(`--only-categories=${categorias}`);
  const r = spawnSync('npx', args, { shell: true, stdio: 'inherit' });
  if (r.status !== 0) throw new Error(`falló lighthouse en ${nombre}`);
}

function guardarPantallaDeLighthouse(nombre) {
  const informe = JSON.parse(readFileSync(join(salida, `${nombre}.report.json`), 'utf8'));
  const imagen = informe.fullPageScreenshot?.screenshot?.data;
  if (!imagen) return;
  const base64 = imagen.slice(imagen.indexOf(',') + 1);
  writeFileSync(join(salida, `${nombre}-pantalla-lighthouse.jpg`), Buffer.from(base64, 'base64'));
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
    document.querySelectorAll('.lh-clump--failed details.lh-audit').forEach((d) => (d.open = true));
    document.querySelectorAll('.lh-audit-group--unlabeled details.lh-audit').forEach((d) => {
      if (d.classList.contains('lh-audit--fail')) d.open = true;
    });
    document.querySelectorAll('details.lh-audit.lh-audit--fail').forEach((d) => (d.open = true));
  });
  await pagina.waitForTimeout(500);
  await pagina.screenshot({ path: join(salida, `${nombre}-2-fallas.png`), fullPage: true });
  await pagina.evaluate(() => {
    const el = document.querySelector('.lh-clump--manual, .lh-clump--passed');
    if (el) window.scrollTo(0, el.getBoundingClientRect().top + window.scrollY - 180);
  });
  await pagina.waitForTimeout(400);
  await pagina.screenshot({ path: join(salida, `${nombre}-3-secciones.png`) });
  await pagina.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await pagina.waitForTimeout(400);
  await pagina.screenshot({ path: join(salida, `${nombre}-4-pie.png`) });
  await pagina.close();
}

async function evidenciaApp(abrirPagina, nombre, ruta, ancho, alto) {
  const pagina = await abrirPagina();
  await pagina.setViewportSize({ width: ancho, height: alto });
  await pagina.goto(url(ruta), { waitUntil: 'domcontentloaded', timeout: 90000 });
  await pagina.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60000 });
  await pagina.waitForTimeout(4000);
  const dom = await pagina.evaluate(() => ({
    nodosSemantica: document.querySelectorAll('flt-semantics').length,
    marcadorAccesibilidad: document.querySelectorAll('flt-semantics-placeholder').length,
    lang: document.documentElement.lang,
    titulo: document.title,
    botones: document.querySelectorAll('flt-semantics[role="button"]').length,
    camposTexto: document.querySelectorAll('flt-semantics input, flt-semantics textarea').length,
    encabezados: document.querySelectorAll('flt-semantics[role="heading"]').length,
  }));
  dom.urlFinal = pagina.url();
  await pagina.screenshot({ path: join(salida, `${nombre}-app.png`) });
  await pagina.close();
  return dom;
}

const evidencia = {};
const lanzado = await chromium.launch({ executablePath: chrome, headless: true });
if (conSesion) {
  for (let intento = 1; intento <= 3 && !perfilSesion; intento++) {
    try {
      perfilSesion = await iniciarSesionEnPerfil({
        base,
        chrome,
        credenciales: leerCredenciales(archivoCredenciales),
      });
    } catch (error) {
      console.log(`intento de sesion ${intento} fallido: ${error.message.split(String.fromCharCode(10))[0]}`);
      if (intento === 3) throw error;
    }
  }
}

for (const [nombreRuta, ruta] of rutas) {
  for (const [nombreModo, banderas] of modos) {
    const nombre = `${nombreRuta}-${nombreModo}`;
    if (conSesion) await correrLighthouseConSesion(nombre, ruta, nombreModo === 'escritorio');
    else correrLighthouse(nombre, ruta, banderas, 'accessibility');
    guardarPantallaDeLighthouse(nombre);
    await capturarInforme(lanzado, nombre);
    const [ancho, alto] = nombreModo === 'movil' ? [390, 844] : [1280, 800];
    const contexto = conSesion
      ? await chromium.launchPersistentContext(copiarPerfil(), { executablePath: chrome, headless: true })
      : null;
    evidencia[nombre] = await evidenciaApp(() => (contexto ?? lanzado).newPage(), nombre, ruta, ancho, alto);
    if (contexto) await contexto.close();
    await new Promise((r) => setTimeout(r, 2000));
  }
}
if (completo && !conSesion) {
  correrLighthouse('inicio-completo-escritorio', '/', ['--preset=desktop'], null);
  guardarPantallaDeLighthouse('inicio-completo-escritorio');
  await capturarInforme(lanzado, 'inicio-completo-escritorio');
}
await lanzado.close();
const archivoEvidencia = conSesion ? 'evidencia-dom-sesion.json' : 'evidencia-dom.json';
writeFileSync(join(salida, archivoEvidencia), JSON.stringify(evidencia, null, 2));
console.log('listo', salida);
