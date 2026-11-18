import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ALIAS, MARCO, origen } from './iconos-origen.mjs';

const aqui = dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(readFileSync(join(aqui, 'tokens.json'), 'utf8'));
const iconos = JSON.parse(readFileSync(join(aqui, 'iconos.json'), 'utf8'));
const iconosMarco = JSON.parse(readFileSync(join(aqui, 'iconos-marco.json'), 'utf8'));
const plugin = readFileSync(join(aqui, 'src', 'plugin.js'), 'utf8');

const codigo = [
  `const TOKENS = ${JSON.stringify(tokens, null, 2)};`,
  `const ICONOS = ${JSON.stringify(iconos, null, 2)};`,
  `const ICONOS_MARCO = ${JSON.stringify(iconosMarco, null, 2)};`,
  plugin,
].join('\n\n');
writeFileSync(join(aqui, 'code.js'), codigo);

function valorFinal(coleccion, campo) {
  const valor = tokens[coleccion][campo];
  if (typeof valor !== 'string' || valor.startsWith('#')) return valor;
  const [otra, otroCampo] = valor.split('/');
  return valorFinal(otra, otroCampo);
}

function medidas(def) {
  const tamano = typeof def.fontSize === 'string' ? valorFinal('Tipos', def.fontSize.split('/')[1]) : def.fontSize;
  const altura = def.height === null ? 'auto' : `${def.height} (${Math.round(tamano * def.height * 100) / 100} px)`;
  return `${tamano} px, altura ${altura}, espaciado ${def.letterSpacing === null ? 0 : def.letterSpacing}, peso ${def.fontWeight}`;
}

function referencia(ruta) {
  const [coleccion, campo] = ruta.split('/');
  return medidas(tokens[coleccion][campo]);
}

const SECCIONES_TEXTO = ['TextTheme', 'TextosTruequeU'];
const SECCIONES_APARTE = ['TextoDerivado', 'Contextos'];

function tablaTokens() {
  const filas = ['| Token Dart | Variable Figma | Valor |', '| --- | --- | --- |'];
  for (const [coleccion, campos] of Object.entries(tokens)) {
    if (SECCIONES_APARTE.includes(coleccion)) continue;
    for (const [campo, valor] of Object.entries(campos)) {
      let mostrado;
      if (SECCIONES_TEXTO.includes(coleccion)) {
        mostrado = medidas(valor);
      } else if (coleccion === 'ColorScheme') {
        mostrado = `${valor} (${valorFinal(coleccion, campo)})`;
      } else {
        mostrado = String(valor);
      }
      const figma = SECCIONES_TEXTO.includes(coleccion) ? `Estilo de texto \`${coleccion}/${campo}\`` : `\`${coleccion}/${campo}\``;
      filas.push(`| \`${coleccion}.${campo}\` | ${figma} | ${mostrado} |`);
    }
  }
  return filas.join('\n');
}

function tablaDerivados() {
  const filas = ['| Estilo Figma | Valor |', '| --- | --- |'];
  for (const [campo, def] of Object.entries(tokens.TextoDerivado)) {
    filas.push(`| \`TextoDerivado/${campo}\` | ${medidas(def)} |`);
  }
  return filas.join('\n');
}

function tablaContextos() {
  const filas = ['| Contexto Flutter | Estilo Figma | Valor |', '| --- | --- | --- |'];
  for (const [contexto, ruta] of Object.entries(tokens.Contextos)) {
    filas.push(`| \`${contexto}\` | \`${ruta}\` | ${referencia(ruta)} |`);
  }
  return filas.join('\n');
}

function descripcionOrigen(nombre) {
  const [estilo, base] = origen(nombre);
  const nota = ALIAS[nombre] ? ' (nombre antiguo de Flutter, mismo dibujo)' : '';
  return `${estilo === 'outlined' ? 'Outlined' : 'Filled'} \`${base}\`${nota}`;
}

function tablaIconos() {
  const filas = ['| Identificador Flutter | Material Icons |', '| --- | --- |'];
  for (const nombre of Object.keys(iconos)) filas.push(`| \`Icons.${nombre}\` | ${descripcionOrigen(nombre)} |`);
  return filas.join('\n');
}

function tablaIconosMarco() {
  const filas = ['| Ícono interno de Material | Material Icons |', '| --- | --- |'];
  for (const nombre of MARCO) filas.push(`| \`Icons.${nombre}\` | ${descripcionOrigen(nombre)} |`);
  return filas.join('\n');
}

function reemplazar(texto, marca, contenido) {
  const inicio = `<!-- ${marca}:inicio -->`;
  const fin = `<!-- ${marca}:fin -->`;
  const desde = texto.indexOf(inicio);
  const hasta = texto.indexOf(fin);
  if (desde === -1 || hasta <= desde) return texto;
  return `${texto.slice(0, desde + inicio.length)}\n${contenido}\n${texto.slice(hasta)}`;
}

const docs = join(aqui, '..', '..', 'docs', 'sistema-diseno.md');
if (existsSync(docs)) {
  let texto = readFileSync(docs, 'utf8');
  texto = reemplazar(texto, 'tokens', tablaTokens());
  texto = reemplazar(texto, 'derivados', tablaDerivados());
  texto = reemplazar(texto, 'contextos', tablaContextos());
  texto = reemplazar(texto, 'iconos', tablaIconos());
  texto = reemplazar(texto, 'iconos-marco', tablaIconosMarco());
  writeFileSync(docs, texto);
}

console.log('code.js generado');
