import { readdirSync } from 'node:fs';

const carpeta = process.argv[2] ?? '..';
const rutas = [
  ['inicio', '/'],
  ['iniciar-sesion', '/iniciar-sesion'],
  ['registro', '/registro'],
  ['recuperar-contrasena', '/recuperar-contrasena'],
];
const formatos = [
  ['escritorio', 'Escritorio'],
  ['movil', 'Móvil'],
];
const capturas = [
  ['1-puntaje', 'Puntaje'],
  ['3-secciones', 'Secciones de auditorías'],
  ['4-pie', 'Pie con versión y entorno'],
  ['5-aprobadas', 'Aprobadas y no aplicables expandidas'],
];

const existentes = new Set(readdirSync(`${carpeta}/antes`));
const lineas = [];
for (const [nombre, ruta] of rutas) {
  for (const [formato, etiquetaFormato] of formatos) {
    lineas.push(`### \`${ruta}\` (${etiquetaFormato})`, '', '| Captura | Antes (producción) | Después (build local) |', '| --- | --- | --- |');
    for (const [sufijo, etiqueta] of capturas) {
      const archivo = `${nombre}-${formato}-${sufijo}.png`;
      if (!existentes.has(archivo)) continue;
      lineas.push(`| ${etiqueta} | <img src="antes/${archivo}" width="420"> | <img src="despues/${archivo}" width="420"> |`);
    }
    lineas.push('');
  }
}
console.log(lineas.join('\n'));
