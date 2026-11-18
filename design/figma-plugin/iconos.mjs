import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PAQUETE, VERSION, MARCO, origen } from './iconos-origen.mjs';

const aqui = dirname(fileURLToPath(import.meta.url));
const carpetaLib = join(aqui, '..', '..', 'trueque-u', 'app', 'lib');

const BASE = `https://cdn.jsdelivr.net/npm/${PAQUETE}@${VERSION}`;

function archivosDart(carpeta) {
  return readdirSync(carpeta, { withFileTypes: true }).flatMap(e => {
    const ruta = join(carpeta, e.name);
    if (e.isDirectory()) return archivosDart(ruta);
    return e.name.endsWith('.dart') ? [ruta] : [];
  });
}

function nombresUsados() {
  const nombres = new Set();
  for (const archivo of archivosDart(carpetaLib)) {
    for (const m of readFileSync(archivo, 'utf8').matchAll(/Icons\.([a-zA-Z0-9_]+)/g)) nombres.add(m[1]);
  }
  return [...nombres].sort();
}

function limpiar(nombre, svg) {
  const sinFondo = svg.replace(/<path d="M0 0h24v24H0z" fill="none"\/>/g, '').trim();
  if (!/viewBox="0 0 24 24"/.test(sinFondo)) throw new Error(`${nombre}: el SVG no tiene viewBox 24x24`);
  if (!/<path /.test(sinFondo)) throw new Error(`${nombre}: el SVG no tiene trazados`);
  return sinFondo;
}

async function descargar(nombre) {
  const [estilo, base] = origen(nombre);
  const url = `${BASE}/${estilo}/${base}.svg`;
  const respuesta = await fetch(url);
  if (!respuesta.ok) throw new Error(`${nombre}: ${url} respondio ${respuesta.status}`);
  return limpiar(nombre, await respuesta.text());
}

async function descargarTodos(lista) {
  const resultado = {};
  const fallos = [];
  await Promise.all(lista.map(async nombre => {
    try {
      resultado[nombre] = await descargar(nombre);
    } catch (error) {
      fallos.push(error.message);
    }
  }));
  if (fallos.length > 0) {
    console.error('Faltan iconos:\n' + fallos.sort().join('\n'));
    process.exit(1);
  }
  return Object.fromEntries(lista.map(n => [n, resultado[n]]));
}

const nombres = nombresUsados();
const iconos = await descargarTodos(nombres);
const marco = await descargarTodos(MARCO);

writeFileSync(join(aqui, 'iconos.json'), JSON.stringify(iconos, null, 2) + '\n');
writeFileSync(join(aqui, 'iconos-marco.json'), JSON.stringify(marco, null, 2) + '\n');
console.log(`iconos.json: ${nombres.length} iconos de ${PAQUETE}@${VERSION}; iconos-marco.json: ${MARCO.length} del framework`);
