import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const [carpeta, puerto = '8080'] = process.argv.slice(2);
if (!carpeta) {
  console.log('uso: node servir.mjs <carpetaBuildWeb> [puerto]');
  process.exit(1);
}

const tipos = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.ico': 'image/x-icon',
};

async function leer(ruta) {
  try {
    return await readFile(ruta);
  } catch {
    return null;
  }
}

createServer(async (peticion, respuesta) => {
  const ruta = normalize(decodeURIComponent(peticion.url.split('?')[0])).replace(/^([/\\])+/, '');
  let archivo = join(carpeta, ruta);
  let contenido = ruta === '' ? null : await leer(archivo);
  if (!contenido) {
    archivo = join(carpeta, 'index.html');
    contenido = await leer(archivo);
  }
  respuesta.writeHead(200, { 'Content-Type': tipos[extname(archivo)] ?? 'application/octet-stream' });
  respuesta.end(contenido);
}).listen(Number(puerto), () => console.log(`sirviendo ${carpeta} en http://localhost:${puerto}`));
